/* ============================================================================
   WMA TRAVEL ERP
   F1-FIN MASTER V3.1 — COMPLEMENTACAO DO PLANO DE CONTAS

   PostgreSQL : 18.x
   Banco      : wma_travel
   Etapa      : F1-FIN.5
   Modo       : CORRECAO CONTROLADA / TRANSACIONAL

   REGRA ARQUITETURAL
   ------------------
   financeiro = autoridade do dominio financeiro
   public     = corporativo / transversal

   OBJETIVO
   --------
   Completar a cadeia ja existente:

       grupo
         -> categoria
           -> subcategoria
             -> classificacao
               -> conta

   ESTADO VALIDADO PELA V3
   -----------------------
   grupo          : 5
   categoria      : 13
   subcategoria   : 23
   classificacao  : 0
   conta          : 0
   lancamento     : 0

   LACUNA ADICIONAL IDENTIFICADA
   -----------------------------
   financeiro.classificacao possui:
       id_natureza_financeira
       id_tipo_dre

   mas a estrutura auditada nao possui FKs efetivas desses campos para
   tabelas de dominio. Esta V3.1 cria dominios financeiros proprios e
   adiciona as FKs de forma controlada.

   ESCOPO
   ------
   1. Pre-validar a estrutura existente.
   2. Criar, se ausentes:
        financeiro.natureza_financeira
        financeiro.tipo_dre
   3. Popular dominios minimos.
   4. Adicionar FKs reais em financeiro.classificacao.
   5. Criar 1 classificacao minima para cada uma das 23 subcategorias.
   6. Criar 1 conta analitica minima para cada classificacao.
   7. Preservar grupos/categorias/subcategorias existentes.
   8. Validar integridade e completude.
   9. COMMIT somente se todas as validacoes forem aprovadas.

   SEGURANCA
   ---------
   - Transacao unica.
   - ON_ERROR_STOP.
   - Sem DROP.
   - Sem CASCADE.
   - Sem UPDATE destrutivo.
   - Idempotente para seeds e classificacoes/contas.
   - Aborta em qualquer divergencia estrutural critica.
   ============================================================================ */

\set ON_ERROR_STOP on
\pset pager off
\pset null '(NULL)'
\timing on

BEGIN;

SET client_encoding = 'UTF8';
SET lock_timeout = '10s';
SET statement_timeout = '0';

\echo ''
\echo '============================================================'
\echo ' WMA TRAVEL ERP'
\echo ' F1-FIN MASTER V3.1 - COMPLEMENTACAO DO PLANO DE CONTAS'
\echo '============================================================'

/* ============================================================================
   V3.1.0 — AMBIENTE
   ============================================================================ */

\echo ''
\echo '=== V3.1.0 - AMBIENTE ==='

SELECT
    current_database() AS banco,
    current_user AS usuario,
    current_setting('server_version') AS postgresql,
    current_setting('server_encoding') AS server_encoding,
    current_setting('client_encoding') AS client_encoding,
    CURRENT_TIMESTAMP AS executado_em;

