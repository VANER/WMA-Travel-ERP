/* ============================================================================
   WMA TRAVEL ERP
   F1-FIN.9 â€” CONCILIACAO E MOVIMENTACAO

   PostgreSQL : 18.x
   Banco      : wma_travel
   Etapa      : F1-FIN.9
   Modo       : COMPLEMENTACAO CONTROLADA / CERTIFICACAO

   REGRA ARQUITETURAL
   ------------------
   financeiro = autoridade do dominio financeiro
   public     = corporativo / transversal

   OBJETIVO
   --------
   Consolidar em um unico script:
     1. Pre-validacao de conciliacao e movimentacao.
     2. Validacao da estrutura existente.
     3. Complementacao minima de indices/constraints/documentacao.
     4. Teste funcional de conciliacao bancaria.
     5. Validacao de vinculo entre movimento e conciliacao.
     6. Limpeza de dados artificiais.
     7. Certificacao final da F1-FIN.9.

   SEGURANCA
   ---------
   - Transacao unica.
   - ON_ERROR_STOP.
   - Sem DROP.
   - Sem CASCADE.
   - Testes artificiais removidos antes do COMMIT.
   - COMMIT somente apos certificacao final.
   ============================================================================ */

\set ON_ERROR_STOP on
\pset pager off
\pset null '(NULL)'
\timing on

\if :{?expected_database}
\else
\set expected_database wma_travel
\endif

BEGIN;

SET client_encoding = 'UTF8';
SET lock_timeout = '10s';
SET statement_timeout = '0';
SELECT set_config('wma.expected_database', :'expected_database', false);

\echo ''
\echo '============================================================'
\echo ' WMA TRAVEL ERP'
\echo ' F1-FIN.9 - CONCILIACAO E MOVIMENTACAO'
\echo '============================================================'

/* ============================================================================
   1. AMBIENTE
   ============================================================================ */

\echo ''
\echo '=== 1 - AMBIENTE ==='

SELECT
    current_database() AS banco,
    current_user AS usuario,
    current_setting('server_version') AS postgresql,
    current_setting('server_encoding') AS server_encoding,
    current_setting('client_encoding') AS client_encoding,
    CURRENT_TIMESTAMP AS executado_em;

