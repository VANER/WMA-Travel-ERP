"""Consultas de identidade para autenticacao."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.seguranca.models import Usuario


class UsuarioRepository:
    """Le a autoridade humana sem alterar estado ou controlar transacao."""

    def __init__(self, session: Session) -> None:
        self.session = session

    def buscar_por_email(self, email: str) -> Usuario | None:
        """Busca uma identidade por email sem diferenciar seu estado cadastral."""
        email_normalizado = email.strip()
        statement = select(Usuario).where(Usuario.email == email_normalizado)
        return self.session.scalar(statement)
