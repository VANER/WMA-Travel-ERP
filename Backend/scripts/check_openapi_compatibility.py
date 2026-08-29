"""Detecta mudanças incompatíveis entre contratos OpenAPI."""

from __future__ import annotations

import argparse
import json
import subprocess
from collections.abc import Iterable
from pathlib import Path
from typing import Any

HTTP_METHODS = {"get", "post", "put", "patch", "delete"}
OPENAPI_PATH = Path(__file__).resolve().parents[1] / "openapi.json"
REPOSITORY_ROOT = Path(__file__).resolve().parents[2]
JsonObject = dict[str, Any]


def _objects(value: object) -> JsonObject:
    return value if isinstance(value, dict) else {}


def _string_items(value: object) -> set[str]:
    return {item for item in value if isinstance(item, str)} if isinstance(value, list) else set()


def _enum_items(value: object) -> set[str] | None:
    if not isinstance(value, list):
        return None
    return {json.dumps(item, ensure_ascii=False, sort_keys=True) for item in value}


def _schema_identity(schema: JsonObject) -> tuple[object, ...]:
    return tuple(
        json.dumps(schema.get(attribute), ensure_ascii=False, sort_keys=True)
        for attribute in ("type", "format", "$ref", "items", "anyOf", "oneOf", "allOf")
    )


def _compare_inline_schema(
    location: str, previous: object, current: object, changes: list[str]
) -> None:
    old_schema = _objects(previous)
    new_schema = _objects(current)
    if _schema_identity(old_schema) != _schema_identity(new_schema):
        changes.append(f"{location}: schema alterado")

    old_enum = _enum_items(old_schema.get("enum"))
    new_enum = _enum_items(new_schema.get("enum"))
    if old_enum is None and new_enum is not None:
        changes.append(f"{location}: restrição enum adicionada")
    elif old_enum is not None and new_enum is not None and old_enum - new_enum:
        changes.append(f"{location}: valores de enum removidos")


def _compare_content(location: str, previous: object, current: object, changes: list[str]) -> None:
    old_content = _objects(previous)
    new_content = _objects(current)
    for media_type in old_content.keys() - new_content.keys():
        changes.append(f"{location}: tipo de mídia removido {media_type}")
    for media_type in old_content.keys() & new_content.keys():
        _compare_inline_schema(
            f"{location} ({media_type})",
            _objects(old_content[media_type]).get("schema"),
            _objects(new_content[media_type]).get("schema"),
            changes,
        )


def _parameter_key(parameter: JsonObject) -> tuple[object, object]:
    return parameter.get("in"), parameter.get("name")


def _compare_parameters(
    location: str, previous: object, current: object, changes: list[str]
) -> None:
    old_parameters = (
        {
            _parameter_key(parameter): parameter
            for parameter in previous
            if isinstance(parameter, dict)
        }
        if isinstance(previous, list)
        else {}
    )
    new_parameters = (
        {
            _parameter_key(parameter): parameter
            for parameter in current
            if isinstance(parameter, dict)
        }
        if isinstance(current, list)
        else {}
    )

    for key, old_parameter in old_parameters.items():
        if key not in new_parameters:
            changes.append(f"{location}: parâmetro removido {key[0]}:{key[1]}")
            continue
        new_parameter = new_parameters[key]
        if not old_parameter.get("required") and new_parameter.get("required"):
            changes.append(f"{location}: parâmetro tornou-se obrigatório {key[0]}:{key[1]}")
        _compare_inline_schema(
            f"{location}: parâmetro {key[0]}:{key[1]}",
            old_parameter.get("schema"),
            new_parameter.get("schema"),
            changes,
        )

    for key, new_parameter in new_parameters.items():
        if key not in old_parameters and new_parameter.get("required"):
            changes.append(f"{location}: novo parâmetro obrigatório {key[0]}:{key[1]}")


def _compare_operations(
    path: str, method: str, previous: JsonObject, current: JsonObject, changes: list[str]
) -> None:
    location = f"{method.upper()} {path}"
    if previous.get("operationId") != current.get("operationId"):
        changes.append(f"{location}: operationId alterado")

    _compare_parameters(location, previous.get("parameters"), current.get("parameters"), changes)

    old_responses = _objects(previous.get("responses"))
    new_responses = _objects(current.get("responses"))
    for status_code in old_responses.keys() - new_responses.keys():
        changes.append(f"{location}: resposta {status_code} removida")
    for status_code in old_responses.keys() & new_responses.keys():
        _compare_content(
            f"{location}: resposta {status_code}",
            _objects(old_responses[status_code]).get("content"),
            _objects(new_responses[status_code]).get("content"),
            changes,
        )

    old_body = _objects(previous.get("requestBody"))
    new_body = _objects(current.get("requestBody"))
    if not old_body.get("required") and new_body.get("required"):
        changes.append(f"{location}: corpo da requisição tornou-se obrigatório")
    _compare_content(
        f"{location}: corpo da requisição",
        old_body.get("content"),
        new_body.get("content"),
        changes,
    )
    if not previous.get("security") and current.get("security"):
        changes.append(f"{location}: autenticação passou a ser obrigatória")


