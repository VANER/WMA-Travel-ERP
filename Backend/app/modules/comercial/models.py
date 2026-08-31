"""Models SQLAlchemy do domínio Comercial."""

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


class LegacyAuditColumnsMixin:
    """Colunas de auditoria opcionais das estruturas da baseline."""

    created_at: Mapped[datetime | None] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=True
    )
    updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    created_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    updated_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    deleted_by: Mapped[str | None] = mapped_column(String(100), nullable=True)
    versao: Mapped[int | None] = mapped_column(Integer, server_default=text("1"), nullable=True)


class AuditColumnsMixin(LegacyAuditColumnsMixin):
    """Colunas obrigatórias das estruturas comerciais da Fase 2."""

    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )
    versao: Mapped[int] = mapped_column(Integer, server_default=text("1"), nullable=False)


class OrigemLead(LegacyAuditColumnsMixin, Base):
    """Canal de aquisição de um lead."""

    __tablename__ = "origem_lead"

    id_origem: Mapped[int] = mapped_column(Integer, primary_key=True)
    codigo: Mapped[str] = mapped_column(String(30), nullable=False)
    descricao: Mapped[str] = mapped_column(String(100), nullable=False)
    tipo: Mapped[str | None] = mapped_column(String(50), nullable=True)
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"), nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )


class Lead(LegacyAuditColumnsMixin, Base):
    """Contato comercial ainda não qualificado."""

    __tablename__ = "lead"

    id_lead: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_origem: Mapped[int | None] = mapped_column(
        ForeignKey("origem_lead.id_origem", name="fk_lead_origem"), nullable=True
    )
    id_cliente: Mapped[int | None] = mapped_column(
        ForeignKey("cliente.id_cliente", name="fk_lead_cliente"), nullable=True
    )
    nome: Mapped[str] = mapped_column(String(150), nullable=False)
    email: Mapped[str | None] = mapped_column(String(150), nullable=True)
    telefone: Mapped[str | None] = mapped_column(String(30), nullable=True)
    cidade: Mapped[str | None] = mapped_column(String(100), nullable=True)
    interesse: Mapped[str | None] = mapped_column(String(150), nullable=True)
    valor_estimado: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    status: Mapped[str | None] = mapped_column(
        String(30), server_default=text("'NOVO'"), nullable=True
    )
    data_cadastro: Mapped[date | None] = mapped_column(
        Date, server_default=text("CURRENT_DATE"), nullable=True
    )


class InteracaoLead(Base):
    """Registro cronológico de contato com um lead."""

    __tablename__ = "interacao_lead"

    id_interacao: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_lead: Mapped[int] = mapped_column(
        ForeignKey("lead.id_lead", name="fk_interacao_lead"), nullable=False
    )
    tipo: Mapped[str | None] = mapped_column(String(50), nullable=True)
    descricao: Mapped[str | None] = mapped_column(Text, nullable=True)
    data_interacao: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )
    responsavel: Mapped[str | None] = mapped_column(String(100), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=False
    )


class FunilVenda(LegacyAuditColumnsMixin, Base):
    """Histórico legado de movimentação de lead no funil."""

    __tablename__ = "funil_vendas"

    id_funil: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_lead: Mapped[int] = mapped_column(
        ForeignKey("lead.id_lead", name="fk_funil_lead"), nullable=False
    )
    etapa: Mapped[str | None] = mapped_column(String(50), nullable=True)
    probabilidade: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
    valor_negociacao: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    data_movimento: Mapped[date | None] = mapped_column(
        Date, server_default=text("CURRENT_DATE"), nullable=True
    )


class Operadora(AuditColumnsMixin, Base):
    """Papel comercial atribuído a um fornecedor corporativo."""

    __tablename__ = "operadora"
    __table_args__ = (
        UniqueConstraint("id_fornecedor", name="uq_operadora_id_fornecedor"),
        UniqueConstraint("codigo", name="uq_operadora_codigo"),
    )

    id_operadora: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_fornecedor: Mapped[int] = mapped_column(
        ForeignKey("fornecedor.id_fornecedor", name="fk_operadora_fornecedor"), nullable=False
    )
    codigo: Mapped[str] = mapped_column(String(30), nullable=False)
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"), nullable=False)


