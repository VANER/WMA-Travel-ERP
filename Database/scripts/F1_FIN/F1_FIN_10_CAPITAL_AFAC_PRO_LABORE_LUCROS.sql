/* ============================================================================
   WMA TRAVEL ERP
   F1-FIN.10 — CAPITAL, AFAC, PRO-LABORE E LUCROS

   PostgreSQL : 18.x
   Banco      : wma_travel
   Etapa      : F1-FIN.10
   Modo       : COMPLEMENTACAO CONTROLADA / CERTIFICACAO

   REGRA ARQUITETURAL
   ------------------
   financeiro = autoridade do dominio financeiro
   public     = corporativo / transversal

   OBJETIVO
   --------
   Consolidar em um unico script:
     1. Pre-validacao das estruturas de capital e distribuicoes.
     2. Inventario dos objetos existentes relacionados a:
        - Capital social
        - AFAC
        - Pro-labore
        - Distribuicao de lucros
     3. Complementacao minima se objetos estiverem ausentes.
     4. Integracao com financeiro.lancamento.
     5. Testes funcionais controlados.
     6. Limpeza dos dados artificiais.
     7. Certificacao final da F1-FIN.10.

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
\echo ' F1-FIN.10 - CAPITAL, AFAC, PRO-LABORE E LUCROS'
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
            'F1-FIN.10 abortada: banco atual %, esperado %.',
            current_database(),
            current_setting('wma.expected_database');
    END IF;

    IF to_regclass('financeiro.lancamento') IS NULL THEN
        RAISE EXCEPTION
            'F1-FIN.10 abortada: financeiro.lancamento ausente.';
    END IF;

    IF to_regclass('financeiro.tipo_lancamento') IS NULL THEN
        RAISE EXCEPTION
            'F1-FIN.10 abortada: financeiro.tipo_lancamento ausente.';
    END IF;

    IF to_regclass('public.empresa') IS NULL THEN
        RAISE EXCEPTION
            'F1-FIN.10 abortada: public.empresa ausente.';
    END IF;

    SELECT count(*)
    INTO v_count
    FROM public.empresa;

    IF v_count = 0 THEN
        RAISE EXCEPTION
            'F1-FIN.10 abortada: public.empresa sem registros.';
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.tipo_lancamento
    WHERE codigo IN ('APORTE','PRO_LABORE','LUCRO')
      AND ativo IS TRUE;

    IF v_count < 3 THEN
        RAISE EXCEPTION
            'F1-FIN.10 abortada: tipos APORTE/PRO_LABORE/LUCRO incompletos.';
    END IF;
END
$$;

\echo 'PRE-VALIDACAO: PASS'

/* ============================================================================
   3. INVENTARIO DE OBJETOS EXISTENTES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 3 - INVENTARIO DE OBJETOS'
\echo '============================================================'

SELECT
    n.nspname AS schema_name,
    c.relname AS object_name,
    CASE c.relkind
        WHEN 'r' THEN 'TABLE'
        WHEN 'p' THEN 'PARTITIONED TABLE'
        WHEN 'v' THEN 'VIEW'
        WHEN 'm' THEN 'MATERIALIZED VIEW'
        ELSE c.relkind::text
    END AS object_type
FROM pg_class c
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE n.nspname NOT LIKE 'pg_%'
  AND n.nspname <> 'information_schema'
  AND c.relkind IN ('r','p','v','m')
  AND c.relname ~* '(capital|afac|pro.?labore|lucro|distribuicao)'
ORDER BY n.nspname, c.relname;

/* ============================================================================
   4. CAPITAL SOCIAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 4 - CAPITAL SOCIAL'
\echo '============================================================'

CREATE TABLE IF NOT EXISTS financeiro.capital_social (
    id_capital bigint GENERATED BY DEFAULT AS IDENTITY,
    id_empresa integer NOT NULL,
    data_evento date NOT NULL,
    tipo_evento character varying(20) NOT NULL,
    valor numeric(15,2) NOT NULL,
    descricao character varying(255),
    id_lancamento bigint,
    ativo boolean NOT NULL DEFAULT TRUE,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer NOT NULL DEFAULT 1,

    CONSTRAINT pk_capital_social
        PRIMARY KEY (id_capital),

    CONSTRAINT chk_capital_social_tipo
        CHECK (tipo_evento IN ('INTEGRALIZACAO','AUMENTO','REDUCAO','AJUSTE')),

    CONSTRAINT chk_capital_social_valor
        CHECK (valor > 0),

    CONSTRAINT fk_capital_social_empresa
        FOREIGN KEY (id_empresa)
        REFERENCES public.empresa(id_empresa)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_capital_social_lancamento
        FOREIGN KEY (id_lancamento)
        REFERENCES financeiro.lancamento(id_lancamento)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_capital_social_created_by
        FOREIGN KEY (created_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_capital_social_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_capital_social_deleted_by
        FOREIGN KEY (deleted_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

/* ============================================================================
   5. AFAC
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 5 - AFAC'
\echo '============================================================'

CREATE TABLE IF NOT EXISTS financeiro.afac (
    id_afac bigint GENERATED BY DEFAULT AS IDENTITY,
    id_empresa integer NOT NULL,
    data_aporte date NOT NULL,
    valor numeric(15,2) NOT NULL,
    origem character varying(120),
    descricao character varying(255),
    status character varying(20) NOT NULL DEFAULT 'ABERTO',
    id_lancamento bigint,
    ativo boolean NOT NULL DEFAULT TRUE,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer NOT NULL DEFAULT 1,

    CONSTRAINT pk_afac
        PRIMARY KEY (id_afac),

    CONSTRAINT chk_afac_valor
        CHECK (valor > 0),

    CONSTRAINT chk_afac_status
        CHECK (status IN ('ABERTO','CONVERTIDO','DEVOLVIDO','CANCELADO')),

    CONSTRAINT fk_afac_empresa
        FOREIGN KEY (id_empresa)
        REFERENCES public.empresa(id_empresa)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_afac_lancamento
        FOREIGN KEY (id_lancamento)
        REFERENCES financeiro.lancamento(id_lancamento)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_afac_created_by
        FOREIGN KEY (created_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_afac_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_afac_deleted_by
        FOREIGN KEY (deleted_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

/* ============================================================================
   6. PRO-LABORE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 6 - PRO-LABORE'
\echo '============================================================'

CREATE TABLE IF NOT EXISTS financeiro.pro_labore (
    id_pro_labore bigint GENERATED BY DEFAULT AS IDENTITY,
    id_empresa integer NOT NULL,
    competencia date NOT NULL,
    valor_bruto numeric(15,2) NOT NULL,
    inss numeric(15,2) NOT NULL DEFAULT 0,
    irrf numeric(15,2) NOT NULL DEFAULT 0,
    outros_descontos numeric(15,2) NOT NULL DEFAULT 0,
    valor_liquido numeric(15,2)
        GENERATED ALWAYS AS (
            valor_bruto - inss - irrf - outros_descontos
        ) STORED,
    data_pagamento date,
    id_lancamento bigint,
    status character varying(20) NOT NULL DEFAULT 'ABERTO',
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer NOT NULL DEFAULT 1,

    CONSTRAINT pk_pro_labore
        PRIMARY KEY (id_pro_labore),

    CONSTRAINT uk_pro_labore_empresa_competencia
        UNIQUE (id_empresa, competencia),

    CONSTRAINT chk_pro_labore_valor_bruto
        CHECK (valor_bruto > 0),

    CONSTRAINT chk_pro_labore_inss
        CHECK (inss >= 0),

    CONSTRAINT chk_pro_labore_irrf
        CHECK (irrf >= 0),

    CONSTRAINT chk_pro_labore_outros
        CHECK (outros_descontos >= 0),

    CONSTRAINT chk_pro_labore_liquido
        CHECK (valor_liquido >= 0),

    CONSTRAINT chk_pro_labore_status
        CHECK (status IN ('ABERTO','PAGO','CANCELADO')),

    CONSTRAINT fk_pro_labore_empresa
        FOREIGN KEY (id_empresa)
        REFERENCES public.empresa(id_empresa)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_pro_labore_lancamento
        FOREIGN KEY (id_lancamento)
        REFERENCES financeiro.lancamento(id_lancamento)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_pro_labore_created_by
        FOREIGN KEY (created_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_pro_labore_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_pro_labore_deleted_by
        FOREIGN KEY (deleted_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

/* ============================================================================
   7. DISTRIBUICAO DE LUCROS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 7 - DISTRIBUICAO DE LUCROS'
\echo '============================================================'

CREATE TABLE IF NOT EXISTS financeiro.distribuicao_lucro (
    id_distribuicao bigint GENERATED BY DEFAULT AS IDENTITY,
    id_empresa integer NOT NULL,
    competencia date NOT NULL,
    data_distribuicao date NOT NULL,
    valor numeric(15,2) NOT NULL,
    descricao character varying(255),
    id_lancamento bigint,
    status character varying(20) NOT NULL DEFAULT 'ABERTA',
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer NOT NULL DEFAULT 1,

    CONSTRAINT pk_distribuicao_lucro
        PRIMARY KEY (id_distribuicao),

    CONSTRAINT chk_distribuicao_lucro_valor
        CHECK (valor > 0),

    CONSTRAINT chk_distribuicao_lucro_status
        CHECK (status IN ('ABERTA','PAGA','CANCELADA')),

    CONSTRAINT fk_distribuicao_lucro_empresa
        FOREIGN KEY (id_empresa)
        REFERENCES public.empresa(id_empresa)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_distribuicao_lucro_lancamento
        FOREIGN KEY (id_lancamento)
        REFERENCES financeiro.lancamento(id_lancamento)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_distribuicao_lucro_created_by
        FOREIGN KEY (created_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_distribuicao_lucro_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_distribuicao_lucro_deleted_by
        FOREIGN KEY (deleted_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

/* ============================================================================
   8. INDICES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 8 - INDICES'
\echo '============================================================'

CREATE INDEX IF NOT EXISTS idx_capital_social_empresa_data
    ON financeiro.capital_social(id_empresa, data_evento);

CREATE INDEX IF NOT EXISTS idx_afac_empresa_data
    ON financeiro.afac(id_empresa, data_aporte);

CREATE INDEX IF NOT EXISTS idx_pro_labore_empresa_competencia
    ON financeiro.pro_labore(id_empresa, competencia);

CREATE INDEX IF NOT EXISTS idx_distribuicao_lucro_empresa_competencia
    ON financeiro.distribuicao_lucro(id_empresa, competencia);

/* ============================================================================
   9. DOCUMENTACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 9 - DOCUMENTACAO'
\echo '============================================================'

COMMENT ON TABLE financeiro.capital_social IS
    'Eventos de integralizacao, aumento, reducao e ajuste do capital social da empresa.';

COMMENT ON TABLE financeiro.afac IS
    'Adiantamentos para futuro aumento de capital controlados pelo modulo financeiro.';

COMMENT ON TABLE financeiro.pro_labore IS
    'Controle mensal de pro-labore, descontos e valor liquido.';

COMMENT ON TABLE financeiro.distribuicao_lucro IS
    'Controle das distribuicoes de lucros aos socios ou titular.';

/* ============================================================================
   10. REAUDITORIA DE OBJETOS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 10 - REAUDITORIA DE OBJETOS'
\echo '============================================================'

WITH esperado(objeto) AS (
    VALUES
        ('capital_social'),
        ('afac'),
        ('pro_labore'),
        ('distribuicao_lucro')
)
SELECT
    objeto,
    CASE
        WHEN to_regclass('financeiro.' || objeto) IS NOT NULL
            THEN 'OK'
        ELSE 'AUSENTE'
    END AS status
FROM esperado
ORDER BY objeto;

/* ============================================================================
   11. REAUDITORIA DE CONSTRAINTS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 11 - REAUDITORIA DE CONSTRAINTS'
\echo '============================================================'

SELECT
    c.relname AS table_name,
    COUNT(*) AS constraints,
    COUNT(*) FILTER (
        WHERE NOT con.convalidated
    ) AS nao_validadas
FROM pg_constraint con
JOIN pg_class c
  ON c.oid = con.conrelid
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'financeiro'
  AND c.relname IN (
      'capital_social',
      'afac',
      'pro_labore',
      'distribuicao_lucro'
  )
GROUP BY c.relname
ORDER BY c.relname;

/* ============================================================================
   12. TESTE FUNCIONAL CONTROLADO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 12 - TESTE FUNCIONAL'
\echo '============================================================'

CREATE TEMP TABLE f1_fin_10_test_ctx (
    id_capital bigint,
    id_afac bigint,
    id_pro_labore bigint,
    id_distribuicao bigint
);

DO $$
DECLARE
    v_empresa integer;
    v_capital bigint;
    v_afac bigint;
    v_pro bigint;
    v_lucro bigint;
BEGIN
    SELECT id_empresa
    INTO v_empresa
    FROM public.empresa
    ORDER BY id_empresa
    LIMIT 1;

    INSERT INTO financeiro.capital_social (
        id_empresa,
        data_evento,
        tipo_evento,
        valor,
        descricao
    )
    VALUES (
        v_empresa,
        CURRENT_DATE,
        'INTEGRALIZACAO',
        10000.00,
        'Teste F1-FIN.10 - capital'
    )
    RETURNING id_capital INTO v_capital;

    INSERT INTO financeiro.afac (
        id_empresa,
        data_aporte,
        valor,
        origem,
        descricao,
        status
    )
    VALUES (
        v_empresa,
        CURRENT_DATE,
        5000.00,
        'SOCIO',
        'Teste F1-FIN.10 - AFAC',
        'ABERTO'
    )
    RETURNING id_afac INTO v_afac;

    INSERT INTO financeiro.pro_labore (
        id_empresa,
        competencia,
        valor_bruto,
        inss,
        irrf,
        outros_descontos,
        data_pagamento,
        status
    )
    VALUES (
        v_empresa,
        date_trunc('month', CURRENT_DATE)::date,
        2500.00,
        275.00,
        0.00,
        0.00,
        CURRENT_DATE,
        'PAGO'
    )
    RETURNING id_pro_labore INTO v_pro;

    INSERT INTO financeiro.distribuicao_lucro (
        id_empresa,
        competencia,
        data_distribuicao,
        valor,
        descricao,
        status
    )
    VALUES (
        v_empresa,
        date_trunc('month', CURRENT_DATE)::date,
        CURRENT_DATE,
        3000.00,
        'Teste F1-FIN.10 - distribuicao',
        'PAGA'
    )
    RETURNING id_distribuicao INTO v_lucro;

    INSERT INTO f1_fin_10_test_ctx
    VALUES (
        v_capital,
        v_afac,
        v_pro,
        v_lucro
    );
END
$$;

/* ============================================================================
   13. VALIDACAO FUNCIONAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 13 - VALIDACAO FUNCIONAL'
\echo '============================================================'

SELECT
    p.id_pro_labore,
    p.valor_bruto,
    p.inss,
    p.irrf,
    p.outros_descontos,
    p.valor_liquido,
    CASE
        WHEN p.valor_liquido =
             p.valor_bruto - p.inss - p.irrf - p.outros_descontos
        THEN 'OK'
        ELSE 'ERRO'
    END AS validacao_liquido
FROM financeiro.pro_labore p
WHERE p.id_pro_labore IN (
    SELECT id_pro_labore
    FROM f1_fin_10_test_ctx
);

DO $$
DECLARE
    v_count bigint;
BEGIN
    SELECT count(*)
    INTO v_count
    FROM financeiro.capital_social
    WHERE id_capital IN (
        SELECT id_capital FROM f1_fin_10_test_ctx
    )
      AND valor = 10000.00;

    IF v_count <> 1 THEN
        RAISE EXCEPTION
            'F1-FIN.10 falhou: teste de capital nao aprovado.';
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.afac
    WHERE id_afac IN (
        SELECT id_afac FROM f1_fin_10_test_ctx
    )
      AND valor = 5000.00
      AND status = 'ABERTO';

    IF v_count <> 1 THEN
        RAISE EXCEPTION
            'F1-FIN.10 falhou: teste de AFAC nao aprovado.';
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.pro_labore
    WHERE id_pro_labore IN (
        SELECT id_pro_labore FROM f1_fin_10_test_ctx
    )
      AND valor_liquido = 2225.00
      AND status = 'PAGO';

    IF v_count <> 1 THEN
        RAISE EXCEPTION
            'F1-FIN.10 falhou: teste de pro-labore nao aprovado.';
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.distribuicao_lucro
    WHERE id_distribuicao IN (
        SELECT id_distribuicao FROM f1_fin_10_test_ctx
    )
      AND valor = 3000.00
      AND status = 'PAGA';

    IF v_count <> 1 THEN
        RAISE EXCEPTION
            'F1-FIN.10 falhou: teste de distribuicao de lucros nao aprovado.';
    END IF;
END
$$;

/* ============================================================================
   14. LIMPEZA DOS DADOS DE TESTE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 14 - LIMPEZA DOS DADOS DE TESTE'
\echo '============================================================'

DELETE FROM financeiro.distribuicao_lucro
WHERE id_distribuicao IN (
    SELECT id_distribuicao FROM f1_fin_10_test_ctx
);

DELETE FROM financeiro.pro_labore
WHERE id_pro_labore IN (
    SELECT id_pro_labore FROM f1_fin_10_test_ctx
);

DELETE FROM financeiro.afac
WHERE id_afac IN (
    SELECT id_afac FROM f1_fin_10_test_ctx
);

DELETE FROM financeiro.capital_social
WHERE id_capital IN (
    SELECT id_capital FROM f1_fin_10_test_ctx
);

/* ============================================================================
   15. CERTIFICACAO FINAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 15 - CERTIFICACAO FINAL F1-FIN.10'
\echo '============================================================'

WITH integridade AS (
    SELECT
        (
            SELECT COUNT(*)
            FROM pg_constraint con
            JOIN pg_class c
              ON c.oid = con.conrelid
            JOIN pg_namespace n
              ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relname IN (
                  'capital_social',
                  'afac',
                  'pro_labore',
                  'distribuicao_lucro'
              )
              AND NOT con.convalidated
        ) AS constraints_nao_validadas,

        (
            SELECT COUNT(*)
            FROM financeiro.capital_social
            WHERE descricao = 'Teste F1-FIN.10 - capital'
        ) AS teste_capital,

        (
            SELECT COUNT(*)
            FROM financeiro.afac
            WHERE descricao = 'Teste F1-FIN.10 - AFAC'
        ) AS teste_afac,

        (
            SELECT COUNT(*)
            FROM financeiro.distribuicao_lucro
            WHERE descricao = 'Teste F1-FIN.10 - distribuicao'
        ) AS teste_lucro
)
SELECT
    CASE WHEN to_regclass('financeiro.capital_social') IS NOT NULL THEN 1 ELSE 0 END AS capital_social,
    CASE WHEN to_regclass('financeiro.afac') IS NOT NULL THEN 1 ELSE 0 END AS afac,
    CASE WHEN to_regclass('financeiro.pro_labore') IS NOT NULL THEN 1 ELSE 0 END AS pro_labore,
    CASE WHEN to_regclass('financeiro.distribuicao_lucro') IS NOT NULL THEN 1 ELSE 0 END AS distribuicao_lucro,
    i.constraints_nao_validadas,
    i.teste_capital,
    i.teste_afac,
    i.teste_lucro,
    CASE
        WHEN to_regclass('financeiro.capital_social') IS NOT NULL
         AND to_regclass('financeiro.afac') IS NOT NULL
         AND to_regclass('financeiro.pro_labore') IS NOT NULL
         AND to_regclass('financeiro.distribuicao_lucro') IS NOT NULL
         AND i.constraints_nao_validadas = 0
         AND i.teste_capital = 0
         AND i.teste_afac = 0
         AND i.teste_lucro = 0
        THEN 'F1_FIN_10_APROVADA'
        ELSE 'F1_FIN_10_PENDENTE'
    END AS status
FROM integridade i;

/* ============================================================================
   16. VALIDACAO BLOQUEANTE FINAL
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
          'capital_social',
          'afac',
          'pro_labore',
          'distribuicao_lucro'
      )
      AND NOT con.convalidated;

    IF v_invalid <> 0 THEN
        RAISE EXCEPTION
            'F1-FIN.10 abortada: % constraints nao validadas.',
            v_invalid;
    END IF;

    IF EXISTS (
        SELECT 1 FROM financeiro.capital_social
        WHERE descricao = 'Teste F1-FIN.10 - capital'
    )
    OR EXISTS (
        SELECT 1 FROM financeiro.afac
        WHERE descricao = 'Teste F1-FIN.10 - AFAC'
    )
    OR EXISTS (
        SELECT 1 FROM financeiro.distribuicao_lucro
        WHERE descricao = 'Teste F1-FIN.10 - distribuicao'
    ) THEN
        RAISE EXCEPTION
            'F1-FIN.10 abortada: dados de teste permaneceram.';
    END IF;
END
$$;

/* ============================================================================
   COMMIT
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.10 CONCLUIDA'
\echo '============================================================'
\echo ' CAPITAL SOCIAL ................... IMPLEMENTADO/VALIDADO'
\echo ' AFAC ............................. IMPLEMENTADO/VALIDADO'
\echo ' PRO-LABORE ....................... IMPLEMENTADO/VALIDADO'
\echo ' DISTRIBUICAO DE LUCROS ........... IMPLEMENTADA/VALIDADA'
\echo ' TESTES FUNCIONAIS ................ APROVADOS'
\echo ' DOCUMENTACAO ..................... APLICADA'
\echo ' PROXIMA ETAPA .................... F1-FIN.11'
\echo '============================================================'

COMMIT;

\echo ''
\echo '============================================================'
\echo ' COMMIT CONCLUIDO'
\echo ' F1-FIN.10 FINALIZADA'
\echo ' PROXIMA ETAPA: F1-FIN.11 - TRIBUTOS, EMPRESTIMOS E IMOBILIZADO'
\echo '============================================================'
