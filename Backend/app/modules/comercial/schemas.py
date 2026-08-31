"""Contratos Pydantic da API Comercial."""

from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class ComercialInput(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class ComercialOutput(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class AuditResponse(ComercialOutput):
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None
    created_by: str | None = None
    updated_by: str | None = None
    deleted_by: str | None = None
    versao: int | None = None


class LeadCreate(ComercialInput):
    id_origem: int | None = Field(default=None, gt=0)
    nome: str = Field(min_length=1, max_length=150)
    email: str | None = Field(default=None, max_length=150)
    telefone: str | None = Field(default=None, max_length=30)
    cidade: str | None = Field(default=None, max_length=100)
    interesse: str | None = Field(default=None, max_length=150)
    valor_estimado: Decimal | None = Field(default=None, ge=0, max_digits=15, decimal_places=2)


class LeadResponse(LeadCreate, AuditResponse):
    id_lead: int
    id_cliente: int | None = None
    status: str | None
    data_cadastro: date | None


class InteracaoLeadCreate(ComercialInput):
    id_lead: int = Field(gt=0)
    tipo: str | None = Field(default=None, max_length=50)
    descricao: str | None = None
    responsavel: str | None = Field(default=None, max_length=100)


class InteracaoLeadResponse(InteracaoLeadCreate, ComercialOutput):
    id_interacao: int
    data_interacao: datetime
    created_at: datetime


class OperadoraCreate(ComercialInput):
    id_fornecedor: int = Field(gt=0)
    codigo: str = Field(min_length=1, max_length=30)
    ativo: bool = True


class OperadoraResponse(OperadoraCreate, AuditResponse):
    id_operadora: int


class OportunidadeCreate(ComercialInput):
    id_lead: int = Field(gt=0)
    id_cliente: int | None = Field(default=None, gt=0)
    titulo: str = Field(min_length=1, max_length=150)
    etapa: str = Field(default="QUALIFICACAO", min_length=1, max_length=30)
    probabilidade: Decimal = Field(
        default=Decimal("0"), ge=0, le=100, max_digits=5, decimal_places=2
    )
    valor_estimado: Decimal = Field(default=Decimal("0"), ge=0, max_digits=15, decimal_places=2)
    data_fechamento_prevista: date | None = None


class OportunidadeResponse(OportunidadeCreate, AuditResponse):
    id_oportunidade: int
    status: str


class PropostaCreate(ComercialInput):
    id_oportunidade: int = Field(gt=0)
    id_cliente: int = Field(gt=0)
    numero: str = Field(min_length=1, max_length=30)
    data_emissao: date
    data_validade: date

    @model_validator(mode="after")
    def validar_vigencia(self) -> "PropostaCreate":
        if self.data_validade < self.data_emissao:
            raise ValueError("data_validade deve ser igual ou posterior à emissão")
        return self


class PropostaResponse(PropostaCreate, AuditResponse):
    id_proposta: int
    status: str
    valor_bruto: Decimal
    desconto: Decimal | None
    valor_liquido: Decimal


class ItemPropostaCreate(ComercialInput):
    id_proposta: int = Field(gt=0)
    descricao: str = Field(min_length=1, max_length=200)
    quantidade: Decimal = Field(gt=0, max_digits=10, decimal_places=2)
    valor_unitario: Decimal = Field(ge=0, max_digits=15, decimal_places=2)
    desconto: Decimal = Field(default=Decimal("0"), ge=0, max_digits=15, decimal_places=2)


class ItemPropostaResponse(ItemPropostaCreate, AuditResponse):
    id_item_proposta: int
    valor_total: Decimal


class CondicaoComercialCreate(ComercialInput):
    id_proposta: int = Field(gt=0)
    tipo: str = Field(min_length=1, max_length=30)
    descricao: str = Field(min_length=1, max_length=200)
    percentual: Decimal | None = Field(default=None, ge=0, le=100)
    valor: Decimal | None = Field(default=None, ge=0, max_digits=15, decimal_places=2)
    data_inicio: date
    data_fim: date | None = None
    ativo: bool = True

    @model_validator(mode="after")
    def validar_vigencia(self) -> "CondicaoComercialCreate":
        if self.data_fim is not None and self.data_fim < self.data_inicio:
            raise ValueError("data_fim deve ser igual ou posterior ao início")
        return self


class CondicaoComercialResponse(CondicaoComercialCreate, AuditResponse):
    id_condicao_comercial: int


class TransicaoStatus(ComercialInput):
    status: str = Field(min_length=1, max_length=30)


class VendaCreate(ComercialInput):
    id_proposta: int = Field(gt=0)
    numero_venda: str = Field(min_length=1, max_length=30)
    data_venda: date


class VendaResponse(AuditResponse):
    id_venda: int
    numero_venda: str
    id_cliente: int
    id_proposta: int | None
    data_venda: date
    valor_bruto: Decimal | None
    desconto: Decimal
    valor_liquido: Decimal | None
    status: str | None


class ContratoCreate(ComercialInput):
    id_documento: int = Field(gt=0)
    id_venda: int | None = Field(default=None, gt=0)
    id_reserva: int | None = Field(default=None, gt=0)
    parte_contratante: str | None = Field(default=None, max_length=150)
    parte_contratada: str | None = Field(default=None, max_length=150)
    data_inicio: date | None = None
    data_fim: date | None = None
    valor_contrato: Decimal | None = Field(default=None, ge=0, max_digits=15, decimal_places=2)
    tipo_contrato: str | None = Field(default=None, max_length=50)
    status: Literal["RASCUNHO", "ATIVO", "ENCERRADO", "CANCELADO"] = "RASCUNHO"

    @model_validator(mode="after")
    def validar_vigencia(self) -> "ContratoCreate":
        if (
            self.data_inicio is not None
            and self.data_fim is not None
            and self.data_fim < self.data_inicio
        ):
            raise ValueError("data_fim deve ser igual ou posterior ao início")
        return self


class ContratoResponse(ContratoCreate, ComercialOutput):
    id_contrato: int
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None
