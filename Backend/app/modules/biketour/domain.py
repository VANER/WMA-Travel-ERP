"""Regras operacionais puras de A2/A5, independentes de ORM e HTTP."""

from collections.abc import Iterable
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from app.modules.biketour.errors import BikeTourError

INSCRICAO_TRANSICOES: dict[str, frozenset[str]] = {
    "PENDENTE": frozenset({"CONFIRMADA", "EXPIRADA", "CANCELADA"}),
    "CONFIRMADA": frozenset({"PRESENTE", "NO_SHOW", "CANCELADA"}),
    "PRESENTE": frozenset({"CONCLUIDA", "CANCELADA"}),
}
EVENTO_TRANSICOES: dict[str, frozenset[str]] = {
    "PLANEJADO": frozenset({"ABERTO", "CANCELADO"}),
    "ABERTO": frozenset({"EM_EXECUCAO", "CANCELADO"}),
    "EM_EXECUCAO": frozenset({"CONCLUIDO", "CANCELADO"}),
}
OCORRENCIA_TRANSICOES: dict[str, frozenset[str]] = {
    "ABERTA": frozenset({"EM_ANALISE"}),
    "EM_ANALISE": frozenset({"RESOLVIDA", "DESCARTADA"}),
}


def validar_transicao_inscricao(atual: str, destino: str) -> None:
    if destino not in INSCRICAO_TRANSICOES.get(atual, frozenset()):
        raise BikeTourError(409, "BT_TRANSICAO_INSCRICAO_INVALIDA")


def validar_transicao_evento(atual: str, destino: str) -> None:
    if destino not in EVENTO_TRANSICOES.get(atual, frozenset()):
        raise BikeTourError(409, "BT_TRANSICAO_EVENTO_INVALIDA")


def validar_transicao_ocorrencia(atual: str, destino: str) -> None:
    if destino not in OCORRENCIA_TRANSICOES.get(atual, frozenset()):
        raise BikeTourError(409, "BT_TRANSICAO_OCORRENCIA_INVALIDA")


def validar_rebloqueio(estado_inscricao: str, estado_evento: str) -> None:
    """Excecao explicita: somente o comando de novo bloqueio reutiliza inscricao terminal."""
    if estado_inscricao not in {"CANCELADA", "EXPIRADA"} or estado_evento != "ABERTO":
        raise BikeTourError(409, "BT_REBLOQUEIO_INELEGIVEL")


def validar_versao(atual: int, esperada: int) -> None:
    if esperada < 1:
        raise BikeTourError(422, "BT_VERSAO_INVALIDA")
    if atual != esperada:
        raise BikeTourError(409, "BT_VERSAO_DIVERGENTE")


def _utc(instante: datetime) -> datetime:
    if instante.tzinfo is None or instante.utcoffset() is None:
        raise BikeTourError(422, "BT_FUSO_OBRIGATORIO")
    return instante.astimezone(UTC)


def calcular_expiracao(
    agora: datetime, inicio_evento: datetime, validade_origem: datetime | None
) -> datetime:
    agora = _utc(agora)
    limites = [agora + timedelta(minutes=15), _utc(inicio_evento)]
    if validade_origem is not None:
        limites.append(_utc(validade_origem))
    limite = min(limites)
    if limite <= agora:
        raise BikeTourError(409, "BT_BLOQUEIO_SEM_VALIDADE")
    return limite


@dataclass(frozen=True, slots=True)
class OcupacaoInscricao:
    id_reserva: int
    status: str
    expira_em: datetime | None


def consome_capacidade(inscricao: OcupacaoInscricao, agora: datetime) -> bool:
    if inscricao.status in {"CONFIRMADA", "PRESENTE"}:
        return True
    return (
        inscricao.status == "PENDENTE"
        and inscricao.expira_em is not None
        and _utc(inscricao.expira_em) > _utc(agora)
    )


def validar_capacidade(
    inscricoes: Iterable[OcupacaoInscricao],
    *,
    agora: datetime,
    capacidade_evento: int,
    capacidade_saida: int,
    id_reserva: int,
    quantidade_reserva: int,
) -> None:
    """Valida uma nova ocupacao; a reacomodacao nao cria outra ocupacao."""
    if not 1 <= capacidade_evento <= 1000:
        raise BikeTourError(422, "BT_CAPACIDADE_INVALIDA")
    if capacidade_evento > capacidade_saida:
        raise BikeTourError(409, "BT_CAPACIDADE_SAIDA")
    comprometidas = [item for item in inscricoes if consome_capacidade(item, agora)]
    if len(comprometidas) >= capacidade_evento:
        raise BikeTourError(409, "BT_EVENTO_LOTADO")
    if sum(item.id_reserva == id_reserva for item in comprometidas) >= quantidade_reserva:
        raise BikeTourError(409, "BT_RESERVA_LOTADA")


def intervalos_sobrepostos(
    inicio: datetime, fim: datetime, outro_inicio: datetime, outro_fim: datetime
) -> bool:
    inicio, fim = _utc(inicio), _utc(fim)
    outro_inicio, outro_fim = _utc(outro_inicio), _utc(outro_fim)
    if inicio >= fim or outro_inicio >= outro_fim:
        raise BikeTourError(422, "BT_INTERVALO_INVALIDO")
    return inicio < outro_fim and outro_inicio < fim
