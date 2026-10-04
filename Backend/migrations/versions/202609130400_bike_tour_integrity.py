"""Bike Tour allocation release and deferred integrity.

Revision ID: 202609130400
Revises: 202609130300
"""

from collections.abc import Sequence

from alembic import op

revision: str = "202609130400"
down_revision: str | None = "202609130300"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


_FUNCTION_NAME = "fn_validar_integridade_bike_tour"
_TRIGGER_INSCRICAO = "trg_integridade_inscricao_bike_tour"
_TRIGGER_ALOCACAO = "trg_integridade_alocacao_bike_tour"


def _require_prerequisites() -> None:
    op.execute(
        """
        DO $$
        BEGIN
            IF to_regclass(
                'public.inscricao_bike_tour'
            ) IS NULL THEN
                RAISE EXCEPTION
                    'Prerequisito ausente: inscricao_bike_tour';
            END IF;

            IF to_regclass(
                'public.alocacao_recurso_bike_tour'
            ) IS NULL THEN
                RAISE EXCEPTION
                    'Prerequisito ausente: alocacao_recurso_bike_tour';
            END IF;

            IF to_regclass(
                'public.recurso_bike_tour'
            ) IS NULL THEN
                RAISE EXCEPTION
                    'Prerequisito ausente: recurso_bike_tour';
            END IF;
        END
        $$;
        """
    )


def _replace_status_check() -> None:
    op.execute(
        """
        DO $$
        DECLARE
            v_constraint_name text;
            v_count integer;
        BEGIN
            SELECT
                count(*),
                min(c.conname)
            INTO
                v_count,
                v_constraint_name
            FROM pg_constraint AS c
            JOIN pg_class AS t
                ON t.oid = c.conrelid
            JOIN pg_namespace AS n
                ON n.oid = t.relnamespace
            WHERE
                n.nspname = 'public'
                AND t.relname =
                    'alocacao_recurso_bike_tour'
                AND c.contype = 'c'
                AND pg_get_constraintdef(c.oid)
                    LIKE '%BLOQUEADA%'
                AND pg_get_constraintdef(c.oid)
                    LIKE '%CONFIRMADA%'
                AND pg_get_constraintdef(c.oid)
                    LIKE '%EXPIRADA%'
                AND pg_get_constraintdef(c.oid)
                    NOT LIKE '%LIBERADA%'
                AND pg_get_constraintdef(c.oid)
                    NOT LIKE '%expira_em%';

            IF v_count <> 1 THEN
                RAISE EXCEPTION
                    'Esperada exatamente uma CHECK de status '
                    'Bike Tour pre-400; encontradas: %',
                    v_count;
            END IF;

            EXECUTE format(
                'ALTER TABLE '
                'public.alocacao_recurso_bike_tour '
                'DROP CONSTRAINT %I',
                v_constraint_name
            );
        END
        $$;
        """
    )

    op.execute(
        """
        ALTER TABLE public.alocacao_recurso_bike_tour
        ADD CONSTRAINT
            ck_alocacao_recurso_bike_tour_status_v2
        CHECK (
            status IN (
                'BLOQUEADA',
                'CONFIRMADA',
                'EXPIRADA',
                'LIBERADA'
            )
        );
        """
    )


