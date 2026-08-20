"""Testes do ciclo de vida da sessão de persistência."""

from unittest.mock import MagicMock, patch

import pytest
from sqlalchemy.exc import OperationalError

from app.core.config import Settings
from app.db.base import Base
from app.db.session import (
    create_db_engine,
    database_is_available,
    get_session,
    transactional_session,
)

DATABASE_URL = "postgresql+psycopg://wma_test@localhost:5432/wma_test"


def test_declarative_base_has_metadata() -> None:
    assert Base.metadata is not None


def test_session_is_yielded_and_closed_by_context_manager() -> None:
    session = MagicMock()
    context_manager = MagicMock()
    context_manager.__enter__.return_value = session

    with patch("app.db.session.SessionFactory", return_value=context_manager):
        generator = get_session()
        assert next(generator) is session
        generator.close()

    context_manager.__exit__.assert_called_once()


def test_session_rolls_back_on_error() -> None:
    session = MagicMock()
    context_manager = MagicMock()
    context_manager.__enter__.return_value = session

    with patch("app.db.session.SessionFactory", return_value=context_manager):
        generator = get_session()
        next(generator)
        with pytest.raises(RuntimeError, match="falha"):
            generator.throw(RuntimeError("falha"))

    session.rollback.assert_called_once_with()
    context_manager.__exit__.assert_called_once()


def test_engine_uses_explicit_pool_settings() -> None:
    settings = Settings(
        database_url=DATABASE_URL,
        database_pool_size=7,
        database_max_overflow=3,
        database_pool_timeout=15,
        database_pool_recycle=900,
        database_connect_timeout=4,
    )

    with patch("app.db.session.create_engine") as create_engine:
        create_db_engine(settings)

    create_engine.assert_called_once_with(
        DATABASE_URL,
        pool_pre_ping=True,
        pool_size=7,
        max_overflow=3,
        pool_timeout=15,
        pool_recycle=900,
        connect_args={"connect_timeout": 4},
    )


def test_transactional_session_commits_on_success() -> None:
    session = MagicMock()
    context_manager = MagicMock()
    context_manager.__enter__.return_value = session

    with (
        patch("app.db.session.SessionFactory", return_value=context_manager),
        transactional_session() as yielded_session,
    ):
        assert yielded_session is session

    session.commit.assert_called_once_with()
    session.rollback.assert_not_called()


def test_transactional_session_rolls_back_on_error() -> None:
    session = MagicMock()
    context_manager = MagicMock()
    context_manager.__enter__.return_value = session

    with (
        patch("app.db.session.SessionFactory", return_value=context_manager),
        pytest.raises(RuntimeError, match="falha transacional"),
        transactional_session(),
    ):
        raise RuntimeError("falha transacional")

    session.commit.assert_not_called()
    session.rollback.assert_called_once_with()


def test_database_health_returns_true_when_select_succeeds() -> None:
    db_engine = MagicMock()
    connection = db_engine.connect.return_value.__enter__.return_value

    assert database_is_available(db_engine)

    statement = connection.execute.call_args.args[0]
    assert str(statement) == "SELECT 1"


def test_database_health_handles_sqlalchemy_unavailability() -> None:
    db_engine = MagicMock()
    db_engine.connect.side_effect = OperationalError("SELECT 1", {}, RuntimeError("offline"))

    assert not database_is_available(db_engine)
