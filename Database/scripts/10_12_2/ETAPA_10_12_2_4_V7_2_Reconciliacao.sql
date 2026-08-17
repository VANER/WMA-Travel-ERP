-- =============================================================================
-- WMA TRAVEL ERP
-- ETAPA 10.12.2.4  V7.2
-- RECONCILIAO QUANTITATIVA E ESTRUTURAL
-- PostgreSQL 18.x
-- Banco-alvo: wma_travel_rebuild_test
--
-- Objetivo:
--   Reconciliar a estrutura reconstruda contra o universo estrutural
--   certificado anteriormente.
--
-- Baseline quantitativo:
--   Schemas       : 8
--   Tabelas       : 209
--   Views         : 38
--   Sequences     : 206
--   ndices       : 357
--   Constraints   : 1176
--   Functions     : 64
--   Procedures    : 11
--   Triggers      : 138
--
-- V7.2 não altera o banco.
-- MODO: SOMENTE LEITURA
-- =============================================================================

\set ON_ERROR_STOP on

\echo ''
\echo '============================================================'
\echo 'ETAPA 10.12.2.4  V7.2'
\echo 'RECONCILIACAO QUANTITATIVA E ESTRUTURAL'
\echo '============================================================'

SELECT
    'CONTEXTO' AS secao,
    current_database() AS banco,
    current_user AS usuario,
    version() AS versao;

-- ============================================================================
-- 1. SCHEMAS
-- ============================================================================

\echo ''
\echo '--- 1. SCHEMAS ---'

WITH esperado AS (
    SELECT 8::bigint AS quantidade
),
atual AS (
    SELECT count(*)::bigint AS quantidade
    FROM pg_namespace
    WHERE nspname NOT IN ('pg_catalog','information_schema')
      AND nspname NOT LIKE 'pg_%'
)
SELECT
    'SCHEMAS' AS objeto,
    esperado.quantidade AS esperado,
    atual.quantidade AS atual,
    CASE
        WHEN esperado.quantidade = atual.quantidade THEN 'OK'
        ELSE 'DIVERGENCIA'
    END AS status
FROM esperado, atual;

-- ============================================================================
-- 2. TABELAS
-- ============================================================================

\echo ''
\echo '--- 2. TABELAS ---'

WITH esperado AS (
    SELECT 209::bigint AS quantidade
),
atual AS (
    SELECT count(*)::bigint AS quantidade
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'r'
      AND n.nspname NOT IN ('pg_catalog','information_schema')
      AND n.nspname NOT LIKE 'pg_%'
)
SELECT
    'TABLES' AS objeto,
    esperado.quantidade AS esperado,
    atual.quantidade AS atual,
    CASE
        WHEN esperado.quantidade = atual.quantidade THEN 'OK'
        ELSE 'DIVERGENCIA'
    END AS status
FROM esperado, atual;

-- ============================================================================
-- 3. VIEWS
-- ============================================================================

\echo ''
\echo '--- 3. VIEWS ---'

WITH esperado AS (
    SELECT 38::bigint AS quantidade
),
atual AS (
    SELECT count(*)::bigint AS quantidade
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'v'
      AND n.nspname NOT IN ('pg_catalog','information_schema')
      AND n.nspname NOT LIKE 'pg_%'
)
SELECT
    'VIEWS' AS objeto,
    esperado.quantidade AS esperado,
    atual.quantidade AS atual,
    CASE
        WHEN esperado.quantidade = atual.quantidade THEN 'OK'
        ELSE 'DIVERGENCIA'
    END AS status
FROM esperado, atual;

-- ============================================================================
-- 4. SEQUENCES
-- ============================================================================

\echo ''
\echo '--- 4. SEQUENCES ---'

WITH esperado AS (
    SELECT 206::bigint AS quantidade
),
atual AS (
    SELECT count(*)::bigint AS quantidade
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'S'
      AND n.nspname NOT IN ('pg_catalog','information_schema')
      AND n.nspname NOT LIKE 'pg_%'
)
SELECT
    'SEQUENCES' AS objeto,
    esperado.quantidade AS esperado,
    atual.quantidade AS atual,
    CASE
        WHEN esperado.quantidade = atual.quantidade THEN 'OK'
        ELSE 'DIVERGENCIA'
    END AS status
FROM esperado, atual;

-- ============================================================================
-- 5. NDICES
-- ============================================================================

\echo ''
\echo '--- 5. INDICES ---'

WITH esperado AS (
    SELECT 357::bigint AS quantidade
),
atual AS (
    SELECT count(*)::bigint AS quantidade
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE c.relkind = 'i'
      AND n.nspname NOT IN ('pg_catalog','information_schema')
      AND n.nspname NOT LIKE 'pg_%'
)
SELECT
    'INDEXES' AS objeto,
    esperado.quantidade AS esperado,
    atual.quantidade AS atual,
    CASE
        WHEN esperado.quantidade = atual.quantidade THEN 'OK'
        ELSE 'DIVERGENCIA'
    END AS status
