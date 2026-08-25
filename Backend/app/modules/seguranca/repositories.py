"""Consultas de identidade para autenticacao."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.modules.seguranca.models import SessaoUsuario, Usuario


class UsuarioRepository:
    """Le a autoridade humana sem alterar estado ou controlar transacao."""

    def __init__(self, session: Session) -> None:
        self.session = session

    def buscar_por_email(self, email: str) -> Usuario | None:
        """Busca uma identidade por email sem diferenciar seu estado cadastral."""
        email_normalizado = email.strip()
        statement = select(Usuario).where(Usuario.email == email_normalizado)
        return self.session.scalar(statement)


class SessaoUsuarioRepository:
    """Persiste o ciclo de vida sem controlar a transacao externa."""

    def __init__(self, session: Session) -> None:
        self.session = session

    def adicionar(self, sessao: SessaoUsuario) -> None:
        self.session.add(sessao)

    def buscar_por_hash_para_atualizacao(self, token_hash: str) -> SessaoUsuario | None:
        statement = (
            select(SessaoUsuario)
            .where(SessaoUsuario.token_refresh_hash == token_hash)
            .with_for_update()
        )
        return self.session.scalar(statement)

    def revogar_familia(self, id_familia: UUID, instante: datetime) -> None:
        statement = (
            update(SessaoUsuario)
            .where(SessaoUsuario.id_familia == id_familia, SessaoUsuario.revogado_em.is_(None))
            .values(revogado_em=instante, updated_at=instante)
        )
        self.session.execute(statement)
