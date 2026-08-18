/* ============================================================================
   WMA TRAVEL ERP
   F1-FIN MASTER V2.1 — CORRECAO MINIMA CONTROLADA

   PostgreSQL : 18.x
   Banco      : wma_travel

   REGRA ARQUITETURAL DEFINIDA NA V1.3
   -----------------------------------
   financeiro = autoridade do dominio financeiro
   public     = autoridade corporativa / transversal

   AUTORIDADE PUBLIC / TRANSVERSAL
   --------------------------------
   public.empresa
   public.cliente
   public.fornecedor
   public.usuario
   public.tipo_documento

   AUTORIDADE FINANCEIRO
   ---------------------
   financeiro.banco
   financeiro.conta_bancaria
   financeiro.forma_pagamento
   financeiro.centro_custo
   financeiro.conciliacao_bancaria
   financeiro.lancamento_parcela
   financeiro.grupo
   financeiro.categoria
   financeiro.subcategoria
   financeiro.classificacao
   financeiro.conta
   financeiro.lancamento
   financeiro.pagamento
   financeiro.movimentacao_bancaria
   financeiro.rateio_centro_custo
   financeiro.tipo_lancamento
   financeiro.status_lancamento
   financeiro.tipo_movimentacao

   ESCOPO DESTA V2.1
   ---------------
   1. Validar pre-condicoes encontradas na V1.3.
   2. Preservar public como autoridade das entidades transversais.
   3. Redirecionar FKs do schema financeiro para public quando o alvo for:
      empresa, cliente, fornecedor, usuario ou tipo_documento.
   4. Alinhar financeiro.lancamento.id_tipo_documento com public.tipo_documento.
   5. Migrar os cadastros existentes de:
      public.centro_custo    -> financeiro.centro_custo
      public.forma_pagamento -> financeiro.forma_pagamento
   6. Popular dominios financeiros minimos:
      financeiro.tipo_lancamento
      financeiro.status_lancamento
      financeiro.tipo_movimentacao
   7. Remover SOMENTE copias transversais vazias do schema financeiro:
      financeiro.empresa
      financeiro.cliente
      financeiro.fornecedor
      financeiro.usuario
      financeiro.tipo_documento
   8. NAO remover nesta etapa tabelas financeiras legadas existentes em public.
   9. Executar reauditoria estrutural ao final.

   REVISAO V2.1
   -----------
   - Corrige o seed INVESTIMENTO, que excedia tipo_lancamento.codigo varchar(10).
   - Usa o codigo INVEST e preserva a descricao Investimento.
   - Valida dinamicamente o comprimento de todos os codigos antes dos INSERTs.

   SEGURANCA
   ---------
   - Transacao unica.
   - ON_ERROR_STOP.
   - Sem CASCADE.
   - Aborta em qualquer divergencia de pre-condicao.
   - As tabelas financeiras legadas de public permanecem intactas.
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
\echo ' F1-FIN MASTER V2.1 - CORRECAO MINIMA CONTROLADA'
\echo '============================================================'
\echo ' financeiro = AUTORIDADE FINANCEIRA'
\echo ' public     = CORPORATIVO / TRANSVERSAL'
\echo '============================================================'

/* ============================================================================
   V2.0 — AMBIENTE
   ============================================================================ */

\echo ''
\echo '=== V2.0 - AMBIENTE ==='

SELECT
    current_database() AS banco,
    current_user AS usuario,
    current_setting('server_version') AS postgresql,
    current_setting('server_encoding') AS server_encoding,
    current_setting('client_encoding') AS client_encoding,
    CURRENT_TIMESTAMP AS executado_em;

