"""Casos de uso transacionais do domínio Turismo."""

from datetime import UTC, date, datetime

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.turismo.models import (
    AlocacaoVaga,
    PacoteViagem,
    Reserva,
    ReservaCorrelacao,
    SaidaTuristica,
)
from app.modules.turismo.repositories import ReservaRepository, SaidaRepository
from app.modules.turismo.schemas import (
    DisponibilidadeResponse,
    ReservaAcao,
    ReservaCreate,
    SaidaCreate,
)


class RegraTurismoError(ValueError):
    """Violação previsível de regra do domínio Turismo."""


def _commit(session: Session) -> None:
    try:
        session.commit()
    except Exception:
        session.rollback()
        raise


def _agora() -> datetime:
    return datetime.now(UTC).replace(tzinfo=None)


def criar_saida(session: Session, payload: SaidaCreate) -> SaidaTuristica:
    pacote = session.get(PacoteViagem, payload.id_pacote)
    if pacote is None:
        raise RegraTurismoError("pacote não encontrado")
    saida = SaidaTuristica(**payload.model_dump(), status="PLANEJADA")
    session.add(saida)
    _commit(session)
    session.refresh(saida)
    return saida


def obter_disponibilidade(session: Session, identifier: int) -> DisponibilidadeResponse:
    repository = SaidaRepository(session)
    saida = repository.obter(identifier)
    if saida is None:
        raise RegraTurismoError("saída não encontrada")
    bloqueadas, confirmadas = repository.ocupacao(identifier, _agora())
    return DisponibilidadeResponse(
        id_saida=identifier,
        capacidade=saida.capacidade,
        vagas_bloqueadas=bloqueadas,
        vagas_confirmadas=confirmadas,
        disponibilidade=saida.capacidade - bloqueadas - confirmadas,
    )


def criar_reserva(session: Session, payload: ReservaCreate) -> Reserva:
    reservas = ReservaRepository(session)
    existente = reservas.por_chave(payload.chave_idempotencia)
    if existente is not None:
        return existente
    saidas = SaidaRepository(session)
    saida = saidas.obter(payload.id_saida, bloquear=True)
    if saida is None:
        raise RegraTurismoError("saída não encontrada")
    if saida.status not in {"PLANEJADA", "ABERTA"}:
        raise RegraTurismoError("saída não aceita reservas")
    bloqueadas, confirmadas = saidas.ocupacao(saida.id_saida, _agora())
    if bloqueadas + confirmadas + payload.quantidade_passageiros > saida.capacidade:
        raise RegraTurismoError("capacidade indisponível")
    reserva = Reserva(
        codigo_reserva=payload.codigo_reserva,
        id_cliente=payload.id_cliente,
        id_pacote=saida.id_pacote,
        id_saida=saida.id_saida,
        data_reserva=date.today(),
        quantidade_passageiros=payload.quantidade_passageiros,
        valor_total=payload.valor_total,
        status="PENDENTE",
    )
    session.add(reserva)
    session.flush()
    status = "BLOQUEADA" if payload.expira_em else "RESERVADA"
    session.add(
        AlocacaoVaga(
            id_saida=saida.id_saida,
            id_reserva=reserva.id_reserva,
            chave_idempotencia=payload.chave_idempotencia,
            quantidade=payload.quantidade_passageiros,
            status=status,
            expira_em=payload.expira_em,
        )
    )
    if any((payload.id_venda, payload.id_item_venda, payload.id_contrato)):
        session.add(
            ReservaCorrelacao(
                id_reserva=reserva.id_reserva,
                id_venda=payload.id_venda,
                id_item_venda=payload.id_item_venda,
                id_contrato=payload.id_contrato,
                chave_idempotencia=f"COR:{payload.chave_idempotencia}",
            )
        )
    _commit(session)
    session.refresh(reserva)
    return reserva


def confirmar_reserva(session: Session, identifier: int, payload: ReservaAcao) -> Reserva:
    reserva = ReservaRepository(session).obter(identifier, bloquear=True)
    if reserva is None:
        raise RegraTurismoError("reserva não encontrada")
    if reserva.status == "CONFIRMADA":
        return reserva
    alocacao = session.scalar(
        select(AlocacaoVaga).where(AlocacaoVaga.id_reserva == identifier).with_for_update()
    )
    if alocacao is None or alocacao.status not in {"BLOQUEADA", "RESERVADA"}:
        raise RegraTurismoError("alocação inválida")
    if alocacao.status == "BLOQUEADA" and (
        alocacao.expira_em is None or alocacao.expira_em <= _agora()
    ):
        raise RegraTurismoError("bloqueio expirado")
    alocacao.status = "RESERVADA"
    alocacao.expira_em = None
    reserva.status = "CONFIRMADA"
    _commit(session)
    return reserva


def cancelar_reserva(session: Session, identifier: int, payload: ReservaAcao) -> Reserva:
    reserva = ReservaRepository(session).obter(identifier, bloquear=True)
    if reserva is None:
        raise RegraTurismoError("reserva não encontrada")
    if reserva.status == "CANCELADA":
        return reserva
    if reserva.status in {"CONCLUIDA", "NO_SHOW"}:
        raise RegraTurismoError("reserva não pode ser cancelada")
    alocacao = session.scalar(
        select(AlocacaoVaga).where(AlocacaoVaga.id_reserva == identifier).with_for_update()
    )
    if alocacao is not None and alocacao.status in {"BLOQUEADA", "RESERVADA"}:
        alocacao.status = "LIBERADA"
        alocacao.expira_em = None
    reserva.status = "CANCELADA"
    _commit(session)
    return reserva
