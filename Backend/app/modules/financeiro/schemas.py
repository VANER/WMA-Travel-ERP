"""Contratos Pydantic da API Financeira."""

from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class FinanceiroInput(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class FinanceiroOutput(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class ParcelaCreate(FinanceiroInput):
    vencimento: date
    valor: Decimal = Field(gt=0, max_digits=15, decimal_places=2)


class LancamentoCreate(FinanceiroInput):
    numero: str = Field(min_length=1, max_length=30)
    id_empresa: int = Field(gt=0)
    id_tipo_lancamento: int = Field(gt=0)
    id_status: int = Field(gt=0)
    id_conta: int = Field(gt=0)
    id_cliente: int | None = Field(default=None, gt=0)
    id_fornecedor: int | None = Field(default=None, gt=0)
    competencia: date
    emissao: date
    vencimento: date
    valor_bruto: Decimal = Field(gt=0, max_digits=15, decimal_places=2)
    desconto: Decimal = Field(default=Decimal("0"), ge=0, max_digits=15, decimal_places=2)
    acrescimo: Decimal = Field(default=Decimal("0"), ge=0, max_digits=15, decimal_places=2)
    juros: Decimal = Field(default=Decimal("0"), ge=0, max_digits=15, decimal_places=2)
    multa: Decimal = Field(default=Decimal("0"), ge=0, max_digits=15, decimal_places=2)
    descricao: str | None = Field(default=None, max_length=300)
    chave_idempotencia: str | None = Field(default=None, min_length=1, max_length=100)
    parcelas: list[ParcelaCreate] = Field(min_length=1)

    @model_validator(mode="after")
    def validar_datas_e_total(self) -> "LancamentoCreate":
        if self.competencia < self.emissao or self.vencimento < self.emissao:
            raise ValueError("competência e vencimento não podem anteceder a emissão")
        liquido = self.valor_bruto - self.desconto + self.acrescimo + self.juros + self.multa
        if sum((item.valor for item in self.parcelas), Decimal("0")) != liquido:
            raise ValueError("a soma das parcelas deve corresponder ao valor líquido")
        return self


class LancamentoResponse(FinanceiroOutput):
    id_lancamento: int
    numero: str
    id_empresa: int
    id_tipo_lancamento: int
    id_status: int
    id_conta: int
    id_cliente: int | None
    id_fornecedor: int | None
    id_venda_origem: int | None
    chave_idempotencia: str | None
    competencia: date
    emissao: date
    vencimento: date
    valor_bruto: Decimal
    desconto: Decimal
    acrescimo: Decimal
    juros: Decimal
    multa: Decimal
    valor_liquido: Decimal
    valor_pago: Decimal
    saldo: Decimal


class PagamentoCreate(FinanceiroInput):
    id_conta_bancaria: int = Field(gt=0)
    id_forma_pagamento: int = Field(gt=0)
    id_tipo_movimentacao: int = Field(gt=0)
    data_pagamento: date
    valor: Decimal = Field(gt=0, max_digits=15, decimal_places=2)
    juros: Decimal = Field(default=Decimal("0"), ge=0)
    desconto: Decimal = Field(default=Decimal("0"), ge=0)
    multa: Decimal = Field(default=Decimal("0"), ge=0)
    chave_idempotencia: str = Field(min_length=1, max_length=100)
    documento: str | None = Field(default=None, max_length=100)


class PagamentoResponse(FinanceiroOutput):
    id_pagamento: int
    id_parcela: int
    id_conta_bancaria: int
    data_pagamento: date
    valor: Decimal
    juros: Decimal
    desconto: Decimal
    multa: Decimal
    chave_idempotencia: str | None
    id_pagamento_estornado: int | None


class TransferenciaCreate(FinanceiroInput):
    id_conta_origem: int = Field(gt=0)
    id_conta_destino: int = Field(gt=0)
    id_tipo_saida: int = Field(gt=0)
    id_tipo_entrada: int = Field(gt=0)
    data_transferencia: date
    valor: Decimal = Field(gt=0, max_digits=15, decimal_places=2)
    chave_idempotencia: str = Field(min_length=1, max_length=100)
    observacao: str | None = None

    @model_validator(mode="after")
    def validar_contas(self) -> "TransferenciaCreate":
        if self.id_conta_origem == self.id_conta_destino:
            raise ValueError("contas de origem e destino devem ser diferentes")
        return self


class TransferenciaResponse(FinanceiroOutput):
    id_transferencia: int
    id_conta_origem: int
    id_conta_destino: int
    data_transferencia: date
    valor: Decimal
    codigo: str


class ConciliacaoCreate(FinanceiroInput):
    data_conciliacao: date
    observacao: str | None = None


class ConciliacaoResponse(FinanceiroOutput):
    id_conciliacao: int
    id_movimento: int
    data_conciliacao: date | None
    conciliado: bool
    observacao: str | None


class VendaFinanceiroCreate(FinanceiroInput):
    id_conta: int = Field(gt=0)
    id_tipo_lancamento: int = Field(gt=0)
    id_status: int = Field(gt=0)
    emissao: date
    vencimentos: list[date] = Field(min_length=1)


class PeriodoCreate(FinanceiroInput):
    competencia: date


class PeriodoResponse(FinanceiroOutput):
    id_periodo_financeiro: int
    competencia: date
    fechado: bool
    fechado_em: datetime | None
