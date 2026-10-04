"""Revisao administrativa por operacao, sem exclusao ou acesso de escrita externo."""

from datetime import datetime, timedelta
from typing import Literal, Self

from pydantic import AwareDatetime, model_validator
from sqlalchemy import select

from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import (
    EventoBikeTour,
    InscricaoBikeTour,
    OcorrenciaBikeTour,
    OperacaoBikeTour,
    PendenciaBikeTour,
)
from app.modules.biketour.operational_schemas import Alteracao
from app.modules.biketour.schemas import BikeTourOutput, Motivo
from app.modules.biketour.uow import ContextoComando, ResultadoComando


class RevisaoRetencao(Alteracao):
    acao: Literal["REVISAR", "PRESERVAR", "LIBERAR_HOLD", "PRORROGAR", "COMPACTAR"]
    motivo: Motivo
    nova_data: AwareDatetime | None = None
    simular: bool = True

    @model_validator(mode="after")
    def validar_data(self) -> Self:
        if (self.acao == "PRORROGAR") != (self.nova_data is not None):
            raise ValueError("nova_data obrigatoria somente para PRORROGAR")
        return self


class RevisaoRetencaoResponse(BikeTourOutput):
    id_operacao_bike_tour: int
    id_evento_bike_tour: int | None
    versao: int
    ator: int
    correlation_id: str
    instante: datetime
    periodo_inicio: datetime
    periodo_fim: datetime
    acao: str
    motivo: str
    simular: bool
    elegivel: int
    processada: int
    preservada: int
    impedimentos: list[str]
    preservacao_expressa: bool
    nova_data: datetime | None
    compactada: bool


def _evento(ctx: ContextoComando, item: OperacaoBikeTour) -> EventoBikeTour | None:
    resultado = item.resultado if isinstance(item.resultado, dict) else {}
    identifier = resultado.get("id_evento_bike_tour")
    if not isinstance(identifier, int):
        if item.operacao in {
            "acao_evento",
            "alterar_evento",
            "definir_pontos",
            "definir_equipe",
            "definir_logistica",
            "expirar_evento",
            "reconciliar_evento",
            "bloquear_inscricao",
            "registrar_ocorrencia",
        }:
            identifier = item.alvo
        elif item.operacao in {
            "acao_inscricao",
            "reacomodar_recursos",
            "registrar_passagem",
            "avaliar_inscricao",
        }:
            inscricao = ctx.session.get(InscricaoBikeTour, item.alvo)
            identifier = inscricao.id_evento_bike_tour if inscricao else None
        elif item.operacao == "alterar_ocorrencia":
            ocorrencia = ctx.session.get(OcorrenciaBikeTour, item.alvo)
            identifier = ocorrencia.id_evento_bike_tour if ocorrencia else None
        elif item.operacao == "tratar_pendencia":
            pendencia = ctx.session.get(PendenciaBikeTour, item.alvo)
            identifier = pendencia.id_evento_bike_tour if pendencia else None
        else:
            identifier = ctx.session.scalar(
                select(PendenciaBikeTour.id_evento_bike_tour)
                .where(PendenciaBikeTour.id_operacao_bike_tour == item.id_operacao_bike_tour)
                .limit(1)
            )
    return ctx.session.get(EventoBikeTour, identifier) if isinstance(identifier, int) else None


