"""Casos de uso de produto e evento Bike Tour."""

from __future__ import annotations

from collections.abc import Callable
from datetime import UTC
from typing import cast
from uuid import UUID, uuid4

from sqlalchemy import select
from sqlalchemy.exc import OperationalError, TimeoutError
from sqlalchemy.orm import Session

from app.core.logging import get_correlation_id
from app.modules.biketour.domain import validar_transicao_evento, validar_versao
from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import (
    AlocacaoRecursoBikeTour,
    EquipeBikeTour,
    EventoBikeTour,
    InscricaoBikeTour,
    LogisticaBikeTour,
    OcorrenciaBikeTour,
    PontoControleBikeTour,
    ProdutoBikeTour,
    RecursoBikeTour,
)
from app.modules.biketour.repositories import EventoRepository, ProdutoRepository
from app.modules.biketour.schemas import (
    EventoAcaoRequest,
    EventoCreate,
    EventoResponse,
    EventoUpdate,
    ProdutoCreate,
    ProdutoResponse,
    ProdutoUpdate,
)
from app.modules.biketour.uow import (
    BikeTourUnitOfWork,
    ContextoComando,
    PermissaoComando,
    ResultadoComando,
)
from app.modules.seguranca.rbac import ContextoRbac
from app.shared.turismo import (
    obter_catalogo_saida,
    obter_contexto_inscricao,
    obter_contexto_saida,
    obter_produto_origem,
)


def listar_produtos(session: Session, offset: int, limite: int) -> list[ProdutoResponse]:
    try:
        return [
            ProdutoResponse.model_validate(item)
            for item in ProdutoRepository(session).listar(offset, limite)
        ]
    except (OperationalError, TimeoutError) as exc:
        raise BikeTourError(503, "BT_FONTE_INDISPONIVEL") from exc


def listar_eventos(session: Session, offset: int, limite: int) -> list[EventoResponse]:
    try:
        return [
            EventoResponse.model_validate(item)
            for item in EventoRepository(session).listar(offset, limite)
        ]
    except (OperationalError, TimeoutError) as exc:
        raise BikeTourError(503, "BT_FONTE_INDISPONIVEL") from exc


def consultar_evento(session: Session, identifier: int) -> EventoResponse:
    try:
        item = EventoRepository(session).obter(identifier)
        if item is None or item.deleted_at is not None:
            raise BikeTourError(404, "BT_EVENTO_NAO_ENCONTRADO")
        return EventoResponse.model_validate(item)
    except (OperationalError, TimeoutError) as exc:
        raise BikeTourError(503, "BT_FONTE_INDISPONIVEL") from exc


def _tem_inscricoes_ativas(session: Session, identifier: int) -> bool:
    return (
        session.scalar(
            select(InscricaoBikeTour.id_inscricao_bike_tour)
            .where(
                InscricaoBikeTour.id_evento_bike_tour == identifier,
                InscricaoBikeTour.status.in_(("PENDENTE", "CONFIRMADA", "PRESENTE")),
            )
            .limit(1)
        )
        is not None
    )


def _alocacoes_ativas(session: Session, identifier: int) -> list[AlocacaoRecursoBikeTour]:
    return list(
        session.scalars(
            select(AlocacaoRecursoBikeTour)
            .where(
                AlocacaoRecursoBikeTour.id_evento_bike_tour == identifier,
                AlocacaoRecursoBikeTour.status.in_(("BLOQUEADA", "CONFIRMADA")),
            )
            .order_by(AlocacaoRecursoBikeTour.id_alocacao_recurso_bike_tour)
            .with_for_update()
        ).all()
    )


