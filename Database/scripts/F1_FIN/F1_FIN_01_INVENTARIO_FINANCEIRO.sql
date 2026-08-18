/* ============================================================================
   WMA TRAVEL ERP
   F1-FIN MASTER V1 — AUDITORIA ESTRUTURAL COMPLETA DO FINANCEIRO
   ETAPAS: F1-FIN.1 -> F1-FIN.13

   PostgreSQL : 18.x
   Banco      : wma_travel
   Modo       : SOMENTE LEITURA / DIAGNOSTICO
   Segurança  : TRANSACTION READ ONLY

   OBJETIVO
   --------
   Executar em uma única rotina:

   F1-FIN.1  Inventário completo do Financeiro
   F1-FIN.2  Mapa funcional tabela -> processo
   F1-FIN.3  Análise de lacunas estruturais
   F1-FIN.4  Diagnóstico de correções mínimas
   F1-FIN.5  Plano de Contas e classificações
   F1-FIN.6  AP/AR e parcelamentos
   F1-FIN.7  Caixa, bancos, cartões e transferências
   F1-FIN.8  Rateios e centros de custo
   F1-FIN.9  Conciliação e movimentação
   F1-FIN.10 Capital, AFAC, pró-labore e lucros
   F1-FIN.11 Tributos, empréstimos e imobilizado
   F1-FIN.12 Auditoria de integridade financeira
   F1-FIN.13 Certificação estrutural preliminar

   IMPORTANTE
   ----------
   Esta versão NÃO executa correções.
   Toda alteração estrutural será gerada somente após análise do resultado.
   ============================================================================ */

\set ON_ERROR_STOP on
\pset pager off
\pset null '(NULL)'
\timing on

BEGIN;
SET TRANSACTION READ ONLY;
SET client_encoding = 'UTF8';

\echo ''
\echo '============================================================'
\echo ' WMA TRAVEL ERP'
\echo ' F1-FIN MASTER V1 - AUDITORIA ESTRUTURAL DO FINANCEIRO'
\echo ' F1-FIN.1 -> F1-FIN.13'
\echo ' MODO: SOMENTE LEITURA'
\echo '============================================================'
\echo ''

