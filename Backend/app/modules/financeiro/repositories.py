"""Persistência do domínio Financeiro sem controle de commit."""

from sqlalchemy import inspect, select
from sqlalchemy.orm import Session

from app.db.base import Base
from app.modules.financeiro.models import Lancamento, Pagamento, Parcela


class Repository[ModelT: Base]:
    def __init__(self, session: Session, model_type: type[ModelT]) -> None:
        self.session = session
        self.model_type = model_type

    def obter(self, identifier: int, *, bloquear: bool = False) -> ModelT | None:
        if not bloquear:
            return self.session.get(self.model_type, identifier)
        primary_key = inspect(self.model_type).primary_key[0]
        statement = select(self.model_type).where(primary_key == identifier).with_for_update()
        return self.session.scalar(statement)

    def listar(self, *, offset: int = 0, limite: int = 100) -> list[ModelT]:
        if offset < 0 or limite < 1 or limite > 1000:
            raise ValueError("paginação inválida")
        primary_key = inspect(self.model_type).primary_key[0]
        return list(
            self.session.scalars(
                select(self.model_type).order_by(primary_key).offset(offset).limit(limite)
            ).all()
        )

    def adicionar(self, entity: ModelT) -> ModelT:
        self.session.add(entity)
        self.session.flush()
        return entity


class LancamentoRepository(Repository[Lancamento]):
    def __init__(self, session: Session) -> None:
        super().__init__(session, Lancamento)

    def por_chave(self, chave: str) -> Lancamento | None:
        return self.session.scalar(select(Lancamento).where(Lancamento.chave_idempotencia == chave))


class ParcelaRepository(Repository[Parcela]):
    def __init__(self, session: Session) -> None:
        super().__init__(session, Parcela)


class PagamentoRepository(Repository[Pagamento]):
    def __init__(self, session: Session) -> None:
        super().__init__(session, Pagamento)

    def por_chave(self, chave: str) -> Pagamento | None:
        return self.session.scalar(select(Pagamento).where(Pagamento.chave_idempotencia == chave))
