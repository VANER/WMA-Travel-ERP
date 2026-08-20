"""Testes da configuração obrigatória por ambiente."""

from pathlib import Path

import pytest
from pydantic import ValidationError

from app.core.config import Settings

VALID_DATABASE_URL = "postgresql+psycopg://wma_test@localhost:5432/wma_test"


def test_database_url_is_required(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.delenv("WMA_DATABASE_URL", raising=False)
    monkeypatch.chdir(tmp_path)

    with pytest.raises(ValidationError) as error:
        Settings()

    assert "database_url" in str(error.value)


def test_database_url_requires_official_driver() -> None:
    with pytest.raises(ValidationError) as error:
        Settings(database_url="sqlite:///local.db")

    assert "postgresql+psycopg" in str(error.value)


def test_production_rejects_debug_logging() -> None:
    with pytest.raises(ValidationError) as error:
        Settings(database_url=VALID_DATABASE_URL, environment="production", log_level="DEBUG")

    assert "DEBUG não é permitido" in str(error.value)
    assert VALID_DATABASE_URL not in str(error.value)


def test_settings_repr_does_not_expose_database_url() -> None:
    settings = Settings(database_url=VALID_DATABASE_URL)

    assert VALID_DATABASE_URL not in repr(settings)
