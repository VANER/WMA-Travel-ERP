"""Testes opt-in contra uma instância PostgreSQL local descartável."""

from unittest.mock import patch

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text

from app.core.config import Settings
from app.db.session import create_db_engine, database_is_available
from app.main import create_app

pytestmark = pytest.mark.postgresql


def test_postgresql_executes_read_only_health_query(postgresql_test_url: str) -> None:
    """Confirma conexão real e execução de consulta sem alterar o banco."""
    settings = Settings(database_url=postgresql_test_url, environment="test")
    engine = create_db_engine(settings)

    try:
        assert database_is_available(engine)
        with engine.connect() as connection:
            database_name = connection.execute(text("SELECT current_database()"))
            assert database_name.scalar_one().endswith("_test")
    finally:
        engine.dispose()


def test_database_health_uses_real_postgresql(postgresql_test_url: str) -> None:
    """Valida o contrato HTTP de disponibilidade contra PostgreSQL real."""
    settings = Settings(database_url=postgresql_test_url, environment="test")
    engine = create_db_engine(settings)

    try:
        with (
            patch(
                "app.api.v1.router.database_is_available",
                side_effect=lambda: database_is_available(engine),
            ),
            TestClient(create_app()) as client,
        ):
            response = client.get("/api/v1/health/database")

        assert response.status_code == 200
        assert response.json() == {"status": "ok", "database": "available"}
    finally:
        engine.dispose()
