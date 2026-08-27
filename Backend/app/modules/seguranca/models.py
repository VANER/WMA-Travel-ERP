"""Models de identidade usados pelo dominio de seguranca."""

from datetime import date, datetime
from uuid import UUID

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PostgreSQLUUID
from sqlalchemy.orm import Mapped, mapped_column
from sqlalchemy.sql.elements import conv

from app.db.base import Base


class Usuario(Base):
    """Autoridade humana existente em ``public.usuario``."""

    __tablename__ = "usuario"
    __table_args__ = (
        UniqueConstraint("email", name="uk_usuario_email"),
        {"comment": "Usuários autorizados do sistema"},
    )

    id_usuario: Mapped[int] = mapped_column(Integer, primary_key=True)
    nome: Mapped[str] = mapped_column(String(100), nullable=False)
    email: Mapped[str] = mapped_column(String(150), nullable=False)
    senha_hash: Mapped[str | None] = mapped_column(String(255), nullable=True)
    perfil: Mapped[str | None] = mapped_column(String(50), nullable=True)
    ativo: Mapped[bool | None] = mapped_column(Boolean, server_default=text("true"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )
    updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    updated_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    deleted_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    versao: Mapped[int | None] = mapped_column(Integer, server_default=text("1"), nullable=True)


class PerfilAcesso(Base):
    """Papel RBAC existente na baseline."""

    __tablename__ = "perfil_acesso"
    __table_args__ = (UniqueConstraint("codigo", name="uk_perfil_acesso_codigo"),)

    id_perfil: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo: Mapped[str] = mapped_column(String(30), nullable=False)
    descricao: Mapped[str] = mapped_column(String(100), nullable=False)
    ativo: Mapped[bool | None] = mapped_column(Boolean, server_default=text("true"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )
    updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    updated_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    deleted_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    versao: Mapped[int | None] = mapped_column(Integer, server_default=text("1"), nullable=True)


class Permissao(Base):
    """Permissao granular existente na baseline."""

    __tablename__ = "permissao"
    __table_args__ = (UniqueConstraint("codigo", name="uk_permissao_codigo"),)

    id_permissao: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo: Mapped[str] = mapped_column(String(50), nullable=False)
    descricao: Mapped[str] = mapped_column(String(150), nullable=False)
    modulo: Mapped[str | None] = mapped_column(String(50), nullable=True)
    created_at: Mapped[datetime | None] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=True
    )
    updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    updated_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    deleted_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    versao: Mapped[int | None] = mapped_column(Integer, server_default=text("1"), nullable=True)


class UsuarioPerfil(Base):
    """Atribuicao temporal de papel a uma identidade humana."""

    __tablename__ = "usuario_perfil"

    id_usuario: Mapped[int] = mapped_column(
        ForeignKey("usuario.id_usuario", name="fk_usuario_perfil_usuario"), primary_key=True
    )
    id_perfil: Mapped[int] = mapped_column(
        ForeignKey("perfil_acesso.id_perfil", name="fk_usuario_perfil_perfil"), primary_key=True
    )
    data_inicio: Mapped[date | None] = mapped_column(
        Date, server_default=text("CURRENT_DATE"), nullable=True
    )
    data_fim: Mapped[date | None] = mapped_column(Date, nullable=True)


class PerfilPermissao(Base):
    """Associacao auditavel entre papel RBAC e permissao."""

    __tablename__ = "perfil_permissao"
    __table_args__ = (
        {"comment": "Associacao auditavel entre papeis RBAC e permissoes granulares"},
    )

    id_perfil: Mapped[int] = mapped_column(
        ForeignKey("perfil_acesso.id_perfil", name="fk_perfil_permissao_perfil_acesso"),
        primary_key=True,
        comment="Papel RBAC autorizado.",
    )
    id_permissao: Mapped[int] = mapped_column(
        ForeignKey("permissao.id_permissao", name="fk_perfil_permissao_permissao"),
        primary_key=True,
        index=True,
        comment="Permissao concedida ao papel.",
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        server_default=text("CURRENT_TIMESTAMP"),
        nullable=False,
        comment="Instante de criacao do registro.",
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime, nullable=True, comment="Instante da ultima atualizacao."
    )
    deleted_at: Mapped[datetime | None] = mapped_column(
        DateTime, nullable=True, comment="Instante de exclusao logica."
    )
    created_by: Mapped[str | None] = mapped_column(
        String(100), nullable=True, comment="Responsavel pela criacao."
    )
    updated_by: Mapped[str | None] = mapped_column(
        String(100), nullable=True, comment="Responsavel pela ultima atualizacao."
    )
    deleted_by: Mapped[str | None] = mapped_column(
        String(100), nullable=True, comment="Responsavel pela exclusao logica."
    )
    versao: Mapped[int] = mapped_column(
        Integer,
        server_default=text("1"),
        nullable=False,
        comment="Versao otimista incrementada pelo trigger de atualizacao.",
    )


class RecuperacaoCredencial(Base):
    """Token de uso unico para redefinicao de credencial humana."""

    __tablename__ = "recuperacao_credencial"
    __table_args__ = (
        CheckConstraint(
            "char_length(token_hash) = 64", name=conv("ck_recuperacao_credencial_token_hash")
        ),
        UniqueConstraint("token_hash", name="uq_recuperacao_credencial_token_hash"),
        {"comment": "Solicitacoes de uso unico para recuperacao de credenciais"},
    )

    id_recuperacao: Mapped[UUID] = mapped_column(PostgreSQLUUID(as_uuid=True), primary_key=True)
    id_usuario: Mapped[int] = mapped_column(
        ForeignKey("usuario.id_usuario", name="fk_recuperacao_credencial_usuario"),
        nullable=False,
        index=True,
    )
    token_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    data_expiracao: Mapped[datetime] = mapped_column(DateTime, nullable=False, index=True)
    utilizado_em: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )
    updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    updated_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    deleted_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    versao: Mapped[int] = mapped_column(Integer, server_default=text("1"), nullable=False)


