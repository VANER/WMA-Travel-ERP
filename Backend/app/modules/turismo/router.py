"""Rotas versionadas do domínio Turismo."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Path, Query, status
from sqlalchemy.orm import Session

from app.core.schemas import ErrorResponse
from app.db.session import get_session
from app.modules.seguranca.authorization import (
    exigir_turismo_gerenciar,
    exigir_turismo_operar,
    exigir_turismo_visualizar,
    obter_contexto_rbac,
)
from app.modules.seguranca.rbac import ContextoRbac
from app.modules.turismo.models import Reserva, SaidaTuristica
from app.modules.turismo.repositories import SaidaRepository
from app.modules.turismo.schemas import (
    DisponibilidadeResponse,
    ReservaAcao,
    ReservaCreate,
    ReservaResponse,
    SaidaCreate,
    SaidaResponse,
)
from app.modules.turismo.services import (
    RecursoTurismoNaoEncontradoError,
    RegraTurismoError,
    cancelar_reserva,
    confirmar_reserva,
    criar_reserva,
    criar_saida,
    obter_disponibilidade,
)

router = APIRouter(
    prefix="/turismo",
    tags=["turismo"],
    dependencies=[Depends(exigir_turismo_visualizar)],
    responses={
        401: {"model": ErrorResponse, "description": "Autenticação ausente ou inválida."},
        403: {"model": ErrorResponse, "description": "Permissão insuficiente."},
    },
)
SessionDep = Annotated[Session, Depends(get_session)]
Identifier = Annotated[int, Path(gt=0)]
Offset = Annotated[int, Query(ge=0)]
Limite = Annotated[int, Query(ge=1, le=1000)]


def _erro_http(exc: RegraTurismoError) -> HTTPException:
    code = 404 if isinstance(exc, RecursoTurismoNaoEncontradoError) else 409
    return HTTPException(status_code=code, detail=str(exc))


@router.get("/saidas", response_model=list[SaidaResponse], operation_id="listar_saidas_turisticas")
def listar_saidas(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[SaidaTuristica]:
    return SaidaRepository(session).listar(offset, limite)


@router.post(
    "/saidas",
    response_model=SaidaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_turismo_gerenciar)],
    responses={
        404: {"model": ErrorResponse, "description": "Recurso referenciado não encontrado."},
        409: {
            "model": ErrorResponse,
            "description": "Capacidade, estado ou unicidade incompatível.",
        },
    },
    operation_id="criar_saida_turistica",
)
def cadastrar_saida(payload: SaidaCreate, session: SessionDep) -> SaidaTuristica:
    try:
        return criar_saida(session, payload)
    except RegraTurismoError as exc:
        raise _erro_http(exc) from exc


@router.get(
    "/saidas/{identifier}/disponibilidade",
    response_model=DisponibilidadeResponse,
    responses={
        404: {"model": ErrorResponse, "description": "Recurso referenciado não encontrado."}
    },
    operation_id="consultar_disponibilidade_turistica",
)
def consultar_disponibilidade(
    identifier: Identifier, session: SessionDep
) -> DisponibilidadeResponse:
    try:
        return obter_disponibilidade(session, identifier)
    except RegraTurismoError as exc:
        raise _erro_http(exc) from exc


@router.post(
    "/reservas",
    response_model=ReservaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_turismo_operar)],
    responses={
        404: {"model": ErrorResponse, "description": "Recurso referenciado não encontrado."},
        409: {
            "model": ErrorResponse,
            "description": "Capacidade, estado ou unicidade incompatível.",
        },
    },
    operation_id="criar_reserva_turistica",
)
def cadastrar_reserva(payload: ReservaCreate, session: SessionDep) -> Reserva:
    try:
        return criar_reserva(session, payload)
    except RegraTurismoError as exc:
        raise _erro_http(exc) from exc


@router.post(
    "/reservas/{identifier}/confirmacao",
    response_model=ReservaResponse,
    dependencies=[Depends(exigir_turismo_operar)],
    responses={
        404: {"model": ErrorResponse, "description": "Recurso referenciado não encontrado."},
        409: {
            "model": ErrorResponse,
            "description": "Capacidade, estado ou unicidade incompatível.",
        },
    },
    operation_id="confirmar_reserva_turistica",
)
def confirmar(
    identifier: Identifier,
    payload: ReservaAcao,
    session: SessionDep,
    contexto: Annotated[ContextoRbac | None, Depends(obter_contexto_rbac)] = None,
) -> ReservaResponse:
    try:
        return confirmar_reserva(
            session, identifier, payload, id_usuario=contexto.id_usuario if contexto else None
        )
    except RegraTurismoError as exc:
        raise _erro_http(exc) from exc


@router.post(
    "/reservas/{identifier}/cancelamento",
    response_model=ReservaResponse,
    dependencies=[Depends(exigir_turismo_operar)],
    responses={
        404: {"model": ErrorResponse, "description": "Recurso referenciado não encontrado."},
        409: {
            "model": ErrorResponse,
            "description": "Capacidade, estado ou unicidade incompatível.",
        },
    },
    operation_id="cancelar_reserva_turistica",
)
def cancelar(
    identifier: Identifier,
    payload: ReservaAcao,
    session: SessionDep,
    contexto: Annotated[ContextoRbac | None, Depends(obter_contexto_rbac)] = None,
) -> ReservaResponse:
    try:
        return cancelar_reserva(
            session, identifier, payload, id_usuario=contexto.id_usuario if contexto else None
        )
    except RegraTurismoError as exc:
        raise _erro_http(exc) from exc
