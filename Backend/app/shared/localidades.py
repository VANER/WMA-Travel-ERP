"""Consulta minima de localidade corporativa para consumidores internos."""

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.modules.corporativo.models import Localidade


def localidade_disponivel(session: Session, identifier: int) -> bool:
    return (
        session.scalar(
            select(Localidade.id_localidade)
            .where(
                Localidade.id_localidade == identifier,
            )
            .with_for_update(read=True)
        )
        is not None
    )
