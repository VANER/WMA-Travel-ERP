"""Contratos internos para consumo compartilhado de entidades comerciais."""

from decimal import Decimal
from typing import Protocol

from sqlalchemy.orm import Session

from app.modules.comercial.models import Contrato, ItemVenda, Venda


class VendaFinanceira(Protocol):
    id_venda: int
    id_cliente: int
    numero_venda: str
    valor_liquido: Decimal | None
    status: str | None


def obter_venda_financeira(session: Session, identifier: int) -> Venda | None:
    """Obtém uma venda pela fronteira compartilhada entre domínios."""
    return session.get(Venda, identifier)


def obter_item_venda(session: Session, identifier: int) -> ItemVenda | None:
    """Obtém um item de venda pela fronteira compartilhada entre domínios."""
    return session.get(ItemVenda, identifier)


def obter_contrato(session: Session, identifier: int) -> Contrato | None:
    """Obtém um contrato pela fronteira compartilhada entre domínios."""
    return session.get(Contrato, identifier)
