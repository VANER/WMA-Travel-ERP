"""Alinha o vocabulario de nivel do Bike Tour ao contrato A2.

Revision ID: 202609170300
Revises: 202609170200
"""

from collections.abc import Sequence

from alembic import op
from sqlalchemy import text

revision: str = "202609170300"
down_revision: str | None = "202609170200"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


_TABLE = "produto_bike_tour"

_OLD_CONSTRAINT = "ck_produto_bike_tour_ck_produto_bike_tour_nivel"

_NEW_CONSTRAINT = "ck_produto_bike_tour_nivel"


def upgrade() -> None:
    """Alinha nivel ao contrato funcional A2."""

    op.drop_constraint(
        op.f(_OLD_CONSTRAINT),
        _TABLE,
        type_="check",
    )

    op.create_check_constraint(
        op.f(_NEW_CONSTRAINT),
        _TABLE,
        "nivel IN ('INICIANTE', 'INTERMEDIARIO', 'AVANCADO')",
    )


def downgrade() -> None:
    """Restaura o vocabulario anterior somente com dados compativeis."""

    incompatible_levels = (
        op.get_bind()
        .execute(
            text(
                "SELECT EXISTS ("
                "SELECT 1 FROM produto_bike_tour "
                "WHERE nivel NOT IN (:facil, :moderado, :dificil, :avancado)"
                ")"
            ),
            {
                "facil": "FACIL",
                "moderado": "MODERADO",
                "dificil": "DIFICIL",
                "avancado": "AVANCADO",
            },
        )
        .scalar_one()
    )
    if incompatible_levels:
        raise RuntimeError(
            "Downgrade bloqueado: existem niveis incompativeis com o vocabulario "
            "legado; nao existe mapeamento reverso semanticamente seguro."
        )

    op.drop_constraint(
        op.f(_NEW_CONSTRAINT),
        _TABLE,
        type_="check",
    )

    op.create_check_constraint(
        op.f(_OLD_CONSTRAINT),
        _TABLE,
        ("nivel IN ('FACIL', 'MODERADO', 'DIFICIL', 'AVANCADO')"),
    )