def _create_integrity_function() -> None:
    op.execute(
        """
        CREATE OR REPLACE FUNCTION
            public.fn_validar_integridade_bike_tour()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $$
        DECLARE
            v_inscricao_id integer;
            v_evento_inscricao integer;
            v_status_inscricao varchar;
            v_evento_alocacao integer;
            v_bicicletas_confirmadas integer;
            v_alocacoes_ativas integer;
        BEGIN
            /*
             * Esta fun??o valida uma inscri??o por chamada.
             *
             * Para UPDATE de aloca??o, dois constraint triggers
             * independentes tratam OLD e NEW quando necess?rio.
             * Para recurso, outra fun??o resolve todas as inscri??es
             * afetadas pelo recurso alterado.
             */
            IF TG_TABLE_NAME = 'inscricao_bike_tour' THEN
                v_inscricao_id :=
                    COALESCE(
                        NEW.id_inscricao_bike_tour,
                        OLD.id_inscricao_bike_tour
                    );
            ELSIF TG_TABLE_NAME =
                'alocacao_recurso_bike_tour'
            THEN
                IF TG_OP = 'DELETE' THEN
                    v_inscricao_id :=
                        OLD.id_inscricao_bike_tour;
                ELSE
                    v_inscricao_id :=
                        NEW.id_inscricao_bike_tour;
                END IF;
            ELSE
                RAISE EXCEPTION
                    'BT_INTEGRITY_UNSUPPORTED_TRIGGER_SOURCE'
                    USING ERRCODE = '23514';
            END IF;

            /*
             * Aloca??es de apoio podem n?o estar vinculadas
             * a uma inscri??o.
             */
            IF v_inscricao_id IS NULL THEN
                RETURN NULL;
            END IF;

            SELECT
                i.id_evento_bike_tour,
                i.status
            INTO
                v_evento_inscricao,
                v_status_inscricao
            FROM public.inscricao_bike_tour AS i
            WHERE
                i.id_inscricao_bike_tour =
                    v_inscricao_id
                AND i.deleted_at IS NULL;

            /*
             * Exclus?o/soft delete de inscri??o n?o pode
             * deixar aloca??o ativa ?rf?.
             */
            IF NOT FOUND THEN
                SELECT count(*)
                INTO v_alocacoes_ativas
                FROM
                    public.alocacao_recurso_bike_tour
                    AS a
                WHERE
                    a.id_inscricao_bike_tour =
                        v_inscricao_id
                    AND a.deleted_at IS NULL
                    AND a.status IN (
                        'BLOQUEADA',
                        'CONFIRMADA'
                    );

                IF v_alocacoes_ativas > 0 THEN
                    RAISE EXCEPTION
                        'BT_INTEGRITY_ACTIVE_ALLOCATION_WITHOUT_INSCRIPTION'
                        USING ERRCODE = '23514';
                END IF;

                RETURN NULL;
            END IF;

            /*
             * Toda aloca??o vinculada, inclusive hist?rica,
             * pertence ao mesmo evento da inscri??o.
             */
            SELECT a.id_evento_bike_tour
            INTO v_evento_alocacao
            FROM
                public.alocacao_recurso_bike_tour AS a
            WHERE
                a.id_inscricao_bike_tour =
                    v_inscricao_id
                AND a.deleted_at IS NULL
                AND a.id_evento_bike_tour
                    <> v_evento_inscricao
            LIMIT 1;

            IF FOUND THEN
                RAISE EXCEPTION
                    'BT_INTEGRITY_ALLOCATION_EVENT_MISMATCH'
                    USING ERRCODE = '23514';
            END IF;

            /*
             * Estados terminais nunca mant?m aloca??o
             * operacional ativa.
             */
            IF v_status_inscricao IN (
                'CONCLUIDA',
                'CANCELADA',
                'EXPIRADA',
                'NO_SHOW'
            ) THEN
                SELECT count(*)
                INTO v_alocacoes_ativas
                FROM
                    public.alocacao_recurso_bike_tour AS a
                WHERE
                    a.id_inscricao_bike_tour =
                        v_inscricao_id
                    AND a.deleted_at IS NULL
                    AND a.status IN (
                        'BLOQUEADA',
                        'CONFIRMADA'
                    );

                IF v_alocacoes_ativas <> 0 THEN
                    RAISE EXCEPTION
                        'BT_INTEGRITY_TERMINAL_WITH_ACTIVE_ALLOCATION'
                        USING ERRCODE = '23514';
                END IF;
            END IF;

            /*
             * Inscri??o confirmada exige exatamente uma
             * bicicleta confirmada.
             */
            IF v_status_inscricao = 'CONFIRMADA' THEN
                SELECT count(*)
                INTO v_bicicletas_confirmadas
                FROM
                    public.alocacao_recurso_bike_tour AS a
                JOIN public.recurso_bike_tour AS r
                    ON r.id_recurso_bike_tour =
                       a.id_recurso_bike_tour
                WHERE
                    a.id_inscricao_bike_tour =
                        v_inscricao_id
                    AND a.deleted_at IS NULL
                    AND r.deleted_at IS NULL
                    AND a.status = 'CONFIRMADA'
                    AND r.tipo = 'BICICLETA';

                IF v_bicicletas_confirmadas <> 1 THEN
                    RAISE EXCEPTION
                        'BT_INTEGRITY_CONFIRMED_BICYCLE_COUNT'
                        USING ERRCODE = '23514';
                END IF;
            END IF;

            RETURN NULL;
        END;
        $$;
        """
    )

    op.execute(
        """
        CREATE OR REPLACE FUNCTION
            public.fn_validar_integridade_recurso_bike_tour()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $$
        DECLARE
            v_inscricao_id integer;
            v_bicicletas_confirmadas integer;
        BEGIN
            /*
             * Altera??es de tipo ou soft delete de um recurso
             * podem invalidar inscri??es CONFIRMADAS que o
             * utilizam. Valida todas as inscri??es afetadas.
             */
            FOR v_inscricao_id IN
                SELECT DISTINCT
                    a.id_inscricao_bike_tour
                FROM
                    public.alocacao_recurso_bike_tour AS a
                WHERE
                    a.id_recurso_bike_tour =
                        COALESCE(
                            NEW.id_recurso_bike_tour,
                            OLD.id_recurso_bike_tour
                        )
                    AND a.id_inscricao_bike_tour
                        IS NOT NULL
                    AND a.deleted_at IS NULL
                    AND a.status = 'CONFIRMADA'
            LOOP
                IF EXISTS (
                    SELECT 1
                    FROM public.inscricao_bike_tour AS i
                    WHERE
                        i.id_inscricao_bike_tour =
                            v_inscricao_id
                        AND i.deleted_at IS NULL
                        AND i.status = 'CONFIRMADA'
                ) THEN
                    SELECT count(*)
                    INTO v_bicicletas_confirmadas
                    FROM
                        public.alocacao_recurso_bike_tour
                        AS a
                    JOIN public.recurso_bike_tour AS r
                        ON r.id_recurso_bike_tour =
                           a.id_recurso_bike_tour
                    WHERE
                        a.id_inscricao_bike_tour =
                            v_inscricao_id
                        AND a.deleted_at IS NULL
                        AND r.deleted_at IS NULL
                        AND a.status = 'CONFIRMADA'
                        AND r.tipo = 'BICICLETA';

                    IF v_bicicletas_confirmadas <> 1 THEN
                        RAISE EXCEPTION
                            'BT_INTEGRITY_CONFIRMED_BICYCLE_COUNT'
                            USING ERRCODE = '23514';
                    END IF;
                END IF;
            END LOOP;

            RETURN NULL;
        END;
        $$;
        """
    )


