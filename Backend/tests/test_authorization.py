"""Gates HTTP de autenticacao, autorizacao e sessoes."""

from datetime import UTC, datetime, timedelta
from unittest.mock import create_autospec, patch
from uuid import uuid4

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.session import get_session
from app.main import app
from app.modules.seguranca.authorization import exigir_permissao, obter_contexto_rbac
from app.modules.seguranca.models import SessaoUsuario, Usuario
from app.modules.seguranca.rbac import ContextoRbac
from app.modules.seguranca.tokens import CodecTokenAcesso


def test_endpoint_corporativo_nega_token_ausente(client: TestClient) -> None:
    response = client.get("/api/v1/localidades")

    assert response.status_code == 401
    assert response.headers["www-authenticate"] == "Bearer"


def test_dependencia_nega_permissao_ausente() -> None:
    verificar = exigir_permissao("CORE_CADASTRAR")

    with pytest.raises(HTTPException) as error:
        verificar(ContextoRbac(7, ("COMERCIAL",), frozenset()))

    assert error.value.status_code == 403


def test_dependencia_retorna_contexto_com_permissao() -> None:
    contexto = ContextoRbac(7, ("ADMIN",), frozenset({"CORE_CADASTRAR"}))

    assert exigir_permissao("CORE_CADASTRAR")(contexto) is contexto


def test_contexto_rbac_valida_token_sessao_e_concessoes() -> None:
    settings = get_settings()
    session = create_autospec(Session, instance=True)
    id_sessao = uuid4()
    token = CodecTokenAcesso(settings).emitir(7, id_sessao, datetime.now(UTC))
    session.scalar.return_value = SessaoUsuario(
        id_sessao=id_sessao,
        id_usuario=7,
        id_familia=id_sessao,
        token_refresh_hash="a" * 64,
        data_expiracao=datetime.now(UTC).replace(tzinfo=None) + timedelta(minutes=5),
    )
    session.scalars.side_effect = [("ADMIN",), ("CORE_VISUALIZAR",)]

    contexto = obter_contexto_rbac(token, session, settings)

    assert contexto.id_usuario == 7
    assert contexto.permissoes == frozenset({"CORE_VISUALIZAR"})


def test_contexto_rbac_nega_token_invalido() -> None:
    with pytest.raises(HTTPException) as error:
        obter_contexto_rbac("invalido", create_autospec(Session, instance=True), get_settings())

    assert error.value.status_code == 401


def test_contexto_rbac_nega_sessao_revogada() -> None:
    settings = get_settings()
    session = create_autospec(Session, instance=True)
    token = CodecTokenAcesso(settings).emitir(7, uuid4(), datetime.now(UTC))
    session.scalar.return_value = None

    with pytest.raises(HTTPException) as error:
        obter_contexto_rbac(token, session, settings)

    assert error.value.status_code == 401


def test_login_inicia_sessao_e_confirma_transacao(client: TestClient) -> None:
    session = create_autospec(Session, instance=True)
    session.scalar.return_value = Usuario(
        id_usuario=7,
        nome="Ana",
        email="ana@example.com",
        senha_hash="hash",
        ativo=True,
    )
    app.dependency_overrides[get_session] = lambda: session
    try:
        with patch(
            "app.modules.seguranca.router.PoliticaHashArgon2id.verificar", return_value=True
        ):
            response = client.post(
                "/api/v1/auth/login",
                json={"email": "ana@example.com", "credencial": "segredo"},
            )
    finally:
        app.dependency_overrides.pop(get_session, None)

    assert response.status_code == 200
    assert response.json()["token_type"] == "Bearer"
    assert session.add.call_count == 2
    session.commit.assert_called_once()
