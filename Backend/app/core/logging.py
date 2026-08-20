"""Configuração central de logging técnico estruturado."""

import json
import logging
from contextvars import ContextVar, Token
from datetime import UTC, datetime
from typing import Any

_correlation_id: ContextVar[str | None] = ContextVar("correlation_id", default=None)
_STANDARD_RECORD_ATTRIBUTES = set(logging.makeLogRecord({}).__dict__)


def bind_correlation_id(correlation_id: str) -> Token[str | None]:
    """Associa o identificador ao contexto assíncrono atual."""
    return _correlation_id.set(correlation_id)


def reset_correlation_id(token: Token[str | None]) -> None:
    """Restaura o contexto anterior ao finalizar a operação."""
    _correlation_id.reset(token)


class JsonFormatter(logging.Formatter):
    """Serializa eventos técnicos em JSON pesquisável e sem settings implícitas."""

    def format(self, record: logging.LogRecord) -> str:
        event: dict[str, Any] = {
            "timestamp": datetime.fromtimestamp(record.created, tz=UTC).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }
        correlation_id = getattr(record, "correlation_id", None) or _correlation_id.get()
        if correlation_id is not None:
            event["correlation_id"] = correlation_id

        for attribute in (
            "duration_ms",
            "environment",
            "exception_type",
            "http_method",
            "http_path",
            "http_status",
        ):
            if attribute in record.__dict__ and attribute not in _STANDARD_RECORD_ATTRIBUTES:
                event[attribute] = record.__dict__[attribute]

        return json.dumps(event, ensure_ascii=False)


def configure_logging(log_level: str) -> None:
    """Configura o logger raiz e integra loggers do servidor ao mesmo formato."""
    handler = logging.StreamHandler()
    handler.setFormatter(JsonFormatter())

    root_logger = logging.getLogger()
    root_logger.handlers.clear()
    root_logger.addHandler(handler)
    root_logger.setLevel(log_level)

    for logger_name in ("uvicorn", "uvicorn.error"):
        server_logger = logging.getLogger(logger_name)
        server_logger.handlers.clear()
        server_logger.disabled = False
        server_logger.propagate = True

    access_logger = logging.getLogger("uvicorn.access")
    access_logger.handlers.clear()
    access_logger.disabled = True
    access_logger.propagate = False

    for logger_name in ("httpcore", "httpcore2", "httpx", "httpx2", "sqlalchemy"):
        logging.getLogger(logger_name).setLevel(logging.WARNING)
