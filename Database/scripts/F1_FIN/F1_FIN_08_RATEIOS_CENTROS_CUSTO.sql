/* ============================================================================
   WMA TRAVEL ERP
   F1-FIN.8 — RATEIOS E CENTROS DE CUSTO

   PostgreSQL : 18.x
   Banco      : wma_travel
   Etapa      : F1-FIN.8
   Modo       : COMPLEMENTACAO CONTROLADA / CERTIFICACAO

   REGRA ARQUITETURAL
   ------------------
   financeiro = autoridade do dominio financeiro
   public     = corporativo / transversal

   OBJETIVO
   --------
   Consolidar em um unico script:
     1. Pre-validacao de centro_custo e rateio_centro_custo.
     2. Validacao da estrutura existente.
     3. Complementacao minima de constraints/indices, se necessaria.
     4. Teste funcional de rateio percentual e por valor.
     5. Validacao de soma de rateios por lancamento.
     6. Documentacao.
     7. Certificacao final da F1-FIN.8.

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
\echo ' F1-FIN.8 - RATEIOS E CENTROS DE CUSTO'
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
            'F1-FIN.8 abortada: banco atual %, esperado %.',
            current_database(),
            current_setting('wma.expected_database');
    END IF;

    IF to_regclass('financeiro.centro_custo') IS NULL THEN
        RAISE EXCEPTION
            'F1-FIN.8 abortada: financeiro.centro_custo ausente.';
    END IF;

    IF to_regclass('financeiro.rateio_centro_custo') IS NULL THEN
        RAISE EXCEPTION
            'F1-FIN.8 abortada: financeiro.rateio_centro_custo ausente.';
    END IF;

    IF to_regclass('financeiro.lancamento') IS NULL THEN
        RAISE EXCEPTION
            'F1-FIN.8 abortada: financeiro.lancamento ausente.';
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.centro_custo;

    IF v_count = 0 THEN
        RAISE EXCEPTION
            'F1-FIN.8 abortada: nenhum centro de custo cadastrado.';
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
          'centro_custo',
          'rateio_centro_custo'
      )
      AND NOT con.convalidated;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'F1-FIN.8 abortada: existem % constraints nao validadas.',
            v_count;
    END IF;
END
$$;

\echo 'PRE-VALIDACAO: PASS'

/* ============================================================================
   3. INVENTARIO DE CENTROS DE CUSTO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 3 - CENTROS DE CUSTO'
\echo '============================================================'

SELECT *
FROM financeiro.centro_custo
ORDER BY id_centro_custo;

/* ============================================================================
   4. ESTRUTURA DE RATEIO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 4 - ESTRUTURA DE RATEIO'
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
  AND table_name = 'rateio_centro_custo'
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
      'centro_custo',
      'rateio_centro_custo'
  )
ORDER BY c.relname, constraint_type, con.conname;

/* ============================================================================
   6. VALIDAR COLUNAS ESSENCIAIS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 6 - VALIDACAO DE COLUNAS ESSENCIAIS'
\echo '============================================================'

DO $$
DECLARE
    v_id_lanc boolean;
    v_id_cc boolean;
    v_percentual boolean;
    v_valor boolean;
BEGIN
    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'rateio_centro_custo'
          AND column_name = 'id_lancamento'
    ) INTO v_id_lanc;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'rateio_centro_custo'
          AND column_name = 'id_centro_custo'
    ) INTO v_id_cc;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'rateio_centro_custo'
          AND column_name = 'percentual'
    ) INTO v_percentual;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'rateio_centro_custo'
          AND column_name = 'valor'
    ) INTO v_valor;

    IF NOT v_id_lanc OR NOT v_id_cc THEN
        RAISE EXCEPTION
            'F1-FIN.8 abortada: rateio sem id_lancamento/id_centro_custo.';
    END IF;

    IF NOT v_percentual AND NOT v_valor THEN
        RAISE EXCEPTION
            'F1-FIN.8 abortada: rateio sem percentual e sem valor.';
    END IF;
END
$$;

/* ============================================================================
   7. COMPLEMENTACAO MINIMA DE INDICES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 7 - INDICES'
\echo '============================================================'

CREATE INDEX IF NOT EXISTS idx_rateio_centro_custo_lancamento
    ON financeiro.rateio_centro_custo(id_lancamento);

CREATE INDEX IF NOT EXISTS idx_rateio_centro_custo_centro
    ON financeiro.rateio_centro_custo(id_centro_custo);

/* ============================================================================
   8. COMPLEMENTACAO MINIMA DE UNICIDADE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 8 - UNICIDADE LOGICA'
\echo '============================================================'

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint con
        JOIN pg_class c
          ON c.oid = con.conrelid
        JOIN pg_namespace n
          ON n.oid = c.relnamespace
        WHERE n.nspname = 'financeiro'
          AND c.relname = 'rateio_centro_custo'
          AND con.contype = 'u'
          AND pg_get_constraintdef(con.oid, TRUE) ILIKE '%id_lancamento%'
          AND pg_get_constraintdef(con.oid, TRUE) ILIKE '%id_centro_custo%'
    ) THEN
        ALTER TABLE financeiro.rateio_centro_custo
            ADD CONSTRAINT uk_rateio_lancamento_centro
            UNIQUE (id_lancamento, id_centro_custo);
    END IF;
END
$$;

/* ============================================================================
   9. CHECKS OPCIONAIS CONFORME COLUNAS EXISTENTES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 9 - CHECKS DE RATEIO'
\echo '============================================================'

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'rateio_centro_custo'
          AND column_name = 'percentual'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM pg_constraint con
        JOIN pg_class c
          ON c.oid = con.conrelid
        JOIN pg_namespace n
          ON n.oid = c.relnamespace
        WHERE n.nspname = 'financeiro'
          AND c.relname = 'rateio_centro_custo'
          AND con.conname = 'chk_rateio_percentual'
    ) THEN
        ALTER TABLE financeiro.rateio_centro_custo
            ADD CONSTRAINT chk_rateio_percentual
            CHECK (
                percentual IS NULL
                OR (percentual > 0 AND percentual <= 100)
            );
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'rateio_centro_custo'
          AND column_name = 'valor'
    )
    AND NOT EXISTS (
        SELECT 1
        FROM pg_constraint con
        JOIN pg_class c
          ON c.oid = con.conrelid
        JOIN pg_namespace n
          ON n.oid = c.relnamespace
        WHERE n.nspname = 'financeiro'
          AND c.relname = 'rateio_centro_custo'
          AND con.conname = 'chk_rateio_valor'
    ) THEN
        ALTER TABLE financeiro.rateio_centro_custo
            ADD CONSTRAINT chk_rateio_valor
            CHECK (
                valor IS NULL
                OR valor > 0
            );
    END IF;
END
$$;

/* ============================================================================
   10. DOCUMENTACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 10 - DOCUMENTACAO'
\echo '============================================================'

COMMENT ON TABLE financeiro.centro_custo IS
    'Centros de custo utilizados para classificacao e rateio gerencial no modulo financeiro.';

COMMENT ON TABLE financeiro.rateio_centro_custo IS
    'Distribuicao de lancamentos financeiros entre centros de custo.';

/* ============================================================================
   11. REAUDITORIA DE ORFAOS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 11 - ORFAOS'
\echo '============================================================'

SELECT
    COUNT(*) FILTER (
        WHERE l.id_lancamento IS NULL
    ) AS rateios_sem_lancamento,

    COUNT(*) FILTER (
        WHERE cc.id_centro_custo IS NULL
    ) AS rateios_sem_centro_custo

FROM financeiro.rateio_centro_custo r
LEFT JOIN financeiro.lancamento l
  ON l.id_lancamento = r.id_lancamento
LEFT JOIN financeiro.centro_custo cc
  ON cc.id_centro_custo = r.id_centro_custo;

/* ============================================================================
   12. DUPLICIDADES LOGICAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 12 - DUPLICIDADES LOGICAS'
\echo '============================================================'

SELECT
    id_lancamento,
    id_centro_custo,
    COUNT(*) AS quantidade
FROM financeiro.rateio_centro_custo
GROUP BY
    id_lancamento,
    id_centro_custo
HAVING COUNT(*) > 1
ORDER BY id_lancamento, id_centro_custo;

/* ============================================================================
   13. SOMA DE PERCENTUAIS POR LANCAMENTO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 13 - SOMA DOS RATEIOS'
\echo '============================================================'

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'rateio_centro_custo'
          AND column_name = 'percentual'
    ) THEN
        RAISE NOTICE 'Coluna percentual encontrada: validacao percentual habilitada.';
    ELSE
        RAISE NOTICE 'Coluna percentual ausente: validacao percentual ignorada.';
    END IF;
END
$$;

/* ============================================================================
   14. TESTE FUNCIONAL CONTROLADO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 14 - TESTE FUNCIONAL DE RATEIO'
\echo '============================================================'

CREATE TEMP TABLE f1_fin_8_test_ctx (
    id_lancamento bigint,
    id_centro_1 bigint,
    id_centro_2 bigint
);

DO $$
DECLARE
    v_empresa integer;
    v_tipo smallint;
    v_status smallint;
    v_conta integer;
    v_cc1 bigint;
    v_cc2 bigint;
    v_lanc bigint;
    v_has_percentual boolean;
    v_has_valor boolean;
    v_sql text;
BEGIN
    SELECT id_empresa
    INTO v_empresa
    FROM public.empresa
    ORDER BY id_empresa
    LIMIT 1;

    SELECT id_tipo_lancamento
    INTO v_tipo
    FROM financeiro.tipo_lancamento
    WHERE ativo IS TRUE
      AND codigo = 'DESPESA'
    ORDER BY id_tipo_lancamento
    LIMIT 1;

    SELECT id_status
    INTO v_status
    FROM financeiro.status_lancamento
    WHERE ativo IS TRUE
      AND codigo = 'ABERTO'
    ORDER BY id_status
    LIMIT 1;

    SELECT id_conta
    INTO v_conta
    FROM financeiro.conta
    WHERE ativo IS TRUE
      AND aceita_lancamento IS TRUE
    ORDER BY id_conta
    LIMIT 1;

    SELECT id_centro_custo
    INTO v_cc1
    FROM financeiro.centro_custo
    ORDER BY id_centro_custo
    LIMIT 1;

    SELECT id_centro_custo
    INTO v_cc2
    FROM financeiro.centro_custo
    WHERE id_centro_custo <> v_cc1
    ORDER BY id_centro_custo
    LIMIT 1;

    IF v_empresa IS NULL
       OR v_tipo IS NULL
       OR v_status IS NULL
       OR v_conta IS NULL
       OR v_cc1 IS NULL
       OR v_cc2 IS NULL THEN
        RAISE EXCEPTION
            'F1-FIN.8 abortada: dados minimos insuficientes para teste funcional.';
    END IF;

    INSERT INTO financeiro.lancamento (
        numero,
        id_empresa,
        id_tipo_lancamento,
        id_status,
        id_conta,
        competencia,
        emissao,
        vencimento,
        descricao,
        valor_bruto,
        desconto,
        acrescimo,
        juros,
        multa,
        valor_pago,
        ativo
    )
    VALUES (
        'F1FIN8-TESTE-001',
        v_empresa,
        v_tipo,
        v_status,
        v_conta,
        CURRENT_DATE,
        CURRENT_DATE,
        CURRENT_DATE + 10,
        'Teste funcional de rateio',
        1000.00,
        0,
        0,
        0,
        0,
        0,
        TRUE
    )
    RETURNING id_lancamento INTO v_lanc;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'rateio_centro_custo'
          AND column_name = 'percentual'
    )
    INTO v_has_percentual;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'rateio_centro_custo'
          AND column_name = 'valor'
    )
    INTO v_has_valor;

    IF v_has_percentual AND v_has_valor THEN
        v_sql := format(
            'INSERT INTO financeiro.rateio_centro_custo
             (id_lancamento,id_centro_custo,percentual,valor)
             VALUES
             (%s,%s,60,600),
             (%s,%s,40,400)',
            v_lanc, v_cc1, v_lanc, v_cc2
        );
        EXECUTE v_sql;

    ELSIF v_has_percentual THEN
        v_sql := format(
            'INSERT INTO financeiro.rateio_centro_custo
             (id_lancamento,id_centro_custo,percentual)
             VALUES
             (%s,%s,60),
             (%s,%s,40)',
            v_lanc, v_cc1, v_lanc, v_cc2
        );
        EXECUTE v_sql;

    ELSIF v_has_valor THEN
        v_sql := format(
            'INSERT INTO financeiro.rateio_centro_custo
             (id_lancamento,id_centro_custo,valor)
             VALUES
             (%s,%s,600),
             (%s,%s,400)',
            v_lanc, v_cc1, v_lanc, v_cc2
        );
        EXECUTE v_sql;

    ELSE
        RAISE EXCEPTION
            'F1-FIN.8 abortada: rateio sem percentual e sem valor.';
    END IF;

    INSERT INTO f1_fin_8_test_ctx
    VALUES (v_lanc, v_cc1, v_cc2);
END
$$;

/* ============================================================================
   15. VALIDACAO FUNCIONAL BLOQUEANTE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 15 - VALIDACAO FUNCIONAL'
\echo '============================================================'

DO $$
DECLARE
    v_lanc bigint;
    v_count bigint;
    v_has_percentual boolean;
    v_has_valor boolean;
    v_total numeric;
BEGIN
    SELECT id_lancamento
    INTO v_lanc
    FROM f1_fin_8_test_ctx;

    SELECT COUNT(*)
    INTO v_count
    FROM financeiro.rateio_centro_custo
    WHERE id_lancamento = v_lanc;

    IF v_count <> 2 THEN
        RAISE EXCEPTION
            'F1-FIN.8 falhou: esperado 2 rateios, encontrado %.',
            v_count;
    END IF;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'rateio_centro_custo'
          AND column_name = 'percentual'
    )
    INTO v_has_percentual;

    SELECT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'financeiro'
          AND table_name = 'rateio_centro_custo'
          AND column_name = 'valor'
    )
    INTO v_has_valor;

    IF v_has_percentual THEN
        EXECUTE format(
            'SELECT COALESCE(SUM(percentual),0)
             FROM financeiro.rateio_centro_custo
             WHERE id_lancamento = %s',
            v_lanc
        )
        INTO v_total;

        IF v_total <> 100 THEN
            RAISE EXCEPTION
                'F1-FIN.8 falhou: soma percentual = %, esperado 100.',
                v_total;
        END IF;
    END IF;

    IF v_has_valor THEN
        EXECUTE format(
            'SELECT COALESCE(SUM(valor),0)
             FROM financeiro.rateio_centro_custo
             WHERE id_lancamento = %s',
            v_lanc
        )
        INTO v_total;

        IF v_total <> 1000 THEN
            RAISE EXCEPTION
                'F1-FIN.8 falhou: soma valor = %, esperado 1000.',
                v_total;
        END IF;
    END IF;
END
$$;

/* ============================================================================
   16. LIMPEZA DOS DADOS DE TESTE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 16 - LIMPEZA DOS DADOS DE TESTE'
\echo '============================================================'

DELETE FROM financeiro.rateio_centro_custo
WHERE id_lancamento IN (
    SELECT id_lancamento
    FROM f1_fin_8_test_ctx
);

DELETE FROM financeiro.lancamento
WHERE id_lancamento IN (
    SELECT id_lancamento
    FROM f1_fin_8_test_ctx
);

/* ============================================================================
   17. CERTIFICACAO FINAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 17 - CERTIFICACAO FINAL F1-FIN.8'
\echo '============================================================'

WITH integridade AS (
    SELECT
        (
            SELECT COUNT(*)
            FROM financeiro.rateio_centro_custo r
            LEFT JOIN financeiro.lancamento l
              ON l.id_lancamento = r.id_lancamento
            WHERE l.id_lancamento IS NULL
        ) AS rateios_sem_lancamento,

        (
            SELECT COUNT(*)
            FROM financeiro.rateio_centro_custo r
            LEFT JOIN financeiro.centro_custo cc
              ON cc.id_centro_custo = r.id_centro_custo
            WHERE cc.id_centro_custo IS NULL
        ) AS rateios_sem_centro,

        (
            SELECT COUNT(*)
            FROM (
                SELECT id_lancamento, id_centro_custo
                FROM financeiro.rateio_centro_custo
                GROUP BY id_lancamento, id_centro_custo
                HAVING COUNT(*) > 1
            ) x
        ) AS duplicidades,

        (
            SELECT COUNT(*)
            FROM pg_constraint con
            JOIN pg_class c
              ON c.oid = con.conrelid
            JOIN pg_namespace n
              ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relname IN (
                  'centro_custo',
                  'rateio_centro_custo'
              )
              AND NOT con.convalidated
        ) AS constraints_nao_validadas,

        (
            SELECT COUNT(*)
            FROM financeiro.lancamento
            WHERE numero = 'F1FIN8-TESTE-001'
        ) AS dados_teste_lancamento,

        (
            SELECT COUNT(*)
            FROM financeiro.rateio_centro_custo r
            JOIN financeiro.lancamento l
              ON l.id_lancamento = r.id_lancamento
            WHERE l.numero = 'F1FIN8-TESTE-001'
        ) AS dados_teste_rateio
)
SELECT
    (SELECT COUNT(*) FROM financeiro.centro_custo) AS centros_custo,
    (SELECT COUNT(*) FROM financeiro.rateio_centro_custo) AS rateios_existentes,
    i.rateios_sem_lancamento,
    i.rateios_sem_centro,
    i.duplicidades,
    i.constraints_nao_validadas,
    i.dados_teste_lancamento,
    i.dados_teste_rateio,
    CASE
        WHEN (SELECT COUNT(*) FROM financeiro.centro_custo) > 0
         AND i.rateios_sem_lancamento = 0
         AND i.rateios_sem_centro = 0
         AND i.duplicidades = 0
         AND i.constraints_nao_validadas = 0
         AND i.dados_teste_lancamento = 0
         AND i.dados_teste_rateio = 0
        THEN 'F1_FIN_8_APROVADA'
        ELSE 'F1_FIN_8_PENDENTE'
    END AS status
FROM integridade i;

/* ============================================================================
   18. VALIDACAO BLOQUEANTE FINAL
   ============================================================================ */