class Oportunidade(AuditColumnsMixin, Base):
    """Lead qualificado acompanhado pelo pipeline comercial."""

    __tablename__ = "oportunidade"
    __table_args__ = (
        CheckConstraint(
            "probabilidade >= 0 AND probabilidade <= 100",
            name="ck_oportunidade_probabilidade",
        ),
        CheckConstraint("valor_estimado >= 0", name="ck_oportunidade_valor_estimado"),
        UniqueConstraint("id_lead", name="uq_oportunidade_id_lead"),
    )

    id_oportunidade: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_lead: Mapped[int] = mapped_column(
        ForeignKey("lead.id_lead", name="fk_oportunidade_lead"), nullable=False
    )
    id_cliente: Mapped[int | None] = mapped_column(
        ForeignKey("cliente.id_cliente", name="fk_oportunidade_cliente"), nullable=True
    )
    titulo: Mapped[str] = mapped_column(String(150), nullable=False)
    etapa: Mapped[str] = mapped_column(
        String(30), server_default=text("'QUALIFICACAO'"), nullable=False
    )
    probabilidade: Mapped[Decimal] = mapped_column(
        Numeric(5, 2), server_default=text("0"), nullable=False
    )
    valor_estimado: Mapped[Decimal] = mapped_column(
        Numeric(15, 2), server_default=text("0"), nullable=False
    )
    status: Mapped[str] = mapped_column(String(20), server_default=text("'ABERTA'"), nullable=False)
    data_fechamento_prevista: Mapped[date | None] = mapped_column(Date, nullable=True)


class Proposta(AuditColumnsMixin, Base):
    """Oferta comercial emitida para uma oportunidade."""

    __tablename__ = "proposta"
    __table_args__ = (
        CheckConstraint("data_validade >= data_emissao", name="ck_proposta_validade"),
        CheckConstraint(
            "valor_bruto >= 0 AND desconto >= 0 AND valor_liquido >= 0",
            name="ck_proposta_valores",
        ),
        UniqueConstraint("numero", name="uq_proposta_numero"),
    )

    id_proposta: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_oportunidade: Mapped[int] = mapped_column(
        ForeignKey("oportunidade.id_oportunidade", name="fk_proposta_oportunidade"),
        nullable=False,
    )
    id_cliente: Mapped[int] = mapped_column(
        ForeignKey("cliente.id_cliente", name="fk_proposta_cliente"), nullable=False
    )
    numero: Mapped[str] = mapped_column(String(30), nullable=False)
    data_emissao: Mapped[date] = mapped_column(
        Date, server_default=text("CURRENT_DATE"), nullable=False
    )
    data_validade: Mapped[date] = mapped_column(Date, nullable=False)
    status: Mapped[str] = mapped_column(
        String(20), server_default=text("'RASCUNHO'"), nullable=False
    )
    valor_bruto: Mapped[Decimal] = mapped_column(
        Numeric(15, 2), server_default=text("0"), nullable=False
    )
    desconto: Mapped[Decimal] = mapped_column(
        Numeric(15, 2), server_default=text("0"), nullable=False
    )
    valor_liquido: Mapped[Decimal] = mapped_column(
        Numeric(15, 2), server_default=text("0"), nullable=False
    )


class ItemProposta(AuditColumnsMixin, Base):
    """Linha monetária de uma proposta."""

    __tablename__ = "item_proposta"
    __table_args__ = (
        CheckConstraint("quantidade > 0", name="ck_item_proposta_quantidade"),
        CheckConstraint(
            "valor_unitario >= 0 AND desconto >= 0 AND valor_total >= 0",
            name="ck_item_proposta_valores",
        ),
    )

    id_item_proposta: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_proposta: Mapped[int] = mapped_column(
        ForeignKey("proposta.id_proposta", name="fk_item_proposta_proposta"), nullable=False
    )
    descricao: Mapped[str] = mapped_column(String(200), nullable=False)
    quantidade: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)
    valor_unitario: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)
    desconto: Mapped[Decimal] = mapped_column(
        Numeric(15, 2), server_default=text("0"), nullable=False
    )
    valor_total: Mapped[Decimal] = mapped_column(Numeric(15, 2), nullable=False)