FROM esperado, atual;

-- ============================================================================
-- 6. CONSTRAINTS
-- ============================================================================

\echo ''
\echo '--- 6. CONSTRAINTS ---'

WITH esperado AS (
    SELECT 1176::bigint AS quantidade
),
atual AS (
    SELECT count(*)::bigint AS quantidade
    FROM pg_constraint con
    JOIN pg_namespace n ON n.oid = con.connamespace
    WHERE n.nspname NOT IN ('pg_catalog','information_schema')
      AND n.nspname NOT LIKE 'pg_%'
)
SELECT
    'CONSTRAINTS' AS objeto,
    esperado.quantidade AS esperado,
    atual.quantidade AS atual,
    CASE
        WHEN esperado.quantidade = atual.quantidade THEN 'OK'
        ELSE 'DIVERGENCIA'
    END AS status
FROM esperado, atual;

-- ============================================================================
-- 7. FUNCTIONS
-- ============================================================================

\echo ''
\echo '--- 7. FUNCTIONS ---'

WITH esperado AS (
    SELECT 64::bigint AS quantidade
),
atual AS (
    SELECT count(*)::bigint AS quantidade
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.prokind = 'f'
      AND n.nspname NOT IN ('pg_catalog','information_schema')
      AND n.nspname NOT LIKE 'pg_%'
)
SELECT
    'FUNCTIONS' AS objeto,
    esperado.quantidade AS esperado,
    atual.quantidade AS atual,
    CASE
        WHEN esperado.quantidade = atual.quantidade THEN 'OK'
        ELSE 'DIVERGENCIA'
    END AS status
FROM esperado, atual;

-- ============================================================================
-- 8. PROCEDURES
-- ============================================================================

\echo ''
\echo '--- 8. PROCEDURES ---'

WITH esperado AS (
    SELECT 11::bigint AS quantidade
),
atual AS (
    SELECT count(*)::bigint AS quantidade
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.prokind = 'p'
      AND n.nspname NOT IN ('pg_catalog','information_schema')
      AND n.nspname NOT LIKE 'pg_%'
)
SELECT
    'PROCEDURES' AS objeto,
    esperado.quantidade AS esperado,
    atual.quantidade AS atual,
    CASE
        WHEN esperado.quantidade = atual.quantidade THEN 'OK'
        ELSE 'DIVERGENCIA'
    END AS status
FROM esperado, atual;

-- ============================================================================
-- 9. TRIGGERS
-- ============================================================================

\echo ''
\echo '--- 9. TRIGGERS ---'

WITH esperado AS (
    SELECT 138::bigint AS quantidade
),
atual AS (
    SELECT count(*)::bigint AS quantidade
    FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE NOT t.tgisinternal
      AND n.nspname NOT IN ('pg_catalog','information_schema')
      AND n.nspname NOT LIKE 'pg_%'
)
SELECT
    'TRIGGERS' AS objeto,
    esperado.quantidade AS esperado,
    atual.quantidade AS atual,
    CASE
        WHEN esperado.quantidade = atual.quantidade THEN 'OK'
        ELSE 'DIVERGENCIA'
    END AS status
FROM esperado, atual;

-- ============================================================================
-- 10. DISTRIBUIO DE CONSTRAINTS
-- ============================================================================

\echo ''
\echo '--- 10. DISTRIBUICAO DE CONSTRAINTS ---'

SELECT
    CASE contype
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'u' THEN 'UNIQUE'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'c' THEN 'CHECK'
        WHEN 'n' THEN 'NOT NULL'
        WHEN 'x' THEN 'EXCLUSION'
        ELSE contype::text
    END AS tipo,
    count(*) AS quantidade
FROM pg_constraint con
JOIN pg_namespace n ON n.oid = con.connamespace
WHERE n.nspname NOT IN ('pg_catalog','information_schema')
  AND n.nspname NOT LIKE 'pg_%'
GROUP BY contype
ORDER BY contype;

-- ============================================================================
-- 11. FKs NO VALIDADAS
-- ============================================================================

\echo ''
\echo '--- 11. FKs NAO VALIDADAS ---'

SELECT
    conrelid::regclass AS tabela,
    conname AS constraint_name,
    confrelid::regclass AS tabela_referenciada
FROM pg_constraint
WHERE contype = 'f'
  AND NOT convalidated
ORDER BY 1,2;

-- ============================================================================
-- 12. CONSTRAINTS COM NOMES DUPLICADOS NO MESMO SCHEMA
-- ============================================================================

