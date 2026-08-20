"""Middleware de correlação de requisições."""

import logging
from time import perf_counter
from uuid import UUID, uuid4

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import Response

from app.core.logging import bind_correlation_id, reset_correlation_id

CORRELATION_HEADER = "X-Correlation-Id"
logger = logging.getLogger(__name__)


def _valid_correlation_id(value: str | None) -> str:
    if value is None:
        return str(uuid4())
    try:
        return str(UUID(value))
    except ValueError:
        return str(uuid4())


class CorrelationIdMiddleware(BaseHTTPMiddleware):
    """Valida ou gera o identificador propagado na resposta."""

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        correlation_id = _valid_correlation_id(request.headers.get(CORRELATION_HEADER))
        request.state.correlation_id = correlation_id
        context_token = bind_correlation_id(correlation_id)
        started_at = perf_counter()
        try:
            response = await call_next(request)
            response.headers[CORRELATION_HEADER] = correlation_id
            logger.info(
                "Requisição concluída",
                extra={
                    "http_method": request.method,
                    "http_path": request.url.path,
                    "http_status": response.status_code,
                    "duration_ms": round((perf_counter() - started_at) * 1000, 2),
                },
            )
            return response
        finally:
            reset_correlation_id(context_token)