def _validar_preparacao(session: Session, item: EventoBikeTour) -> None:
    pontos = list(
        session.scalars(
            select(PontoControleBikeTour)
            .where(
                PontoControleBikeTour.id_evento_bike_tour == item.id_evento_bike_tour,
                PontoControleBikeTour.deleted_at.is_(None),
            )
            .order_by(PontoControleBikeTour.ordem)
        ).all()
    )
    if len(pontos) < 2 or any(
        anterior.distancia_km >= proximo.distancia_km
        for anterior, proximo in zip(pontos, pontos[1:], strict=False)
    ):
        raise BikeTourError(409, "BT_ROTA_INCOMPLETA")
    apoio = (
        select(RecursoBikeTour.id_recurso_bike_tour)
        .join(
            AlocacaoRecursoBikeTour,
            AlocacaoRecursoBikeTour.id_recurso_bike_tour == RecursoBikeTour.id_recurso_bike_tour,
        )
        .where(
            AlocacaoRecursoBikeTour.id_evento_bike_tour == item.id_evento_bike_tour,
            AlocacaoRecursoBikeTour.id_inscricao_bike_tour.is_(None),
            AlocacaoRecursoBikeTour.status == "CONFIRMADA",
            AlocacaoRecursoBikeTour.deleted_at.is_(None),
            AlocacaoRecursoBikeTour.inicio <= item.inicio,
            AlocacaoRecursoBikeTour.fim >= item.fim,
            RecursoBikeTour.deleted_at.is_(None),
            RecursoBikeTour.status == "DISPONIVEL",
        )
    )
    lider = session.scalar(
        apoio.join(
            EquipeBikeTour,
            EquipeBikeTour.id_recurso_bike_tour == RecursoBikeTour.id_recurso_bike_tour,
        )
        .where(
            EquipeBikeTour.id_evento_bike_tour == item.id_evento_bike_tour,
            EquipeBikeTour.papel == "LIDER",
            EquipeBikeTour.deleted_at.is_(None),
            RecursoBikeTour.tipo == "GUIA",
        )
        .limit(1)
    )
    veiculo = session.scalar(
        apoio.join(
            LogisticaBikeTour,
            LogisticaBikeTour.id_recurso_bike_tour == RecursoBikeTour.id_recurso_bike_tour,
        )
        .where(
            LogisticaBikeTour.id_evento_bike_tour == item.id_evento_bike_tour,
            LogisticaBikeTour.deleted_at.is_(None),
            RecursoBikeTour.tipo == "VEICULO",
        )
        .limit(1)
    )
    if lider is None or veiculo is None:
        raise BikeTourError(409, "BT_APOIO_INCOMPLETO")


