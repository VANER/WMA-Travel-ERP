"""Testes dos contratos e handlers centrais de erro."""

import asyncio
import json
from unittest.mock import patch

from fastapi import Request
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException

from app.core.errors import (
    http_error_handler,
    unexpected_error_handler,
    validation_error_handler,
)
from app.core.schemas import ErrorResponse


def _request(correlation_id: str | None = None) -> Request:
    request = Request({"type": "http", "method": "GET", "path": "/", "headers": []})
    if correlation_id is not None:
        request.state.correlation_id = correlation_id
    return request


def test_validation_error_has_safe_contract() -> None:
    error = RequestValidationError(
        [{"type": "missing", "loc": ("body", "nome"), "msg": "Field required", "input": {}}]
    )

    response = asyncio.run(validation_error_handler(_request("correlation-id"), error))

    assert response.status_code == 422
    assert b'"code":"VALIDATION_ERROR"' in response.body
    assert b'"field":"body.nome"' in response.body
    assert b'"correlation_id":"correlation-id"' in response.body


def test_unexpected_error_is_logged_without_exposing_details() -> None:
    with patch("app.core.errors.logger.error") as log_error:
        response = asyncio.run(
            unexpected_error_handler(_request(), RuntimeError("detalhe interno"))
        )

    assert response.status_code == 500
    assert b'"code":"INTERNAL_ERROR"' in response.body
    assert b"detalhe interno" not in response.body
    assert b'"correlation_id":"indisponivel"' in response.body
    log_error.assert_called_once_with("Erro inesperado", extra={"exception_type": "RuntimeError"})


def test_generic_http_error_does_not_expose_detail() -> None:
    error = HTTPException(status_code=418, detail="detalhe interno")

    response = asyncio.run(http_error_handler(_request("correlation-id"), error))
    body = json.loads(bytes(response.body).decode("utf-8"))

    assert response.status_code == 418
    assert body["code"] == "HTTP_ERROR"
    assert body["message"] == "Não foi possível processar a requisição."
    assert b"detalhe interno" not in response.body
    assert body["correlation_id"] == "correlation-id"


def test_error_response_uses_independent_error_lists() -> None:
    first = ErrorResponse(message="erro", code="TEST", correlation_id="one")
    second = ErrorResponse(message="erro", code="TEST", correlation_id="two")

    first.errors.append({"field": "nome", "message": "inválido"})

    assert second.errors == []
