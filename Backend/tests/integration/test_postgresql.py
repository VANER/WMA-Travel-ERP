"""Testes opt-in contra uma instância PostgreSQL local descartável."""

import pytest
from sqlalchemy import text

from app.core.config import Settings
from app.db.session import create_db_engine, database_is_available

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