/* ============================================================================
   V3.1.1 — PRE-VALIDACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.1 - PRE-VALIDACAO'
\echo '============================================================'

DO $$
DECLARE
    v_count bigint;
BEGIN
    IF current_database() <> 'wma_travel' THEN
        RAISE EXCEPTION
            'V3.1 abortada: banco atual = %, esperado = wma_travel.',
            current_database();
    END IF;

    /* Objetos obrigatorios. */
    IF to_regclass('financeiro.grupo') IS NULL
       OR to_regclass('financeiro.categoria') IS NULL
       OR to_regclass('financeiro.subcategoria') IS NULL
       OR to_regclass('financeiro.classificacao') IS NULL
       OR to_regclass('financeiro.conta') IS NULL
       OR to_regclass('financeiro.lancamento') IS NULL THEN
        RAISE EXCEPTION
            'V3.1 abortada: um ou mais objetos-base do plano de contas nao existem.';
    END IF;

    /* Estado minimo validado anteriormente. */
    SELECT count(*) INTO v_count FROM financeiro.grupo;
    IF v_count <> 5 THEN
        RAISE EXCEPTION
            'V3.1 abortada: esperado 5 grupos; encontrado %.', v_count;
    END IF;

    SELECT count(*) INTO v_count FROM financeiro.categoria;
    IF v_count <> 13 THEN
        RAISE EXCEPTION
            'V3.1 abortada: esperado 13 categorias; encontrado %.', v_count;
    END IF;

    SELECT count(*) INTO v_count FROM financeiro.subcategoria;
    IF v_count <> 23 THEN
        RAISE EXCEPTION
            'V3.1 abortada: esperado 23 subcategorias; encontrado %.', v_count;
    END IF;

    /* Nenhuma hierarquia orfa pode existir. */
    SELECT count(*)
    INTO v_count
    FROM financeiro.categoria c
    LEFT JOIN financeiro.grupo g
      ON g.id_grupo = c.id_grupo
    WHERE g.id_grupo IS NULL;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'V3.1 abortada: existem % categorias orfas.', v_count;
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.subcategoria s
    LEFT JOIN financeiro.categoria c
      ON c.id_categoria = s.id_categoria
    WHERE c.id_categoria IS NULL;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'V3.1 abortada: existem % subcategorias orfas.', v_count;
    END IF;

    /* Estrutura obrigatoria de classificacao. */
    SELECT count(*)
    INTO v_count
    FROM information_schema.columns
    WHERE table_schema = 'financeiro'
      AND table_name = 'classificacao'
      AND column_name IN (
          'id_classificacao',
          'id_subcategoria',
          'codigo',
          'descricao',
          'ativo',
          'id_natureza_financeira',
          'id_tipo_dre',
          'ordem_dre',
          'gera_fluxo_caixa',
          'gera_dre',
          'aceita_cliente',
          'aceita_fornecedor',
          'aceita_centro_custo',
          'aceita_conta_bancaria'
      );

    IF v_count <> 14 THEN
        RAISE EXCEPTION
            'V3.1 abortada: estrutura de financeiro.classificacao divergente.';
    END IF;

    /* Estrutura obrigatoria de conta. */
    SELECT count(*)
    INTO v_count
    FROM information_schema.columns
    WHERE table_schema = 'financeiro'
      AND table_name = 'conta'
      AND column_name IN (
          'id_conta',
          'id_classificacao',
          'codigo',
          'descricao',
          'aceita_lancamento',
          'ativo'
      );

    IF v_count <> 6 THEN
        RAISE EXCEPTION
            'V3.1 abortada: estrutura de financeiro.conta divergente.';
    END IF;
END
$$;

\echo 'PRE-VALIDACAO: PASS'

