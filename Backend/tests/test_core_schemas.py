"""Gates dos schemas do Core Corporativo."""

from datetime import date, datetime
from decimal import Decimal

import pytest
from pydantic import BaseModel, ValidationError

from app.db.base import Base
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

RESPONSE_SCHEMAS = (
    (LocalidadeResponse, Localidade),
    (PessoaResponse, Pessoa),
    (EmpresaResponse, Empresa),
    (ClienteResponse, Cliente),
    (FornecedorResponse, Fornecedor),
    (TipoDocumentoResponse, TipoDocumento),
    (DocumentoResponse, Documento),
    (ConfiguracaoEmpresaResponse, ConfiguracaoEmpresa),
    (ParametroSistemaResponse, ParametroSistema),
)


@pytest.mark.parametrize(
    ("schema_type", "payload"),
    (
        (LocalidadeCreate, {"cidade": "Recife"}),
        (
            PessoaCreate,
            {"tipo_pessoa": "FISICA", "nome_razao_social": "Ana", "id_localidade": 1},
        ),
        (
            EmpresaCreate,
            {
                "razao_social": "WMA Travel Ltda.",
                "nome_fantasia": "WMA Travel",
                "capital_social": "1000.50",
                "id_localidade": 1,
            },
        ),
        (ClienteCreate, {"id_pessoa": 1}),
        (FornecedorCreate, {"id_pessoa": 1}),
        (TipoDocumentoCreate, {"codigo": "PASSAPORTE", "descricao": "Passaporte"}),
        (DocumentoCreate, {"id_tipo_documento": 1}),
        (ConfiguracaoEmpresaCreate, {"id_empresa": 1}),
        (ParametroSistemaCreate, {"codigo": "IDIOMA"}),
    ),
)
def test_create_schemas_accept_the_minimum_valid_payload(
    schema_type: type[BaseModel], payload: dict[str, object]
) -> None:
    result = schema_type.model_validate(payload)

    assert result is not None


def test_create_schemas_reject_server_managed_fields_and_unknown_data() -> None:
    with pytest.raises(ValidationError) as exc_info:
        LocalidadeCreate.model_validate(
            {"id_localidade": 10, "cidade": "Natal", "campo_desconhecido": True}
        )

    errors = exc_info.value.errors()
    assert {error["loc"] for error in errors} == {
        ("id_localidade",),
        ("campo_desconhecido",),
    }


@pytest.mark.parametrize(("schema_type", "model_type"), RESPONSE_SCHEMAS)
def test_response_fields_match_all_model_columns(
    schema_type: type[BaseModel], model_type: type[Base]
) -> None:
    assert set(schema_type.model_fields) == set(model_type.__table__.columns.keys())


@pytest.mark.parametrize("tipo_pessoa", ("", "F", "EMPRESA", "fisica"))
def test_pessoa_rejects_values_outside_the_historical_constraint(tipo_pessoa: str) -> None:
    with pytest.raises(ValidationError):
        PessoaCreate.model_validate(
            {
                "tipo_pessoa": tipo_pessoa,
                "nome_razao_social": "Pessoa inválida",
                "id_localidade": 1,
            }
        )


@pytest.mark.parametrize(
    ("schema_type", "payload"),
    (
        (LocalidadeCreate, {"cidade": "", "uf": "S"}),
        (
            PessoaCreate,
            {"tipo_pessoa": "FISICA", "nome_razao_social": "A" * 151, "id_localidade": 1},
        ),
        (
            EmpresaCreate,
            {
                "razao_social": "Empresa",
                "nome_fantasia": "Empresa",
                "capital_social": "12345678901234.56",
                "id_localidade": 1,
            },
        ),
        (DocumentoCreate, {"id_tipo_documento": 0}),
        (TipoDocumentoCreate, {"codigo": "TIPO", "descricao": "Tipo", "prazo_validade_dias": -1}),
    ),
)
def test_create_schemas_enforce_database_compatible_limits(
    schema_type: type[BaseModel], payload: dict[str, object]
) -> None:
    with pytest.raises(ValidationError):
        schema_type.model_validate(payload)


def test_defaults_match_the_database_contract() -> None:
    assert LocalidadeCreate(cidade="Maceió").pais == "Brasil"
    assert TipoDocumentoCreate(codigo="RG", descricao="RG").ativo
    assert DocumentoCreate(id_tipo_documento=1).status == "ATIVO"
    assert ConfiguracaoEmpresaCreate(id_empresa=1).timezone == "America/Sao_Paulo"
    assert ParametroSistemaCreate(codigo="MOEDA").ativo


@pytest.mark.parametrize(
    ("schema_type", "payload", "nullable_field"),
    (
        (
            TipoDocumentoResponse,
            {"id_tipo_documento": 1, "codigo": "RG", "descricao": "RG", "ativo": None},
            "ativo",
        ),
        (
            DocumentoResponse,
            {"id_documento": 1, "id_tipo_documento": 1, "status": None},
            "status",
        ),
        (
            ConfiguracaoEmpresaResponse,
            {"id_configuracao": 1, "id_empresa": 1, "timezone": None},
            "timezone",
        ),
        (
            ParametroSistemaResponse,
            {"id_parametro": 1, "codigo": "MOEDA", "ativo": None},
            "ativo",
        ),
    ),
)
def test_responses_accept_nullable_historical_defaults(
    schema_type: type[BaseModel], payload: dict[str, object], nullable_field: str
) -> None:
    response = schema_type.model_validate(payload)

    assert getattr(response, nullable_field) is None


def test_monetary_values_remain_decimal() -> None:
    schema = EmpresaCreate.model_validate(
        {
            "razao_social": "Empresa",
            "nome_fantasia": "Empresa",
            "capital_social": "123.45",
            "id_localidade": 1,
        }
    )

    assert schema.capital_social == Decimal("123.45")


def test_response_schema_reads_sqlalchemy_model_without_loading_relationships() -> None:
    localidade = Localidade(id_localidade=3, cidade="Curitiba", uf="PR", pais="Brasil")

    response = LocalidadeResponse.model_validate(localidade)

    assert response.model_dump() == {
        "id_localidade": 3,
        "cidade": "Curitiba",
        "uf": "PR",
        "pais": "Brasil",
    }


def test_audit_fields_are_output_only() -> None:
    created_at = datetime(2026, 8, 25, 12, 0, 0)
    pessoa = Pessoa(
        id_pessoa=4,
        tipo_pessoa="FISICA",
        nome_razao_social="Ana",
        data_nascimento=date(1990, 1, 1),
        id_localidade=3,
        created_at=created_at,
    )

    response = PessoaResponse.model_validate(pessoa)

    assert response.id_pessoa == 4
    assert response.created_at == created_at
    assert "created_at" not in PessoaCreate.model_fields