/* ============================================================================
   V2.1 — PRE-VALIDACAO DA BASELINE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.1 - PRE-VALIDACAO'
\echo '============================================================'

DO $$
DECLARE
    v_count bigint;
    v_obj text;
BEGIN
    /* PostgreSQL esperado. */
    IF current_setting('server_version_num')::integer < 180000 THEN
        RAISE EXCEPTION
            'V2.1 abortada: PostgreSQL 18.x ou superior esperado. Atual: %',
            current_setting('server_version');
    END IF;

    /* Schemas obrigatorios. */
    IF to_regnamespace('public') IS NULL
       OR to_regnamespace('financeiro') IS NULL THEN
        RAISE EXCEPTION
            'V2.1 abortada: schemas public e/ou financeiro nao encontrados.';
    END IF;

    /* Tabelas transversais de public precisam existir. */
    FOREACH v_obj IN ARRAY ARRAY[
        'public.empresa',
        'public.cliente',
        'public.fornecedor',
        'public.usuario',
        'public.tipo_documento'
    ]
    LOOP
        IF to_regclass(v_obj) IS NULL THEN
            RAISE EXCEPTION
                'V2.1 abortada: autoridade transversal ausente: %', v_obj;
        END IF;
    END LOOP;

    /* Tabelas financeiras que precisam existir. */
    FOREACH v_obj IN ARRAY ARRAY[
        'financeiro.banco',
        'financeiro.conta_bancaria',
        'financeiro.forma_pagamento',
        'financeiro.centro_custo',
        'financeiro.conciliacao_bancaria',
        'financeiro.lancamento_parcela',
        'financeiro.lancamento',
        'financeiro.pagamento',
        'financeiro.movimentacao_bancaria',
        'financeiro.rateio_centro_custo',
        'financeiro.tipo_lancamento',
        'financeiro.status_lancamento',
        'financeiro.tipo_movimentacao'
    ]
    LOOP
        IF to_regclass(v_obj) IS NULL THEN
            RAISE EXCEPTION
                'V2.1 abortada: objeto financeiro obrigatorio ausente: %', v_obj;
        END IF;
    END LOOP;

    /*
       Arquitetura definitiva:
         financeiro = autoridade do dominio financeiro
         public     = corporativo / transversal

       As entidades corporativas devem existir em public e nao precisam
       possuir copias no schema financeiro.
    */
    FOREACH v_obj IN ARRAY ARRAY[
        'public.empresa',
        'public.cliente',
        'public.fornecedor',
        'public.usuario',
        'public.tipo_documento'
    ]
    LOOP
        IF to_regclass(v_obj) IS NULL THEN
            RAISE EXCEPTION
                'F1-FIN.04 abortada: entidade transversal ausente: %',
                v_obj;
        END IF;
    END LOOP;

    /* Integridade estrutural previa do financeiro. */
    SELECT count(*)
    INTO v_count
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

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'V2.1 abortada: existem % tabela(s) de financeiro sem PK.', v_count;
    END IF;

    SELECT count(*)
    INTO v_count
    FROM pg_constraint con
    JOIN pg_class c
      ON c.oid = con.conrelid
    JOIN pg_namespace n
      ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND NOT con.convalidated;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'V2.1 abortada: existem % constraint(s) nao validadas.', v_count;
    END IF;
END
$$;

\echo 'PRE-VALIDACAO: PASS'

/* ============================================================================
   V2.2 — SNAPSHOT DE CONTAGENS ANTES DA CORRECAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.2 - SNAPSHOT ANTES'
\echo '============================================================'

SELECT 'public.centro_custo' AS objeto, COUNT(*) AS registros
FROM public.centro_custo
UNION ALL
SELECT 'financeiro.centro_custo', COUNT(*)
FROM financeiro.centro_custo
UNION ALL
SELECT 'public.forma_pagamento', COUNT(*)
FROM public.forma_pagamento
UNION ALL
SELECT 'financeiro.forma_pagamento', COUNT(*)
FROM financeiro.forma_pagamento
UNION ALL
SELECT 'public.empresa', COUNT(*)
FROM public.empresa
UNION ALL
SELECT 'public.tipo_documento', COUNT(*)
FROM public.tipo_documento
ORDER BY objeto;

/* ============================================================================
   V2.3 — MIGRAR CENTROS DE CUSTO PARA A AUTORIDADE FINANCEIRO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.3 - MIGRACAO CENTRO_CUSTO'
\echo '============================================================'

/*
   Apenas campos existentes na estrutura financeira atual sao migrados.
   A tabela public.centro_custo NAO e removida nesta V2.1.
*/
INSERT INTO financeiro.centro_custo (
    id_centro_custo,
    codigo,
    descricao,
    ativo
)
SELECT
    p.id_centro_custo,
    p.codigo,
    p.descricao,
    COALESCE(p.ativo, TRUE)
