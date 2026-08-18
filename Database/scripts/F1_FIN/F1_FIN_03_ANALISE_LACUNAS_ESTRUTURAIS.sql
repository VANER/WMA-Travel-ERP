/* ============================================================================
   WMA TRAVEL ERP
   F1-FIN MASTER V1.1 — DIAGNOSTICO GLOBAL DO MODULO FINANCEIRO

   PostgreSQL : 18.x
   Banco      : wma_travel
   Modo       : SOMENTE LEITURA
   Objetivo   : Eliminar falsos diagnosticos da MASTER V1 e identificar
                somente lacunas estruturais reais antes da MASTER V2.

   REGRAS
   ------
   1. Nenhum objeto sera criado, alterado ou removido.
   2. Analise global dos schemas de negocio.
   3. Reconhecimento da nomenclatura real existente.
   4. Comparacao public x financeiro.
   5. Analise do modelo unificado AP/AR.
   6. Separacao entre:
      IMPLEMENTADO
      IMPLEMENTADO_COM_OUTRO_NOME
      PARCIAL
      AUSENTE
      REDUNDANTE
      DUPLICIDADE_POTENCIAL
      REVISAR
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
\echo ' F1-FIN MASTER V1.1 - DIAGNOSTICO GLOBAL'
\echo ' MODO: SOMENTE LEITURA'
\echo '============================================================'

/* ============================================================================
   V1.1.0 — AMBIENTE
   ============================================================================ */

\echo ''
\echo '=== V1.1.0 - AMBIENTE ==='

SELECT
    current_database() AS banco,
    current_user AS usuario,
    current_setting('server_version') AS postgresql,
    current_setting('server_encoding') AS server_encoding,
    current_setting('client_encoding') AS client_encoding,
    CURRENT_TIMESTAMP AS executado_em;

/* ============================================================================
   V1.1.1 — SCHEMAS DE NEGOCIO
   ============================================================================ */

\echo ''
\echo '=== V1.1.1 - SCHEMAS DE NEGOCIO ==='

SELECT
    n.nspname AS schema_name,
    pg_get_userbyid(n.nspowner) AS owner,
    COUNT(c.oid) FILTER (
        WHERE c.relkind IN ('r', 'p')
    ) AS tabelas
FROM pg_namespace n
LEFT JOIN pg_class c
    ON c.relnamespace = n.oid
WHERE n.nspname NOT LIKE 'pg_%'
  AND n.nspname <> 'information_schema'
GROUP BY
    n.nspname,
    n.nspowner
ORDER BY
    n.nspname;

/* ============================================================================
   V1.1.2 — INVENTARIO GLOBAL DE OBJETOS FINANCEIROS
   ============================================================================ */

\echo ''
\echo '=== V1.1.2 - OBJETOS POTENCIALMENTE FINANCEIROS EM TODOS OS SCHEMAS ==='

WITH objetos AS (
    SELECT
        n.nspname AS schema_name,
        c.relname AS object_name,
        CASE c.relkind
            WHEN 'r' THEN 'TABLE'
            WHEN 'p' THEN 'PARTITIONED TABLE'
            WHEN 'v' THEN 'VIEW'
            WHEN 'm' THEN 'MATERIALIZED VIEW'
            WHEN 'S' THEN 'SEQUENCE'
            ELSE c.relkind::text
        END AS object_type,
        obj_description(c.oid, 'pg_class') AS comentario
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname NOT LIKE 'pg_%'
      AND n.nspname <> 'information_schema'
      AND c.relkind IN ('r', 'p', 'v', 'm')
)
SELECT
    schema_name,
    object_name,
    object_type,
    comentario
FROM objetos
WHERE object_name ~* (
    'financ|conta|lancamento|pagamento|recebimento|parcela|'
    'banco|caixa|cartao|fatura|transfer|rateio|custo|concili|'
    'extrato|capital|aporte|afac|labore|lucro|tribut|imposto|'
    'emprest|financiamento|imobilizado|depreciacao|fornecedor|'
    'cliente|empresa|classificacao|categoria|grupo'
)
ORDER BY
    schema_name,
    object_name;