def _create_allocation_origin_function() -> None:
    op.execute(
        """
        CREATE OR REPLACE FUNCTION
            public.fn_validar_integridade_alocacao_origem_bike_tour()
        RETURNS trigger
        LANGUAGE plpgsql
        AS $$
        DECLARE
            v_status_inscricao varchar;
            v_bicicletas_confirmadas integer;
            v_alocacoes_ativas integer;
        BEGIN
            IF OLD.id_inscricao_bike_tour IS NULL THEN
                RETURN NULL;
            END IF;

            SELECT i.status
            INTO v_status_inscricao
            FROM public.inscricao_bike_tour AS i
            WHERE
                i.id_inscricao_bike_tour =
                    OLD.id_inscricao_bike_tour
                AND i.deleted_at IS NULL;

            IF NOT FOUND THEN
                SELECT count(*)
                INTO v_alocacoes_ativas
                FROM
                    public.alocacao_recurso_bike_tour AS a
                WHERE
                    a.id_inscricao_bike_tour =
                        OLD.id_inscricao_bike_tour
                    AND a.deleted_at IS NULL
                    AND a.status IN (
                        'BLOQUEADA',
                        'CONFIRMADA'
                    );

                IF v_alocacoes_ativas > 0 THEN
                    RAISE EXCEPTION
                        'BT_INTEGRITY_ACTIVE_ALLOCATION_WITHOUT_INSCRIPTION'
                        USING ERRCODE = '23514';
                END IF;

                RETURN NULL;
            END IF;

            IF v_status_inscricao = 'CONFIRMADA' THEN
                SELECT count(*)
                INTO v_bicicletas_confirmadas
                FROM
                    public.alocacao_recurso_bike_tour AS a
                JOIN public.recurso_bike_tour AS r
                    ON r.id_recurso_bike_tour =
                       a.id_recurso_bike_tour
                WHERE
                    a.id_inscricao_bike_tour =
                        OLD.id_inscricao_bike_tour
                    AND a.deleted_at IS NULL
                    AND r.deleted_at IS NULL
                    AND a.status = 'CONFIRMADA'
                    AND r.tipo = 'BICICLETA';

                IF v_bicicletas_confirmadas <> 1 THEN
                    RAISE EXCEPTION
                        'BT_INTEGRITY_CONFIRMED_BICYCLE_COUNT'
                        USING ERRCODE = '23514';
                END IF;
            END IF;

            RETURN NULL;
        END;
        $$;
        """
    )