/* ============================================================================
   V3.1.2 — SNAPSHOT ANTES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.2 - SNAPSHOT ANTES'
\echo '============================================================'

SELECT 'grupo' AS objeto, count(*) AS registros FROM financeiro.grupo
UNION ALL
SELECT 'categoria', count(*) FROM financeiro.categoria
UNION ALL
SELECT 'subcategoria', count(*) FROM financeiro.subcategoria
UNION ALL
SELECT 'classificacao', count(*) FROM financeiro.classificacao
UNION ALL
SELECT 'conta', count(*) FROM financeiro.conta
UNION ALL
SELECT 'lancamento', count(*) FROM financeiro.lancamento
ORDER BY objeto;

/* ============================================================================
   V3.1.3 — DOMINIO NATUREZA FINANCEIRA
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.3 - NATUREZA FINANCEIRA'
\echo '============================================================'

CREATE TABLE IF NOT EXISTS financeiro.natureza_financeira (
    id_natureza_financeira integer
        GENERATED BY DEFAULT AS IDENTITY,
    codigo character varying(10) NOT NULL,
    descricao character varying(80) NOT NULL,
    ativo boolean NOT NULL DEFAULT TRUE,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_natureza_financeira
        PRIMARY KEY (id_natureza_financeira),

    CONSTRAINT uk_natureza_financeira_codigo
        UNIQUE (codigo),

    CONSTRAINT chk_natureza_financeira_codigo
        CHECK (codigo IN ('A', 'P', 'L', 'R', 'D'))
);

COMMENT ON TABLE financeiro.natureza_financeira IS
    'Dominio das naturezas financeiras utilizadas pelo Plano de Contas.';

COMMENT ON COLUMN financeiro.natureza_financeira.codigo IS
    'A=Ativo, P=Passivo, L=Patrimonio Liquido, R=Receita, D=Custo/Despesa.';

INSERT INTO financeiro.natureza_financeira (
    codigo,
    descricao
)
VALUES
    ('A', 'Ativo'),
    ('P', 'Passivo'),
    ('L', 'Patrimonio Liquido'),
    ('R', 'Receita'),
    ('D', 'Custo ou Despesa')
ON CONFLICT (codigo) DO UPDATE
SET
    descricao = EXCLUDED.descricao,
    ativo = TRUE;

/* ============================================================================
   V3.1.4 — DOMINIO TIPO DRE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.4 - TIPO DRE'
\echo '============================================================'

CREATE TABLE IF NOT EXISTS financeiro.tipo_dre (
    id_tipo_dre integer
        GENERATED BY DEFAULT AS IDENTITY,
    codigo character varying(30) NOT NULL,
    descricao character varying(120) NOT NULL,
    natureza character(1) NOT NULL,
    ordem smallint NOT NULL,
    ativo boolean NOT NULL DEFAULT TRUE,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_tipo_dre
        PRIMARY KEY (id_tipo_dre),

    CONSTRAINT uk_tipo_dre_codigo
        UNIQUE (codigo),

    CONSTRAINT chk_tipo_dre_natureza
        CHECK (natureza IN ('R', 'D')),

    CONSTRAINT chk_tipo_dre_ordem
        CHECK (ordem > 0)
);

COMMENT ON TABLE financeiro.tipo_dre IS
    'Dominio de agrupamentos gerenciais para apresentacao da DRE.';

INSERT INTO financeiro.tipo_dre (
    codigo,
    descricao,
    natureza,
    ordem
)
VALUES
    ('RECEITA_OPERACIONAL',  'Receitas Operacionais',       'R', 10),
    ('RECEITA_FINANCEIRA',   'Receitas Financeiras',        'R', 20),
    ('OUTRA_RECEITA',        'Outras Receitas',             'R', 30),
    ('CUSTO_OPERACIONAL',    'Custos Operacionais',         'D', 40),
    ('DESPESA_ADMIN',        'Despesas Administrativas',    'D', 50),
    ('DESPESA_COMERCIAL',    'Despesas Comerciais',         'D', 60),
    ('DESPESA_FINANCEIRA',   'Despesas Financeiras',        'D', 70),
    ('DESPESA_TRIBUTARIA',   'Despesas Tributarias',        'D', 80)
ON CONFLICT (codigo) DO UPDATE
SET
    descricao = EXCLUDED.descricao,
    natureza = EXCLUDED.natureza,
    ordem = EXCLUDED.ordem,
    ativo = TRUE;

/* ============================================================================
   V3.1.5 — VALIDAR DOMINIOS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.5 - VALIDACAO DOS DOMINIOS'
\echo '============================================================'

DO $$
DECLARE
    v_count bigint;
BEGIN
    SELECT count(*)
    INTO v_count
    FROM financeiro.natureza_financeira
    WHERE codigo IN ('A','P','L','R','D')
      AND ativo IS TRUE;

    IF v_count <> 5 THEN
        RAISE EXCEPTION
            'V3.1 abortada: dominio natureza_financeira incompleto. Esperado 5, encontrado %.',
            v_count;
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.tipo_dre
    WHERE codigo IN (
        'RECEITA_OPERACIONAL',
        'RECEITA_FINANCEIRA',
        'OUTRA_RECEITA',
        'CUSTO_OPERACIONAL',
        'DESPESA_ADMIN',
        'DESPESA_COMERCIAL',
        'DESPESA_FINANCEIRA',
        'DESPESA_TRIBUTARIA'
    )
      AND ativo IS TRUE;

    IF v_count <> 8 THEN
        RAISE EXCEPTION
            'V3.1 abortada: dominio tipo_dre incompleto. Esperado 8, encontrado %.',
            v_count;
    END IF;
END
$$;

/* ============================================================================
   V3.1.6 — ADICIONAR FKS REAIS DOS DOMINIOS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.6 - FKS DOS DOMINIOS'
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
          AND c.relname = 'classificacao'
          AND con.conname = 'fk_classificacao_natureza_financeira'
    ) THEN
        ALTER TABLE financeiro.classificacao
            ADD CONSTRAINT fk_classificacao_natureza_financeira
            FOREIGN KEY (id_natureza_financeira)
            REFERENCES financeiro.natureza_financeira(id_natureza_financeira)
            ON UPDATE CASCADE
            ON DELETE RESTRICT;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_constraint con
        JOIN pg_class c
          ON c.oid = con.conrelid
        JOIN pg_namespace n
          ON n.oid = c.relnamespace
        WHERE n.nspname = 'financeiro'
          AND c.relname = 'classificacao'
          AND con.conname = 'fk_classificacao_tipo_dre'
    ) THEN
        ALTER TABLE financeiro.classificacao
            ADD CONSTRAINT fk_classificacao_tipo_dre
            FOREIGN KEY (id_tipo_dre)
            REFERENCES financeiro.tipo_dre(id_tipo_dre)
            ON UPDATE CASCADE
            ON DELETE RESTRICT;
    END IF;
END
$$;

/* ============================================================================
   V3.1.7 — PLANO DE CLASSIFICACOES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.7 - PLANO DE CLASSIFICACOES'
\echo '============================================================'

/*
   Regra:
   - Uma classificacao minima por subcategoria.
   - codigo = codigo da subcategoria + '.01'
   - descricao = descricao da subcategoria
   - natureza = herdada do grupo.
   - DRE apenas para grupos Receita (R) e Custo/Despesa (D).
*/

