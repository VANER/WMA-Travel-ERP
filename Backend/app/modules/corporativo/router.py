"""Rotas versionadas do Core Corporativo."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Path, Query, status
from sqlalchemy.orm import Session

from app.core.schemas import ErrorResponse
from app.db.base import Base
from app.db.session import get_session
from app.modules.corporativo.models import (
    Cliente,
    ConfiguracaoEmpresa,
    Documento,
    Empresa,
    Fornecedor,
    Localidade,
    ParametroSistema,
    Pessoa,
    TipoDocumento,
)
from app.modules.corporativo.schemas import (
    ClienteCreate,
    ClienteResponse,
    ConfiguracaoEmpresaCreate,
    ConfiguracaoEmpresaResponse,
    DocumentoCreate,
    DocumentoResponse,
    EmpresaCreate,
    EmpresaResponse,
    FornecedorCreate,
    FornecedorResponse,
    LocalidadeCreate,
    LocalidadeResponse,
    ParametroSistemaCreate,
    ParametroSistemaResponse,
    PessoaCreate,
    PessoaResponse,
    TipoDocumentoCreate,
    TipoDocumentoResponse,
)
from app.modules.corporativo.services import (
    ClienteService,
    ConfiguracaoEmpresaService,
    DocumentoService,
    EmpresaService,
    FornecedorService,
    LocalidadeService,
    ParametroSistemaService,
    PessoaService,
    TipoDocumentoService,
)
from app.modules.seguranca.authorization import exigir_core_cadastrar, exigir_core_visualizar

router = APIRouter(
    tags=["core-corporativo"],
    dependencies=[Depends(exigir_core_visualizar)],
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


@router.get(
    "/localidades",
    response_model=list[LocalidadeResponse],
    operation_id="listar_localidades_api_v1_localidades_get",
)
def listar_localidades(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[Localidade]:
    return LocalidadeService(session).listar(offset=offset, limite=limite)


@router.get(
    "/localidades/{identifier}",
    response_model=LocalidadeResponse,
    operation_id="obter_localidade_api_v1_localidades__identifier__get",
)
def obter_localidade(identifier: Identifier, session: SessionDep) -> Localidade:
    return _required(LocalidadeService(session).obter(identifier))


@router.post(
    "/localidades",
    response_model=LocalidadeResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
    operation_id="cadastrar_localidade_api_v1_localidades_post",
)
def cadastrar_localidade(payload: LocalidadeCreate, session: SessionDep) -> Localidade:
    return LocalidadeService(session).cadastrar(Localidade(**payload.model_dump()))


@router.get(
    "/pessoas",
    response_model=list[PessoaResponse],
    operation_id="listar_pessoas_api_v1_pessoas_get",
)
def listar_pessoas(session: SessionDep, offset: Offset = 0, limite: Limite = 100) -> list[Pessoa]:
    return PessoaService(session).listar(offset=offset, limite=limite)


@router.get(
    "/pessoas/{identifier}",
    response_model=PessoaResponse,
    operation_id="obter_pessoa_api_v1_pessoas__identifier__get",
)
def obter_pessoa(identifier: Identifier, session: SessionDep) -> Pessoa:
    return _required(PessoaService(session).obter(identifier))


@router.post(
    "/pessoas",
    response_model=PessoaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
    operation_id="cadastrar_pessoa_api_v1_pessoas_post",
)
def cadastrar_pessoa(payload: PessoaCreate, session: SessionDep) -> Pessoa:
    return PessoaService(session).cadastrar(Pessoa(**payload.model_dump()))


@router.get(
    "/empresas",
    response_model=list[EmpresaResponse],
    operation_id="listar_empresas_api_v1_empresas_get",
)
def listar_empresas(session: SessionDep, offset: Offset = 0, limite: Limite = 100) -> list[Empresa]:
    return EmpresaService(session).listar(offset=offset, limite=limite)


@router.get(
    "/empresas/{identifier}",
    response_model=EmpresaResponse,
    operation_id="obter_empresa_api_v1_empresas__identifier__get",
)
def obter_empresa(identifier: Identifier, session: SessionDep) -> Empresa:
    return _required(EmpresaService(session).obter(identifier))


@router.post(
    "/empresas",
    response_model=EmpresaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
    operation_id="cadastrar_empresa_api_v1_empresas_post",
)
def cadastrar_empresa(payload: EmpresaCreate, session: SessionDep) -> Empresa:
    return EmpresaService(session).cadastrar(Empresa(**payload.model_dump()))


@router.get(
    "/clientes",
    response_model=list[ClienteResponse],
    operation_id="listar_clientes_api_v1_clientes_get",
)
def listar_clientes(session: SessionDep, offset: Offset = 0, limite: Limite = 100) -> list[Cliente]:
    return ClienteService(session).listar(offset=offset, limite=limite)


@router.get(
    "/clientes/{identifier}",
    response_model=ClienteResponse,
    operation_id="obter_cliente_api_v1_clientes__identifier__get",
)
def obter_cliente(identifier: Identifier, session: SessionDep) -> Cliente:
    return _required(ClienteService(session).obter(identifier))


@router.post(
    "/clientes",
    response_model=ClienteResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
    operation_id="cadastrar_cliente_api_v1_clientes_post",
)
def cadastrar_cliente(payload: ClienteCreate, session: SessionDep) -> Cliente:
    return ClienteService(session).cadastrar(Cliente(**payload.model_dump()))


@router.get(
    "/fornecedores",
    response_model=list[FornecedorResponse],
    operation_id="listar_fornecedores_api_v1_fornecedores_get",
)
def listar_fornecedores(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[Fornecedor]:
    return FornecedorService(session).listar(offset=offset, limite=limite)


@router.get(
    "/fornecedores/{identifier}",
    response_model=FornecedorResponse,
    operation_id="obter_fornecedor_api_v1_fornecedores__identifier__get",
)
def obter_fornecedor(identifier: Identifier, session: SessionDep) -> Fornecedor:
    return _required(FornecedorService(session).obter(identifier))


@router.post(
    "/fornecedores",
    response_model=FornecedorResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
    operation_id="cadastrar_fornecedor_api_v1_fornecedores_post",
)
def cadastrar_fornecedor(payload: FornecedorCreate, session: SessionDep) -> Fornecedor:
    return FornecedorService(session).cadastrar(Fornecedor(**payload.model_dump()))


@router.get(
    "/tipos-documento",
    response_model=list[TipoDocumentoResponse],
    operation_id="listar_tipos_documento_api_v1_tipos_documento_get",
)
def listar_tipos_documento(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[TipoDocumento]:
    return TipoDocumentoService(session).listar(offset=offset, limite=limite)


@router.get(
    "/tipos-documento/{identifier}",
    response_model=TipoDocumentoResponse,
    operation_id="obter_tipo_documento_api_v1_tipos_documento__identifier__get",
)
def obter_tipo_documento(identifier: Identifier, session: SessionDep) -> TipoDocumento:
    return _required(TipoDocumentoService(session).obter(identifier))


@router.post(
    "/tipos-documento",
    response_model=TipoDocumentoResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
    operation_id="cadastrar_tipo_documento_api_v1_tipos_documento_post",
)
def cadastrar_tipo_documento(payload: TipoDocumentoCreate, session: SessionDep) -> TipoDocumento:
    return TipoDocumentoService(session).cadastrar(TipoDocumento(**payload.model_dump()))


@router.get(
    "/documentos",
    response_model=list[DocumentoResponse],
    operation_id="listar_documentos_api_v1_documentos_get",
)
def listar_documentos(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[Documento]:
    return DocumentoService(session).listar(offset=offset, limite=limite)


@router.get(
    "/documentos/{identifier}",
    response_model=DocumentoResponse,
    operation_id="obter_documento_api_v1_documentos__identifier__get",
)
def obter_documento(identifier: Identifier, session: SessionDep) -> Documento:
    return _required(DocumentoService(session).obter(identifier))


@router.post(
    "/documentos",
    response_model=DocumentoResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
    operation_id="cadastrar_documento_api_v1_documentos_post",
)
def cadastrar_documento(payload: DocumentoCreate, session: SessionDep) -> Documento:
    return DocumentoService(session).cadastrar(Documento(**payload.model_dump()))


@router.get(
    "/configuracoes-empresa",
    response_model=list[ConfiguracaoEmpresaResponse],
    operation_id="listar_configuracoes_empresa_api_v1_configuracoes_empresa_get",
)
def listar_configuracoes_empresa(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[ConfiguracaoEmpresa]:
    return ConfiguracaoEmpresaService(session).listar(offset=offset, limite=limite)


@router.get(
    "/configuracoes-empresa/{identifier}",
    response_model=ConfiguracaoEmpresaResponse,
    operation_id="obter_configuracao_empresa_api_v1_configuracoes_empresa__identifier__get",
)
def obter_configuracao_empresa(identifier: Identifier, session: SessionDep) -> ConfiguracaoEmpresa:
    return _required(ConfiguracaoEmpresaService(session).obter(identifier))


@router.post(
    "/configuracoes-empresa",
    response_model=ConfiguracaoEmpresaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
    operation_id="cadastrar_configuracao_empresa_api_v1_configuracoes_empresa_post",
)
def cadastrar_configuracao_empresa(
    payload: ConfiguracaoEmpresaCreate, session: SessionDep
) -> ConfiguracaoEmpresa:
    return ConfiguracaoEmpresaService(session).cadastrar(
        ConfiguracaoEmpresa(**payload.model_dump())
    )


@router.get(
    "/parametros-sistema",
    response_model=list[ParametroSistemaResponse],
    operation_id="listar_parametros_sistema_api_v1_parametros_sistema_get",
)
def listar_parametros_sistema(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[ParametroSistema]:
    return ParametroSistemaService(session).listar(offset=offset, limite=limite)


@router.get(
    "/parametros-sistema/{identifier}",
    response_model=ParametroSistemaResponse,
    operation_id="obter_parametro_sistema_api_v1_parametros_sistema__identifier__get",
)
def obter_parametro_sistema(identifier: Identifier, session: SessionDep) -> ParametroSistema:
    return _required(ParametroSistemaService(session).obter(identifier))


@router.post(
    "/parametros-sistema",
    response_model=ParametroSistemaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
    operation_id="cadastrar_parametro_sistema_api_v1_parametros_sistema_post",
)
def cadastrar_parametro_sistema(
    payload: ParametroSistemaCreate, session: SessionDep
) -> ParametroSistema:
    return ParametroSistemaService(session).cadastrar(ParametroSistema(**payload.model_dump()))