FROM public.centro_custo p
ON CONFLICT (id_centro_custo) DO UPDATE
SET
    codigo = EXCLUDED.codigo,
    descricao = EXCLUDED.descricao,
    ativo = EXCLUDED.ativo;

/* Ajustar sequence apos insercao explicita de IDs. */
SELECT setval(
    pg_get_serial_sequence(
        'financeiro.centro_custo',
        'id_centro_custo'
    ),
    COALESCE(
        (SELECT MAX(id_centro_custo) FROM financeiro.centro_custo),
        1
    ),
    EXISTS (
        SELECT 1
        FROM financeiro.centro_custo
    )
);

/* ============================================================================
   V2.4 — MIGRAR FORMAS DE PAGAMENTO PARA A AUTORIDADE FINANCEIRO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.4 - MIGRACAO FORMA_PAGAMENTO'
\echo '============================================================'

INSERT INTO financeiro.forma_pagamento (
    id_forma_pagamento,
    descricao,
    ativo
)
SELECT
    p.id_forma_pagamento,
    p.descricao,
    COALESCE(p.ativo, TRUE)
FROM public.forma_pagamento p
ON CONFLICT (id_forma_pagamento) DO UPDATE
SET
    descricao = EXCLUDED.descricao,
    ativo = EXCLUDED.ativo;

SELECT setval(
    pg_get_serial_sequence(
        'financeiro.forma_pagamento',
        'id_forma_pagamento'
    ),
    COALESCE(
        (SELECT MAX(id_forma_pagamento) FROM financeiro.forma_pagamento),
        1
    ),
    EXISTS (
        SELECT 1
        FROM financeiro.forma_pagamento
    )
);

/* ============================================================================
   V2.5 — POPULAR DOMINIOS FINANCEIROS MINIMOS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.5 - DOMINIOS FINANCEIROS'
\echo '============================================================'

/*
   Naturezas permitidas pela constraint existente:
   R, D, T, A, I, P, L.

   V2.1: antes dos INSERTs, valida os comprimentos dos codigos propostos
   contra os limites reais das colunas do banco. O script se adapta ao
   contrato existente; nao amplia VARCHAR para acomodar dados de seed.
*/
DO $$
DECLARE
    v_tipo_lancamento_max integer;
    v_status_lancamento_max integer;
    v_tipo_movimentacao_max integer;
    v_valor text;
BEGIN
    SELECT character_maximum_length
      INTO v_tipo_lancamento_max
      FROM information_schema.columns
     WHERE table_schema = 'financeiro'
       AND table_name = 'tipo_lancamento'
       AND column_name = 'codigo';

    SELECT character_maximum_length
      INTO v_status_lancamento_max
      FROM information_schema.columns
     WHERE table_schema = 'financeiro'
       AND table_name = 'status_lancamento'
       AND column_name = 'codigo';

    SELECT character_maximum_length
      INTO v_tipo_movimentacao_max
      FROM information_schema.columns
     WHERE table_schema = 'financeiro'
       AND table_name = 'tipo_movimentacao'
       AND column_name = 'codigo';

    IF v_tipo_lancamento_max IS NULL
       OR v_status_lancamento_max IS NULL
       OR v_tipo_movimentacao_max IS NULL THEN
        RAISE EXCEPTION
            'V2.1 abortada: nao foi possivel determinar os limites dos codigos de dominio.';
    END IF;

    FOREACH v_valor IN ARRAY ARRAY[
        'RECEITA',
        'DESPESA',
        'TRANSFER',
        'APORTE',
        'INVEST',
        'PRO_LABORE',
        'LUCRO'
    ]
    LOOP
        IF char_length(v_valor) > v_tipo_lancamento_max THEN
            RAISE EXCEPTION
                'V2.1 abortada: tipo_lancamento.codigo=% excede varchar(%).',
                v_valor,
                v_tipo_lancamento_max;
        END IF;
    END LOOP;

    FOREACH v_valor IN ARRAY ARRAY[
        'PREVISTO',
        'ABERTO',
        'PARCIAL',
        'PAGO',
        'VENCIDO',
        'CANCELADO',
        'ESTORNADO'
    ]
    LOOP
        IF char_length(v_valor) > v_status_lancamento_max THEN
            RAISE EXCEPTION
                'V2.1 abortada: status_lancamento.codigo=% excede varchar(%).',
                v_valor,
                v_status_lancamento_max;
        END IF;
    END LOOP;

    FOREACH v_valor IN ARRAY ARRAY['ENTRADA', 'SAIDA']
    LOOP
        IF char_length(v_valor) > v_tipo_movimentacao_max THEN
            RAISE EXCEPTION
                'V2.1 abortada: tipo_movimentacao.codigo=% excede varchar(%).',
                v_valor,
                v_tipo_movimentacao_max;
        END IF;
    END LOOP;

    RAISE NOTICE
        'Limites validados: tipo_lancamento=% / status_lancamento=% / tipo_movimentacao=%',
        v_tipo_lancamento_max,
        v_status_lancamento_max,
        v_tipo_movimentacao_max;
