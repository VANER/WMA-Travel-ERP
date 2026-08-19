"""Testes do ciclo de vida da sessão de persistência."""

from unittest.mock import MagicMock, patch

import pytest

from app.db.base import Base
from app.db.session import get_session


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
