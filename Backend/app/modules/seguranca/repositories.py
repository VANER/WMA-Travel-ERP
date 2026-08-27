"""Consultas de identidade para autenticacao."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.modules.seguranca.models import (
    PerfilAcesso,
    PerfilPermissao,
    Permissao,
    RecuperacaoCredencial,
    SessaoUsuario,
    Usuario,
    UsuarioPerfil,
)


class UsuarioRepository:
    """Le a autoridade humana sem alterar estado ou controlar transacao."""

    def __init__(self, session: Session) -> None:
        self.session = session

    def buscar_por_email(self, email: str) -> Usuario | None:
        """Busca uma identidade por email sem diferenciar seu estado cadastral."""
        email_normalizado = email.strip()
        statement = select(Usuario).where(Usuario.email == email_normalizado)
        return self.session.scalar(statement)

    def buscar_por_id(self, id_usuario: int) -> Usuario | None:
        return self.session.get(Usuario, id_usuario)

    def buscar_ativo_por_id(self, id_usuario: int) -> Usuario | None:
        statement = select(Usuario).where(
            Usuario.id_usuario == id_usuario,
            Usuario.ativo.is_(True),
            Usuario.deleted_at.is_(None),
        )
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

    def buscar_ativa(
        self, id_sessao: UUID, id_usuario: int, instante: datetime
    ) -> SessaoUsuario | None:
        statement = select(SessaoUsuario).where(
            SessaoUsuario.id_sessao == id_sessao,
            SessaoUsuario.id_usuario == id_usuario,
            SessaoUsuario.revogado_em.is_(None),
            SessaoUsuario.deleted_at.is_(None),
            SessaoUsuario.data_expiracao > instante,
        )
        return self.session.scalar(statement)

    def revogar_familia(self, id_familia: UUID, instante: datetime) -> None:
        statement = (
            update(SessaoUsuario)
            .where(SessaoUsuario.id_familia == id_familia, SessaoUsuario.revogado_em.is_(None))
            .values(revogado_em=instante, updated_at=instante)
        )
        self.session.execute(statement)

    def revogar_usuario(self, id_usuario: int, instante: datetime) -> None:
        statement = (
            update(SessaoUsuario)
            .where(SessaoUsuario.id_usuario == id_usuario, SessaoUsuario.revogado_em.is_(None))
            .values(revogado_em=instante, updated_at=instante)
        )
        self.session.execute(statement)


class RecuperacaoRepository:
    """Persiste solicitacoes de recuperacao sem controlar a transacao."""

    def __init__(self, session: Session) -> None:
        self.session = session

    def adicionar(self, recuperacao: RecuperacaoCredencial) -> None:
        self.session.add(recuperacao)

    def buscar_por_hash_para_atualizacao(self, token_hash: str) -> RecuperacaoCredencial | None:
        statement = (
            select(RecuperacaoCredencial)
            .where(RecuperacaoCredencial.token_hash == token_hash)
            .with_for_update()
        )
        return self.session.scalar(statement)


class RbacRepository:
    """Consulta papeis e permissoes efetivos sem controlar transacao."""

    def __init__(self, session: Session) -> None:
        self.session = session

    def listar_perfis_ativos(self, id_usuario: int, hoje: date) -> tuple[str, ...]:
        statement = (
            select(PerfilAcesso.codigo)
            .join(UsuarioPerfil, UsuarioPerfil.id_perfil == PerfilAcesso.id_perfil)
            .where(
                UsuarioPerfil.id_usuario == id_usuario,
                PerfilAcesso.ativo.is_(True),
                PerfilAcesso.deleted_at.is_(None),
                (UsuarioPerfil.data_inicio.is_(None) | (UsuarioPerfil.data_inicio <= hoje)),
                (UsuarioPerfil.data_fim.is_(None) | (UsuarioPerfil.data_fim >= hoje)),
            )
            .order_by(PerfilAcesso.codigo)
        )
        return tuple(self.session.scalars(statement))

    def listar_permissoes_ativas(self, id_usuario: int, hoje: date) -> frozenset[str]:
        statement = (
            select(Permissao.codigo)
            .join(PerfilPermissao, PerfilPermissao.id_permissao == Permissao.id_permissao)
            .join(PerfilAcesso, PerfilAcesso.id_perfil == PerfilPermissao.id_perfil)
            .join(UsuarioPerfil, UsuarioPerfil.id_perfil == PerfilAcesso.id_perfil)
            .where(
                UsuarioPerfil.id_usuario == id_usuario,
                PerfilAcesso.ativo.is_(True),
                PerfilAcesso.deleted_at.is_(None),
                Permissao.deleted_at.is_(None),
                PerfilPermissao.deleted_at.is_(None),
                (UsuarioPerfil.data_inicio.is_(None) | (UsuarioPerfil.data_inicio <= hoje)),
                (UsuarioPerfil.data_fim.is_(None) | (UsuarioPerfil.data_fim >= hoje)),
            )
            .distinct()
        )
        return frozenset(self.session.scalars(statement))