def _validar_acao(
    ctx: ContextoComando, item: EventoBikeTour, acao: str, motivo: str | None = None
) -> None:
    if acao in {"ABRIR", "INICIAR"}:
        saida = obter_contexto_saida(ctx.session, item.id_saida, bloquear=True)
        if (
            saida is None
            or saida.deleted_at is not None
            or saida.status not in {"PLANEJADA", "ABERTA"}
        ):
            raise BikeTourError(409, "BT_SAIDA_ORIGEM_INCOMPATIVEL")
        catalogo = obter_catalogo_saida(ctx.session, saida, bloquear=True)
        if catalogo is None or not catalogo.elegivel or catalogo.produto.tipo != "CICLOTURISMO":
            raise BikeTourError(409, "BT_SAIDA_ORIGEM_INCOMPATIVEL")
        _validar_preparacao(ctx.session, item)
        if acao == "INICIAR" and not item.inicio <= ctx.agora < item.fim:
            raise BikeTourError(409, "BT_HORARIO_INCOMPATIVEL")
        if acao == "INICIAR":
            inscricoes = ctx.session.scalars(
                select(InscricaoBikeTour)
                .where(
                    InscricaoBikeTour.id_evento_bike_tour == item.id_evento_bike_tour,
                    InscricaoBikeTour.status.in_(("PENDENTE", "CONFIRMADA", "PRESENTE")),
                )
                .order_by(InscricaoBikeTour.id_reserva, InscricaoBikeTour.id_passageiro)
            ).all()
            for inscricao in inscricoes:
                origem = obter_contexto_inscricao(
                    ctx.session,
                    item.id_saida,
                    inscricao.id_reserva,
                    inscricao.id_passageiro,
                    bloquear=True,
                )
                if (
                    origem is None
                    or origem.reserva.deleted_at is not None
                    or origem.reserva.status != "CONFIRMADA"
                    or origem.passageiro.deleted_at is not None
                    or origem.passageiro.status != "ATIVO"
                ):
                    raise BikeTourError(409, "BT_INSCRICAO_ORIGEM_INCOMPATIVEL")
    else:
        if acao == "CONCLUIR" and _tem_inscricoes_ativas(ctx.session, item.id_evento_bike_tour):
            raise BikeTourError(409, "BT_INSCRICOES_ATIVAS")
        if acao == "CANCELAR":
            from app.modules.biketour.operations import OperacoesBikeTour

            OperacoesBikeTour(ctx).cancelar_evento(item, motivo or "OPERACIONAL")
        if (
            acao == "CONCLUIR"
            and ctx.session.scalar(
                select(OcorrenciaBikeTour.id_ocorrencia_bike_tour)
                .where(
                    OcorrenciaBikeTour.id_evento_bike_tour == item.id_evento_bike_tour,
                    OcorrenciaBikeTour.gravidade == "ALTA",
                    OcorrenciaBikeTour.status.in_(("ABERTA", "EM_ANALISE")),
                )
                .limit(1)
            )
            is not None
        ):
            raise BikeTourError(409, "BT_OCORRENCIAS_PENDENTES")
        for alocacao in _alocacoes_ativas(ctx.session, item.id_evento_bike_tour):
            alocacao.status = "LIBERADA"
            alocacao.expira_em = None
            alocacao.updated_by = str(ctx.ator.id_usuario)
        if acao == "CANCELAR" and item.status == "EM_EXECUCAO":
            ctx.session.add(
                OcorrenciaBikeTour(
                    id_evento_bike_tour=item.id_evento_bike_tour,
                    tipo="INTERRUPCAO",
                    gravidade="ALTA",
                    motivo=motivo or "OPERACIONAL",
                    created_by=str(ctx.ator.id_usuario),
                )
            )


def _produto_resultado(item: ProdutoBikeTour) -> dict[str, object]:
    return {
        "id_produto_bike_tour": item.id_produto_bike_tour,
        "id_produto": item.id_produto,
        "distancia_km": str(item.distancia_km),
        "desnivel_m": str(item.desnivel_m),
        "nivel": item.nivel,
        "ativo": item.ativo,
        "versao": item.versao,
        "created_at": item.created_at.isoformat(),
        "updated_at": item.updated_at.isoformat() if item.updated_at else None,
    }


def _evento_resultado(item: EventoBikeTour) -> dict[str, object]:
    return {
        "id_evento_bike_tour": item.id_evento_bike_tour,
        "id_saida": item.id_saida,
        "inicio": item.inicio.isoformat(),
        "fim": item.fim.isoformat(),
        "capacidade": item.capacidade,
        "status": item.status,
        "versao": item.versao,
        "created_at": item.created_at.isoformat(),
        "updated_at": item.updated_at.isoformat() if item.updated_at else None,
    }


def _executar(
    session: Session,
    contexto: ContextoRbac,
    permissao: PermissaoComando,
    operacao: str,
    alvo: int,
    chave: str,
    payload: dict[str, object],
    comando: Callable[[ContextoComando], ResultadoComando],
) -> dict[str, object]:
    return cast(
        dict[str, object],
        BikeTourUnitOfWork(session)
        .executar(
            ator=contexto,
            permissao=permissao,
            correlation_id=UUID(correlation) if (correlation := get_correlation_id()) else uuid4(),
            operacao=operacao,
            alvo=alvo,
            chave=chave,
            payload=payload,
            comando=comando,
        )
        .corpo,
    )


