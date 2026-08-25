"""Gates HTTP da API do Core Corporativo."""

from collections.abc import Iterator
from contextlib import contextmanager
from unittest.mock import MagicMock, create_autospec

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db.base import Base
from app.db.session import get_session
from app.main import app

RESOURCES = (
    ("localidades", {"cidade": "Recife", "pais": "Brasil"}, "id_localidade"),
    (
        "pessoas",
        {"tipo_pessoa": "FISICA", "nome_razao_social": "Ana", "id_localidade": 1},
        "id_pessoa",
    ),
    (
        "empresas",
        {"razao_social": "Empresa", "nome_fantasia": "Empresa", "id_localidade": 1},
        "id_empresa",
    ),
    ("clientes", {"id_pessoa": 1}, "id_cliente"),
    ("fornecedores", {"id_pessoa": 1}, "id_fornecedor"),
    (
        "tipos-documento",
        {"codigo": "PASSAPORTE", "descricao": "Passaporte"},
        "id_tipo_documento",
    ),
    ("documentos", {"id_tipo_documento": 1}, "id_documento"),
    ("configuracoes-empresa", {"id_empresa": 1}, "id_configuracao"),
    ("parametros-sistema", {"codigo": "IDIOMA"}, "id_parametro"),
)


@contextmanager
def _overridden_session(session: Session) -> Iterator[None]:
    app.dependency_overrides[get_session] = lambda: session
    try:
        yield
    finally:
        app.dependency_overrides.pop(get_session, None)


@pytest.mark.parametrize(("resource", "_payload", "_identifier"), RESOURCES)
def test_list_endpoints_return_paginated_collections(
    client: TestClient,
    resource: str,
    _payload: dict[str, object],
    _identifier: str,
) -> None:
    session = create_autospec(Session, instance=True)
    scalar_result = MagicMock()
    scalar_result.all.return_value = []
    session.scalars.return_value = scalar_result

    with _overridden_session(session):
        response = client.get(f"/api/v1/{resource}?offset=2&limite=5")

    assert response.status_code == 200
    assert response.json() == []
    session.scalars.assert_called_once()
    session.commit.assert_not_called()


@pytest.mark.parametrize(("resource", "payload", "identifier"), RESOURCES)
def test_create_endpoints_return_201_and_server_identity(
    client: TestClient, resource: str, payload: dict[str, object], identifier: str
) -> None:
    session = create_autospec(Session, instance=True)

    def assign_identity() -> None:
        entity = session.add.call_args.args[0]
        setattr(entity, identifier, 101)

    session.flush.side_effect = assign_identity

    with _overridden_session(session):
        response = client.post(f"/api/v1/{resource}", json=payload)

    assert response.status_code == 201
    assert response.json()[identifier] == 101
    session.commit.assert_called_once_with()
    session.rollback.assert_not_called()


@pytest.mark.parametrize(("resource", "payload", "identifier"), RESOURCES)
def test_get_endpoints_return_the_requested_resource(
    client: TestClient, resource: str, payload: dict[str, object], identifier: str
) -> None:
    session = create_autospec(Session, instance=True)

    def load_entity(model_type: type[Base], identity: int) -> Base:
        entity = model_type(**payload)
        setattr(entity, identifier, identity)
        return entity

    session.get.side_effect = load_entity

    with _overridden_session(session):
        response = client.get(f"/api/v1/{resource}/77")

    assert response.status_code == 200
    assert response.json()[identifier] == 77
    session.commit.assert_not_called()


def test_get_endpoint_returns_standard_not_found(client: TestClient) -> None:
    session = create_autospec(Session, instance=True)
    session.get.return_value = None

    with _overridden_session(session):
        response = client.get("/api/v1/localidades/999")

    assert response.status_code == 404
    assert response.json()["code"] == "NOT_FOUND"
    assert "X-Correlation-Id" in response.headers


def test_pagination_is_validated_before_query(client: TestClient) -> None:
    session = create_autospec(Session, instance=True)

    with _overridden_session(session):
        response = client.get("/api/v1/localidades?offset=-1&limite=1001")

    assert response.status_code == 422
    assert response.json()["code"] == "VALIDATION_ERROR"
    session.scalars.assert_not_called()


def test_identifier_is_validated_before_query(client: TestClient) -> None:
    session = create_autospec(Session, instance=True)

    with _overridden_session(session):
        response = client.get("/api/v1/localidades/0")

    assert response.status_code == 422
    assert response.json()["code"] == "VALIDATION_ERROR"
    session.get.assert_not_called()


def test_integrity_errors_return_safe_conflict(client: TestClient) -> None:
    session = create_autospec(Session, instance=True)
    session.flush.side_effect = IntegrityError("statement", {}, RuntimeError("constraint"))

    with _overridden_session(session):
        response = client.post("/api/v1/localidades", json={"cidade": "Recife"})

    assert response.status_code == 409
    assert response.json()["code"] == "RESOURCE_CONFLICT"
    assert "constraint" not in response.text
    session.rollback.assert_called_once_with()


def test_openapi_exposes_all_core_resources_and_contracts(client: TestClient) -> None:
    schema = client.get("/openapi.json").json()

    for resource, _payload, _identifier in RESOURCES:
        collection = schema["paths"][f"/api/v1/{resource}"]
        item = schema["paths"][f"/api/v1/{resource}/{{identifier}}"]
        assert {"get", "post"} <= set(collection)
        assert "get" in item
        assert collection["post"]["responses"]["201"]
        assert collection["post"]["responses"]["409"]["content"]["application/json"]["schema"] == {
            "$ref": "#/components/schemas/ErrorResponse"
        }
        assert collection["get"]["tags"] == ["core-corporativo"]
