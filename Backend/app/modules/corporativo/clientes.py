"""Adaptador do Core para o contrato interno de Cliente."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.corporativo.models import Cliente, Pessoa
from app.shared.clientes import ClienteCorporativo, NovoClienteCorporativo, PessoaParaCliente


class CadastroClienteCorporativoSqlAlchemy:
    """Adaptador SQLAlchemy do contrato interno de Cliente."""

    def __init__(self, session: Session) -> None:
        self.session = session

    def obter_pessoa(self, id_pessoa: int) -> PessoaParaCliente | None:
        pessoa = self.session.get(Pessoa, id_pessoa)
        if pessoa is None:
            return None
        return PessoaParaCliente(
            id_pessoa=pessoa.id_pessoa,
            nome_razao_social=pessoa.nome_razao_social,
            excluida=pessoa.deleted_at is not None,
        )

    def obter_cliente_por_pessoa(self, id_pessoa: int) -> ClienteCorporativo | None:
        statement = (
            select(Cliente)
            .where(Cliente.id_pessoa == id_pessoa)
            .order_by(Cliente.id_cliente)
            .limit(1)
        )
        cliente = self.session.scalar(statement)
        return self._projetar_cliente(cliente) if cliente is not None else None

    def adicionar_cliente(self, novo_cliente: NovoClienteCorporativo) -> ClienteCorporativo:
        cliente = Cliente(
            id_pessoa=novo_cliente.id_pessoa,
            codigo_cliente=novo_cliente.codigo_cliente,
            observacao=novo_cliente.observacao,
        )
        self.session.add(cliente)
        self.session.flush()
        return self._projetar_cliente(cliente)

    @staticmethod
    def _projetar_cliente(cliente: Cliente) -> ClienteCorporativo:
        return ClienteCorporativo(
            id_cliente=cliente.id_cliente,
            id_pessoa=cliente.id_pessoa,
            codigo_cliente=cliente.codigo_cliente,
            observacao=cliente.observacao,
        )
