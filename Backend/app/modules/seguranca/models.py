"""Models de identidade usados pelo dominio de seguranca."""

from datetime import datetime
from uuid import UUID

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Integer,
    String,
    UniqueConstraint,
    text,
)
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