END
$$;

INSERT INTO financeiro.tipo_lancamento (
    codigo,
    descricao,
    natureza,
    ativo
)
VALUES
    ('RECEITA',       'Receita',                  'R', TRUE),
    ('DESPESA',       'Despesa',                  'D', TRUE),
    ('TRANSFER',      'Transferencia',            'T', TRUE),
    ('APORTE',        'Aporte de capital',        'A', TRUE),
    ('INVEST',        'Investimento',             'I', TRUE),
    ('PRO_LABORE',    'Pro-labore',               'P', TRUE),
    ('LUCRO',         'Distribuicao de lucros',   'L', TRUE)
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO financeiro.status_lancamento (
    codigo,
    descricao,
    ativo
)
VALUES
    ('PREVISTO',   'Previsto',            TRUE),
    ('ABERTO',     'Em aberto',            TRUE),
    ('PARCIAL',    'Parcialmente liquidado', TRUE),
    ('PAGO',       'Liquidado',            TRUE),
    ('VENCIDO',    'Vencido',              TRUE),
    ('CANCELADO',  'Cancelado',            TRUE),
    ('ESTORNADO',  'Estornado',            TRUE)
ON CONFLICT (codigo) DO NOTHING;

INSERT INTO financeiro.tipo_movimentacao (
    codigo,
    descricao,
    entrada_saida,
    ativo
)
VALUES
    ('ENTRADA', 'Entrada financeira', 'E', TRUE),
    ('SAIDA',   'Saida financeira',   'S', TRUE)
ON CONFLICT (codigo) DO NOTHING;

/* ============================================================================
   V2.6 — REDIRECIONAR TIPO_DOCUMENTO PARA PUBLIC
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.6 - TIPO_DOCUMENTO TRANSVERSAL'
\echo '============================================================'

/*
   public.tipo_documento usa integer.
   financeiro.lancamento.id_tipo_documento usa smallint.
   Como public e a autoridade transversal, alinhamos a FK ao tipo integer.
*/
ALTER TABLE financeiro.lancamento
    DROP CONSTRAINT IF EXISTS fk_lancamento_tipo_documento;

ALTER TABLE financeiro.lancamento
    ALTER COLUMN id_tipo_documento TYPE integer
    USING id_tipo_documento::integer;

ALTER TABLE financeiro.lancamento
    ADD CONSTRAINT fk_lancamento_tipo_documento
    FOREIGN KEY (id_tipo_documento)
    REFERENCES public.tipo_documento(id_tipo_documento);

/* ============================================================================
   V2.7 — REDIRECIONAR FKS TRANSVERSAIS DO SCHEMA FINANCEIRO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.7 - REDIRECIONAMENTO DE FKS TRANSVERSAIS'
\echo '============================================================'

/*
   Preserva nome, colunas e regras ON UPDATE / ON DELETE.
   Exclui tipo_documento, ja tratado acima por causa do alinhamento de tipo.
*/
DO $$
DECLARE
    r record;
    v_definition text;
    v_new_definition text;