WITH plano AS (
    SELECT
        s.id_subcategoria,
        s.codigo || '.01' AS codigo,
        s.descricao,
        g.natureza,
        CASE s.codigo
            WHEN '4.1.01' THEN 'RECEITA_OPERACIONAL'
            WHEN '4.1.02' THEN 'RECEITA_OPERACIONAL'
            WHEN '4.2.01' THEN 'RECEITA_FINANCEIRA'
            WHEN '4.3.01' THEN 'OUTRA_RECEITA'
            WHEN '5.1.01' THEN 'CUSTO_OPERACIONAL'
            WHEN '5.2.01' THEN 'DESPESA_ADMIN'
            WHEN '5.3.01' THEN 'DESPESA_COMERCIAL'
            WHEN '5.4.01' THEN 'DESPESA_FINANCEIRA'
            WHEN '5.5.01' THEN 'DESPESA_TRIBUTARIA'
            ELSE NULL
        END AS codigo_tipo_dre,

        CASE
            WHEN s.codigo = '1.1.04' THEN TRUE
            WHEN g.natureza = 'R' THEN TRUE
            ELSE FALSE
        END AS aceita_cliente,

        CASE
            WHEN s.codigo = '2.1.01' THEN TRUE
            WHEN g.natureza = 'D' THEN TRUE
            ELSE FALSE
        END AS aceita_fornecedor,

        CASE
            WHEN g.natureza IN ('R','D') THEN TRUE
            ELSE FALSE
        END AS aceita_centro_custo,

        CASE
            WHEN s.codigo IN ('1.1.01','1.1.02','1.1.03')
              OR g.natureza IN ('R','D')
            THEN TRUE
            ELSE FALSE
        END AS aceita_conta_bancaria

    FROM financeiro.subcategoria s
    JOIN financeiro.categoria c
      ON c.id_categoria = s.id_categoria
    JOIN financeiro.grupo g
      ON g.id_grupo = c.id_grupo
),
resolvido AS (
    SELECT
        p.*,
        nf.id_natureza_financeira,
        td.id_tipo_dre,
        td.ordem AS ordem_dre
    FROM plano p
    JOIN financeiro.natureza_financeira nf
      ON nf.codigo = p.natureza
     AND nf.ativo IS TRUE
    LEFT JOIN financeiro.tipo_dre td
      ON td.codigo = p.codigo_tipo_dre
     AND td.ativo IS TRUE
)
INSERT INTO financeiro.classificacao (
    id_subcategoria,
    codigo,
    descricao,
    ativo,
    id_natureza_financeira,
    id_tipo_dre,
    ordem_dre,
    gera_fluxo_caixa,
    gera_dre,
    aceita_cliente,
    aceita_fornecedor,
    aceita_centro_custo,
    aceita_conta_bancaria
)
SELECT
    id_subcategoria,
    codigo,
    descricao,
    TRUE,
    id_natureza_financeira,
    id_tipo_dre,
    COALESCE(ordem_dre, 0),
    TRUE,
    (natureza IN ('R','D')),
    aceita_cliente,
    aceita_fornecedor,
    aceita_centro_custo,
    aceita_conta_bancaria
