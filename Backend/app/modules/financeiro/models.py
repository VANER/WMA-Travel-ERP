"""Models SQLAlchemy do domínio Financeiro."""

from datetime import date, datetime
from decimal import Decimal

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    Computed,
    Date,
    DateTime,
    ForeignKey,
    Identity,
    Integer,
    Numeric,
    SmallInteger,
    String,
    Text,
    UniqueConstraint,
    text,
)
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base

SCHEMA = "financeiro"


class AuditMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )
    updated_at: Mapped[datetime | None] = mapped_column(DateTime)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime)
    created_by: Mapped[int | None] = mapped_column(Integer)
    updated_by: Mapped[int | None] = mapped_column(Integer)
    deleted_by: Mapped[int | None] = mapped_column(Integer)
    versao: Mapped[int] = mapped_column(Integer, server_default=text("1"), nullable=False)


class Grupo(AuditMixin, Base):
    __tablename__ = "grupo"
    __table_args__ = {"schema": SCHEMA}
    id_grupo: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo: Mapped[str] = mapped_column(String(10), nullable=False)
    descricao: Mapped[str] = mapped_column(String(120), nullable=False)
    natureza: Mapped[str] = mapped_column(String(1), nullable=False)
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))


class Categoria(AuditMixin, Base):
    __tablename__ = "categoria"
    __table_args__ = {"schema": SCHEMA}
    id_categoria: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_grupo: Mapped[int] = mapped_column(ForeignKey("financeiro.grupo.id_grupo"))
    codigo: Mapped[str] = mapped_column(String(20), nullable=False)
    descricao: Mapped[str] = mapped_column(String(120), nullable=False)
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))


class Subcategoria(AuditMixin, Base):
    __tablename__ = "subcategoria"
    __table_args__ = {"schema": SCHEMA}
    id_subcategoria: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_categoria: Mapped[int] = mapped_column(ForeignKey("financeiro.categoria.id_categoria"))
    codigo: Mapped[str] = mapped_column(String(30), nullable=False)
    descricao: Mapped[str] = mapped_column(String(150), nullable=False)
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))


class Classificacao(AuditMixin, Base):
    __tablename__ = "classificacao"
    __table_args__ = {"schema": SCHEMA}
    id_classificacao: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_subcategoria: Mapped[int] = mapped_column(
        ForeignKey("financeiro.subcategoria.id_subcategoria")
    )
    codigo: Mapped[str] = mapped_column(String(20), nullable=False)
    descricao: Mapped[str] = mapped_column(String(180), nullable=False)
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))
    gera_fluxo_caixa: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))
    gera_dre: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))


class Conta(AuditMixin, Base):
    __tablename__ = "conta"
    __table_args__ = {"schema": SCHEMA}
    id_conta: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_classificacao: Mapped[int] = mapped_column(
        ForeignKey("financeiro.classificacao.id_classificacao")
    )
    codigo: Mapped[str] = mapped_column(String(20), nullable=False)
    descricao: Mapped[str] = mapped_column(String(180), nullable=False)
    aceita_lancamento: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))


class CentroCusto(Base):
    __tablename__ = "centro_custo"
    __table_args__ = {"schema": SCHEMA}
    id_centro_custo: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo: Mapped[str | None] = mapped_column(String(20))
    descricao: Mapped[str] = mapped_column(String(150), nullable=False)
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))


class Banco(Base):
    __tablename__ = "banco"
    __table_args__ = {"schema": SCHEMA}
    id_banco: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo_banco: Mapped[str | None] = mapped_column(String(10))
    nome: Mapped[str] = mapped_column(String(120), nullable=False)
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))


class ContaBancaria(Base):
    __tablename__ = "conta_bancaria"
    __table_args__ = {"schema": SCHEMA}
    id_conta_bancaria: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_banco: Mapped[int] = mapped_column(ForeignKey("financeiro.banco.id_banco"))
    agencia: Mapped[str | None] = mapped_column(String(20))
    conta: Mapped[str | None] = mapped_column(String(30))
    digito: Mapped[str | None] = mapped_column(String(5))
    tipo: Mapped[str | None] = mapped_column(String(20))
    pix: Mapped[str | None] = mapped_column(String(150))
    saldo_inicial: Mapped[Decimal] = mapped_column(Numeric(15, 2), server_default=text("0"))
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))