def _create_constraint_triggers() -> None:
    op.execute(
        """
        CREATE CONSTRAINT TRIGGER
            trg_integridade_inscricao_bike_tour
        AFTER INSERT OR UPDATE OR DELETE
        ON public.inscricao_bike_tour
        DEFERRABLE INITIALLY DEFERRED
        FOR EACH ROW
        EXECUTE FUNCTION
            public.fn_validar_integridade_bike_tour();
        """
    )

    op.execute(
        """
        CREATE CONSTRAINT TRIGGER
            trg_integridade_alocacao_bike_tour
        AFTER INSERT OR UPDATE OR DELETE
        ON public.alocacao_recurso_bike_tour
        DEFERRABLE INITIALLY DEFERRED
        FOR EACH ROW
        EXECUTE FUNCTION
            public.fn_validar_integridade_bike_tour();
        """
    )

    # Reatribui??o tamb?m valida a inscri??o de origem.
    op.execute(
        """
        CREATE CONSTRAINT TRIGGER
            trg_integridade_alocacao_origem_bike_tour
        AFTER UPDATE
        ON public.alocacao_recurso_bike_tour
        DEFERRABLE INITIALLY DEFERRED
        FOR EACH ROW
        WHEN (
            OLD.id_inscricao_bike_tour IS DISTINCT FROM
            NEW.id_inscricao_bike_tour
        )
        EXECUTE FUNCTION
            public.fn_validar_integridade_alocacao_origem_bike_tour();
        """
    )

    op.execute(
        """
        CREATE CONSTRAINT TRIGGER
            trg_integridade_recurso_bike_tour
        AFTER UPDATE OR DELETE
        ON public.recurso_bike_tour
        DEFERRABLE INITIALLY DEFERRED
        FOR EACH ROW
        EXECUTE FUNCTION
            public.fn_validar_integridade_recurso_bike_tour();
        """
    )


def upgrade() -> None:
    _require_prerequisites()
    _replace_status_check()
    _create_integrity_function()
    _create_allocation_origin_function()
    _create_constraint_triggers()


def downgrade() -> None:
    # Remover primeiro os constraint triggers dependentes.
    op.execute(
        """
        DROP TRIGGER IF EXISTS
            trg_integridade_recurso_bike_tour
        ON public.recurso_bike_tour;
        """
    )

    op.execute(
        """
        DROP TRIGGER IF EXISTS
            trg_integridade_alocacao_origem_bike_tour
        ON public.alocacao_recurso_bike_tour;
        """
    )

    op.execute(
        f"""
        DROP TRIGGER IF EXISTS {_TRIGGER_ALOCACAO}
        ON public.alocacao_recurso_bike_tour;
        """
    )

    op.execute(
        f"""
        DROP TRIGGER IF EXISTS {_TRIGGER_INSCRICAO}
        ON public.inscricao_bike_tour;
        """
    )

    # Depois remover as fun??es usadas pelos triggers.
    op.execute(
        """
        DROP FUNCTION IF EXISTS
            public.fn_validar_integridade_recurso_bike_tour();
        """
    )

    op.execute(
        """
        DROP FUNCTION IF EXISTS
            public.fn_validar_integridade_alocacao_origem_bike_tour();
        """
    )

    op.execute(
        f"""
        DROP FUNCTION IF EXISTS
            public.{_FUNCTION_NAME}();
        """
    )

    # Restaurar exatamente o contrato de status da revision 300.
    op.execute(
        """
        ALTER TABLE public.alocacao_recurso_bike_tour
        DROP CONSTRAINT
            ck_alocacao_recurso_bike_tour_status_v2;
        """
    )

    op.execute(
        """
        ALTER TABLE public.alocacao_recurso_bike_tour
        ADD CONSTRAINT
            ck_alocacao_recurso_bike_tour_status
        CHECK (
            status IN (
                'BLOQUEADA',
                'CONFIRMADA',
                'EXPIRADA'
            )
        );
        """
    )