def revisar_retencao(
    ctx: ContextoComando, identifier: int, payload: RevisaoRetencao
) -> ResultadoComando:
    """A UoW persiste a decisao e seu resultado na mesma transacao da compactacao."""
    item = ctx.session.get(OperacaoBikeTour, identifier)
    if item is None:
        raise BikeTourError(404, "BT_RECURSO_NAO_ENCONTRADO")
    if item.versao != payload.versao_esperada:
        raise BikeTourError(409, "BT_VERSAO_DIVERGENTE")
    if payload.nova_data is not None and payload.nova_data <= ctx.agora:
        raise BikeTourError(422, "BT_DATA_REVISAO_INVALIDA")
    anterior = ctx.session.scalar(
        select(OperacaoBikeTour)
        .where(
            OperacaoBikeTour.operacao == "revisar_retencao",
            OperacaoBikeTour.alvo == identifier,
            OperacaoBikeTour.resultado["simular"].as_boolean().is_(False),
        )
        .order_by(OperacaoBikeTour.id_operacao_bike_tour.desc())
        .limit(1)
    )
    estado = anterior.resultado if anterior and isinstance(anterior.resultado, dict) else {}
    hold = estado.get("preservacao_expressa") is True
    data = estado.get("nova_data")
    nova_data = datetime.fromisoformat(data) if isinstance(data, str) else None
    evento = _evento(ctx, item)
    marco = item.created_at
    impedimentos: list[str] = []
    if evento is not None and evento.status in {"CONCLUIDO", "CANCELADO"}:
        terminal = ctx.session.scalar(
            select(OperacaoBikeTour.created_at)
            .where(
                OperacaoBikeTour.operacao == "acao_evento",
                OperacaoBikeTour.alvo == evento.id_evento_bike_tour,
                OperacaoBikeTour.resultado["status"].as_string().in_(("CONCLUIDO", "CANCELADO")),
            )
            .order_by(OperacaoBikeTour.id_operacao_bike_tour.desc())
            .limit(1)
        )
        if terminal is None:
            impedimentos.append("MARCO_TERMINAL_AUSENTE")
        else:
            marco = terminal
    pendencia = ctx.session.scalar(
        select(PendenciaBikeTour.id_pendencia_bike_tour)
        .where(
            PendenciaBikeTour.status == "ABERTA",
            (PendenciaBikeTour.id_evento_bike_tour == evento.id_evento_bike_tour)
            if evento
            else (PendenciaBikeTour.id_operacao_bike_tour == identifier),
        )
        .limit(1)
    )
    elegivel = ctx.agora >= marco + timedelta(days=365)
    if not elegivel:
        impedimentos.append("PRAZO_365_DIAS")
    if pendencia is not None:
        impedimentos.append("PENDENCIA_ABERTA")
    if hold:
        impedimentos.append("PRESERVACAO_EXPRESSA")
    if nova_data is not None and ctx.agora < nova_data:
        impedimentos.append("RETENCAO_ADICIONAL")
    if ctx.agora < item.created_at + timedelta(days=90):
        impedimentos.append("REPLAY_90_DIAS")
    if item.operacao == "revisar_retencao":
        impedimentos.append("DECISAO_ADMINISTRATIVA")
    if isinstance(item.resultado, list):
        impedimentos.append("RESULTADO_COMPOSTO_PRESERVADO")
    # Preservar respostas de eventos conserva o marco terminal e a rastreabilidade.
    if evento is not None:
        impedimentos.append("VINCULO_OPERACIONAL_PRESERVADO")
    compactada = (
        isinstance(item.resultado, dict) and item.resultado.get("retencao_compactada") is True
    )
    processada = 0
    if not payload.simular:
        if payload.acao == "PRESERVAR":
            hold = True
        elif payload.acao == "LIBERAR_HOLD":
            hold = False
        elif payload.acao == "PRORROGAR":
            nova_data = payload.nova_data
        elif payload.acao == "COMPACTAR" and not impedimentos and not compactada:
            minimo = (
                {
                    key: value
                    for key, value in item.resultado.items()
                    if key.startswith("id_") or key in {"id", "status", "versao"}
                }
                if isinstance(item.resultado, dict)
                else {}
            )
            item.resultado = {**minimo, "retencao_compactada": True}
            compactada = True
            processada = 1
        item.versao += 1
        item.updated_by = str(ctx.ator.id_usuario)
        ctx.session.flush()
    return ResultadoComando(
        200,
        {
            "id_operacao_bike_tour": identifier,
            "id_evento_bike_tour": evento.id_evento_bike_tour if evento else None,
            "versao": item.versao,
            "ator": ctx.ator.id_usuario,
            "correlation_id": str(ctx.correlation_id),
            "instante": ctx.agora.isoformat(),
            "periodo_inicio": marco.isoformat(),
            "periodo_fim": ctx.agora.isoformat(),
            "acao": payload.acao,
            "motivo": payload.motivo,
            "simular": payload.simular,
            "elegivel": int(elegivel),
            "processada": processada,
            "preservada": 1 - processada,
            "impedimentos": impedimentos,
            "preservacao_expressa": hold,
            "nova_data": nova_data.isoformat() if nova_data else None,
            "compactada": compactada,
        },
    )
