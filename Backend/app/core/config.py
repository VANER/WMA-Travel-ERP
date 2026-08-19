"""Configuração validada a partir do ambiente."""

from functools import lru_cache
from typing import Literal

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Configurações não sensíveis e conexão injetada por ambiente."""

    model_config = SettingsConfigDict(env_file=".env", env_prefix="WMA_", extra="ignore")

    app_name: str = "WMA Travel ERP API"
    app_version: str = "2.0.2"
    environment: Literal["development", "test", "production"] = "development"
    log_level: Literal["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"] = "INFO"
    database_url: str = Field(
        default="postgresql+psycopg://wma_app:senha_local@localhost:5432/wma_development",
        repr=False,
    )


@lru_cache
def get_settings() -> Settings:
    """Retorna uma instância por processo das configurações."""
    return Settings()