FROM resolvido
ON CONFLICT (codigo) DO NOTHING;

/* ============================================================================
   V3.1.8 — VALIDAR CLASSIFICACOES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.8 - VALIDACAO DAS CLASSIFICACOES'
\echo '============================================================'

DO $$
DECLARE
    v_count bigint;
BEGIN
    SELECT count(*)
    INTO v_count
    FROM financeiro.classificacao;

    IF v_count <> 23 THEN
        RAISE EXCEPTION
            'V3.1 abortada: esperado 23 classificacoes, encontrado %.',
            v_count;
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.classificacao
    WHERE id_natureza_financeira IS NULL;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'V3.1 abortada: existem % classificacoes sem natureza financeira.',
            v_count;
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.classificacao
    WHERE gera_dre IS TRUE
      AND id_tipo_dre IS NULL;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'V3.1 abortada: existem % classificacoes DRE sem tipo DRE.',
            v_count;
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.classificacao cl
    LEFT JOIN financeiro.subcategoria s
      ON s.id_subcategoria = cl.id_subcategoria
    WHERE s.id_subcategoria IS NULL;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'V3.1 abortada: existem % classificacoes orfas.',
            v_count;
    END IF;
END
$$;

/* ============================================================================
   V3.1.9 — CRIAR CONTAS ANALITICAS MINIMAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.9 - CONTAS ANALITICAS'
\echo '============================================================'

/*
   Uma conta analitica inicial por classificacao.
   O desenho permite adicionar contas mais granulares futuramente sem
   alterar a hierarquia ou as FKs.
*/

INSERT INTO financeiro.conta (
    id_classificacao,
    codigo,
    descricao,
    aceita_lancamento,
    ativo
)
SELECT
    cl.id_classificacao,
    s.codigo || '.01.001' AS codigo,
    s.descricao,
    TRUE,
    TRUE
FROM financeiro.classificacao cl
JOIN financeiro.subcategoria s
  ON s.id_subcategoria = cl.id_subcategoria
ON CONFLICT (codigo) DO NOTHING;

