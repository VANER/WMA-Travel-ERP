"""Testes do classificador de compatibilidade OpenAPI."""

from copy import deepcopy
from typing import Any

from scripts.check_openapi_compatibility import _load_git_snapshot, find_breaking_changes

JsonObject = dict[str, Any]


def _contract() -> JsonObject:
    return {
        "paths": {
            "/api/v1/items": {
                "get": {
                    "operationId": "list_items",
                    "parameters": [{"in": "query", "name": "page", "required": False}],
                    "responses": {"200": {}, "422": {}},
                }
            }
        },
        "components": {
            "schemas": {
                "Item": {
                    "type": "object",
                    "properties": {
                        "id": {"type": "integer"},
                        "status": {"type": "string", "enum": ["active", "inactive"]},
                    },
                    "required": ["id"],
                }
            }
        },
    }


def test_additive_contract_changes_are_compatible() -> None:
    previous = _contract()
    current = deepcopy(previous)
    current["paths"]["/api/v1/items"]["get"]["parameters"].append(
        {"in": "query", "name": "search", "required": False}
    )
    current["components"]["schemas"]["Item"]["properties"]["description"] = {"type": "string"}

    assert find_breaking_changes(previous, current) == []


def test_removed_route_operation_response_and_schema_are_breaking() -> None:
    previous = _contract()

    assert find_breaking_changes(previous, {"paths": {}, "components": {"schemas": {}}}) == [
        "rota removida: /api/v1/items",
        "schema removido: Item",
    ]

    current = deepcopy(previous)
    del current["paths"]["/api/v1/items"]["get"]["responses"]["422"]
    assert find_breaking_changes(previous, current) == ["GET /api/v1/items: resposta 422 removida"]


def test_new_requirements_and_security_are_breaking() -> None:
    previous = _contract()
    current = deepcopy(previous)
    parameter = current["paths"]["/api/v1/items"]["get"]["parameters"][0]
    parameter["required"] = True
    current["paths"]["/api/v1/items"]["get"]["requestBody"] = {"required": True}
    current["paths"]["/api/v1/items"]["get"]["security"] = [{"Bearer": []}]
    current["components"]["schemas"]["Item"]["required"].append("status")

    changes = find_breaking_changes(previous, current)

    assert "GET /api/v1/items: parâmetro tornou-se obrigatório query:page" in changes
    assert "GET /api/v1/items: corpo da requisição tornou-se obrigatório" in changes
    assert "GET /api/v1/items: autenticação passou a ser obrigatória" in changes
    assert "schema Item: propriedade tornou-se obrigatória status" in changes


def test_property_contract_regressions_are_breaking() -> None:
    previous = _contract()
    current = deepcopy(previous)
    del current["components"]["schemas"]["Item"]["properties"]["id"]
    status = current["components"]["schemas"]["Item"]["properties"]["status"]
    status["type"] = "integer"
    status["enum"] = ["active"]

    changes = find_breaking_changes(previous, current)

    assert "schema Item: propriedade removida id" in changes
    assert "schema Item.status: schema alterado" in changes
    assert "schema Item.status: valores de enum removidos" in changes


def test_path_parameters_and_inline_contracts_are_checked() -> None:
    previous = _contract()
    current = deepcopy(previous)
    previous["paths"]["/api/v1/items"]["parameters"] = [
        {"in": "header", "name": "X-Tenant", "required": False, "schema": {"type": "string"}}
    ]
    current["paths"]["/api/v1/items"]["parameters"] = [
        {"in": "header", "name": "X-Tenant", "required": True, "schema": {"type": "integer"}}
    ]
    previous["paths"]["/api/v1/items"]["get"]["responses"]["200"] = {
        "content": {"application/json": {"schema": {"type": "array"}}}
    }
    current["paths"]["/api/v1/items"]["get"]["responses"]["200"] = {"content": {}}

    changes = find_breaking_changes(previous, current)

    assert "rota /api/v1/items: parâmetro tornou-se obrigatório header:X-Tenant" in changes
    assert "rota /api/v1/items: parâmetro header:X-Tenant: schema alterado" in changes
    assert "GET /api/v1/items: resposta 200: tipo de mídia removido application/json" in changes


def test_enum_widening_and_complex_values_do_not_crash() -> None:
    previous = _contract()
    current = deepcopy(previous)
    previous_status = previous["components"]["schemas"]["Item"]["properties"]["status"]
    current_status = current["components"]["schemas"]["Item"]["properties"]["status"]
    previous_status["enum"] = [{"code": "active"}]
    current_status.pop("enum")

    assert find_breaking_changes(previous, current) == []


def test_global_security_and_new_enum_restriction_are_breaking() -> None:
    previous = _contract()
    current = deepcopy(previous)
    current["security"] = [{"Bearer": []}]
    current["components"]["schemas"]["Item"]["properties"]["id"]["enum"] = [1, 2]

    changes = find_breaking_changes(previous, current)

    assert "autenticação global passou a ser obrigatória" in changes
    assert "schema Item.id: restrição enum adicionada" in changes


def test_git_snapshot_is_loaded_from_repository_root() -> None:
    snapshot = _load_git_snapshot("HEAD")

    assert snapshot is not None
    assert snapshot["info"]["title"] == "WMA Travel ERP API"
