"""Contratos internos para consumo compartilhado de entidades comerciais."""

from decimal import Decimal
from typing import Protocol

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.comercial.models import Contrato, ItemVenda, Venda


class VendaFinanceira(Protocol):
    id_venda: int
    id_cliente: int
    numero_venda: str
    valor_liquido: Decimal | None
    status: str | None


def obter_venda_financeira(
    session: Session, identifier: int, *, bloquear: bool = False
) -> Venda | None:
    """Obtém uma venda pela fronteira compartilhada entre domínios."""
    if bloquear:
        return session.scalar(
            select(Venda)
            .where(Venda.id_venda == identifier)
            .with_for_update(read=True)
            .execution_options(populate_existing=True)
        )
    return session.get(Venda, identifier)


def obter_item_venda(
    session: Session, identifier: int, *, bloquear: bool = False
) -> ItemVenda | None:
    """Obtém um item de venda pela fronteira compartilhada entre domínios."""
    if bloquear:
        return session.scalar(
            select(ItemVenda)
            .where(ItemVenda.id_item == identifier)
            .with_for_update(read=True)
            .execution_options(populate_existing=True)
        )
    return session.get(ItemVenda, identifier)


def obter_contrato(session: Session, identifier: int, *, bloquear: bool = False) -> Contrato | None:
    """Obtém um contrato pela fronteira compartilhada entre domínios."""
    if bloquear:
        return session.scalar(
            select(Contrato)
            .where(Contrato.id_contrato == identifier)
            .with_for_update(read=True)
            .execution_options(populate_existing=True)
        )
    return session.get(Contrato, identifier)
