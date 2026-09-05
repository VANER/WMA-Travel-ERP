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
from app.modules.comercial.clientes import ClienteComercialService, HabilitarCliente
from app.modules.corporativo import models as _corporativo_models  # noqa: F401
from app.modules.corporativo.clientes import CadastroClienteCorporativoSqlAlchemy
from app.modules.corporativo.models import Cliente, Localidade, Pessoa
from app.modules.seguranca.authorization import (
    exigir_comercial_gerenciar,
    exigir_comercial_visualizar,
    exigir_core_cadastrar,
    exigir_core_visualizar,
)
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
from app.modules.turismo.models import PacoteViagem, ProdutoTuristico
from app.modules.turismo.schemas import ReservaAcao, ReservaCreate, SaidaCreate
from app.modules.turismo.services import (
    RegraTurismoError,
    cancelar_reserva,
    confirmar_reserva,
    criar_reserva,
    criar_saida,
    obter_disponibilidade,
)

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
        permissoes=frozenset(
            {
                "COMERCIAL_GERENCIAR",
                "COMERCIAL_VISUALIZAR",
                "CORE_VISUALIZAR",
                "CORE_CADASTRAR",
            }
        ),
    )
    application.dependency_overrides[exigir_core_visualizar] = lambda: contexto
    application.dependency_overrides[exigir_core_cadastrar] = lambda: contexto
    application.dependency_overrides[exigir_comercial_visualizar] = lambda: contexto
    application.dependency_overrides[exigir_comercial_gerenciar] = lambda: contexto
    with engine.begin() as connection:
        connection.execute(text("CREATE SCHEMA IF NOT EXISTS financeiro"))
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


def test_turismo_preserva_ultima_vaga_e_idempotencia_no_postgresql(
    postgresql_test_url: str,
) -> None:
    """Valida o núcleo transacional de Turismo contra PostgreSQL real."""
    engine = create_db_engine(Settings(database_url=postgresql_test_url, environment="test"))
    with engine.begin() as connection:
        connection.execute(text("CREATE SCHEMA IF NOT EXISTS financeiro"))
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    try:
        with Session(engine) as session:
            localidade = Localidade(cidade="Curitiba", uf="PR", pais="Brasil")
            session.add(localidade)
            session.flush()
            session.add(
                Pessoa(
                    id_pessoa=1,
                    tipo_pessoa="FISICA",
                    nome_razao_social="Cliente Turismo",
                    id_localidade=localidade.id_localidade,
                )
            )
            session.flush()
            session.add(Cliente(id_cliente=1, id_pessoa=1, codigo_cliente="TUR-1"))
            session.add(
                ProdutoTuristico(
                    id_produto=1,
                    codigo="PROD-1",
                    nome="Produto",
                    tipo_produto="PACOTE",
                )
            )
            session.flush()
            session.add(PacoteViagem(id_pacote=1, id_produto=1, codigo_pacote="PAC-1"))
            session.commit()

            saida = criar_saida(
                session,
                SaidaCreate(
                    id_pacote=1,
                    codigo="SAI-1",
                    data_inicio=date(2026, 10, 1),
                    data_fim=date(2026, 10, 2),
                    capacidade=1,
                ),
            )
            payload = ReservaCreate(
                codigo_reserva="RES-1",
                id_cliente=1,
                id_saida=saida.id_saida,
                quantidade_passageiros=1,
                chave_idempotencia="turismo:reserva:1",
            )
            reserva = criar_reserva(session, payload)
            assert criar_reserva(session, payload).id_reserva == reserva.id_reserva
            assert obter_disponibilidade(session, saida.id_saida).disponibilidade == 0
            with pytest.raises(RegraTurismoError, match="capacidade"):
                criar_reserva(
                    session,
                    payload.model_copy(
                        update={
                            "codigo_reserva": "RES-2",
                            "chave_idempotencia": "turismo:reserva:2",
                        }
                    ),
                )
            action = ReservaAcao(chave_idempotencia="turismo:acao:1")
            assert confirmar_reserva(session, reserva.id_reserva, action).status == "CONFIRMADA"
            assert cancelar_reserva(session, reserva.id_reserva, action).status == "CANCELADA"
            assert obter_disponibilidade(session, saida.id_saida).disponibilidade == 1
    finally:
        Base.metadata.drop_all(engine)
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


