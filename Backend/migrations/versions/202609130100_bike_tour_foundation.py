"""Bike Tour foundation and canonical reservation passenger.

Revision ID: 202609130100
Revises: 202609080100
"""

from collections.abc import Sequence
from typing import Any

import sqlalchemy as sa
from alembic import op

revision: str = "202609130100"
down_revision: str | None = "202609080100"
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
        sa.Column("created_by", sa.String(length=100), nullable=True),
        sa.Column("updated_by", sa.String(length=100), nullable=True),
        sa.Column("deleted_by", sa.String(length=100), nullable=True),
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
        "reserva",
        "perfil_acesso",
        "permissao",
        "perfil_permissao",
    )

    for table_name in required_tables:
        exists = bind.execute(
            sa.text(
                """
                SELECT to_regclass(:qualified_name) IS NOT NULL
                """
            ),
            {"qualified_name": f"public.{table_name}"},
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


def _install_permissions() -> None:
    op.execute(
        sa.text(
            """
            INSERT INTO public.permissao (
                codigo,
                descricao,
                modulo,
                created_by
            )
            VALUES
                (
                    'BIKETOUR_VISUALIZAR',
                    'Visualizar Bike Tour',
                    'BIKETOUR',
                    'migration'
                ),
                (
                    'BIKETOUR_OPERAR',
                    'Operar Bike Tour',
                    'BIKETOUR',
                    'migration'
                ),
                (
                    'BIKETOUR_GERENCIAR',
                    'Gerenciar Bike Tour',
                    'BIKETOUR',
                    'migration'
                )
            ON CONFLICT (codigo) DO NOTHING
            """
        )
    )

    op.execute(
        sa.text(
            """
            INSERT INTO public.perfil_permissao (
                id_perfil,
                id_permissao,
                created_by
            )
            SELECT
                pa.id_perfil,
                p.id_permissao,
                'migration'
            FROM public.perfil_acesso pa
            CROSS JOIN public.permissao p
            WHERE pa.codigo = 'ADMIN'
              AND p.codigo IN (
                  'BIKETOUR_VISUALIZAR',
                  'BIKETOUR_OPERAR',
                  'BIKETOUR_GERENCIAR'
              )
            ON CONFLICT (id_perfil, id_permissao) DO NOTHING
            """
        )
    )


def upgrade() -> None:
    _validate_prerequisites()

    op.create_table(
        "passageiro_reserva",
        sa.Column(
            "id_passageiro",
            sa.Integer(),
            sa.Identity(),
            primary_key=True,
        ),
        sa.Column(
            "id_reserva",
            sa.Integer(),
            sa.ForeignKey(
                "reserva.id_reserva",
                name="fk_passageiro_reserva_reserva",
            ),
            nullable=False,
        ),
        sa.Column("ordem", sa.Integer(), nullable=False),
        sa.Column(
            "status",
            sa.String(length=20),
            nullable=False,
            server_default=sa.text("'ATIVO'"),
        ),
        *_audit_columns(),
        sa.CheckConstraint(
            "ordem > 0",
            name="ck_passageiro_reserva_ordem_positiva",
        ),
        sa.CheckConstraint(
            "status IN ('ATIVO', 'INATIVO')",
            name="ck_passageiro_reserva_status",
        ),
        sa.UniqueConstraint(
            "id_reserva",
            "ordem",
            name="uq_passageiro_reserva_reserva_ordem",
        ),
        schema="public",
    )

    op.create_index(
        "idx_passageiro_reserva_id_reserva",
        "passageiro_reserva",
        ["id_reserva"],
        schema="public",
    )

    _create_audit_triggers("passageiro_reserva")
    _install_permissions()


def downgrade() -> None:
    op.execute(
        sa.text(
            """
            DELETE FROM public.perfil_permissao pp
            USING public.perfil_acesso pa, public.permissao p
            WHERE pp.id_perfil = pa.id_perfil
              AND pp.id_permissao = p.id_permissao
              AND pa.codigo = 'ADMIN'
              AND p.codigo IN (
                  'BIKETOUR_VISUALIZAR',
                  'BIKETOUR_OPERAR',
                  'BIKETOUR_GERENCIAR'
              )
              AND pp.created_by = 'migration'
            """
        )
    )

    op.execute(
        sa.text(
            """
            DELETE FROM public.permissao
            WHERE codigo IN (
                'BIKETOUR_VISUALIZAR',
                'BIKETOUR_OPERAR',
                'BIKETOUR_GERENCIAR'
            )
              AND created_by = 'migration'
            """
        )
    )

    _drop_audit_triggers("passageiro_reserva")

    op.drop_index(
        "idx_passageiro_reserva_id_reserva",
        table_name="passageiro_reserva",
        schema="public",
    )

    op.drop_table(
        "passageiro_reserva",
        schema="public",
    )
