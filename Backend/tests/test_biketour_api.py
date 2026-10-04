"""Certificacao HTTP da API de Produto e Evento Bike Tour."""

from collections.abc import Iterator
from contextlib import contextmanager
from datetime import UTC, datetime
from decimal import Decimal
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.exc import OperationalError, TimeoutError

from app.db.session import get_session
from app.main import create_app
from app.modules.biketour.errors import BikeTourError
from app.modules.seguranca.authorization import obter_contexto_rbac
from app.modules.seguranca.rbac import ContextoRbac

BASE = "/api/v1/biketour"
NOW = datetime(2026, 9, 21, 12, tzinfo=UTC)


def produto() -> SimpleNamespace:
    return SimpleNamespace(
        id_produto_bike_tour=10,
        id_produto=20,
        distancia_km=Decimal("12.50"),
        desnivel_m=Decimal("240.00"),
        nivel="INTERMEDIARIO",
        ativo=True,
        versao=1,
        created_at=NOW,
        updated_at=None,
        deleted_at=None,
    )


def evento() -> SimpleNamespace:
    return SimpleNamespace(
        id_evento_bike_tour=30,
        id_saida=40,
        inicio=NOW,
        fim=NOW.replace(hour=16),
        capacidade=12,
        status="PLANEJADO",
        versao=1,
        created_at=NOW,
        updated_at=None,
        deleted_at=None,
    )


@contextmanager
def cliente_com_permissoes(
    permissoes: set[str],
    *,
    session_get: object | None = None,
    session: MagicMock | None = None,
    papeis: tuple[str, ...] = (),
) -> Iterator[TestClient]:
    app = create_app()
    session = session if session is not None else MagicMock()
    session.get.return_value = session_get
    app.dependency_overrides[get_session] = lambda: session
    app.dependency_overrides[obter_contexto_rbac] = lambda: ContextoRbac(
        id_usuario=7,
        papeis=papeis,
        permissoes=frozenset(permissoes),
    )
    try:
        with TestClient(app, raise_server_exceptions=False) as client:
            yield client
    finally:
        app.dependency_overrides.clear()


def headers() -> dict[str, str]:
    return {"X-Correlation-Id": "7f7d9d2d-4c5b-4af1-9f7d-2d7d9d2d4c5b"}


def produto_payload() -> dict[str, object]:
    return {
        "id_produto": 20,
        "distancia_km": "12.50",
        "desnivel_m": "240.00",
        "nivel": "INTERMEDIARIO",
        "chave_idempotencia": "produto-api-1",
    }


def evento_payload() -> dict[str, object]:
    return {
        "id_saida": 40,
        "inicio": "2026-09-21T12:00:00Z",
        "fim": "2026-09-21T16:00:00Z",
        "capacidade": 12,
        "chave_idempotencia": "evento-api-1",
    }


def test_sem_autenticacao_retorna_401() -> None:
    with TestClient(create_app()) as client:
        response = client.get(f"{BASE}/produtos")
    assert response.status_code == 401


def test_token_invalido_retorna_401() -> None:
    app = create_app()
    app.dependency_overrides[get_session] = lambda: MagicMock()
    try:
        with TestClient(app) as client:
            response = client.get(f"{BASE}/produtos", headers={"Authorization": "Bearer invalido"})
    finally:
        app.dependency_overrides.clear()
    assert response.status_code == 401


@pytest.mark.parametrize("path", ("/produtos", "/eventos"))
def test_sem_visualizar_retorna_403(path: str) -> None:
    with cliente_com_permissoes(set()) as client:
        response = client.get(BASE + path, headers=headers())
    assert response.status_code == 403


def test_visualizar_permite_listagem_de_produto() -> None:
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR"}) as client,
    ):
        response = client.get(f"{BASE}/produtos", headers=headers())
    assert response.status_code == 200


def test_visualizar_sem_gerenciar_bloqueia_mutacao() -> None:
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR"}) as client,
        patch("app.modules.biketour.router.criar_produto") as service,
    ):
        response = client.post(BASE + "/produtos", json=produto_payload(), headers=headers())
    assert response.status_code == 403
    service.assert_not_called()


def test_criar_produto_com_gerenciar() -> None:
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}) as client,
        patch("app.modules.biketour.router.criar_produto", return_value=produto()) as service,
    ):
        response = client.post(BASE + "/produtos", json=produto_payload(), headers=headers())
    assert response.status_code == 201
    assert response.json()["id_produto_bike_tour"] == 10
    service.assert_called_once()


def test_produto_payload_invalido_retorna_422() -> None:
    payload = produto_payload()
    payload["distancia_km"] = 0
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}) as client,
        patch("app.modules.biketour.router.criar_produto") as service,
    ):
        response = client.post(BASE + "/produtos", json=payload, headers=headers())
    assert response.status_code == 422
    service.assert_not_called()


def test_produto_service_error_e_convertido_para_http() -> None:
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}) as client,
        patch(
            "app.modules.biketour.router.criar_produto",
            side_effect=BikeTourError(404, "BT_PRODUTO_ORIGEM_NAO_ENCONTRADO"),
        ),
    ):
        response = client.post(BASE + "/produtos", json=produto_payload(), headers=headers())
    assert response.status_code == 404


