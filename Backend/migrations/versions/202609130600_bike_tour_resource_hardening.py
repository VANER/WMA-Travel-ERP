"""Harden Bike Tour resource origin integrity.

Revision ID: 202609130600
Revises: 202609130500
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "202609130600"
down_revision: str | None = "202609130500"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _validate_existing_rows() -> None:
    bind = op.get_bind()

    incompatible = bind.execute(
        sa.text(
            """
            SELECT id_recurso_bike_tour
            FROM public.recurso_bike_tour
            WHERE NOT (
                (
                    tipo IN ('BICICLETA', 'EQUIPAMENTO')
                    AND id_guia IS NULL
                    AND id_transporte IS NULL
                )
                OR
                (
                    tipo = 'GUIA'
                    AND id_ativo IS NULL
                    AND id_guia IS NOT NULL
                    AND id_transporte IS NULL
                )
                OR
                (
                    tipo = 'VEICULO'
                    AND id_ativo IS NULL
                    AND id_guia IS NULL
                    AND id_transporte IS NOT NULL
                )
            )
            LIMIT 1
            """
        )
    ).first()

    if incompatible is not None:
        raise RuntimeError("recurso_bike_tour possui origem incompatível com o tipo")

    duplicate = bind.execute(
        sa.text(
            """
            SELECT origem, identificador
            FROM (
                SELECT
                    'id_ativo' AS origem,
                    id_ativo AS identificador
                FROM public.recurso_bike_tour
                WHERE id_ativo IS NOT NULL

                UNION ALL

                SELECT
                    'id_guia' AS origem,
                    id_guia AS identificador
                FROM public.recurso_bike_tour
                WHERE id_guia IS NOT NULL

                UNION ALL

                SELECT
                    'id_transporte' AS origem,
                    id_transporte AS identificador
                FROM public.recurso_bike_tour
                WHERE id_transporte IS NOT NULL
            ) AS origens
            GROUP BY origem, identificador
            HAVING COUNT(*) > 1
            LIMIT 1
            """
        )
    ).first()

    if duplicate is not None:
        raise RuntimeError("recurso_bike_tour possui origem externa duplicada")


def upgrade() -> None:
    _validate_existing_rows()

    op.create_unique_constraint(
        "uq_recurso_bike_tour_id_ativo",
        "recurso_bike_tour",
        ["id_ativo"],
        schema="public",
    )

    op.create_unique_constraint(
        "uq_recurso_bike_tour_id_guia",
        "recurso_bike_tour",
        ["id_guia"],
        schema="public",
    )

    op.create_unique_constraint(
        "uq_recurso_bike_tour_id_transporte",
        "recurso_bike_tour",
        ["id_transporte"],
        schema="public",
    )

    op.create_check_constraint(
        op.f("ck_recurso_bike_tour_origem_compativel_tipo"),
        "recurso_bike_tour",
        """
        (
            tipo IN ('BICICLETA', 'EQUIPAMENTO')
            AND id_guia IS NULL
            AND id_transporte IS NULL
        )
        OR
        (
            tipo = 'GUIA'
            AND id_ativo IS NULL
            AND id_guia IS NOT NULL
            AND id_transporte IS NULL
        )
        OR
        (
            tipo = 'VEICULO'
            AND id_ativo IS NULL
            AND id_guia IS NULL
            AND id_transporte IS NOT NULL
        )
        """,
        schema="public",
    )


def downgrade() -> None:
    op.drop_constraint(
        op.f("ck_recurso_bike_tour_origem_compativel_tipo"),
        "recurso_bike_tour",
        schema="public",
        type_="check",
    )

    op.drop_constraint(
        "uq_recurso_bike_tour_id_transporte",
        "recurso_bike_tour",
        schema="public",
        type_="unique",
    )

    op.drop_constraint(
        "uq_recurso_bike_tour_id_guia",
        "recurso_bike_tour",
        schema="public",
        type_="unique",
    )

    op.drop_constraint(
        "uq_recurso_bike_tour_id_ativo",
        "recurso_bike_tour",
        schema="public",
        type_="unique",
    )
