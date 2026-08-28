"""Configuração validada a partir do ambiente."""

from functools import lru_cache
from typing import Literal, Self

from pydantic import Field, HttpUrl, SecretStr, field_validator, model_validator
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
    database_pool_size: int = Field(default=5, ge=1, le=50)
    database_max_overflow: int = Field(default=10, ge=0, le=100)
    database_pool_timeout: int = Field(default=30, ge=1, le=120)
    database_pool_recycle: int = Field(default=1800, ge=60, le=86400)
    database_connect_timeout: int = Field(default=5, ge=1, le=30)
    token_signing_key: SecretStr = Field(repr=False, min_length=32)
    token_issuer: str = Field(default="wma-travel-erp", min_length=1, max_length=100)
    token_audience: str = Field(default="wma-travel-erp-api", min_length=1, max_length=100)
    access_token_ttl_minutes: int = Field(default=15, ge=5, le=30)
    refresh_token_ttl_days: int = Field(default=30, ge=1, le=90)
    smtp_host: str = Field(default="mail.wmatravel.com.br", min_length=1, max_length=255)
    smtp_port: int = Field(default=465, ge=1, le=65535)
    smtp_username: str = Field(default="vaner@wmatravel.com.br", min_length=3, max_length=254)
    smtp_password: SecretStr | None = Field(default=None, repr=False, min_length=1)
    smtp_sender: str = Field(default="vaner@wmatravel.com.br", min_length=3, max_length=254)
    recovery_url: HttpUrl = HttpUrl("https://wmatravel.com.br/redefinir-senha")

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

    @field_validator("smtp_host", "smtp_username", "smtp_sender")
    @classmethod
    def validate_smtp_header_values(cls, value: str) -> str:
        """Impede quebra de headers e comandos SMTP por configuracao."""
        if "\r" in value or "\n" in value:
            raise ValueError("configuracao SMTP contem quebra de linha")
        return value

    @field_validator("smtp_username", "smtp_sender")
    @classmethod
    def validate_smtp_addresses(cls, value: str) -> str:
        if value.count("@") != 1 or any(character.isspace() for character in value):
            raise ValueError("endereco SMTP invalido")
        return value

    @field_validator("recovery_url")
    @classmethod
    def validate_recovery_url(cls, value: HttpUrl) -> HttpUrl:
        if value.scheme != "https":
            raise ValueError("recovery_url deve usar HTTPS")
        return value


@lru_cache
def get_settings() -> Settings:
    """Retorna uma instância por processo das configurações."""
    return Settings()
