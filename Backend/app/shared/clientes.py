"""Contrato interno compartilhado para o papel cadastral de Cliente."""

from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True, slots=True)
class PessoaParaCliente:
    """Projeção mínima de Pessoa consumível pelo domínio Comercial."""

    id_pessoa: int
    nome_razao_social: str
    excluida: bool


@dataclass(frozen=True, slots=True)
class ClienteCorporativo:
    """Projeção do papel Cliente cuja autoridade permanece no Core."""

    id_cliente: int
    id_pessoa: int
    codigo_cliente: str | None
    observacao: str | None


@dataclass(frozen=True, slots=True)
class NovoClienteCorporativo:
    """Dados internos necessários para atribuir o papel Cliente."""

    id_pessoa: int
    codigo_cliente: str | None = None
    observacao: str | None = None


class CadastroClienteCorporativo(Protocol):
    """Porta estável oferecida pelo Core aos módulos consumidores."""

    def obter_pessoa(self, id_pessoa: int) -> PessoaParaCliente | None:
        """Obtém a projeção de Pessoa pela identidade corporativa."""
        ...

    def obter_cliente_por_pessoa(self, id_pessoa: int) -> ClienteCorporativo | None:
        """Obtém o papel Cliente já associado à Pessoa, quando existir."""
        ...

    def adicionar_cliente(self, novo_cliente: NovoClienteCorporativo) -> ClienteCorporativo:
        """Adiciona o papel cadastral sem confirmar a transação."""
        ...
