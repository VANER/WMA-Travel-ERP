"""API operacional Bike Tour com RBAC explicito e replay do status original."""

from collections.abc import Callable
from typing import Annotated, Literal
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Path, Query, Request, Response
from pydantic import AwareDatetime
from sqlalchemy.exc import OperationalError, TimeoutError
from sqlalchemy.orm import Session

from app.core.schemas import ErrorResponse
from app.db.session import get_session
from app.modules.biketour import operational_schemas as s
from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import OcorrenciaBikeTour, PendenciaBikeTour, RecursoBikeTour
from app.modules.biketour.operations import OperacoesBikeTour
from app.modules.biketour.queries import ConsultasBikeTour
from app.modules.biketour.uow import (
    BikeTourUnitOfWork,
    PermissaoComando,
    ResultadoComando,
    ResultadoJSON,
)
from app.modules.seguranca.authorization import (
    exigir_bike_tour_gerenciar,
    exigir_bike_tour_operar,
    obter_contexto_rbac,
)
from app.modules.seguranca.rbac import ContextoRbac

router = APIRouter(
    responses={code: {"model": ErrorResponse} for code in (401, 403, 404, 409, 422, 500, 503)}
)
SessionDep = Annotated[Session, Depends(get_session)]
ContextDep = Annotated[ContextoRbac, Depends(obter_contexto_rbac)]
Identifier = Annotated[int, Path(gt=0)]
Offset = Annotated[int, Query(ge=0)]
Limit = Annotated[int, Query(ge=1, le=100)]
G = [Depends(exigir_bike_tour_gerenciar)]
OPERAR = [Depends(exigir_bike_tour_operar)]


def _mutar(
    session: Session,
    ator: ContextoRbac,
    request: Request,
    response: Response,
    payload: s.Comando,
    operacao: str,
    identifier: int,
    permissao: PermissaoComando,
    handler: Callable[[OperacoesBikeTour], ResultadoComando],
) -> ResultadoJSON:
    try:
        resultado = BikeTourUnitOfWork(session).executar(
            ator=ator,
            permissao=permissao,
            correlation_id=UUID(request.state.correlation_id),
            operacao=operacao,
            alvo=identifier,
            chave=payload.chave_idempotencia,
            payload=payload.model_dump(mode="json", exclude={"chave_idempotencia"}),
            comando=lambda ctx: handler(OperacoesBikeTour(ctx)),
        )
    except BikeTourError as exc:
        raise HTTPException(exc.status_code, exc.code) from exc
    response.status_code = resultado.status
    return resultado.corpo


def _ler[T](handler: Callable[[], T]) -> T:
    try:
        return handler()
    except BikeTourError as exc:
        raise HTTPException(exc.status_code, exc.code) from exc
    except (OperationalError, TimeoutError) as exc:
        raise HTTPException(503, "BT_FONTE_INDISPONIVEL") from exc


@router.post(
    "/recursos",
    dependencies=G,
    status_code=201,
    response_model=s.RecursoResponse,
    operation_id="biketour_criar_recurso",
)
def criar_recurso(
    payload: s.RecursoCreate,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "criar_recurso",
        0,
        "BIKE_TOUR_GERENCIAR",
        lambda op: op.criar_recurso(payload),
    )


@router.patch(
    "/recursos/{identifier}",
    dependencies=G,
    response_model=s.RecursoResponse,
    operation_id="biketour_alterar_recurso",
)
def alterar_recurso(
    identifier: Identifier,
    payload: s.RecursoUpdate,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "alterar_recurso",
        identifier,
        "BIKE_TOUR_GERENCIAR",
        lambda op: op.alterar_recurso(identifier, payload),
    )


@router.post(
    "/eventos/{identifier}/inscricoes",
    dependencies=OPERAR,
    status_code=201,
    responses={200: {"description": "Rebloqueio da inscricao existente."}},
    operation_id="biketour_bloquear_inscricao",
    response_model=s.InscricaoResponse,
)
def bloquear(
    identifier: Identifier,
    payload: s.InscricaoCreate,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "bloquear_inscricao",
        identifier,
        "BIKE_TOUR_OPERAR",
        lambda op: op.bloquear(identifier, payload),
    )


@router.post(
    "/inscricoes/{identifier}/acoes",
    dependencies=OPERAR,
    operation_id="biketour_acao_inscricao",
    response_model=s.InscricaoResponse,
)
def acionar_inscricao(
    identifier: Identifier,
    payload: s.InscricaoAcao,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "acao_inscricao",
        identifier,
        "BIKE_TOUR_OPERAR",
        lambda op: op.acionar_inscricao(identifier, payload),
    )


