"""Gates de tokens e sessoes humanas."""

from datetime import UTC, datetime, timedelta
from pathlib import Path
from typing import Any, cast
from unittest.mock import create_autospec
from uuid import UUID

import jwt
import pytest
from pydantic import ValidationError
from sqlalchemy import Select, Table, Update
from sqlalchemy.dialects import postgresql
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.modules.seguranca.models import SessaoUsuario
from app.modules.seguranca.repositories import SessaoUsuarioRepository
from app.modules.seguranca.services import IdentidadeAutenticada
from app.modules.seguranca.tokens import (
    JWT_ALGORITHM,
    CodecTokenAcesso,
    RepositorioSessao,
    SessaoService,
    TokenInvalidoError,
)

DATABASE_URL = "postgresql+psycopg://wma_test@localhost:5432/wma_test"
SIGNING_KEY = "test-only-signing-key-with-at-least-32-bytes"
NOW = datetime.now(UTC).replace(microsecond=0)
BACKEND_ROOT = Path(__file__).parents[1]


def _settings() -> Settings:
    return Settings(database_url=DATABASE_URL, token_signing_key=SIGNING_KEY)


def _service() -> tuple[SessaoService, Any, CodecTokenAcesso]:
    repository: Any = create_autospec(RepositorioSessao, instance=True)
    codec = CodecTokenAcesso(_settings())
    return SessaoService(repository, codec, _settings(), clock=lambda: NOW), repository, codec


def test_segredo_de_assinatura_e_obrigatorio_e_oculto() -> None:
    with pytest.raises(ValidationError):
        Settings(database_url=DATABASE_URL, token_signing_key="curto")

    settings = _settings()
    assert SIGNING_KEY not in repr(settings)


def test_model_sessao_humana_tem_constraints_e_auditoria() -> None:
    table = cast(Table, SessaoUsuario.__table__)

    assert table.name == "sessao_usuario"
    assert table.schema is None
    assert set(table.columns.keys()) == {
        "id_sessao",
        "id_usuario",
        "id_familia",
        "token_refresh_hash",
        "data_expiracao",
        "revogado_em",
        "id_sessao_substituta",
        "created_at",
        "updated_at",
        "deleted_at",
        "created_by",
        "updated_by",
        "deleted_by",
        "versao",
    }
    names = {constraint.name for constraint in table.constraints}
    assert "uq_sessao_usuario_token_refresh_hash" in names
    assert "fk_sessao_usuario_usuario" in names
    assert "fk_sessao_usuario_sessao_substituta" in names
    assert "ck_sessao_usuario_token_refresh_hash" in names


def test_repository_bloqueia_refresh_e_revoga_familia_sem_commit() -> None:
    session: Any = create_autospec(Session, instance=True)
    repository = SessaoUsuarioRepository(session)
    expected = SessaoUsuario(
        id_sessao=UUID("b181cec0-57c1-493c-8d9d-9eae31d36f58"),
        id_usuario=7,
        id_familia=UUID("1a89112a-a2a9-433f-b983-a529b2527929"),
        token_refresh_hash="a" * 64,
        data_expiracao=NOW.replace(tzinfo=None) + timedelta(days=1),
    )
    session.scalar.return_value = expected

    assert repository.buscar_por_hash_para_atualizacao("a" * 64) is expected
    select_statement = session.scalar.call_args.args[0]
    assert isinstance(select_statement, Select)
    compiled = str(select_statement.compile(dialect=postgresql.dialect()))  # type: ignore[no-untyped-call]
    assert "FOR UPDATE" in compiled

    repository.revogar_familia(expected.id_familia, NOW.replace(tzinfo=None))
    update_statement = session.execute.call_args.args[0]
    assert isinstance(update_statement, Update)
    session.commit.assert_not_called()


def test_repository_adiciona_sem_controlar_transacao() -> None:
    session: Any = create_autospec(Session, instance=True)
    repository = SessaoUsuarioRepository(session)
    sessao = SessaoUsuario()

    repository.adicionar(sessao)

    session.add.assert_called_once_with(sessao)
    session.commit.assert_not_called()


def test_migration_declara_dependencias_triggers_e_rollback() -> None:
    migration = (BACKEND_ROOT / "migrations/versions/202608252204_sessao_usuario.py").read_text(
        encoding="utf-8"
    )

    assert "to_regclass('public.usuario')" in migration
    assert "public.fn_atualiza_updated_at()" in migration
    assert "public.fn_log_auditoria()" in migration
    assert "CREATE TRIGGER trg_atualiza_updated_at" in migration
    assert "CREATE TRIGGER trg_log_auditoria" in migration
    assert 'op.drop_table("sessao_usuario")' in migration


def test_codec_emite_e_valida_claims_obrigatorias() -> None:
    codec = CodecTokenAcesso(_settings())
    session_id = UUID("b181cec0-57c1-493c-8d9d-9eae31d36f58")
    token = codec.emitir(42, session_id, NOW)
    claims = codec.validar(token)
    payload = jwt.decode(
        token,
        SIGNING_KEY,
        algorithms=[JWT_ALGORITHM],
        audience="wma-travel-erp-api",
        issuer="wma-travel-erp",
    )

    assert claims.id_usuario == 42
    assert claims.id_sessao == session_id
    assert payload["typ"] == "access"
    assert payload["exp"] - payload["iat"] == 900

    naive_token = codec.emitir(42, session_id, NOW.replace(tzinfo=None))
    assert codec.validar(naive_token).id_sessao == session_id


