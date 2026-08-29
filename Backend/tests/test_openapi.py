"""Testes do contrato OpenAPI e das interfaces de documentação."""

import ast
import json
from pathlib import Path

from fastapi.testclient import TestClient

OPENAPI_SNAPSHOT = Path(__file__).resolve().parents[1] / "openapi.json"
API_DOCUMENTATION = Path(__file__).resolve().parents[2] / "Docs" / "API.md"
ROUTER_SOURCES = (
    Path(__file__).resolve().parents[1] / "app" / "main.py",
    Path(__file__).resolve().parents[1] / "app" / "api" / "v1" / "router.py",
    Path(__file__).resolve().parents[1] / "app" / "modules" / "corporativo" / "router.py",
    Path(__file__).resolve().parents[1] / "app" / "modules" / "seguranca" / "router.py",
)


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


def test_application_routes_declare_operation_ids_explicitly() -> None:
    route_decorators: list[tuple[str, ast.Call]] = []
    for source in ROUTER_SOURCES:
        tree = ast.parse(source.read_text(encoding="utf-8"))
        for node in ast.walk(tree):
            if not isinstance(node, ast.FunctionDef | ast.AsyncFunctionDef):
                continue
            for decorator in node.decorator_list:
                if (
                    isinstance(decorator, ast.Call)
                    and isinstance(decorator.func, ast.Attribute)
                    and decorator.func.attr in {"get", "post", "put", "patch", "delete"}
                ):
                    route_decorators.append((decorator.func.attr, decorator))

    assert len(route_decorators) == 35
    for method, decorator in route_decorators:
        operation_ids = [
            keyword.value for keyword in decorator.keywords if keyword.arg == "operation_id"
        ]
        assert len(operation_ids) == 1
        assert isinstance(operation_ids[0], ast.Constant)
        assert isinstance(operation_ids[0].value, str)
        assert operation_ids[0].value.endswith(f"_{method}")


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


def test_openapi_responses_follow_governance_matrix(client: TestClient) -> None:
    paths = client.get("/openapi.json").json()["paths"]
    baseline = {"404", "405", "409", "422", "500"}

    for path_item in paths.values():
        for method, operation in path_item.items():
            if method in {"get", "post", "put", "patch", "delete"}:
                assert baseline <= operation["responses"].keys()

    assert "503" in paths["/api/v1/health/database"]["get"]["responses"]
    assert "401" in paths["/api/v1/auth/login"]["post"]["responses"]
    assert "401" in paths["/api/v1/auth/refresh"]["post"]["responses"]
    assert "503" in paths["/api/v1/auth/recovery/request"]["post"]["responses"]
    assert "400" in paths["/api/v1/auth/recovery/reset"]["post"]["responses"]

    for path, path_item in paths.items():
        if not path.startswith("/api/v1/"):
            continue
        for method, operation in path_item.items():
            if (
                method in {"get", "post", "put", "patch", "delete"}
                and "core-corporativo" in operation["tags"]
            ):
                assert {"401", "403"} <= operation["responses"].keys()


def test_openapi_error_responses_use_standard_schema(client: TestClient) -> None:
    paths = client.get("/openapi.json").json()["paths"]
    for path_item in paths.values():
        for method, operation in path_item.items():
            if method not in {"get", "post", "put", "patch", "delete"}:
                continue
            for status_code, response in operation["responses"].items():
                if status_code.startswith(("4", "5")):
                    assert response["content"]["application/json"]["schema"] == {
                        "$ref": "#/components/schemas/ErrorResponse"
                    }


def test_openapi_matches_versioned_contract(client: TestClient) -> None:
    expected = json.loads(OPENAPI_SNAPSHOT.read_text(encoding="utf-8"))

    assert client.get("/openapi.json").json() == expected


def test_api_documentation_matches_published_pagination_contract() -> None:
    documentation = API_DOCUMENTATION.read_text(encoding="utf-8")

    assert "| offset | Integer | Não | 0 | mínimo 0 |" in documentation
    assert "| limite | Integer | Não | 100 | 1 a 1000 |" in documentation
    assert "GET /api/v1/clientes?offset=0&limite=20" in documentation
    assert "page_size" not in documentation
    assert "?page=" not in documentation
