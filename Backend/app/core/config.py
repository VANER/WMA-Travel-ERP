"""Configuração validada a partir do ambiente."""

from functools import lru_cache
from typing import Literal, Self

from pydantic import Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from sqlalchemy.engine import make_url
from sqlalchemy.exc import ArgumentError


class Settings(BaseSettings):
    """Configurações não sensíveis e conexão injetada por ambiente."""

    model_config = SettingsConfigDict(
        env_file=".env", env_prefix="WMA_", extra="ignore", hide_input_in_errors=True
    )

    app_name: str = "WMA Travel ERP API"
    app_version: str = "0.1.0-dev"
    environment: Literal["development", "test", "production"] = "development"
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] = "INFO"
    database_url: str = Field(repr=False)

    @field_validator("database_url")
    @classmethod
    def validate_database_url(cls, value: str) -> str:
        """Aceita somente a URL síncrona oficial do PostgreSQL com psycopg."""
        try:
            url = make_url(value)
        except ArgumentError as exc:
            raise ValueError("database_url inválida") from exc
        if url.drivername != "postgresql+psycopg":
            raise ValueError("database_url deve usar postgresql+psycopg://")
        if not url.host or not url.database:
            raise ValueError("database_url deve informar host e banco")
        return value

    @model_validator(mode="after")
    def validate_production_settings(self) -> Self:
        """Impede configuração insegura conhecida no ambiente de produção."""
        if self.environment == "production" and self.log_level == "DEBUG":
            raise ValueError("log_level DEBUG não é permitido em production")
        return self


@lru_cache
def get_settings() -> Settings:
    """Retorna uma instância por processo das configurações."""
    return Settings()
