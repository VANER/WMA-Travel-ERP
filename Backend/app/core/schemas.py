"""Schemas compartilhados pelos endpoints técnicos."""

from typing import Literal

from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    """Resposta do health check de processo."""

    status: Literal["ok"] = Field(default="ok", description="Estado do processo da API.")
    version: str = Field(description="Versão da aplicação em execução.")


class DatabaseHealthResponse(BaseModel):
    """Resposta do health check da persistência oficial."""

    status: Literal["ok"] = Field(default="ok", description="Estado do health check.")
    database: Literal["available"] = Field(
        default="available", description="Disponibilidade da persistência PostgreSQL."
    )


class ErrorDetail(BaseModel):
    """Detalhe seguro associado a um campo inválido."""

    field: str = Field(description="Campo relacionado ao erro.")
    message: str = Field(description="Descrição pública do erro.")


class ErrorResponse(BaseModel):
    """Contrato público padronizado para erros."""

    success: Literal[False] = Field(default=False, description="Indica falha da operação.")
    message: str = Field(description="Mensagem pública e segura.")
    code: str = Field(description="Código estável para tratamento pelo cliente.")
    errors: list[ErrorDetail] = Field(default_factory=list)
    correlation_id: str = Field(description="Identificador de correlação da requisição.")
