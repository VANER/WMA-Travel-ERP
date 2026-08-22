"""Fixtures da suíte de testes HTTP."""

import os
from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy.engine import make_url

os.environ.setdefault(
    "WMA_DATABASE_URL",
    "postgresql+psycopg://wma_test@localhost:5432/wma_test",
)


def pytest_addoption(parser: pytest.Parser) -> None:
    """Registra o opt-in para testes contra PostgreSQL real."""
    parser.addoption(
        "--run-postgresql",
        action="store_true",
        default=False,
        help="executa testes de integração usando WMA_TEST_DATABASE_URL",
    )


@pytest.fixture
def postgresql_test_url(request: pytest.FixtureRequest) -> str:
    """Valida e fornece uma URL explicitamente destinada a testes locais."""
    if not request.config.getoption("--run-postgresql"):
        pytest.skip("use --run-postgresql para habilitar a integração real")

    database_url = os.getenv("WMA_TEST_DATABASE_URL")
    if database_url is None:
        pytest.fail("WMA_TEST_DATABASE_URL é obrigatória com --run-postgresql")

    parsed_url = make_url(database_url)
    if parsed_url.host not in {"localhost", "127.0.0.1", "::1"}:
        pytest.fail("WMA_TEST_DATABASE_URL deve apontar para PostgreSQL local")
    if parsed_url.database is None or not parsed_url.database.endswith("_test"):
        pytest.fail("o banco de integração deve possuir o sufixo _test")

    return database_url


@pytest.fixture
def client() -> Generator[TestClient]:
    """Fornece um cliente isolado para cada teste."""
    from app.main import app

    with TestClient(app) as test_client:
        yield test_client