/* ============================================================================
   V1.1.3 — COMPARACAO PUBLIC x FINANCEIRO
   ============================================================================ */

\echo ''
\echo '=== V1.1.3 - OBJETOS HOMONIMOS PUBLIC x FINANCEIRO ==='

WITH public_tables AS (
    SELECT
        c.relname AS table_name,
        c.oid AS table_oid
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r', 'p')
),
financeiro_tables AS (
    SELECT
        c.relname AS table_name,
        c.oid AS table_oid
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relkind IN ('r', 'p')
)
SELECT
    f.table_name,
    (
        SELECT COUNT(*)
        FROM pg_attribute a
        WHERE a.attrelid = f.table_oid
          AND a.attnum > 0
          AND NOT a.attisdropped
    ) AS colunas_financeiro,
    (
        SELECT COUNT(*)
        FROM pg_attribute a
        WHERE a.attrelid = p.table_oid
          AND a.attnum > 0
          AND NOT a.attisdropped
    ) AS colunas_public,
    'DUPLICIDADE_POTENCIAL' AS status
FROM financeiro_tables f
JOIN public_tables p
    ON p.table_name = f.table_name
ORDER BY f.table_name;

/* ============================================================================
   V1.1.4 — COMPARACAO DETALHADA DE COLUNAS PUBLIC x FINANCEIRO
   ============================================================================ */

\echo ''
\echo '=== V1.1.4 - DIFERENCAS DE COLUNAS EM TABELAS HOMONIMAS ==='

WITH cols AS (
    SELECT
        n.nspname AS schema_name,
        c.relname AS table_name,
        a.attname AS column_name,
        pg_catalog.format_type(
            a.atttypid,
            a.atttypmod
        ) AS data_type
    FROM pg_attribute a
    JOIN pg_class c
        ON c.oid = a.attrelid
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname IN ('public', 'financeiro')
      AND c.relkind IN ('r', 'p')
      AND a.attnum > 0
      AND NOT a.attisdropped
),
homonimas AS (
    SELECT table_name
    FROM cols
    GROUP BY table_name
    HAVING COUNT(DISTINCT schema_name) = 2
)
SELECT
    h.table_name,
    COALESCE(p.column_name, f.column_name) AS column_name,
    p.data_type AS public_type,
    f.data_type AS financeiro_type,
    CASE
        WHEN p.column_name IS NULL
            THEN 'SOMENTE_FINANCEIRO'
        WHEN f.column_name IS NULL
            THEN 'SOMENTE_PUBLIC'
        WHEN p.data_type <> f.data_type
            THEN 'TIPO_DIFERENTE'
        ELSE 'IGUAL'
    END AS status
FROM homonimas h
LEFT JOIN cols p
    ON p.table_name = h.table_name
   AND p.schema_name = 'public'
FULL JOIN cols f
    ON f.table_name = h.table_name
   AND f.schema_name = 'financeiro'
   AND f.column_name = p.column_name
WHERE COALESCE(p.table_name, f.table_name) = h.table_name
ORDER BY
    h.table_name,
    COALESCE(p.column_name, f.column_name);

/* ============================================================================
   V1.1.5 — MAPA REAL DO PLANO DE CONTAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.1.5 - PLANO DE CONTAS REAL'
\echo '============================================================'

WITH conceitos(conceito, nome_real) AS (
    VALUES
        ('GRUPO_CONTA', 'grupo'),
        ('CATEGORIA_CONTA', 'categoria'),
        ('SUBCATEGORIA_CONTA', 'subcategoria'),
        ('CLASSIFICACAO_FINANCEIRA', 'classificacao'),
        ('CONTA_PLANO', 'conta')
)
SELECT
    c.conceito,
    c.nome_real,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM pg_class pc
            JOIN pg_namespace pn
                ON pn.oid = pc.relnamespace
            WHERE pn.nspname = 'financeiro'
              AND pc.relname = c.nome_real
              AND pc.relkind IN ('r', 'p')
        )
        THEN 'IMPLEMENTADO_COM_OUTRO_NOME'
        ELSE 'AUSENTE'
    END AS status
FROM conceitos c
ORDER BY c.conceito;

/* Relações reais do plano de contas */