/* ============================================================================
   F1-FIN.0 — IDENTIFICAÇÃO DO AMBIENTE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.0 - AMBIENTE'
\echo '============================================================'

SELECT
    current_database() AS banco,
    current_user AS usuario,
    current_schema() AS schema_atual,
    current_setting('server_version') AS postgresql,
    current_setting('server_encoding') AS server_encoding,
    current_setting('client_encoding') AS client_encoding,
    CURRENT_TIMESTAMP AS executado_em;

/* ============================================================================
   F1-FIN.1 — INVENTÁRIO COMPLETO DO FINANCEIRO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.1 - INVENTARIO COMPLETO DO FINANCEIRO'
\echo '============================================================'

/* --------------------------------------------------------------------------
   F1-FIN.1.1 — Schemas
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.1.1 - SCHEMAS ---'

SELECT
    n.nspname AS schema_name,
    pg_get_userbyid(n.nspowner) AS owner
FROM pg_namespace n
WHERE n.nspname NOT LIKE 'pg_%'
  AND n.nspname <> 'information_schema'
ORDER BY n.nspname;

/* --------------------------------------------------------------------------
   F1-FIN.1.2 — Tabelas do schema financeiro
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.1.2 - TABELAS FINANCEIRO ---'

SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    CASE c.relkind
        WHEN 'r' THEN 'TABLE'
        WHEN 'p' THEN 'PARTITIONED TABLE'
        ELSE c.relkind::text
    END AS object_type,
    pg_get_userbyid(c.relowner) AS owner,
    obj_description(c.oid, 'pg_class') AS comentario,
    c.reltuples::bigint AS estimated_rows
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relkind IN ('r', 'p')
ORDER BY c.relname;

/* --------------------------------------------------------------------------
   F1-FIN.1.3 — Colunas
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.1.3 - COLUNAS ---'

SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    a.attnum AS ordinal_position,
    a.attname AS column_name,
    pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
    a.attnotnull AS not_null,
    pg_get_expr(ad.adbin, ad.adrelid) AS default_value,
    col_description(c.oid, a.attnum) AS comentario
FROM pg_attribute a
JOIN pg_class c
    ON c.oid = a.attrelid
JOIN pg_namespace n
    ON n.oid = c.relnamespace
LEFT JOIN pg_attrdef ad
    ON ad.adrelid = c.oid
   AND ad.adnum = a.attnum
WHERE n.nspname = 'financeiro'
  AND c.relkind IN ('r', 'p')
  AND a.attnum > 0
  AND NOT a.attisdropped
ORDER BY
    c.relname,
    a.attnum;

/* --------------------------------------------------------------------------
   F1-FIN.1.4 — Constraints
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.1.4 - CONSTRAINTS ---'

SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    con.conname AS constraint_name,
    CASE con.contype
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'u' THEN 'UNIQUE'
        WHEN 'c' THEN 'CHECK'
        WHEN 'x' THEN 'EXCLUSION'
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
ORDER BY
    c.relname,
    constraint_type,
    con.conname;

/* --------------------------------------------------------------------------
   F1-FIN.1.5 — Foreign Keys internas e externas
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.1.5 - RELACIONAMENTOS FK ---'

SELECT
    sn.nspname AS source_schema,
    sc.relname AS source_table,
    con.conname AS fk_name,
    rn.nspname AS target_schema,
    rc.relname AS target_table,
    pg_get_constraintdef(con.oid, TRUE) AS definition,
    con.convalidated AS validated
FROM pg_constraint con
JOIN pg_class sc
    ON sc.oid = con.conrelid
JOIN pg_namespace sn
    ON sn.oid = sc.relnamespace
JOIN pg_class rc
    ON rc.oid = con.confrelid
JOIN pg_namespace rn
    ON rn.oid = rc.relnamespace
WHERE con.contype = 'f'
  AND (
        sn.nspname = 'financeiro'
        OR rn.nspname = 'financeiro'
      )
ORDER BY
    sn.nspname,
    sc.relname,
    con.conname;

/* --------------------------------------------------------------------------
   F1-FIN.1.6 — Índices
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.1.6 - INDICES ---'

SELECT
    schemaname AS schema_name,
    tablename AS table_name,
    indexname AS index_name,
    indexdef AS definition
FROM pg_indexes
WHERE schemaname = 'financeiro'
ORDER BY
    tablename,
    indexname;

/* --------------------------------------------------------------------------
   F1-FIN.1.7 — Sequences
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.1.7 - SEQUENCES ---'

SELECT
    n.nspname AS schema_name,
    c.relname AS sequence_name,
    pg_get_userbyid(c.relowner) AS owner,
    obj_description(c.oid, 'pg_class') AS comentario
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relkind = 'S'
ORDER BY c.relname;

/* --------------------------------------------------------------------------
   F1-FIN.1.8 — Views
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.1.8 - VIEWS ---'

SELECT
    schemaname AS schema_name,
    viewname AS view_name,
    viewowner AS owner
FROM pg_views
WHERE schemaname = 'financeiro'
ORDER BY viewname;

/* --------------------------------------------------------------------------
   F1-FIN.1.9 — Rotinas
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.1.9 - FUNCTIONS / PROCEDURES ---'

SELECT
    n.nspname AS schema_name,
    p.proname AS routine_name,
    CASE p.prokind
        WHEN 'f' THEN 'FUNCTION'
        WHEN 'p' THEN 'PROCEDURE'
        WHEN 'a' THEN 'AGGREGATE'
        WHEN 'w' THEN 'WINDOW'
        ELSE p.prokind::text
    END AS routine_type,
    pg_get_function_identity_arguments(p.oid) AS arguments,
    l.lanname AS language,
    obj_description(p.oid, 'pg_proc') AS comentario
FROM pg_proc p
JOIN pg_namespace n
    ON n.oid = p.pronamespace
JOIN pg_language l
    ON l.oid = p.prolang
WHERE n.nspname = 'financeiro'
ORDER BY
    routine_type,
    routine_name;

/* --------------------------------------------------------------------------
   F1-FIN.1.10 — Triggers
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.1.10 - TRIGGERS ---'

SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    t.tgname AS trigger_name,
    pg_get_triggerdef(t.oid, TRUE) AS definition,
    obj_description(t.oid, 'pg_trigger') AS comentario
FROM pg_trigger t
JOIN pg_class c
    ON c.oid = t.tgrelid
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND NOT t.tgisinternal
ORDER BY
    c.relname,
    t.tgname;

/* --------------------------------------------------------------------------
   F1-FIN.1.11 — Resumo
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.1.11 - RESUMO DO INVENTARIO ---'

SELECT 'TABLES' AS objeto, COUNT(*) AS quantidade
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relkind IN ('r', 'p')

UNION ALL

SELECT 'COLUMNS', COUNT(*)
FROM information_schema.columns
WHERE table_schema = 'financeiro'

UNION ALL

SELECT 'CONSTRAINTS', COUNT(*)
FROM pg_constraint con
JOIN pg_class c ON c.oid = con.conrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'

UNION ALL

SELECT 'INDEXES', COUNT(*)
FROM pg_indexes
WHERE schemaname = 'financeiro'

UNION ALL

SELECT 'SEQUENCES', COUNT(*)
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relkind = 'S'

UNION ALL

SELECT 'VIEWS', COUNT(*)
FROM pg_views
WHERE schemaname = 'financeiro'

UNION ALL

SELECT 'ROUTINES', COUNT(*)
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'financeiro'
  AND p.prokind IN ('f', 'p')

UNION ALL

SELECT 'TRIGGERS', COUNT(*)
FROM pg_trigger t
JOIN pg_class c ON c.oid = t.tgrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND NOT t.tgisinternal

ORDER BY objeto;

/* ============================================================================
   F1-FIN.2 — MAPA FUNCIONAL TABELA -> PROCESSO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.2 - MAPA FUNCIONAL TABELA -> PROCESSO'
\echo '============================================================'

WITH tabelas AS (
    SELECT
        c.relname AS table_name,
        obj_description(c.oid, 'pg_class') AS comentario
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relkind IN ('r', 'p')
)
SELECT
    table_name,
    CASE
        WHEN table_name ~* '(grupo_conta|categoria_conta|subcategoria_conta|plano_conta|conta_contabil)'
            THEN 'PLANO_DE_CONTAS'

        WHEN table_name ~* '(conta_pagar|titulo_pagar|pagamento|parcela_pagar)'
            THEN 'CONTAS_A_PAGAR'

        WHEN table_name ~* '(conta_receber|titulo_receber|recebimento|parcela_receber)'
            THEN 'CONTAS_A_RECEBER'

        WHEN table_name ~* '(conta_banc|banco|caixa|carteira)'
            THEN 'CAIXA_E_BANCOS'

        WHEN table_name ~* '(cartao|fatura|adquirente|bandeira)'
            THEN 'CARTOES'

        WHEN table_name ~* '(transfer)'
            THEN 'TRANSFERENCIAS'

        WHEN table_name ~* '(centro_custo)'
            THEN 'CENTRO_DE_CUSTO'

        WHEN table_name ~* '(rateio)'
            THEN 'RATEIOS'

        WHEN table_name ~* '(concili)'
            THEN 'CONCILIACAO'

        WHEN table_name ~* '(moviment|lancamento)'
            THEN 'MOVIMENTACAO_FINANCEIRA'

        WHEN table_name ~* '(aporte|afac|capital)'
            THEN 'CAPITAL_E_AFAC'

        WHEN table_name ~* '(pro.?labore)'
            THEN 'PRO_LABORE'

        WHEN table_name ~* '(lucro|distribuicao)'
            THEN 'LUCROS'

        WHEN table_name ~* '(tribut|imposto|guia)'
            THEN 'TRIBUTOS'

        WHEN table_name ~* '(emprest|financiamento)'
            THEN 'EMPRESTIMOS_E_FINANCIAMENTOS'

        WHEN table_name ~* '(imobilizado|depreciacao|ativo)'
            THEN 'ATIVO_IMOBILIZADO'

        WHEN table_name ~* '(forma_pagamento|meio_pagamento)'
            THEN 'FORMAS_DE_PAGAMENTO'

        ELSE 'REVISAR_CLASSIFICACAO'
    END AS processo_sugerido,
    comentario
FROM tabelas
ORDER BY
    processo_sugerido,
    table_name;

/* ============================================================================
   F1-FIN.3 — ANÁLISE DE LACUNAS ESTRUTURAIS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.3 - ANALISE DE LACUNAS ESTRUTURAIS'
\echo '============================================================'

/* Tabelas sem PK */

