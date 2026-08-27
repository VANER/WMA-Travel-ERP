"""Testes opt-in contra uma instância PostgreSQL local descartável."""

from collections.abc import Generator
from contextlib import contextmanager
from datetime import UTC, date, datetime, timedelta
from unittest.mock import patch
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import Settings
from app.db.base import Base
from app.db.session import create_db_engine, database_is_available, get_session
from app.main import create_app
from app.modules.corporativo import models as _corporativo_models  # noqa: F401
from app.modules.seguranca.authorization import exigir_core_cadastrar, exigir_core_visualizar
from app.modules.seguranca.models import (
    PerfilAcesso,
    PerfilPermissao,
    Permissao,
    SessaoUsuario,
    Usuario,
    UsuarioPerfil,
)
from app.modules.seguranca.rbac import ContextoRbac
from app.modules.seguranca.tokens import CodecTokenAcesso

pytestmark = pytest.mark.postgresql


@contextmanager
def _corporate_database_client(postgresql_test_url: str) -> Generator[TestClient]:
    """Monta o recorte corporativo somente no banco descartável validado pela fixture."""
    engine = create_db_engine(Settings(database_url=postgresql_test_url, environment="test"))
    session_factory = sessionmaker(bind=engine, expire_on_commit=False)
    application = create_app()

    def session_dependency() -> Generator[Session]:
        with session_factory() as session:
            yield session

    application.dependency_overrides[get_session] = session_dependency
    contexto = ContextoRbac(
        id_usuario=1,
        papeis=("ADMIN",),
        permissoes=frozenset({"CORE_VISUALIZAR", "CORE_CADASTRAR"}),
    )
    application.dependency_overrides[exigir_core_visualizar] = lambda: contexto
    application.dependency_overrides[exigir_core_cadastrar] = lambda: contexto
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    try:
        with TestClient(application) as client:
            yield client
    finally:
        application.dependency_overrides.clear()
        Base.metadata.drop_all(engine)
        engine.dispose()


def test_postgresql_executes_read_only_health_query(postgresql_test_url: str) -> None:
    """Confirma conexão real e execução de consulta sem alterar o banco."""
    settings = Settings(database_url=postgresql_test_url, environment="test")
    engine = create_db_engine(settings)

    try:
        assert database_is_available(engine)
        with engine.connect() as connection:
            database_name = connection.execute(text("SELECT current_database()"))
            assert database_name.scalar_one().endswith("_test")
    finally:
        engine.dispose()


def test_database_health_uses_real_postgresql(postgresql_test_url: str) -> None:
    """Valida o contrato HTTP de disponibilidade contra PostgreSQL real."""
    settings = Settings(database_url=postgresql_test_url, environment="test")
    engine = create_db_engine(settings)

    try:
        with (
            patch(
                "app.api.v1.router.database_is_available",
                side_effect=lambda: database_is_available(engine),
            ),
            TestClient(create_app()) as client,
        ):
            response = client.get("/api/v1/health/database")

        assert response.status_code == 200
        assert response.json() == {"status": "ok", "database": "available"}
    finally:
        engine.dispose()


