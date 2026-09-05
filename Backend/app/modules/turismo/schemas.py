"""Contratos Pydantic da API de Turismo."""

from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, Field, model_validator


class TurismoInput(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class TurismoOutput(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class SaidaCreate(TurismoInput):
    id_pacote: int = Field(gt=0)
    codigo: str = Field(min_length=1, max_length=30)
    data_inicio: date
    data_fim: date
    capacidade: int = Field(ge=0)

    @model_validator(mode="after")
    def validar_periodo(self) -> "SaidaCreate":
        if self.data_fim < self.data_inicio:
            raise ValueError("fim da saída não pode anteceder o início")
        return self


class SaidaResponse(TurismoOutput):
    id_saida: int
    id_pacote: int
    codigo: str
    data_inicio: date
    data_fim: date
    capacidade: int
    status: str
    versao: int


class DisponibilidadeResponse(TurismoOutput):
    id_saida: int
    capacidade: int
    vagas_bloqueadas: int
    vagas_confirmadas: int
    disponibilidade: int


class ReservaCreate(TurismoInput):
    codigo_reserva: str = Field(min_length=1, max_length=30)
    id_cliente: int = Field(gt=0)
    id_saida: int = Field(gt=0)
    quantidade_passageiros: int = Field(gt=0)
    valor_total: Decimal | None = Field(default=None, ge=0, max_digits=15, decimal_places=2)
    chave_idempotencia: str = Field(min_length=1, max_length=100)
    expira_em: datetime | None = None
    id_venda: int | None = Field(default=None, gt=0)
    id_item_venda: int | None = Field(default=None, gt=0)
    id_contrato: int | None = Field(default=None, gt=0)

    @model_validator(mode="after")
    def validar_expiracao(self) -> "ReservaCreate":
        if self.expira_em is not None and self.expira_em <= datetime.now():
            raise ValueError("expiração do bloqueio deve estar no futuro")
        return self


class ReservaResponse(TurismoOutput):
    id_reserva: int
    codigo_reserva: str
    id_cliente: int
    id_pacote: int
    id_saida: int | None
    data_reserva: date
    quantidade_passageiros: int
    valor_total: Decimal | None
    status: str
    versao: int


class ReservaAcao(TurismoInput):
    chave_idempotencia: str = Field(min_length=1, max_length=100)
