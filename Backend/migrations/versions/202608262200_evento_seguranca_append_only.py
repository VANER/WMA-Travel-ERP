"""Protege a trilha de eventos de seguranca contra mutacoes.

Objetos: funcao e trigger append-only em public.evento_seguranca.
Dependencias: revision de recuperacao e auditoria.
Rollback: remove apenas o trigger e a funcao desta revision.
"""

from collections.abc import Sequence

from alembic import op

revision: str = "202608262200"
down_revision: str | Sequence[str] | None = "202608252330"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        """
        DO $$ BEGIN
            IF to_regclass('public.evento_seguranca') IS NULL THEN
                RAISE EXCEPTION 'migration requer public.evento_seguranca';
            END IF;
        END $$;

        CREATE FUNCTION public.fn_bloqueia_mutacao_evento_seguranca()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $$
        BEGIN
            RAISE EXCEPTION 'evento_seguranca e append-only'
                USING ERRCODE = '55000';
        END;
        $$;

        CREATE TRIGGER trg_bloqueia_mutacao
        BEFORE UPDATE OR DELETE ON public.evento_seguranca
        FOR EACH ROW EXECUTE FUNCTION public.fn_bloqueia_mutacao_evento_seguranca();

        COMMENT ON FUNCTION public.fn_bloqueia_mutacao_evento_seguranca() IS
            'Impede alteracao ou exclusao de eventos de seguranca';
        COMMENT ON TRIGGER trg_bloqueia_mutacao ON public.evento_seguranca IS
            'Garante que a trilha operacional de seguranca seja append-only';
        """
    )


def downgrade() -> None:
    op.execute("DROP TRIGGER IF EXISTS trg_bloqueia_mutacao ON public.evento_seguranca")
    op.execute("DROP FUNCTION IF EXISTS public.fn_bloqueia_mutacao_evento_seguranca()")
