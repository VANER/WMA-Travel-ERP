"""Testes do contrato OpenAPI e das interfaces de documentação."""

from fastapi.testclient import TestClient


def test_documentation_interfaces_are_available(client: TestClient) -> None:
    docs_response = client.get("/docs")
    redoc_response = client.get("/redoc")

    assert docs_response.status_code == 200
    assert "text/html" in docs_response.headers["content-type"]
    assert redoc_response.status_code == 200
    assert "text/html" in redoc_response.headers["content-type"]


def test_openapi_has_required_metadata_and_versioned_paths(client: TestClient) -> None:
    response = client.get("/openapi.json")
    schema = response.json()

    assert response.status_code == 200
    assert response.headers["content-type"].startswith("application/json")
    assert schema["openapi"].startswith("3.1.")
    assert schema["info"]["title"] == "WMA Travel ERP API"
    assert schema["info"]["summary"] == "API corporativa do WMA Travel ERP"
    assert schema["info"]["version"] == "0.1.0-dev"
    assert "X-Correlation-Id" in schema["info"]["description"]
    assert "/health" in schema["paths"]
    assert "/api/v1/health" in schema["paths"]
    assert "/api/v1/health/database" in schema["paths"]


def test_openapi_exposes_typed_success_and_error_schemas(client: TestClient) -> None:
    schema = client.get("/openapi.json").json()
    components = schema["components"]["schemas"]
    health_operation = schema["paths"]["/api/v1/health"]["get"]
    database_operation = schema["paths"]["/api/v1/health/database"]["get"]

    assert {"HealthResponse", "DatabaseHealthResponse", "ErrorDetail", "ErrorResponse"} <= set(
        components
    )
    assert health_operation["responses"]["200"]["content"]["application/json"]["schema"] == {
        "$ref": "#/components/schemas/HealthResponse"
    }
    assert database_operation["responses"]["503"]["content"]["application/json"]["schema"] == {
        "$ref": "#/components/schemas/ErrorResponse"
    }
    assert health_operation["responses"]["404"]["content"]["application/json"]["schema"] == {
        "$ref": "#/components/schemas/ErrorResponse"
    }


def test_openapi_operation_ids_are_unique(client: TestClient) -> None:
    schema = client.get("/openapi.json").json()
    operation_ids = [
        operation["operationId"]
        for path_item in schema["paths"].values()
        for method, operation in path_item.items()
        if method in {"get", "post", "put", "patch", "delete"}
    ]

    assert len(operation_ids) == len(set(operation_ids))


def test_openapi_operations_have_governance_metadata(client: TestClient) -> None:
    schema = client.get("/openapi.json").json()
    operations = [
        operation
        for path_item in schema["paths"].values()
        for method, operation in path_item.items()
        if method in {"get", "post", "put", "patch", "delete"}
    ]

    assert operations
    assert all(operation.get("operationId") for operation in operations)
    assert all(operation.get("tags") for operation in operations)
    assert all("responses" in operation for operation in operations)
    assert all(
        any(status_code.startswith("2") for status_code in operation["responses"])
        for operation in operations
    )
