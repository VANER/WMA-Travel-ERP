/*
 * WMA Travel ERP — validação estrutural da auditoria
 *
 * Execução somente leitura. Falha com SQLSTATE P0001 quando encontra uma
 * não conformidade bloqueante. Pode ser executado repetidamente.
 */

\set ON_ERROR_STOP on
\pset pager off
\pset null '(NULL)'

BEGIN;
SET TRANSACTION READ ONLY;
SET client_encoding = 'UTF8';

\echo '=== Validação estrutural da auditoria ==='

SELECT
    current_database() AS banco,
    current_user AS usuario,
    current_setting('server_version') AS postgresql,
    CURRENT_TIMESTAMP AS validado_em;

\echo '--- Funções obrigatórias ---'

SELECT
    p.oid::regprocedure AS funcao
FROM pg_proc p
JOIN pg_namespace n
  ON n.oid = p.pronamespace
WHERE p.proname IN ('fn_atualiza_updated_at', 'fn_log_auditoria')
ORDER BY 1;

\echo '--- Triggers de usuário por schema ---'

SELECT
    n.nspname AS schema_name,
    COUNT(*) AS triggers,
    COUNT(*) FILTER (WHERE t.tgenabled = 'D') AS desabilitados
FROM pg_trigger t
JOIN pg_class c
  ON c.oid = t.tgrelid
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE NOT t.tgisinternal
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
GROUP BY n.nspname
ORDER BY n.nspname;

\echo '--- Constraints não validadas ---'

SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    con.conname AS constraint_name,
    con.contype AS constraint_type
FROM pg_constraint con
JOIN pg_class c
  ON c.oid = con.conrelid
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE NOT con.convalidated
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
ORDER BY n.nspname, c.relname, con.conname;

\echo '--- Tabelas sem chave primária ---'

SELECT
    n.nspname AS schema_name,
    c.relname AS table_name
FROM pg_class c
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE c.relkind IN ('r', 'p')
  AND n.nspname NOT IN ('pg_catalog', 'information_schema')
  AND n.nspname !~ '^pg_toast'
  AND NOT (n.nspname = 'public' AND c.relname = 'v_total')
  AND NOT EXISTS (
      SELECT 1
      FROM pg_constraint con
      WHERE con.conrelid = c.oid
        AND con.contype = 'p'
  )
ORDER BY n.nspname, c.relname;

DO $$
DECLARE
    v_funcoes_ausentes integer;
    v_triggers_desabilitados integer;
    v_constraints_invalidas integer;
    v_tabelas_sem_pk integer;
BEGIN
    SELECT 2 - COUNT(DISTINCT p.proname)
      INTO v_funcoes_ausentes
      FROM pg_proc p
      JOIN pg_namespace n
        ON n.oid = p.pronamespace
     WHERE p.proname IN ('fn_atualiza_updated_at', 'fn_log_auditoria');

    SELECT COUNT(*)
      INTO v_triggers_desabilitados
      FROM pg_trigger t
      JOIN pg_class c
        ON c.oid = t.tgrelid
      JOIN pg_namespace n
        ON n.oid = c.relnamespace
     WHERE NOT t.tgisinternal
       AND t.tgenabled = 'D'
       AND n.nspname NOT IN ('pg_catalog', 'information_schema');

    SELECT COUNT(*)
      INTO v_constraints_invalidas
      FROM pg_constraint con
      JOIN pg_class c
        ON c.oid = con.conrelid
      JOIN pg_namespace n
        ON n.oid = c.relnamespace
     WHERE NOT con.convalidated
       AND n.nspname NOT IN ('pg_catalog', 'information_schema');

    SELECT COUNT(*)
      INTO v_tabelas_sem_pk
      FROM pg_class c
      JOIN pg_namespace n
        ON n.oid = c.relnamespace
     WHERE c.relkind IN ('r', 'p')
       AND n.nspname NOT IN ('pg_catalog', 'information_schema')
       AND n.nspname !~ '^pg_toast'
       AND NOT (n.nspname = 'public' AND c.relname = 'v_total')
       AND NOT EXISTS (
           SELECT 1
           FROM pg_constraint con
           WHERE con.conrelid = c.oid
             AND con.contype = 'p'
       );

    IF v_funcoes_ausentes <> 0
       OR v_triggers_desabilitados <> 0
       OR v_constraints_invalidas <> 0
       OR v_tabelas_sem_pk <> 0 THEN
        RAISE EXCEPTION
            'Validação reprovada: funções ausentes=%, triggers desabilitados=%, constraints inválidas=%, tabelas sem PK=%',
            v_funcoes_ausentes,
            v_triggers_desabilitados,
            v_constraints_invalidas,
            v_tabelas_sem_pk;
    END IF;
END
$$;

ROLLBACK;

\echo 'VALIDAÇÃO ESTRUTURAL DA AUDITORIA: APROVADA'
