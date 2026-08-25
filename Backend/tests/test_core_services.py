"""Gates transacionais dos services do Core Corporativo."""

from collections.abc import Callable
from typing import Any
from unittest.mock import MagicMock, create_autospec, patch

import pytest
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
from app.modules.corporativo.services import (
    CadastroService,
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

SERVICES = (
    (LocalidadeService, Localidade, "id_localidade"),
    (PessoaService, Pessoa, "id_pessoa"),
    (EmpresaService, Empresa, "id_empresa"),
    (ClienteService, Cliente, "id_cliente"),
    (FornecedorService, Fornecedor, "id_fornecedor"),
    (TipoDocumentoService, TipoDocumento, "id_tipo_documento"),
    (DocumentoService, Documento, "id_documento"),
    (ConfiguracaoEmpresaService, ConfiguracaoEmpresa, "id_configuracao"),
    (ParametroSistemaService, ParametroSistema, "id_parametro"),
)


@pytest.mark.parametrize(("service_type", "model_type", "identifier"), SERVICES)
def test_concrete_services_bind_the_expected_repository(
    service_type: Callable[[Session], CadastroService[Any]],
    model_type: type[Base],
    identifier: str,
) -> None:
    service = service_type(create_autospec(Session, instance=True))

    assert service.repository.model_type is model_type
    assert service.repository.identifier.key == identifier


def test_obter_delegates_without_changing_transaction() -> None:
    session = create_autospec(Session, instance=True)
    expected = Localidade(cidade="Salvador", pais="Brasil")
    service = LocalidadeService(session)
    obter = MagicMock(return_value=expected)

    with patch.object(service.repository, "obter", obter):
        result = service.obter(7)

    assert result is expected
    obter.assert_called_once_with(7)
    session.commit.assert_not_called()
    session.rollback.assert_not_called()


def test_listar_delegates_without_changing_transaction() -> None:
    session = create_autospec(Session, instance=True)
    expected = [Localidade(cidade="Fortaleza", pais="Brasil")]
    service = LocalidadeService(session)
    listar = MagicMock(return_value=expected)

    with patch.object(service.repository, "listar", listar):
        result = service.listar(offset=10, limite=5)

    assert result is expected
    listar.assert_called_once_with(offset=10, limite=5)
    session.commit.assert_not_called()
    session.rollback.assert_not_called()


def test_cadastrar_commits_once_after_repository_success() -> None:
    session = create_autospec(Session, instance=True)
    entity = Localidade(cidade="Belém", pais="Brasil")
    service = LocalidadeService(session)
    adicionar = MagicMock(return_value=entity)

    with patch.object(service.repository, "adicionar", adicionar):
        result = service.cadastrar(entity)

    assert result is entity
    adicionar.assert_called_once_with(entity)
    session.commit.assert_called_once_with()
    session.rollback.assert_not_called()


@pytest.mark.parametrize("failure_point", ("repository", "commit"))
def test_cadastrar_rolls_back_and_propagates_any_failure(failure_point: str) -> None:
    session = create_autospec(Session, instance=True)
    entity = Localidade(cidade="Goiânia", pais="Brasil")
    service = LocalidadeService(session)

    if failure_point == "repository":
        adicionar = MagicMock(side_effect=RuntimeError("falha no repository"))
    else:
        adicionar = MagicMock(return_value=entity)
        session.commit.side_effect = RuntimeError("falha no commit")

    with (
        patch.object(service.repository, "adicionar", adicionar),
        pytest.raises(RuntimeError, match="falha"),
    ):
        service.cadastrar(entity)

    session.rollback.assert_called_once_with()
