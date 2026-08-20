"""Handlers centrais para respostas de erro seguras."""

import logging

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

logger = logging.getLogger(__name__)


def _correlation_id(request: Request) -> str:
    return str(getattr(request.state, "correlation_id", "indisponivel"))


async def validation_error_handler(
    request: Request, exc: RequestValidationError
) -> JSONResponse:
    errors = [
        {"field": ".".join(str(part) for part in error["loc"]), "message": error["msg"]}
        for error in exc.errors()
    ]
    return JSONResponse(
        status_code=422,
        content={
            "success": False,
            "message": "Dados de entrada inválidos.",
            "code": "VALIDATION_ERROR",
            "errors": errors,
            "correlation_id": _correlation_id(request),
        },
    )


async def unexpected_error_handler(request: Request, exc: Exception) -> JSONResponse:
    correlation_id = _correlation_id(request)
    logger.error("Erro inesperado", extra={"exception_type": type(exc).__name__})
    return JSONResponse(
        status_code=500,
        content={
            "success": False,
            "message": "Erro interno ao processar a requisição.",
            "code": "INTERNAL_ERROR",
            "errors": [],
            "correlation_id": correlation_id,
        },
    )


def register_exception_handlers(app: FastAPI) -> None:
    """Registra os handlers globais da aplicação."""
    app.add_exception_handler(RequestValidationError, validation_error_handler)  # type: ignore[arg-type]
    app.add_exception_handler(Exception, unexpected_error_handler)