BEGIN
    FOR r IN
        SELECT
            con.oid AS constraint_oid,
            con.conname,
            src_ns.nspname AS source_schema,
            src.relname AS source_table,
            tgt_ns.nspname AS target_schema,
            tgt.relname AS target_table,
            pg_get_constraintdef(con.oid, TRUE) AS definition
        FROM pg_constraint con
        JOIN pg_class src
          ON src.oid = con.conrelid
        JOIN pg_namespace src_ns
          ON src_ns.oid = src.relnamespace
        JOIN pg_class tgt
          ON tgt.oid = con.confrelid
        JOIN pg_namespace tgt_ns
          ON tgt_ns.oid = tgt.relnamespace
        WHERE con.contype = 'f'
          AND src_ns.nspname = 'financeiro'
          AND tgt_ns.nspname = 'financeiro'
          AND tgt.relname IN (
              'empresa',
              'cliente',
              'fornecedor',
              'usuario'
          )
        ORDER BY src.relname, con.conname
    LOOP
        v_definition := r.definition;

        v_new_definition := replace(
            v_definition,
            format(
                'REFERENCES %I.%I',
                r.target_schema,
                r.target_table
            ),
            format(
                'REFERENCES %I.%I',
                'public',
                r.target_table
            )
        );

        IF v_new_definition = v_definition THEN
            RAISE EXCEPTION
                'Nao foi possivel reconstruir FK %.% (%). Definicao: %',
                r.source_schema,
                r.source_table,
                r.conname,
                v_definition;
        END IF;

        RAISE NOTICE
            'Redirecionando %.% / %: financeiro.% -> public.%',
            r.source_schema,
            r.source_table,
            r.conname,
            r.target_table,
            r.target_table;

        EXECUTE format(
            'ALTER TABLE %I.%I DROP CONSTRAINT %I',
            r.source_schema,
            r.source_table,
            r.conname
        );

        EXECUTE format(
            'ALTER TABLE %I.%I ADD CONSTRAINT %I %s',
            r.source_schema,
            r.source_table,
            r.conname,
            v_new_definition
        );
    END LOOP;
END
$$;

/* ============================================================================
   V2.8 — VALIDAR QUE COPIAS TRANSVERSAIS FINANCEIRO NAO TEM MAIS FKS RECEBIDAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.8 - VALIDACAO ANTES DOS DROPS'
\echo '============================================================'

DO $$
DECLARE
    v_count bigint;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM pg_constraint con
    JOIN pg_class tgt
      ON tgt.oid = con.confrelid
    JOIN pg_namespace tgt_ns
      ON tgt_ns.oid = tgt.relnamespace
    WHERE con.contype = 'f'
      AND tgt_ns.nspname = 'financeiro'
      AND tgt.relname IN (
          'empresa',
          'cliente',
          'fornecedor',
          'usuario',
          'tipo_documento'
      );

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'V2 abortada antes dos DROPs: ainda existem % FK(s) apontando para copias transversais em financeiro.',
            v_count;
    END IF;
END
$$;

/* ============================================================================
   V2.9 — REMOVER SOMENTE COPIAS TRANSVERSAIS VAZIAS DE FINANCEIRO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.9 - REMOCAO DAS COPIAS TRANSVERSAIS VAZIAS'
\echo '============================================================'

/* Sem CASCADE: se houver dependencia inesperada, PostgreSQL aborta tudo. */
DROP TABLE IF EXISTS financeiro.tipo_documento;
DROP TABLE IF EXISTS financeiro.fornecedor;
DROP TABLE IF EXISTS financeiro.cliente;
DROP TABLE IF EXISTS financeiro.empresa;
DROP TABLE IF EXISTS financeiro.usuario;