\echo ''
\echo '--- TABELAS SEM PRIMARY KEY ---'

SELECT
    n.nspname AS schema_name,
    c.relname AS table_name
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relkind IN ('r', 'p')
  AND NOT EXISTS (
        SELECT 1
        FROM pg_constraint con
        WHERE con.conrelid = c.oid
          AND con.contype = 'p'
  )
ORDER BY c.relname;

/* Tabelas sem comentário */

\echo ''
\echo '--- TABELAS SEM COMENTARIO ---'

SELECT
    n.nspname AS schema_name,
    c.relname AS table_name
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relkind IN ('r', 'p')
  AND obj_description(c.oid, 'pg_class') IS NULL
ORDER BY c.relname;

/* Colunas sem comentário */

\echo ''
\echo '--- COLUNAS SEM COMENTARIO ---'

SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    a.attname AS column_name
FROM pg_attribute a
JOIN pg_class c
    ON c.oid = a.attrelid
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relkind IN ('r', 'p')
  AND a.attnum > 0
  AND NOT a.attisdropped
  AND col_description(c.oid, a.attnum) IS NULL
ORDER BY
    c.relname,
    a.attnum;

/* Constraints não validadas */

\echo ''
\echo '--- CONSTRAINTS NAO VALIDADAS ---'

SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    con.conname AS constraint_name,
    con.contype
FROM pg_constraint con
JOIN pg_class c
    ON c.oid = con.conrelid
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND NOT con.convalidated
ORDER BY
    c.relname,
    con.conname;

/* Colunas monetárias usando tipos inadequados */

\echo ''
\echo '--- POSSIVEIS COLUNAS MONETARIAS COM TIPO INADEQUADO ---'

SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    udt_name
FROM information_schema.columns
WHERE table_schema = 'financeiro'
  AND column_name ~* '(valor|saldo|preco|custo|taxa|juros|multa|desconto|total)'
  AND data_type IN (
      'real',
      'double precision',
      'smallint',
      'integer',
      'bigint'
  )
ORDER BY
    table_name,
    column_name;

/* Tabelas potencialmente empresariais sem id_empresa */

\echo ''
\echo '--- TABELAS SEM ID_EMPRESA - REVISAR MULTIEMPRESA ---'

SELECT
    t.table_name
FROM information_schema.tables t
WHERE t.table_schema = 'financeiro'
  AND t.table_type = 'BASE TABLE'
  AND NOT EXISTS (
      SELECT 1
      FROM information_schema.columns c
      WHERE c.table_schema = t.table_schema
        AND c.table_name = t.table_name
        AND c.column_name = 'id_empresa'
  )
ORDER BY t.table_name;

/* ============================================================================
   F1-FIN.4 — CORREÇÕES MÍNIMAS NECESSÁRIAS — DIAGNÓSTICO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.4 - CORRECOES MINIMAS NECESSARIAS'
\echo ' MODO V1: DIAGNOSTICO - NENHUMA CORRECAO SERA EXECUTADA'
\echo '============================================================'

WITH problemas AS (
    SELECT
        'SEM_PK'::text AS tipo,
        c.relname AS objeto
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relkind IN ('r', 'p')
      AND NOT EXISTS (
          SELECT 1
          FROM pg_constraint con
          WHERE con.conrelid = c.oid
            AND con.contype = 'p'
      )

    UNION ALL

    SELECT
        'SEM_COMENTARIO_TABELA',
        c.relname
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relkind IN ('r', 'p')
      AND obj_description(c.oid, 'pg_class') IS NULL

    UNION ALL

    SELECT
        'CONSTRAINT_NAO_VALIDADA',
        c.relname || '.' || con.conname
    FROM pg_constraint con
    JOIN pg_class c
        ON c.oid = con.conrelid
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND NOT con.convalidated
)
SELECT
    tipo,
    COUNT(*) AS quantidade
FROM problemas
GROUP BY tipo
ORDER BY tipo;

/* ============================================================================
   FUNÇÃO AUXILIAR CONCEITUAL:
   As próximas etapas verificam presença estrutural através de nomes das
   tabelas existentes. Nenhuma ausência gera alteração nesta V1.
   ============================================================================ */

