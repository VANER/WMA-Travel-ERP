"""Agregador de rotas da API v1."""

from fastapi import APIRouter

from app.core.config import get_settings
from app.core.errors import DatabaseUnavailableError
from app.core.schemas import DatabaseHealthResponse, ErrorResponse, HealthResponse
from app.db.session import database_is_available
from app.modules.corporativo.router import router as corporativo_router

router = APIRouter()
router.include_router(corporativo_router)


@router.get("/health", response_model=HealthResponse, tags=["health"])
def health() -> HealthResponse:
    """Informa a disponibilidade do processo da API v1."""
    settings = get_settings()
    return HealthResponse(status="ok", version=settings.app_version)


@router.get(
    "/health/database",
    response_model=DatabaseHealthResponse,
    responses={503: {"model": ErrorResponse}},
    tags=["health"],
)
def database_health() -> DatabaseHealthResponse:
    """Confirma conectividade mínima com o PostgreSQL sem alterar dados."""
    if not database_is_available():
        raise DatabaseUnavailableError
    return DatabaseHealthResponse()
