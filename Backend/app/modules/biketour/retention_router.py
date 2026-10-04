"""Acao administrativa explicita; um registro por transacao."""

from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request

from app.core.schemas import ErrorResponse
from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.operational_router import ContextDep, Identifier, SessionDep
from app.modules.biketour.retention import (
    RevisaoRetencao,
    RevisaoRetencaoResponse,
    revisar_retencao,
)
from app.modules.biketour.uow import BikeTourUnitOfWork, ResultadoJSON
from app.modules.seguranca.authorization import exigir_bike_tour_gerenciar

router = APIRouter()


@router.post(
    "/operacoes/{identifier}/retencao",
    dependencies=[Depends(exigir_bike_tour_gerenciar)],
    response_model=RevisaoRetencaoResponse,
    responses={code: {"model": ErrorResponse} for code in (401, 403, 404, 409, 422, 500, 503)},
    operation_id="biketour_revisar_retencao",
)
def revisar(
    identifier: Identifier,
    payload: RevisaoRetencao,
    request: Request,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    try:
        return (
            BikeTourUnitOfWork(session)
            .executar(
                ator=contexto,
                permissao="BIKE_TOUR_GERENCIAR",
                correlation_id=UUID(request.state.correlation_id),
                operacao="revisar_retencao",
                alvo=identifier,
                chave=payload.chave_idempotencia,
                payload=payload.model_dump(mode="json", exclude={"chave_idempotencia"}),
                comando=lambda ctx: revisar_retencao(ctx, identifier, payload),
            )
            .corpo
        )
    except BikeTourError as exc:
        raise HTTPException(exc.status_code, exc.code) from exc
