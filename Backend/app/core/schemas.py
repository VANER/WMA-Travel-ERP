"""Schemas compartilhados pelos endpoints técnicos."""

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """Resposta do health check de processo."""

    status: str
    version: str


class ErrorResponse(BaseModel):
    """Contrato público padronizado para erros."""

    success: bool = False
    message: str
    code: str
    errors: list[dict[str, str]] = Field(default_factory=list)
    correlation_id: str
