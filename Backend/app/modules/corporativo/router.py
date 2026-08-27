"""Rotas versionadas do Core Corporativo."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Path, Query, status
from sqlalchemy.orm import Session

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

router = APIRouter(tags=["core-corporativo"], dependencies=[Depends(exigir_core_visualizar)])
SessionDep = Annotated[Session, Depends(get_session)]
Offset = Annotated[int, Query(ge=0)]
Limite = Annotated[int, Query(ge=1, le=1000)]
Identifier = Annotated[int, Path(gt=0)]


def _required[ModelT: Base](entity: ModelT | None) -> ModelT:
    if entity is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND)
    return entity


@router.get("/localidades", response_model=list[LocalidadeResponse])
def listar_localidades(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[Localidade]:
    return LocalidadeService(session).listar(offset=offset, limite=limite)


@router.get("/localidades/{identifier}", response_model=LocalidadeResponse)
def obter_localidade(identifier: Identifier, session: SessionDep) -> Localidade:
    return _required(LocalidadeService(session).obter(identifier))


@router.post(
    "/localidades",
    response_model=LocalidadeResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
)
def cadastrar_localidade(payload: LocalidadeCreate, session: SessionDep) -> Localidade:
    return LocalidadeService(session).cadastrar(Localidade(**payload.model_dump()))


@router.get("/pessoas", response_model=list[PessoaResponse])
def listar_pessoas(session: SessionDep, offset: Offset = 0, limite: Limite = 100) -> list[Pessoa]:
    return PessoaService(session).listar(offset=offset, limite=limite)


@router.get("/pessoas/{identifier}", response_model=PessoaResponse)
def obter_pessoa(identifier: Identifier, session: SessionDep) -> Pessoa:
    return _required(PessoaService(session).obter(identifier))


@router.post(
    "/pessoas",
    response_model=PessoaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
)
def cadastrar_pessoa(payload: PessoaCreate, session: SessionDep) -> Pessoa:
    return PessoaService(session).cadastrar(Pessoa(**payload.model_dump()))


@router.get("/empresas", response_model=list[EmpresaResponse])
def listar_empresas(session: SessionDep, offset: Offset = 0, limite: Limite = 100) -> list[Empresa]:
    return EmpresaService(session).listar(offset=offset, limite=limite)


@router.get("/empresas/{identifier}", response_model=EmpresaResponse)
def obter_empresa(identifier: Identifier, session: SessionDep) -> Empresa:
    return _required(EmpresaService(session).obter(identifier))


@router.post(
    "/empresas",
    response_model=EmpresaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
)
def cadastrar_empresa(payload: EmpresaCreate, session: SessionDep) -> Empresa:
    return EmpresaService(session).cadastrar(Empresa(**payload.model_dump()))


@router.get("/clientes", response_model=list[ClienteResponse])
def listar_clientes(session: SessionDep, offset: Offset = 0, limite: Limite = 100) -> list[Cliente]:
    return ClienteService(session).listar(offset=offset, limite=limite)


@router.get("/clientes/{identifier}", response_model=ClienteResponse)
def obter_cliente(identifier: Identifier, session: SessionDep) -> Cliente:
    return _required(ClienteService(session).obter(identifier))


@router.post(
    "/clientes",
    response_model=ClienteResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
)
def cadastrar_cliente(payload: ClienteCreate, session: SessionDep) -> Cliente:
    return ClienteService(session).cadastrar(Cliente(**payload.model_dump()))


@router.get("/fornecedores", response_model=list[FornecedorResponse])
def listar_fornecedores(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[Fornecedor]:
    return FornecedorService(session).listar(offset=offset, limite=limite)


@router.get("/fornecedores/{identifier}", response_model=FornecedorResponse)
def obter_fornecedor(identifier: Identifier, session: SessionDep) -> Fornecedor:
    return _required(FornecedorService(session).obter(identifier))


@router.post(
    "/fornecedores",
    response_model=FornecedorResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
)
def cadastrar_fornecedor(payload: FornecedorCreate, session: SessionDep) -> Fornecedor:
    return FornecedorService(session).cadastrar(Fornecedor(**payload.model_dump()))


@router.get("/tipos-documento", response_model=list[TipoDocumentoResponse])
def listar_tipos_documento(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[TipoDocumento]:
    return TipoDocumentoService(session).listar(offset=offset, limite=limite)


@router.get("/tipos-documento/{identifier}", response_model=TipoDocumentoResponse)
def obter_tipo_documento(identifier: Identifier, session: SessionDep) -> TipoDocumento:
    return _required(TipoDocumentoService(session).obter(identifier))


@router.post(
    "/tipos-documento",
    response_model=TipoDocumentoResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
)
def cadastrar_tipo_documento(payload: TipoDocumentoCreate, session: SessionDep) -> TipoDocumento:
    return TipoDocumentoService(session).cadastrar(TipoDocumento(**payload.model_dump()))


@router.get("/documentos", response_model=list[DocumentoResponse])
def listar_documentos(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[Documento]:
    return DocumentoService(session).listar(offset=offset, limite=limite)


@router.get("/documentos/{identifier}", response_model=DocumentoResponse)
def obter_documento(identifier: Identifier, session: SessionDep) -> Documento:
    return _required(DocumentoService(session).obter(identifier))


@router.post(
    "/documentos",
    response_model=DocumentoResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
)
def cadastrar_documento(payload: DocumentoCreate, session: SessionDep) -> Documento:
    return DocumentoService(session).cadastrar(Documento(**payload.model_dump()))


@router.get("/configuracoes-empresa", response_model=list[ConfiguracaoEmpresaResponse])
def listar_configuracoes_empresa(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[ConfiguracaoEmpresa]:
    return ConfiguracaoEmpresaService(session).listar(offset=offset, limite=limite)


@router.get("/configuracoes-empresa/{identifier}", response_model=ConfiguracaoEmpresaResponse)
def obter_configuracao_empresa(identifier: Identifier, session: SessionDep) -> ConfiguracaoEmpresa:
    return _required(ConfiguracaoEmpresaService(session).obter(identifier))


@router.post(
    "/configuracoes-empresa",
    response_model=ConfiguracaoEmpresaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
)
def cadastrar_configuracao_empresa(
    payload: ConfiguracaoEmpresaCreate, session: SessionDep
) -> ConfiguracaoEmpresa:
    return ConfiguracaoEmpresaService(session).cadastrar(
        ConfiguracaoEmpresa(**payload.model_dump())
    )


@router.get("/parametros-sistema", response_model=list[ParametroSistemaResponse])
def listar_parametros_sistema(
    session: SessionDep, offset: Offset = 0, limite: Limite = 100
) -> list[ParametroSistema]:
    return ParametroSistemaService(session).listar(offset=offset, limite=limite)


@router.get("/parametros-sistema/{identifier}", response_model=ParametroSistemaResponse)
def obter_parametro_sistema(identifier: Identifier, session: SessionDep) -> ParametroSistema:
    return _required(ParametroSistemaService(session).obter(identifier))


@router.post(
    "/parametros-sistema",
    response_model=ParametroSistemaResponse,
    status_code=status.HTTP_201_CREATED,
    dependencies=[Depends(exigir_core_cadastrar)],
)
def cadastrar_parametro_sistema(
    payload: ParametroSistemaCreate, session: SessionDep
) -> ParametroSistema:
    return ParametroSistemaService(session).cadastrar(ParametroSistema(**payload.model_dump()))
