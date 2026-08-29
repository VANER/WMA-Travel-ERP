"""Testes do transporte SMTP Titan sem egress de rede."""

from email.message import EmailMessage
from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException

from app.core.config import Settings
from app.integrations.email_titan import NotificadorRecuperacaoTitan, _adicionar_token
from app.modules.seguranca.router import obter_notificador_recuperacao

DATABASE_URL = "postgresql+psycopg://wma_test@localhost:5432/wma_test"


def test_notificador_exige_segredo_smtp() -> None:
    with pytest.raises(ValueError, match="senha SMTP"):
        NotificadorRecuperacaoTitan(Settings(database_url=DATABASE_URL))


def test_dependencia_ativa_somente_com_segredo_smtp() -> None:
    with pytest.raises(HTTPException) as error:
        obter_notificador_recuperacao(Settings(database_url=DATABASE_URL))

    assert error.value.status_code == 503
    notificador = obter_notificador_recuperacao(
        Settings(database_url=DATABASE_URL, smtp_password="segredo-smtp")
    )
    assert isinstance(notificador, NotificadorRecuperacaoTitan)


def test_notificador_usa_ssl_autenticado_e_destinatario_da_conta() -> None:
    settings = Settings(database_url=DATABASE_URL, smtp_password="segredo-smtp")
    cliente = MagicMock()
    contexto_cliente = MagicMock()
    contexto_cliente.__enter__.return_value = cliente

    with (
        patch("app.integrations.email_titan.ssl.create_default_context") as criar_contexto,
        patch(
            "app.integrations.email_titan.smtplib.SMTP_SSL", return_value=contexto_cliente
        ) as smtp_ssl,
    ):
        NotificadorRecuperacaoTitan(settings).enviar("ana@example.com", "token opaco")

    smtp_ssl.assert_called_once_with(
        "smtp.titan.email", 465, timeout=15, context=criar_contexto.return_value
    )
    cliente.login.assert_called_once_with("vaner@wmatravel.com.br", "segredo-smtp")
    mensagem = cliente.send_message.call_args.args[0]
    assert isinstance(mensagem, EmailMessage)
    assert mensagem["From"] == "vaner@wmatravel.com.br"
    assert mensagem["To"] == "ana@example.com"
    assert "token=token+opaco" in mensagem.get_content()


def test_link_preserva_query_existente_e_fragmento() -> None:
    link = _adicionar_token("https://wmatravel.com.br/redefinir?origem=erp#form", "a+b")

    assert link == "https://wmatravel.com.br/redefinir?origem=erp&token=a%2Bb#form"
