"""Contratos dos comandos operacionais Bike Tour, sem dados pessoais."""

from datetime import datetime
from decimal import Decimal
from typing import Annotated, Literal, Self
from uuid import UUID

from pydantic import AwareDatetime, Field, model_validator

from app.modules.biketour.schemas import BikeTourInput, BikeTourOutput
from app.modules.biketour.schemas import Motivo as Motivo

type TipoRecurso = Literal["BICICLETA", "EQUIPAMENTO", "GUIA", "VEICULO"]
type Id = Annotated[int, Field(gt=0)]


class Comando(BikeTourInput):
    chave_idempotencia: str = Field(min_length=1, max_length=100)


class Alteracao(Comando):
    versao_esperada: int = Field(ge=1)


class RecursoCreate(Comando):
    codigo: str = Field(min_length=1, max_length=30)
    tipo: TipoRecurso
    id_ativo: Id | None = None
    id_guia: Id | None = None
    id_transporte: Id | None = None

    @model_validator(mode="after")
    def validar_origem(self) -> Self:
        if self.tipo in {"BICICLETA", "EQUIPAMENTO"}:
            valido = self.id_guia is None and self.id_transporte is None
        elif self.tipo == "GUIA":
            valido = (
                self.id_guia is not None and self.id_ativo is None and self.id_transporte is None
            )
        else:
            valido = (
                self.id_transporte is not None and self.id_ativo is None and self.id_guia is None
            )
        if not valido:
            raise ValueError("origem incompativel com o tipo de recurso")
        return self


class RecursoUpdate(Alteracao):
    status: Literal["DISPONIVEL", "INDISPONIVEL", "MANUTENCAO", "INATIVO"]


class RecursosInscricao(BikeTourInput):
    id_bicicleta: Id
    ids_equipamentos: list[Id] = Field(default_factory=list, max_length=20)

    @model_validator(mode="after")
    def validar_unicidade(self) -> Self:
        ids = [self.id_bicicleta, *self.ids_equipamentos]
        if len(ids) != len(set(ids)):
            raise ValueError("recursos devem ser distintos")
        return self


class InscricaoCreate(RecursosInscricao, Comando):
    id_reserva: Id
    id_passageiro: Id
    papel: Literal["PARTICIPANTE", "CICLISTA", "ACOMPANHANTE"]
    versao_esperada: int | None = Field(default=None, ge=1)


class InscricaoAcao(Alteracao):
    acao: Literal["CONFIRMAR", "CANCELAR", "PRESENCA", "NO_SHOW", "CONCLUIR"]
    motivo: Motivo | None = None


class Reacomodacao(RecursosInscricao, Alteracao):
    pass


class PontoInput(BikeTourInput):
    ordem: int = Field(gt=0)
    id_localidade: Id
    distancia_km: Decimal = Field(ge=0, max_digits=10, decimal_places=2)


class PontosRequest(Alteracao):
    pontos: list[PontoInput] = Field(min_length=2, max_length=100)

    @model_validator(mode="after")
    def validar_ordem(self) -> Self:
        pontos = sorted(self.pontos, key=lambda ponto: ponto.ordem)
        if len({p.ordem for p in pontos}) != len(pontos) or any(
            a.distancia_km >= b.distancia_km for a, b in zip(pontos, pontos[1:], strict=False)
        ):
            raise ValueError("ordem e distancia dos pontos devem ser crescentes")
        self.pontos = pontos
        return self


class GuiaInput(BikeTourInput):
    id_recurso: Id
    papel: Literal["LIDER", "APOIO"]


class ApoioInput(BikeTourInput):
    id_recurso: Id
    finalidade: Literal["TRANSPORTE", "APOIO", "MATERIAL"]


class EquipeRequest(Alteracao):
    equipe: list[GuiaInput] = Field(max_length=100)

    @model_validator(mode="after")
    def validar_equipe(self) -> Self:
        if (
            len({p.id_recurso for p in self.equipe}) != len(self.equipe)
            or sum(p.papel == "LIDER" for p in self.equipe) > 1
        ):
            raise ValueError("equipe duplicada ou mais de um lider")
        return self


