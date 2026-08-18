/* ============================================================================
   WMA TRAVEL ERP
   F1-FIN MASTER V1.3 — CLASSIFICACAO DE DOMINIO

   PostgreSQL : 18.x
   Banco      : wma_travel
   Modo       : SOMENTE LEITURA

   REGRA ARQUITETURAL
   ------------------
   financeiro = autoridade do dominio financeiro
   public     = autoridade corporativa / transversal

   OBJETIVO
   --------
   Classificar definitivamente as tabelas homonimas encontradas entre
   public e financeiro antes da F1-FIN.4 / MASTER V2.

   Esta etapa NAO altera estruturas nem dados.

   CLASSIFICACOES
   --------------
   FINANCEIRO
   PUBLIC_TRANSVERSAL
   REVISAR

   DECISOES
   --------
   MANTER_FINANCEIRO
   MANTER_PUBLIC
   CONSOLIDAR_EM_FINANCEIRO
   CONSOLIDAR_EM_PUBLIC
   REVISAR_MANUALMENTE
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
\echo ' F1-FIN MASTER V1.3 - CLASSIFICACAO DE DOMINIO'
\echo '============================================================'
\echo ' financeiro = AUTORIDADE FINANCEIRA'
\echo ' public     = CORPORATIVO / TRANSVERSAL'
\echo ' MODO       = SOMENTE LEITURA'
\echo '============================================================'

/* ============================================================================
   V1.3.0 — AMBIENTE
   ============================================================================ */

\echo ''
\echo '=== V1.3.0 - AMBIENTE ==='

SELECT
    current_database() AS banco,
    current_user AS usuario,
    current_setting('server_version') AS postgresql,
    current_setting('server_encoding') AS server_encoding,
    current_setting('client_encoding') AS client_encoding,
    CURRENT_TIMESTAMP AS executado_em;