def test_alterar_produto_com_versao() -> None:
    payload = {
        "ativo": False,
        "versao_esperada": 1,
        "chave_idempotencia": "produto-api-2",
    }
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}) as client,
        patch("app.modules.biketour.router.alterar_produto", return_value=produto()) as service,
    ):
        response = client.patch(BASE + "/produtos/10", json=payload, headers=headers())
    assert response.status_code == 200
    service.assert_called_once()


def test_listar_eventos_e_consultar_evento() -> None:
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR"}) as client,
    ):
        lista = client.get(BASE + "/eventos", headers=headers())
        individual = client.get(BASE + "/eventos/30", headers=headers())
    assert lista.status_code == 200
    assert individual.status_code == 404


def test_consultar_evento_existente_retorna_projecao() -> None:
    with cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR"}, session_get=evento()) as client:
        response = client.get(BASE + "/eventos/30", headers=headers())
    assert response.status_code == 200
    assert response.json()["id_evento_bike_tour"] == 30


def test_criar_evento_com_gerenciar() -> None:
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}) as client,
        patch("app.modules.biketour.router.criar_evento", return_value=evento()) as service,
    ):
        response = client.post(BASE + "/eventos", json=evento_payload(), headers=headers())
    assert response.status_code == 201
    assert response.json()["status"] == "PLANEJADO"
    service.assert_called_once()


@pytest.mark.parametrize(
    "field,value",
    (("capacidade", 0), ("inicio", "2026-09-21T16:00:00Z")),
)
def test_evento_payload_invalido_retorna_422(field: str, value: object) -> None:
    payload = evento_payload()
    payload[field] = value
    if field == "inicio":
        payload["fim"] = "2026-09-21T12:00:00Z"
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}) as client,
        patch("app.modules.biketour.router.criar_evento") as service,
    ):
        response = client.post(BASE + "/eventos", json=payload, headers=headers())
    assert response.status_code == 422
    service.assert_not_called()


def test_evento_service_error_e_convertido_para_http() -> None:
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}) as client,
        patch(
            "app.modules.biketour.router.criar_evento",
            side_effect=BikeTourError(409, "BT_CAPACIDADE_SAIDA"),
        ),
    ):
        response = client.post(BASE + "/eventos", json=evento_payload(), headers=headers())
    assert response.status_code == 409


@pytest.mark.parametrize("path", ["/produtos", "/eventos", "/eventos/30"])
@pytest.mark.parametrize(
    "falha", [OperationalError("SQL privado", {}, Exception("segredo")), TimeoutError("segredo")]
)
def test_leitura_indisponivel_retorna_503_seguro(path: str, falha: Exception) -> None:
    session = MagicMock()
    session.get.side_effect = falha
    session.scalars.side_effect = falha
    with cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR"}, session=session) as client:
        response = client.get(BASE + path, headers=headers())
    assert response.status_code == 503
    assert "segredo" not in response.text and "SQL privado" not in response.text
    assert response.json()["correlation_id"] == headers()["X-Correlation-Id"]


@pytest.mark.parametrize("recurso", ["produtos", "eventos"])
def test_listagem_retorna_projecao_e_paginacao(recurso: str) -> None:
    session = MagicMock()
    item = produto() if recurso == "produtos" else evento()
    session.scalars.return_value.all.return_value = [item]
    with cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR"}, session=session) as client:
        response = client.get(f"{BASE}/{recurso}?offset=2&limite=3")
    assert response.status_code == 200
    assert len(response.json()) == 1
    assert "deleted_at" not in response.json()[0]
    statement = session.scalars.call_args.args[0]
    assert statement.compile().params == {"param_1": 3, "param_2": 2}
    assert "deleted_at IS NULL" in str(statement)
    assert "ORDER BY" in str(statement)


@pytest.mark.parametrize("recurso", ["produtos", "eventos"])
@pytest.mark.parametrize("query", ["offset=-1", "limite=0", "limite=101"])
def test_paginacao_invalida_retorna_422(recurso: str, query: str) -> None:
    with cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR"}) as client:
        response = client.get(f"{BASE}/{recurso}?{query}")
    assert response.status_code == 422


@pytest.mark.parametrize("permissoes", [set(), {"BIKE_TOUR_GERENCIAR"}, {"BIKE_TOUR_VISUALIZAR"}])
@pytest.mark.parametrize("papeis", [(), ("ADMIN",)])
def test_matriz_rbac_sem_hierarquia_ou_bypass(
    permissoes: set[str], papeis: tuple[str, ...]
) -> None:
    with cliente_com_permissoes(permissoes, papeis=papeis) as client:
        for path, method, payload in (
            ("/produtos", "POST", produto_payload()),
            ("/eventos", "POST", evento_payload()),
            (
                "/produtos/10",
                "PATCH",
                {"ativo": False, "versao_esperada": 1, "chave_idempotencia": "rbac"},
            ),
            (
                "/eventos/30",
                "PATCH",
                {"capacidade": 5, "versao_esperada": 1, "chave_idempotencia": "rbac"},
            ),
            (
                "/eventos/30/acoes",
                "POST",
                {"acao": "ABRIR", "versao_esperada": 1, "chave_idempotencia": "rbac"},
            ),
        ):
            assert client.request(method, BASE + path, json=payload).status_code == 403
        expected = 200 if "BIKE_TOUR_VISUALIZAR" in permissoes else 403
        for path in ("/produtos", "/eventos"):
            assert client.get(BASE + path).status_code == expected


