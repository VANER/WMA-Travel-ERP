"""Casos de uso transacionais do domínio Turismo."""

from collections.abc import Callable
from datetime import UTC, date, datetime
from functools import wraps
from typing import Concatenate

from sqlalchemy import select, update
from sqlalchemy.orm import Session

from app.modules.turismo.models import (
    AlocacaoVaga,
    PacoteViagem,
    Reserva,
    ReservaCorrelacao,
    ReservaOperacao,
    SaidaTuristica,
)
from app.modules.turismo.repositories import ReservaRepository, SaidaRepository
from app.modules.turismo.schemas import (
    DisponibilidadeResponse,
    ReservaAcao,
    ReservaCreate,
    ReservaResponse,
    SaidaCreate,
)
from app.shared.vendas import (
    obter_contrato,
    obter_item_venda,
    obter_venda_financeira,
)


class RegraTurismoError(ValueError):
    """Violação previsível de regra do domínio Turismo."""


class RecursoTurismoNaoEncontradoError(RegraTurismoError):
    """Referência inexistente no domínio ou no Comercial."""


def _transacional[T, **P](
    func: Callable[Concatenate[Session, P], T],
) -> Callable[Concatenate[Session, P], T]:
    @wraps(func)
    def executar(session: Session, /, *args: P.args, **kwargs: P.kwargs) -> T:
        try:
            return func(session, *args, **kwargs)
        except Exception:
            session.rollback()
            raise

    return executar


def _validar_correlacao(session: Session, payload: ReservaCreate) -> None:
    if payload.id_venda is not None and obter_venda_financeira(session, payload.id_venda) is None:
        raise RecursoTurismoNaoEncontradoError("venda não encontrada")

    if payload.id_item_venda is not None:
        item = obter_item_venda(session, payload.id_item_venda)
        if item is None:
            raise RecursoTurismoNaoEncontradoError("item de venda não encontrado")
        if item.id_venda != payload.id_venda:
            raise RegraTurismoError("item incompatível com a venda")

    if payload.id_contrato is not None:
        contrato = obter_contrato(session, payload.id_contrato)
        if contrato is None:
            raise RecursoTurismoNaoEncontradoError("contrato não encontrado")
        if payload.id_venda is not None and contrato.id_venda != payload.id_venda:
            raise RegraTurismoError("contrato incompatível com a venda")


def _resultado_anterior(
    session: Session, identifier: int, operacao: str, chave: str, id_usuario: int | None
) -> ReservaResponse | None:
    registro = session.scalar(
        select(ReservaOperacao).where(
            ReservaOperacao.id_reserva == identifier,
            ReservaOperacao.operacao == operacao,
            ReservaOperacao.id_usuario == id_usuario,
            ReservaOperacao.chave_idempotencia == chave,
        )
    )
    if registro is None:
        return None
    return ReservaResponse.model_validate(registro.resultado)


def _registrar_resultado(
    session: Session, reserva: Reserva, operacao: str, chave: str, id_usuario: int | None
) -> ReservaResponse:
    session.flush()
    session.refresh(reserva)
    resposta = ReservaResponse.model_validate(reserva)
    session.add(
        ReservaOperacao(
            id_reserva=reserva.id_reserva,
            id_usuario=id_usuario,
            operacao=operacao,
            chave_idempotencia=chave,
            resultado=resposta.model_dump(mode="json"),
        )
    )
    session.commit()
    return resposta


def _agora() -> datetime:
    return datetime.now(UTC).replace(tzinfo=None)


@_transacional
def criar_saida(session: Session, payload: SaidaCreate) -> SaidaTuristica:
    pacote = session.get(PacoteViagem, payload.id_pacote)
    if pacote is None:
        raise RecursoTurismoNaoEncontradoError("pacote não encontrado")
    saida = SaidaTuristica(**payload.model_dump(), status="PLANEJADA")
    session.add(saida)
    session.commit()
    session.refresh(saida)
    return saida


def obter_disponibilidade(session: Session, identifier: int) -> DisponibilidadeResponse:
    repository = SaidaRepository(session)
    saida = repository.obter(identifier)
    if saida is None:
        raise RecursoTurismoNaoEncontradoError("saída não encontrada")
    bloqueadas, confirmadas = repository.ocupacao(identifier, _agora())
    return DisponibilidadeResponse(
        id_saida=identifier,
        capacidade=saida.capacidade,
        vagas_bloqueadas=bloqueadas,
        vagas_confirmadas=confirmadas,
        disponibilidade=saida.capacidade - bloqueadas - confirmadas,
    )


