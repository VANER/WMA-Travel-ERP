"""Rotas versionadas do domínio Financeiro."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Path, Query, status
from sqlalchemy.orm import Session

from app.core.schemas import ErrorResponse
from app.db.session import get_session
from app.modules.financeiro.models import (
    Conciliacao,
    Lancamento,
    Pagamento,
    PeriodoFinanceiro,
)
from app.modules.financeiro.repositories import LancamentoRepository, Repository
from app.modules.financeiro.schemas import (
    ConciliacaoCreate,
    ConciliacaoResponse,
    LancamentoCreate,
    LancamentoResponse,
    PagamentoCreate,
    PagamentoResponse,
    PeriodoCreate,
    PeriodoResponse,
    TransferenciaCreate,
    TransferenciaResponse,
    VendaFinanceiroCreate,
)
from app.modules.financeiro.services import (
    RegraFinanceiraError,
    conciliar,
    criar_lancamento,
    fechar_periodo,
    gerar_da_venda,
    liquidar_parcela,
    transferir,
)
from app.modules.seguranca.authorization import (
    exigir_financeiro_aprovar,
    exigir_financeiro_operar,
    exigir_financeiro_visualizar,
)
from app.shared.vendas import obter_venda_financeira

router = APIRouter(
    prefix="/financeiro",
    tags=["financeiro"],
    dependencies=[Depends(exigir_financeiro_visualizar)],
    responses={
        401: {"model": ErrorResponse, "description": "Autenticação ausente ou inválida."},
        403: {"model": ErrorResponse, "description": "Permissão insuficiente."},
    },
)
SessionDep = Annotated[Session, Depends(get_session)]
Identifier = Annotated[int, Path(gt=0)]
Offset = Annotated[int, Query(ge=0)]
Limite = Annotated[int, Query(ge=1, le=1000)]


def _conflict(exc: RegraFinanceiraError) -> HTTPException:
    return HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc))


@router.get(
    "/lancamentos", response_model=list[LancamentoResponse], operation_id="listar_lancamentos"
)
def listar_lancamentos(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[Lancamento]:
    return LancamentoRepository(session).listar(offset=offset, limite=limite)


@router.post(
    "/lancamentos",
    response_model=LancamentoResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_financeiro_operar)],
    operation_id="criar_lancamento_financeiro",
)
def cadastrar_lancamento(payload: LancamentoCreate, session: SessionDep) -> Lancamento:
    try:
        return criar_lancamento(session, payload)
    except RegraFinanceiraError as exc:
        raise _conflict(exc) from exc


@router.post(
    "/parcelas/{identifier}/pagamentos",
    response_model=PagamentoResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_financeiro_operar)],
    operation_id="liquidar_parcela_financeira",
)
def cadastrar_pagamento(
    identifier: Identifier, payload: PagamentoCreate, session: SessionDep
) -> Pagamento:
    try:
        return liquidar_parcela(session, identifier, payload)
    except RegraFinanceiraError as exc:
        raise _conflict(exc) from exc


@router.post(
    "/transferencias",
    response_model=TransferenciaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_financeiro_operar)],
    operation_id="transferir_entre_contas",
)
def cadastrar_transferencia(
    payload: TransferenciaCreate, session: SessionDep
) -> TransferenciaResponse:
    return TransferenciaResponse.model_validate(transferir(session, payload))


@router.post(
    "/movimentacoes/{identifier}/conciliacao",
    response_model=ConciliacaoResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_financeiro_operar)],
    operation_id="conciliar_movimentacao",
)
def cadastrar_conciliacao(
    identifier: Identifier, payload: ConciliacaoCreate, session: SessionDep
) -> Conciliacao:
    try:
        return conciliar(session, identifier, payload)
    except RegraFinanceiraError as exc:
        raise _conflict(exc) from exc


@router.post(
    "/vendas/{identifier}/lancamento",
    response_model=LancamentoResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_financeiro_operar)],
    operation_id="gerar_financeiro_da_venda",
)
def cadastrar_financeiro_venda(
    identifier: Identifier, payload: VendaFinanceiroCreate, session: SessionDep
) -> Lancamento:
    venda = obter_venda_financeira(session, identifier)
    if venda is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)
    try:
        return gerar_da_venda(session, venda, payload)
    except RegraFinanceiraError as exc:
        raise _conflict(exc) from exc


@router.post(
    "/periodos",
    response_model=PeriodoResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_financeiro_aprovar)],
    operation_id="criar_periodo_financeiro",
)
def cadastrar_periodo(payload: PeriodoCreate, session: SessionDep) -> PeriodoFinanceiro:
    periodo = PeriodoFinanceiro(competencia=payload.competencia.replace(day=1), fechado=False)
    Repository(session, PeriodoFinanceiro).adicionar(periodo)
    session.commit()
    return periodo


@router.post(
    "/periodos/{identifier}/fechamento",
    response_model=PeriodoResponse,
    dependencies=[Depends(exigir_financeiro_aprovar)],
    operation_id="fechar_periodo_financeiro",
)
def fechar(identifier: Identifier, session: SessionDep) -> PeriodoFinanceiro:
    periodo = Repository(session, PeriodoFinanceiro).obter(identifier, bloquear=True)
    if periodo is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)
    return fechar_periodo(session, periodo)
