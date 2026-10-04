"""Contrato HTTP, permissoes e validacao da superficie operacional."""

from collections.abc import Generator
from datetime import UTC, datetime
from typing import Any, cast
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient
from sqlalchemy.exc import OperationalError

from app.db.session import get_session
from app.main import create_app
from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.uow import ContextoComando, ResultadoComando
from app.modules.seguranca.authorization import obter_contexto_rbac
from app.modules.seguranca.rbac import ContextoRbac

NOW = datetime(2026, 9, 23, 12, tzinfo=UTC)
ATOR = ContextoRbac(
    1, (), frozenset({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_OPERAR", "BIKE_TOUR_GERENCIAR"})
)
BASE = "/api/v1/biketour"
COMANDOS = [
    ("POST", "/recursos", "criar_recurso", {"codigo": "B1", "tipo": "BICICLETA"}, 201),
    ("PATCH", "/recursos/1", "alterar_recurso", {"status": "MANUTENCAO"}, 200),
    (
        "POST",
        "/eventos/1/inscricoes",
        "bloquear",
        {"id_reserva": 1, "id_passageiro": 1, "papel": "PARTICIPANTE", "id_bicicleta": 1},
        201,
    ),
    ("POST", "/inscricoes/1/acoes", "acionar_inscricao", {"acao": "CONFIRMAR"}, 200),
    ("POST", "/inscricoes/1/recursos", "reacomodar", {"id_bicicleta": 2}, 200),
    (
        "POST",
        "/eventos/1/pontos",
        "definir_pontos",
        {
            "pontos": [
                {"ordem": 1, "id_localidade": 1, "distancia_km": 0},
                {"ordem": 2, "id_localidade": 1, "distancia_km": 5},
            ]
        },
        200,
    ),
    (
        "POST",
        "/eventos/1/equipe",
        "definir_apoio",
        {"equipe": [{"id_recurso": 1, "papel": "LIDER"}]},
        200,
    ),
    (
        "POST",
        "/eventos/1/logistica",
        "definir_apoio",
        {"apoio": [{"id_recurso": 1, "finalidade": "APOIO"}]},
        200,
    ),
    (
        "POST",
        "/inscricoes/1/passagens",
        "registrar_passagem",
        {"id_ponto": 1, "instante": NOW.isoformat()},
        201,
    ),
    (
        "POST",
        "/eventos/1/ocorrencias",
        "registrar_ocorrencia",
        {"tipo": "MECANICA", "gravidade": "BAIXA", "motivo": "OPERACIONAL"},
        201,
    ),
    (
        "PATCH",
        "/ocorrencias/1",
        "alterar_ocorrencia",
        {"status": "RESOLVIDA", "motivo": "TRATAMENTO_CONCLUIDO"},
        200,
    ),
    ("POST", "/eventos/1/reconciliacao", "reconciliar", {}, 200),
    ("POST", "/eventos/1/expiracao", "expirar_evento", {}, 200),
    ("POST", "/inscricoes/1/avaliacao", "avaliar", {"nota": 5}, 201),
    (
        "POST",
        "/pendencias/1/tratamento",
        "tratar_pendencia",
        {"referencia_tratamento": "FIN-1", "motivo": "TRATAMENTO_CONCLUIDO"},
        200,
    ),
]


@pytest.fixture
def client() -> Generator[TestClient]:
    app = create_app()
    app.dependency_overrides[get_session] = lambda: MagicMock()
    app.dependency_overrides[obter_contexto_rbac] = lambda: ATOR
    with TestClient(app) as client:
        yield client
    app.dependency_overrides.clear()


def _executar(**kw: Any) -> ResultadoComando:
    return cast(
        ResultadoComando,
        kw["comando"](ContextoComando(MagicMock(), ATOR, kw["correlation_id"], NOW)),
    )


@pytest.mark.parametrize("method,path,handler,atributos,status", COMANDOS)
def test_comandos_http_propagam_correlacao_e_status(
    client: TestClient,
    method: str,
    path: str,
    handler: str,
    atributos: dict[str, object],
    status: int,
) -> None:
    payload = {**atributos, "chave_idempotencia": "k"}
    if handler not in {"criar_recurso", "registrar_ocorrencia"}:
        payload["versao_esperada"] = 1
    registro: dict[str, object] = {
        "id": 1,
        "versao": 1,
        "created_at": "2026-09-23T12:00:00Z",
        "updated_at": None,
    }

    recurso: dict[str, object] = {
        **registro,
        "codigo": "B1",
        "tipo": "BICICLETA",
        "status": "DISPONIVEL",
        "id_ativo": None,
        "id_guia": None,
        "id_transporte": None,
    }

    inscricao_pendente: dict[str, object] = {
        **registro,
        "id_evento_bike_tour": 1,
        "id_reserva": 1,
        "id_passageiro": 1,
        "papel": "CICLISTA",
        "status": "PENDENTE",
        "expira_em": "2026-09-23T12:00:00Z",
        "alocacoes": [1],
        "origem_valida": True,
    }

    inscricao_confirmada: dict[str, object] = {
        **registro,
        "id_evento_bike_tour": 1,
        "id_reserva": 1,
        "id_passageiro": 1,
        "papel": "CICLISTA",
        "status": "CONFIRMADA",
        "expira_em": None,
        "alocacoes": [1],
        "origem_valida": True,
    }

    ponto: dict[str, object] = {
        **registro,
        "id_evento_bike_tour": 1,
        "ordem": 1,
        "id_localidade": 1,
        "distancia_km": "10.00",
    }

    equipe: dict[str, object] = {
        **registro,
        "id_evento_bike_tour": 1,
        "id_recurso_bike_tour": 1,
        "papel": "LIDER",
    }

    logistica: dict[str, object] = {
        **registro,
        "id_evento_bike_tour": 1,
        "id_recurso_bike_tour": 1,
        "finalidade": "APOIO",
    }

    passagem: dict[str, object] = {
        **registro,
        "id_inscricao_bike_tour": 1,
        "id_ponto_controle_bike_tour": 1,
        "instante": "2026-09-23T12:00:00Z",
    }

    ocorrencia: dict[str, object] = {
        **registro,
        "id_evento_bike_tour": 1,
        "id_inscricao_bike_tour": None,
        "tipo": "OPERACIONAL",
        "gravidade": "BAIXA",
        "status": "ABERTA",
        "motivo": "TESTE",
    }

    avaliacao: dict[str, object] = {
        **registro,
        "id_inscricao_bike_tour": 1,
        "nota": 5,
    }

    pendencia: dict[str, object] = {
        **registro,
        "id_evento_bike_tour": 1,
        "id_inscricao_bike_tour": 1,
        "id_operacao_bike_tour": 1,
        "tipo": "CANCELAMENTO",
        "status": "TRATADA",
        "motivo": "OPERACIONAL",
        "referencia_tratamento": "REF-1",
    }

    corpos: dict[
        tuple[str, str],
        dict[str, object] | list[dict[str, object]],
    ] = {
        ("criar_recurso", "/recursos"): recurso,
        ("alterar_recurso", "/recursos/1"): recurso,
        ("bloquear", "/eventos/1/inscricoes"): inscricao_pendente,
        ("acionar_inscricao", "/inscricoes/1/acoes"): inscricao_confirmada,
        ("reacomodar", "/inscricoes/1/recursos"): inscricao_pendente,
        ("definir_pontos", "/eventos/1/pontos"): [ponto],
        ("definir_apoio", "/eventos/1/equipe"): [equipe],
        ("definir_apoio", "/eventos/1/logistica"): [logistica],
        ("registrar_passagem", "/inscricoes/1/passagens"): passagem,
        ("registrar_ocorrencia", "/eventos/1/ocorrencias"): ocorrencia,
        ("alterar_ocorrencia", "/ocorrencias/1"): ocorrencia,
        ("reconciliar", "/eventos/1/reconciliacao"): {
            "id_evento_bike_tour": 1,
            "tratadas": [],
            "proximo_cursor": None,
        },
        ("expirar_evento", "/eventos/1/expiracao"): {
            "id_evento_bike_tour": 1,
            "expiradas": [],
        },
        ("avaliar", "/inscricoes/1/avaliacao"): avaliacao,
        ("tratar_pendencia", "/pendencias/1/tratamento"): pendencia,
    }

    corpo = corpos[(handler, path)]
    correlation = uuid4()
    with (
        patch(
            "app.modules.biketour.operational_router.BikeTourUnitOfWork.executar",
            side_effect=_executar,
        ) as uow,
        patch(
            f"app.modules.biketour.operations.OperacoesBikeTour.{handler}",
            return_value=ResultadoComando(status, corpo),
        ) as command,
    ):
        response = client.request(
            method, BASE + path, json=payload, headers={"X-Correlation-Id": str(correlation)}
        )
    assert response.status_code == status, response.text
    assert response.json() == corpo
    assert uow.call_args.kwargs["correlation_id"] == correlation
    command.assert_called_once()


@pytest.mark.parametrize(
    "path,handler,resultado",
    [
        ("/recursos", "listar", []),
        ("/eventos/1/inscricoes", "inscricoes", []),
        ("/eventos/1/ocorrencias", "listar", []),
        ("/eventos/1/pendencias", "listar", []),
        (
            "/inscricoes/1/origem",
            "correlacao",
            {
                "id_reserva": 1,
                "id_venda": None,
                "id_item_venda": None,
                "id_contrato": None,
                "origem_valida": True,
            },
        ),
        (
            "/eventos/1/disponibilidade",
            "disponibilidade",
            {
                "id_evento_bike_tour": 1,
                "capacidade": 10,
                "comprometidas": 2,
                "saldo": 8,
                "recursos": [],
            },
        ),
        (
            "/eventos/1/relatorio",
            "relatorio",
            {
                "id_evento_bike_tour": 1,
                "inscricoes": {"CONFIRMADA": 1},
                "ids_inscricoes": [1],
                "passagens": 1,
                "ocorrencias": {"ABERTA": 1},
            },
        ),
        ("/eventos/1/auditoria", "auditoria", []),
    ],
)
def test_consultas_http(client: TestClient, path: str, handler: str, resultado: object) -> None:
    with patch(f"app.modules.biketour.queries.ConsultasBikeTour.{handler}", return_value=resultado):
        assert client.get(BASE + path).json() == resultado


@pytest.mark.parametrize(
    "exc,status",
    [(BikeTourError(404, "AUSENTE"), 404), (OperationalError("privado", {}, Exception()), 503)],
)
def test_consulta_mapeia_falha_sem_expor_sql(
    client: TestClient, exc: Exception, status: int
) -> None:
    with patch("app.modules.biketour.queries.ConsultasBikeTour.listar", side_effect=exc):
        response = client.get(BASE + "/recursos")
    assert response.status_code == status
    assert "privado" not in response.text


def test_disponibilidade_preserva_schema_publicado_de_turismo(client: TestClient) -> None:
    schema = client.get("/openapi.json").json()
    paths = schema["paths"]
    turismo = paths["/api/v1/turismo/saidas/{identifier}/disponibilidade"]["get"]
    biketour = paths[BASE + "/eventos/{identifier}/disponibilidade"]["get"]
    assert turismo["responses"]["200"]["content"]["application/json"]["schema"] == {
        "$ref": "#/components/schemas/DisponibilidadeResponse"
    }
    assert biketour["responses"]["200"]["content"]["application/json"]["schema"] == {
        "$ref": "#/components/schemas/DisponibilidadeBikeTourResponse"
    }
    assert "DisponibilidadeResponse" in schema["components"]["schemas"]


def test_mutacao_mapeia_conflito(client: TestClient) -> None:
    with patch(
        "app.modules.biketour.operational_router.BikeTourUnitOfWork.executar",
        side_effect=BikeTourError(409, "CONFLITO"),
    ):
        response = client.post(
            BASE + "/recursos",
            json={"codigo": "B1", "tipo": "BICICLETA", "chave_idempotencia": "k"},
        )
    assert response.status_code == 409


@pytest.mark.parametrize("permissoes", [set(), {"BIKE_TOUR_VISUALIZAR"}, {"BIKE_TOUR_OPERAR"}])
def test_operar_exige_visualizar_e_operar(client: TestClient, permissoes: set[str]) -> None:
    cast(FastAPI, client.app).dependency_overrides[obter_contexto_rbac] = lambda: ContextoRbac(
        1, (), frozenset(permissoes)
    )
    response = client.post(
        BASE + "/eventos/1/expiracao", json={"versao_esperada": 1, "chave_idempotencia": "k"}
    )
    assert response.status_code == 403