def criar_produto(
    session: Session, contexto: ContextoRbac, payload: ProdutoCreate
) -> dict[str, object]:
    def comando(ctx: ContextoComando) -> ResultadoComando:
        origem = obter_produto_origem(ctx.session, payload.id_produto, bloquear=True)
        if origem is None:
            raise BikeTourError(404, "BT_PRODUTO_ORIGEM_NAO_ENCONTRADO")
        if not origem.ativo or origem.tipo != "CICLOTURISMO":
            raise BikeTourError(409, "BT_PRODUTO_ORIGEM_INCOMPATIVEL")
        repository = ProdutoRepository(ctx.session)
        if repository.por_origem(payload.id_produto) is not None:
            raise BikeTourError(409, "BT_PRODUTO_DUPLICADO")
        item = ProdutoBikeTour(
            **payload.model_dump(exclude={"chave_idempotencia"}),
            created_by=str(ctx.ator.id_usuario),
        )
        repository.salvar(item)
        return ResultadoComando(201, _produto_resultado(item))

    return _executar(
        session,
        contexto,
        "BIKE_TOUR_GERENCIAR",
        "criar_produto",
        0,
        payload.chave_idempotencia,
        payload.model_dump(mode="json"),
        comando,
    )


def alterar_produto(
    session: Session, contexto: ContextoRbac, identifier: int, payload: ProdutoUpdate
) -> dict[str, object]:
    def comando(ctx: ContextoComando) -> ResultadoComando:
        repository = ProdutoRepository(ctx.session)
        item = repository.obter(identifier, bloquear=True)
        if item is None or item.deleted_at is not None:
            raise BikeTourError(404, "BT_PRODUTO_NAO_ENCONTRADO")
        validar_versao(item.versao, payload.versao_esperada)
        for field in ("distancia_km", "desnivel_m", "nivel", "ativo"):
            value = getattr(payload, field)
            if value is not None:
                setattr(item, field, value)
        item.updated_by = str(ctx.ator.id_usuario)
        repository.salvar(item)
        return ResultadoComando(200, _produto_resultado(item))

    return _executar(
        session,
        contexto,
        "BIKE_TOUR_GERENCIAR",
        "alterar_produto",
        identifier,
        payload.chave_idempotencia,
        payload.model_dump(mode="json"),
        comando,
    )


def criar_evento(
    session: Session, contexto: ContextoRbac, payload: EventoCreate
) -> dict[str, object]:
    def comando(ctx: ContextoComando) -> ResultadoComando:
        saida = obter_contexto_saida(ctx.session, payload.id_saida, bloquear=True)
        if saida is None:
            raise BikeTourError(404, "BT_SAIDA_NAO_ENCONTRADA")
        if saida.deleted_at is not None or saida.status not in {"PLANEJADA", "ABERTA"}:
            raise BikeTourError(409, "BT_SAIDA_ORIGEM_INCOMPATIVEL")
        catalogo = obter_catalogo_saida(ctx.session, saida, bloquear=True)
        if catalogo is None or not catalogo.elegivel or catalogo.produto.tipo != "CICLOTURISMO":
            raise BikeTourError(409, "BT_SAIDA_ORIGEM_INCOMPATIVEL")
        produto = ProdutoRepository(ctx.session).por_origem(catalogo.produto.id_produto)
        if produto is None or produto.deleted_at is not None or not produto.ativo:
            raise BikeTourError(409, "BT_PRODUTO_INCOMPATIVEL")
        inicio, fim = payload.inicio.astimezone(UTC), payload.fim.astimezone(UTC)
        if inicio.date() < saida.data_inicio or fim.date() > saida.data_fim:
            raise BikeTourError(409, "BT_PERIODO_FORA_DA_SAIDA")
        if payload.capacidade > saida.capacidade:
            raise BikeTourError(409, "BT_CAPACIDADE_SAIDA")
        item = EventoBikeTour(
            id_saida=payload.id_saida,
            inicio=inicio,
            fim=fim,
            capacidade=payload.capacidade,
            created_by=str(ctx.ator.id_usuario),
        )
        EventoRepository(ctx.session).salvar(item)
        return ResultadoComando(201, _evento_resultado(item))

    return _executar(
        session,
        contexto,
        "BIKE_TOUR_GERENCIAR",
        "criar_evento",
        0,
        payload.chave_idempotencia,
        payload.model_dump(mode="json"),
        comando,
    )


