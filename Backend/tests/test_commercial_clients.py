"""Gates dos casos de uso comerciais de Cliente."""

from unittest.mock import MagicMock, create_autospec

import pytest
from sqlalchemy import Select
from sqlalchemy.orm import Session

from app.modules.comercial.clientes import (
    ClienteComercialService,
    ClienteJaCadastradoError,
    HabilitarCliente,
    PessoaExcluidaError,
    PessoaNaoEncontradaError,
    UnidadeTrabalhoCliente,
)
from app.modules.corporativo.clientes import CadastroClienteCorporativoSqlAlchemy
from app.modules.corporativo.models import Cliente, Pessoa
from app.shared.clientes import (
    CadastroClienteCorporativo,
    ClienteCorporativo,
    NovoClienteCorporativo,
    PessoaParaCliente,
)


def _service() -> tuple[
    ClienteComercialService,
    MagicMock,
    MagicMock,
]:
    unidade_trabalho = create_autospec(UnidadeTrabalhoCliente, instance=True)
    cadastro = create_autospec(CadastroClienteCorporativo, instance=True)
    return ClienteComercialService(unidade_trabalho, cadastro), unidade_trabalho, cadastro


def test_gateway_obter_pessoa_retorna_none_quando_ausente() -> None:
    session = create_autospec(Session, instance=True)
    session.get.return_value = None
    gateway = CadastroClienteCorporativoSqlAlchemy(session)

    assert gateway.obter_pessoa(9) is None
    session.get.assert_called_once_with(Pessoa, 9)


@pytest.mark.parametrize("excluida", (False, True))
def test_gateway_obter_pessoa_projeta_estado_de_exclusao(excluida: bool) -> None:
    session = create_autospec(Session, instance=True)
    pessoa = Pessoa(
        id_pessoa=9,
        tipo_pessoa="FISICA",
        nome_razao_social="Pessoa Cliente",
        id_localidade=1,
    )
    if excluida:
        from datetime import datetime

        pessoa.deleted_at = datetime(2026, 8, 30)
    session.get.return_value = pessoa
    gateway = CadastroClienteCorporativoSqlAlchemy(session)

    assert gateway.obter_pessoa(9) == PessoaParaCliente(9, "Pessoa Cliente", excluida)


def test_gateway_obter_cliente_por_pessoa_limita_consulta_deterministica() -> None:
    session = create_autospec(Session, instance=True)
    cliente = Cliente(id_cliente=4, id_pessoa=9, codigo_cliente="CLI-9")
    session.scalar.return_value = cliente
    gateway = CadastroClienteCorporativoSqlAlchemy(session)

    assert gateway.obter_cliente_por_pessoa(9) == ClienteCorporativo(4, 9, "CLI-9", None)
    statement = session.scalar.call_args.args[0]
    assert isinstance(statement, Select)
    compiled = str(statement.compile(compile_kwargs={"literal_binds": True}))
    assert "WHERE cliente.id_pessoa = 9" in compiled
    assert "ORDER BY cliente.id_cliente" in compiled
    assert "LIMIT 1" in compiled


def test_gateway_obter_cliente_por_pessoa_retorna_none_quando_ausente() -> None:
    session = create_autospec(Session, instance=True)
    session.scalar.return_value = None

    assert CadastroClienteCorporativoSqlAlchemy(session).obter_cliente_por_pessoa(9) is None


def test_gateway_adicionar_cliente_faz_flush_sem_commit() -> None:
    session = create_autospec(Session, instance=True)

    def atribuir_identidade(cliente: Cliente) -> None:
        cliente.id_cliente = 12

    session.flush.side_effect = lambda: atribuir_identidade(session.add.call_args.args[0])
    gateway = CadastroClienteCorporativoSqlAlchemy(session)

    resultado = gateway.adicionar_cliente(NovoClienteCorporativo(9, "CLI-9", "Observação"))

    assert resultado == ClienteCorporativo(12, 9, "CLI-9", "Observação")
    session.add.assert_called_once()
    session.flush.assert_called_once_with()
    session.commit.assert_not_called()