/* ============================================================================
   V2.10 — VALIDAR MIGRACAO DOS DADOS FINANCEIROS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.10 - VALIDACAO DOS DADOS MIGRADOS'
\echo '============================================================'

DO $$
DECLARE
    v_public bigint;
    v_fin bigint;
    v_missing bigint;
BEGIN
    /* Centro de custo. */
    SELECT count(*) INTO v_public FROM public.centro_custo;

    SELECT count(*)
    INTO v_missing
    FROM public.centro_custo p
    WHERE NOT EXISTS (
        SELECT 1
        FROM financeiro.centro_custo f
        WHERE f.id_centro_custo = p.id_centro_custo
          AND f.descricao = p.descricao
          AND f.ativo IS NOT DISTINCT FROM COALESCE(p.ativo, TRUE)
    );

    IF v_missing <> 0 THEN
        RAISE EXCEPTION
            'Falha na migracao de centro_custo: % registro(s) de public nao foram reproduzidos corretamente em financeiro.',
            v_missing;
    END IF;

    SELECT count(*) INTO v_fin FROM financeiro.centro_custo;

    RAISE NOTICE
        'centro_custo: public=% / financeiro=% / faltantes=0',
        v_public,
        v_fin;

    /* Forma de pagamento. */
    SELECT count(*) INTO v_public FROM public.forma_pagamento;

    SELECT count(*)
    INTO v_missing
    FROM public.forma_pagamento p
    WHERE NOT EXISTS (
        SELECT 1
        FROM financeiro.forma_pagamento f
        WHERE f.id_forma_pagamento = p.id_forma_pagamento
          AND f.descricao = p.descricao
          AND f.ativo IS NOT DISTINCT FROM COALESCE(p.ativo, TRUE)
    );

    IF v_missing <> 0 THEN
        RAISE EXCEPTION
            'Falha na migracao de forma_pagamento: % registro(s) de public nao foram reproduzidos corretamente em financeiro.',
            v_missing;
    END IF;

    SELECT count(*) INTO v_fin FROM financeiro.forma_pagamento;

    RAISE NOTICE
        'forma_pagamento: public=% / financeiro=% / faltantes=0',
        v_public,
        v_fin;
END
$$;

/* ============================================================================
   V2.11 — REAUDITORIA DAS FKS SEGUNDO A ARQUITETURA DEFINIDA
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.11 - REAUDITORIA DE FKS'
\echo '============================================================'

WITH autoridade(table_name, schema_autoridade) AS (
    VALUES
        ('empresa', 'public'),
        ('cliente', 'public'),
        ('fornecedor', 'public'),
        ('usuario', 'public'),
        ('tipo_documento', 'public'),

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
    target_ns.nspname AS target_schema,
    target.relname AS target_table,
    a.schema_autoridade AS schema_esperado,
    CASE
        WHEN target_ns.nspname = a.schema_autoridade
            THEN 'OK'
        ELSE 'DIVERGENTE'
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
  AND source_ns.nspname = 'financeiro'
ORDER BY
    status DESC,
    source.relname,
    con.conname;

/* ============================================================================
   V2.12 — VALIDACAO AUTOMATICA FINAL DE FKS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.12 - VALIDACAO AUTOMATICA FINAL'
\echo '============================================================'

DO $$
DECLARE
    v_count bigint;
BEGIN
    /* Nenhuma FK do financeiro pode apontar para as copias removidas. */
    SELECT count(*)
    INTO v_count
    FROM pg_constraint con
    JOIN pg_class src
      ON src.oid = con.conrelid
    JOIN pg_namespace src_ns
      ON src_ns.oid = src.relnamespace
    JOIN pg_class tgt
      ON tgt.oid = con.confrelid
    JOIN pg_namespace tgt_ns
      ON tgt_ns.oid = tgt.relnamespace
    WHERE con.contype = 'f'
      AND src_ns.nspname = 'financeiro'
      AND (
          (tgt.relname IN (
              'empresa',
              'cliente',
              'fornecedor',
              'usuario',
              'tipo_documento'
          ) AND tgt_ns.nspname <> 'public')
          OR
          (tgt.relname IN (
              'banco',
              'conta_bancaria',
              'forma_pagamento',
              'conciliacao_bancaria',
              'lancamento_parcela',
              'centro_custo'
          ) AND tgt_ns.nspname <> 'financeiro')
      );

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'V2.1 falhou na reauditoria: % FK(s) do nucleo financeiro contrariando a arquitetura.',
            v_count;
    END IF;

    /* Constraints nao validadas. */
    SELECT count(*)
    INTO v_count
    FROM pg_constraint con
    JOIN pg_class c
      ON c.oid = con.conrelid
    JOIN pg_namespace n
      ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND NOT con.convalidated;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'V2.1 falhou: % constraint(s) nao validadas no schema financeiro.',
            v_count;
    END IF;

    /* Tabelas sem PK. */
    SELECT count(*)
    INTO v_count
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

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'V2.1 falhou: % tabela(s) de financeiro sem PK.',
            v_count;
    END IF;

    /* Dominios minimos precisam estar populados. */
    IF NOT EXISTS (SELECT 1 FROM financeiro.tipo_lancamento) THEN
        RAISE EXCEPTION 'V2.1 falhou: tipo_lancamento continua vazio.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM financeiro.status_lancamento) THEN
        RAISE EXCEPTION 'V2.1 falhou: status_lancamento continua vazio.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM financeiro.tipo_movimentacao) THEN
        RAISE EXCEPTION 'V2.1 falhou: tipo_movimentacao continua vazio.';
    END IF;
