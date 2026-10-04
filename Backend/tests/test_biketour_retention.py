"""Prazos, preservacao, autorizacao e decisao administrativa de retencao."""

import hashlib
from datetime import UTC, datetime, timedelta
from typing import Any, cast
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError

from app.db.session import get_session
from app.main import create_app
from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import EventoBikeTour, InscricaoBikeTour, OperacaoBikeTour
from app.modules.biketour.retention import RevisaoRetencao, _evento, revisar_retencao
from app.modules.biketour.uow import BikeTourUnitOfWork, ContextoComando
from app.modules.seguranca.authorization import obter_contexto_rbac
from app.modules.seguranca.rbac import ContextoRbac

NOW = datetime(2026, 9, 28, tzinfo=UTC)
ACTOR = ContextoRbac(1, (), frozenset({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}))


def payload(**kwargs: Any) -> RevisaoRetencao:
    return RevisaoRetencao.model_validate(
        {
            "acao": "REVISAR",
            "motivo": "OPERACIONAL",
            "chave_idempotencia": "review",
            "versao_esperada": 1,
            **kwargs,
        }
    )


def operation(**kwargs: Any) -> OperacaoBikeTour:
    return OperacaoBikeTour(
        **{
            "id_operacao_bike_tour": 10,
            "operacao": "criar_recurso",
            "alvo": 0,
            "resultado": {"id": 3},
            "created_at": NOW - timedelta(days=366),
            "versao": 1,
            **kwargs,
        }
    )


def context(item: OperacaoBikeTour | None) -> ContextoComando:
    session = MagicMock()
    session.get.return_value = item
    session.scalar.return_value = None
    return ContextoComando(session, ACTOR, uuid4(), NOW)


@pytest.mark.parametrize("days,eligible", [(89, 0), (90, 0), (364, 0), (365, 1), (366, 1)])
def test_prazo_e_simulacao(days: int, eligible: int) -> None:
    item = operation(created_at=NOW - timedelta(days=days))
    ctx = context(item)
    with patch("app.modules.biketour.retention._evento", return_value=None):
        result = revisar_retencao(ctx, 10, payload(acao="COMPACTAR")).corpo
    assert isinstance(result, dict)
    assert result["elegivel"] == eligible
    assert result["processada"] == 0
    assert item.resultado == {"id": 3}
    assert item.versao == 1
    assert ("REPLAY_90_DIAS" in result["impedimentos"]) == (days < 90)  # type: ignore[operator]


@pytest.mark.parametrize("acao", ["REVISAR", "PRESERVAR", "LIBERAR_HOLD", "PRORROGAR", "COMPACTAR"])
def test_acoes_e_evidencia(acao: str) -> None:
    item = operation()
    ctx = context(item)
    data = NOW + timedelta(days=30) if acao == "PRORROGAR" else None
    with patch("app.modules.biketour.retention._evento", return_value=None):
        result = revisar_retencao(ctx, 10, payload(acao=acao, simular=False, nova_data=data)).corpo
    assert isinstance(result, dict)
    assert result["ator"] == 1
    assert result["correlation_id"] == str(ctx.correlation_id)
    assert result["preservacao_expressa"] == (acao == "PRESERVAR")
    assert result["compactada"] == (acao == "COMPACTAR")
    assert item.versao == 2


@pytest.mark.parametrize("missing", [True, False])
def test_recurso_e_versao(missing: bool) -> None:
    ctx = context(None if missing else operation(versao=2))
    with pytest.raises(BikeTourError) as error:
        revisar_retencao(ctx, 10, payload())
    assert error.value.status_code == (404 if missing else 409)


def test_validacao_data_e_motivo() -> None:
    for kwargs in ({"acao": "PRORROGAR"}, {"nova_data": NOW}, {"motivo": ""}):
        with pytest.raises(ValidationError):
            payload(**kwargs)
    with pytest.raises(BikeTourError) as error:
        revisar_retencao(context(operation()), 10, payload(acao="PRORROGAR", nova_data=NOW))
    assert error.value.status_code == 422


def test_holds_extensao_e_journal_preservados() -> None:
    item = operation(operacao="revisar_retencao", resultado={"retencao_compactada": True})
    ctx = context(item)
    cast(MagicMock, ctx.session).scalar.side_effect = [
        operation(
            resultado={
                "preservacao_expressa": True,
                "nova_data": (NOW + timedelta(days=1)).isoformat(),
            }
        ),
        9,
    ]
    with patch("app.modules.biketour.retention._evento", return_value=None):
        result = revisar_retencao(ctx, 10, payload(acao="COMPACTAR", simular=False)).corpo
    assert isinstance(result, dict)
    assert result["processada"] == 0
    assert result["impedimentos"] == [
        "PENDENCIA_ABERTA",
        "PRESERVACAO_EXPRESSA",
        "RETENCAO_ADICIONAL",
        "DECISAO_ADMINISTRATIVA",
    ]