@router.post(
    "/inscricoes/{identifier}/recursos",
    dependencies=OPERAR,
    operation_id="biketour_reacomodar_recursos",
    response_model=s.InscricaoResponse,
)
def reacomodar(
    identifier: Identifier,
    payload: s.Reacomodacao,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "reacomodar_recursos",
        identifier,
        "BIKE_TOUR_OPERAR",
        lambda op: op.reacomodar(identifier, payload),
    )


@router.post(
    "/eventos/{identifier}/pontos",
    dependencies=G,
    operation_id="biketour_definir_pontos",
    response_model=list[s.PontoResponse],
)
def definir_pontos(
    identifier: Identifier,
    payload: s.PontosRequest,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "definir_pontos",
        identifier,
        "BIKE_TOUR_GERENCIAR",
        lambda op: op.definir_pontos(identifier, payload),
    )


@router.post(
    "/eventos/{identifier}/equipe",
    dependencies=G,
    operation_id="biketour_definir_equipe",
    response_model=list[s.EquipeResponse],
)
def definir_equipe(
    identifier: Identifier,
    payload: s.EquipeRequest,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "definir_equipe",
        identifier,
        "BIKE_TOUR_GERENCIAR",
        lambda op: op.definir_apoio(identifier, payload),
    )


@router.post(
    "/eventos/{identifier}/logistica",
    dependencies=G,
    operation_id="biketour_definir_logistica",
    response_model=list[s.LogisticaResponse],
)
def definir_logistica(
    identifier: Identifier,
    payload: s.LogisticaRequest,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "definir_logistica",
        identifier,
        "BIKE_TOUR_GERENCIAR",
        lambda op: op.definir_apoio(identifier, payload),
    )


@router.post(
    "/inscricoes/{identifier}/passagens",
    dependencies=OPERAR,
    status_code=201,
    operation_id="biketour_registrar_passagem",
    response_model=s.PassagemResponse,
)
def registrar_passagem(
    identifier: Identifier,
    payload: s.PassagemCreate,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "registrar_passagem",
        identifier,
        "BIKE_TOUR_OPERAR",
        lambda op: op.registrar_passagem(identifier, payload),
    )


@router.post(
    "/eventos/{identifier}/ocorrencias",
    dependencies=OPERAR,
    status_code=201,
    operation_id="biketour_registrar_ocorrencia",
    response_model=s.OcorrenciaResponse,
)
def registrar_ocorrencia(
    identifier: Identifier,
    payload: s.OcorrenciaCreate,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "registrar_ocorrencia",
        identifier,
        "BIKE_TOUR_OPERAR",
        lambda op: op.registrar_ocorrencia(identifier, payload),
    )


@router.patch(
    "/ocorrencias/{identifier}",
    dependencies=OPERAR,
    operation_id="biketour_alterar_ocorrencia",
    response_model=s.OcorrenciaResponse,
)
def alterar_ocorrencia(
    identifier: Identifier,
    payload: s.OcorrenciaUpdate,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "alterar_ocorrencia",
        identifier,
        "BIKE_TOUR_OPERAR",
        lambda op: op.alterar_ocorrencia(identifier, payload),
    )


@router.post(
    "/eventos/{identifier}/reconciliacao",
    dependencies=OPERAR,
    operation_id="biketour_reconciliar_evento",
    response_model=s.ReconciliacaoResponse,
)
def reconciliar(
    identifier: Identifier,
    payload: s.Reconciliacao,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "reconciliar_evento",
        identifier,
        "BIKE_TOUR_OPERAR",
        lambda op: op.reconciliar(identifier, payload),
    )


@router.post(
    "/eventos/{identifier}/expiracao",
    dependencies=OPERAR,
    operation_id="biketour_expirar_evento",
    response_model=s.ExpiracaoResponse,
)
def expirar(
    identifier: Identifier,
    payload: s.Alteracao,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "expirar_evento",
        identifier,
        "BIKE_TOUR_OPERAR",
        lambda op: op.expirar_evento(identifier, payload),
    )