def test_motivo_livre_rejeitado_antes_do_comando() -> None:
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}) as client,
        patch("app.modules.biketour.router.acionar_evento") as service,
    ):
        response = client.post(
            BASE + "/eventos/30/acoes",
            json={
                "acao": "CANCELAR",
                "motivo": "texto pessoal nao permitido",
                "versao_esperada": 1,
                "chave_idempotencia": "privacidade",
            },
        )
    assert response.status_code == 422
    assert "texto pessoal nao permitido" not in response.text
    service.assert_not_called()


def test_erro_inesperado_nao_expoe_detalhes() -> None:
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}) as client,
        patch("app.modules.biketour.router.criar_produto", side_effect=RuntimeError("SQL segredo")),
    ):
        response = client.post(BASE + "/produtos", json=produto_payload())
    assert response.status_code == 500
    assert "SQL segredo" not in response.text


def test_openapi_produto_evento_documenta_erros_e_ids_unicos() -> None:
    schema = create_app().openapi()
    operations = []
    for path, methods in schema["paths"].items():
        for method, operation in methods.items():
            if method not in {"get", "post", "patch", "put", "delete"}:
                continue
            operations.append(operation["operationId"])
            if path in {
                BASE + suffix
                for suffix in (
                    "/produtos",
                    "/produtos/{identifier}",
                    "/eventos",
                    "/eventos/{identifier}",
                    "/eventos/{identifier}/acoes",
                )
            }:
                expected = {"401", "403", "422", "500", "503"}
                if method != "get":
                    expected |= {"404", "409"}
                elif "{identifier}" in path:
                    expected.add("404")
                assert expected <= operation["responses"].keys()
                for code in expected:
                    assert operation["responses"][code]["content"]["application/json"][
                        "schema"
                    ] == {"$ref": "#/components/schemas/ErrorResponse"}
    assert len(operations) == len(set(operations))


def test_alterar_evento_e_acionar_transicao() -> None:
    update = {
        "capacidade": 10,
        "versao_esperada": 1,
        "chave_idempotencia": "evento-api-2",
    }
    action = {
        "acao": "ABRIR",
        "versao_esperada": 1,
        "chave_idempotencia": "evento-api-3",
    }
    permissoes = {"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}
    with (
        cliente_com_permissoes(permissoes) as client,
        patch(
            "app.modules.biketour.router.alterar_evento", return_value=evento()
        ) as update_service,
        patch(
            "app.modules.biketour.router.acionar_evento", return_value=evento()
        ) as action_service,
    ):
        updated = client.patch(BASE + "/eventos/30", json=update, headers=headers())
        acted = client.post(BASE + "/eventos/30/acoes", json=action, headers=headers())
    assert updated.status_code == 200
    assert acted.status_code == 200
    update_service.assert_called_once()
    action_service.assert_called_once()


def test_acao_evento_service_error_e_convertido_para_http() -> None:
    payload = {
        "acao": "ABRIR",
        "versao_esperada": 1,
        "chave_idempotencia": "evento-api-error",
    }
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}) as client,
        patch(
            "app.modules.biketour.router.acionar_evento",
            side_effect=BikeTourError(409, "BT_TRANSICAO_EVENTO_INVALIDA"),
        ),
    ):
        response = client.post(BASE + "/eventos/30/acoes", json=payload, headers=headers())
    assert response.status_code == 409


def test_evento_inexistente_retorna_404() -> None:
    with cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR"}) as client:
        response = client.get(BASE + "/eventos/999", headers=headers())
    assert response.status_code == 404


def test_evento_excluido_retorna_404() -> None:
    item = evento()
    item.deleted_at = NOW
    with cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR"}, session_get=item) as client:
        response = client.get(BASE + "/eventos/30", headers=headers())
    assert response.status_code == 404


@pytest.mark.parametrize(
    "recurso,servico",
    [
        ("produtos", "alterar_produto"),
        ("eventos", "alterar_evento"),
    ],
)
def test_patch_propaga_conflito_de_versao(recurso: str, servico: str) -> None:
    payload: dict[str, object] = {"versao_esperada": 1, "chave_idempotencia": "conflito"}
    if recurso == "produtos":
        payload["ativo"] = False
    else:
        payload["capacidade"] = 5
    with (
        cliente_com_permissoes({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}) as client,
        patch(
            f"app.modules.biketour.router.{servico}",
            side_effect=BikeTourError(409, "BT_VERSAO_DIVERGENTE"),
        ),
    ):
        response = client.patch(f"{BASE}/{recurso}/10", json=payload, headers=headers())
    assert response.status_code == 409