/* ============================================================================
   V3.1.10 — VALIDAR CONTAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.10 - VALIDACAO DAS CONTAS'
\echo '============================================================'

DO $$
DECLARE
    v_count bigint;
BEGIN
    SELECT count(*)
    INTO v_count
    FROM financeiro.conta;

    IF v_count <> 23 THEN
        RAISE EXCEPTION
            'V3.1 abortada: esperado 23 contas iniciais, encontrado %.',
            v_count;
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.conta ct
    LEFT JOIN financeiro.classificacao cl
      ON cl.id_classificacao = ct.id_classificacao
    WHERE cl.id_classificacao IS NULL;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'V3.1 abortada: existem % contas orfas.',
            v_count;
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.conta
    WHERE aceita_lancamento IS NOT TRUE
       OR ativo IS NOT TRUE;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'V3.1 abortada: existem % contas iniciais nao aptas a lancamento.',
            v_count;
    END IF;
END
$$;

/* ============================================================================
   V3.1.11 — HIERARQUIA POS-COMPLEMENTACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.11 - HIERARQUIA POS-COMPLEMENTACAO'
\echo '============================================================'

SELECT
    g.codigo AS grupo_codigo,
    g.descricao AS grupo,
    c.codigo AS categoria_codigo,
    c.descricao AS categoria,
    s.codigo AS subcategoria_codigo,
    s.descricao AS subcategoria,
    cl.codigo AS classificacao_codigo,
    cl.descricao AS classificacao,
    nf.codigo AS natureza,
    td.codigo AS tipo_dre,
    cl.gera_fluxo_caixa,
    cl.gera_dre,
    ct.codigo AS conta_codigo,
    ct.descricao AS conta,
    ct.aceita_lancamento
FROM financeiro.grupo g
JOIN financeiro.categoria c
  ON c.id_grupo = g.id_grupo
JOIN financeiro.subcategoria s
  ON s.id_categoria = c.id_categoria
JOIN financeiro.classificacao cl
  ON cl.id_subcategoria = s.id_subcategoria
JOIN financeiro.natureza_financeira nf
  ON nf.id_natureza_financeira = cl.id_natureza_financeira
LEFT JOIN financeiro.tipo_dre td
  ON td.id_tipo_dre = cl.id_tipo_dre
JOIN financeiro.conta ct
  ON ct.id_classificacao = cl.id_classificacao
ORDER BY
    g.codigo,
    c.codigo,
    s.codigo,
    cl.codigo,
    ct.codigo;

/* ============================================================================
   V3.1.12 — DISTRIBUICAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.12 - DISTRIBUICAO'
\echo '============================================================'

SELECT
    g.codigo AS grupo_codigo,
    g.descricao AS grupo,
    COUNT(DISTINCT c.id_categoria) AS categorias,
    COUNT(DISTINCT s.id_subcategoria) AS subcategorias,
    COUNT(DISTINCT cl.id_classificacao) AS classificacoes,
    COUNT(DISTINCT ct.id_conta) AS contas,
    COUNT(DISTINCT ct.id_conta) FILTER (
        WHERE ct.aceita_lancamento IS TRUE
    ) AS contas_analiticas
FROM financeiro.grupo g
LEFT JOIN financeiro.categoria c
  ON c.id_grupo = g.id_grupo
LEFT JOIN financeiro.subcategoria s
  ON s.id_categoria = c.id_categoria
LEFT JOIN financeiro.classificacao cl
  ON cl.id_subcategoria = s.id_subcategoria
LEFT JOIN financeiro.conta ct
  ON ct.id_classificacao = cl.id_classificacao
GROUP BY
    g.codigo,
    g.descricao
ORDER BY g.codigo;

/* ============================================================================
   V3.1.13 — REAUDITORIA ESTRUTURAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.13 - REAUDITORIA ESTRUTURAL'
\echo '============================================================'

WITH metricas AS (
    SELECT
        (
            SELECT count(*)
            FROM financeiro.categoria c
            LEFT JOIN financeiro.grupo g
              ON g.id_grupo = c.id_grupo
            WHERE g.id_grupo IS NULL
        ) AS categorias_orfas,

        (
            SELECT count(*)
            FROM financeiro.subcategoria s
            LEFT JOIN financeiro.categoria c
              ON c.id_categoria = s.id_categoria
            WHERE c.id_categoria IS NULL
        ) AS subcategorias_orfas,

        (
            SELECT count(*)
            FROM financeiro.classificacao cl
            LEFT JOIN financeiro.subcategoria s
              ON s.id_subcategoria = cl.id_subcategoria
            WHERE s.id_subcategoria IS NULL
        ) AS classificacoes_orfas,

        (
            SELECT count(*)
            FROM financeiro.conta ct
            LEFT JOIN financeiro.classificacao cl
              ON cl.id_classificacao = ct.id_classificacao
            WHERE cl.id_classificacao IS NULL
        ) AS contas_orfas,

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
        ) AS classificacoes_dre_sem_tipo,

        (
            SELECT count(*)
            FROM pg_constraint con
            JOIN pg_class c
              ON c.oid = con.conrelid
            JOIN pg_namespace n
              ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND NOT con.convalidated
        ) AS constraints_nao_validadas
)
SELECT *
FROM metricas;

/* ============================================================================
   V3.1.14 — CERTIFICACAO F1-FIN.5
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V3.1.14 - CERTIFICACAO F1-FIN.5'
\echo '============================================================'

WITH metricas AS (
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
        ) AS sem_natureza,

        (
            SELECT count(*)
            FROM financeiro.classificacao
            WHERE gera_dre IS TRUE
              AND id_tipo_dre IS NULL
        ) AS dre_sem_tipo,

        (
            SELECT count(*)
            FROM financeiro.classificacao cl
            LEFT JOIN financeiro.subcategoria s
              ON s.id_subcategoria = cl.id_subcategoria
            WHERE s.id_subcategoria IS NULL
        ) AS classificacoes_orfas,

        (
            SELECT count(*)
            FROM financeiro.conta ct
            LEFT JOIN financeiro.classificacao cl
              ON cl.id_classificacao = ct.id_classificacao
            WHERE cl.id_classificacao IS NULL
        ) AS contas_orfas,

        (
            SELECT count(*)
            FROM pg_constraint con
            JOIN pg_class c
              ON c.oid = con.conrelid
            JOIN pg_namespace n
              ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND NOT con.convalidated
        ) AS constraints_nao_validadas
)
SELECT
    grupos,
    categorias,
    subcategorias,
    classificacoes,
    contas,
    sem_natureza,
    dre_sem_tipo,
    classificacoes_orfas,
    contas_orfas,
    constraints_nao_validadas,

    CASE
        WHEN grupos = 5
         AND categorias = 13
         AND subcategorias = 23
         AND classificacoes = 23
         AND contas = 23
         AND sem_natureza = 0
         AND dre_sem_tipo = 0
         AND classificacoes_orfas = 0
         AND contas_orfas = 0
         AND constraints_nao_validadas = 0
        THEN 'F1_FIN_5_APROVADA'
        ELSE 'F1_FIN_5_PENDENTE'
    END AS status
FROM metricas;

/* ============================================================================
   V3.1.15 — VALIDACAO BLOQUEANTE FINAL
   ============================================================================ */