@pytest.mark.parametrize("token", ("invalido", ""))
def test_codec_recusa_token_invalido(token: str) -> None:
    with pytest.raises(TokenInvalidoError):
        CodecTokenAcesso(_settings()).validar(token)


def test_codec_recusa_algoritmo_audience_issuer_e_tipo_incorretos() -> None:
    codec = CodecTokenAcesso(_settings())
    base = {
        "sub": "1",
        "sid": "b181cec0-57c1-493c-8d9d-9eae31d36f58",
        "jti": "798bde86-f199-44a3-89ff-d4927af1c735",
        "iat": NOW,
        "nbf": NOW,
        "exp": NOW + timedelta(minutes=15),
        "typ": "refresh",
        "iss": "wma-travel-erp",
        "aud": "wma-travel-erp-api",
    }
    wrong_type = jwt.encode(base, SIGNING_KEY, algorithm=JWT_ALGORITHM)
    wrong_issuer = jwt.encode({**base, "typ": "access", "iss": "outro"}, SIGNING_KEY)
    wrong_audience = jwt.encode({**base, "typ": "access", "aud": "outra"}, SIGNING_KEY)

    for token in (wrong_type, wrong_issuer, wrong_audience):
        with pytest.raises(TokenInvalidoError):
            codec.validar(token)


def test_iniciar_persiste_somente_hash_e_emite_par() -> None:
    service, repository, codec = _service()
    pair = service.iniciar(IdentidadeAutenticada(7, "Ana", "ana@example.com"))
    persisted = repository.adicionar.call_args.args[0]

    assert pair.token_type == "Bearer"
    assert pair.expires_in == 900
    assert len(pair.refresh_token) >= 43
    assert pair.refresh_token not in persisted.token_refresh_hash
    assert len(persisted.token_refresh_hash) == 64
    assert persisted.id_familia == persisted.id_sessao
    assert codec.validar(pair.access_token).id_usuario == 7


def test_renovar_rotaciona_refresh_token_uma_unica_vez() -> None:
    service, repository, _ = _service()
    current = SessaoUsuario(
        id_sessao=UUID("b181cec0-57c1-493c-8d9d-9eae31d36f58"),
        id_usuario=7,
        id_familia=UUID("1a89112a-a2a9-433f-b983-a529b2527929"),
        token_refresh_hash="a" * 64,
        data_expiracao=NOW.replace(tzinfo=None) + timedelta(days=1),
    )
    repository.buscar_por_hash_para_atualizacao.return_value = current

    pair = service.renovar("refresh-atual")
    successor = repository.adicionar.call_args.args[0]

    assert current.revogado_em == NOW.replace(tzinfo=None)
    assert current.id_sessao_substituta == successor.id_sessao
    assert successor.id_familia == current.id_familia
    assert successor.token_refresh_hash != current.token_refresh_hash
    assert pair.refresh_token not in successor.token_refresh_hash


def test_reutilizacao_ou_expiracao_revoga_familia() -> None:
    service, repository, _ = _service()
    family = UUID("1a89112a-a2a9-433f-b983-a529b2527929")
    session = SessaoUsuario(
        id_sessao=UUID("b181cec0-57c1-493c-8d9d-9eae31d36f58"),
        id_usuario=7,
        id_familia=family,
        token_refresh_hash="a" * 64,
        data_expiracao=NOW.replace(tzinfo=None) - timedelta(seconds=1),
    )
    repository.buscar_por_hash_para_atualizacao.return_value = session

    with pytest.raises(TokenInvalidoError):
        service.renovar("expirado")

    repository.revogar_familia.assert_called_once_with(family, NOW.replace(tzinfo=None))

    repository.reset_mock()
    session.revogado_em = NOW.replace(tzinfo=None)
    with pytest.raises(TokenInvalidoError):
        service.renovar("reutilizado")
    repository.revogar_familia.assert_called_once_with(family, NOW.replace(tzinfo=None))


def test_refresh_desconhecido_falha_sem_criar_sessao() -> None:
    service, repository, _ = _service()
    repository.buscar_por_hash_para_atualizacao.return_value = None

    with pytest.raises(TokenInvalidoError):
        service.renovar("desconhecido")

    repository.adicionar.assert_not_called()


def test_revogar_e_idempotente_para_token_desconhecido() -> None:
    service, repository, _ = _service()
    repository.buscar_por_hash_para_atualizacao.return_value = None

    service.revogar("desconhecido")

    repository.revogar_familia.assert_not_called()

    family = UUID("1a89112a-a2a9-433f-b983-a529b2527929")
    repository.buscar_por_hash_para_atualizacao.return_value = SessaoUsuario(
        id_sessao=UUID("b181cec0-57c1-493c-8d9d-9eae31d36f58"),
        id_usuario=7,
        id_familia=family,
        token_refresh_hash="a" * 64,
        data_expiracao=NOW.replace(tzinfo=None) + timedelta(days=1),
    )
    service.revogar("conhecido")
    repository.revogar_familia.assert_called_once_with(family, NOW.replace(tzinfo=None))
