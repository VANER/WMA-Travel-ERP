"""Contratos Pydantic do Core Corporativo."""

from datetime import date, datetime
from decimal import Decimal
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field


class CoreInputSchema(BaseModel):
    """Configuração comum dos contratos de entrada."""

    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class CoreOutputSchema(BaseModel):
    """Configuração comum dos contratos derivados do ORM."""

    model_config = ConfigDict(from_attributes=True)


class AuditResponse(CoreOutputSchema):
    """Campos históricos expostos somente em respostas."""

    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None
    created_by: str | None = None
    updated_by: str | None = None
    deleted_by: str | None = None
    versao: int | None = None


class LocalidadeCreate(CoreInputSchema):
    """Entrada para cadastro de localidade."""

    cidade: str = Field(min_length=1, max_length=100)
    uf: str | None = Field(default=None, min_length=2, max_length=2)
    pais: str = Field(default="Brasil", min_length=1, max_length=100)


class LocalidadeResponse(CoreOutputSchema):
    """Representação pública de localidade."""

    id_localidade: int
    cidade: str
    uf: str | None
    pais: str


class PessoaCreate(CoreInputSchema):
    """Entrada para cadastro de pessoa."""

    tipo_pessoa: Literal["FISICA", "JURIDICA"]
    nome_razao_social: str = Field(min_length=1, max_length=150)
    nome_fantasia: str | None = Field(default=None, max_length=100)
    cpf_cnpj: str | None = Field(default=None, max_length=18)
    rg_ie: str | None = Field(default=None, max_length=30)
    data_nascimento: date | None = None
    telefone: str | None = Field(default=None, max_length=30)
    email: str | None = Field(default=None, max_length=150)
    logradouro: str | None = Field(default=None, max_length=150)
    numero: str | None = Field(default=None, max_length=20)
    bairro: str | None = Field(default=None, max_length=100)
    cep: str | None = Field(default=None, max_length=10)
    id_localidade: int = Field(gt=0)


class PessoaResponse(PessoaCreate, AuditResponse):
    """Representação pública de pessoa."""

    model_config = ConfigDict(from_attributes=True)
    id_pessoa: int


class EmpresaCreate(CoreInputSchema):
    """Entrada para cadastro de empresa."""

    razao_social: str = Field(min_length=1, max_length=150)
    nome_fantasia: str = Field(min_length=1, max_length=100)
    cnpj: str | None = Field(default=None, max_length=18)
    inscricao_municipal: str | None = Field(default=None, max_length=30)
    regime_tributario: str | None = Field(default=None, max_length=50)
    data_abertura: date | None = None
    capital_social: Decimal | None = Field(default=None, max_digits=15, decimal_places=2)
    telefone: str | None = Field(default=None, max_length=30)
    email: str | None = Field(default=None, max_length=150)
    site: str | None = Field(default=None, max_length=150)
    logradouro: str | None = Field(default=None, max_length=150)
    numero: str | None = Field(default=None, max_length=20)
    complemento: str | None = Field(default=None, max_length=100)
    bairro: str | None = Field(default=None, max_length=100)
    cep: str | None = Field(default=None, max_length=10)
    id_localidade: int = Field(gt=0)


class EmpresaResponse(EmpresaCreate, AuditResponse):
    """Representação pública de empresa."""

    model_config = ConfigDict(from_attributes=True)
    id_empresa: int


class ClienteCreate(CoreInputSchema):
    """Entrada para cadastro de cliente."""

    id_pessoa: int = Field(gt=0)
    codigo_cliente: str | None = Field(default=None, max_length=20)
    observacao: str | None = None


class ClienteResponse(ClienteCreate, AuditResponse):
    """Representação pública de cliente."""

    model_config = ConfigDict(from_attributes=True)
    id_cliente: int


class FornecedorCreate(CoreInputSchema):
    """Entrada para cadastro de fornecedor."""

    id_pessoa: int = Field(gt=0)
    codigo_fornecedor: str | None = Field(default=None, max_length=20)
    tipo_fornecedor: str | None = Field(default=None, max_length=50)
    observacao: str | None = None


class FornecedorResponse(FornecedorCreate, AuditResponse):
    """Representação pública de fornecedor."""

    model_config = ConfigDict(from_attributes=True)
    id_fornecedor: int


class TipoDocumentoCreate(CoreInputSchema):
    """Entrada para cadastro de tipo documental."""

    codigo: str = Field(min_length=1, max_length=30)
    descricao: str = Field(min_length=1, max_length=150)
    categoria: str | None = Field(default=None, max_length=50)
    prazo_validade_dias: int | None = Field(default=None, ge=0)
    ativo: bool = True


class TipoDocumentoResponse(AuditResponse):
    """Representação pública de tipo documental."""

    model_config = ConfigDict(from_attributes=True)
    id_tipo_documento: int
    codigo: str
    descricao: str
    categoria: str | None = None
    prazo_validade_dias: int | None = None
    ativo: bool | None = None


class DocumentoCreate(CoreInputSchema):
    """Entrada para cadastro de documento."""

    id_tipo_documento: int = Field(gt=0)
    descricao: str | None = Field(default=None, max_length=200)
    entidade_tipo: str | None = Field(default=None, max_length=50)
    entidade_id: int | None = Field(default=None, gt=0)
    data_documento: date | None = None
    data_validade: date | None = None
    status: str = Field(default="ATIVO", min_length=1, max_length=30)
    observacao: str | None = None


class DocumentoResponse(AuditResponse):
    """Representação pública de documento."""

    model_config = ConfigDict(from_attributes=True)
    id_documento: int
    id_tipo_documento: int
    descricao: str | None = None
    entidade_tipo: str | None = None
    entidade_id: int | None = None
    data_documento: date | None = None
    data_validade: date | None = None
    status: str | None = None
    observacao: str | None = None


class ConfiguracaoEmpresaCreate(CoreInputSchema):
    """Entrada para cadastro de configuração empresarial."""

    id_empresa: int = Field(gt=0)
    nome_sistema: str | None = Field(default=None, max_length=100)
    logo: str | None = None
    email_padrao: str | None = Field(default=None, max_length=150)
    telefone_padrao: str | None = Field(default=None, max_length=30)
    site: str | None = Field(default=None, max_length=150)
    timezone: str = Field(default="America/Sao_Paulo", min_length=1, max_length=50)


class ConfiguracaoEmpresaResponse(CoreOutputSchema):
    """Representação pública de configuração empresarial."""

    model_config = ConfigDict(from_attributes=True)
    id_configuracao: int
    id_empresa: int
    nome_sistema: str | None = None
    logo: str | None = None
    email_padrao: str | None = None
    telefone_padrao: str | None = None
    site: str | None = None
    timezone: str | None = None
    created_at: datetime | None = None
    updated_at: datetime | None = None
    deleted_at: datetime | None = None


class ParametroSistemaCreate(CoreInputSchema):
    """Entrada para cadastro de parâmetro global."""

    codigo: str = Field(min_length=1, max_length=50)
    descricao: str | None = Field(default=None, max_length=150)
    valor: str | None = Field(default=None, max_length=255)
    tipo: str | None = Field(default=None, max_length=30)
    grupo: str | None = Field(default=None, max_length=50)
    ativo: bool = True


class ParametroSistemaResponse(AuditResponse):
    """Representação pública de parâmetro global."""

    model_config = ConfigDict(from_attributes=True)
    id_parametro: int
    codigo: str
    descricao: str | None = None
    valor: str | None = None
    tipo: str | None = None
    grupo: str | None = None
    ativo: bool | None = None