class Lancamento(AuditMixin, Base):
    __tablename__ = "lancamento"
    __table_args__ = (
        UniqueConstraint("chave_idempotencia", name="uq_lancamento_chave_idempotencia"),
        CheckConstraint("valor_bruto > 0", name="ck_lancamento_f2_valor_bruto"),
        {"schema": SCHEMA},
    )
    id_lancamento: Mapped[int] = mapped_column(Integer, primary_key=True)
    numero: Mapped[str] = mapped_column(String(30), nullable=False)
    id_empresa: Mapped[int] = mapped_column(Integer, nullable=False)
    id_tipo_lancamento: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    id_status: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    id_conta: Mapped[int] = mapped_column(ForeignKey("financeiro.conta.id_conta"))
    id_cliente: Mapped[int | None] = mapped_column(Integer)
    id_fornecedor: Mapped[int | None] = mapped_column(Integer)
    id_conta_bancaria: Mapped[int | None] = mapped_column(Integer)
    id_forma_pagamento: Mapped[int | None] = mapped_column(Integer)
    id_tipo_documento: Mapped[int | None] = mapped_column(SmallInteger)
    id_venda_origem: Mapped[int | None] = mapped_column(ForeignKey("venda.id_venda"))
    chave_idempotencia: Mapped[str | None] = mapped_column(String(100))
    competencia: Mapped[date] = mapped_column(Date, nullable=False)
    emissao: Mapped[date] = mapped_column(Date, nullable=False)
    vencimento: Mapped[date] = mapped_column(Date, nullable=False)
    pagamento: Mapped[date | None] = mapped_column(Date)
    documento: Mapped[str | None] = mapped_column(String(100))
    descricao: Mapped[str | None] = mapped_column(String(300))
    observacao: Mapped[str | None] = mapped_column(Text)
    valor_bruto: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    desconto: Mapped[Decimal] = mapped_column(Numeric(15, 2), server_default=text("0"))
    acrescimo: Mapped[Decimal] = mapped_column(Numeric(15, 2), server_default=text("0"))
    juros: Mapped[Decimal] = mapped_column(Numeric(15, 2), server_default=text("0"))
    multa: Mapped[Decimal] = mapped_column(Numeric(15, 2), server_default=text("0"))
    valor_liquido: Mapped[Decimal] = mapped_column(
        Numeric(15, 2),
        Computed("valor_bruto - desconto + acrescimo + juros + multa", persisted=True),
    )
    valor_pago: Mapped[Decimal] = mapped_column(Numeric(15, 2), server_default=text("0"))
    saldo: Mapped[Decimal] = mapped_column(
        Numeric(15, 2),
        Computed("valor_bruto - desconto + acrescimo + juros + multa - valor_pago", persisted=True),
    )
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"))


class Parcela(Base):
    __tablename__ = "lancamento_parcela"
    __table_args__ = (
        UniqueConstraint("id_lancamento", "numero_parcela", name="uq_parcela_lancamento_numero"),
        {"schema": SCHEMA},
    )
    id_parcela: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_lancamento: Mapped[int] = mapped_column(ForeignKey("financeiro.lancamento.id_lancamento"))
    numero_parcela: Mapped[int] = mapped_column(Integer, nullable=False)
    vencimento: Mapped[date] = mapped_column(Date, nullable=False)
    valor: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    valor_pago: Mapped[Decimal] = mapped_column(Numeric(15, 2), server_default=text("0"))
    saldo: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    id_status: Mapped[int | None] = mapped_column(SmallInteger)
    observacao: Mapped[str | None] = mapped_column(Text)


