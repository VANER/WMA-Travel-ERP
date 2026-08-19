"""Testes dos contratos técnicos de disponibilidade."""

from uuid import UUID

from fastapi.testclient import TestClient


def test_root_health(client: TestClient) -> None:
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "version": "2.0.2"}
    UUID(response.headers["X-Correlation-Id"])


def test_versioned_health_reuses_valid_correlation_id(client: TestClient) -> None:
    correlation_id = "6c64c6a2-bb73-48a5-bec3-aeaf893e1a8e"
    response = client.get("/api/v1/health", headers={"X-Correlation-Id": correlation_id})

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "version": "2.0.2"}
    assert response.headers["X-Correlation-Id"] == correlation_id


def test_invalid_correlation_id_is_replaced(client: TestClient) -> None:
    response = client.get("/health", headers={"X-Correlation-Id": "invalido"})

    assert response.status_code == 200
    assert response.headers["X-Correlation-Id"] != "invalido"
    UUID(response.headers["X-Correlation-Id"])
