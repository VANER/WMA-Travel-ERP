"""Contrato interno para consumo financeiro de vendas comerciais."""

from decimal import Decimal
from typing import Protocol

from sqlalchemy.orm import Session

from app.modules.comercial.models import Venda


class VendaFinanceira(Protocol):
    id_venda: int
    id_cliente: int
    numero_venda: str
    valor_liquido: Decimal | None
    status: str | None


def obter_venda_financeira(session: Session, identifier: int) -> Venda | None:
    """Obtém uma venda pela fronteira compartilhada entre domínios."""
    return session.get(Venda, identifier)