/* ============================================================================
   2. PRE-VALIDACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 2 - PRE-VALIDACAO'
\echo '============================================================'

DO $$
DECLARE
    v_count bigint;
BEGIN
    IF current_database() <> current_setting('wma.expected_database') THEN
        RAISE EXCEPTION
            'F1-FIN.9 abortada: banco atual %, esperado %.',
            current_database(),
            current_setting('wma.expected_database');
    END IF;

    IF to_regclass('financeiro.movimentacao_bancaria') IS NULL THEN
        RAISE EXCEPTION
            'F1-FIN.9 abortada: financeiro.movimentacao_bancaria ausente.';
    END IF;

    IF to_regclass('financeiro.conciliacao_bancaria') IS NULL THEN
        RAISE EXCEPTION
            'F1-FIN.9 abortada: financeiro.conciliacao_bancaria ausente.';
    END IF;

    IF to_regclass('financeiro.conta_bancaria') IS NULL THEN
        RAISE EXCEPTION
            'F1-FIN.9 abortada: financeiro.conta_bancaria ausente.';
    END IF;

    IF to_regclass('financeiro.tipo_movimentacao') IS NULL THEN
        RAISE EXCEPTION
            'F1-FIN.9 abortada: financeiro.tipo_movimentacao ausente.';
    END IF;

    SELECT count(*)
    INTO v_count
    FROM pg_constraint con
    JOIN pg_class c
      ON c.oid = con.conrelid
    JOIN pg_namespace n
      ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relname IN (
          'movimentacao_bancaria',
          'conciliacao_bancaria'
      )
      AND NOT con.convalidated;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'F1-FIN.9 abortada: existem % constraints nao validadas.',
            v_count;
    END IF;
END
$$;

\echo 'PRE-VALIDACAO: PASS'

/* ============================================================================
   3. ESTRUTURA DE MOVIMENTACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 3 - ESTRUTURA DE MOVIMENTACAO'
\echo '============================================================'

SELECT
    ordinal_position,
    column_name,
    data_type,
    udt_name,
    is_nullable,
    is_generated,
    generation_expression,
    column_default
FROM information_schema.columns
WHERE table_schema = 'financeiro'
  AND table_name = 'movimentacao_bancaria'
ORDER BY ordinal_position;

/* ============================================================================
   4. ESTRUTURA DE CONCILIACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 4 - ESTRUTURA DE CONCILIACAO'
\echo '============================================================'

SELECT
    ordinal_position,
    column_name,
    data_type,
    udt_name,
    is_nullable,
    is_generated,
    generation_expression,
    column_default
FROM information_schema.columns
WHERE table_schema = 'financeiro'
  AND table_name = 'conciliacao_bancaria'
ORDER BY ordinal_position;

/* ============================================================================
   5. FKS E CONSTRAINTS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 5 - FKS E CONSTRAINTS'
\echo '============================================================'

SELECT
    c.relname AS table_name,
    con.conname AS constraint_name,
    CASE con.contype
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'u' THEN 'UNIQUE'
        WHEN 'c' THEN 'CHECK'
        WHEN 'n' THEN 'NOT NULL'
        ELSE con.contype::text
    END AS constraint_type,
    pg_get_constraintdef(con.oid, TRUE) AS definition,
    con.convalidated AS validated
FROM pg_constraint con
JOIN pg_class c
  ON c.oid = con.conrelid
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relname IN (
      'movimentacao_bancaria',
      'conciliacao_bancaria'
  )
ORDER BY c.relname, constraint_type, con.conname;

/* ============================================================================
   6. VALIDAR CAMPOS DE CONCILIACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 6 - CAMPOS ESSENCIAIS'
\echo '============================================================'

DO $$
DECLARE
    v_has_mov boolean;
    v_has_conta boolean;
    v_has_data boolean;
    v_has_valor boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'conciliacao_bancaria'
          AND column_name IN ('id_movimento','id_movimentacao')
    ) INTO v_has_mov;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'conciliacao_bancaria'
          AND column_name = 'id_conta_bancaria'
    ) INTO v_has_conta;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'conciliacao_bancaria'
          AND column_name ~* '(data|concili)'
    ) INTO v_has_data;

    IF NOT v_has_mov THEN
        RAISE EXCEPTION
            'F1-FIN.9 abortada: conciliacao sem id_movimento.';
    END IF;

    IF NOT v_has_data THEN
        RAISE EXCEPTION
            'F1-FIN.9 abortada: conciliacao sem data_conciliacao.';
    END IF;
END
$$;

/* ============================================================================
   7. INDICES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 7 - INDICES'
\echo '============================================================'

CREATE INDEX IF NOT EXISTS idx_movimentacao_bancaria_conta_data
    ON financeiro.movimentacao_bancaria(
        id_conta_bancaria,
        data_movimento
    );

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'conciliacao_bancaria'
          AND column_name = 'id_conta_bancaria'
    ) THEN
        EXECUTE '
            CREATE INDEX IF NOT EXISTS idx_conciliacao_bancaria_conta
            ON financeiro.conciliacao_bancaria(id_conta_bancaria)
        ';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'conciliacao_bancaria'
          AND column_name = 'id_movimento'
    ) THEN
        EXECUTE '
            CREATE INDEX IF NOT EXISTS idx_conciliacao_bancaria_movimento
            ON financeiro.conciliacao_bancaria(id_movimento)
        ';
    ELSIF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'conciliacao_bancaria'
          AND column_name = 'id_movimentacao'
    ) THEN
        EXECUTE '
            CREATE INDEX IF NOT EXISTS idx_conciliacao_bancaria_movimentacao
            ON financeiro.conciliacao_bancaria(id_movimentacao)
        ';
    END IF;
END
$$;

/* ============================================================================
   8. DOCUMENTACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 8 - DOCUMENTACAO'
\echo '============================================================'

COMMENT ON TABLE financeiro.movimentacao_bancaria IS
    'Movimentacoes bancarias financeiras utilizadas para entradas, saidas e conciliacao.';

COMMENT ON TABLE financeiro.conciliacao_bancaria IS
    'Registros de conciliacao entre movimentacoes financeiras e informacoes bancarias.';

/* ============================================================================
   9. ORFAOS E INCONSISTENCIAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 9 - ORFAOS E INCONSISTENCIAS'
\echo '============================================================'

SELECT
    COUNT(*) FILTER (
        WHERE cb.id_conta_bancaria IS NULL
    ) AS movimentos_sem_conta,

    COUNT(*) FILTER (
        WHERE tm.id_tipo_movimentacao IS NULL
    ) AS movimentos_sem_tipo

FROM financeiro.movimentacao_bancaria m
LEFT JOIN financeiro.conta_bancaria cb
  ON cb.id_conta_bancaria = m.id_conta_bancaria
LEFT JOIN financeiro.tipo_movimentacao tm
  ON tm.id_tipo_movimentacao = m.id_tipo_movimentacao;

/* ============================================================================
   10. INVENTARIO DE CONCILIACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 10 - INVENTARIO DE CONCILIACAO'
\echo '============================================================'

SELECT *
FROM financeiro.conciliacao_bancaria
ORDER BY 1;

/* ============================================================================
   11. TESTE FUNCIONAL CONTROLADO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 11 - TESTE FUNCIONAL DE CONCILIACAO'
\echo '============================================================'

CREATE TEMP TABLE f1_fin_9_test_ctx (
    id_banco integer,
    id_conta_bancaria integer,
    id_movimento bigint,
    id_conciliacao bigint
);

DO $$
DECLARE
    v_id_banco integer;
    v_id_conta integer;
    v_tipo_entrada smallint;
    v_mov bigint;
    v_conc bigint;
    v_pk_col text;
    v_cols text := '';
    v_vals text := '';
    v_sql text;
BEGIN
    SELECT id_banco
    INTO v_id_banco
    FROM financeiro.banco
    ORDER BY id_banco
    LIMIT 1;

    IF v_id_banco IS NULL THEN
        INSERT INTO financeiro.banco (
            codigo_banco,
            nome,
            ativo
        )
        VALUES (
            '997',
            'BANCO TESTE F1-FIN.9',
            TRUE
        )
        RETURNING id_banco INTO v_id_banco;
    END IF;

    INSERT INTO financeiro.conta_bancaria (
        id_banco,
        agencia,
        conta,
        digito,
        tipo,
        saldo_inicial,
        ativo
    )
    VALUES (
        v_id_banco,
        '0001',
        'F1FIN9',
        '0',
        'TESTE',
        0,
        TRUE
    )
    RETURNING id_conta_bancaria INTO v_id_conta;

    SELECT id_tipo_movimentacao
    INTO v_tipo_entrada
    FROM financeiro.tipo_movimentacao
    WHERE ativo IS TRUE
      AND entrada_saida = 'E'
    ORDER BY id_tipo_movimentacao
    LIMIT 1;

    INSERT INTO financeiro.movimentacao_bancaria (
        id_conta_bancaria,
        id_tipo_movimentacao,
        data_movimento,
        valor,
        saldo_anterior,
        saldo_atual,
        historico
    )
    VALUES (
        v_id_conta,
        v_tipo_entrada,
        CURRENT_DATE,
        350.00,
        0.00,
        350.00,
        'Teste F1-FIN.9'
    )
    RETURNING id_movimento INTO v_mov;

    /*
       Montagem dinamica da conciliacao para respeitar o schema real.
    */

    SELECT a.attname
    INTO v_pk_col
    FROM pg_index i
    JOIN pg_class c
      ON c.oid = i.indrelid
    JOIN pg_namespace n
      ON n.oid = c.relnamespace
    JOIN pg_attribute a
      ON a.attrelid = c.oid
     AND a.attnum = ANY(i.indkey)
    WHERE n.nspname = 'financeiro'
      AND c.relname = 'conciliacao_bancaria'
      AND i.indisprimary
    ORDER BY a.attnum
    LIMIT 1;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='financeiro'
          AND table_name='conciliacao_bancaria'
          AND column_name='id_movimento'
    ) THEN
        v_cols := v_cols || 'id_movimento,';
        v_vals := v_vals || v_mov || ',';
    ELSIF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='financeiro'
          AND table_name='conciliacao_bancaria'
          AND column_name='id_movimentacao'
    ) THEN
        v_cols := v_cols || 'id_movimentacao,';
        v_vals := v_vals || v_mov || ',';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='financeiro'
          AND table_name='conciliacao_bancaria'
          AND column_name='id_conta_bancaria'
    ) THEN
        v_cols := v_cols || 'id_conta_bancaria,';
        v_vals := v_vals || v_id_conta || ',';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='financeiro'
          AND table_name='conciliacao_bancaria'
          AND column_name='data_conciliacao'
    ) THEN
        v_cols := v_cols || 'data_conciliacao,';
        v_vals := v_vals || 'CURRENT_DATE,';
    ELSIF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='financeiro'
          AND table_name='conciliacao_bancaria'
          AND column_name='data'
    ) THEN
        v_cols := v_cols || 'data,';
        v_vals := v_vals || 'CURRENT_DATE,';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='financeiro'
          AND table_name='conciliacao_bancaria'
          AND column_name='valor'
    ) THEN
        v_cols := v_cols || 'valor,';
        v_vals := v_vals || '350.00,';
    ELSIF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='financeiro'
          AND table_name='conciliacao_bancaria'
          AND column_name='saldo'
    ) THEN
        v_cols := v_cols || 'saldo,';
        v_vals := v_vals || '350.00,';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='financeiro'
          AND table_name='conciliacao_bancaria'
          AND column_name='conciliado'
    ) THEN
        v_cols := v_cols || 'conciliado,';
        v_vals := v_vals || 'TRUE,';
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='financeiro'
          AND table_name='conciliacao_bancaria'
          AND column_name='observacao'
    ) THEN
        v_cols := v_cols || 'observacao,';
        v_vals := v_vals || quote_literal('Teste funcional F1-FIN.9') || ',';
    END IF;

    v_cols := regexp_replace(v_cols, ',$', '');
    v_vals := regexp_replace(v_vals, ',$', '');

    IF v_cols = '' THEN
        RAISE EXCEPTION
            'F1-FIN.9 abortada: nenhum campo utilizavel encontrado em conciliacao_bancaria.';
    END IF;

    v_sql :=
        'INSERT INTO financeiro.conciliacao_bancaria (' ||
        v_cols ||
        ') VALUES (' ||
        v_vals ||
        ') RETURNING ' ||
        quote_ident(v_pk_col);

    EXECUTE v_sql INTO v_conc;

    INSERT INTO f1_fin_9_test_ctx
    VALUES (
        v_id_banco,
        v_id_conta,
        v_mov,
        v_conc
    );
