"""Testes dos contratos técnicos de disponibilidade."""

from unittest.mock import patch
from uuid import UUID

from fastapi.testclient import TestClient


def test_root_health(client: TestClient) -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "version": "0.1.0-dev"}
    UUID(response.headers["X-Correlation-Id"])


def test_versioned_health_reuses_valid_correlation_id(client: TestClient) -> None:
    correlation_id = "6c64c6a2-bb73-48a5-bec3-aeaf893e1a8e"
    response = client.get("/api/v1/health", headers={"X-Correlation-Id": correlation_id})

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "version": "0.1.0-dev"}
    assert response.headers["X-Correlation-Id"] == correlation_id


def test_invalid_correlation_id_is_replaced(client: TestClient) -> None:
    response = client.get("/health", headers={"X-Correlation-Id": "invalido"})

    assert response.status_code == 200
    assert response.headers["X-Correlation-Id"] != "invalido"
    UUID(response.headers["X-Correlation-Id"])


def test_database_health_reports_available(client: TestClient) -> None:
    with patch("app.api.v1.router.database_is_available", return_value=True):
        response = client.get("/api/v1/health/database")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "database": "available"}


def test_database_health_returns_safe_503(client: TestClient) -> None:
    with patch("app.api.v1.router.database_is_available", return_value=False):
        response = client.get("/api/v1/health/database")

    assert response.status_code == 503
    assert response.json()["code"] == "DATABASE_UNAVAILABLE"
    assert response.json()["message"] == "Banco de dados temporariamente indisponível."
    UUID(response.json()["correlation_id"])