def test_core_api_persists_complete_flow_in_postgresql(postgresql_test_url: str) -> None:
    """Exercita API, services, repositories e models contra PostgreSQL real."""
    with _corporate_database_client(postgresql_test_url) as client:
        locality_payload = {"cidade": "Recife", "uf": "PE"}
        locality = client.post("/api/v1/localidades", json=locality_payload)
        assert locality.status_code == 201
        locality_data = locality.json()
        assert locality_data["pais"] == "Brasil"

        person = client.post(
            "/api/v1/pessoas",
            json={
                "tipo_pessoa": "FISICA",
                "nome_razao_social": "Pessoa Integração",
                "id_localidade": locality_data["id_localidade"],
            },
        )
        assert person.status_code == 201
        person_data = person.json()

        company = client.post(
            "/api/v1/empresas",
            json={
                "razao_social": "Empresa Integração",
                "nome_fantasia": "Empresa Teste",
                "id_localidade": locality_data["id_localidade"],
            },
        )
        assert company.status_code == 201
        company_data = company.json()

        dependent_payloads = (
            ("clientes", {"id_pessoa": person_data["id_pessoa"]}),
            ("fornecedores", {"id_pessoa": person_data["id_pessoa"]}),
            ("configuracoes-empresa", {"id_empresa": company_data["id_empresa"]}),
            ("parametros-sistema", {"codigo": "INTEGRACAO_2_1_7"}),
        )
        for resource, payload in dependent_payloads:
            assert client.post(f"/api/v1/{resource}", json=payload).status_code == 201

        document_type = client.post(
            "/api/v1/tipos-documento",
            json={"codigo": "INTEGRACAO", "descricao": "Documento de integração"},
        )
        assert document_type.status_code == 201
        document = client.post(
            "/api/v1/documentos",
            json={"id_tipo_documento": document_type.json()["id_tipo_documento"]},
        )
        assert document.status_code == 201
        assert document.json()["status"] == "ATIVO"

        fetched = client.get(f"/api/v1/pessoas/{person_data['id_pessoa']}")
        assert fetched.status_code == 200
        assert fetched.json()["nome_razao_social"] == "Pessoa Integração"
        assert len(client.get("/api/v1/pessoas?limite=1").json()) == 1

        duplicate = client.post("/api/v1/localidades", json=locality_payload)
        assert duplicate.status_code == 409
        assert duplicate.json()["code"] == "RESOURCE_CONFLICT"


def test_auth_rbac_real_revalida_usuario_e_revoga_sessao(
    postgresql_test_url: str,
) -> None:
    settings = Settings(database_url=postgresql_test_url, environment="test")
    engine = create_db_engine(settings)
    session_factory = sessionmaker(bind=engine, expire_on_commit=False)
    application = create_app()

    def session_dependency() -> Generator[Session]:
        with session_factory() as session:
            yield session

    application.dependency_overrides[get_session] = session_dependency
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    id_sessao = uuid4()
    agora = datetime.now(UTC).replace(tzinfo=None)
    try:
        with session_factory() as session:
            session.add_all(
                [
                    Usuario(id_usuario=7, nome="Ana", email="ana@example.com", ativo=True),
                    PerfilAcesso(
                        id_perfil=1, codigo="ADMIN", descricao="Administrador", ativo=True
                    ),
                    Permissao(
                        id_permissao=1,
                        codigo="CORE_VISUALIZAR",
                        descricao="Visualizar Core",
                    ),
                ]
            )
            session.flush()
            session.add_all(
                [
                    UsuarioPerfil(id_usuario=7, id_perfil=1, data_inicio=date.today()),
                    PerfilPermissao(id_perfil=1, id_permissao=1),
                    SessaoUsuario(
                        id_sessao=id_sessao,
                        id_usuario=7,
                        id_familia=id_sessao,
                        token_refresh_hash="a" * 64,
                        data_expiracao=agora + timedelta(minutes=30),
                    ),
                ]
            )
            session.commit()

        token = CodecTokenAcesso(settings).emitir(7, id_sessao, datetime.now(UTC))
        headers = {"Authorization": f"Bearer {token}"}
        with TestClient(application) as client:
            assert client.get("/api/v1/localidades", headers=headers).status_code == 200
            with session_factory() as session:
                usuario = session.get(Usuario, 7)
                assert usuario is not None
                usuario.ativo = False
                session.commit()
            assert client.get("/api/v1/localidades", headers=headers).status_code == 401

        with session_factory() as session:
            sessao = session.get(SessaoUsuario, id_sessao)
            assert sessao is not None
            assert sessao.revogado_em is not None
    finally:
        application.dependency_overrides.clear()
        Base.metadata.drop_all(engine)
        engine.dispose()
