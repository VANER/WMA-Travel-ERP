"""Entrega SMTP de recuperacao pela conta Titan Email autorizada."""

import smtplib
import ssl
from email.message import EmailMessage
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

from app.core.config import Settings

SMTP_TIMEOUT_SECONDS = 15


class NotificadorRecuperacaoTitan:
    """Envia link de uso unico por SMTP SSL sem registrar o token."""

    def __init__(self, settings: Settings) -> None:
        if settings.smtp_password is None:
            raise ValueError("senha SMTP nao configurada")
        self._host = settings.smtp_host
        self._port = settings.smtp_port
        self._username = settings.smtp_username
        self._password = settings.smtp_password
        self._sender = settings.smtp_sender
        self._recovery_url = str(settings.recovery_url)

    def enviar(self, email: str, token: str) -> None:
        mensagem = EmailMessage()
        mensagem["Subject"] = "Redefinicao de senha - WMA Travel ERP"
        mensagem["From"] = self._sender
        mensagem["To"] = email
        mensagem.set_content(
            "Foi solicitada uma redefinicao de senha para sua conta.\n\n"
            f"Acesse o link: {_adicionar_token(self._recovery_url, token)}\n\n"
            "O link expira em 30 minutos e pode ser utilizado uma unica vez. "
            "Ignore esta mensagem se voce nao fez a solicitacao."
        )
        contexto = ssl.create_default_context()
        with smtplib.SMTP_SSL(
            self._host,
            self._port,
            timeout=SMTP_TIMEOUT_SECONDS,
            context=contexto,
        ) as smtp:
            smtp.login(self._username, self._password.get_secret_value())
            smtp.send_message(mensagem)


def _adicionar_token(url: str, token: str) -> str:
    partes = urlsplit(url)
    query = parse_qsl(partes.query, keep_blank_values=True)
    query.append(("token", token))
    return urlunsplit(
        (partes.scheme, partes.netloc, partes.path, urlencode(query), partes.fragment)
    )
