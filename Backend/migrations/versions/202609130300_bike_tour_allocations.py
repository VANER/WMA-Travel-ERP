"""Bike Tour inscriptions, allocations and temporal exclusion.

Revision ID: 202609130300
Revises: 202609130200
"""

from collections.abc import Sequence
from typing import Any

import sqlalchemy as sa
from alembic import op

revision: str = "202609130300"
down_revision: str | None = "202609130200"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


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


def _require_table(table_name: str) -> None:
    bind = op.get_bind()

    exists = bind.execute(
        sa.text(
            """
            SELECT to_regclass(:name) IS NOT NULL
            """
        ),
        {"name": f"public.{table_name}"},
    ).scalar_one()

    if not exists:
        raise RuntimeError(f"Bike Tour prerequisite missing: public.{table_name}")


def _require_function(function_name: str) -> None:
    bind = op.get_bind()

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


def _ensure_btree_gist() -> None:
    bind = op.get_bind()

    installed = bind.execute(
        sa.text(
            """
            SELECT EXISTS (
                SELECT 1
                FROM pg_extension
                WHERE extname = 'btree_gist'
            )
            """
        )
    ).scalar_one()

    if installed:
        return

    available = bind.execute(
        sa.text(
            """
            SELECT EXISTS (
                SELECT 1
                FROM pg_available_extensions
                WHERE name = 'btree_gist'
            )
            """
        )
    ).scalar_one()

    if not available:
        raise RuntimeError("PostgreSQL extension btree_gist unavailable.")

    op.execute(
        sa.text(
            """
            CREATE EXTENSION IF NOT EXISTS btree_gist
            """
        )
    )


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
            AFTER INSERT OR UPDATE OR DELETE
            ON public.{table_name}
            FOR EACH ROW
            EXECUTE FUNCTION public.fn_log_auditoria()
            """
        )
    )


def upgrade() -> None:
    for table_name in (
        "evento_bike_tour",
        "recurso_bike_tour",
        "reserva",
        "passageiro_reserva",
        "ativo_imobilizado",
        "guia_turistico",
        "transporte",
    ):
        _require_table(table_name)

    for function_name in (
        "fn_atualiza_updated_at",
        "fn_log_auditoria",
    ):
        _require_function(function_name)

    _ensure_btree_gist()

    op.create_foreign_key(
        "fk_recurso_bike_tour_ativo_imobilizado",
        "recurso_bike_tour",
        "ativo_imobilizado",
        ["id_ativo"],
        ["id_ativo"],
        source_schema="public",
        referent_schema="public",
    )

    op.create_foreign_key(
        "fk_recurso_bike_tour_guia_turistico",
        "recurso_bike_tour",
        "guia_turistico",
        ["id_guia"],
        ["id_guia"],
        source_schema="public",
        referent_schema="public",
    )

    op.create_foreign_key(
        "fk_recurso_bike_tour_transporte",
        "recurso_bike_tour",
        "transporte",
        ["id_transporte"],
        ["id_transporte"],
        source_schema="public",
        referent_schema="public",
    )

    op.create_table(
        "inscricao_bike_tour",
        sa.Column(
            "id_inscricao_bike_tour",
            sa.Integer(),
            sa.Identity(),
            primary_key=True,
        ),
        sa.Column(
            "id_evento_bike_tour",
            sa.Integer(),
            sa.ForeignKey(
                "evento_bike_tour.id_evento_bike_tour",
                name=("fk_inscricao_bike_tour_evento_bike_tour"),
            ),
            nullable=False,
        ),
        sa.Column(
            "id_reserva",
            sa.Integer(),
            sa.ForeignKey(
                "reserva.id_reserva",
                name="fk_inscricao_bike_tour_reserva",
            ),
            nullable=False,
        ),
        sa.Column(
            "id_passageiro",
            sa.Integer(),
            sa.ForeignKey(
                "passageiro_reserva.id_passageiro",
                name=("fk_inscricao_bike_tour_passageiro_reserva"),
            ),
            nullable=False,
        ),
        sa.Column(
            "papel",
            sa.String(length=20),
            nullable=False,
        ),
        sa.Column(
            "status",
            sa.String(length=20),
            nullable=False,
            server_default=sa.text("'PENDENTE'"),
        ),
        *_audit_columns(),
        sa.UniqueConstraint(
            "id_evento_bike_tour",
            "id_passageiro",
            name=("uq_inscricao_bike_tour_evento_passageiro"),
        ),
        sa.CheckConstraint(
            "papel IN ('CICLISTA', 'ACOMPANHANTE')",
            name="ck_inscricao_bike_tour_papel",
        ),
        sa.CheckConstraint(
            """
            status IN (
                'PENDENTE',
                'CONFIRMADA',
                'PRESENTE',
                'CONCLUIDA',
                'CANCELADA',
                'EXPIRADA',
                'NO_SHOW'
            )
            """,
            name="ck_inscricao_bike_tour_status",
        ),
        schema="public",
    )

    op.create_index(
        "idx_inscricao_bike_tour_evento_status",
        "inscricao_bike_tour",
        ["id_evento_bike_tour", "status"],
        schema="public",
    )

    op.create_index(
        "idx_inscricao_bike_tour_reserva",
        "inscricao_bike_tour",
        ["id_reserva"],
        schema="public",
    )

    op.create_table(
        "alocacao_recurso_bike_tour",
        sa.Column(
            "id_alocacao_recurso_bike_tour",
            sa.Integer(),
            sa.Identity(),
            primary_key=True,
        ),
        sa.Column(
            "id_evento_bike_tour",
            sa.Integer(),
            sa.ForeignKey(
                "evento_bike_tour.id_evento_bike_tour",
                name=("fk_alocacao_recurso_bike_tour_evento_bike_tour"),
            ),
            nullable=False,
        ),
        sa.Column(
            "id_inscricao_bike_tour",
            sa.Integer(),
            sa.ForeignKey(
                "inscricao_bike_tour.id_inscricao_bike_tour",
                name=("fk_alocacao_recurso_bike_tour_inscricao_bike_tour"),
            ),
            nullable=True,
        ),
        sa.Column(
            "id_recurso_bike_tour",
            sa.Integer(),
            sa.ForeignKey(
                "recurso_bike_tour.id_recurso_bike_tour",
                name=("fk_alocacao_recurso_bike_tour_recurso_bike_tour"),
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
            "expira_em",
            sa.DateTime(timezone=True),
            nullable=True,
        ),
        sa.Column(
            "status",
            sa.String(length=20),
            nullable=False,
            server_default=sa.text("'BLOQUEADA'"),
        ),
        *_audit_columns(),
        sa.CheckConstraint(
            "inicio < fim",
            name=("ck_alocacao_recurso_bike_tour_periodo"),
        ),
        sa.CheckConstraint(
            """
            status IN (
                'BLOQUEADA',
                'CONFIRMADA',
                'EXPIRADA'
            )
            """,
            name=("ck_alocacao_recurso_bike_tour_status"),
        ),
        sa.CheckConstraint(
            """
            (
                status = 'BLOQUEADA'
                AND expira_em IS NOT NULL
            )
            OR
            (
                status <> 'BLOQUEADA'
                AND expira_em IS NULL
            )
            """,
            name=("ck_alocacao_recurso_bike_tour_expiracao"),
        ),
        schema="public",
    )

    op.create_index(
        ("idx_alocacao_recurso_bike_tour_evento_status_expira"),
        "alocacao_recurso_bike_tour",
        [
            "id_evento_bike_tour",
            "status",
            "expira_em",
        ],
        schema="public",
    )

    op.create_index(
        "idx_alocacao_recurso_bike_tour_inscricao",
        "alocacao_recurso_bike_tour",
        ["id_inscricao_bike_tour"],
        schema="public",
    )

    op.create_index(
        "idx_alocacao_recurso_bike_tour_recurso",
        "alocacao_recurso_bike_tour",
        ["id_recurso_bike_tour"],
        schema="public",
    )

    op.execute(
        sa.text(
            """
            ALTER TABLE public.alocacao_recurso_bike_tour
            ADD CONSTRAINT
                ex_alocacao_recurso_bike_tour_periodo_ativo
            EXCLUDE USING gist (
                id_recurso_bike_tour WITH =,
                tstzrange(inicio, fim, '[)') WITH &&
            )
            WHERE (
                status IN ('BLOQUEADA', 'CONFIRMADA')
            )
            """
        )
    )

    _create_audit_triggers("inscricao_bike_tour")
    _create_audit_triggers("alocacao_recurso_bike_tour")


def downgrade() -> None:
    op.drop_table(
        "alocacao_recurso_bike_tour",
        schema="public",
    )

    op.drop_table(
        "inscricao_bike_tour",
        schema="public",
    )

    for constraint_name in (
        "fk_recurso_bike_tour_transporte",
        "fk_recurso_bike_tour_guia_turistico",
        "fk_recurso_bike_tour_ativo_imobilizado",
    ):
        op.drop_constraint(
            constraint_name,
            "recurso_bike_tour",
            type_="foreignkey",
            schema="public",
        )

    # btree_gist permanece instalada.
    # A extensao pode ser compartilhada por objetos futuros.
