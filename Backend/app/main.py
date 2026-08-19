"""Ponto de entrada da aplicação FastAPI."""

from fastapi import FastAPI

from app.api.v1.router import router as api_v1_router
from app.core.config import get_settings
from app.core.errors import register_exception_handlers
from app.core.middleware import CorrelationIdMiddleware
from app.core.schemas import HealthResponse


def create_app() -> FastAPI:
    """Cria uma instância configurada da aplicação."""
    settings = get_settings()
    application = FastAPI(title=settings.app_name, version=settings.app_version)
    application.add_middleware(CorrelationIdMiddleware)
    register_exception_handlers(application)
    application.include_router(api_v1_router, prefix="/api/v1")

    @application.get("/health", response_model=HealthResponse, tags=["health"])
    def health() -> HealthResponse:
        return HealthResponse(status="ok", version=settings.app_version)

    return application


app = create_app()