END
$$;

/* ============================================================================
   V2.13 — OBJETOS LEGADOS DE PUBLIC PRESERVADOS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.13 - PUBLIC FINANCEIRO LEGADO PRESERVADO'
\echo '============================================================'

SELECT
    n.nspname AS schema_name,
    c.relname AS table_name,
    CASE
        WHEN c.relname IN (
            'banco',
            'centro_custo',
            'conciliacao_bancaria',
            'conta_bancaria',
            'forma_pagamento',
            'lancamento_parcela',
            'lancamento_financeiro'
        )
        THEN 'LEGADO_PRESERVADO_NESTA_V2_1'
        ELSE 'OUTRO'
    END AS status
FROM pg_class c
JOIN pg_namespace n
  ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relkind IN ('r', 'p')
  AND c.relname IN (
      'banco',
      'centro_custo',
      'conciliacao_bancaria',
      'conta_bancaria',
      'forma_pagamento',
      'lancamento_parcela',
      'lancamento_financeiro'
  )
ORDER BY c.relname;

/* ============================================================================
   V2.14 — RESUMO POS-CORRECAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.14 - RESUMO POS-CORRECAO'
\echo '============================================================'

SELECT
    (SELECT COUNT(*)
     FROM pg_class c
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'financeiro'
       AND c.relkind IN ('r', 'p')) AS tabelas_financeiro,

    (SELECT COUNT(*)
     FROM pg_constraint con
     JOIN pg_class c ON c.oid = con.conrelid
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'financeiro') AS constraints_financeiro,

    (SELECT COUNT(*)
     FROM pg_constraint con
     JOIN pg_class c ON c.oid = con.conrelid
     JOIN pg_namespace n ON n.oid = c.relnamespace
     WHERE n.nspname = 'financeiro'
       AND con.contype = 'f') AS fks_financeiro,

    (SELECT COUNT(*) FROM financeiro.centro_custo)
        AS centros_custo_financeiro,

    (SELECT COUNT(*) FROM financeiro.forma_pagamento)
        AS formas_pagamento_financeiro,

    (SELECT COUNT(*) FROM financeiro.tipo_lancamento)
        AS tipos_lancamento,

    (SELECT COUNT(*) FROM financeiro.status_lancamento)
        AS status_lancamento,

    (SELECT COUNT(*) FROM financeiro.tipo_movimentacao)
        AS tipos_movimentacao;

/* ============================================================================
   V2.15 — CERTIFICACAO DA ETAPA F1-FIN.4
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V2.15 - CERTIFICACAO F1-FIN.4'
\echo '============================================================'

WITH metricas AS (
    SELECT
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
              AND NOT EXISTS (
                  SELECT 1
                  FROM pg_constraint con
                  WHERE con.conrelid = c.oid
                    AND con.contype = 'p'
              )
        ) AS tabelas_sem_pk,

        (
            SELECT COUNT(*)
            FROM pg_class c
            JOIN pg_namespace n
              ON n.oid = c.relnamespace
            WHERE n.nspname = 'financeiro'
              AND c.relkind IN ('r', 'p')
              AND c.relname IN (
                  'empresa',
                  'cliente',
                  'fornecedor',
                  'usuario',
                  'tipo_documento'
              )
        ) AS copias_transversais_restantes
)
SELECT
    constraints_nao_validadas,
    tabelas_sem_pk,
    copias_transversais_restantes,
    CASE
        WHEN constraints_nao_validadas = 0
         AND tabelas_sem_pk = 0
         AND copias_transversais_restantes = 0
        THEN 'F1_FIN_4_APROVADA'
        ELSE 'F1_FIN_4_PENDENTE'
    END AS status
FROM metricas;

\echo ''
\echo '============================================================'
\echo ' F1-FIN MASTER V2 CONCLUIDA'
\echo '============================================================'
\echo ' AUTORIDADE FINANCEIRA .............. financeiro'
\echo ' AUTORIDADE CORPORATIVA ............. public'
\echo ' TRANSVERSAIS REDIRECIONADAS ........ SIM'
\echo ' CENTRO_CUSTO MIGRADO ............... SIM'
\echo ' FORMA_PAGAMENTO MIGRADA ............ SIM'
\echo ' DOMINIOS MINIMOS POPULADOS ......... SIM'
\echo ' PUBLIC FINANCEIRO LEGADO ........... PRESERVADO'
\echo ' DROPS COM CASCADE .................. NAO'
\echo '============================================================'

/* ============================================================================
   DOCUMENTACAO DAS TABELAS FINANCEIRAS
   ============================================================================ */

