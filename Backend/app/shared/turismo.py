"""Projecoes publicas somente-leitura do dominio Turismo."""

from dataclasses import dataclass
from datetime import UTC, date, datetime
from decimal import Decimal
from typing import Literal

from sqlalchemy import select, text
from sqlalchemy.orm import Session

from app.modules.turismo.models import (
    AlocacaoVaga,
    PacoteViagem,
    PassageiroReserva,
    ProdutoTuristico,
    ReservaCorrelacao,
)
from app.modules.turismo.repositories import (
    PassageiroReservaRepository,
    ReservaRepository,
    SaidaRepository,
)
from app.shared.vendas import obter_contrato, obter_item_venda, obter_venda_financeira


@dataclass(frozen=True, slots=True)
class ContextoSaida:
    id_saida: int
    id_pacote: int
    codigo: str
    data_inicio: date
    data_fim: date
    capacidade: int
    status: str
    versao: int
    deleted_at: datetime | None = None


@dataclass(frozen=True, slots=True)
class OrigemReserva:
    id_reserva: int
    codigo_reserva: str
    id_cliente: int
    id_pacote: int
    id_saida: int | None
    quantidade_passageiros: int
    valor_total: Decimal | None
    status: str
    versao: int
    deleted_at: datetime | None = None


@dataclass(frozen=True, slots=True)
class RecursoOrigem:
    id_passageiro: int
    id_reserva: int
    ordem: int
    status: str
    versao: int
    deleted_at: datetime | None = None


@dataclass(frozen=True, slots=True)
class ContextoInscricao:
    saida: ContextoSaida
    reserva: OrigemReserva
    passageiro: RecursoOrigem


@dataclass(frozen=True, slots=True)
class ProdutoOrigem:
    id_produto: int
    tipo: str
    ativo: bool
    versao: int | None


@dataclass(frozen=True, slots=True)
class CatalogoSaida:
    id_saida: int
    id_pacote: int
    produto: ProdutoOrigem
    elegivel: bool


@dataclass(frozen=True, slots=True)
class BloqueioTuristico:
    status: str
    expira_em: datetime | None


@dataclass(frozen=True, slots=True)
class OrigemComercialReserva:
    id_venda: int | None
    id_item_venda: int | None
    id_contrato: int | None
    valida: bool


@dataclass(frozen=True, slots=True)
class SituacaoRecursoOrigem:
    tipo: str
    identificador: int
    existe: bool
    permitido: bool


def obter_contexto_saida(
    session: Session,
    id_saida: int,
    *,
    bloquear: bool = False,
) -> ContextoSaida | None:
    """Obtem saida sem assumir controle da transacao do chamador."""
    saida = SaidaRepository(session).obter(
        id_saida,
        bloquear=bloquear,
    )
    if saida is None:
        return None

    return ContextoSaida(
        id_saida=saida.id_saida,
        id_pacote=saida.id_pacote,
        codigo=saida.codigo,
        data_inicio=saida.data_inicio,
        data_fim=saida.data_fim,
        capacidade=saida.capacidade,
        status=saida.status,
        versao=saida.versao,
        deleted_at=saida.deleted_at,
    )


def obter_origem_reserva(
    session: Session,
    id_reserva: int,
    *,
    bloquear: bool = False,
) -> OrigemReserva | None:
    """Obtem reserva sem commit e sem expor instancia ORM."""
    reserva = ReservaRepository(session).obter(
        id_reserva,
        bloquear=bloquear,
    )
    if reserva is None:
        return None

    if reserva.versao is None or reserva.versao < 1:
        raise ValueError("reserva sem versao valida para projecao publica")

    return OrigemReserva(
        id_reserva=reserva.id_reserva,
        codigo_reserva=reserva.codigo_reserva,
        id_cliente=reserva.id_cliente,
        id_pacote=reserva.id_pacote,
        id_saida=reserva.id_saida,
        quantidade_passageiros=reserva.quantidade_passageiros,
        valor_total=reserva.valor_total,
        status=reserva.status,
        versao=reserva.versao,
        deleted_at=reserva.deleted_at,
    )


def obter_recurso_origem(
    session: Session,
    id_passageiro: int,
    *,
    bloquear: bool = False,
) -> RecursoOrigem | None:
    """Obtem passageiro canonico sem expor instancia ORM."""
    passageiro = PassageiroReservaRepository(session).obter(
        id_passageiro,
        bloquear=bloquear,
    )
    if passageiro is None:
        return None

    return _recurso_origem(passageiro)


def obter_contexto_inscricao(
    session: Session,
    id_saida: int,
    id_reserva: int,
    id_passageiro: int,
    *,
    bloquear: bool = False,
) -> ContextoInscricao | None:
    """Resolve a origem completa para uma inscricao Bike Tour.

    Quando bloquear=True, a ordem de locks e:
    saida -> reserva -> passageiro.
    """
    saida = obter_contexto_saida(
        session,
        id_saida,
        bloquear=bloquear,
    )
    if saida is None:
        return None

    reserva = obter_origem_reserva(
        session,
        id_reserva,
        bloquear=bloquear,
    )
    if reserva is None or reserva.id_saida != id_saida:
        return None

    passageiro = obter_recurso_origem(
        session,
        id_passageiro,
        bloquear=bloquear,
    )
    if passageiro is None or passageiro.id_reserva != id_reserva:
        return None

    return ContextoInscricao(
        saida=saida,
        reserva=reserva,
        passageiro=passageiro,
    )


