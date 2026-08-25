"""Models de identidade usados pelo dominio de seguranca."""

from datetime import datetime

from sqlalchemy import Boolean, DateTime, Integer, String, UniqueConstraint, text
from sqlalchemy.orm import Mapped, mapped_column

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
