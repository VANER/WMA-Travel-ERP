"""Ponto de entrada da aplicação FastAPI."""

import logging
from typing import Any

from fastapi import FastAPI

from app.api.router import api_router
from app.core.config import get_settings
from app.core.errors import register_exception_handlers
from app.core.logging import configure_logging
from app.core.middleware import CorrelationIdMiddleware
from app.core.schemas import ErrorResponse, HealthResponse

logger = logging.getLogger(__name__)

OPENAPI_TAGS = [
    {
        "name": "health",
        "description": "Disponibilidade do processo e das dependências técnicas.",
    }
]

COMMON_ERROR_RESPONSES: dict[int | str, dict[str, Any]] = {
    404: {"model": ErrorResponse, "description": "Recurso não encontrado."},
    405: {"model": ErrorResponse, "description": "Método HTTP não permitido."},
    422: {"model": ErrorResponse, "description": "Dados de entrada inválidos."},
    500: {"model": ErrorResponse, "description": "Falha interna não detalhada."},
}


def create_app() -> FastAPI:
    """Cria uma instância configurada da aplicação."""
    settings = get_settings()
    configure_logging(settings.log_level)
    logger.info("Aplicação configurada", extra={"environment": settings.environment})
    application = FastAPI(
        title=settings.app_name,
        summary="API corporativa do WMA Travel ERP",
        description=(
            "API versionada para os módulos corporativos do WMA Travel ERP. "
            "Envie e reutilize o header X-Correlation-Id para rastreabilidade."
        ),
        version=settings.app_version,
        openapi_url="/openapi.json",
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_tags=OPENAPI_TAGS,
        responses=COMMON_ERROR_RESPONSES,
        swagger_ui_parameters={"displayRequestDuration": True},
    )
    application.add_middleware(CorrelationIdMiddleware)
    register_exception_handlers(application)
    application.include_router(api_router, prefix="/api")

    @application.get("/health", response_model=HealthResponse, tags=["health"])
    def health() -> HealthResponse:
        return HealthResponse(status="ok", version=settings.app_version)

    return application


app = create_app()