def _compare_schemas(
    name: str, previous: JsonObject, current: JsonObject, changes: list[str]
) -> None:
    location = f"schema {name}"
    old_properties = _objects(previous.get("properties"))
    new_properties = _objects(current.get("properties"))
    for property_name in old_properties.keys() - new_properties.keys():
        changes.append(f"{location}: propriedade removida {property_name}")

    old_required = _string_items(previous.get("required"))
    new_required = _string_items(current.get("required"))
    for required_name in new_required - old_required:
        changes.append(f"{location}: propriedade tornou-se obrigatória {required_name}")

    for property_name in old_properties.keys() & new_properties.keys():
        old_property = _objects(old_properties[property_name])
        new_property = _objects(new_properties[property_name])
        _compare_inline_schema(f"{location}.{property_name}", old_property, new_property, changes)


def find_breaking_changes(previous: JsonObject, current: JsonObject) -> list[str]:
    """Retorna incompatibilidades conhecidas entre dois contratos."""
    changes: list[str] = []
    old_paths = _objects(previous.get("paths"))
    new_paths = _objects(current.get("paths"))

    for path in old_paths.keys() - new_paths.keys():
        changes.append(f"rota removida: {path}")
    for path in old_paths.keys() & new_paths.keys():
        old_path = _objects(old_paths[path])
        new_path = _objects(new_paths[path])
        _compare_parameters(
            f"rota {path}", old_path.get("parameters"), new_path.get("parameters"), changes
        )
        for method in (old_path.keys() & HTTP_METHODS) - new_path.keys():
            changes.append(f"operação removida: {method.upper()} {path}")
        for method in old_path.keys() & new_path.keys() & HTTP_METHODS:
            _compare_operations(
                path,
                method,
                _objects(old_path[method]),
                _objects(new_path[method]),
                changes,
            )

    old_schemas = _objects(_objects(previous.get("components")).get("schemas"))
    new_schemas = _objects(_objects(current.get("components")).get("schemas"))
    for name in old_schemas.keys() - new_schemas.keys():
        changes.append(f"schema removido: {name}")
    for name in old_schemas.keys() & new_schemas.keys():
        _compare_schemas(name, _objects(old_schemas[name]), _objects(new_schemas[name]), changes)

    if not previous.get("security") and current.get("security"):
        changes.append("autenticação global passou a ser obrigatória")

    return sorted(changes)


def _load_json(content: str) -> JsonObject:
    parsed = json.loads(content)
    if not isinstance(parsed, dict):
        raise ValueError("o contrato OpenAPI deve ser um objeto JSON")
    return parsed


def _load_git_snapshot(base_ref: str) -> JsonObject | None:
    tree = subprocess.run(
        ["git", "ls-tree", "--name-only", base_ref, "--", "Backend/openapi.json"],
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
        cwd=REPOSITORY_ROOT,
    )
    if not tree.stdout.strip():
        return None
    result = subprocess.run(
        ["git", "show", f"{base_ref}:Backend/openapi.json"],
        check=True,
        capture_output=True,
        text=True,
        encoding="utf-8",
        cwd=REPOSITORY_ROOT,
    )
    return _load_json(result.stdout)


def _print_changes(changes: Iterable[str]) -> None:
    print("Mudanças incompatíveis detectadas:")
    for change in changes:
        print(f"- {change}")


def main() -> int:
    """Compara o snapshot atual com o contrato versionado na referência-base."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--base-ref", required=True, help="referência Git usada como contrato anterior"
    )
    args = parser.parse_args()

    previous = _load_git_snapshot(args.base_ref)
    current = _load_json(OPENAPI_PATH.read_text(encoding="utf-8"))
    if previous is None:
        print("Branch-base sem snapshot OpenAPI; baseline inicial aceita.")
        return 0
    changes = find_breaking_changes(previous, current)
    if changes:
        _print_changes(changes)
        return 1
    print("Nenhuma mudança incompatível detectada no contrato OpenAPI.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