COMMENT ON TABLE financeiro.anexo IS
    'Anexos vinculados a lancamentos financeiros para suporte documental e rastreabilidade.';

COMMENT ON TABLE financeiro.categoria IS
    'Categorias do plano de contas financeiro, subordinadas aos grupos contabeis ou gerenciais.';

COMMENT ON TABLE financeiro.configuracao IS
    'Configuracoes gerais e parametros operacionais do modulo financeiro.';

COMMENT ON TABLE financeiro.conta IS
    'Contas analiticas do plano de contas utilizadas na classificacao dos lancamentos financeiros.';

COMMENT ON TABLE financeiro.forma_pagamento IS
    'Formas de pagamento utilizadas em lancamentos, recebimentos e pagamentos do modulo financeiro.';

COMMENT ON TABLE financeiro.grupo IS
    'Grupos principais utilizados na organizacao hierarquica do plano de contas financeiro.';

COMMENT ON TABLE financeiro.historico_lancamento IS
    'Historico de alteracoes e eventos associados aos lancamentos financeiros.';

COMMENT ON TABLE financeiro.lancamento IS
    'Entidade central de contas a pagar e receber, representando compromissos e direitos financeiros.';

COMMENT ON TABLE financeiro.lancamento_parcela IS
    'Parcelas derivadas de lancamentos financeiros, com controle de vencimento, valores e liquidacao.';

COMMENT ON TABLE financeiro.pagamento IS
    'Registros de pagamentos e recebimentos vinculados a parcelas e contas bancarias.';

COMMENT ON TABLE financeiro.status_lancamento IS
    'Dominio dos status operacionais utilizados pelos lancamentos financeiros.';

COMMENT ON TABLE financeiro.subcategoria IS
    'Subcategorias do plano de contas financeiro subordinadas as categorias.';

COMMENT ON TABLE financeiro.tipo_lancamento IS
    'Dominio dos tipos de lancamento utilizados para classificar receitas, despesas e demais movimentos financeiros.';

/* ============================================================================
   FIM DA DOCUMENTACAO DAS TABELAS FINANCEIRAS
   ============================================================================ */

COMMIT;

\echo ''
\echo '============================================================'
\echo ' COMMIT CONCLUIDO'
\echo ' PROXIMA ETAPA: F1-FIN.5'
\echo '============================================================'






