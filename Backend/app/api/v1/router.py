"""Agregador de rotas da API v1."""

from fastapi import APIRouter

from app.core.config import get_settings
from app.core.schemas import HealthResponse

router = APIRouter()


@router.get("/health", response_model=HealthResponse, tags=["health"])
def health() -> HealthResponse:
    """Informa a disponibilidade do processo da API v1."""
    settings = get_settings()
    return HealthResponse(status="ok", version=settings.app_version)
