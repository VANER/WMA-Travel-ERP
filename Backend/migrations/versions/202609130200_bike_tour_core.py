"""Bike Tour core product, event and resource.

Revision ID: 202609130200
Revises: 202609130100
"""

from collections.abc import Sequence
from typing import Any

import sqlalchemy as sa
from alembic import op

revision: str = "202609130200"
down_revision: str | None = "202609130100"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

TABLES = (
    "produto_bike_tour",
    "evento_bike_tour",
    "recurso_bike_tour",
)


def _audit_columns() -> list[sa.Column[Any]]:
    return [
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
        sa.Column(
            "deleted_at",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
        sa.Column(
            "created_by",
            sa.String(length=100),
            nullable=True,
        ),
        sa.Column(
            "updated_by",
            sa.String(length=100),
            nullable=True,
        ),
        sa.Column(
            "deleted_by",
            sa.String(length=100),
            nullable=True,
        ),
        sa.Column(
            "versao",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("1"),
        ),
    ]


def _create_audit_triggers(table_name: str) -> None:
    op.execute(
        sa.text(
            f"""
            CREATE TRIGGER trg_atualiza_updated_at
            BEFORE UPDATE ON public.{table_name}
            FOR EACH ROW
            EXECUTE FUNCTION public.fn_atualiza_updated_at()
            """
        )
    )

    op.execute(
        sa.text(
            f"""
            CREATE TRIGGER trg_log_auditoria
            AFTER INSERT OR UPDATE OR DELETE ON public.{table_name}
            FOR EACH ROW
            EXECUTE FUNCTION public.fn_log_auditoria()
            """
        )
    )


def _drop_audit_triggers(table_name: str) -> None:
    op.execute(
        sa.text(
            f"""
            DROP TRIGGER IF EXISTS trg_log_auditoria
            ON public.{table_name}
            """
        )
    )

    op.execute(
        sa.text(
            f"""
            DROP TRIGGER IF EXISTS trg_atualiza_updated_at
            ON public.{table_name}
            """
        )
    )


def _validate_prerequisites() -> None:
    bind = op.get_bind()

    required_tables = (
        "produto_turistico",
        "saida_turistica",
        "passageiro_reserva",
    )

    for table_name in required_tables:
        exists = bind.execute(
            sa.text(
                """
                SELECT to_regclass(:qualified_name) IS NOT NULL
                """
            ),
            {"qualified_name": (f"public.{table_name}")},
        ).scalar_one()

        if not exists:
            raise RuntimeError(f"Bike Tour prerequisite missing: public.{table_name}")

    for function_name in (
        "fn_atualiza_updated_at",
        "fn_log_auditoria",
    ):
        exists = bind.execute(
            sa.text(
                """
                SELECT EXISTS (
                    SELECT 1
                    FROM pg_proc p
                    JOIN pg_namespace n
                      ON n.oid = p.pronamespace
                    WHERE n.nspname = 'public'
                      AND p.proname = :function_name
                )
                """
            ),
            {"function_name": function_name},
        ).scalar_one()

        if not exists:
            raise RuntimeError(f"Bike Tour prerequisite missing: public.{function_name}")


def upgrade() -> None:
    _validate_prerequisites()

    op.create_table(
        "produto_bike_tour",
        sa.Column(
            "id_produto_bike_tour",
            sa.Integer(),
            sa.Identity(),
            primary_key=True,
        ),
        sa.Column(
            "id_produto",
            sa.Integer(),
            sa.ForeignKey(
                "produto_turistico.id_produto",
                name=("fk_produto_bike_tour_produto_turistico"),
            ),
            nullable=False,
        ),
        sa.Column(
            "distancia_km",
            sa.Numeric(10, 2),
            nullable=False,
        ),
        sa.Column(
            "desnivel_m",
            sa.Numeric(10, 2),
            nullable=False,
            server_default=sa.text("0"),
        ),
        sa.Column(
            "nivel",
            sa.String(length=20),
            nullable=False,
        ),
        sa.Column(
            "ativo",
            sa.Boolean(),
            nullable=False,
            server_default=sa.text("true"),
        ),
        *_audit_columns(),
        sa.CheckConstraint(
            "distancia_km > 0",
            name="ck_produto_bike_tour_distancia_positiva",
        ),
        sa.CheckConstraint(
            "desnivel_m >= 0",
            name="ck_produto_bike_tour_desnivel_nao_negativo",
        ),
        sa.CheckConstraint(
            """
            nivel IN (
                'FACIL',
                'MODERADO',
                'DIFICIL',
                'AVANCADO'
            )
            """,
            name="ck_produto_bike_tour_nivel",
        ),
        sa.UniqueConstraint(
            "id_produto",
            name="uq_produto_bike_tour_id_produto",
        ),
        schema="public",
    )

    op.create_table(
        "evento_bike_tour",
        sa.Column(
            "id_evento_bike_tour",
            sa.Integer(),
            sa.Identity(),
            primary_key=True,
        ),
        sa.Column(
            "id_saida",
            sa.Integer(),
            sa.ForeignKey(
                "saida_turistica.id_saida",
                name=("fk_evento_bike_tour_saida_turistica"),
            ),
            nullable=False,
        ),
        sa.Column(
            "inicio",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.Column(
            "fim",
            sa.DateTime(timezone=True),
            nullable=False,
        ),
        sa.Column(
            "capacidade",
            sa.Integer(),
            nullable=False,
        ),
        sa.Column(
            "status",
            sa.String(length=20),
            nullable=False,
            server_default=sa.text("'PLANEJADO'"),
        ),
        *_audit_columns(),
        sa.CheckConstraint(
            "inicio < fim",
            name="ck_evento_bike_tour_periodo",
        ),
        sa.CheckConstraint(
            "capacidade BETWEEN 1 AND 1000",
            name="ck_evento_bike_tour_capacidade",
        ),
        sa.CheckConstraint(
            """
            status IN (
                'PLANEJADO',
                'ABERTO',
                'EM_ANDAMENTO',
                'CONCLUIDO',
                'CANCELADO'
            )
            """,
            name="ck_evento_bike_tour_status",
        ),
        sa.UniqueConstraint(
            "id_saida",
            name="uq_evento_bike_tour_id_saida",
        ),
        schema="public",
    )

    op.create_table(
        "recurso_bike_tour",
        sa.Column(
            "id_recurso_bike_tour",
            sa.Integer(),
            sa.Identity(),
            primary_key=True,
        ),
        sa.Column(
            "codigo",
            sa.String(length=30),
            nullable=False,
        ),
        sa.Column(
            "tipo",
            sa.String(length=20),
            nullable=False,
        ),
        sa.Column(
            "status",
            sa.String(length=20),
            nullable=False,
            server_default=sa.text("'DISPONIVEL'"),
        ),
        sa.Column(
            "id_ativo",
            sa.Integer(),
            nullable=True,
        ),
        sa.Column(
            "id_guia",
            sa.Integer(),
            nullable=True,
        ),
        sa.Column(
            "id_transporte",
            sa.Integer(),
            nullable=True,
        ),
        *_audit_columns(),
        sa.CheckConstraint(
            """
            tipo IN (
                'BICICLETA',
                'EQUIPAMENTO',
                'GUIA',
                'VEICULO'
            )
            """,
            name="ck_recurso_bike_tour_tipo",
        ),
        sa.CheckConstraint(
            """
            status IN (
                'DISPONIVEL',
                'INDISPONIVEL',
                'MANUTENCAO',
                'INATIVO'
            )
            """,
            name="ck_recurso_bike_tour_status",
        ),
        sa.CheckConstraint(
            """
            (
                CASE
                    WHEN id_ativo IS NOT NULL
                    THEN 1 ELSE 0
                END
                +
                CASE
                    WHEN id_guia IS NOT NULL
                    THEN 1 ELSE 0
                END
                +
                CASE
                    WHEN id_transporte IS NOT NULL
                    THEN 1 ELSE 0
                END
            ) <= 1
            """,
            name="ck_recurso_bike_tour_origem_unica",
        ),
        sa.UniqueConstraint(
            "codigo",
            name="uq_recurso_bike_tour_codigo",
        ),
        schema="public",
    )

    for table_name in TABLES:
        _create_audit_triggers(table_name)


def downgrade() -> None:
    for table_name in reversed(TABLES):
        _drop_audit_triggers(table_name)
        op.drop_table(
            table_name,
            schema="public",
        )
