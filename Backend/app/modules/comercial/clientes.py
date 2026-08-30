"""Casos de uso comerciais sobre a autoridade Cliente do Core."""

from dataclasses import dataclass
from typing import Protocol

from app.shared.clientes import (
    CadastroClienteCorporativo,
    ClienteCorporativo,
    NovoClienteCorporativo,
)


class UnidadeTrabalhoCliente(Protocol):
    """Limite transacional mínimo exigido pelo caso de uso."""

    def commit(self) -> None:
        """Confirma a unidade de trabalho."""
        ...

    def rollback(self) -> None:
        """Reverte a unidade de trabalho."""
        ...


class ClienteComercialError(Exception):
    """Erro esperado dos casos de uso comerciais de Cliente."""


class PessoaNaoEncontradaError(ClienteComercialError):
    """Indica que a identidade corporativa informada não existe."""


class PessoaExcluidaError(ClienteComercialError):
    """Indica que uma Pessoa excluída não pode receber novo papel."""


class ClienteJaCadastradoError(ClienteComercialError):
    """Indica que a Pessoa já possui o papel Cliente."""


@dataclass(frozen=True, slots=True)
class HabilitarCliente:
    """Comando interno para atribuição do papel comercial Cliente."""

    id_pessoa: int
    codigo_cliente: str | None = None
    observacao: str | None = None

    def __post_init__(self) -> None:
        if self.id_pessoa <= 0:
            raise ValueError("id_pessoa deve ser positivo")
        if self.codigo_cliente is not None:
            if not self.codigo_cliente.strip():
                raise ValueError("codigo_cliente não pode ser vazio")
            if len(self.codigo_cliente) > 20:
                raise ValueError("codigo_cliente deve possuir no máximo 20 caracteres")


class ClienteComercialService:
    """Orquestra o papel comercial sem assumir a autoridade cadastral."""

    def __init__(
        self,
        unidade_trabalho: UnidadeTrabalhoCliente,
        cadastro_corporativo: CadastroClienteCorporativo,
    ) -> None:
        self.unidade_trabalho = unidade_trabalho
        self.cadastro_corporativo = cadastro_corporativo

    def obter_por_pessoa(self, id_pessoa: int) -> ClienteCorporativo | None:
        """Consulta o papel Cliente sem alterar a transação."""
        if id_pessoa <= 0:
            raise ValueError("id_pessoa deve ser positivo")
        return self.cadastro_corporativo.obter_cliente_por_pessoa(id_pessoa)

    def habilitar(self, comando: HabilitarCliente) -> ClienteCorporativo:
        """Atribui o papel Cliente a uma Pessoa elegível de forma atômica."""
        pessoa = self.cadastro_corporativo.obter_pessoa(comando.id_pessoa)
        if pessoa is None:
            raise PessoaNaoEncontradaError("pessoa não encontrada")
        if pessoa.excluida:
            raise PessoaExcluidaError("pessoa excluída não pode receber o papel Cliente")
        if self.cadastro_corporativo.obter_cliente_por_pessoa(comando.id_pessoa) is not None:
            raise ClienteJaCadastradoError("pessoa já possui o papel Cliente")

        novo_cliente = NovoClienteCorporativo(
            id_pessoa=comando.id_pessoa,
            codigo_cliente=comando.codigo_cliente,
            observacao=comando.observacao,
        )
        try:
            cliente = self.cadastro_corporativo.adicionar_cliente(novo_cliente)
            self.unidade_trabalho.commit()
        except Exception:
            self.unidade_trabalho.rollback()
            raise
        return cliente
