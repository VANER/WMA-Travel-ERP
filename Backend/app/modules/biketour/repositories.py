"""Persistencia Bike Tour usando exclusivamente a transacao do chamador."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.biketour.models import EventoBikeTour, OperacaoBikeTour, ProdutoBikeTour


class ProdutoRepository:
    def __init__(self, session: Session) -> None:
        self.session = session

    def obter(self, identifier: int, *, bloquear: bool = False) -> ProdutoBikeTour | None:
        return self.session.get(ProdutoBikeTour, identifier, with_for_update=bloquear)

    def por_origem(self, id_produto: int) -> ProdutoBikeTour | None:
        """Inclui exclusao logica para preservar a unicidade historica da origem."""
        return self.session.scalar(
            select(ProdutoBikeTour).where(ProdutoBikeTour.id_produto == id_produto)
        )

    def listar(self, offset: int, limite: int) -> list[ProdutoBikeTour]:
        return list(
            self.session.scalars(
                select(ProdutoBikeTour)
                .where(ProdutoBikeTour.deleted_at.is_(None))
                .order_by(ProdutoBikeTour.id_produto_bike_tour)
                .offset(offset)
                .limit(limite)
            ).all()
        )

    def salvar(self, item: ProdutoBikeTour) -> None:
        self.session.add(item)
        self.session.flush()
        self.session.refresh(item)


class EventoRepository:
    def __init__(self, session: Session) -> None:
        self.session = session

    def obter(self, identifier: int, *, bloquear: bool = False) -> EventoBikeTour | None:
        return self.session.get(EventoBikeTour, identifier, with_for_update=bloquear)

    def listar(self, offset: int, limite: int) -> list[EventoBikeTour]:
        return list(
            self.session.scalars(
                select(EventoBikeTour)
                .where(EventoBikeTour.deleted_at.is_(None))
                .order_by(EventoBikeTour.id_evento_bike_tour)
                .offset(offset)
                .limit(limite)
            ).all()
        )

    def salvar(self, item: EventoBikeTour) -> None:
        self.session.add(item)
        self.session.flush()
        self.session.refresh(item)


class OperacaoRepository:
    def __init__(self, session: Session) -> None:
        self.session = session

    def obter(
        self, id_usuario: int, operacao: str, alvo: int, chave_hash: str
    ) -> OperacaoBikeTour | None:
        """Inclui tombstones: excluir uma resposta nunca torna sua chave reutilizavel."""
        return self.session.scalar(
            select(OperacaoBikeTour)
            .where(
                OperacaoBikeTour.id_usuario == id_usuario,
                OperacaoBikeTour.operacao == operacao,
                OperacaoBikeTour.alvo == alvo,
                OperacaoBikeTour.chave_hash == chave_hash,
            )
            .with_for_update()
            .execution_options(populate_existing=True)
        )

    def adicionar(self, registro: OperacaoBikeTour) -> None:
        self.session.add(registro)
        self.session.flush()