def test_comercial_habilita_cliente_sobre_autoridade_corporativa(
    postgresql_test_url: str,
) -> None:
    settings = Settings(database_url=postgresql_test_url, environment="test")
    engine = create_db_engine(settings)
    session_factory = sessionmaker(bind=engine, expire_on_commit=False)
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    try:
        with session_factory() as session:
            localidade = _corporativo_models.Localidade(cidade="Natal", uf="RN", pais="Brasil")
            session.add(localidade)
            session.flush()
            pessoa = _corporativo_models.Pessoa(
                tipo_pessoa="FISICA",
                nome_razao_social="Cliente Comercial",
                id_localidade=localidade.id_localidade,
            )
            session.add(pessoa)
            session.commit()

            service = ClienteComercialService(
                session,
                CadastroClienteCorporativoSqlAlchemy(session),
            )
            cliente = service.habilitar(HabilitarCliente(pessoa.id_pessoa, "COM-001"))

            assert cliente.id_pessoa == pessoa.id_pessoa
            assert cliente.codigo_cliente == "COM-001"
            assert service.obter_por_pessoa(pessoa.id_pessoa) == cliente
    finally:
        Base.metadata.drop_all(engine)
        engine.dispose()


def test_comercial_api_executes_full_conversion_flow(postgresql_test_url: str) -> None:
    """Exercita Lead, fornecedor, pipeline, proposta, venda e contrato reais."""
    with _corporate_database_client(postgresql_test_url) as client:
        locality = client.post("/api/v1/localidades", json={"cidade": "Fortaleza"}).json()
        person = client.post(
            "/api/v1/pessoas",
            json={
                "tipo_pessoa": "JURIDICA",
                "nome_razao_social": "Operadora Integração",
                "id_localidade": locality["id_localidade"],
            },
        ).json()
        client_record = client.post(
            "/api/v1/clientes", json={"id_pessoa": person["id_pessoa"]}
        ).json()
        supplier = client.post(
            "/api/v1/fornecedores", json={"id_pessoa": person["id_pessoa"]}
        ).json()
        operator = client.post(
            "/api/v1/comercial/operadoras",
            json={"id_fornecedor": supplier["id_fornecedor"], "codigo": "OP-INT"},
        )
        assert operator.status_code == 201

        lead = client.post("/api/v1/comercial/leads", json={"nome": "Lead Integração"}).json()
        assert (
            client.post(
                "/api/v1/comercial/interacoes",
                json={"id_lead": lead["id_lead"], "tipo": "EMAIL"},
            ).status_code
            == 201
        )
        opportunity = client.post(
            "/api/v1/comercial/oportunidades",
            json={
                "id_lead": lead["id_lead"],
                "id_cliente": client_record["id_cliente"],
                "titulo": "Viagem de integração",
            },
        ).json()
        proposal = client.post(
            "/api/v1/comercial/propostas",
            json={
                "id_oportunidade": opportunity["id_oportunidade"],
                "id_cliente": client_record["id_cliente"],
                "numero": "PROP-INT",
                "data_emissao": "2026-08-31",
                "data_validade": "2026-09-30",
            },
        ).json()
        item = client.post(
            "/api/v1/comercial/itens-proposta",
            json={
                "id_proposta": proposal["id_proposta"],
                "descricao": "Pacote turístico",
                "quantidade": "2.00",
                "valor_unitario": "500.00",
                "desconto": "100.00",
            },
        )
        assert item.json()["valor_total"] == "900.00"
        assert (
            client.post(
                "/api/v1/comercial/condicoes",
                json={
                    "id_proposta": proposal["id_proposta"],
                    "tipo": "PAGAMENTO",
                    "descricao": "À vista",
                    "data_inicio": "2026-08-31",
                },
            ).status_code
            == 201
        )
        for proposal_status in ("ENVIADA", "ACEITA"):
            response = client.post(
                f"/api/v1/comercial/propostas/{proposal['id_proposta']}/status",
                json={"status": proposal_status},
            )
            assert response.status_code == 200
        sale = client.post(
            "/api/v1/comercial/vendas",
            json={
                "id_proposta": proposal["id_proposta"],
                "numero_venda": "VENDA-INT",
                "data_venda": "2026-08-31",
            },
        ).json()
        document_type = client.post(
            "/api/v1/tipos-documento",
            json={"codigo": "CONTRATO-INT", "descricao": "Contrato integração"},
        ).json()
        document = client.post(
            "/api/v1/documentos",
            json={"id_tipo_documento": document_type["id_tipo_documento"]},
        ).json()
        contract = client.post(
            "/api/v1/comercial/contratos",
            json={
                "id_documento": document["id_documento"],
                "id_venda": sale["id_venda"],
                "status": "ATIVO",
            },
        )
        assert contract.status_code == 201
        assert client.get("/api/v1/comercial/vendas").json()[0]["valor_liquido"] == "900.00"