def alterar_evento(
    session: Session, contexto: ContextoRbac, identifier: int, payload: EventoUpdate
) -> dict[str, object]:
    def comando(ctx: ContextoComando) -> ResultadoComando:
        repository = EventoRepository(ctx.session)
        item = repository.obter(identifier, bloquear=True)
        if item is None or item.deleted_at is not None:
            raise BikeTourError(404, "BT_EVENTO_NAO_ENCONTRADO")
        if item.status != "PLANEJADO":
            raise BikeTourError(409, "BT_EVENTO_ESTADO_INCOMPATIVEL")
        validar_versao(item.versao, payload.versao_esperada)
        if _tem_inscricoes_ativas(ctx.session, identifier) or _alocacoes_ativas(
            ctx.session, identifier
        ):
            raise BikeTourError(409, "BT_EVENTO_COM_VINCULOS_ATIVOS")
        if payload.inicio is not None and payload.fim is not None:
            item.inicio, item.fim = payload.inicio.astimezone(UTC), payload.fim.astimezone(UTC)
            saida = obter_contexto_saida(ctx.session, item.id_saida, bloquear=True)
            if (
                saida is None
                or item.inicio.date() < saida.data_inicio
                or item.fim.date() > saida.data_fim
            ):
                raise BikeTourError(409, "BT_PERIODO_FORA_DA_SAIDA")
        if payload.capacidade is not None:
            saida = obter_contexto_saida(ctx.session, item.id_saida, bloquear=True)
            if saida is None or payload.capacidade > saida.capacidade:
                raise BikeTourError(409, "BT_CAPACIDADE_SAIDA")
            item.capacidade = payload.capacidade
        item.updated_by = str(ctx.ator.id_usuario)
        repository.salvar(item)
        return ResultadoComando(200, _evento_resultado(item))

    return _executar(
        session,
        contexto,
        "BIKE_TOUR_GERENCIAR",
        "alterar_evento",
        identifier,
        payload.chave_idempotencia,
        payload.model_dump(mode="json"),
        comando,
    )


def acionar_evento(
    session: Session, contexto: ContextoRbac, identifier: int, payload: EventoAcaoRequest
) -> dict[str, object]:
    destinos = {
        "ABRIR": "ABERTO",
        "INICIAR": "EM_EXECUCAO",
        "CANCELAR": "CANCELADO",
        "CONCLUIR": "CONCLUIDO",
    }

    def comando(ctx: ContextoComando) -> ResultadoComando:
        repository = EventoRepository(ctx.session)
        item = repository.obter(identifier, bloquear=True)
        if item is None or item.deleted_at is not None:
            raise BikeTourError(404, "BT_EVENTO_NAO_ENCONTRADO")
        validar_versao(item.versao, payload.versao_esperada)
        if payload.acao in {"CANCELAR", "CONCLUIR"} and not payload.motivo:
            raise BikeTourError(422, "BT_MOTIVO_OBRIGATORIO")
        validar_transicao_evento(item.status, destinos[payload.acao])
        _validar_acao(ctx, item, payload.acao, payload.motivo)
        item.status = destinos[payload.acao]
        item.updated_by = str(ctx.ator.id_usuario)
        repository.salvar(item)
        return ResultadoComando(200, _evento_resultado(item))

    return _executar(
        session,
        contexto,
        "BIKE_TOUR_GERENCIAR",
        "acao_evento",
        identifier,
        payload.chave_idempotencia,
        payload.model_dump(mode="json"),
        comando,
    )