@router.post(
    "/inscricoes/{identifier}/avaliacao",
    dependencies=OPERAR,
    status_code=201,
    operation_id="biketour_avaliar_inscricao",
    response_model=s.AvaliacaoResponse,
)
def avaliar(
    identifier: Identifier,
    payload: s.AvaliacaoCreate,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "avaliar_inscricao",
        identifier,
        "BIKE_TOUR_OPERAR",
        lambda op: op.avaliar(identifier, payload),
    )


@router.post(
    "/pendencias/{identifier}/tratamento",
    dependencies=G,
    operation_id="biketour_tratar_pendencia",
    response_model=s.PendenciaResponse,
)
def tratar_pendencia(
    identifier: Identifier,
    payload: s.TratamentoRequest,
    request: Request,
    response: Response,
    session: SessionDep,
    contexto: ContextDep,
) -> ResultadoJSON:
    return _mutar(
        session,
        contexto,
        request,
        response,
        payload,
        "tratar_pendencia",
        identifier,
        "BIKE_TOUR_GERENCIAR",
        lambda op: op.tratar_pendencia(identifier, payload),
    )


@router.get(
    "/recursos", response_model=list[s.RecursoResponse], operation_id="biketour_listar_recursos"
)
def listar_recursos(session: SessionDep, offset: Offset = 0, limite: Limit = 20) -> ResultadoJSON:
    return _ler(lambda: ConsultasBikeTour(session).listar(RecursoBikeTour, offset, limite))


@router.get(
    "/eventos/{identifier}/inscricoes",
    operation_id="biketour_listar_inscricoes",
    response_model=list[s.InscricaoResponse],
)
def listar_inscricoes(
    identifier: Identifier, session: SessionDep, offset: Offset = 0, limite: Limit = 20
) -> ResultadoJSON:
    return _ler(lambda: ConsultasBikeTour(session).inscricoes(identifier, offset, limite))


@router.get(
    "/eventos/{identifier}/ocorrencias",
    operation_id="biketour_listar_ocorrencias",
    response_model=list[s.OcorrenciaResponse],
)
def listar_ocorrencias(
    identifier: Identifier, session: SessionDep, offset: Offset = 0, limite: Limit = 20
) -> ResultadoJSON:
    return _ler(
        lambda: ConsultasBikeTour(session).listar(OcorrenciaBikeTour, offset, limite, identifier)
    )


@router.get(
    "/eventos/{identifier}/pendencias",
    dependencies=G,
    operation_id="biketour_listar_pendencias",
    response_model=list[s.PendenciaResponse],
)
def listar_pendencias(
    identifier: Identifier,
    session: SessionDep,
    offset: Offset = 0,
    limite: Limit = 20,
    status: Literal["ABERTA", "TRATADA"] | None = None,
) -> ResultadoJSON:
    return _ler(
        lambda: ConsultasBikeTour(session).listar(
            PendenciaBikeTour, offset, limite, identifier, status
        )
    )


@router.get(
    "/inscricoes/{identifier}/origem",
    dependencies=G,
    operation_id="biketour_consultar_correlacao",
    response_model=s.OrigemResponse,
)
def consultar_correlacao(identifier: Identifier, session: SessionDep) -> ResultadoJSON:
    return _ler(lambda: ConsultasBikeTour(session).correlacao(identifier))


@router.get(
    "/eventos/{identifier}/disponibilidade",
    operation_id="biketour_consultar_disponibilidade",
    response_model=s.DisponibilidadeBikeTourResponse,
)
def disponibilidade(
    identifier: Identifier,
    session: SessionDep,
    inicio: AwareDatetime | None = None,
    fim: AwareDatetime | None = None,
    offset: Offset = 0,
    limite: Limit = 20,
) -> ResultadoJSON:
    return _ler(
        lambda: ConsultasBikeTour(session).disponibilidade(identifier, inicio, fim, offset, limite)
    )


@router.get(
    "/eventos/{identifier}/relatorio",
    operation_id="biketour_relatorio_evento",
    response_model=s.RelatorioEventoResponse,
)
def relatorio(identifier: Identifier, session: SessionDep) -> ResultadoJSON:
    return _ler(lambda: ConsultasBikeTour(session).relatorio(identifier))


@router.get(
    "/eventos/{identifier}/auditoria",
    dependencies=G,
    operation_id="biketour_consultar_auditoria",
    response_model=list[s.AuditoriaResponse],
)
def auditoria(
    identifier: Identifier, session: SessionDep, offset: Offset = 0, limite: Limit = 20
) -> ResultadoJSON:
    return _ler(lambda: ConsultasBikeTour(session).auditoria(identifier, offset, limite))
