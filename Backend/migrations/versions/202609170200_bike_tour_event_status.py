"""Normaliza o estado de execucao do evento Bike Tour.

Revision ID: 202609170200
Revises: 202609170100
"""

from collections.abc import Sequence

from alembic import op

revision: str = "202609170200"
down_revision: str | None = "202609170100"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    """Adota EM_EXECUCAO como estado canonico do evento Bike Tour."""

    op.execute(
        """
        DO $$
        BEGIN
            IF EXISTS (
                SELECT 1
                  FROM pg_constraint c
                  JOIN pg_class t ON t.oid = c.conrelid
                  JOIN pg_namespace n ON n.oid = t.relnamespace
                 WHERE n.nspname = 'public'
                   AND t.relname = 'evento_bike_tour'
                   AND c.conname = 'ck_evento_bike_tour_status'
            ) THEN
                ALTER TABLE public.evento_bike_tour
                    DROP CONSTRAINT ck_evento_bike_tour_status;
            END IF;
            IF EXISTS (
                SELECT 1
                  FROM pg_constraint c
                  JOIN pg_class t ON t.oid = c.conrelid
                  JOIN pg_namespace n ON n.oid = t.relnamespace
                 WHERE n.nspname = 'public'
                   AND t.relname = 'evento_bike_tour'
                   AND c.conname = 'ck_evento_bike_tour_ck_evento_bike_tour_status'
            ) THEN
                ALTER TABLE public.evento_bike_tour
                    DROP CONSTRAINT ck_evento_bike_tour_ck_evento_bike_tour_status;
            END IF;
        END $$;
        """
    )

    op.execute(
        """
        UPDATE public.evento_bike_tour
           SET status = 'EM_EXECUCAO'
         WHERE status = 'EM_ANDAMENTO'
        """
    )

    op.execute(
        """
        ALTER TABLE public.evento_bike_tour
        ADD CONSTRAINT ck_evento_bike_tour_status CHECK (
            status IN (
                'PLANEJADO',
                'ABERTO',
                'EM_EXECUCAO',
                'CONCLUIDO',
                'CANCELADO'
            )
        )
        """
    )


def downgrade() -> None:
    """Restaura o vocabulário histórico da revision 130200."""

    op.execute(
        """
        DO $$
        BEGIN
            ALTER TABLE public.evento_bike_tour
                DROP CONSTRAINT IF EXISTS ck_evento_bike_tour_status;
            ALTER TABLE public.evento_bike_tour
                DROP CONSTRAINT IF EXISTS ck_evento_bike_tour_ck_evento_bike_tour_status;
        END $$;
        """
    )

    op.execute(
        """
        UPDATE public.evento_bike_tour
           SET status = 'EM_ANDAMENTO'
         WHERE status = 'EM_EXECUCAO'
        """
    )

    op.execute(
        """
        ALTER TABLE public.evento_bike_tour
        ADD CONSTRAINT ck_evento_bike_tour_status CHECK (
            status IN (
                'PLANEJADO',
                'ABERTO',
                'EM_ANDAMENTO',
                'CONCLUIDO',
                'CANCELADO'
            )
        )
        """
    )