/* ============================================================================
   V1.3.1 — UNIVERSO PUBLIC x FINANCEIRO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.1 - TABELAS HOMONIMAS'
\echo '============================================================'

WITH objetos AS (
    SELECT
        n.nspname AS schema_name,
        c.relname AS table_name,
        c.oid
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname IN ('public', 'financeiro')
      AND c.relkind IN ('r', 'p')
),
homonimas AS (
    SELECT table_name
    FROM objetos
    GROUP BY table_name
    HAVING COUNT(DISTINCT schema_name) = 2
)
SELECT
    table_name
FROM homonimas
ORDER BY table_name;

/* ============================================================================
   V1.3.2 — CLASSIFICACAO FUNCIONAL PREDEFINIDA
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.2 - CLASSIFICACAO FUNCIONAL'
\echo '============================================================'

WITH classificacao(
    table_name,
    dominio,
    justificativa
) AS (
    VALUES

        (
            'empresa',
            'PUBLIC_TRANSVERSAL',
            'Entidade corporativa utilizada por todos os modulos do ERP.'
        ),

        (
            'cliente',
            'PUBLIC_TRANSVERSAL',
            'Cliente e entidade corporativa compartilhada entre modulos.'
        ),

        (
            'fornecedor',
            'PUBLIC_TRANSVERSAL',
            'Fornecedor e entidade corporativa compartilhada.'
        ),

        (
            'usuario',
            'PUBLIC_TRANSVERSAL',
            'Usuario pertence a identidade e seguranca corporativa.'
        ),

        (
            'banco',
            'FINANCEIRO',
            'Cadastro bancario pertence ao dominio financeiro.'
        ),

        (
            'conta_bancaria',
            'FINANCEIRO',
            'Conta bancaria e recurso operacional do modulo financeiro.'
        ),

        (
            'forma_pagamento',
            'FINANCEIRO',
            'Forma de pagamento participa diretamente das operacoes financeiras.'
        ),

        (
            'conciliacao_bancaria',
            'FINANCEIRO',
            'Conciliacao bancaria e processo exclusivo do dominio financeiro.'
        ),

        (
            'lancamento_parcela',
            'FINANCEIRO',
            'Parcela e parte do ciclo de contas a pagar e receber.'
        ),

        (
            'centro_custo',
            'FINANCEIRO',
            'Centro de custo e classificacao gerencial financeira nesta fase.'
        ),

        (
            'tipo_documento',
            'REVISAR',
            'Pode possuir uso transversal ou especializacao financeira.'
        )
)
SELECT
    table_name,
    dominio,
    justificativa
FROM classificacao
ORDER BY
    dominio,
    table_name;

/* ============================================================================
   V1.3.3 — VALIDAR EXISTENCIA DAS TABELAS CLASSIFICADAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.3 - VALIDACAO DE EXISTENCIA'
\echo '============================================================'

WITH classificacao(table_name, dominio) AS (
    VALUES
        ('empresa', 'PUBLIC_TRANSVERSAL'),
        ('cliente', 'PUBLIC_TRANSVERSAL'),
        ('fornecedor', 'PUBLIC_TRANSVERSAL'),
        ('usuario', 'PUBLIC_TRANSVERSAL'),

        ('banco', 'FINANCEIRO'),
        ('conta_bancaria', 'FINANCEIRO'),
        ('forma_pagamento', 'FINANCEIRO'),
        ('conciliacao_bancaria', 'FINANCEIRO'),
        ('lancamento_parcela', 'FINANCEIRO'),
        ('centro_custo', 'FINANCEIRO'),

        ('tipo_documento', 'REVISAR')
)
SELECT
    x.table_name,
    x.dominio,

    EXISTS (
        SELECT 1
        FROM pg_class c
        JOIN pg_namespace n
            ON n.oid = c.relnamespace
        WHERE n.nspname = 'public'
          AND c.relname = x.table_name
          AND c.relkind IN ('r', 'p')
    ) AS existe_public,

    EXISTS (
        SELECT 1
        FROM pg_class c
        JOIN pg_namespace n
            ON n.oid = c.relnamespace
        WHERE n.nspname = 'financeiro'
          AND c.relname = x.table_name
          AND c.relkind IN ('r', 'p')
    ) AS existe_financeiro

FROM classificacao x
ORDER BY x.table_name;

/* ============================================================================
   V1.3.4 — CONTAGEM EXATA DE DADOS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.4 - CONTAGEM DE REGISTROS'
\echo '============================================================'

SELECT format(
    'SELECT %L AS objeto, COUNT(*) AS registros FROM %I.%I;',
    n.nspname || '.' || c.relname,
    n.nspname,
    c.relname
)
FROM pg_class c
JOIN pg_namespace n
    ON n.oid = c.relnamespace
WHERE n.nspname IN ('public', 'financeiro')
  AND c.relkind IN ('r', 'p')
  AND c.relname IN (
      'empresa',
      'cliente',
      'fornecedor',
      'usuario',
      'banco',
      'conta_bancaria',
      'forma_pagamento',
      'conciliacao_bancaria',
      'lancamento_parcela',
      'centro_custo',
      'tipo_documento'
  )
ORDER BY
    c.relname,
    n.nspname
\gexec

/* ============================================================================
   V1.3.5 — COMPARACAO DE COLUNAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.5 - DIFERENCAS ESTRUTURAIS'
\echo '============================================================'

WITH cols AS (
    SELECT
        n.nspname AS schema_name,
        c.relname AS table_name,
        a.attname AS column_name,

        pg_catalog.format_type(
            a.atttypid,
            a.atttypmod
        ) AS data_type,

        a.attnotnull AS not_null

    FROM pg_attribute a

    JOIN pg_class c
        ON c.oid = a.attrelid

    JOIN pg_namespace n
        ON n.oid = c.relnamespace

    WHERE n.nspname IN ('public', 'financeiro')

      AND c.relname IN (
          'empresa',
          'cliente',
          'fornecedor',
          'usuario',
          'banco',
          'conta_bancaria',
          'forma_pagamento',
          'conciliacao_bancaria',
          'lancamento_parcela',
          'centro_custo',
          'tipo_documento'
      )

      AND c.relkind IN ('r', 'p')
      AND a.attnum > 0
      AND NOT a.attisdropped
),
public_cols AS (
    SELECT *
    FROM cols
    WHERE schema_name = 'public'
),
financeiro_cols AS (
    SELECT *
    FROM cols
    WHERE schema_name = 'financeiro'
)
SELECT
    COALESCE(p.table_name, f.table_name) AS table_name,
    COALESCE(p.column_name, f.column_name) AS column_name,

    p.data_type AS public_type,
    f.data_type AS financeiro_type,

    p.not_null AS public_not_null,
    f.not_null AS financeiro_not_null,

    CASE
        WHEN p.column_name IS NULL
            THEN 'SOMENTE_FINANCEIRO'

        WHEN f.column_name IS NULL
            THEN 'SOMENTE_PUBLIC'

        WHEN p.data_type <> f.data_type
            THEN 'TIPO_DIFERENTE'

        WHEN p.not_null <> f.not_null
            THEN 'NULLABILITY_DIFERENTE'

        ELSE 'IGUAL'
    END AS comparacao

FROM public_cols p

FULL JOIN financeiro_cols f
    ON f.table_name = p.table_name
   AND f.column_name = p.column_name

ORDER BY
    COALESCE(p.table_name, f.table_name),
    COALESCE(p.column_name, f.column_name);

/* ============================================================================
   V1.3.6 — FKS QUE APONTAM PARA PUBLIC / FINANCEIRO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.6 - DEPENDENCIAS RECEBIDAS'
\echo '============================================================'

SELECT
    target_ns.nspname AS target_schema,
    target.relname AS target_table,

    source_ns.nspname AS source_schema,
    source.relname AS source_table,

    con.conname AS fk_name,

    pg_get_constraintdef(
        con.oid,
        TRUE
    ) AS definition

FROM pg_constraint con

JOIN pg_class source
    ON source.oid = con.conrelid

JOIN pg_namespace source_ns
    ON source_ns.oid = source.relnamespace

JOIN pg_class target
    ON target.oid = con.confrelid

JOIN pg_namespace target_ns
    ON target_ns.oid = target.relnamespace

WHERE con.contype = 'f'

  AND target_ns.nspname IN (
      'public',
      'financeiro'
  )

  AND target.relname IN (
      'empresa',
      'cliente',
      'fornecedor',
      'usuario',
      'banco',
      'conta_bancaria',
      'forma_pagamento',
      'conciliacao_bancaria',
      'lancamento_parcela',
      'centro_custo',
      'tipo_documento'
  )

ORDER BY
    target.relname,
    target_ns.nspname,
    source_ns.nspname,
    source.relname;

/* ============================================================================
   V1.3.7 — RESUMO DAS DEPENDENCIAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.7 - RESUMO DE DEPENDENCIAS'
\echo '============================================================'

WITH objetos AS (
    SELECT
        n.nspname AS schema_name,
        c.relname AS table_name,
        c.oid
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname IN ('public', 'financeiro')
      AND c.relkind IN ('r', 'p')
      AND c.relname IN (
          'empresa',
          'cliente',
          'fornecedor',
          'usuario',
          'banco',
          'conta_bancaria',
          'forma_pagamento',
          'conciliacao_bancaria',
          'lancamento_parcela',
          'centro_custo',
          'tipo_documento'
      )
),
metricas AS (
    SELECT
        o.schema_name,
        o.table_name,

        (
            SELECT COUNT(*)
            FROM pg_constraint con
            WHERE con.confrelid = o.oid
              AND con.contype = 'f'
        ) AS fks_recebidas,

        (
            SELECT COUNT(*)
            FROM pg_constraint con
            WHERE con.conrelid = o.oid
              AND con.contype = 'f'
        ) AS fks_emitidas

    FROM objetos o
)
SELECT
    table_name,

    MAX(fks_recebidas) FILTER (
        WHERE schema_name = 'public'
    ) AS public_fks_recebidas,

    MAX(fks_recebidas) FILTER (
        WHERE schema_name = 'financeiro'
    ) AS financeiro_fks_recebidas,

    MAX(fks_emitidas) FILTER (
        WHERE schema_name = 'public'
    ) AS public_fks_emitidas,

    MAX(fks_emitidas) FILTER (
        WHERE schema_name = 'financeiro'
    ) AS financeiro_fks_emitidas

FROM metricas

GROUP BY table_name

ORDER BY table_name;

/* ============================================================================
   V1.3.8 — CLASSIFICAR FKS DO NUCLEO FINANCEIRO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.8 - FKS DO NUCLEO FINANCEIRO'
\echo '============================================================'

SELECT
    source.relname AS tabela_financeira,
    con.conname AS fk_name,
    target_ns.nspname AS target_schema,
    target.relname AS target_table,

    CASE
        WHEN target.relname IN (
            'empresa',
            'cliente',
            'fornecedor',
            'usuario'
        )
        THEN
            CASE
                WHEN target_ns.nspname = 'public'
                    THEN 'OK_PUBLIC_TRANSVERSAL'
                ELSE 'REDIRECIONAR_PARA_PUBLIC'
            END

        WHEN target.relname IN (
            'banco',
            'conta_bancaria',
            'forma_pagamento',
            'conciliacao_bancaria',
            'lancamento_parcela',
            'centro_custo'
        )
        THEN
            CASE
                WHEN target_ns.nspname = 'financeiro'
                    THEN 'OK_FINANCEIRO'
                ELSE 'REDIRECIONAR_PARA_FINANCEIRO'
            END

        ELSE 'OUTRO_DOMINIO'
    END AS decisao

FROM pg_constraint con

JOIN pg_class source
    ON source.oid = con.conrelid

JOIN pg_namespace source_ns
    ON source_ns.oid = source.relnamespace

JOIN pg_class target
    ON target.oid = con.confrelid

JOIN pg_namespace target_ns
    ON target_ns.oid = target.relnamespace

WHERE con.contype = 'f'
  AND source_ns.nspname = 'financeiro'

ORDER BY
    source.relname,
    con.conname;

/* ============================================================================
   V1.3.9 — BANCO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.9 - BANCO'
\echo ' AUTORIDADE ESPERADA: FINANCEIRO'
\echo '============================================================'

SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema IN ('public', 'financeiro')
  AND table_name = 'banco'
ORDER BY
    table_schema,
    ordinal_position;

/* ============================================================================
   V1.3.10 — CONTA BANCARIA
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.10 - CONTA_BANCARIA'
\echo ' AUTORIDADE ESPERADA: FINANCEIRO'
\echo '============================================================'

SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema IN ('public', 'financeiro')
  AND table_name = 'conta_bancaria'
ORDER BY
    table_schema,
    ordinal_position;

/* ============================================================================
   V1.3.11 — FORMA DE PAGAMENTO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.11 - FORMA_PAGAMENTO'
\echo ' AUTORIDADE ESPERADA: FINANCEIRO'
\echo '============================================================'

SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema IN ('public', 'financeiro')
  AND table_name = 'forma_pagamento'
ORDER BY
    table_schema,
    ordinal_position;

/* ============================================================================
   V1.3.12 — CENTRO DE CUSTO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.12 - CENTRO_CUSTO'
\echo ' AUTORIDADE ESPERADA: FINANCEIRO'
\echo '============================================================'

SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema IN ('public', 'financeiro')
  AND table_name = 'centro_custo'
ORDER BY
    table_schema,
    ordinal_position;

/* ============================================================================
   V1.3.13 — CONCILIACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.13 - CONCILIACAO_BANCARIA'
\echo ' AUTORIDADE ESPERADA: FINANCEIRO'
\echo '============================================================'

SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema IN ('public', 'financeiro')
  AND table_name = 'conciliacao_bancaria'
ORDER BY
    table_schema,
    ordinal_position;

/* ============================================================================
   V1.3.14 — PARCELAMENTO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.14 - LANCAMENTO_PARCELA'
\echo ' AUTORIDADE ESPERADA: FINANCEIRO'
\echo '============================================================'

SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema IN ('public', 'financeiro')
  AND table_name = 'lancamento_parcela'
ORDER BY
    table_schema,
    ordinal_position;

/* ============================================================================
   V1.3.15 — ENTIDADES CORPORATIVAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.15 - ENTIDADES PUBLIC TRANSVERSAIS'
\echo '============================================================'

SELECT
    table_schema,
    table_name,
    COUNT(*) AS quantidade_colunas
FROM information_schema.columns
WHERE table_schema IN ('public', 'financeiro')
  AND table_name IN (
      'empresa',
      'cliente',
      'fornecedor',
      'usuario'
  )
GROUP BY
    table_schema,
    table_name
ORDER BY
    table_name,
    table_schema;

/* ============================================================================
   V1.3.16 — TIPO_DOCUMENTO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.16 - TIPO_DOCUMENTO - ANALISE ESPECIAL'
\echo '============================================================'

SELECT
    table_schema,
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema IN ('public', 'financeiro')
  AND table_name = 'tipo_documento'
ORDER BY
    table_schema,
    ordinal_position;

\echo ''
\echo '--- FKS PARA TIPO_DOCUMENTO ---'

SELECT
    source_ns.nspname AS source_schema,
    source.relname AS source_table,
    con.conname AS fk_name,
    target_ns.nspname AS target_schema,
    target.relname AS target_table,
    pg_get_constraintdef(con.oid, TRUE) AS definition
FROM pg_constraint con
JOIN pg_class source
    ON source.oid = con.conrelid
JOIN pg_namespace source_ns
    ON source_ns.oid = source.relnamespace
JOIN pg_class target
    ON target.oid = con.confrelid
JOIN pg_namespace target_ns
    ON target_ns.oid = target.relnamespace
WHERE con.contype = 'f'
  AND target.relname = 'tipo_documento'
ORDER BY
    source_ns.nspname,
    source.relname;

/* ============================================================================
   V1.3.17 — MATRIZ ARQUITETURAL FINAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.17 - MATRIZ ARQUITETURAL FINAL'
\echo '============================================================'

WITH classificacao(
    table_name,
    dominio,
    schema_autoridade
) AS (
    VALUES
        ('empresa', 'PUBLIC_TRANSVERSAL', 'public'),
        ('cliente', 'PUBLIC_TRANSVERSAL', 'public'),
        ('fornecedor', 'PUBLIC_TRANSVERSAL', 'public'),
        ('usuario', 'PUBLIC_TRANSVERSAL', 'public'),

        ('banco', 'FINANCEIRO', 'financeiro'),
        ('conta_bancaria', 'FINANCEIRO', 'financeiro'),
        ('forma_pagamento', 'FINANCEIRO', 'financeiro'),
        ('conciliacao_bancaria', 'FINANCEIRO', 'financeiro'),
        ('lancamento_parcela', 'FINANCEIRO', 'financeiro'),
        ('centro_custo', 'FINANCEIRO', 'financeiro'),

        ('tipo_documento', 'REVISAR', NULL)
),
objetos AS (
    SELECT
        n.nspname AS schema_name,
        c.relname AS table_name,
        c.oid,

        (
            SELECT COUNT(*)
            FROM pg_attribute a
            WHERE a.attrelid = c.oid
              AND a.attnum > 0
              AND NOT a.attisdropped
        ) AS colunas,

        (
            SELECT COUNT(*)
            FROM pg_constraint con
            WHERE con.confrelid = c.oid
              AND con.contype = 'f'
        ) AS fks_recebidas,

        (
            SELECT COUNT(*)
            FROM pg_constraint con
            WHERE con.conrelid = c.oid
              AND con.contype = 'f'
        ) AS fks_emitidas

    FROM pg_class c

    JOIN pg_namespace n
        ON n.oid = c.relnamespace

    WHERE n.nspname IN ('public', 'financeiro')
      AND c.relkind IN ('r', 'p')
)
SELECT
    cl.table_name,
    cl.dominio,
    cl.schema_autoridade,

    COALESCE(
        MAX(o.colunas) FILTER (
            WHERE o.schema_name = 'public'
        ),
        0
    ) AS public_colunas,

    COALESCE(
        MAX(o.colunas) FILTER (
            WHERE o.schema_name = 'financeiro'
        ),
        0
    ) AS financeiro_colunas,

    COALESCE(
        MAX(o.fks_recebidas) FILTER (
            WHERE o.schema_name = 'public'
        ),
        0
    ) AS public_fks_recebidas,

    COALESCE(
        MAX(o.fks_recebidas) FILTER (
            WHERE o.schema_name = 'financeiro'
        ),
        0
    ) AS financeiro_fks_recebidas,

    CASE
        WHEN cl.dominio = 'PUBLIC_TRANSVERSAL'
            THEN 'MANTER_PUBLIC'

        WHEN cl.dominio = 'FINANCEIRO'
            THEN 'MANTER_FINANCEIRO'

        ELSE 'REVISAR_MANUALMENTE'
    END AS decisao

FROM classificacao cl

LEFT JOIN objetos o
    ON o.table_name = cl.table_name

GROUP BY
    cl.table_name,
    cl.dominio,
    cl.schema_autoridade

ORDER BY
    cl.dominio,
    cl.table_name;

/* ============================================================================
   V1.3.18 — DETECTAR FKS CONTRARIAS A REGRA
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.18 - FKS CONTRARIAS A ARQUITETURA'
\echo '============================================================'

WITH autoridade(table_name, schema_autoridade) AS (
    VALUES
        ('empresa', 'public'),
        ('cliente', 'public'),
        ('fornecedor', 'public'),
        ('usuario', 'public'),

        ('banco', 'financeiro'),
        ('conta_bancaria', 'financeiro'),
        ('forma_pagamento', 'financeiro'),
        ('conciliacao_bancaria', 'financeiro'),
        ('lancamento_parcela', 'financeiro'),
        ('centro_custo', 'financeiro')
)
SELECT
    source_ns.nspname AS source_schema,
    source.relname AS source_table,
    con.conname AS fk_name,

    target_ns.nspname AS target_schema_atual,
    target.relname AS target_table,

    a.schema_autoridade AS target_schema_esperado,

    CASE
        WHEN target_ns.nspname = a.schema_autoridade
            THEN 'OK'
        ELSE 'CORRIGIR_NA_V2'
    END AS status

FROM pg_constraint con

JOIN pg_class source
    ON source.oid = con.conrelid

JOIN pg_namespace source_ns
    ON source_ns.oid = source.relnamespace

JOIN pg_class target
    ON target.oid = con.confrelid

JOIN pg_namespace target_ns
    ON target_ns.oid = target.relnamespace

JOIN autoridade a
    ON a.table_name = target.relname

WHERE con.contype = 'f'

ORDER BY
    status DESC,
    target.relname,
    source_ns.nspname,
    source.relname;

/* ============================================================================
   V1.3.19 — RESUMO DAS CORRECOES FUTURAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.19 - RESUMO PARA F1-FIN.4'
\echo '============================================================'

WITH autoridade(table_name, schema_autoridade) AS (
    VALUES
        ('empresa', 'public'),
        ('cliente', 'public'),
        ('fornecedor', 'public'),
        ('usuario', 'public'),

        ('banco', 'financeiro'),
        ('conta_bancaria', 'financeiro'),
        ('forma_pagamento', 'financeiro'),
        ('conciliacao_bancaria', 'financeiro'),
        ('lancamento_parcela', 'financeiro'),
        ('centro_custo', 'financeiro')
),
analise AS (
    SELECT
        con.oid,
        source_ns.nspname AS source_schema,
        source.relname AS source_table,
        con.conname,
        target_ns.nspname AS target_schema,
        target.relname AS target_table,
        a.schema_autoridade

    FROM pg_constraint con

    JOIN pg_class source
        ON source.oid = con.conrelid

    JOIN pg_namespace source_ns
        ON source_ns.oid = source.relnamespace

    JOIN pg_class target
        ON target.oid = con.confrelid

    JOIN pg_namespace target_ns
        ON target_ns.oid = target.relnamespace

    JOIN autoridade a
        ON a.table_name = target.relname

    WHERE con.contype = 'f'
)
SELECT
    COUNT(*) AS fks_analisadas,

    COUNT(*) FILTER (
        WHERE target_schema = schema_autoridade
    ) AS fks_corretas,

    COUNT(*) FILTER (
        WHERE target_schema <> schema_autoridade
    ) AS fks_para_corrigir,

    CASE
        WHEN COUNT(*) FILTER (
            WHERE target_schema <> schema_autoridade
        ) = 0
        THEN 'ARQUITETURA_FK_OK'
        ELSE 'GERAR_CORRECOES_NA_V2'
    END AS decisao

FROM analise;

/* ============================================================================
   V1.3.20 — INTEGRIDADE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.20 - INTEGRIDADE DO FINANCEIRO'
\echo '============================================================'

WITH tabelas AS (
    SELECT c.oid
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relkind IN ('r', 'p')
),
sem_pk AS (
    SELECT COUNT(*) AS quantidade
    FROM tabelas t
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
)
SELECT
    (SELECT COUNT(*) FROM tabelas) AS tabelas_financeiro,
    (SELECT quantidade FROM sem_pk) AS tabelas_sem_pk,
    (
        SELECT quantidade
        FROM nao_validadas
    ) AS constraints_nao_validadas,

    CASE
        WHEN (SELECT quantidade FROM sem_pk) = 0
         AND (SELECT quantidade FROM nao_validadas) = 0
        THEN 'APROVADO'
        ELSE 'PENDENTE'
    END AS status;

/* ============================================================================
   V1.3.21 — PAINEL FINAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V1.3.21 - PAINEL FINAL'
\echo '============================================================'

WITH autoridade(table_name, schema_autoridade) AS (
    VALUES
        ('empresa', 'public'),
        ('cliente', 'public'),
        ('fornecedor', 'public'),
        ('usuario', 'public'),

        ('banco', 'financeiro'),
        ('conta_bancaria', 'financeiro'),
        ('forma_pagamento', 'financeiro'),
        ('conciliacao_bancaria', 'financeiro'),
        ('lancamento_parcela', 'financeiro'),
        ('centro_custo', 'financeiro')
),
fks_erradas AS (
    SELECT COUNT(*) AS quantidade
    FROM pg_constraint con
    JOIN pg_class target
        ON target.oid = con.confrelid
    JOIN pg_namespace target_ns
        ON target_ns.oid = target.relnamespace
    JOIN autoridade a
        ON a.table_name = target.relname
    WHERE con.contype = 'f'
      AND target_ns.nspname <> a.schema_autoridade
),
tipo_documento AS (
    SELECT
        COUNT(DISTINCT n.nspname) AS schemas
    FROM pg_class c
    JOIN pg_namespace n
        ON n.oid = c.relnamespace
    WHERE c.relname = 'tipo_documento'
      AND n.nspname IN ('public', 'financeiro')
      AND c.relkind IN ('r', 'p')
)
SELECT
    (SELECT quantidade FROM fks_erradas)
        AS fks_contrarias_arquitetura,

    (SELECT schemas FROM tipo_documento)
        AS versoes_tipo_documento,

    CASE
        WHEN (SELECT quantidade FROM fks_erradas) > 0
            THEN 'F1_FIN_4_CORRECAO_NECESSARIA'

        WHEN (SELECT schemas FROM tipo_documento) > 1
            THEN 'DECIDIR_TIPO_DOCUMENTO'

        ELSE 'CLASSIFICACAO_CONCLUIDA'
    END AS proxima_etapa;

/* ============================================================================
   ENCERRAMENTO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN MASTER V1.3 CONCLUIDA'
\echo '============================================================'
\echo ''
\echo ' REGRA ARQUITETURAL'
\echo ' -----------------------------------------------------------'
\echo ' financeiro = autoridade do dominio financeiro'
\echo ' public     = corporativo / transversal'
\echo ''
\echo ' AUTORIDADE PUBLIC'
\echo ' -----------------------------------------------------------'
\echo ' empresa'
\echo ' cliente'
\echo ' fornecedor'
\echo ' usuario'
\echo ''
\echo ' AUTORIDADE FINANCEIRO'
\echo ' -----------------------------------------------------------'
\echo ' banco'
\echo ' conta_bancaria'
\echo ' forma_pagamento'
\echo ' conciliacao_bancaria'
\echo ' lancamento_parcela'
\echo ' centro_custo'
\echo ''
\echo ' EM ANALISE'
\echo ' -----------------------------------------------------------'
\echo ' tipo_documento'
\echo ''
\echo ' NENHUMA ALTERACAO FOI EXECUTADA.'
\echo '============================================================'

ROLLBACK;