\echo ''
\echo '--- 12. NOMES DE CONSTRAINTS DUPLICADOS ---'

SELECT
    n.nspname AS schema,
    con.conname AS constraint_name,
    count(*) AS ocorrencias
FROM pg_constraint con
JOIN pg_namespace n ON n.oid = con.connamespace
WHERE n.nspname NOT IN ('pg_catalog','information_schema')
  AND n.nspname NOT LIKE 'pg_%'
GROUP BY n.nspname, con.conname
HAVING count(*) > 1
ORDER BY n.nspname, con.conname;

-- ============================================================================
-- 13. TRIGGERS POR SCHEMA
-- ============================================================================

\echo ''
\echo '--- 13. TRIGGERS POR SCHEMA ---'

SELECT
    n.nspname AS schema,
    count(*) AS triggers
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE NOT t.tgisinternal
  AND n.nspname NOT IN ('pg_catalog','information_schema')
  AND n.nspname NOT LIKE 'pg_%'
GROUP BY n.nspname
ORDER BY n.nspname;

-- ============================================================================
-- 14. VIEWS POR SCHEMA
-- ============================================================================

\echo ''
\echo '--- 14. VIEWS POR SCHEMA ---'

SELECT
    n.nspname AS schema,
    count(*) AS views
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'v'
  AND n.nspname NOT IN ('pg_catalog','information_schema')
  AND n.nspname NOT LIKE 'pg_%'
GROUP BY n.nspname
ORDER BY n.nspname;

-- ============================================================================
-- 15. SEQUENCES POR SCHEMA
-- ============================================================================

\echo ''
\echo '--- 15. SEQUENCES POR SCHEMA ---'

SELECT
    n.nspname AS schema,
    count(*) AS sequences
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE c.relkind = 'S'
  AND n.nspname NOT IN ('pg_catalog','information_schema')
  AND n.nspname NOT LIKE 'pg_%'
GROUP BY n.nspname
ORDER BY n.nspname;

-- ============================================================================
-- 16. RESUMO FINAL AUTOMTICO
-- ============================================================================

\echo ''
\echo '============================================================'
\echo 'RESUMO FINAL V7.2'
\echo '============================================================'

WITH
dados AS (
    SELECT
        (
            SELECT count(*)
            FROM pg_namespace
            WHERE nspname NOT IN ('pg_catalog','information_schema')
              AND nspname NOT LIKE 'pg_%'
        ) AS schemas,

        (
            SELECT count(*)
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relkind = 'r'
              AND n.nspname NOT IN ('pg_catalog','information_schema')
              AND n.nspname NOT LIKE 'pg_%'
        ) AS tabelas,

        (
            SELECT count(*)
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relkind = 'v'
              AND n.nspname NOT IN ('pg_catalog','information_schema')
              AND n.nspname NOT LIKE 'pg_%'
        ) AS views,

        (
            SELECT count(*)
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relkind = 'S'
              AND n.nspname NOT IN ('pg_catalog','information_schema')
              AND n.nspname NOT LIKE 'pg_%'
        ) AS sequences,

        (
            SELECT count(*)
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relkind = 'i'
              AND n.nspname NOT IN ('pg_catalog','information_schema')
              AND n.nspname NOT LIKE 'pg_%'
        ) AS indices,

        (
            SELECT count(*)
            FROM pg_constraint con
            JOIN pg_namespace n ON n.oid = con.connamespace
            WHERE n.nspname NOT IN ('pg_catalog','information_schema')
              AND n.nspname NOT LIKE 'pg_%'
        ) AS constraints,

        (
            SELECT count(*)
            FROM pg_proc p
            JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE p.prokind = 'f'
              AND n.nspname NOT IN ('pg_catalog','information_schema')
              AND n.nspname NOT LIKE 'pg_%'
        ) AS functions,

        (
            SELECT count(*)
            FROM pg_proc p
            JOIN pg_namespace n ON n.oid = p.pronamespace
            WHERE p.prokind = 'p'
              AND n.nspname NOT IN ('pg_catalog','information_schema')
              AND n.nspname NOT LIKE 'pg_%'
        ) AS procedures,

        (
            SELECT count(*)
            FROM pg_trigger t
            JOIN pg_class c ON c.oid = t.tgrelid
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE NOT t.tgisinternal
              AND n.nspname NOT IN ('pg_catalog','information_schema')
              AND n.nspname NOT LIKE 'pg_%'
        ) AS triggers
)
SELECT *
FROM dados;

\echo ''
\echo '============================================================'
\echo 'ETAPA 10.12.2.4  V7.2  FIM'
\echo 'MODO: SOMENTE LEITURA'
\echo '============================================================'