class Pagamento(AuditMixin, Base):
    __tablename__ = "pagamento"
    __table_args__ = (
        UniqueConstraint("chave_idempotencia", name="uq_pagamento_chave_idempotencia"),
        {"schema": SCHEMA},
    )
    id_pagamento: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_parcela: Mapped[int] = mapped_column(ForeignKey("financeiro.lancamento_parcela.id_parcela"))
    id_conta_bancaria: Mapped[int] = mapped_column(Integer, nullable=False)
    id_forma_pagamento: Mapped[int] = mapped_column(Integer, nullable=False)
    data_pagamento: Mapped[date] = mapped_column(Date, nullable=False)
    valor: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    juros: Mapped[Decimal] = mapped_column(Numeric(15, 2), server_default=text("0"))
    desconto: Mapped[Decimal] = mapped_column(Numeric(15, 2), server_default=text("0"))
    multa: Mapped[Decimal] = mapped_column(Numeric(15, 2), server_default=text("0"))
    chave_idempotencia: Mapped[str | None] = mapped_column(String(100))
    id_pagamento_estornado: Mapped[int | None] = mapped_column(
        ForeignKey("financeiro.pagamento.id_pagamento")
    )
    documento: Mapped[str | None] = mapped_column(String(100))
    observacao: Mapped[str | None] = mapped_column(Text)


class Movimentacao(AuditMixin, Base):
    __tablename__ = "movimentacao_bancaria"
    __table_args__ = {"schema": SCHEMA}
    id_movimento: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_conta_bancaria: Mapped[int] = mapped_column(Integer, nullable=False)
    id_pagamento: Mapped[int | None] = mapped_column(Integer)
    id_tipo_movimentacao: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    data_movimento: Mapped[date | None] = mapped_column(Date)
    valor: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    saldo_anterior: Mapped[Decimal | None] = mapped_column(Numeric(15, 2))
    saldo_atual: Mapped[Decimal | None] = mapped_column(Numeric(15, 2))
    historico: Mapped[str | None] = mapped_column(Text)


class Conciliacao(Base):
    __tablename__ = "conciliacao_bancaria"
    __table_args__ = (
        UniqueConstraint("id_movimento", name="uq_conciliacao_movimento"),
        {"schema": SCHEMA},
    )
    id_conciliacao: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_movimento: Mapped[int] = mapped_column(Integer, nullable=False)
    data_conciliacao: Mapped[date | None] = mapped_column(Date)
    conciliado: Mapped[bool] = mapped_column(Boolean, server_default=text("false"))
    observacao: Mapped[str | None] = mapped_column(Text)


class PeriodoFinanceiro(AuditMixin, Base):
    __tablename__ = "periodo_financeiro"
    __table_args__ = (
        UniqueConstraint("competencia", name="uq_periodo_financeiro_competencia"),
        {"schema": SCHEMA},
    )
    id_periodo_financeiro: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    competencia: Mapped[date] = mapped_column(Date, nullable=False)
    fechado: Mapped[bool] = mapped_column(Boolean, server_default=text("false"), nullable=False)
    fechado_em: Mapped[datetime | None] = mapped_column(DateTime)


class Transferencia(AuditMixin, Base):
    __tablename__ = "transferencia"
    __table_args__ = (
        CheckConstraint("id_conta_origem <> id_conta_destino", name="ck_transferencia_contas"),
        UniqueConstraint("codigo", name="uq_transferencia_codigo"),
        {"schema": SCHEMA},
    )
    id_transferencia: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo: Mapped[str] = mapped_column(String(30), nullable=False)
    id_conta_origem: Mapped[int] = mapped_column(Integer, nullable=False)
    id_conta_destino: Mapped[int] = mapped_column(Integer, nullable=False)
    data_transferencia: Mapped[date] = mapped_column(Date, nullable=False)
    valor: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    id_movimento_saida: Mapped[int | None] = mapped_column(Integer)
    id_movimento_entrada: Mapped[int | None] = mapped_column(Integer)
    historico: Mapped[str | None] = mapped_column(Text)
    status: Mapped[str] = mapped_column(String(20), server_default=text("'PENDENTE'"))