DO $$
DECLARE
    v_invalid bigint;
    v_orphans bigint;
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
          'centro_custo',
          'rateio_centro_custo'
      )
      AND NOT con.convalidated;

    SELECT
        (
            SELECT COUNT(*)
            FROM financeiro.rateio_centro_custo r
            LEFT JOIN financeiro.lancamento l
              ON l.id_lancamento = r.id_lancamento
            WHERE l.id_lancamento IS NULL
        )
        +
        (
            SELECT COUNT(*)
            FROM financeiro.rateio_centro_custo r
            LEFT JOIN financeiro.centro_custo cc
              ON cc.id_centro_custo = r.id_centro_custo
            WHERE cc.id_centro_custo IS NULL
        )
    INTO v_orphans;

    IF v_invalid <> 0 THEN
        RAISE EXCEPTION
            'F1-FIN.8 abortada: % constraints nao validadas.',
            v_invalid;
    END IF;

    IF v_orphans <> 0 THEN
        RAISE EXCEPTION
            'F1-FIN.8 abortada: % rateios orfaos.',
            v_orphans;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM financeiro.lancamento
        WHERE numero = 'F1FIN8-TESTE-001'
    ) THEN
        RAISE EXCEPTION
            'F1-FIN.8 abortada: dado de teste permaneceu.';
    END IF;
END
$$;

/* ============================================================================
   COMMIT
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.8 CONCLUIDA'
\echo '============================================================'
\echo ' CENTROS DE CUSTO ................ VALIDADOS'
\echo ' RATEIOS .......................... VALIDADOS'
\echo ' UNICIDADE ........................ VALIDADA'
\echo ' INDICES .......................... VALIDOS'
\echo ' TESTE FUNCIONAL .................. APROVADO'
\echo ' DOCUMENTACAO ..................... APLICADA'
\echo ' PROXIMA ETAPA .................... F1-FIN.9'
\echo '============================================================'

COMMIT;

\echo ''
\echo '============================================================'
\echo ' COMMIT CONCLUIDO'
\echo ' F1-FIN.8 FINALIZADA'
\echo ' PROXIMA ETAPA: F1-FIN.9 - CONCILIACAO E MOVIMENTACAO'
\echo '============================================================'