\echo ''
\echo '--- RELACIONAMENTOS DO PLANO DE CONTAS ---'

SELECT
    sn.nspname AS source_schema,
    sc.relname AS source_table,
    con.conname AS fk_name,
    rn.nspname AS target_schema,
    rc.relname AS target_table,
    pg_get_constraintdef(con.oid, TRUE) AS definition
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
  AND sn.nspname = 'financeiro'
  AND (
      sc.relname IN (
          'grupo',
          'categoria',
          'subcategoria',
          'classificacao',
          'conta'
      )
      OR rc.relname IN (
          'grupo',
          'categoria',
          'subcategoria',
          'classificacao',
          'conta'
      )
  )
ORDER BY
    sc.relname,
    con.conname;

/* ============================================================================
   V1.1.6 — CLASSIFICACAO DRE / FLUXO / NATUREZA
   ============================================================================ */

\echo ''
\echo '=== V1.1.6 - CLASSIFICACOES CONTABEIS E GERENCIAIS ==='

SELECT
    table_schema,
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema NOT IN (
    'pg_catalog',
    'information_schema'
)
AND (
    column_name ~* '(dre|natureza|fluxo.*caixa|caixa.*fluxo)'
    OR table_name ~* '(dre|natureza.*financ|fluxo.*caixa)'
)
ORDER BY
    table_schema,
    table_name,
    ordinal_position;

/* ============================================================================
   V1.1.7 — MODELO UNIFICADO AP / AR
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.1.7 - VALIDACAO DO MODELO UNIFICADO AP/AR'
\echo '============================================================'

WITH requisitos(requisito, coluna) AS (
    VALUES
        ('EMPRESA', 'id_empresa'),
        ('TIPO_LANCAMENTO', 'id_tipo_lancamento'),
        ('STATUS', 'id_status'),
        ('CONTA', 'id_conta'),
        ('CLIENTE', 'id_cliente'),
        ('FORNECEDOR', 'id_fornecedor'),
        ('COMPETENCIA', 'competencia'),
        ('EMISSAO', 'emissao'),
        ('VENCIMENTO', 'vencimento'),
        ('PAGAMENTO', 'pagamento'),
        ('VALOR_BRUTO', 'valor_bruto'),
        ('DESCONTO', 'desconto'),
        ('ACRESCIMO', 'acrescimo'),
        ('JUROS', 'juros'),
        ('MULTA', 'multa'),
        ('VALOR_LIQUIDO', 'valor_liquido'),
        ('VALOR_PAGO', 'valor_pago'),
        ('SALDO', 'saldo')
)
SELECT
    r.requisito,
    r.coluna,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM information_schema.columns c
            WHERE c.table_schema = 'financeiro'
              AND c.table_name = 'lancamento'
              AND c.column_name = r.coluna
        )
        THEN 'IMPLEMENTADO'
        ELSE 'AUSENTE'
    END AS status
FROM requisitos r
ORDER BY r.requisito;

/* Núcleo AP/AR */

\echo ''
\echo '--- NUCLEO AP/AR ---'

WITH requisitos(conceito, tabela) AS (
    VALUES
        ('LANCAMENTO', 'lancamento'),
        ('TIPO_LANCAMENTO', 'tipo_lancamento'),
        ('STATUS_LANCAMENTO', 'status_lancamento'),
        ('PARCELAMENTO', 'lancamento_parcela'),
        ('PAGAMENTO_RECEBIMENTO', 'pagamento')
)
SELECT
    r.conceito,
    r.tabela,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM pg_class c
            JOIN pg_namespace n
                ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relname = r.tabela
              AND c.relkind IN ('r', 'p')
        )
        THEN 'IMPLEMENTADO'
        ELSE 'AUSENTE'
    END AS status
