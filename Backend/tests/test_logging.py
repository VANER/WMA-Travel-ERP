"""Testes do logging técnico estruturado e correlacionado."""

import json
import logging

from app.core.logging import (
    JsonFormatter,
    bind_correlation_id,
    configure_logging,
    reset_correlation_id,
)


def test_json_formatter_includes_safe_context() -> None:
    formatter = JsonFormatter()
    record = logging.LogRecord(
        name="app.test",
        level=logging.INFO,
        pathname=__file__,
        lineno=1,
        msg="evento técnico",
        args=(),
        exc_info=None,
    )
    record.environment = "test"
    record.database_url = "postgresql+psycopg://usuario:senha@localhost/banco"

    token = bind_correlation_id("6c64c6a2-bb73-48a5-bec3-aeaf893e1a8e")
    try:
        event = json.loads(formatter.format(record))
    finally:
        reset_correlation_id(token)

    assert event["message"] == "evento técnico"
    assert event["environment"] == "test"
    assert event["correlation_id"] == "6c64c6a2-bb73-48a5-bec3-aeaf893e1a8e"
    assert "database_url" not in event
    assert "senha" not in formatter.format(record)


def test_json_formatter_omits_missing_correlation_id() -> None:
    formatter = JsonFormatter()
    record = logging.LogRecord("app.test", logging.INFO, __file__, 1, "evento", (), None)

    event = json.loads(formatter.format(record))

    assert "correlation_id" not in event


def test_logging_configuration_suppresses_unsafe_access_logs() -> None:
    configure_logging("INFO")

    root_logger = logging.getLogger()
    access_logger = logging.getLogger("uvicorn.access")

    assert root_logger.level == logging.INFO
    assert isinstance(root_logger.handlers[0].formatter, JsonFormatter)
    assert access_logger.disabled
    assert not access_logger.propagate
    assert logging.getLogger("httpx2").level == logging.WARNING