/* ============================================================================
   F1-FIN.5 — PLANO DE CONTAS E CLASSIFICAÇÕES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.5 - PLANO DE CONTAS E CLASSIFICACOES'
\echo '============================================================'

WITH conceitos(conceito, padrao) AS (
    VALUES
        ('GRUPO_CONTA', 'grupo_conta'),
        ('CATEGORIA_CONTA', 'categoria_conta'),
        ('SUBCATEGORIA_CONTA', 'subcategoria_conta'),
        ('PLANO_CONTA', '(plano.*conta|conta_contabil)'),
        ('CLASSIFICACAO_DRE', '(dre|classificacao.*dre)'),
        ('CLASSIFICACAO_FLUXO_CAIXA', '(fluxo.*caixa|classificacao.*caixa)')
)
SELECT
    conceito,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace n
                ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relkind IN ('r', 'p', 'v')
              AND c.relname ~* padrao
        )
        THEN 'ENCONTRADO'
        ELSE 'AUSENTE_OU_REVISAR'
    END AS status
FROM conceitos
ORDER BY conceito;

/* ============================================================================
   F1-FIN.6 — AP / AR E PARCELAMENTOS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.6 - AP/AR E PARCELAMENTOS'
\echo '============================================================'

WITH conceitos(conceito, padrao) AS (
    VALUES
        ('CONTAS_A_PAGAR', '(conta.*pagar|titulo.*pagar)'),
        ('PARCELAS_A_PAGAR', '(parcela.*pagar|conta.*pagar.*parcela)'),
        ('PAGAMENTOS', '(^pagamento|pagamento_)'),
        ('CONTAS_A_RECEBER', '(conta.*receber|titulo.*receber)'),
        ('PARCELAS_A_RECEBER', '(parcela.*receber|conta.*receber.*parcela)'),
        ('RECEBIMENTOS', '(^recebimento|recebimento_)')
)
SELECT
    conceito,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace n
                ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relkind IN ('r', 'p', 'v')
              AND c.relname ~* padrao
        )
        THEN 'ENCONTRADO'
        ELSE 'AUSENTE_OU_REVISAR'
    END AS status
FROM conceitos
ORDER BY conceito;

/* ============================================================================
   F1-FIN.7 — CAIXA, BANCOS, CARTÕES E TRANSFERÊNCIAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.7 - CAIXA, BANCOS, CARTOES E TRANSFERENCIAS'
\echo '============================================================'

WITH conceitos(conceito, padrao) AS (
    VALUES
        ('CONTA_BANCARIA', '(conta.*banc|conta_bancaria)'),
        ('BANCO', '(^banco$|banco_)'),
        ('CAIXA', '(^caixa$|caixa_)'),
        ('CARTAO', '(cartao)'),
        ('FATURA_CARTAO', '(fatura.*cartao|cartao.*fatura)'),
        ('TRANSFERENCIA', '(transfer)')
)
SELECT
    conceito,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace n
                ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relkind IN ('r', 'p', 'v')
              AND c.relname ~* padrao
        )
        THEN 'ENCONTRADO'
        ELSE 'AUSENTE_OU_REVISAR'
    END AS status
FROM conceitos
ORDER BY conceito;

/* ============================================================================
   F1-FIN.8 — RATEIOS E CENTROS DE CUSTO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.8 - RATEIOS E CENTROS DE CUSTO'
\echo '============================================================'

WITH conceitos(conceito, padrao) AS (
    VALUES
        ('CENTRO_CUSTO', '(centro.*custo)'),
        ('RATEIO', '(rateio)')
)
SELECT
    conceito,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace n
                ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relkind IN ('r', 'p', 'v')
              AND c.relname ~* padrao
        )
        THEN 'ENCONTRADO'
        ELSE 'AUSENTE_OU_REVISAR'
    END AS status
FROM conceitos
ORDER BY conceito;

/* ============================================================================
   F1-FIN.9 — CONCILIAÇÃO E MOVIMENTAÇÃO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.9 - CONCILIACAO E MOVIMENTACAO'
\echo '============================================================'

WITH conceitos(conceito, padrao) AS (
    VALUES
        ('MOVIMENTACAO_FINANCEIRA', '(moviment.*financ|movimentacao|lancamento.*financ)'),
        ('CONCILIACAO_BANCARIA', '(concili)'),
        ('EXTRATO_BANCARIO', '(extrato)')
)
SELECT
    conceito,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace n
                ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relkind IN ('r', 'p', 'v')
              AND c.relname ~* padrao
        )
        THEN 'ENCONTRADO'
        ELSE 'AUSENTE_OU_REVISAR'
    END AS status
FROM conceitos
ORDER BY conceito;

/* ============================================================================
   F1-FIN.10 — CAPITAL, AFAC, PRÓ-LABORE E LUCROS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.10 - CAPITAL, AFAC, PRO-LABORE E LUCROS'
\echo '============================================================'

WITH conceitos(conceito, padrao) AS (
    VALUES
        ('CAPITAL_SOCIAL', '(capital.*social|capital)'),
        ('APORTE_CAPITAL', '(aporte)'),
        ('AFAC', '(afac)'),
        ('PRO_LABORE', '(pro.?labore)'),
        ('DISTRIBUICAO_LUCROS', '(distribuicao.*lucro|lucro.*distribuicao)')
)
SELECT
    conceito,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace n
                ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relkind IN ('r', 'p', 'v')
              AND c.relname ~* padrao
        )
        THEN 'ENCONTRADO'
        ELSE 'AUSENTE_OU_REVISAR'
    END AS status
FROM conceitos
ORDER BY conceito;

/* ============================================================================
   F1-FIN.11 — TRIBUTOS, EMPRÉSTIMOS E IMOBILIZADO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.11 - TRIBUTOS, EMPRESTIMOS E IMOBILIZADO'
\echo '============================================================'

WITH conceitos(conceito, padrao) AS (
    VALUES
        ('TRIBUTOS', '(tribut|imposto)'),
        ('OBRIGACAO_TRIBUTARIA', '(obrigacao.*tribut|guia.*tribut)'),
        ('EMPRESTIMO', '(emprest)'),
        ('FINANCIAMENTO', '(financiamento)'),
        ('ATIVO_IMOBILIZADO', '(ativo.*imobilizado|imobilizado)'),
        ('DEPRECIACAO', '(depreciacao)')
)
SELECT
    conceito,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace n
                ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relkind IN ('r', 'p', 'v')
              AND c.relname ~* padrao
        )
        THEN 'ENCONTRADO'
        ELSE 'AUSENTE_OU_REVISAR'
    END AS status
FROM conceitos
ORDER BY conceito;

/* ============================================================================
   F1-FIN.12 — AUDITORIA DE INTEGRIDADE FINANCEIRA
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.12 - AUDITORIA DE INTEGRIDADE FINANCEIRA'
\echo '============================================================'

/* --------------------------------------------------------------------------
   12.1 — Constraints inválidas / não validadas
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.12.1 - CONSTRAINTS NAO VALIDADAS ---'

SELECT
    COUNT(*) AS constraints_nao_validadas
FROM pg_constraint con
JOIN pg_class c
    ON c.oid = con.conrelid
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND NOT con.convalidated;

/* --------------------------------------------------------------------------
   12.2 — Tabelas sem PK
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.12.2 - TABELAS SEM PK ---'

SELECT
    COUNT(*) AS tabelas_sem_pk
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relkind IN ('r', 'p')
  AND NOT EXISTS (
      SELECT 1
      FROM pg_constraint con
      WHERE con.conrelid = c.oid
        AND con.contype = 'p'
  );

/* --------------------------------------------------------------------------
   12.3 — Constraints com nomes duplicados no mesmo schema
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.12.3 - NOMES DE CONSTRAINT REPETIDOS ---'

SELECT
    con.conname AS constraint_name,
    COUNT(*) AS quantidade
FROM pg_constraint con
JOIN pg_class c
    ON c.oid = con.conrelid
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
GROUP BY con.conname
HAVING COUNT(*) > 1
ORDER BY
    quantidade DESC,
    con.conname;

/* --------------------------------------------------------------------------
   12.4 — FKs relacionadas ao financeiro
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.12.4 - TOTAL DE FKS ---'

SELECT
    COUNT(*) AS foreign_keys_financeiro
FROM pg_constraint con
JOIN pg_class c
    ON c.oid = con.conrelid
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND con.contype = 'f';

/* --------------------------------------------------------------------------
   12.5 — Colunas financeiras sem NOT NULL — apenas diagnóstico
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.12.5 - COLUNAS CRITICAS NULLABLE PARA REVISAO ---'

SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'financeiro'
  AND is_nullable = 'YES'
  AND column_name ~* '^id_empresa$|^valor$|valor_total|data_vencimento'
ORDER BY
    table_name,
    column_name;

/* --------------------------------------------------------------------------
   12.6 — Objetos sem documentação
   -------------------------------------------------------------------------- */