FROM requisitos r
ORDER BY r.conceito;

/* Valores existentes em tipo_lancamento */

\echo ''
\echo '--- DADOS DE TIPO_LANCAMENTO ---'

SELECT *
FROM financeiro.tipo_lancamento
ORDER BY id_tipo_lancamento;

/* ============================================================================
   V1.1.8 — CAIXA, BANCOS, CARTOES E TRANSFERENCIAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.1.8 - CAIXA / BANCOS / CARTOES / TRANSFERENCIAS'
\echo '============================================================'

WITH conceitos(conceito, regex) AS (
    VALUES
        ('BANCO', '(^banco$)'),
        ('CONTA_BANCARIA', '(^conta_bancaria$)'),
        ('CAIXA', '(^caixa$|caixa_)'),
        ('CARTAO', '(cartao)'),
        ('FATURA_CARTAO', '(fatura.*cartao|cartao.*fatura)'),
        ('TRANSFERENCIA', '(transfer)')
)
SELECT
    x.conceito,
    COALESCE(
        string_agg(
            n.nspname || '.' || c.relname,
            ', ' ORDER BY n.nspname, c.relname
        ),
        '(NAO ENCONTRADO)'
    ) AS objetos,
    CASE
        WHEN COUNT(c.oid) > 0 THEN 'IMPLEMENTADO'
        ELSE 'AUSENTE'
    END AS status
FROM conceitos x
LEFT JOIN pg_class c
    ON c.relname ~* x.regex
   AND c.relkind IN ('r', 'p', 'v', 'm')
LEFT JOIN pg_namespace n
    ON n.oid = c.relnamespace
   AND n.nspname NOT LIKE 'pg_%'
   AND n.nspname <> 'information_schema'
GROUP BY
    x.conceito
ORDER BY x.conceito;

/* ============================================================================
   V1.1.9 — RATEIOS E CENTRO DE CUSTO
   ============================================================================ */

\echo ''
\echo '=== V1.1.9 - RATEIOS E CENTRO DE CUSTO ==='

SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    CASE
        WHEN c.relname = 'centro_custo'
            THEN 'CENTRO_DE_CUSTO'
        WHEN c.relname ~* 'rateio'
            THEN 'RATEIO'
        ELSE 'REVISAR'
    END AS conceito,
    obj_description(c.oid, 'pg_class') AS comentario
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname NOT LIKE 'pg_%'
  AND n.nspname <> 'information_schema'
  AND c.relkind IN ('r', 'p')
  AND (
      c.relname = 'centro_custo'
      OR c.relname ~* 'rateio'
  )
ORDER BY
    n.nspname,
    c.relname;

/* ============================================================================
   V1.1.10 — CONCILIACAO E MOVIMENTACAO
   ============================================================================ */

\echo ''
\echo '=== V1.1.10 - CONCILIACAO E MOVIMENTACAO ==='

WITH conceitos(conceito, regex) AS (
    VALUES
        ('CONCILIACAO', '(concili)'),
        ('MOVIMENTACAO', '(movimentacao_bancaria|moviment.*financ)'),
        ('EXTRATO', '(extrato)')
)
SELECT
    x.conceito,
    COALESCE(
        string_agg(
            n.nspname || '.' || c.relname,
            ', ' ORDER BY n.nspname, c.relname
        ),
        '(NAO ENCONTRADO)'
    ) AS objetos,
    CASE
        WHEN COUNT(c.oid) > 0 THEN 'IMPLEMENTADO'
        ELSE 'AUSENTE'
    END AS status
FROM conceitos x
LEFT JOIN pg_class c
    ON c.relname ~* x.regex
   AND c.relkind IN ('r', 'p', 'v', 'm')
LEFT JOIN pg_namespace n
    ON n.oid = c.relnamespace
   AND n.nspname NOT LIKE 'pg_%'
   AND n.nspname <> 'information_schema'
GROUP BY x.conceito
ORDER BY x.conceito;