DO $$
DECLARE
    v_status text;
BEGIN
    WITH metricas AS (
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
            ) AS sem_natureza,
            (
                SELECT count(*)
                FROM financeiro.classificacao
                WHERE gera_dre IS TRUE
                  AND id_tipo_dre IS NULL
            ) AS dre_sem_tipo
    )
    SELECT
        CASE
            WHEN grupos = 5
             AND categorias = 13
             AND subcategorias = 23
             AND classificacoes = 23
             AND contas = 23
             AND sem_natureza = 0
             AND dre_sem_tipo = 0
            THEN 'OK'
            ELSE 'ERRO'
        END
    INTO v_status
    FROM metricas;

    IF v_status <> 'OK' THEN
        RAISE EXCEPTION
            'V3.1 abortada: certificacao final da F1-FIN.5 nao aprovada.';
    END IF;
END
$$;

/* ============================================================================
   COMMIT
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN MASTER V3.1 CONCLUIDA'
\echo '============================================================'
\echo ' PLANO DE CONTAS COMPLEMENTADO'
\echo ' NATUREZAS FINANCEIRAS ............ 5'
\echo ' TIPOS DRE ........................ 8'
\echo ' CLASSIFICACOES ................... 23'
\echo ' CONTAS ANALITICAS ................ 23'
\echo ' PROXIMA ETAPA .................... F1-FIN.6'
\echo '============================================================'

COMMIT;

\echo ''
\echo '============================================================'
\echo ' COMMIT CONCLUIDO'
\echo ' F1-FIN.5 FINALIZADA'
\echo ' PROXIMA ETAPA: F1-FIN.6 - AP/AR E PARCELAMENTOS'
\echo '============================================================'
