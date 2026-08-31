"""Rotas versionadas do domínio Comercial."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Path, Query, status
from sqlalchemy.orm import Session

from app.core.schemas import ErrorResponse
from app.db.base import Base
from app.db.session import get_session
from app.modules.comercial.models import (
    CondicaoComercial,
    Contrato,
    InteracaoLead,
    ItemProposta,
    Lead,
    Operadora,
    Oportunidade,
    Proposta,
    Venda,
)
from app.modules.comercial.repositories import (
    CondicaoComercialRepository,
    ContratoRepository,
    InteracaoLeadRepository,
    LeadRepository,
    OperadoraRepository,
    OportunidadeRepository,
    PropostaRepository,
    Repository,
    VendaRepository,
)
from app.modules.comercial.schemas import (
    CondicaoComercialCreate,
    CondicaoComercialResponse,
    ContratoCreate,
    ContratoResponse,
    InteracaoLeadCreate,
    InteracaoLeadResponse,
    ItemPropostaCreate,
    ItemPropostaResponse,
    LeadCreate,
    LeadResponse,
    OperadoraCreate,
    OperadoraResponse,
    OportunidadeCreate,
    OportunidadeResponse,
    PropostaCreate,
    PropostaResponse,
    TransicaoStatus,
    VendaCreate,
    VendaResponse,
)
from app.modules.comercial.services import (
    CadastroService,
    RegraComercialError,
    adicionar_item,
    converter_em_venda,
    transicionar,
)
from app.modules.seguranca.authorization import (
    exigir_comercial_gerenciar,
    exigir_comercial_visualizar,
)

router = APIRouter(
    prefix="/comercial",
    tags=["comercial"],
    dependencies=[Depends(exigir_comercial_visualizar)],
    responses={
        401: {"model": ErrorResponse, "description": "Autenticação ausente ou inválida."},
        403: {"model": ErrorResponse, "description": "Permissão insuficiente."},
    },
)
SessionDep = Annotated[Session, Depends(get_session)]
Offset = Annotated[int, Query(ge=0)]
Limite = Annotated[int, Query(ge=1, le=1000)]
Identifier = Annotated[int, Path(gt=0)]


def _required[ModelT: Base](entity: ModelT | None) -> ModelT:
    if entity is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)
    return entity


def _service[ModelT: Base](
    session: Session, repository: Repository[ModelT]
) -> CadastroService[ModelT]:
    return CadastroService(session, repository)


def _conflict(exc: RegraComercialError) -> HTTPException:
    return HTTPException(status_code=status.HTTP_409_CONFLICT, detail=str(exc))


@router.get("/leads", response_model=list[LeadResponse], operation_id="listar_leads")
def listar_leads(session: SessionDep, offset: Offset = 0, limite: Limite = 100) -> list[Lead]:
    return _service(session, LeadRepository(session)).listar(offset=offset, limite=limite)


@router.post(
    "/leads",
    response_model=LeadResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_comercial_gerenciar)],
    operation_id="cadastrar_lead",
)
def cadastrar_lead(payload: LeadCreate, session: SessionDep) -> Lead:
    return _service(session, LeadRepository(session)).cadastrar(Lead(**payload.model_dump()))


@router.post(
    "/leads/{identifier}/status",
    response_model=LeadResponse,
    dependencies=[Depends(exigir_comercial_gerenciar)],
    operation_id="transicionar_lead",
)
def transicionar_lead(
    identifier: Identifier, payload: TransicaoStatus, session: SessionDep
) -> Lead:
    lead = _required(LeadRepository(session).obter(identifier))
    try:
        return transicionar(session, lead, payload.status)  # type: ignore[return-value]
    except RegraComercialError as exc:
        raise _conflict(exc) from exc


@router.post(
    "/interacoes",
    response_model=InteracaoLeadResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_comercial_gerenciar)],
    operation_id="registrar_interacao_lead",
)
def registrar_interacao(payload: InteracaoLeadCreate, session: SessionDep) -> InteracaoLead:
    _required(LeadRepository(session).obter(payload.id_lead))
    return _service(session, InteracaoLeadRepository(session)).cadastrar(
        InteracaoLead(**payload.model_dump())
    )


@router.get("/operadoras", response_model=list[OperadoraResponse], operation_id="listar_operadoras")
def listar_operadoras(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[Operadora]:
    return _service(session, OperadoraRepository(session)).listar(offset=offset, limite=limite)


@router.post(
    "/operadoras",
    response_model=OperadoraResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_comercial_gerenciar)],
    operation_id="cadastrar_operadora",
)
def cadastrar_operadora(payload: OperadoraCreate, session: SessionDep) -> Operadora:
    return _service(session, OperadoraRepository(session)).cadastrar(
        Operadora(**payload.model_dump())
    )


@router.get(
    "/oportunidades",
    response_model=list[OportunidadeResponse],
    operation_id="listar_oportunidades",
)
def listar_oportunidades(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[Oportunidade]:
    return _service(session, OportunidadeRepository(session)).listar(offset=offset, limite=limite)


@router.post(
    "/oportunidades",
    response_model=OportunidadeResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_comercial_gerenciar)],
    operation_id="cadastrar_oportunidade",
)
def cadastrar_oportunidade(payload: OportunidadeCreate, session: SessionDep) -> Oportunidade:
    _required(LeadRepository(session).obter(payload.id_lead))
    return _service(session, OportunidadeRepository(session)).cadastrar(
        Oportunidade(**payload.model_dump())
    )


@router.post(
    "/oportunidades/{identifier}/status",
    response_model=OportunidadeResponse,
    dependencies=[Depends(exigir_comercial_gerenciar)],
    operation_id="transicionar_oportunidade",
)
def transicionar_oportunidade(
    identifier: Identifier, payload: TransicaoStatus, session: SessionDep
) -> Oportunidade:
    oportunidade = _required(OportunidadeRepository(session).obter(identifier))
    try:
        return transicionar(session, oportunidade, payload.status)  # type: ignore[return-value]
    except RegraComercialError as exc:
        raise _conflict(exc) from exc


@router.get("/propostas", response_model=list[PropostaResponse], operation_id="listar_propostas")
def listar_propostas(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[Proposta]:
    return _service(session, PropostaRepository(session)).listar(offset=offset, limite=limite)


@router.post(
    "/propostas",
    response_model=PropostaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_comercial_gerenciar)],
    operation_id="cadastrar_proposta",
)
def cadastrar_proposta(payload: PropostaCreate, session: SessionDep) -> Proposta:
    _required(OportunidadeRepository(session).obter(payload.id_oportunidade))
    return _service(session, PropostaRepository(session)).cadastrar(
        Proposta(**payload.model_dump())
    )


@router.post(
    "/propostas/{identifier}/status",
    response_model=PropostaResponse,
    dependencies=[Depends(exigir_comercial_gerenciar)],
    operation_id="transicionar_proposta",
)
def transicionar_proposta(
    identifier: Identifier, payload: TransicaoStatus, session: SessionDep
) -> Proposta:
    proposta = _required(PropostaRepository(session).obter(identifier))
    try:
        return transicionar(session, proposta, payload.status)  # type: ignore[return-value]
    except RegraComercialError as exc:
        raise _conflict(exc) from exc


@router.post(
    "/itens-proposta",
    response_model=ItemPropostaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_comercial_gerenciar)],
    operation_id="adicionar_item_proposta",
)
def cadastrar_item_proposta(payload: ItemPropostaCreate, session: SessionDep) -> ItemProposta:
    proposta = _required(PropostaRepository(session).obter(payload.id_proposta))
    item_data = payload.model_dump(exclude={"id_proposta"})
    item = ItemProposta(id_proposta=payload.id_proposta, valor_total=0, **item_data)
    try:
        return adicionar_item(session, proposta, item)
    except RegraComercialError as exc:
        raise _conflict(exc) from exc


@router.post(
    "/condicoes",
    response_model=CondicaoComercialResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_comercial_gerenciar)],
    operation_id="cadastrar_condicao_comercial",
)
def cadastrar_condicao(payload: CondicaoComercialCreate, session: SessionDep) -> CondicaoComercial:
    _required(PropostaRepository(session).obter(payload.id_proposta))
    return _service(session, CondicaoComercialRepository(session)).cadastrar(
        CondicaoComercial(**payload.model_dump())
    )


@router.get("/vendas", response_model=list[VendaResponse], operation_id="listar_vendas")
def listar_vendas(session: SessionDep, offset: Offset = 0, limite: Limite = 100) -> list[Venda]:
    return _service(session, VendaRepository(session)).listar(offset=offset, limite=limite)


@router.post(
    "/vendas",
    response_model=VendaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_comercial_gerenciar)],
    operation_id="converter_proposta_em_venda",
)
def cadastrar_venda(payload: VendaCreate, session: SessionDep) -> Venda:
    proposta = _required(PropostaRepository(session).obter(payload.id_proposta))
    try:
        return converter_em_venda(
            session,
            proposta,
            numero_venda=payload.numero_venda,
            data_venda=payload.data_venda,
        )
    except RegraComercialError as exc:
        raise _conflict(exc) from exc


@router.get("/contratos", response_model=list[ContratoResponse], operation_id="listar_contratos")
def listar_contratos(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[Contrato]:
    return _service(session, ContratoRepository(session)).listar(offset=offset, limite=limite)


@router.post(
    "/contratos",
    response_model=ContratoResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_comercial_gerenciar)],
    operation_id="cadastrar_contrato",
)
def cadastrar_contrato(payload: ContratoCreate, session: SessionDep) -> Contrato:
    return _service(session, ContratoRepository(session)).cadastrar(
        Contrato(**payload.model_dump())
    )
