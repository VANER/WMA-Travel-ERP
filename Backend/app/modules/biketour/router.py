"""Rotas da configuracao e operacao basica do Bike Tour."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Path, Query, status
from sqlalchemy.orm import Session

from app.core.schemas import ErrorResponse
from app.db.session import get_session
from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.operational_router import router as operational_router
from app.modules.biketour.retention_router import router as retention_router
from app.modules.biketour.schemas import (
    EventoAcaoRequest,
    EventoCreate,
    EventoResponse,
    EventoUpdate,
    ProdutoCreate,
    ProdutoResponse,
    ProdutoUpdate,
)
from app.modules.biketour.services import (
    acionar_evento,
    alterar_evento,
    alterar_produto,
    criar_evento,
    criar_produto,
)
from app.modules.biketour.services import (
    consultar_evento as consultar_evento_service,
)
from app.modules.biketour.services import (
    listar_eventos as listar_eventos_service,
)
from app.modules.biketour.services import (
    listar_produtos as listar_produtos_service,
)
from app.modules.seguranca.authorization import (
    exigir_bike_tour_gerenciar,
    exigir_bike_tour_visualizar,
    obter_contexto_rbac,
)
from app.modules.seguranca.rbac import ContextoRbac

router = APIRouter(
    tags=["bike-tour"],
    dependencies=[Depends(exigir_bike_tour_visualizar)],
    responses={
        401: {"model": ErrorResponse, "description": "Autenticacao ausente ou invalida."},
        403: {"model": ErrorResponse, "description": "Permissao insuficiente."},
        422: {"model": ErrorResponse, "description": "Dados de entrada invalidos."},
        500: {"model": ErrorResponse, "description": "Erro interno sem exposicao de detalhes."},
        503: {"model": ErrorResponse, "description": "Dependencia ou banco indisponivel."},
    },
)
SessionDep = Annotated[Session, Depends(get_session)]
ContextDep = Annotated[ContextoRbac, Depends(obter_contexto_rbac)]
Identifier = Annotated[int, Path(gt=0)]
Offset = Annotated[int, Query(ge=0)]
Limit = Annotated[int, Query(ge=1, le=100)]
router.include_router(operational_router)
router.include_router(retention_router)


def _erro(exc: BikeTourError) -> HTTPException:
    return HTTPException(status_code=exc.status_code, detail=exc.code)


@router.post(
    "/produtos",
    response_model=ProdutoResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_bike_tour_gerenciar)],
    operation_id="biketour_criar_produto",
    responses={
        404: {"model": ErrorResponse, "description": "Produto de origem inexistente."},
        409: {"model": ErrorResponse, "description": "Origem incompativel ou duplicidade."},
    },
)
def criar_produto_endpoint(
    payload: ProdutoCreate, session: SessionDep, contexto: ContextDep
) -> dict[str, object]:
    try:
        return criar_produto(session, contexto, payload)
    except BikeTourError as exc:
        raise _erro(exc) from exc


@router.get(
    "/produtos", response_model=list[ProdutoResponse], operation_id="biketour_listar_produtos"
)
def listar_produtos(
    session: SessionDep, offset: Offset = 0, limite: Limit = 20
) -> list[ProdutoResponse]:
    try:
        return listar_produtos_service(session, offset, limite)
    except BikeTourError as exc:
        raise _erro(exc) from exc


@router.patch(
    "/produtos/{identifier}",
    response_model=ProdutoResponse,
    dependencies=[Depends(exigir_bike_tour_gerenciar)],
    operation_id="biketour_alterar_produto",
    responses={
        404: {"model": ErrorResponse, "description": "Produto inexistente."},
        409: {"model": ErrorResponse, "description": "Versao ou chave em conflito."},
    },
)
def alterar_produto_endpoint(
    identifier: Identifier, payload: ProdutoUpdate, session: SessionDep, contexto: ContextDep
) -> dict[str, object]:
    try:
        return alterar_produto(session, contexto, identifier, payload)
    except BikeTourError as exc:
        raise _erro(exc) from exc


@router.post(
    "/eventos",
    response_model=EventoResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_bike_tour_gerenciar)],
    operation_id="biketour_criar_evento",
    responses={
        404: {"model": ErrorResponse, "description": "Saida inexistente."},
        409: {"model": ErrorResponse, "description": "Origem, periodo, capacidade ou unicidade."},
    },
)
def criar_evento_endpoint(
    payload: EventoCreate, session: SessionDep, contexto: ContextDep
) -> dict[str, object]:
    try:
        return criar_evento(session, contexto, payload)
    except BikeTourError as exc:
        raise _erro(exc) from exc


@router.get("/eventos", response_model=list[EventoResponse], operation_id="biketour_listar_eventos")
def listar_eventos(
    session: SessionDep, offset: Offset = 0, limite: Limit = 20
) -> list[EventoResponse]:
    try:
        return listar_eventos_service(session, offset, limite)
    except BikeTourError as exc:
        raise _erro(exc) from exc


@router.get(
    "/eventos/{identifier}",
    response_model=EventoResponse,
    operation_id="biketour_consultar_evento",
    responses={404: {"model": ErrorResponse, "description": "Evento inexistente."}},
)
def consultar_evento(identifier: Identifier, session: SessionDep) -> EventoResponse:
    try:
        return consultar_evento_service(session, identifier)
    except BikeTourError as exc:
        raise _erro(exc) from exc


@router.patch(
    "/eventos/{identifier}",
    response_model=EventoResponse,
    dependencies=[Depends(exigir_bike_tour_gerenciar)],
    operation_id="biketour_alterar_evento",
    responses={
        404: {"model": ErrorResponse, "description": "Evento inexistente."},
        409: {"model": ErrorResponse, "description": "Estado, vinculos, limites ou versao."},
    },
)
def alterar_evento_endpoint(
    identifier: Identifier, payload: EventoUpdate, session: SessionDep, contexto: ContextDep
) -> dict[str, object]:
    try:
        return alterar_evento(session, contexto, identifier, payload)
    except BikeTourError as exc:
        raise _erro(exc) from exc


@router.post(
    "/eventos/{identifier}/acoes",
    response_model=EventoResponse,
    dependencies=[Depends(exigir_bike_tour_gerenciar)],
    operation_id="biketour_acionar_evento",
    responses={
        404: {"model": ErrorResponse, "description": "Evento inexistente."},
        409: {
            "model": ErrorResponse,
            "description": "Transicao, preparacao ou versao incompativel.",
        },
    },
)
def acionar_evento_endpoint(
    identifier: Identifier, payload: EventoAcaoRequest, session: SessionDep, contexto: ContextDep
) -> dict[str, object]:
    try:
        return acionar_evento(session, contexto, identifier, payload)
    except BikeTourError as exc:
        raise _erro(exc) from exc
