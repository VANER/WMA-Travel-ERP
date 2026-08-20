"""Schemas compartilhados pelos endpoints técnicos."""

from typing import Literal

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """Resposta do health check de processo."""

    status: str
    version: str


class DatabaseHealthResponse(BaseModel):
    """Resposta do health check da persistência oficial."""

    status: Literal["ok"] = "ok"
    database: Literal["available"] = "available"


class ErrorResponse(BaseModel):
    """Contrato público padronizado para erros."""

    success: bool = False
    message: str
    code: str
    errors: list[dict[str, str]] = Field(default_factory=list)
    correlation_id: str