@pytest.mark.parametrize("terminal", [None, NOW - timedelta(days=364), NOW - timedelta(days=365)])
def test_marco_terminal_e_vinculos_preservados(terminal: datetime | None) -> None:
    item = operation()
    ctx = context(item)
    ctx.session.scalar.side_effect = [None, terminal, None]  # type: ignore[attr-defined]
    event = EventoBikeTour(id_evento_bike_tour=4, status="CONCLUIDO")
    with patch("app.modules.biketour.retention._evento", return_value=event):
        result = revisar_retencao(ctx, 10, payload(acao="COMPACTAR", simular=False)).corpo
    assert isinstance(result, dict)
    assert result["processada"] == 0
    assert "VINCULO_OPERACIONAL_PRESERVADO" in result["impedimentos"]  # type: ignore[operator]
    assert item.resultado == {"id": 3}


@pytest.mark.parametrize(
    "kind", ["json", "evento", "inscricao", "sem_inscricao", "pendencia", "lista"]
)
def test_resolucao_do_evento(kind: str) -> None:
    item = operation()
    ctx = context(item)
    event = EventoBikeTour(id_evento_bike_tour=5, status="ABERTO")
    ctx.session.get.return_value = event  # type: ignore[attr-defined]
    if kind == "json":
        item.resultado = {"id_evento_bike_tour": 5}
    elif kind == "evento":
        item.operacao, item.alvo = "acao_evento", 5
    elif kind in {"inscricao", "sem_inscricao"}:
        item.operacao = "acao_inscricao"
        ctx.session.get.side_effect = [  # type: ignore[attr-defined]
            InscricaoBikeTour(id_evento_bike_tour=5) if kind == "inscricao" else None,
            event,
        ]
    elif kind == "pendencia":
        ctx.session.scalar.return_value = 5  # type: ignore[attr-defined]
    else:
        item.resultado = []
    assert (_evento(ctx, item) is event) == (kind not in {"lista", "sem_inscricao"})


@pytest.mark.parametrize(
    "permission,status", [(None, 401), (frozenset(), 403), (ACTOR.permissoes, 200)]
)
def test_http_autenticacao_e_permissao(permission: frozenset[str] | None, status: int) -> None:
    app = create_app()
    app.dependency_overrides[get_session] = lambda: MagicMock()
    if permission is not None:
        app.dependency_overrides[obter_contexto_rbac] = lambda: ContextoRbac(1, (), permission)
    with (
        TestClient(app) as client,
        patch("app.modules.biketour.retention_router.BikeTourUnitOfWork") as uow,
    ):
        ctx = context(operation())
        with patch("app.modules.biketour.retention._evento", return_value=None):
            uow.return_value.executar.return_value = revisar_retencao(ctx, 10, payload())
        response = client.post(
            "/api/v1/biketour/operacoes/10/retencao", json=payload().model_dump(mode="json")
        )
        assert response.status_code == status
        if status == 200:
            handler = uow.return_value.executar.call_args.kwargs["comando"]
            with patch("app.modules.biketour.retention_router.revisar_retencao") as review:
                handler(ctx)
                review.assert_called_once()
            uow.return_value.executar.side_effect = BikeTourError(409, "BT_VERSAO_DIVERGENTE")
            assert (
                client.post(
                    "/api/v1/biketour/operacoes/10/retencao", json=payload().model_dump(mode="json")
                ).status_code
                == 409
            )


@pytest.mark.parametrize("op", ["alterar_ocorrencia", "tratar_pendencia"])
def test_resolucao_de_vinculos_indiretos(op: str) -> None:
    item = operation(operacao=op)
    ctx = context(item)
    event = EventoBikeTour(id_evento_bike_tour=5, status="ABERTO")
    cast(MagicMock, ctx.session).get.side_effect = [
        InscricaoBikeTour(id_evento_bike_tour=5),
        event,
    ]
    assert _evento(ctx, item) is event


def test_resultado_composto_permanece_integro() -> None:
    item = operation(resultado=[{"id": 1}])
    ctx = context(item)
    with patch("app.modules.biketour.retention._evento", return_value=None):
        result = revisar_retencao(ctx, 10, payload(acao="COMPACTAR", simular=False)).corpo
    assert isinstance(result, dict)
    assert result["impedimentos"] == ["RESULTADO_COMPOSTO_PRESERVADO"]
    assert item.resultado == [{"id": 1}]


def test_replay_compactado_nao_executa_handler() -> None:
    session = MagicMock()
    session.in_transaction.return_value = False
    with patch("app.modules.biketour.uow.OperacaoRepository") as repository:
        repository.return_value.obter.return_value = operation(
            resultado={"retencao_compactada": True},
            payload_hash=hashlib.sha256(b"{}").hexdigest(),
        )
        handler = MagicMock()
        with pytest.raises(BikeTourError) as error:
            BikeTourUnitOfWork(session).executar(
                ator=ACTOR,
                permissao="BIKE_TOUR_GERENCIAR",
                correlation_id=uuid4(),
                operacao="criar_recurso",
                alvo=0,
                chave="known",
                payload={},
                comando=handler,
            )
        assert error.value.code == "BT_RESPOSTA_COMPACTADA"
        handler.assert_not_called()