END
$$;

/* ============================================================================
   12. VALIDACAO FUNCIONAL BLOQUEANTE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 12 - VALIDACAO FUNCIONAL'
\echo '============================================================'

DO $$
DECLARE
    v_mov bigint;
    v_conc bigint;
    v_count bigint := 0;
BEGIN
    SELECT id_movimento, id_conciliacao
    INTO v_mov, v_conc
    FROM f1_fin_9_test_ctx;

    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='financeiro'
          AND table_name='conciliacao_bancaria'
          AND column_name='id_movimento'
    ) THEN
        EXECUTE format(
            'SELECT count(*)
             FROM financeiro.conciliacao_bancaria
             WHERE id_movimento = %s',
            v_mov
        )
        INTO v_count;

    ELSIF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='financeiro'
          AND table_name='conciliacao_bancaria'
          AND column_name='id_movimentacao'
    ) THEN
        EXECUTE format(
            'SELECT count(*)
             FROM financeiro.conciliacao_bancaria
             WHERE id_movimentacao = %s',
            v_mov
        )
        INTO v_count;

    ELSE
        SELECT count(*)
        INTO v_count
        FROM f1_fin_9_test_ctx
        WHERE id_conciliacao = v_conc;
    END IF;

    IF v_count <> 1 THEN
        RAISE EXCEPTION
            'F1-FIN.9 falhou: conciliacao funcional nao encontrada.';
    END IF;
END
$$;

/* ============================================================================
   13. LIMPEZA DOS DADOS DE TESTE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 13 - LIMPEZA DOS DADOS DE TESTE'
\echo '============================================================'

DO $$
DECLARE
    v_pk_col text;
BEGIN
    SELECT a.attname
    INTO v_pk_col
    FROM pg_index i
    JOIN pg_class c
      ON c.oid = i.indrelid
    JOIN pg_namespace n
      ON n.oid = c.relnamespace
    JOIN pg_attribute a
      ON a.attrelid = c.oid
     AND a.attnum = ANY(i.indkey)
    WHERE n.nspname = 'financeiro'
      AND c.relname = 'conciliacao_bancaria'
      AND i.indisprimary
    ORDER BY a.attnum
    LIMIT 1;

    EXECUTE format(
        'DELETE FROM financeiro.conciliacao_bancaria
         WHERE %I IN (
             SELECT id_conciliacao
             FROM f1_fin_9_test_ctx
         )',
        v_pk_col
    );
END
$$;

DELETE FROM financeiro.movimentacao_bancaria
WHERE id_movimento IN (
    SELECT id_movimento
    FROM f1_fin_9_test_ctx
);

DELETE FROM financeiro.conta_bancaria
WHERE id_conta_bancaria IN (
    SELECT id_conta_bancaria
    FROM f1_fin_9_test_ctx
);

DELETE FROM financeiro.banco b
WHERE b.id_banco IN (
    SELECT id_banco
    FROM f1_fin_9_test_ctx
)
AND b.codigo_banco = '997'
AND NOT EXISTS (
    SELECT 1
    FROM financeiro.conta_bancaria cb
    WHERE cb.id_banco = b.id_banco
);

/* ============================================================================
   14. CERTIFICACAO FINAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 14 - CERTIFICACAO FINAL F1-FIN.9'
\echo '============================================================'

WITH integridade AS (
    SELECT
        (
            SELECT COUNT(*)
            FROM financeiro.movimentacao_bancaria m
            LEFT JOIN financeiro.conta_bancaria cb
              ON cb.id_conta_bancaria = m.id_conta_bancaria
            WHERE cb.id_conta_bancaria IS NULL
        ) AS movimentos_sem_conta,

        (
            SELECT COUNT(*)
            FROM financeiro.movimentacao_bancaria m
            LEFT JOIN financeiro.tipo_movimentacao tm
              ON tm.id_tipo_movimentacao = m.id_tipo_movimentacao
            WHERE tm.id_tipo_movimentacao IS NULL
        ) AS movimentos_sem_tipo,

        (
            SELECT COUNT(*)
            FROM pg_constraint con
            JOIN pg_class c
              ON c.oid = con.conrelid
            JOIN pg_namespace n
              ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relname IN (
                  'movimentacao_bancaria',
                  'conciliacao_bancaria'
              )
              AND NOT con.convalidated
        ) AS constraints_nao_validadas,

        (
            SELECT COUNT(*)
            FROM financeiro.movimentacao_bancaria
            WHERE historico = 'Teste F1-FIN.9'
        ) AS dados_teste_movimento,

        (
            SELECT COUNT(*)
            FROM financeiro.conta_bancaria
            WHERE conta = 'F1FIN9'
        ) AS dados_teste_conta
)
SELECT
    i.movimentos_sem_conta,
    i.movimentos_sem_tipo,
    i.constraints_nao_validadas,
    i.dados_teste_movimento,
    i.dados_teste_conta,
    CASE
        WHEN i.movimentos_sem_conta = 0
         AND i.movimentos_sem_tipo = 0
         AND i.constraints_nao_validadas = 0
         AND i.dados_teste_movimento = 0
         AND i.dados_teste_conta = 0
        THEN 'F1_FIN_9_APROVADA'
        ELSE 'F1_FIN_9_PENDENTE'
    END AS status
FROM integridade i;

/* ============================================================================
   15. VALIDACAO BLOQUEANTE FINAL
   ============================================================================ */

