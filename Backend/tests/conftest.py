"""Fixtures da suíte de testes HTTP."""

import os
from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient

os.environ.setdefault(
    "WMA_DATABASE_URL",
    "postgresql+psycopg://wma_test@localhost:5432/wma_test",
)


@pytest.fixture
def client() -> Generator[TestClient]:
    """Fornece um cliente isolado para cada teste."""
    from app.main import app

    with TestClient(app) as test_client:
        yield test_client
