"""Testes da configuração obrigatória por ambiente."""

from pathlib import Path

import pytest
from pydantic import ValidationError

from app.core.config import Settings


def test_database_url_is_required(monkeypatch: pytest.MonkeyPatch, tmp_path: Path) -> None:
    monkeypatch.delenv("WMA_DATABASE_URL", raising=False)
    monkeypatch.chdir(tmp_path)

    with pytest.raises(ValidationError) as error:
        Settings()

    assert "database_url" in str(error.value)