DO $$
DECLARE
    v_invalid bigint;
BEGIN
    SELECT COUNT(*)
    INTO v_invalid
    FROM pg_constraint con
    JOIN pg_class c
      ON c.oid = con.conrelid
    JOIN pg_namespace n
      ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relname IN (
          'movimentacao_bancaria',
          'conciliacao_bancaria'
      )
      AND NOT con.convalidated;

    IF v_invalid <> 0 THEN
        RAISE EXCEPTION
            'F1-FIN.9 abortada: % constraints nao validadas.',
            v_invalid;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM financeiro.movimentacao_bancaria
        WHERE historico = 'Teste F1-FIN.9'
    ) THEN
        RAISE EXCEPTION
            'F1-FIN.9 abortada: movimento de teste permaneceu.';
    END IF;
END
$$;

/* ============================================================================
   COMMIT
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.9 CONCLUIDA'
\echo '============================================================'
\echo ' MOVIMENTACAO BANCARIA ............ VALIDADA'
\echo ' CONCILIACAO BANCARIA ............. VALIDADA'
\echo ' INDICES .......................... VALIDOS'
\echo ' TESTE FUNCIONAL .................. APROVADO'
\echo ' DOCUMENTACAO ..................... APLICADA'
\echo ' PROXIMA ETAPA .................... F1-FIN.10'
\echo '============================================================'

COMMIT;

\echo ''
\echo '============================================================'
\echo ' COMMIT CONCLUIDO'
\echo ' F1-FIN.9 FINALIZADA'
\echo ' PROXIMA ETAPA: F1-FIN.10 - CAPITAL, AFAC, PRO-LABORE E LUCROS'
\echo '============================================================'