class LogisticaRequest(Alteracao):
    apoio: list[ApoioInput] = Field(max_length=100)

    @model_validator(mode="after")
    def validar_apoio(self) -> Self:
        if len({p.id_recurso for p in self.apoio}) != len(self.apoio):
            raise ValueError("recurso de apoio duplicado")
        return self


class PassagemCreate(Alteracao):
    id_ponto: Id
    instante: AwareDatetime


class OcorrenciaCreate(Comando):
    id_inscricao: Id | None = None
    tipo: Literal["ATRASO", "MECANICA", "INTERRUPCAO", "OUTRA"]
    gravidade: Literal["BAIXA", "MEDIA", "ALTA"]
    motivo: Motivo


class OcorrenciaUpdate(Alteracao):
    status: Literal["EM_ANALISE", "RESOLVIDA", "DESCARTADA"]
    motivo: Motivo


class Reconciliacao(Alteracao):
    cursor: int = Field(default=0, ge=0)
    limite: int = Field(default=100, ge=1, le=100)


class AvaliacaoCreate(Alteracao):
    nota: int = Field(ge=1, le=5, strict=True)


class TratamentoRequest(Alteracao):
    referencia_tratamento: str = Field(min_length=1, max_length=100)
    motivo: Motivo


class RegistroResponse(BikeTourOutput):
    id: int
    versao: int
    created_at: datetime
    updated_at: datetime | None


class RecursoResponse(RegistroResponse):
    codigo: str
    tipo: TipoRecurso
    status: str
    id_ativo: int | None
    id_guia: int | None
    id_transporte: int | None


class InscricaoResponse(RegistroResponse):
    id_evento_bike_tour: int
    id_reserva: int
    id_passageiro: int
    papel: str
    status: str
    expira_em: datetime | None
    alocacoes: list[int]
    origem_valida: bool


class PontoResponse(RegistroResponse):
    id_evento_bike_tour: int
    ordem: int
    id_localidade: int
    distancia_km: Decimal


class EquipeResponse(RegistroResponse):
    id_evento_bike_tour: int
    id_recurso_bike_tour: int
    papel: str


class LogisticaResponse(RegistroResponse):
    id_evento_bike_tour: int
    id_recurso_bike_tour: int
    finalidade: str


class PassagemResponse(RegistroResponse):
    id_inscricao_bike_tour: int
    id_ponto_controle_bike_tour: int
    instante: datetime


class OcorrenciaResponse(RegistroResponse):
    id_evento_bike_tour: int
    id_inscricao_bike_tour: int | None
    tipo: str
    gravidade: str
    status: str
    motivo: str


class AvaliacaoResponse(RegistroResponse):
    id_inscricao_bike_tour: int
    nota: int


class PendenciaResponse(RegistroResponse):
    id_evento_bike_tour: int
    id_inscricao_bike_tour: int | None
    id_operacao_bike_tour: int
    tipo: str
    status: str
    motivo: str
    referencia_tratamento: str | None


class ReconciliacaoResponse(BikeTourOutput):
    id_evento_bike_tour: int
    tratadas: list[int]
    proximo_cursor: int | None


class ExpiracaoResponse(BikeTourOutput):
    id_evento_bike_tour: int
    expiradas: list[int]


class OrigemResponse(BikeTourOutput):
    id_reserva: int
    id_venda: int | None
    id_item_venda: int | None
    id_contrato: int | None
    origem_valida: bool


class DisponibilidadeBikeTourResponse(BikeTourOutput):
    id_evento_bike_tour: int
    capacidade: int
    comprometidas: int
    saldo: int
    recursos: list[RecursoResponse]


class RelatorioEventoResponse(BikeTourOutput):
    id_evento_bike_tour: int
    inscricoes: dict[str, int]
    ids_inscricoes: list[int]
    passagens: int
    ocorrencias: dict[str, int]


class AuditoriaResponse(BikeTourOutput):
    id: int
    ator: int
    operacao: str
    instante: datetime
    correlation_id: UUID
    status_http: int
