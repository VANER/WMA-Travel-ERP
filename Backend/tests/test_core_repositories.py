"""Gates dos repositories do Core Corporativo."""

from collections.abc import Callable
from typing import Any
from unittest.mock import MagicMock, create_autospec

import pytest
from sqlalchemy import Select
from sqlalchemy.orm import Session

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
from app.modules.corporativo.repositories import (
    ClienteRepository,
    ConfiguracaoEmpresaRepository,
    DocumentoRepository,
    EmpresaRepository,
    FornecedorRepository,
    LocalidadeRepository,
    ParametroSistemaRepository,
    PessoaRepository,
    Repository,
    TipoDocumentoRepository,
)

REPOSITORIES = (
    (LocalidadeRepository, Localidade, "id_localidade"),
    (PessoaRepository, Pessoa, "id_pessoa"),
    (EmpresaRepository, Empresa, "id_empresa"),
    (ClienteRepository, Cliente, "id_cliente"),
    (FornecedorRepository, Fornecedor, "id_fornecedor"),
    (TipoDocumentoRepository, TipoDocumento, "id_tipo_documento"),
    (DocumentoRepository, Documento, "id_documento"),
    (ConfiguracaoEmpresaRepository, ConfiguracaoEmpresa, "id_configuracao"),
    (ParametroSistemaRepository, ParametroSistema, "id_parametro"),
)


@pytest.mark.parametrize(("repository_type", "model_type", "identifier"), REPOSITORIES)
def test_concrete_repositories_bind_the_expected_model(
    repository_type: Callable[[Session], Repository[Any]],
    model_type: type[Base],
    identifier: str,
) -> None:
    session = create_autospec(Session, instance=True)

    repository = repository_type(session)

    assert repository.model_type is model_type
    assert repository.identifier.key == identifier


def test_obter_delegates_primary_key_lookup_without_commit() -> None:
    session = create_autospec(Session, instance=True)
    expected = Localidade(cidade="São Paulo", pais="Brasil")
    session.get.return_value = expected
    repository = LocalidadeRepository(session)

    result = repository.obter(10)

    assert result is expected
    session.get.assert_called_once_with(Localidade, 10)
    session.commit.assert_not_called()


def test_listar_builds_deterministic_paginated_query_without_commit() -> None:
    session = create_autospec(Session, instance=True)
    scalar_result = MagicMock()
    scalar_result.all.return_value = [Localidade(cidade="Recife", pais="Brasil")]
    session.scalars.return_value = scalar_result
    repository = LocalidadeRepository(session)

    result = repository.listar(offset=20, limite=10)

    statement = session.scalars.call_args.args[0]
    assert isinstance(statement, Select)
    compiled_statement = str(statement.compile(compile_kwargs={"literal_binds": True}))
    assert "ORDER BY localidade.id_localidade" in compiled_statement
    assert "LIMIT 10 OFFSET 20" in compiled_statement
    assert len(result) == 1
    session.commit.assert_not_called()


@pytest.mark.parametrize(
    ("offset", "limite"),
    ((-1, 10), (0, 0), (0, 1001)),
)
def test_listar_rejects_invalid_pagination(offset: int, limite: int) -> None:
    repository = LocalidadeRepository(create_autospec(Session, instance=True))

    with pytest.raises(ValueError):
        repository.listar(offset=offset, limite=limite)


def test_adicionar_flushes_without_committing() -> None:
    session = create_autospec(Session, instance=True)
    entity = Localidade(cidade="Curitiba", pais="Brasil")
    repository = LocalidadeRepository(session)

    result = repository.adicionar(entity)

    assert result is entity
    session.add.assert_called_once_with(entity)
    session.flush.assert_called_once_with()
    session.commit.assert_not_called()


def test_adicionar_propagates_flush_failure_to_transaction_owner() -> None:
    session = create_autospec(Session, instance=True)
    session.flush.side_effect = RuntimeError("falha simulada")
    repository = LocalidadeRepository(session)

    with pytest.raises(RuntimeError, match="falha simulada"):
        repository.adicionar(Localidade(cidade="Manaus", pais="Brasil"))

    session.commit.assert_not_called()
    session.rollback.assert_not_called()