@pytest.mark.parametrize(
    "payload",
    (
        {"id_pessoa": 0},
        {"id_pessoa": 1, "codigo_cliente": " "},
        {"id_pessoa": 1, "codigo_cliente": "X" * 21},
    ),
)
def test_habilitar_cliente_rejeita_comando_invalido(payload: dict[str, object]) -> None:
    with pytest.raises(ValueError):
        HabilitarCliente(**payload)  # type: ignore[arg-type]


def test_obter_por_pessoa_delega_sem_alterar_transacao() -> None:
    service, unidade_trabalho, cadastro = _service()
    esperado = ClienteCorporativo(7, 11, "CLI-11", None)
    cadastro.obter_cliente_por_pessoa.return_value = esperado

    assert service.obter_por_pessoa(11) is esperado
    cadastro.obter_cliente_por_pessoa.assert_called_once_with(11)
    unidade_trabalho.commit.assert_not_called()
    unidade_trabalho.rollback.assert_not_called()


def test_obter_por_pessoa_rejeita_identidade_invalida() -> None:
    service, _, cadastro = _service()

    with pytest.raises(ValueError, match="positivo"):
        service.obter_por_pessoa(0)

    cadastro.obter_cliente_por_pessoa.assert_not_called()


@pytest.mark.parametrize(
    ("pessoa", "cliente", "error_type"),
    (
        (None, None, PessoaNaoEncontradaError),
        (PessoaParaCliente(1, "Pessoa", True), None, PessoaExcluidaError),
        (
            PessoaParaCliente(1, "Pessoa", False),
            ClienteCorporativo(3, 1, None, None),
            ClienteJaCadastradoError,
        ),
    ),
)
def test_habilitar_cliente_rejeita_pessoa_inelegivel_sem_transacao(
    pessoa: PessoaParaCliente | None,
    cliente: ClienteCorporativo | None,
    error_type: type[Exception],
) -> None:
    service, unidade_trabalho, cadastro = _service()
    cadastro.obter_pessoa.return_value = pessoa
    cadastro.obter_cliente_por_pessoa.return_value = cliente

    with pytest.raises(error_type):
        service.habilitar(HabilitarCliente(id_pessoa=1))

    cadastro.adicionar_cliente.assert_not_called()
    unidade_trabalho.commit.assert_not_called()
    unidade_trabalho.rollback.assert_not_called()


def test_habilitar_cliente_adiciona_no_core_e_confirma_uma_vez() -> None:
    service, unidade_trabalho, cadastro = _service()
    cadastro.obter_pessoa.return_value = PessoaParaCliente(1, "Pessoa", False)
    cadastro.obter_cliente_por_pessoa.return_value = None
    esperado = ClienteCorporativo(5, 1, "CLI-1", "Prioritário")
    cadastro.adicionar_cliente.return_value = esperado

    resultado = service.habilitar(HabilitarCliente(1, "CLI-1", "Prioritário"))

    assert resultado is esperado
    cadastro.adicionar_cliente.assert_called_once_with(
        NovoClienteCorporativo(1, "CLI-1", "Prioritário")
    )
    unidade_trabalho.commit.assert_called_once_with()
    unidade_trabalho.rollback.assert_not_called()


@pytest.mark.parametrize("failure_point", ("adicionar", "commit"))
def test_habilitar_cliente_reverte_e_propaga_falhas(failure_point: str) -> None:
    service, unidade_trabalho, cadastro = _service()
    cadastro.obter_pessoa.return_value = PessoaParaCliente(1, "Pessoa", False)
    cadastro.obter_cliente_por_pessoa.return_value = None
    cadastro.adicionar_cliente.return_value = ClienteCorporativo(5, 1, None, None)
    if failure_point == "adicionar":
        cadastro.adicionar_cliente.side_effect = RuntimeError("falha no Core")
    else:
        unidade_trabalho.commit.side_effect = RuntimeError("falha no commit")

    with pytest.raises(RuntimeError, match="falha"):
        service.habilitar(HabilitarCliente(1))

    unidade_trabalho.rollback.assert_called_once_with()
