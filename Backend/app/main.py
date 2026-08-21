"""Ponto de entrada da aplicação FastAPI."""

import logging

from fastapi import FastAPI

from app.api.router import api_router
from app.core.config import get_settings
from app.core.errors import register_exception_handlers
from app.core.logging import configure_logging
from app.core.middleware import CorrelationIdMiddleware
from app.core.schemas import HealthResponse

logger = logging.getLogger(__name__)


def create_app() -> FastAPI:
    """Cria uma instância configurada da aplicação."""
    settings = get_settings()
    configure_logging(settings.log_level)
    logger.info("Aplicação configurada", extra={"environment": settings.environment})
    application = FastAPI(title=settings.app_name, version=settings.app_version)
    application.add_middleware(CorrelationIdMiddleware)
    register_exception_handlers(application)
    application.include_router(api_router, prefix="/api")

    @application.get("/health", response_model=HealthResponse, tags=["health"])
    def health() -> HealthResponse:
        return HealthResponse(status="ok", version=settings.app_version)

    return application


app = create_app()
