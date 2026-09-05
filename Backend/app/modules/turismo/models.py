"""Models SQLAlchemy do domínio Turismo."""

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Date,
    DateTime,
    ForeignKey,
    Identity,
    Integer,
    Numeric,
    String,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class LegacyAuditMixin:
    created_at: Mapped[datetime | None] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=True
    )
    updated_at: Mapped[datetime | None] = mapped_column(DateTime)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime)
    created_by: Mapped[str | None] = mapped_column(String(100))
    updated_by: Mapped[str | None] = mapped_column(String(100))
    deleted_by: Mapped[str | None] = mapped_column(String(100))
    versao: Mapped[int | None] = mapped_column(Integer, server_default=text("1"), nullable=True)


class AuditMixin(LegacyAuditMixin):
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )
    versao: Mapped[int] = mapped_column(Integer, server_default=text("1"), nullable=False)


class Destino(LegacyAuditMixin, Base):
    __tablename__ = "destino"
    id_destino: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo: Mapped[str] = mapped_column(String(20), nullable=False)
    nome: Mapped[str] = mapped_column(String(150), nullable=False)
    descricao: Mapped[str | None] = mapped_column(Text)
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"), nullable=False)
    id_localidade: Mapped[int] = mapped_column(ForeignKey("localidade.id_localidade"))
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )


class ProdutoTuristico(LegacyAuditMixin, Base):
    __tablename__ = "produto_turistico"
    id_produto: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo: Mapped[str] = mapped_column(String(20), nullable=False)
    nome: Mapped[str] = mapped_column(String(150), nullable=False)
    tipo_produto: Mapped[str] = mapped_column(String(50), nullable=False)
    descricao: Mapped[str | None] = mapped_column(Text)
    duracao_dias: Mapped[int | None] = mapped_column(Integer)
    destino: Mapped[str | None] = mapped_column(String(150))
    id_destino: Mapped[int | None] = mapped_column(ForeignKey("destino.id_destino"))
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )


class PacoteViagem(LegacyAuditMixin, Base):
    __tablename__ = "pacote_viagem"
    id_pacote: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_produto: Mapped[int] = mapped_column(ForeignKey("produto_turistico.id_produto"))
    codigo_pacote: Mapped[str | None] = mapped_column(String(30))
    data_inicio: Mapped[date | None] = mapped_column(Date)
    data_fim: Mapped[date | None] = mapped_column(Date)
    quantidade_vagas: Mapped[int | None] = mapped_column(Integer)
    valor_venda: Mapped[Decimal | None] = mapped_column(Numeric(15, 2))
    custo_estimado: Mapped[Decimal | None] = mapped_column(Numeric(15, 2))
    status: Mapped[str | None] = mapped_column(String(30), server_default=text("'ATIVO'"))


class SaidaTuristica(AuditMixin, Base):
    __tablename__ = "saida_turistica"
    __table_args__ = (
        CheckConstraint("data_fim >= data_inicio", name="periodo"),
        CheckConstraint("capacidade >= 0", name="capacidade"),
        UniqueConstraint("codigo", name="uq_saida_turistica_codigo"),
    )
    id_saida: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_pacote: Mapped[int] = mapped_column(ForeignKey("pacote_viagem.id_pacote"))
    codigo: Mapped[str] = mapped_column(String(30), nullable=False)
    data_inicio: Mapped[date] = mapped_column(Date, nullable=False)
    data_fim: Mapped[date] = mapped_column(Date, nullable=False)
    capacidade: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(
        String(20), server_default=text("'PLANEJADA'"), nullable=False
    )


class Reserva(LegacyAuditMixin, Base):
    __tablename__ = "reserva"
    id_reserva: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo_reserva: Mapped[str] = mapped_column(String(30), nullable=False)
    id_cliente: Mapped[int] = mapped_column(ForeignKey("cliente.id_cliente"))
    id_pacote: Mapped[int] = mapped_column(ForeignKey("pacote_viagem.id_pacote"))
    id_saida: Mapped[int | None] = mapped_column(ForeignKey("saida_turistica.id_saida"))
    data_reserva: Mapped[date] = mapped_column(Date, nullable=False)
    quantidade_passageiros: Mapped[int] = mapped_column(Integer, server_default=text("1"))
    valor_total: Mapped[Decimal | None] = mapped_column(Numeric(15, 2))
    status: Mapped[str] = mapped_column(
        String(30), server_default=text("'PENDENTE'"), nullable=False
    )


class AlocacaoVaga(AuditMixin, Base):
    __tablename__ = "alocacao_vaga"
    __table_args__ = (
        CheckConstraint("quantidade > 0", name="quantidade"),
        UniqueConstraint("chave_idempotencia", name="uq_alocacao_vaga_chave"),
    )
    id_alocacao: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_saida: Mapped[int] = mapped_column(ForeignKey("saida_turistica.id_saida"))
    id_reserva: Mapped[int | None] = mapped_column(ForeignKey("reserva.id_reserva"))
    chave_idempotencia: Mapped[str] = mapped_column(String(100), nullable=False)
    quantidade: Mapped[int] = mapped_column(Integer, nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False)
    expira_em: Mapped[datetime | None] = mapped_column(DateTime)


class ReservaCorrelacao(AuditMixin, Base):
    __tablename__ = "reserva_correlacao"
    __table_args__ = (
        UniqueConstraint("id_reserva", name="uq_reserva_correlacao_reserva"),
        UniqueConstraint("chave_idempotencia", name="uq_reserva_correlacao_chave"),
    )
    id_correlacao: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_reserva: Mapped[int] = mapped_column(ForeignKey("reserva.id_reserva"))
    id_venda: Mapped[int | None] = mapped_column(ForeignKey("venda.id_venda"))
    id_item_venda: Mapped[int | None] = mapped_column(ForeignKey("item_venda.id_item"))
    id_contrato: Mapped[int | None] = mapped_column(ForeignKey("contrato.id_contrato"))
    chave_idempotencia: Mapped[str] = mapped_column(String(100), nullable=False)
