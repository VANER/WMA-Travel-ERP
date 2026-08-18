/* ============================================================================
   WMA TRAVEL ERP
   F1-FIN.13 — CERTIFICACAO ESTRUTURAL DO MODULO FINANCEIRO

   PostgreSQL : 18.x
   Banco      : wma_travel
   Etapa      : F1-FIN.13
   Modo       : SOMENTE LEITURA / CERTIFICACAO FINAL

   REGRA ARQUITETURAL
   ------------------
   financeiro = autoridade do dominio financeiro
   public     = corporativo / transversal

   OBJETIVO
   --------
   Certificar estruturalmente o modulo Financeiro apos conclusao das etapas
   F1-FIN.01 a F1-FIN.12.

   CRITERIOS BLOQUEANTES
   ---------------------
   - Todas as tabelas do schema financeiro possuem PK.
   - Nenhuma constraint nao validada.
   - Nenhum orfao nos nucleos criticos.
   - Nenhum residuo de dados de teste F1-FIN.
   - Plano de contas estruturalmente consistente.
   - FKs financeiro -> public limitadas a entidades transversais permitidas.

   LEGADOS CONTROLADOS
   -------------------
   public.centro_custo
   public.forma_pagamento
   public.imposto
   e demais objetos public de semantica financeira identificados na F1-FIN.12.

   IMPORTANTE
   ----------
   A existencia de legados controlados NAO bloqueia a certificacao estrutural,
   desde que:
     - financeiro permaneça como autoridade;
     - nao existam falhas de integridade;
     - os legados estejam explicitamente classificados para migracao/revisao;
     - nenhuma remocao destrutiva seja feita nesta etapa.

   NENHUMA ALTERACAO DE DADOS OU ESTRUTURA E EXECUTADA.
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
\echo ' F1-FIN.13 - CERTIFICACAO ESTRUTURAL DO MODULO FINANCEIRO'
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
    CURRENT_TIMESTAMP AS certificado_em;

/* ============================================================================
   2. UNIVERSO ESTRUTURAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 2 - UNIVERSO ESTRUTURAL'
\echo '============================================================'

SELECT
    COUNT(*) FILTER (WHERE c.relkind IN ('r','p')) AS tabelas,
    COUNT(*) FILTER (WHERE c.relkind = 'S') AS sequences,
    COUNT(*) FILTER (WHERE c.relkind = 'i') AS indices
FROM pg_class c
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro';

/* ============================================================================
   3. TABELAS SEM PK
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 3 - TABELAS SEM PK'
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
   4. CONSTRAINTS NAO VALIDADAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 4 - CONSTRAINTS NAO VALIDADAS'
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
   5. FKS FINANCEIRO -> PUBLIC
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 5 - FKS FINANCEIRO -> PUBLIC'
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
        ELSE 'BLOQUEANTE_REVISAR'
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
   6. ORFAOS DOS NUCLEOS CRITICOS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 6 - ORFAOS DOS NUCLEOS CRITICOS'
\echo '============================================================'

WITH metricas AS (
    SELECT
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
        ) AS rateios_sem_lancamento,

        (
            SELECT count(*)
            FROM financeiro.rateio_centro_custo r
            LEFT JOIN financeiro.centro_custo cc
              ON cc.id_centro_custo = r.id_centro_custo
            WHERE cc.id_centro_custo IS NULL
        ) AS rateios_sem_centro
)
SELECT *
FROM metricas;

/* ============================================================================
   7. PLANO DE CONTAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 7 - PLANO DE CONTAS'
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
   8. RESIDUOS DE TESTE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 8 - RESIDUOS DE TESTE F1-FIN'
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
   9. LEGADOS CONTROLADOS PUBLIC
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 9 - LEGADOS CONTROLADOS PUBLIC'
\echo '============================================================'

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
        ) AS dependencias,
        'financeiro.centro_custo'::text AS autoridade

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
        ),
        'financeiro.forma_pagamento'

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
        ),
        'financeiro.tributo'
)
SELECT
    objeto,
    registros,
    dependencias,
    autoridade,
    CASE
        WHEN objeto = 'public.imposto'
            THEN 'CANDIDATO_MIGRACAO_REVISAR_DADOS'
        WHEN dependencias > 0
            THEN 'LEGADO_COM_DEPENDENCIAS_REQUER_PLANO'
        WHEN registros = 0
            THEN 'LEGADO_VAZIO'
        ELSE 'LEGADO_CONTROLADO_REVISAR'
    END AS classificacao
FROM legados
ORDER BY objeto;

/* ============================================================================
   10. DOCUMENTACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 10 - DOCUMENTACAO DAS TABELAS'
\echo '============================================================'

SELECT
    COUNT(*) AS tabelas,
    COUNT(*) FILTER (
        WHERE obj_description(c.oid, 'pg_class') IS NOT NULL
    ) AS documentadas,
    COUNT(*) FILTER (
        WHERE obj_description(c.oid, 'pg_class') IS NULL
    ) AS sem_comentario
FROM pg_class c
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relkind IN ('r','p');

/* ============================================================================
   11. METRICAS BLOQUEANTES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 11 - METRICAS BLOQUEANTES'
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
              AND target.relname NOT IN (
                  'empresa',
                  'cliente',
                  'fornecedor',
                  'usuario',
                  'tipo_documento'
              )
        ) AS fks_public_nao_transversais,

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
            SELECT count(*)
            FROM financeiro.classificacao
            WHERE gera_dre IS TRUE
              AND id_tipo_dre IS NULL
        ) AS dre_sem_tipo,

        (
            SELECT
                (SELECT count(*) FROM financeiro.lancamento
                 WHERE numero ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.movimentacao_bancaria
                 WHERE historico ~* 'F1-FIN')
              + (SELECT count(*) FROM financeiro.transferencia
                 WHERE codigo ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.tributo
                 WHERE codigo ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.emprestimo
                 WHERE descricao ~* 'F1-FIN')
              + (SELECT count(*) FROM financeiro.ativo_imobilizado
                 WHERE codigo ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.capital_social
                 WHERE descricao ~* 'F1-FIN')
              + (SELECT count(*) FROM financeiro.afac
                 WHERE descricao ~* 'F1-FIN')
              + (SELECT count(*) FROM financeiro.distribuicao_lucro
                 WHERE descricao ~* 'F1-FIN')
        ) AS residuos_teste
)
SELECT *
FROM metricas;

/* ============================================================================
   12. CERTIFICACAO FINAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 12 - CERTIFICACAO FINAL'
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
              AND target.relname NOT IN (
                  'empresa',
                  'cliente',
                  'fornecedor',
                  'usuario',
                  'tipo_documento'
              )
        ) AS fks_public_nao_transversais,

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
            SELECT count(*)
            FROM financeiro.classificacao
            WHERE gera_dre IS TRUE
              AND id_tipo_dre IS NULL
        ) AS dre_sem_tipo,

        (
            SELECT
                (SELECT count(*) FROM financeiro.lancamento
                 WHERE numero ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.movimentacao_bancaria
                 WHERE historico ~* 'F1-FIN')
              + (SELECT count(*) FROM financeiro.transferencia
                 WHERE codigo ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.tributo
                 WHERE codigo ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.emprestimo
                 WHERE descricao ~* 'F1-FIN')
              + (SELECT count(*) FROM financeiro.ativo_imobilizado
                 WHERE codigo ~* '^F1FIN')
              + (SELECT count(*) FROM financeiro.capital_social
                 WHERE descricao ~* 'F1-FIN')
              + (SELECT count(*) FROM financeiro.afac
                 WHERE descricao ~* 'F1-FIN')
              + (SELECT count(*) FROM financeiro.distribuicao_lucro
                 WHERE descricao ~* 'F1-FIN')
        ) AS residuos_teste
)
SELECT
    *,
    CASE
        WHEN tabelas_sem_pk = 0
         AND constraints_nao_validadas = 0
         AND fks_public_nao_transversais = 0
         AND parcelas_orfas = 0
         AND pagamentos_orfaos = 0
         AND movimentos_orfaos = 0
         AND conciliacoes_orfas = 0
         AND rateios_orfaos = 0
         AND classificacoes_sem_natureza = 0
         AND dre_sem_tipo = 0
         AND residuos_teste = 0
        THEN 'F1_FIN_13_CERTIFICADA'
        ELSE 'F1_FIN_13_REPROVADA'
    END AS status
FROM metricas;

/* ============================================================================
   13. VALIDACAO BLOQUEANTE DA CERTIFICACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 13 - VALIDACAO BLOQUEANTE'
\echo '============================================================'

DO $$
DECLARE
    v_total bigint;
BEGIN
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
        )
        +
        (
            SELECT count(*)
            FROM pg_constraint con
            JOIN pg_class c
              ON c.oid = con.conrelid
            JOIN pg_namespace n
              ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND NOT con.convalidated
        )
        +
        (
            SELECT count(*)
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
              AND target.relname NOT IN (
                  'empresa',
                  'cliente',
                  'fornecedor',
                  'usuario',
                  'tipo_documento'
              )
        )
        +
        (
            SELECT count(*)
            FROM financeiro.lancamento_parcela p
            LEFT JOIN financeiro.lancamento l
              ON l.id_lancamento = p.id_lancamento
            WHERE l.id_lancamento IS NULL
        )
        +
        (
            SELECT count(*)
            FROM financeiro.pagamento pg
            LEFT JOIN financeiro.lancamento_parcela p
              ON p.id_parcela = pg.id_parcela
            WHERE p.id_parcela IS NULL
        )
        +
        (
            SELECT count(*)
            FROM financeiro.movimentacao_bancaria m
            LEFT JOIN financeiro.conta_bancaria cb
              ON cb.id_conta_bancaria = m.id_conta_bancaria
            WHERE cb.id_conta_bancaria IS NULL
        )
        +
        (
            SELECT count(*)
            FROM financeiro.conciliacao_bancaria c
            LEFT JOIN financeiro.movimentacao_bancaria m
              ON m.id_movimento = c.id_movimento
            WHERE m.id_movimento IS NULL
        )
        +
        (
            SELECT count(*)
            FROM financeiro.rateio_centro_custo r
            LEFT JOIN financeiro.lancamento l
              ON l.id_lancamento = r.id_lancamento
            WHERE l.id_lancamento IS NULL
        )
        +
        (
            SELECT count(*)
            FROM financeiro.classificacao
            WHERE id_natureza_financeira IS NULL
        )
        +
        (
            SELECT count(*)
            FROM financeiro.classificacao
            WHERE gera_dre IS TRUE
              AND id_tipo_dre IS NULL
        )
    INTO v_total;

    IF v_total <> 0 THEN
        RAISE EXCEPTION
            'F1-FIN.13 REPROVADA: % bloqueantes estruturais encontrados.',
            v_total;
    END IF;
END
$$;

/* ============================================================================
   ENCERRAMENTO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.13 - CERTIFICACAO ESTRUTURAL CONCLUIDA'
\echo '============================================================'
\echo ' MODULO FINANCEIRO ............... CERTIFICADO ESTRUTURALMENTE'
\echo ' SCHEMA AUTORITATIVO ............. financeiro'
\echo ' PUBLIC .......................... CORPORATIVO / TRANSVERSAL'
\echo ' LEGADOS PUBLIC .................. CONTROLADOS / NAO BLOQUEANTES'
\echo ' ALTERACOES EXECUTADAS ........... NENHUMA'
\echo '============================================================'

ROLLBACK;

\echo ''
\echo '============================================================'
\echo ' ROLLBACK CONCLUIDO'
\echo ' F1-FIN.13 FINALIZADA'
\echo ' MODULO FINANCEIRO CERTIFICADO'
\echo '============================================================'
