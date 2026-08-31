"""Casos de uso transacionais do domínio Comercial."""

from datetime import date
from decimal import Decimal

from sqlalchemy.orm import Session

from app.db.base import Base
from app.modules.comercial.models import ItemProposta, Lead, Oportunidade, Proposta, Venda
from app.modules.comercial.repositories import Repository


class RegraComercialError(Exception):
    """Violação esperada de regra comercial."""


class CadastroService[ModelT: Base]:
    """Operações comuns com transação explícita."""

    def __init__(self, session: Session, repository: Repository[ModelT]) -> None:
        self.session = session
        self.repository = repository

    def obter(self, identifier: int) -> ModelT | None:
        return self.repository.obter(identifier)

    def listar(self, *, offset: int = 0, limite: int = 100) -> list[ModelT]:
        return self.repository.listar(offset=offset, limite=limite)

    def cadastrar(self, entity: ModelT) -> ModelT:
        try:
            persisted = self.repository.adicionar(entity)
            self.session.commit()
        except Exception:
            self.session.rollback()
            raise
        return persisted


TRANSICOES_LEAD = {
    "NOVO": {"CONTATADO", "PERDIDO"},
    "CONTATADO": {"QUALIFICADO", "PERDIDO"},
    "QUALIFICADO": {"CONVERTIDO", "PERDIDO"},
    "CONVERTIDO": set(),
    "PERDIDO": set(),
}
TRANSICOES_OPORTUNIDADE = {
    "ABERTA": {"GANHA", "PERDIDA"},
    "GANHA": set(),
    "PERDIDA": set(),
}
TRANSICOES_PROPOSTA = {
    "RASCUNHO": {"ENVIADA", "CANCELADA"},
    "ENVIADA": {"ACEITA", "RECUSADA", "EXPIRADA", "CANCELADA"},
    "ACEITA": set(),
    "RECUSADA": set(),
    "EXPIRADA": set(),
    "CANCELADA": set(),
}
CENTAVO = Decimal("0.01")


def transicionar(
    session: Session,
    entity: Lead | Oportunidade | Proposta,
    novo_status: str,
) -> Lead | Oportunidade | Proposta:
    """Aplica uma transição válida e confirma a unidade de trabalho."""
    transicoes = (
        TRANSICOES_LEAD
        if isinstance(entity, Lead)
        else TRANSICOES_OPORTUNIDADE
        if isinstance(entity, Oportunidade)
        else TRANSICOES_PROPOSTA
    )
    status_atual = entity.status or ""
    if novo_status not in transicoes.get(status_atual, set()):
        raise RegraComercialError(f"transição inválida: {entity.status} -> {novo_status}")
    entity.status = novo_status
    try:
        session.commit()
    except Exception:
        session.rollback()
        raise
    return entity


def adicionar_item(session: Session, proposta: Proposta, item: ItemProposta) -> ItemProposta:
    """Inclui item em rascunho e recalcula os totais da proposta."""
    if proposta.status != "RASCUNHO":
        raise RegraComercialError("itens só podem ser alterados em proposta rascunho")
    valor_bruto_item = (item.quantidade * item.valor_unitario).quantize(CENTAVO)
    item.valor_total = (valor_bruto_item - item.desconto).quantize(CENTAVO)
    if item.valor_total < 0:
        raise RegraComercialError("desconto não pode superar o valor bruto do item")
    item.id_proposta = proposta.id_proposta
    proposta.valor_bruto = (proposta.valor_bruto + valor_bruto_item).quantize(CENTAVO)
    proposta.desconto = (proposta.desconto + item.desconto).quantize(CENTAVO)
    proposta.valor_liquido = (proposta.valor_bruto - proposta.desconto).quantize(CENTAVO)
    try:
        session.add(item)
        session.commit()
    except Exception:
        session.rollback()
        raise
    return item


def converter_em_venda(
    session: Session,
    proposta: Proposta,
    *,
    numero_venda: str,
    data_venda: date,
) -> Venda:
    """Converte uma proposta aceita em venda rastreável e única."""
    if proposta.status != "ACEITA":
        raise RegraComercialError("somente proposta aceita pode gerar venda")
    venda = Venda(
        numero_venda=numero_venda,
        id_cliente=proposta.id_cliente,
        id_proposta=proposta.id_proposta,
        data_venda=data_venda,
        valor_bruto=proposta.valor_bruto,
        desconto=proposta.desconto,
        valor_liquido=proposta.valor_liquido,
        status="CONFIRMADA",
    )
    try:
        session.add(venda)
        session.commit()
    except Exception:
        session.rollback()
        raise
    return venda
