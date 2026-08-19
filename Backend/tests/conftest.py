"""Fixtures da suíte de testes HTTP."""

from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def client() -> Generator[TestClient]:
    """Fornece um cliente isolado para cada teste."""
    with TestClient(app) as test_client:
        yield test_client