def _recurso_origem(
    passageiro: PassageiroReserva,
) -> RecursoOrigem:
    return RecursoOrigem(
        id_passageiro=passageiro.id_passageiro,
        id_reserva=passageiro.id_reserva,
        ordem=passageiro.ordem,
        status=passageiro.status,
        versao=passageiro.versao,
        deleted_at=passageiro.deleted_at,
    )


def obter_produto_origem(
    session: Session, identifier: int, *, bloquear: bool = False
) -> ProdutoOrigem | None:
    statement = select(ProdutoTuristico).where(ProdutoTuristico.id_produto == identifier)
    if bloquear:
        statement = statement.with_for_update(read=True).execution_options(populate_existing=True)
    produto = session.scalar(statement)
    if produto is None:
        return None
    return ProdutoOrigem(
        produto.id_produto,
        produto.tipo_produto,
        bool(produto.ativo) and produto.deleted_at is None,
        produto.versao,
    )


def obter_catalogo_saida(
    session: Session, saida: ContextoSaida, *, bloquear: bool = False
) -> CatalogoSaida | None:
    """Complementa a saida ja protegida, sem duplicar produto ou pacote."""
    statement = select(PacoteViagem).where(PacoteViagem.id_pacote == saida.id_pacote)
    if bloquear:
        statement = statement.with_for_update(read=True).execution_options(populate_existing=True)
    pacote = session.scalar(statement)
    if pacote is None:
        return None
    produto = obter_produto_origem(session, pacote.id_produto, bloquear=bloquear)
    if produto is None:
        return None
    return CatalogoSaida(
        saida.id_saida,
        pacote.id_pacote,
        produto,
        pacote.deleted_at is None and pacote.status == "ATIVO" and produto.ativo,
    )


def obter_bloqueio_turistico(
    session: Session, id_reserva: int, *, bloquear: bool = False
) -> BloqueioTuristico | None:
    """A reserva protegida pelo caller serializa a alocacao pertencente a Turismo."""
    statement = (
        select(AlocacaoVaga)
        .where(AlocacaoVaga.id_reserva == id_reserva, AlocacaoVaga.deleted_at.is_(None))
        .execution_options(populate_existing=True)
    )
    if bloquear:
        statement = statement.with_for_update(read=True)
    alocacao = session.scalar(statement)
    if alocacao is None:
        return None
    # Turismo persiste UTC sem fuso na baseline; nao interpretar como horario local.
    expires = alocacao.expira_em
    if expires is not None:
        expires = expires.replace(tzinfo=UTC) if expires.tzinfo is None else expires.astimezone(UTC)
    return BloqueioTuristico(alocacao.status, expires)


def obter_origem_comercial_reserva(
    session: Session, id_reserva: int, *, bloquear: bool = False
) -> OrigemComercialReserva:
    """IDs comerciais minimos; nenhuma entidade ORM ou valor financeiro cruza a porta."""
    statement = (
        select(ReservaCorrelacao)
        .where(ReservaCorrelacao.id_reserva == id_reserva, ReservaCorrelacao.deleted_at.is_(None))
        .execution_options(populate_existing=True)
    )
    if bloquear:
        statement = statement.with_for_update(read=True)
    correlacao = session.scalar(statement)
    if correlacao is None:
        return OrigemComercialReserva(None, None, None, True)
    valida = True
    if correlacao.id_venda is not None:
        venda = obter_venda_financeira(session, correlacao.id_venda, bloquear=bloquear)
        valida = venda is not None and venda.deleted_at is None
    if correlacao.id_item_venda is not None:
        item = obter_item_venda(session, correlacao.id_item_venda, bloquear=bloquear)
        valida = (
            valida
            and item is not None
            and item.deleted_at is None
            and item.id_venda == correlacao.id_venda
        )
    if correlacao.id_contrato is not None:
        contrato = obter_contrato(session, correlacao.id_contrato, bloquear=bloquear)
        valida = (
            valida
            and contrato is not None
            and contrato.deleted_at is None
            and (correlacao.id_venda is None or contrato.id_venda == correlacao.id_venda)
        )
    return OrigemComercialReserva(
        correlacao.id_venda, correlacao.id_item_venda, correlacao.id_contrato, valida
    )


def obter_situacao_recurso_origem(
    session: Session,
    tipo: Literal["BICICLETA", "EQUIPAMENTO", "GUIA", "VEICULO"],
    identifier: int,
    *,
    bloquear: bool = False,
) -> SituacaoRecursoOrigem:
    """Le somente colunas verificadas no catalogo; guia/transporte nao possuem status."""
    table, pk, status = {
        "BICICLETA": ("ativo_imobilizado", "id_ativo", "status"),
        "EQUIPAMENTO": ("ativo_imobilizado", "id_ativo", "status"),
        "GUIA": ("guia_turistico", "id_guia", "'ATIVO'"),
        "VEICULO": ("transporte", "id_transporte", "'ATIVO'"),
    }[tipo]
    lock = " FOR SHARE" if bloquear else ""
    row = (
        session.execute(
            text(f"SELECT deleted_at, {status} AS status FROM public.{table} WHERE {pk}=:id{lock}"),
            {"id": identifier},
        )
        .mappings()
        .one_or_none()
    )
    return SituacaoRecursoOrigem(
        tipo,
        identifier,
        row is not None,
        row is not None and row["deleted_at"] is None and row["status"] == "ATIVO",
    )