class EventoSeguranca(Base):
    """Evento operacional de seguranca sem segredos ou credenciais."""

    __tablename__ = "evento_seguranca"
    __table_args__ = ({"comment": "Trilha de eventos operacionais de seguranca"},)

    id_evento: Mapped[UUID] = mapped_column(PostgreSQLUUID(as_uuid=True), primary_key=True)
    codigo: Mapped[str] = mapped_column(String(50), nullable=False, index=True)
    resultado: Mapped[str] = mapped_column(String(20), nullable=False)
    id_usuario: Mapped[int | None] = mapped_column(
        ForeignKey("usuario.id_usuario", name="fk_evento_seguranca_usuario"), nullable=True
    )
    id_sessao: Mapped[UUID | None] = mapped_column(PostgreSQLUUID(as_uuid=True), nullable=True)
    endereco_ip: Mapped[str | None] = mapped_column(String(45), nullable=True)
    agente_usuario: Mapped[str | None] = mapped_column(String(255), nullable=True)
    detalhes: Mapped[dict[str, object]] = mapped_column(
        JSONB, server_default=text("'{}'::jsonb"), nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False, index=True
    )


class SessaoUsuario(Base):
    """Sessao humana renovavel, distinta dos tokens de integracao."""

    __tablename__ = "sessao_usuario"
    __table_args__ = (
        CheckConstraint(
            "char_length(token_refresh_hash) = 64",
            name=conv("ck_sessao_usuario_token_refresh_hash"),
        ),
        UniqueConstraint("token_refresh_hash", name="uq_sessao_usuario_token_refresh_hash"),
        {"comment": "Sessões renováveis das identidades humanas autenticadas"},
    )

    id_sessao: Mapped[UUID] = mapped_column(
        PostgreSQLUUID(as_uuid=True), primary_key=True, comment="Identificador opaco da sessão."
    )
    id_usuario: Mapped[int] = mapped_column(
        ForeignKey("usuario.id_usuario", name="fk_sessao_usuario_usuario"),
        nullable=False,
        index=True,
        comment="Identidade humana da sessão.",
    )
    id_familia: Mapped[UUID] = mapped_column(
        PostgreSQLUUID(as_uuid=True),
        nullable=False,
        index=True,
        comment="Família usada na rotação e revogação.",
    )
    token_refresh_hash: Mapped[str] = mapped_column(
        String(64), nullable=False, comment="SHA-256 hexadecimal do refresh token opaco."
    )
    data_expiracao: Mapped[datetime] = mapped_column(
        DateTime,
        nullable=False,
        index=True,
        comment="Expiração UTC da capacidade de renovação.",
    )
    revogado_em: Mapped[datetime | None] = mapped_column(
        DateTime, nullable=True, comment="Instante UTC da revogação."
    )
    id_sessao_substituta: Mapped[UUID | None] = mapped_column(
        ForeignKey("sessao_usuario.id_sessao", name="fk_sessao_usuario_sessao_substituta"),
        nullable=True,
        comment="Sessão sucessora criada pela rotação.",
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime,
        server_default=text("CURRENT_TIMESTAMP"),
        nullable=False,
        comment="Instante de criação do registro.",
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime, nullable=True, comment="Instante da última atualização."
    )
    deleted_at: Mapped[datetime | None] = mapped_column(
        DateTime, nullable=True, comment="Instante de exclusão lógica."
    )
    created_by: Mapped[str | None] = mapped_column(
        String(100), nullable=True, comment="Responsável pela criação."
    )
    updated_by: Mapped[str | None] = mapped_column(
        String(100), nullable=True, comment="Responsável pela última atualização."
    )
    deleted_by: Mapped[str | None] = mapped_column(
        String(100), nullable=True, comment="Responsável pela exclusão lógica."
    )
    versao: Mapped[int] = mapped_column(
        Integer,
        server_default=text("1"),
        nullable=False,
        comment="Versão otimista incrementada pelo trigger de atualização.",
    )
