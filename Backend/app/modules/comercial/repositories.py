"""Repositories SQLAlchemy do domínio Comercial."""

from sqlalchemy import select
from sqlalchemy.orm import InstrumentedAttribute, Session

from app.db.base import Base
from app.modules.comercial.models import (
    CondicaoComercial,
    Contrato,
    InteracaoLead,
    ItemProposta,
    Lead,
    Operadora,
    Oportunidade,
    Proposta,
    Venda,
)


class Repository[ModelT: Base]:
    """Persistência paginada sem assumir o limite transacional."""

    def __init__(
        self,
        session: Session,
        model_type: type[ModelT],
        identifier: InstrumentedAttribute[int],
    ) -> None:
        self.session = session
        self.model_type = model_type
        self.identifier = identifier

    def obter(self, identifier: int) -> ModelT | None:
        """Obtém uma entidade por sua chave primária."""
        return self.session.get(self.model_type, identifier)

    def listar(self, *, offset: int = 0, limite: int = 100) -> list[ModelT]:
        """Lista registros ativos em ordem determinística."""
        if offset < 0:
            raise ValueError("offset não pode ser negativo")
        if limite < 1 or limite > 1000:
            raise ValueError("limite deve estar entre 1 e 1000")
        statement = select(self.model_type).order_by(self.identifier).offset(offset).limit(limite)
        return list(self.session.scalars(statement).all())

    def adicionar(self, entity: ModelT) -> ModelT:
        """Adiciona e sincroniza uma entidade."""
        self.session.add(entity)
        self.session.flush()
        return entity


class LeadRepository(Repository[Lead]):
    def __init__(self, session: Session) -> None:
        super().__init__(session, Lead, Lead.id_lead)


class InteracaoLeadRepository(Repository[InteracaoLead]):
    def __init__(self, session: Session) -> None:
        super().__init__(session, InteracaoLead, InteracaoLead.id_interacao)


class OperadoraRepository(Repository[Operadora]):
    def __init__(self, session: Session) -> None:
        super().__init__(session, Operadora, Operadora.id_operadora)


class OportunidadeRepository(Repository[Oportunidade]):
    def __init__(self, session: Session) -> None:
        super().__init__(session, Oportunidade, Oportunidade.id_oportunidade)


class PropostaRepository(Repository[Proposta]):
    def __init__(self, session: Session) -> None:
        super().__init__(session, Proposta, Proposta.id_proposta)


class ItemPropostaRepository(Repository[ItemProposta]):
    def __init__(self, session: Session) -> None:
        super().__init__(session, ItemProposta, ItemProposta.id_item_proposta)


class CondicaoComercialRepository(Repository[CondicaoComercial]):
    def __init__(self, session: Session) -> None:
        super().__init__(session, CondicaoComercial, CondicaoComercial.id_condicao_comercial)


class VendaRepository(Repository[Venda]):
    def __init__(self, session: Session) -> None:
        super().__init__(session, Venda, Venda.id_venda)


class ContratoRepository(Repository[Contrato]):
    def __init__(self, session: Session) -> None:
        super().__init__(session, Contrato, Contrato.id_contrato)
