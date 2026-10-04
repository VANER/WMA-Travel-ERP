"""Contratos HTTP da configuracao operacional de Bike Tour."""

from datetime import datetime
from decimal import Decimal
from enum import StrEnum
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, model_validator

type Motivo = Literal[
    "SOLICITACAO",
    "CLIMA",
    "RECURSO_INDISPONIVEL",
    "ORIGEM_INVALIDA",
    "OPERACIONAL",
    "TRATAMENTO_CONCLUIDO",
]


class BikeTourInput(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class BikeTourOutput(BaseModel):
    model_config = ConfigDict(from_attributes=True)


class NivelBikeTour(StrEnum):
    INICIANTE = "INICIANTE"
    INTERMEDIARIO = "INTERMEDIARIO"
    AVANCADO = "AVANCADO"


class ProdutoCreate(BikeTourInput):
    id_produto: int = Field(gt=0)
    distancia_km: Decimal = Field(gt=0, max_digits=10, decimal_places=2)
    desnivel_m: Decimal = Field(ge=0, max_digits=10, decimal_places=2)
    nivel: NivelBikeTour
    chave_idempotencia: str = Field(min_length=1, max_length=100)


class ProdutoUpdate(BikeTourInput):
    distancia_km: Decimal | None = Field(default=None, gt=0, max_digits=10, decimal_places=2)
    desnivel_m: Decimal | None = Field(default=None, ge=0, max_digits=10, decimal_places=2)
    nivel: NivelBikeTour | None = None
    ativo: bool | None = None
    versao_esperada: int = Field(ge=1)
    chave_idempotencia: str = Field(min_length=1, max_length=100)

    @model_validator(mode="after")
    def exige_alteracao(self) -> "ProdutoUpdate":
        if any(getattr(self, field) is None for field in self.model_fields_set):
            raise ValueError("atributos de atualizacao nao aceitam null")
        if all(
            value is None for value in (self.distancia_km, self.desnivel_m, self.nivel, self.ativo)
        ):
            raise ValueError("ao menos um atributo deve ser alterado")
        return self


class ProdutoResponse(BikeTourOutput):
    id_produto_bike_tour: int
    id_produto: int
    distancia_km: Decimal
    desnivel_m: Decimal
    nivel: NivelBikeTour
    ativo: bool
    versao: int
    created_at: datetime
    updated_at: datetime | None


class EventoCreate(BikeTourInput):
    id_saida: int = Field(gt=0)
    inicio: datetime
    fim: datetime
    capacidade: int = Field(ge=1, le=1000)
    chave_idempotencia: str = Field(min_length=1, max_length=100)

    @model_validator(mode="after")
    def valida_periodo(self) -> "EventoCreate":
        if self.inicio.tzinfo is None or self.fim.tzinfo is None:
            raise ValueError("inicio e fim devem informar fuso horario")
        if self.inicio >= self.fim:
            raise ValueError("inicio deve anteceder fim")
        return self


class EventoUpdate(BikeTourInput):
    inicio: datetime | None = None
    fim: datetime | None = None
    capacidade: int | None = Field(default=None, ge=1, le=1000)
    versao_esperada: int = Field(ge=1)
    chave_idempotencia: str = Field(min_length=1, max_length=100)

    @model_validator(mode="after")
    def exige_alteracao(self) -> "EventoUpdate":
        if any(getattr(self, field) is None for field in self.model_fields_set):
            raise ValueError("atributos de atualizacao nao aceitam null")
        if self.inicio is None and self.fim is None and self.capacidade is None:
            raise ValueError("ao menos um atributo deve ser alterado")
        if (self.inicio is None) != (self.fim is None):
            raise ValueError("inicio e fim devem ser informados juntos")
        if (
            self.inicio is not None
            and self.fim is not None
            and (self.inicio.tzinfo is None or self.fim.tzinfo is None or self.inicio >= self.fim)
        ):
            raise ValueError("periodo invalido")
        return self


class EventoAcaoRequest(BikeTourInput):
    acao: str = Field(pattern="^(ABRIR|INICIAR|CANCELAR|CONCLUIR)$")
    motivo: Motivo | None = None
    versao_esperada: int = Field(ge=1)
    chave_idempotencia: str = Field(min_length=1, max_length=100)


class EventoResponse(BikeTourOutput):
    id_evento_bike_tour: int
    id_saida: int
    inicio: datetime
    fim: datetime
    capacidade: int
    status: Literal["PLANEJADO", "ABERTO", "EM_EXECUCAO", "CONCLUIDO", "CANCELADO"]
    versao: int
    created_at: datetime
    updated_at: datetime | None