\echo ''
\echo '--- F1-FIN.12.6 - RESUMO DOCUMENTACAO ---'

SELECT
    COUNT(*) FILTER (
        WHERE obj_description(c.oid, 'pg_class') IS NULL
    ) AS tabelas_sem_comentario,
    COUNT(*) AS total_tabelas
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relkind IN ('r', 'p');

/* ============================================================================
   F1-FIN.13 — CERTIFICAÇÃO ESTRUTURAL PRELIMINAR
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.13 - CERTIFICACAO ESTRUTURAL PRELIMINAR'
\echo '============================================================'

WITH metricas AS (
    SELECT
        (
            SELECT COUNT(*)
            FROM pg_class c
            JOIN pg_namespace n
                ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relkind IN ('r', 'p')
        ) AS total_tabelas,

        (
            SELECT COUNT(*)
            FROM pg_class c
            JOIN pg_namespace n
                ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relkind IN ('r', 'p')
              AND NOT EXISTS (
                  SELECT 1
                  FROM pg_constraint con
                  WHERE con.conrelid = c.oid
                    AND con.contype = 'p'
              )
        ) AS tabelas_sem_pk,

        (
            SELECT COUNT(*)
            FROM pg_constraint con
            JOIN pg_class c
                ON c.oid = con.conrelid
            JOIN pg_namespace n
                ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND NOT con.convalidated
        ) AS constraints_nao_validadas,

        (
            SELECT COUNT(*)
            FROM pg_class c
            JOIN pg_namespace n
                ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relkind IN ('r', 'p')
              AND obj_description(c.oid, 'pg_class') IS NULL
        ) AS tabelas_sem_comentario
)
SELECT
    total_tabelas,
    tabelas_sem_pk,
    constraints_nao_validadas,
    tabelas_sem_comentario,
    CASE
        WHEN total_tabelas = 0
            THEN 'REPROVADO - SCHEMA FINANCEIRO SEM TABELAS'
        WHEN tabelas_sem_pk > 0
            THEN 'PENDENTE - EXISTEM TABELAS SEM PK'
        WHEN constraints_nao_validadas > 0
            THEN 'PENDENTE - EXISTEM CONSTRAINTS NAO VALIDADAS'
        ELSE
            'APROVACAO ESTRUTURAL PRELIMINAR'
    END AS status_f1_fin_13
FROM metricas;

/* ============================================================================
   PAINEL FINAL F1-FIN.1 -> F1-FIN.13
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' PAINEL FINAL - F1-FIN MASTER V1'
\echo '============================================================'

WITH
objetos AS (
    SELECT
        COUNT(*) FILTER (WHERE c.relkind IN ('r', 'p')) AS tabelas,
        COUNT(*) FILTER (WHERE c.relkind = 'S') AS sequences
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
),
constraints_fin AS (
    SELECT
        COUNT(*) AS total,
        COUNT(*) FILTER (WHERE con.contype = 'p') AS pk,
        COUNT(*) FILTER (WHERE con.contype = 'f') AS fk,
        COUNT(*) FILTER (WHERE con.contype = 'u') AS unique_constraints,
        COUNT(*) FILTER (WHERE con.contype = 'c') AS check_constraints,
        COUNT(*) FILTER (WHERE NOT con.convalidated) AS nao_validadas
    FROM pg_constraint con
    JOIN pg_class c
        ON c.oid = con.conrelid
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
),
outros AS (
    SELECT
        (SELECT COUNT(*)
         FROM pg_indexes
         WHERE schemaname = 'financeiro') AS indices,

        (SELECT COUNT(*)
         FROM pg_views
         WHERE schemaname = 'financeiro') AS views,

        (SELECT COUNT(*)
         FROM pg_proc p
         JOIN pg_namespace n ON n.oid = p.pronamespace
         WHERE n.nspname = 'financeiro'
           AND p.prokind IN ('f', 'p')) AS rotinas,

        (SELECT COUNT(*)
         FROM pg_trigger t
         JOIN pg_class c ON c.oid = t.tgrelid
         JOIN pg_namespace n ON n.oid = c.relnamespace
         WHERE n.nspname = 'financeiro'
           AND NOT t.tgisinternal) AS triggers
),
sem_pk AS (
    SELECT COUNT(*) AS quantidade
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relkind IN ('r', 'p')
      AND NOT EXISTS (
          SELECT 1
          FROM pg_constraint con
          WHERE con.conrelid = c.oid
            AND con.contype = 'p'
      )
)
SELECT
    o.tabelas,
    cf.total AS constraints,
    cf.pk,
    cf.fk,
    cf.unique_constraints,
    cf.check_constraints,
    ot.indices,
    o.sequences,
    ot.views,
    ot.rotinas,
    ot.triggers,
    sp.quantidade AS tabelas_sem_pk,
    cf.nao_validadas AS constraints_nao_validadas,
    CASE
        WHEN o.tabelas = 0
            THEN 'REPROVADO'
        WHEN sp.quantidade <> 0
            THEN 'PENDENTE'
        WHEN cf.nao_validadas <> 0
            THEN 'PENDENTE'
        ELSE 'APROVACAO_PRELIMINAR'
    END AS status
FROM objetos o
CROSS JOIN constraints_fin cf
CROSS JOIN outros ot
CROSS JOIN sem_pk sp;

\echo ''
\echo '============================================================'
\echo ' F1-FIN MASTER V1 CONCLUIDA'
\echo '============================================================'
\echo ''
\echo ' F1-FIN.1  Inventario ................. EXECUTADO'
\echo ' F1-FIN.2  Mapa funcional ............. EXECUTADO'
\echo ' F1-FIN.3  Lacunas .................... EXECUTADO'
\echo ' F1-FIN.4  Correcoes .................. DIAGNOSTICO'
\echo ' F1-FIN.5  Plano de Contas ............ AVALIADO'
\echo ' F1-FIN.6  AP/AR ...................... AVALIADO'
\echo ' F1-FIN.7  Caixa/Bancos/Cartoes ....... AVALIADO'
\echo ' F1-FIN.8  Rateios/Centro de Custo .... AVALIADO'
\echo ' F1-FIN.9  Conciliacao/Movimentacao ... AVALIADO'
\echo ' F1-FIN.10 Capital/AFAC/Lucros ......... AVALIADO'
\echo ' F1-FIN.11 Tributos/Emprestimos ........ AVALIADO'
\echo ' F1-FIN.12 Integridade ................. EXECUTADO'
\echo ' F1-FIN.13 Certificacao ................ PRELIMINAR'
\echo ''
\echo ' NENHUMA ALTERACAO FOI EXECUTADA NO BANCO.'
\echo ' PROXIMO PASSO: ANALISAR O LOG E GERAR MASTER V2.'
\echo '============================================================'
\echo ''

ROLLBACK;