@_transacional
def criar_reserva(session: Session, payload: ReservaCreate) -> Reserva:
    reservas = ReservaRepository(session)
    existente = reservas.por_chave(payload.chave_idempotencia)
    if existente is not None:
        return existente
    saidas = SaidaRepository(session)
    saida = saidas.obter(payload.id_saida, bloquear=True)
    if saida is None:
        raise RecursoTurismoNaoEncontradoError("saída não encontrada")
    if saida.status not in {"PLANEJADA", "ABERTA"}:
        raise RegraTurismoError("saída não aceita reservas")
    existente = reservas.por_chave(payload.chave_idempotencia)
    if existente is not None:
        return existente
    _validar_correlacao(session, payload)
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
                chave_idempotencia=payload.chave_idempotencia,
            )
        )
    session.commit()
    session.refresh(reserva)
    return reserva


@_transacional
def confirmar_reserva(
    session: Session, identifier: int, payload: ReservaAcao, *, id_usuario: int | None = None
) -> ReservaResponse:
    referencia = ReservaRepository(session).obter(identifier)
    if referencia is None:
        raise RecursoTurismoNaoEncontradoError("reserva não encontrada")
    if referencia.id_saida is not None:
        SaidaRepository(session).obter(referencia.id_saida, bloquear=True)
    reserva = ReservaRepository(session).obter(identifier, bloquear=True)
    if reserva is None:
        raise RecursoTurismoNaoEncontradoError("reserva não encontrada")
    anterior = _resultado_anterior(
        session, identifier, "CONFIRMAR", payload.chave_idempotencia, id_usuario
    )
    if anterior is not None:
        return anterior
    if reserva.status == "CONFIRMADA":
        return _registrar_resultado(
            session, reserva, "CONFIRMAR", payload.chave_idempotencia, id_usuario
        )
    if reserva.status != "PENDENTE":
        raise RegraTurismoError("reserva não pode ser confirmada")
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
    return _registrar_resultado(
        session, reserva, "CONFIRMAR", payload.chave_idempotencia, id_usuario
    )


@_transacional
def cancelar_reserva(
    session: Session, identifier: int, payload: ReservaAcao, *, id_usuario: int | None = None
) -> ReservaResponse:
    referencia = ReservaRepository(session).obter(identifier)
    if referencia is None:
        raise RecursoTurismoNaoEncontradoError("reserva não encontrada")
    if referencia.id_saida is not None:
        SaidaRepository(session).obter(referencia.id_saida, bloquear=True)
    reserva = ReservaRepository(session).obter(identifier, bloquear=True)
    if reserva is None:
        raise RecursoTurismoNaoEncontradoError("reserva não encontrada")
    anterior = _resultado_anterior(
        session, identifier, "CANCELAR", payload.chave_idempotencia, id_usuario
    )
    if anterior is not None:
        return anterior
    if reserva.status == "CANCELADA":
        return _registrar_resultado(
            session, reserva, "CANCELAR", payload.chave_idempotencia, id_usuario
        )
    if reserva.status in {"CONCLUIDA", "NO_SHOW"}:
        raise RegraTurismoError("reserva não pode ser cancelada")
    alocacao = session.scalar(
        select(AlocacaoVaga).where(AlocacaoVaga.id_reserva == identifier).with_for_update()
    )
    if alocacao is not None and alocacao.status in {"BLOQUEADA", "RESERVADA"}:
        alocacao.status = "LIBERADA"
        alocacao.expira_em = None
    reserva.status = "CANCELADA"
    return _registrar_resultado(
        session, reserva, "CANCELAR", payload.chave_idempotencia, id_usuario
    )


@_transacional
def expirar_bloqueios(session: Session, id_saida: int) -> int:
    """Materializa expiração sob lock da saída, sem apagar o histórico."""
    if SaidaRepository(session).obter(id_saida, bloquear=True) is None:
        raise RecursoTurismoNaoEncontradoError("saída não encontrada")
    identifiers = session.scalars(
        update(AlocacaoVaga)
        .where(
            AlocacaoVaga.id_saida == id_saida,
            AlocacaoVaga.status == "BLOQUEADA",
            AlocacaoVaga.expira_em <= _agora(),
        )
        .values(status="EXPIRADA")
        .returning(AlocacaoVaga.id_alocacao)
    ).all()
    session.commit()
    return len(identifiers)