class CondicaoComercial(AuditColumnsMixin, Base):
    """Condição financeira ou comercial aplicável a uma proposta."""

    __tablename__ = "condicao_comercial"
    __table_args__ = (
        CheckConstraint(
            "percentual IS NULL OR (percentual >= 0 AND percentual <= 100)",
            name="ck_condicao_comercial_percentual",
        ),
        CheckConstraint("valor IS NULL OR valor >= 0", name="ck_condicao_comercial_valor"),
        CheckConstraint(
            "data_fim IS NULL OR data_fim >= data_inicio",
            name="ck_condicao_comercial_vigencia",
        ),
    )

    id_condicao_comercial: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_proposta: Mapped[int] = mapped_column(
        ForeignKey("proposta.id_proposta", name="fk_condicao_comercial_proposta"), nullable=False
    )
    tipo: Mapped[str] = mapped_column(String(30), nullable=False)
    descricao: Mapped[str] = mapped_column(String(200), nullable=False)
    percentual: Mapped[Decimal | None] = mapped_column(Numeric(5, 2), nullable=True)
    valor: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    data_inicio: Mapped[date] = mapped_column(Date, nullable=False)
    data_fim: Mapped[date | None] = mapped_column(Date, nullable=True)
    ativo: Mapped[bool] = mapped_column(Boolean, server_default=text("true"), nullable=False)


class Venda(LegacyAuditColumnsMixin, Base):
    """Conversão comercial de uma proposta aceita."""

    __tablename__ = "venda"
    __table_args__ = (UniqueConstraint("id_proposta", name="uq_venda_id_proposta"),)

    id_venda: Mapped[int] = mapped_column(Integer, primary_key=True)
    numero_venda: Mapped[str] = mapped_column(String(30), nullable=False)
    id_cliente: Mapped[int] = mapped_column(
        ForeignKey("cliente.id_cliente", name="fk_venda_cliente"), nullable=False
    )
    id_proposta: Mapped[int | None] = mapped_column(
        ForeignKey("proposta.id_proposta", name="fk_venda_proposta"), nullable=True
    )
    data_venda: Mapped[date] = mapped_column(Date, nullable=False)
    valor_bruto: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    desconto: Mapped[Decimal | None] = mapped_column(
        Numeric(15, 2), server_default=text("0"), nullable=True
    )
    valor_liquido: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    status: Mapped[str | None] = mapped_column(String(30), nullable=True)


class ItemVenda(LegacyAuditColumnsMixin, Base):
    """Produto turístico referenciado por uma venda."""

    __tablename__ = "item_venda"

    id_item: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_venda: Mapped[int] = mapped_column(
        ForeignKey("venda.id_venda", name="fk_item_venda"), nullable=False
    )
    id_produto: Mapped[int] = mapped_column(Integer, nullable=False)
    quantidade: Mapped[int | None] = mapped_column(Integer, server_default=text("1"), nullable=True)
    valor_unitario: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    valor_total: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)


class Contrato(Base):
    """Instrumento contratual ligado à venda e, opcionalmente, à reserva."""

    __tablename__ = "contrato"

    id_contrato: Mapped[int] = mapped_column(Integer, primary_key=True)
    id_documento: Mapped[int] = mapped_column(
        ForeignKey("documento.id_documento", name="fk_contrato_documento"), nullable=False
    )
    id_venda: Mapped[int | None] = mapped_column(
        ForeignKey("venda.id_venda", name="fk_contrato_venda"), nullable=True
    )
    id_reserva: Mapped[int | None] = mapped_column(Integer, nullable=True)
    parte_contratante: Mapped[str | None] = mapped_column(String(150), nullable=True)
    parte_contratada: Mapped[str | None] = mapped_column(String(150), nullable=True)
    data_inicio: Mapped[date | None] = mapped_column(Date, nullable=True)
    data_fim: Mapped[date | None] = mapped_column(Date, nullable=True)
    valor_contrato: Mapped[Decimal | None] = mapped_column(Numeric(15, 2), nullable=True)
    tipo_contrato: Mapped[str | None] = mapped_column(String(50), nullable=True)
    status: Mapped[str | None] = mapped_column(String(30), nullable=True)
    created_at: Mapped[datetime | None] = mapped_column(
        DateTime, server_default=text("CURRENT_TIMESTAMP"), nullable=True
    )
    updated_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
    deleted_at: Mapped[datetime | None] = mapped_column(DateTime, nullable=True)
