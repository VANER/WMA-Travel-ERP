/* ============================================================================
   WMA TRAVEL ERP
   F1-FIN.12 — AUDITORIA DE INTEGRIDADE FINANCEIRA

   PostgreSQL : 18.x
   Banco      : wma_travel
   Etapa      : F1-FIN.12
   Modo       : SOMENTE LEITURA / AUDITORIA FINAL DO MODULO

   REGRA ARQUITETURAL
   ------------------
   financeiro = autoridade do dominio financeiro
   public     = corporativo / transversal

   OBJETIVO
   --------
   Auditar integralmente o modulo financeiro antes da certificacao F1-FIN.13:

     1. Universo de objetos financeiros.
     2. Tabelas sem PK.
     3. Constraints nao validadas.
     4. FKs e orfaos.
     5. Sobreposicoes entre financeiro e public.
     6. Objetos legados / candidatos a migracao.
     7. Documentacao.
     8. Indices.
     9. Residuos de dados de teste.
    10. Consistencia dos nucleos F1-FIN.5 a F1-FIN.11.
    11. Classificacao final:
        - OK
        - REVISAR
        - LEGADO
        - CANDIDATO_MIGRACAO
        - BLOQUEANTE
    12. Status preliminar para F1-FIN.13.

   IMPORTANTE
   ----------
   Nenhum CREATE / ALTER / DROP / INSERT / UPDATE / DELETE.
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
\echo ' F1-FIN.12 - AUDITORIA DE INTEGRIDADE FINANCEIRA'
\echo ' MODO: SOMENTE LEITURA'
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
   2. UNIVERSO DO SCHEMA FINANCEIRO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 2 - UNIVERSO DO SCHEMA FINANCEIRO'
\echo '============================================================'

SELECT
    CASE c.relkind
        WHEN 'r' THEN 'TABLE'
        WHEN 'p' THEN 'PARTITIONED TABLE'
        WHEN 'v' THEN 'VIEW'
        WHEN 'm' THEN 'MATERIALIZED VIEW'
        WHEN 'S' THEN 'SEQUENCE'
        ELSE c.relkind::text
    END AS object_type,
    COUNT(*) AS quantidade
FROM pg_class c
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
GROUP BY c.relkind
ORDER BY object_type;

/* ============================================================================
   3. INVENTARIO DE TABELAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 3 - TABELAS FINANCEIRAS'
\echo '============================================================'

SELECT
    c.relname AS tabela,
    obj_description(c.oid, 'pg_class') AS comentario
FROM pg_class c
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relkind IN ('r','p')
ORDER BY c.relname;

/* ============================================================================
   4. TABELAS SEM PK
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 4 - TABELAS SEM PK'
\echo '============================================================'

SELECT
    c.relname AS tabela
FROM pg_class c
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relkind IN ('r','p')
  AND NOT EXISTS (
      SELECT 1
      FROM pg_constraint con
      WHERE con.conrelid = c.oid
        AND con.contype = 'p'
  )
ORDER BY c.relname;

/* ============================================================================
   5. CONSTRAINTS NAO VALIDADAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 5 - CONSTRAINTS NAO VALIDADAS'
\echo '============================================================'

SELECT
    c.relname AS tabela,
    con.conname AS constraint_name,
    con.contype,
    pg_get_constraintdef(con.oid, TRUE) AS definition
FROM pg_constraint con
JOIN pg_class c
  ON c.oid = con.conrelid
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND NOT con.convalidated
ORDER BY c.relname, con.conname;

/* ============================================================================
   6. FKS DO SCHEMA FINANCEIRO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 6 - FKS DO SCHEMA FINANCEIRO'
\echo '============================================================'

SELECT
    source.relname AS tabela_origem,
    con.conname AS fk_name,
    target_ns.nspname AS schema_destino,
    target.relname AS tabela_destino,
    pg_get_constraintdef(con.oid, TRUE) AS definition,
    con.convalidated AS validated
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
ORDER BY source.relname, con.conname;

/* ============================================================================
   7. FKS PARA PUBLIC — TRANSVERSALIDADE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 7 - FKS FINANCEIRO -> PUBLIC'
\echo '============================================================'

SELECT
    source.relname AS tabela_origem,
    con.conname AS fk_name,
    target.relname AS tabela_public,
    CASE
        WHEN target.relname IN (
            'empresa',
            'cliente',
            'fornecedor',
            'usuario',
            'tipo_documento'
        )
        THEN 'OK_TRANSVERSAL'
        ELSE 'REVISAR'
    END AS classificacao
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
  AND target_ns.nspname = 'public'
ORDER BY source.relname, target.relname;

/* ============================================================================
   8. SOBREPOSICOES DE NOMES FINANCEIRO X PUBLIC
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 8 - SOBREPOSICOES FINANCEIRO X PUBLIC'
\echo '============================================================'

WITH f AS (
    SELECT c.relname
    FROM pg_class c
    JOIN pg_namespace n
      ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relkind IN ('r','p','v','m')
),
p AS (
    SELECT c.relname
    FROM pg_class c
    JOIN pg_namespace n
      ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relkind IN ('r','p','v','m')
)
SELECT
    f.relname AS objeto,
    CASE
        WHEN f.relname IN (
            'banco',
            'conta_bancaria',
            'centro_custo',
            'forma_pagamento',
            'conciliacao_bancaria',
            'lancamento_parcela',
            'capital_social',
            'afac',
            'pro_labore',
            'distribuicao_lucro',
            'tributo',
            'ativo_imobilizado',
            'emprestimo',
            'emprestimo_parcela',
            'depreciacao_ativo'
        )
        THEN 'FINANCEIRO_AUTORIDADE'
        ELSE 'REVISAR'
    END AS classificacao
FROM f
JOIN p
  ON p.relname = f.relname
ORDER BY f.relname;

/* ============================================================================
   9. OBJETOS PUBLIC COM SEMANTICA FINANCEIRA
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 9 - OBJETOS PUBLIC COM SEMANTICA FINANCEIRA'
\echo '============================================================'

SELECT
    c.relname AS objeto_public,
    CASE c.relkind
        WHEN 'r' THEN 'TABLE'
        WHEN 'p' THEN 'PARTITIONED TABLE'
        WHEN 'v' THEN 'VIEW'
        WHEN 'm' THEN 'MATERIALIZED VIEW'
        ELSE c.relkind::text
    END AS object_type,
    CASE
        WHEN c.relname IN (
            'empresa',
            'cliente',
            'fornecedor',
            'usuario',
            'tipo_documento'
        )
        THEN 'PUBLIC_TRANSVERSAL'

        WHEN c.relname ~* '(banco|conta_bancaria|centro_custo|forma_pagamento|conciliacao|lancamento_financeiro|aporte_capital|pro_labore|distribuicao_lucros|imposto|ativo_imobilizado|depreciacao)'
        THEN 'LEGADO_OU_CANDIDATO_MIGRACAO'

        ELSE 'REVISAR'
    END AS classificacao
FROM pg_class c
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind IN ('r','p','v','m')
  AND c.relname ~* '(finance|banco|conta|centro_custo|forma_pagamento|conciliacao|lancamento|capital|afac|pro.?labore|lucro|imposto|tribut|imobil|depreci)'
ORDER BY c.relname;

/* ============================================================================
   10. CONTAGENS DAS SOBREPOSICOES CONHECIDAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 10 - CONTAGENS DE OBJETOS LEGADOS / SOBREPOSTOS'
\echo '============================================================'

SELECT
    'public.banco' AS objeto,
    CASE WHEN to_regclass('public.banco') IS NOT NULL
         THEN (SELECT count(*) FROM public.banco)
         ELSE NULL END AS registros
UNION ALL
SELECT
    'public.conta_bancaria',
    CASE WHEN to_regclass('public.conta_bancaria') IS NOT NULL
         THEN (SELECT count(*) FROM public.conta_bancaria)
         ELSE NULL END
UNION ALL
SELECT
    'public.centro_custo',
    CASE WHEN to_regclass('public.centro_custo') IS NOT NULL
         THEN (SELECT count(*) FROM public.centro_custo)
         ELSE NULL END
UNION ALL
SELECT
    'public.forma_pagamento',
    CASE WHEN to_regclass('public.forma_pagamento') IS NOT NULL
         THEN (SELECT count(*) FROM public.forma_pagamento)
         ELSE NULL END
UNION ALL
SELECT
    'public.pro_labore',
    CASE WHEN to_regclass('public.pro_labore') IS NOT NULL
         THEN (SELECT count(*) FROM public.pro_labore)
         ELSE NULL END
UNION ALL
SELECT
    'public.distribuicao_lucros',
    CASE WHEN to_regclass('public.distribuicao_lucros') IS NOT NULL
         THEN (SELECT count(*) FROM public.distribuicao_lucros)
         ELSE NULL END
UNION ALL
SELECT
    'public.aporte_capital',
    CASE WHEN to_regclass('public.aporte_capital') IS NOT NULL
         THEN (SELECT count(*) FROM public.aporte_capital)
         ELSE NULL END
UNION ALL
SELECT
    'public.imposto',
    CASE WHEN to_regclass('public.imposto') IS NOT NULL
         THEN (SELECT count(*) FROM public.imposto)
         ELSE NULL END
UNION ALL
SELECT
    'public.ativo_imobilizado',
    CASE WHEN to_regclass('public.ativo_imobilizado') IS NOT NULL
         THEN (SELECT count(*) FROM public.ativo_imobilizado)
         ELSE NULL END
UNION ALL
SELECT
    'public.depreciacao',
    CASE WHEN to_regclass('public.depreciacao') IS NOT NULL
         THEN (SELECT count(*) FROM public.depreciacao)
         ELSE NULL END;

/* ============================================================================
   11. DOCUMENTACAO DE TABELAS FINANCEIRAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 11 - DOCUMENTACAO DAS TABELAS'
\echo '============================================================'

SELECT
    c.relname AS tabela,
    CASE
        WHEN obj_description(c.oid, 'pg_class') IS NULL
            THEN 'SEM_COMENTARIO'
        ELSE 'DOCUMENTADA'
    END AS status
FROM pg_class c
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relkind IN ('r','p')
ORDER BY c.relname;

/* ============================================================================
   12. INDICES POR TABELA
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 12 - INDICES POR TABELA'
\echo '============================================================'

SELECT
    t.relname AS tabela,
    COUNT(i.indexrelid) AS indices
FROM pg_class t
JOIN pg_namespace n
  ON n.oid = t.relnamespace
LEFT JOIN pg_index i
  ON i.indrelid = t.oid
WHERE n.nspname = 'financeiro'
  AND t.relkind IN ('r','p')
GROUP BY t.relname
ORDER BY t.relname;

/* ============================================================================
   13. RESIDUOS DE TESTES F1-FIN
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 13 - RESIDUOS DE DADOS DE TESTE'
\echo '============================================================'

WITH residuos AS (
    SELECT 'lancamento' AS origem, count(*) AS quantidade
    FROM financeiro.lancamento
    WHERE numero ~* '^F1FIN'

    UNION ALL

    SELECT 'movimentacao_bancaria', count(*)
    FROM financeiro.movimentacao_bancaria
    WHERE historico ~* 'F1-FIN'

    UNION ALL

    SELECT 'transferencia', count(*)
    FROM financeiro.transferencia
    WHERE codigo ~* '^F1FIN'

    UNION ALL

    SELECT 'tributo', count(*)
    FROM financeiro.tributo
    WHERE codigo ~* '^F1FIN'

    UNION ALL

    SELECT 'emprestimo', count(*)
    FROM financeiro.emprestimo
    WHERE descricao ~* 'F1-FIN'

    UNION ALL

    SELECT 'ativo_imobilizado', count(*)
    FROM financeiro.ativo_imobilizado
    WHERE codigo ~* '^F1FIN'

    UNION ALL

    SELECT 'capital_social', count(*)
    FROM financeiro.capital_social
    WHERE descricao ~* 'F1-FIN'

    UNION ALL

    SELECT 'afac', count(*)
    FROM financeiro.afac
    WHERE descricao ~* 'F1-FIN'

    UNION ALL

    SELECT 'distribuicao_lucro', count(*)
    FROM financeiro.distribuicao_lucro
    WHERE descricao ~* 'F1-FIN'
)
SELECT *
FROM residuos
ORDER BY origem;

/* ============================================================================
   14. NUCLEO PLANO DE CONTAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 14 - PLANO DE CONTAS'
\echo '============================================================'

SELECT
    (SELECT count(*) FROM financeiro.grupo) AS grupos,
    (SELECT count(*) FROM financeiro.categoria) AS categorias,
    (SELECT count(*) FROM financeiro.subcategoria) AS subcategorias,
    (SELECT count(*) FROM financeiro.classificacao) AS classificacoes,
    (SELECT count(*) FROM financeiro.conta) AS contas,
    (
        SELECT count(*)
        FROM financeiro.classificacao
        WHERE id_natureza_financeira IS NULL
    ) AS classificacoes_sem_natureza,
    (
        SELECT count(*)
        FROM financeiro.classificacao
        WHERE gera_dre IS TRUE
          AND id_tipo_dre IS NULL
    ) AS dre_sem_tipo;

/* ============================================================================
   15. NUCLEO AP/AR
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 15 - AP/AR'
\echo '============================================================'

SELECT
    (SELECT count(*) FROM financeiro.lancamento) AS lancamentos,
    (SELECT count(*) FROM financeiro.lancamento_parcela) AS parcelas,
    (SELECT count(*) FROM financeiro.pagamento) AS pagamentos,
    (
        SELECT count(*)
        FROM financeiro.lancamento_parcela p
        LEFT JOIN financeiro.lancamento l
          ON l.id_lancamento = p.id_lancamento
        WHERE l.id_lancamento IS NULL
    ) AS parcelas_orfas,
    (
        SELECT count(*)
        FROM financeiro.pagamento pg
        LEFT JOIN financeiro.lancamento_parcela p
          ON p.id_parcela = pg.id_parcela
        WHERE p.id_parcela IS NULL
    ) AS pagamentos_orfaos;

/* ============================================================================
   16. NUCLEO BANCARIO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 16 - NUCLEO BANCARIO'
\echo '============================================================'

SELECT
    (SELECT count(*) FROM financeiro.banco) AS bancos,
    (SELECT count(*) FROM financeiro.conta_bancaria) AS contas_bancarias,
    (SELECT count(*) FROM financeiro.movimentacao_bancaria) AS movimentacoes,
    (SELECT count(*) FROM financeiro.transferencia) AS transferencias,
    (SELECT count(*) FROM financeiro.cartao) AS cartoes,
    (SELECT count(*) FROM financeiro.fatura_cartao) AS faturas,
    (
        SELECT count(*)
        FROM financeiro.movimentacao_bancaria m
        LEFT JOIN financeiro.conta_bancaria cb
          ON cb.id_conta_bancaria = m.id_conta_bancaria
        WHERE cb.id_conta_bancaria IS NULL
    ) AS movimentos_orfaos;

/* ============================================================================
   17. RATEIOS E CENTROS DE CUSTO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 17 - RATEIOS E CENTROS DE CUSTO'
\echo '============================================================'

SELECT
    (SELECT count(*) FROM financeiro.centro_custo) AS centros_custo,
    (SELECT count(*) FROM financeiro.rateio_centro_custo) AS rateios,
    (
        SELECT count(*)
        FROM financeiro.rateio_centro_custo r
        LEFT JOIN financeiro.lancamento l
          ON l.id_lancamento = r.id_lancamento
        WHERE l.id_lancamento IS NULL
    ) AS rateios_sem_lancamento,
    (
        SELECT count(*)
        FROM financeiro.rateio_centro_custo r
        LEFT JOIN financeiro.centro_custo cc
          ON cc.id_centro_custo = r.id_centro_custo
        WHERE cc.id_centro_custo IS NULL
    ) AS rateios_sem_centro;

/* ============================================================================
   18. CONCILIACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 18 - CONCILIACAO'
\echo '============================================================'

SELECT
    (SELECT count(*) FROM financeiro.conciliacao_bancaria) AS conciliacoes,
    (
        SELECT count(*)
        FROM financeiro.conciliacao_bancaria c
        LEFT JOIN financeiro.movimentacao_bancaria m
          ON m.id_movimento = c.id_movimento
        WHERE m.id_movimento IS NULL
    ) AS conciliacoes_orfas;

/* ============================================================================
   19. CAPITAL / AFAC / PRO-LABORE / LUCROS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 19 - CAPITAL / AFAC / PRO-LABORE / LUCROS'
\echo '============================================================'

SELECT
    (SELECT count(*) FROM financeiro.capital_social) AS capital_social,
    (SELECT count(*) FROM financeiro.afac) AS afac,
    (SELECT count(*) FROM financeiro.pro_labore) AS pro_labore,
    (SELECT count(*) FROM financeiro.distribuicao_lucro) AS distribuicao_lucro;

/* ============================================================================
   20. TRIBUTOS / EMPRESTIMOS / IMOBILIZADO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 20 - TRIBUTOS / EMPRESTIMOS / IMOBILIZADO'
\echo '============================================================'

SELECT
    (SELECT count(*) FROM financeiro.tributo) AS tributos,
    (SELECT count(*) FROM financeiro.emprestimo) AS emprestimos,
    (SELECT count(*) FROM financeiro.emprestimo_parcela) AS parcelas_emprestimo,
    (SELECT count(*) FROM financeiro.ativo_imobilizado) AS ativos_imobilizados,
    (SELECT count(*) FROM financeiro.depreciacao_ativo) AS depreciacoes;

/* ============================================================================
   21. RESUMO BLOQUEANTE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 21 - RESUMO BLOQUEANTE'
\echo '============================================================'

WITH metricas AS (
    SELECT
        (
            SELECT count(*)
            FROM pg_class c
            JOIN pg_namespace n
              ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relkind IN ('r','p')
              AND NOT EXISTS (
                  SELECT 1
                  FROM pg_constraint con
                  WHERE con.conrelid = c.oid
                    AND con.contype = 'p'
              )
        ) AS tabelas_sem_pk,

        (
            SELECT count(*)
            FROM pg_constraint con
            JOIN pg_class c
              ON c.oid = con.conrelid
            JOIN pg_namespace n
              ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND NOT con.convalidated
        ) AS constraints_nao_validadas,

        (
            SELECT count(*)
            FROM financeiro.lancamento_parcela p
            LEFT JOIN financeiro.lancamento l
              ON l.id_lancamento = p.id_lancamento
            WHERE l.id_lancamento IS NULL
        ) AS parcelas_orfas,

        (
            SELECT count(*)
            FROM financeiro.pagamento pg
            LEFT JOIN financeiro.lancamento_parcela p
              ON p.id_parcela = pg.id_parcela
            WHERE p.id_parcela IS NULL
        ) AS pagamentos_orfaos,

        (
            SELECT count(*)
            FROM financeiro.movimentacao_bancaria m
            LEFT JOIN financeiro.conta_bancaria cb
              ON cb.id_conta_bancaria = m.id_conta_bancaria
            WHERE cb.id_conta_bancaria IS NULL
        ) AS movimentos_orfaos,

        (
            SELECT count(*)
            FROM financeiro.conciliacao_bancaria c
            LEFT JOIN financeiro.movimentacao_bancaria m
              ON m.id_movimento = c.id_movimento
            WHERE m.id_movimento IS NULL
        ) AS conciliacoes_orfas,

        (
            SELECT count(*)
            FROM financeiro.rateio_centro_custo r
            LEFT JOIN financeiro.lancamento l
              ON l.id_lancamento = r.id_lancamento
            WHERE l.id_lancamento IS NULL
        ) AS rateios_orfaos,

        (
            SELECT count(*)
            FROM financeiro.classificacao
            WHERE id_natureza_financeira IS NULL
        ) AS classificacoes_sem_natureza,

        (
            SELECT
                (SELECT count(*) FROM financeiro.lancamento WHERE numero ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.movimentacao_bancaria WHERE historico ~* 'F1-FIN')
              + (SELECT count(*) FROM financeiro.transferencia WHERE codigo ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.tributo WHERE codigo ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.emprestimo WHERE descricao ~* 'F1-FIN')
              + (SELECT count(*) FROM financeiro.ativo_imobilizado WHERE codigo ~* '^F1FIN')
        ) AS residuos_teste
)
SELECT *
FROM metricas;

/* ============================================================================
   22. SOBREPOSICOES NAO BLOQUEANTES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 22 - SOBREPOSICOES NAO BLOQUEANTES'
\echo '============================================================'

SELECT
    objeto,
    registros,
    CASE
        WHEN registros IS NULL THEN 'NAO_EXISTE'
        WHEN registros = 0 THEN 'LEGADO_VAZIO'
        ELSE 'LEGADO_COM_DADOS_REVISAR'
    END AS status
FROM (
    SELECT
        'public.banco' AS objeto,
        CASE WHEN to_regclass('public.banco') IS NOT NULL
             THEN (SELECT count(*) FROM public.banco)
             ELSE NULL END AS registros

    UNION ALL
    SELECT
        'public.conta_bancaria',
        CASE WHEN to_regclass('public.conta_bancaria') IS NOT NULL
             THEN (SELECT count(*) FROM public.conta_bancaria)
             ELSE NULL END

    UNION ALL
    SELECT
        'public.pro_labore',
        CASE WHEN to_regclass('public.pro_labore') IS NOT NULL
             THEN (SELECT count(*) FROM public.pro_labore)
             ELSE NULL END

    UNION ALL
    SELECT
        'public.distribuicao_lucros',
        CASE WHEN to_regclass('public.distribuicao_lucros') IS NOT NULL
             THEN (SELECT count(*) FROM public.distribuicao_lucros)
             ELSE NULL END

    UNION ALL
    SELECT
        'public.aporte_capital',
        CASE WHEN to_regclass('public.aporte_capital') IS NOT NULL
             THEN (SELECT count(*) FROM public.aporte_capital)
             ELSE NULL END

    UNION ALL
    SELECT
        'public.imposto',
        CASE WHEN to_regclass('public.imposto') IS NOT NULL
             THEN (SELECT count(*) FROM public.imposto)
             ELSE NULL END

    UNION ALL
    SELECT
        'public.ativo_imobilizado',
        CASE WHEN to_regclass('public.ativo_imobilizado') IS NOT NULL
             THEN (SELECT count(*) FROM public.ativo_imobilizado)
             ELSE NULL END

    UNION ALL
    SELECT
        'public.depreciacao',
        CASE WHEN to_regclass('public.depreciacao') IS NOT NULL
             THEN (SELECT count(*) FROM public.depreciacao)
             ELSE NULL END
) x
ORDER BY objeto;

/* ============================================================================
   22.1 RECONCILIACAO DOS LEGADOS COM DADOS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 22.1 - RECONCILIACAO DE LEGADOS COM DADOS'
\echo ' MARCADOR: F1_FIN_12_RECONCILIACAO_ATIVA'
\echo '============================================================'

\echo ''
\echo '--- 22.1.1 CONTAGENS PUBLIC X FINANCEIRO ---'

SELECT
    'centro_custo' AS dominio,
    (SELECT count(*) FROM public.centro_custo) AS public_registros,
    (SELECT count(*) FROM financeiro.centro_custo) AS financeiro_registros,
    'financeiro.centro_custo' AS autoridade

UNION ALL

SELECT
    'forma_pagamento',
    (SELECT count(*) FROM public.forma_pagamento),
    (SELECT count(*) FROM financeiro.forma_pagamento),
    'financeiro.forma_pagamento'

UNION ALL

SELECT
    'imposto/tributo',
    (SELECT count(*) FROM public.imposto),
    (SELECT count(*) FROM financeiro.tributo),
    'financeiro.tributo'

ORDER BY dominio;

\echo ''
\echo '--- 22.1.2 DEPENDENCIAS DOS LEGADOS PUBLIC ---'

SELECT
    src_ns.nspname AS schema_origem,
    src.relname AS tabela_origem,
    con.conname AS fk_name,
    dst.relname AS tabela_public_legada,
    pg_get_constraintdef(con.oid, TRUE) AS definition
FROM pg_constraint con
JOIN pg_class src
  ON src.oid = con.conrelid
JOIN pg_namespace src_ns
  ON src_ns.oid = src.relnamespace
JOIN pg_class dst
  ON dst.oid = con.confrelid
JOIN pg_namespace dst_ns
  ON dst_ns.oid = dst.relnamespace
WHERE con.contype = 'f'
  AND dst_ns.nspname = 'public'
  AND dst.relname IN (
      'centro_custo',
      'forma_pagamento',
      'imposto'
  )
ORDER BY
    dst.relname,
    src_ns.nspname,
    src.relname,
    con.conname;

\echo ''
\echo '--- 22.1.3 PUBLIC.CENTRO_CUSTO ---'

SELECT to_jsonb(x) AS registro
FROM public.centro_custo x
ORDER BY to_jsonb(x)::text;

\echo ''
\echo '--- 22.1.4 FINANCEIRO.CENTRO_CUSTO ---'

SELECT to_jsonb(x) AS registro
FROM financeiro.centro_custo x
ORDER BY to_jsonb(x)::text;

\echo ''
\echo '--- 22.1.5 PUBLIC.FORMA_PAGAMENTO ---'

SELECT to_jsonb(x) AS registro
FROM public.forma_pagamento x
ORDER BY to_jsonb(x)::text;

\echo ''
\echo '--- 22.1.6 FINANCEIRO.FORMA_PAGAMENTO ---'

SELECT to_jsonb(x) AS registro
FROM financeiro.forma_pagamento x
ORDER BY to_jsonb(x)::text;

\echo ''
\echo '--- 22.1.7 PUBLIC.IMPOSTO ---'

SELECT to_jsonb(x) AS registro
FROM public.imposto x
ORDER BY to_jsonb(x)::text;

\echo ''
\echo '--- 22.1.8 FINANCEIRO.TRIBUTO ---'

SELECT to_jsonb(x) AS registro
FROM financeiro.tributo x
ORDER BY to_jsonb(x)::text;

\echo ''
\echo '--- 22.1.9 CLASSIFICACAO PARA DECISAO ---'

WITH legados AS (

    SELECT
        'public.centro_custo'::text AS objeto,
        (SELECT count(*) FROM public.centro_custo) AS registros,
        (
            SELECT count(*)
            FROM pg_constraint con
            JOIN pg_class dst
              ON dst.oid = con.confrelid
            JOIN pg_namespace n
              ON n.oid = dst.relnamespace
            WHERE con.contype = 'f'
              AND n.nspname = 'public'
              AND dst.relname = 'centro_custo'
        ) AS dependencias

    UNION ALL

    SELECT
        'public.forma_pagamento',
        (SELECT count(*) FROM public.forma_pagamento),
        (
            SELECT count(*)
            FROM pg_constraint con
            JOIN pg_class dst
              ON dst.oid = con.confrelid
            JOIN pg_namespace n
              ON n.oid = dst.relnamespace
            WHERE con.contype = 'f'
              AND n.nspname = 'public'
              AND dst.relname = 'forma_pagamento'
        )

    UNION ALL

    SELECT
        'public.imposto',
        (SELECT count(*) FROM public.imposto),
        (
            SELECT count(*)
            FROM pg_constraint con
            JOIN pg_class dst
              ON dst.oid = con.confrelid
            JOIN pg_namespace n
              ON n.oid = dst.relnamespace
            WHERE con.contype = 'f'
              AND n.nspname = 'public'
              AND dst.relname = 'imposto'
        )
)

SELECT
    objeto,
    registros,
    dependencias,
    CASE
        WHEN registros = 0
         AND dependencias = 0
            THEN 'LEGADO_VAZIO_SEM_DEPENDENCIA'

        WHEN registros > 0
         AND dependencias = 0
            THEN 'CANDIDATO_MIGRACAO_REVISAR_DADOS'

        WHEN dependencias > 0
            THEN 'LEGADO_COM_DEPENDENCIAS_REQUER_PLANO'

        ELSE 'REVISAR'
    END AS classificacao
FROM legados
ORDER BY objeto;

/* ============================================================================
   22.2 RESUMO DA RECONCILIACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 22.2 - RESUMO DA RECONCILIACAO'
\echo '============================================================'

SELECT
    (SELECT count(*) FROM public.centro_custo)
        AS public_centro_custo,

    (SELECT count(*) FROM financeiro.centro_custo)
        AS financeiro_centro_custo,

    (SELECT count(*) FROM public.forma_pagamento)
        AS public_forma_pagamento,

    (SELECT count(*) FROM financeiro.forma_pagamento)
        AS financeiro_forma_pagamento,

    (SELECT count(*) FROM public.imposto)
        AS public_imposto,

    (SELECT count(*) FROM financeiro.tributo)
        AS financeiro_tributo,

    'RECONCILIACAO_EXECUTADA_SEM_ALTERACAO'
        AS status;

/* ============================================================================
   23. CERTIFICACAO PRELIMINAR F1-FIN.12
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 23 - CERTIFICACAO F1-FIN.12'
\echo '============================================================'

WITH metricas AS (
    SELECT
        (
            SELECT count(*)
            FROM pg_class c
            JOIN pg_namespace n
              ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relkind IN ('r','p')
              AND NOT EXISTS (
                  SELECT 1
                  FROM pg_constraint con
                  WHERE con.conrelid = c.oid
                    AND con.contype = 'p'
              )
        ) AS tabelas_sem_pk,

        (
            SELECT count(*)
            FROM pg_constraint con
            JOIN pg_class c
              ON c.oid = con.conrelid
            JOIN pg_namespace n
              ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND NOT con.convalidated
        ) AS constraints_nao_validadas,

        (
            SELECT count(*)
            FROM financeiro.lancamento_parcela p
            LEFT JOIN financeiro.lancamento l
              ON l.id_lancamento = p.id_lancamento
            WHERE l.id_lancamento IS NULL
        ) AS parcelas_orfas,

        (
            SELECT count(*)
            FROM financeiro.pagamento pg
            LEFT JOIN financeiro.lancamento_parcela p
              ON p.id_parcela = pg.id_parcela
            WHERE p.id_parcela IS NULL
        ) AS pagamentos_orfaos,

        (
            SELECT count(*)
            FROM financeiro.movimentacao_bancaria m
            LEFT JOIN financeiro.conta_bancaria cb
              ON cb.id_conta_bancaria = m.id_conta_bancaria
            WHERE cb.id_conta_bancaria IS NULL
        ) AS movimentos_orfaos,

        (
            SELECT count(*)
            FROM financeiro.conciliacao_bancaria c
            LEFT JOIN financeiro.movimentacao_bancaria m
              ON m.id_movimento = c.id_movimento
            WHERE m.id_movimento IS NULL
        ) AS conciliacoes_orfas,

        (
            SELECT count(*)
            FROM financeiro.rateio_centro_custo r
            LEFT JOIN financeiro.lancamento l
              ON l.id_lancamento = r.id_lancamento
            WHERE l.id_lancamento IS NULL
        ) AS rateios_orfaos,

        (
            SELECT count(*)
            FROM financeiro.classificacao
            WHERE id_natureza_financeira IS NULL
        ) AS classificacoes_sem_natureza,

        (
            SELECT
                (SELECT count(*) FROM financeiro.lancamento WHERE numero ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.movimentacao_bancaria WHERE historico ~* 'F1-FIN')
              + (SELECT count(*) FROM financeiro.transferencia WHERE codigo ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.tributo WHERE codigo ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.emprestimo WHERE descricao ~* 'F1-FIN')
              + (SELECT count(*) FROM financeiro.ativo_imobilizado WHERE codigo ~* '^F1FIN')
        ) AS residuos_teste
)
SELECT
    *,
    CASE
        WHEN tabelas_sem_pk = 0
         AND constraints_nao_validadas = 0
         AND parcelas_orfas = 0
         AND pagamentos_orfaos = 0
         AND movimentos_orfaos = 0
         AND conciliacoes_orfas = 0
         AND rateios_orfaos = 0
         AND classificacoes_sem_natureza = 0
         AND residuos_teste = 0
        THEN 'F1_FIN_12_APROVADA'
        ELSE 'F1_FIN_12_PENDENTE'
    END AS status
FROM metricas;

/* ============================================================================
   ENCERRAMENTO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.12 CONCLUIDA'
\echo '============================================================'
\echo ' NENHUMA ALTERACAO FOI EXECUTADA.'
\echo ' SE STATUS = F1_FIN_12_APROVADA:'
\echo '   PROXIMA ETAPA = F1-FIN.13 - CERTIFICACAO ESTRUTURAL FINAL'
\echo ' SE STATUS = F1_FIN_12_PENDENTE:'
\echo '   CORRIGIR SOMENTE OS BLOQUEANTES APONTADOS'
\echo '============================================================'

ROLLBACK;