/* ============================================================================
   V1.1.11 — CAPITAL / AFAC / PRO-LABORE / LUCROS — GLOBAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.1.11 - CAPITAL / AFAC / PRO-LABORE / LUCROS'
\echo '============================================================'

WITH conceitos(conceito, regex) AS (
    VALUES
        ('CAPITAL_SOCIAL', '(capital.*social|capital_social)'),
        ('APORTE_CAPITAL', '(aporte.*capital|aporte)'),
        ('AFAC', '(^afac$|afac_)'),
        ('PRO_LABORE', '(pro.?labore)'),
        ('DISTRIBUICAO_LUCROS', '(distribuicao.*lucro|lucro.*distribu)')
)
SELECT
    x.conceito,
    COALESCE(
        string_agg(
            DISTINCT n.nspname || '.' || c.relname,
            ', ' ORDER BY n.nspname || '.' || c.relname
        ),
        '(NAO ENCONTRADO)'
    ) AS objetos,
    CASE
        WHEN COUNT(c.oid) > 0
            THEN 'IMPLEMENTADO'
        ELSE 'AUSENTE'
    END AS status
FROM conceitos x
LEFT JOIN pg_class c
    ON c.relname ~* x.regex
   AND c.relkind IN ('r', 'p', 'v', 'm')
LEFT JOIN pg_namespace n
    ON n.oid = c.relnamespace
   AND n.nspname NOT LIKE 'pg_%'
   AND n.nspname <> 'information_schema'
GROUP BY x.conceito
ORDER BY x.conceito;

/* ============================================================================
   V1.1.12 — TRIBUTOS / EMPRESTIMOS / IMOBILIZADO — GLOBAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.1.12 - TRIBUTOS / EMPRESTIMOS / IMOBILIZADO'
\echo '============================================================'

WITH conceitos(conceito, regex) AS (
    VALUES
        ('TRIBUTOS', '(tribut|imposto)'),
        ('OBRIGACAO_TRIBUTARIA', '(obrigacao.*tribut|guia.*tribut)'),
        ('EMPRESTIMO', '(emprest)'),
        ('FINANCIAMENTO', '(financiamento)'),
        ('ATIVO_IMOBILIZADO', '(ativo.*imobilizado|imobilizado)'),
        ('DEPRECIACAO', '(depreciacao)')
)
SELECT
    x.conceito,
    COALESCE(
        string_agg(
            DISTINCT n.nspname || '.' || c.relname,
            ', ' ORDER BY n.nspname || '.' || c.relname
        ),
        '(NAO ENCONTRADO)'
    ) AS objetos,
    CASE
        WHEN COUNT(c.oid) > 0
            THEN 'IMPLEMENTADO'
        ELSE 'AUSENTE'
    END AS status
FROM conceitos x
LEFT JOIN pg_class c
    ON c.relname ~* x.regex
   AND c.relkind IN ('r', 'p', 'v', 'm')
LEFT JOIN pg_namespace n
    ON n.oid = c.relnamespace
   AND n.nspname NOT LIKE 'pg_%'
   AND n.nspname <> 'information_schema'
GROUP BY x.conceito
ORDER BY x.conceito;

/* ============================================================================
   V1.1.13 — MULTIEMPRESA
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.1.13 - CLASSIFICACAO MULTIEMPRESA'
\echo '============================================================'

WITH financeiro_tables AS (
    SELECT
        c.oid,
        c.relname AS table_name
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relkind IN ('r', 'p')
),
analise AS (
    SELECT
        t.oid,
        t.table_name,

        EXISTS (
            SELECT 1
            FROM pg_attribute a
            WHERE a.attrelid = t.oid
              AND a.attname = 'id_empresa'
              AND a.attnum > 0
              AND NOT a.attisdropped
        ) AS possui_id_empresa,

        EXISTS (
            SELECT 1
            FROM pg_constraint fk
            JOIN pg_class ref
                ON ref.oid = fk.confrelid
            WHERE fk.conrelid = t.oid
              AND fk.contype = 'f'
              AND ref.relname IN (
                  'lancamento',
                  'lancamento_parcela',
                  'conta_bancaria'
              )
        ) AS possui_heranca_empresa
    FROM financeiro_tables t
)
SELECT
    table_name,
    CASE
        WHEN table_name IN (
            'banco',
            'forma_pagamento',
            'status_lancamento',
            'tipo_documento',
            'tipo_lancamento',
            'tipo_movimentacao'
        )
        THEN 'GLOBAL_CANDIDATO'

        WHEN possui_id_empresa
        THEN 'EMPRESA_DIRETA'

        WHEN possui_heranca_empresa
        THEN 'EMPRESA_HERDADA'

        ELSE 'REVISAR'
    END AS classificacao_multiempresa
FROM analise
ORDER BY
    classificacao_multiempresa,
    table_name;

/* ============================================================================
   V1.1.14 — TIPOS MONETARIOS — CORRIGIDO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.1.14 - VALIDACAO DE TIPOS MONETARIOS'
\echo '============================================================'

SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    numeric_precision,
    numeric_scale,
    CASE
        WHEN data_type IN ('numeric', 'decimal')
            THEN 'OK'
        ELSE 'REVISAR'
    END AS status
FROM information_schema.columns
WHERE table_schema = 'financeiro'
  AND column_name !~* '^id_'
  AND column_name ~* (
      '(^valor$|valor_|_valor$|saldo|preco|custo_total|'
      'taxa|juros|multa|desconto|acrescimo|total)'
  )
ORDER BY
    table_name,
    ordinal_position;

/* ============================================================================
   V1.1.15 — DOCUMENTACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.1.15 - DOCUMENTACAO ESTRUTURAL'
\echo '============================================================'

WITH tabelas AS (
    SELECT
        c.oid,
        c.relname AS table_name,
        obj_description(c.oid, 'pg_class') AS comentario
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relkind IN ('r', 'p')
),
colunas AS (
    SELECT
        c.oid,
        c.relname AS table_name,
        a.attnum,
        a.attname AS column_name,
        col_description(c.oid, a.attnum) AS comentario
    FROM pg_attribute a
    JOIN pg_class c
        ON c.oid = a.attrelid
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relkind IN ('r', 'p')
      AND a.attnum > 0
      AND NOT a.attisdropped
)
SELECT
    (SELECT COUNT(*) FROM tabelas) AS total_tabelas,
    (
        SELECT COUNT(*)
        FROM tabelas
        WHERE comentario IS NULL
           OR btrim(comentario) = ''
    ) AS tabelas_sem_comentario,
    (SELECT COUNT(*) FROM colunas) AS total_colunas,
    (
        SELECT COUNT(*)
        FROM colunas
        WHERE comentario IS NULL
           OR btrim(comentario) = ''
    ) AS colunas_sem_comentario;

/* ============================================================================
   V1.1.16 — INTEGRIDADE ESTRUTURAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.1.16 - INTEGRIDADE ESTRUTURAL'
\echo '============================================================'

WITH
tables_fin AS (
    SELECT c.oid
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relkind IN ('r', 'p')
),
sem_pk AS (
    SELECT COUNT(*) AS quantidade
    FROM tables_fin t
    WHERE NOT EXISTS (
        SELECT 1
        FROM pg_constraint con
        WHERE con.conrelid = t.oid
          AND con.contype = 'p'
    )
),
nao_validadas AS (
    SELECT COUNT(*) AS quantidade
    FROM pg_constraint con
    JOIN pg_class c
        ON c.oid = con.conrelid
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND NOT con.convalidated
),
duplicadas AS (
    SELECT COUNT(*) AS quantidade
    FROM (
        SELECT con.conname
        FROM pg_constraint con
        JOIN pg_class c
            ON c.oid = con.conrelid
        JOIN pg_namespace n
            ON n.oid = c.relnamespace
        WHERE n.nspname = 'financeiro'
        GROUP BY con.conname
        HAVING COUNT(*) > 1
    ) x
)
SELECT
    (SELECT COUNT(*) FROM tables_fin) AS tabelas,
    (SELECT quantidade FROM sem_pk) AS tabelas_sem_pk,
    (SELECT quantidade FROM nao_validadas) AS constraints_nao_validadas,
    (SELECT quantidade FROM duplicadas) AS nomes_constraints_duplicados,
    CASE
        WHEN (SELECT quantidade FROM sem_pk) = 0
         AND (SELECT quantidade FROM nao_validadas) = 0
         AND (SELECT quantidade FROM duplicadas) = 0
        THEN 'APROVADO'
        ELSE 'PENDENTE'
    END AS status;

/* ============================================================================
   V1.1.17 — DEPENDENCIAS ENTRE SCHEMAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.1.17 - DEPENDENCIAS ENTRE SCHEMAS'
\echo '============================================================'

SELECT
    sn.nspname AS source_schema,
    sc.relname AS source_table,
    con.conname AS fk_name,
    rn.nspname AS target_schema,
    rc.relname AS target_table,
    pg_get_constraintdef(con.oid, TRUE) AS definition
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
  AND sn.nspname <> rn.nspname
ORDER BY
    sn.nspname,
    sc.relname,
    rn.nspname,
    rc.relname;

/* ============================================================================
   V1.1.18 — MATRIZ GLOBAL DE COBERTURA FUNCIONAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.1.18 - MATRIZ GLOBAL DE COBERTURA'
\echo '============================================================'

WITH conceitos(conceito, regex) AS (
    VALUES
        ('PLANO_CONTAS_GRUPO', '(^grupo$|grupo_conta)'),
        ('PLANO_CONTAS_CATEGORIA', '(^categoria$|categoria_conta)'),
        ('PLANO_CONTAS_SUBCATEGORIA', '(^subcategoria$|subcategoria_conta)'),
        ('CLASSIFICACAO_FINANCEIRA', '(^classificacao$)'),
        ('CONTA_PLANO', '(^conta$|conta_contabil)'),
        ('LANCAMENTO', '(^lancamento$)'),
        ('PARCELAMENTO', '(^lancamento_parcela$|parcela.*lancamento)'),
        ('PAGAMENTO_RECEBIMENTO', '(^pagamento$|recebimento)'),
        ('BANCO', '(^banco$)'),
        ('CONTA_BANCARIA', '(^conta_bancaria$)'),
        ('CAIXA', '(^caixa$|caixa_)'),
        ('CARTAO', '(cartao)'),
        ('TRANSFERENCIA', '(transfer)'),
        ('CENTRO_CUSTO', '(^centro_custo$)'),
        ('RATEIO', '(rateio)'),
        ('CONCILIACAO', '(concili)'),
        ('MOVIMENTACAO', '(movimentacao_bancaria|moviment.*financ)'),
        ('EXTRATO_BANCARIO', '(extrato)'),
        ('CAPITAL_SOCIAL', '(capital.*social|capital_social)'),
        ('APORTE_CAPITAL', '(aporte)'),
        ('AFAC', '(^afac$|afac_)'),
        ('PRO_LABORE', '(pro.?labore)'),
        ('DISTRIBUICAO_LUCROS', '(distribuicao.*lucro|lucro.*distribu)'),
        ('TRIBUTOS', '(tribut|imposto)'),
        ('EMPRESTIMO', '(emprest)'),
        ('FINANCIAMENTO', '(financiamento)'),
        ('ATIVO_IMOBILIZADO', '(ativo.*imobilizado|imobilizado)'),
        ('DEPRECIACAO', '(depreciacao)')
)
SELECT
    x.conceito,
    COUNT(c.oid) AS objetos_encontrados,
    COALESCE(
        string_agg(
            DISTINCT n.nspname || '.' || c.relname,
            ', ' ORDER BY n.nspname || '.' || c.relname
        ),
        '(NAO ENCONTRADO)'
    ) AS objetos,
    CASE
        WHEN COUNT(c.oid) > 0
            THEN 'IMPLEMENTADO'
        ELSE 'AUSENTE'
    END AS status
FROM conceitos x
LEFT JOIN pg_class c
    ON c.relname ~* x.regex
   AND c.relkind IN ('r', 'p', 'v', 'm')
LEFT JOIN pg_namespace n
    ON n.oid = c.relnamespace
   AND n.nspname NOT LIKE 'pg_%'
   AND n.nspname <> 'information_schema'
GROUP BY x.conceito
ORDER BY x.conceito;

/* ============================================================================
   V1.1.19 — PAINEL DE DECISAO PARA MASTER V2
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.1.19 - PAINEL DE DECISAO'
\echo '============================================================'

WITH
estrutura AS (
    SELECT
        COUNT(*) AS total_tabelas,
        COUNT(*) FILTER (
            WHERE obj_description(c.oid, 'pg_class') IS NULL
        ) AS sem_comentario
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relkind IN ('r', 'p')
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
),
invalidas AS (
    SELECT COUNT(*) AS quantidade
    FROM pg_constraint con
    JOIN pg_class c
        ON c.oid = con.conrelid
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND NOT con.convalidated
),
homonimas AS (
    SELECT COUNT(*) AS quantidade
    FROM (
        SELECT c.relname
        FROM pg_class c
        JOIN pg_namespace n
            ON n.oid = c.relnamespace
        WHERE n.nspname IN ('public', 'financeiro')
          AND c.relkind IN ('r', 'p')
        GROUP BY c.relname
        HAVING COUNT(DISTINCT n.nspname) = 2
    ) x
)
SELECT
    e.total_tabelas,
    s.quantidade AS tabelas_sem_pk,
    i.quantidade AS constraints_nao_validadas,
    e.sem_comentario AS tabelas_sem_comentario,
    h.quantidade AS homonimas_public_financeiro,
    CASE
        WHEN s.quantidade > 0
          OR i.quantidade > 0
        THEN 'CORRECAO_ESTRUTURAL_NECESSARIA'

        WHEN h.quantidade > 0
        THEN 'REVISAR_ARQUITETURA_ANTES_DA_V2'

        WHEN e.sem_comentario > 0
        THEN 'ESTRUTURA_OK_DOCUMENTACAO_PENDENTE'

        ELSE 'PRONTO_PARA_CERTIFICACAO'
    END AS decisao
FROM estrutura e
CROSS JOIN sem_pk s
CROSS JOIN invalidas i
CROSS JOIN homonimas h;

/* ============================================================================
   ENCERRAMENTO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN MASTER V1.1 CONCLUIDA'
\echo '============================================================'
\echo ''
\echo ' ANALISE GLOBAL ................. EXECUTADA'
\echo ' PUBLIC x FINANCEIRO ............ EXECUTADO'
\echo ' PLANO DE CONTAS REAL ........... EXECUTADO'
\echo ' AP/AR UNIFICADO ................ EXECUTADO'
\echo ' CAIXA/BANCOS/CARTOES ........... EXECUTADO'
\echo ' RATEIOS/CENTRO DE CUSTO ........ EXECUTADO'
\echo ' CONCILIACAO/MOVIMENTACAO ....... EXECUTADO'
\echo ' CAPITAL/AFAC/LUCROS ............ EXECUTADO'
\echo ' TRIBUTOS/EMPRESTIMOS ........... EXECUTADO'
\echo ' MULTIEMPRESA ................... EXECUTADO'
\echo ' TIPOS MONETARIOS ............... EXECUTADO'
\echo ' DOCUMENTACAO ................... EXECUTADO'
\echo ' INTEGRIDADE .................... EXECUTADO'
\echo ' MATRIZ GLOBAL .................. EXECUTADA'
\echo ''
\echo ' NENHUMA ALTERACAO FOI REALIZADA.'
\echo ' PROXIMO PASSO: MASTER V2 SOMENTE APOS ANALISE DESTE LOG.'
\echo '============================================================'

ROLLBACK;
