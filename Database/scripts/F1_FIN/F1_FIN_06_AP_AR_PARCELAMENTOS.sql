/* ============================================================================
   WMA TRAVEL ERP
   F1-FIN MASTER V4.1.2 — TESTE FUNCIONAL CONTROLADO AP/AR

   PostgreSQL : 18.x
   Banco      : wma_travel
   Etapa      : F1-FIN.6
   Modo       : TESTE FUNCIONAL / ROLLBACK OBRIGATORIO

   OBJETIVO
   --------
   Validar funcionalmente o modelo unificado:

       financeiro.lancamento
           -> financeiro.lancamento_parcela
               -> financeiro.pagamento

   DIFERENCIAL DA V4.1.2
   ---------------------
   Esta versao detecta automaticamente colunas GENERATED e evita
   INSERT/UPDATE direto nessas colunas.

   CENARIOS
   --------
   A. Contas a receber.
   B. Contas a pagar.
   C. Parcelamento.
   D. Recebimento parcial.
   E. Liquidacao total.
   F. Protecoes de constraints.
   G. Certificacao funcional.

   SEGURANCA
   ---------
   - Transacao unica.
   - ON_ERROR_STOP.
   - Nenhum DROP permanente.
   - Nenhum CASCADE.
   - Nenhum dado artificial persistido.
   - ROLLBACK obrigatorio ao final.
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
\echo ' F1-FIN MASTER V4.1.2 - TESTE FUNCIONAL AP/AR'
\echo ' ETAPA F1-FIN.6'
\echo ' MODO: TESTE CONTROLADO / ROLLBACK'
\echo '============================================================'

/* ============================================================================
   V4.1.2.0 — AMBIENTE
   ============================================================================ */

\echo ''
\echo '=== V4.1.2.0 - AMBIENTE ==='

SELECT
    current_database() AS banco,
    current_user AS usuario,
    current_setting('server_version') AS postgresql,
    current_setting('server_encoding') AS server_encoding,
    current_setting('client_encoding') AS client_encoding,
    CURRENT_TIMESTAMP AS executado_em;

/* ============================================================================
   V4.1.2.1 — PRE-VALIDACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.1 - PRE-VALIDACAO'
\echo '============================================================'

DO $$
DECLARE
    v_count bigint;
BEGIN
    IF current_database() <> 'wma_travel' THEN
        RAISE EXCEPTION
            'V4.1.2 abortada: banco atual %, esperado wma_travel.',
            current_database();
    END IF;

    IF to_regclass('financeiro.lancamento') IS NULL
       OR to_regclass('financeiro.lancamento_parcela') IS NULL
       OR to_regclass('financeiro.pagamento') IS NULL
       OR to_regclass('financeiro.tipo_lancamento') IS NULL
       OR to_regclass('financeiro.status_lancamento') IS NULL
       OR to_regclass('financeiro.conta') IS NULL
       OR to_regclass('financeiro.forma_pagamento') IS NULL
       OR to_regclass('financeiro.conta_bancaria') IS NULL THEN
        RAISE EXCEPTION
            'V4.1.2 abortada: estrutura AP/AR incompleta.';
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.conta
    WHERE ativo IS TRUE
      AND aceita_lancamento IS TRUE;

    IF v_count = 0 THEN
        RAISE EXCEPTION
            'V4.1.2 abortada: nenhuma conta analitica apta a lancamento.';
    END IF;
END
$$;

\echo 'PRE-VALIDACAO: PASS'

/* ============================================================================
   V4.1.2.2 — DETECCAO DE COLUNAS GENERATED
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.2 - COLUNAS GENERATED'
\echo '============================================================'

CREATE TEMP TABLE f1_fin_v412_generated AS
SELECT
    table_name,
    column_name,
    is_generated,
    generation_expression
FROM information_schema.columns
WHERE table_schema = 'financeiro'
  AND table_name IN (
      'lancamento',
      'lancamento_parcela'
  )
  AND column_name IN (
      'valor_liquido',
      'saldo',
      'valor_pago'
  )
ORDER BY table_name, column_name;

TABLE f1_fin_v412_generated;

/* ============================================================================
   V4.1.2.3 — CONTEXTO DE TESTE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.3 - IDS DE DOMINIO'
\echo '============================================================'

CREATE TEMP TABLE f1_fin_v412_ctx AS
SELECT
    (
        SELECT id_tipo_lancamento
        FROM financeiro.tipo_lancamento
        WHERE ativo IS TRUE
          AND upper(codigo) = 'RECEITA'
        ORDER BY id_tipo_lancamento
        LIMIT 1
    ) AS id_tipo_receita,

    (
        SELECT id_tipo_lancamento
        FROM financeiro.tipo_lancamento
        WHERE ativo IS TRUE
          AND upper(codigo) = 'DESPESA'
        ORDER BY id_tipo_lancamento
        LIMIT 1
    ) AS id_tipo_despesa,

    (
        SELECT id_status
        FROM financeiro.status_lancamento
        WHERE ativo IS TRUE
          AND upper(codigo) = 'ABERTO'
        ORDER BY id_status
        LIMIT 1
    ) AS id_status_aberto,

    (
        SELECT id_status
        FROM financeiro.status_lancamento
        WHERE ativo IS TRUE
          AND upper(codigo) = 'PARCIAL'
        ORDER BY id_status
        LIMIT 1
    ) AS id_status_parcial,

    (
        SELECT id_status
        FROM financeiro.status_lancamento
        WHERE ativo IS TRUE
          AND upper(codigo) = 'PAGO'
        ORDER BY id_status
        LIMIT 1
    ) AS id_status_pago,

    (
        SELECT id_conta
        FROM financeiro.conta
        WHERE ativo IS TRUE
          AND aceita_lancamento IS TRUE
        ORDER BY id_conta
        LIMIT 1
    ) AS id_conta,

    (
        SELECT id_empresa
        FROM public.empresa
        ORDER BY id_empresa
        LIMIT 1
    ) AS id_empresa,

    (
        SELECT id_forma_pagamento
        FROM financeiro.forma_pagamento
        WHERE ativo IS TRUE
        ORDER BY id_forma_pagamento
        LIMIT 1
    ) AS id_forma_pagamento,

    (
        SELECT id_conta_bancaria
        FROM financeiro.conta_bancaria
        WHERE COALESCE(ativo, TRUE) IS TRUE
        ORDER BY id_conta_bancaria
        LIMIT 1
    ) AS id_conta_bancaria;

DO $$
DECLARE
    r record;
BEGIN
    SELECT * INTO r FROM f1_fin_v412_ctx;

    IF r.id_tipo_receita IS NULL
       OR r.id_tipo_despesa IS NULL THEN
        RAISE EXCEPTION
            'V4.1.2 abortada: tipos RECEITA/DESPESA nao encontrados.';
    END IF;

    IF r.id_status_aberto IS NULL
       OR r.id_status_parcial IS NULL
       OR r.id_status_pago IS NULL THEN
        RAISE EXCEPTION
            'V4.1.2 abortada: status ABERTO/PARCIAL/PAGO incompletos.';
    END IF;

    IF r.id_conta IS NULL THEN
        RAISE EXCEPTION
            'V4.1.2 abortada: conta analitica nao encontrada.';
    END IF;

    IF r.id_empresa IS NULL THEN
        RAISE EXCEPTION
            'V4.1.2 abortada: public.empresa sem registro.';
    END IF;

    IF r.id_forma_pagamento IS NULL THEN
        RAISE EXCEPTION
            'V4.1.2 abortada: nenhuma forma de pagamento ativa.';
    END IF;
END
$$;

TABLE f1_fin_v412_ctx;

/* ============================================================================
   V4.1.2.4 — CONTA BANCARIA TEMPORARIA, SE NECESSARIO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.4 - APOIO FINANCEIRO TEMPORARIO'
\echo '============================================================'

DO $$
DECLARE
    v_id_banco integer;
    v_id_conta_bancaria integer;
BEGIN
    SELECT id_conta_bancaria
    INTO v_id_conta_bancaria
    FROM f1_fin_v412_ctx;

    IF v_id_conta_bancaria IS NULL THEN
        SELECT id_banco
        INTO v_id_banco
        FROM financeiro.banco
        WHERE COALESCE(ativo, TRUE) IS TRUE
        ORDER BY id_banco
        LIMIT 1;

        IF v_id_banco IS NULL THEN
            INSERT INTO financeiro.banco (
                codigo_banco,
                nome,
                ativo
            )
            VALUES (
                '999',
                'BANCO TESTE F1-FIN',
                TRUE
            )
            RETURNING id_banco
            INTO v_id_banco;
        END IF;

        INSERT INTO financeiro.conta_bancaria (
            id_banco,
            agencia,
            conta,
            digito,
            tipo,
            saldo_inicial,
            ativo
        )
        VALUES (
            v_id_banco,
            '0001',
            'F1FINV412',
            '0',
            'TESTE',
            0,
            TRUE
        )
        RETURNING id_conta_bancaria
        INTO v_id_conta_bancaria;

        UPDATE f1_fin_v412_ctx
        SET id_conta_bancaria = v_id_conta_bancaria;
    END IF;
END
$$;

TABLE f1_fin_v412_ctx;

/* ============================================================================
   V4.1.2.5 — FUNCOES TEMPORARIAS AUXILIARES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.5 - AUXILIARES PARA GENERATED'
\echo '============================================================'

CREATE OR REPLACE FUNCTION pg_temp.f1_fin_is_generated(
    p_table text,
    p_column text
)
RETURNS boolean
LANGUAGE sql
AS $$
    SELECT COALESCE(
        (
            SELECT is_generated = 'ALWAYS'
            FROM information_schema.columns
            WHERE table_schema = 'financeiro'
              AND table_name = p_table
              AND column_name = p_column
        ),
        FALSE
    );
$$;

/* ============================================================================
   V4.1.2.6 — CENARIO A: CONTAS A RECEBER
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.6 - CENARIO A: CONTAS A RECEBER'
\echo '============================================================'

CREATE TEMP TABLE f1_fin_v412_receber (
    id_lancamento bigint,
    id_parcela_1 bigint,
    id_parcela_2 bigint
);

DO $$
DECLARE
    c record;
    v_lanc bigint;
    v_p1 bigint;
    v_p2 bigint;
    v_sql text;
    v_cols text;
    v_vals text;
BEGIN
    SELECT * INTO c FROM f1_fin_v412_ctx;

    v_cols :=
        'numero,id_empresa,id_tipo_lancamento,id_status,id_conta,' ||
        'competencia,emissao,vencimento,descricao,valor_bruto,' ||
        'desconto,acrescimo,juros,multa,valor_pago,ativo';

    v_vals :=
        quote_literal('F1FIN-V412-REC-001') || ',' ||
        c.id_empresa || ',' ||
        c.id_tipo_receita || ',' ||
        c.id_status_aberto || ',' ||
        c.id_conta || ',' ||
        'CURRENT_DATE,CURRENT_DATE,CURRENT_DATE + 30,' ||
        quote_literal('Teste funcional contas a receber') || ',' ||
        '1000.00,0,0,0,0,0,TRUE';

    IF NOT pg_temp.f1_fin_is_generated('lancamento','valor_liquido') THEN
        v_cols := v_cols || ',valor_liquido';
        v_vals := v_vals || ',1000.00';
    END IF;

    IF NOT pg_temp.f1_fin_is_generated('lancamento','saldo') THEN
        v_cols := v_cols || ',saldo';
        v_vals := v_vals || ',1000.00';
    END IF;

    v_sql :=
        'INSERT INTO financeiro.lancamento (' || v_cols || ') ' ||
        'VALUES (' || v_vals || ') RETURNING id_lancamento';

    EXECUTE v_sql INTO v_lanc;

    /* Parcela 1 */
    IF pg_temp.f1_fin_is_generated('lancamento_parcela','saldo') THEN
        INSERT INTO financeiro.lancamento_parcela (
            id_lancamento,
            numero_parcela,
            vencimento,
            valor,
            valor_pago,
            id_status,
            observacao
        )
        VALUES (
            v_lanc,
            1,
            CURRENT_DATE + 15,
            500.00,
            0,
            c.id_status_aberto,
            'Parcela 1 - teste receber'
        )
        RETURNING id_parcela INTO v_p1;
    ELSE
        INSERT INTO financeiro.lancamento_parcela (
            id_lancamento,
            numero_parcela,
            vencimento,
            valor,
            valor_pago,
            saldo,
            id_status,
            observacao
        )
        VALUES (
            v_lanc,
            1,
            CURRENT_DATE + 15,
            500.00,
            0,
            500.00,
            c.id_status_aberto,
            'Parcela 1 - teste receber'
        )
        RETURNING id_parcela INTO v_p1;
    END IF;

    /* Parcela 2 */
    IF pg_temp.f1_fin_is_generated('lancamento_parcela','saldo') THEN
        INSERT INTO financeiro.lancamento_parcela (
            id_lancamento,
            numero_parcela,
            vencimento,
            valor,
            valor_pago,
            id_status,
            observacao
        )
        VALUES (
            v_lanc,
            2,
            CURRENT_DATE + 30,
            500.00,
            0,
            c.id_status_aberto,
            'Parcela 2 - teste receber'
        )
        RETURNING id_parcela INTO v_p2;
    ELSE
        INSERT INTO financeiro.lancamento_parcela (
            id_lancamento,
            numero_parcela,
            vencimento,
            valor,
            valor_pago,
            saldo,
            id_status,
            observacao
        )
        VALUES (
            v_lanc,
            2,
            CURRENT_DATE + 30,
            500.00,
            0,
            500.00,
            c.id_status_aberto,
            'Parcela 2 - teste receber'
        )
        RETURNING id_parcela INTO v_p2;
    END IF;

    INSERT INTO f1_fin_v412_receber
    VALUES (v_lanc, v_p1, v_p2);
END
$$;

TABLE f1_fin_v412_receber;

/* ============================================================================
   V4.1.2.7 — RECEBIMENTO PARCIAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.7 - RECEBIMENTO PARCIAL'
\echo '============================================================'

DO $$
DECLARE
    c record;
    r record;
BEGIN
    SELECT * INTO c FROM f1_fin_v412_ctx;
    SELECT * INTO r FROM f1_fin_v412_receber;

    INSERT INTO financeiro.pagamento (
        id_parcela,
        id_conta_bancaria,
        id_forma_pagamento,
        data_pagamento,
        valor,
        juros,
        desconto,
        multa,
        documento,
        observacao
    )
    VALUES (
        r.id_parcela_1,
        c.id_conta_bancaria,
        c.id_forma_pagamento,
        CURRENT_DATE,
        200.00,
        0,
        0,
        0,
        'F1FIN-V412-REC-PARC',
        'Recebimento parcial controlado'
    );

    IF pg_temp.f1_fin_is_generated('lancamento_parcela','saldo') THEN
        UPDATE financeiro.lancamento_parcela
        SET
            valor_pago = 200.00,
            id_status = c.id_status_parcial
        WHERE id_parcela = r.id_parcela_1;
    ELSE
        UPDATE financeiro.lancamento_parcela
        SET
            valor_pago = 200.00,
            saldo = 300.00,
            id_status = c.id_status_parcial
        WHERE id_parcela = r.id_parcela_1;
    END IF;

    IF pg_temp.f1_fin_is_generated('lancamento','saldo') THEN
        UPDATE financeiro.lancamento
        SET
            valor_pago = 200.00,
            id_status = c.id_status_parcial
        WHERE id_lancamento = r.id_lancamento;
    ELSE
        UPDATE financeiro.lancamento
        SET
            valor_pago = 200.00,
            saldo = 800.00,
            id_status = c.id_status_parcial
        WHERE id_lancamento = r.id_lancamento;
    END IF;
END
$$;

SELECT
    l.numero,
    l.valor_bruto,
    l.valor_liquido,
    l.valor_pago,
    l.saldo,
    sl.codigo AS status
FROM financeiro.lancamento l
JOIN financeiro.status_lancamento sl
  ON sl.id_status = l.id_status
WHERE l.numero = 'F1FIN-V412-REC-001';

/* ============================================================================
   V4.1.2.8 — RECEBIMENTO TOTAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.8 - RECEBIMENTO TOTAL'
\echo '============================================================'

DO $$
DECLARE
    c record;
    r record;
BEGIN
    SELECT * INTO c FROM f1_fin_v412_ctx;
    SELECT * INTO r FROM f1_fin_v412_receber;

    INSERT INTO financeiro.pagamento (
        id_parcela,
        id_conta_bancaria,
        id_forma_pagamento,
        data_pagamento,
        valor,
        documento
    )
    VALUES (
        r.id_parcela_1,
        c.id_conta_bancaria,
        c.id_forma_pagamento,
        CURRENT_DATE,
        300.00,
        'F1FIN-V412-REC-P1'
    );

    INSERT INTO financeiro.pagamento (
        id_parcela,
        id_conta_bancaria,
        id_forma_pagamento,
        data_pagamento,
        valor,
        documento
    )
    VALUES (
        r.id_parcela_2,
        c.id_conta_bancaria,
        c.id_forma_pagamento,
        CURRENT_DATE,
        500.00,
        'F1FIN-V412-REC-P2'
    );

    IF pg_temp.f1_fin_is_generated('lancamento_parcela','saldo') THEN
        UPDATE financeiro.lancamento_parcela
        SET
            valor_pago = valor,
            id_status = c.id_status_pago
        WHERE id_parcela IN (r.id_parcela_1, r.id_parcela_2);
    ELSE
        UPDATE financeiro.lancamento_parcela
        SET
            valor_pago = valor,
            saldo = 0,
            id_status = c.id_status_pago
        WHERE id_parcela IN (r.id_parcela_1, r.id_parcela_2);
    END IF;

    IF pg_temp.f1_fin_is_generated('lancamento','saldo') THEN
        UPDATE financeiro.lancamento
        SET
            valor_pago = valor_liquido,
            id_status = c.id_status_pago,
            pagamento = CURRENT_DATE
        WHERE id_lancamento = r.id_lancamento;
    ELSE
        UPDATE financeiro.lancamento
        SET
            valor_pago = valor_liquido,
            saldo = 0,
            id_status = c.id_status_pago,
            pagamento = CURRENT_DATE
        WHERE id_lancamento = r.id_lancamento;
    END IF;
END
$$;

/* ============================================================================
   V4.1.2.9 — CENARIO B: CONTAS A PAGAR
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.9 - CENARIO B: CONTAS A PAGAR'
\echo '============================================================'

CREATE TEMP TABLE f1_fin_v412_pagar (
    id_lancamento bigint,
    id_parcela bigint
);

DO $$
DECLARE
    c record;
    v_lanc bigint;
    v_parc bigint;
    v_sql text;
    v_cols text;
    v_vals text;
BEGIN
    SELECT * INTO c FROM f1_fin_v412_ctx;

    v_cols :=
        'numero,id_empresa,id_tipo_lancamento,id_status,id_conta,' ||
        'competencia,emissao,vencimento,descricao,valor_bruto,' ||
        'desconto,acrescimo,juros,multa,valor_pago,ativo';

    v_vals :=
        quote_literal('F1FIN-V412-PAG-001') || ',' ||
        c.id_empresa || ',' ||
        c.id_tipo_despesa || ',' ||
        c.id_status_aberto || ',' ||
        c.id_conta || ',' ||
        'CURRENT_DATE,CURRENT_DATE,CURRENT_DATE + 10,' ||
        quote_literal('Teste funcional contas a pagar') || ',' ||
        '600.00,0,0,0,0,0,TRUE';

    IF NOT pg_temp.f1_fin_is_generated('lancamento','valor_liquido') THEN
        v_cols := v_cols || ',valor_liquido';
        v_vals := v_vals || ',600.00';
    END IF;

    IF NOT pg_temp.f1_fin_is_generated('lancamento','saldo') THEN
        v_cols := v_cols || ',saldo';
        v_vals := v_vals || ',600.00';
    END IF;

    v_sql :=
        'INSERT INTO financeiro.lancamento (' || v_cols || ') ' ||
        'VALUES (' || v_vals || ') RETURNING id_lancamento';

    EXECUTE v_sql INTO v_lanc;

    IF pg_temp.f1_fin_is_generated('lancamento_parcela','saldo') THEN
        INSERT INTO financeiro.lancamento_parcela (
            id_lancamento,
            numero_parcela,
            vencimento,
            valor,
            valor_pago,
            id_status,
            observacao
        )
        VALUES (
            v_lanc,
            1,
            CURRENT_DATE + 10,
            600.00,
            0,
            c.id_status_aberto,
            'Parcela teste pagar'
        )
        RETURNING id_parcela INTO v_parc;
    ELSE
        INSERT INTO financeiro.lancamento_parcela (
            id_lancamento,
            numero_parcela,
            vencimento,
            valor,
            valor_pago,
            saldo,
            id_status,
            observacao
        )
        VALUES (
            v_lanc,
            1,
            CURRENT_DATE + 10,
            600.00,
            0,
            600.00,
            c.id_status_aberto,
            'Parcela teste pagar'
        )
        RETURNING id_parcela INTO v_parc;
    END IF;

    INSERT INTO f1_fin_v412_pagar
    VALUES (v_lanc, v_parc);
END
$$;

/* ============================================================================
   V4.1.2.10 — PAGAMENTO TOTAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.10 - PAGAMENTO TOTAL'
\echo '============================================================'

DO $$
DECLARE
    c record;
    r record;
BEGIN
    SELECT * INTO c FROM f1_fin_v412_ctx;
    SELECT * INTO r FROM f1_fin_v412_pagar;

    INSERT INTO financeiro.pagamento (
        id_parcela,
        id_conta_bancaria,
        id_forma_pagamento,
        data_pagamento,
        valor,
        documento
    )
    VALUES (
        r.id_parcela,
        c.id_conta_bancaria,
        c.id_forma_pagamento,
        CURRENT_DATE,
        600.00,
        'F1FIN-V412-PAG-001'
    );

    IF pg_temp.f1_fin_is_generated('lancamento_parcela','saldo') THEN
        UPDATE financeiro.lancamento_parcela
        SET
            valor_pago = valor,
            id_status = c.id_status_pago
        WHERE id_parcela = r.id_parcela;
    ELSE
        UPDATE financeiro.lancamento_parcela
        SET
            valor_pago = valor,
            saldo = 0,
            id_status = c.id_status_pago
        WHERE id_parcela = r.id_parcela;
    END IF;

    IF pg_temp.f1_fin_is_generated('lancamento','saldo') THEN
        UPDATE financeiro.lancamento
        SET
            valor_pago = valor_liquido,
            id_status = c.id_status_pago,
            pagamento = CURRENT_DATE
        WHERE id_lancamento = r.id_lancamento;
    ELSE
        UPDATE financeiro.lancamento
        SET
            valor_pago = valor_liquido,
            saldo = 0,
            id_status = c.id_status_pago,
            pagamento = CURRENT_DATE
        WHERE id_lancamento = r.id_lancamento;
    END IF;
END
$$;

/* ============================================================================
   V4.1.2.11 — RESULTADO FUNCIONAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.11 - RESULTADO FUNCIONAL'
\echo '============================================================'

SELECT
    l.numero,
    tl.codigo AS tipo,
    sl.codigo AS status,
    l.valor_bruto,
    l.valor_liquido,
    l.valor_pago,
    l.saldo,
    COUNT(DISTINCT p.id_parcela) AS parcelas,
    COALESCE(SUM(pg.valor),0)::numeric(15,2) AS pagamentos
FROM financeiro.lancamento l
JOIN financeiro.tipo_lancamento tl
  ON tl.id_tipo_lancamento = l.id_tipo_lancamento
JOIN financeiro.status_lancamento sl
  ON sl.id_status = l.id_status
LEFT JOIN financeiro.lancamento_parcela p
  ON p.id_lancamento = l.id_lancamento
LEFT JOIN financeiro.pagamento pg
  ON pg.id_parcela = p.id_parcela
WHERE l.numero IN (
    'F1FIN-V412-REC-001',
    'F1FIN-V412-PAG-001'
)
GROUP BY
    l.numero,
    tl.codigo,
    sl.codigo,
    l.valor_bruto,
    l.valor_liquido,
    l.valor_pago,
    l.saldo
ORDER BY l.numero;

/* ============================================================================
   V4.1.2.12 — TESTES DE PROTECAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.12 - TESTES DE PROTECAO'
\echo '============================================================'

CREATE TEMP TABLE f1_fin_v412_testes (
    teste text PRIMARY KEY,
    resultado text NOT NULL
);

DO $$
DECLARE
    c record;
BEGIN
    SELECT * INTO c FROM f1_fin_v412_ctx;

    BEGIN
        INSERT INTO financeiro.lancamento (
            numero,
            id_empresa,
            id_tipo_lancamento,
            id_status,
            id_conta,
            competencia,
            emissao,
            vencimento,
            valor_bruto
        )
        VALUES (
            'F1FIN-V412-ERR-VALOR',
            c.id_empresa,
            c.id_tipo_despesa,
            c.id_status_aberto,
            c.id_conta,
            CURRENT_DATE,
            CURRENT_DATE,
            CURRENT_DATE,
            -100
        );

        INSERT INTO f1_fin_v412_testes
        VALUES ('valor_bruto_negativo','FALHOU_PROTECAO');
    EXCEPTION
        WHEN check_violation THEN
            INSERT INTO f1_fin_v412_testes
            VALUES ('valor_bruto_negativo','PROTEGIDO');
    END;

    BEGIN
        INSERT INTO financeiro.lancamento_parcela (
            id_lancamento,
            numero_parcela,
            vencimento,
            valor,
            valor_pago
        )
        VALUES (
            (SELECT id_lancamento FROM f1_fin_v412_receber),
            99,
            CURRENT_DATE,
            0,
            0
        );

        INSERT INTO f1_fin_v412_testes
        VALUES ('parcela_valor_zero','FALHOU_PROTECAO');
    EXCEPTION
        WHEN check_violation THEN
            INSERT INTO f1_fin_v412_testes
            VALUES ('parcela_valor_zero','PROTEGIDO');
    END;

    BEGIN
        INSERT INTO financeiro.pagamento (
            id_parcela,
            id_conta_bancaria,
            id_forma_pagamento,
            data_pagamento,
            valor
        )
        VALUES (
            (SELECT id_parcela_1 FROM f1_fin_v412_receber),
            c.id_conta_bancaria,
            c.id_forma_pagamento,
            CURRENT_DATE,
            0
        );

        INSERT INTO f1_fin_v412_testes
        VALUES ('pagamento_valor_zero','FALHOU_PROTECAO');
    EXCEPTION
        WHEN check_violation THEN
            INSERT INTO f1_fin_v412_testes
            VALUES ('pagamento_valor_zero','PROTEGIDO');
    END;

    BEGIN
        INSERT INTO financeiro.pagamento (
            id_parcela,
            id_conta_bancaria,
            id_forma_pagamento,
            data_pagamento,
            valor
        )
        VALUES (
            999999999999,
            c.id_conta_bancaria,
            c.id_forma_pagamento,
            CURRENT_DATE,
            10
        );

        INSERT INTO f1_fin_v412_testes
        VALUES ('pagamento_parcela_inexistente','FALHOU_PROTECAO');
    EXCEPTION
        WHEN foreign_key_violation THEN
            INSERT INTO f1_fin_v412_testes
            VALUES ('pagamento_parcela_inexistente','PROTEGIDO');
    END;
END
$$;

TABLE f1_fin_v412_testes;

/* ============================================================================
   V4.1.2.13 — REAUDITORIA
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.13 - REAUDITORIA'
\echo '============================================================'

WITH teste_lancamentos AS (
    SELECT *
    FROM financeiro.lancamento
    WHERE numero IN (
        'F1FIN-V412-REC-001',
        'F1FIN-V412-PAG-001'
    )
)
SELECT
    (
        SELECT COUNT(*)
        FROM teste_lancamentos
        WHERE valor_liquido IS DISTINCT FROM (
            COALESCE(valor_bruto,0)
            - COALESCE(desconto,0)
            + COALESCE(acrescimo,0)
            + COALESCE(juros,0)
            + COALESCE(multa,0)
        )::numeric(15,2)
    ) AS lancamentos_liquido_inconsistente,

    (
        SELECT COUNT(*)
        FROM teste_lancamentos
        WHERE saldo IS DISTINCT FROM (
            COALESCE(valor_liquido,0)
            - COALESCE(valor_pago,0)
        )::numeric(15,2)
    ) AS lancamentos_saldo_inconsistente,

    (
        SELECT COUNT(*)
        FROM financeiro.lancamento_parcela p
        JOIN teste_lancamentos l
          ON l.id_lancamento = p.id_lancamento
        WHERE p.saldo IS DISTINCT FROM (
            COALESCE(p.valor,0)
            - COALESCE(p.valor_pago,0)
        )::numeric(15,2)
    ) AS parcelas_saldo_inconsistente;

/* ============================================================================
   V4.1.2.14 — CERTIFICACAO FUNCIONAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' V4.1.2.14 - CERTIFICACAO FUNCIONAL F1-FIN.6'
\echo '============================================================'

WITH protecoes AS (
    SELECT
        COUNT(*) FILTER (
            WHERE resultado = 'PROTEGIDO'
        ) AS protegidos,
        COUNT(*) AS total
    FROM f1_fin_v412_testes
),
funcional AS (
    SELECT
        COUNT(*) FILTER (
            WHERE saldo = 0
              AND valor_pago = valor_liquido
        ) AS lancamentos_liquidados
    FROM financeiro.lancamento
    WHERE numero IN (
        'F1FIN-V412-REC-001',
        'F1FIN-V412-PAG-001'
    )
),
parcelas AS (
    SELECT
        COUNT(*) FILTER (
            WHERE p.saldo = 0
              AND p.valor_pago = p.valor
        ) AS parcelas_liquidadas
    FROM financeiro.lancamento_parcela p
    JOIN financeiro.lancamento l
      ON l.id_lancamento = p.id_lancamento
    WHERE l.numero IN (
        'F1FIN-V412-REC-001',
        'F1FIN-V412-PAG-001'
    )
)
SELECT
    f.lancamentos_liquidados,
    p.parcelas_liquidadas,
    pr.protegidos AS testes_protecao_aprovados,
    pr.total AS testes_protecao_total,
    CASE
        WHEN f.lancamentos_liquidados = 2
         AND p.parcelas_liquidadas = 3
         AND pr.protegidos = pr.total
        THEN 'F1_FIN_6_APROVADA_FUNCIONALMENTE'
        ELSE 'F1_FIN_6_PENDENTE'
    END AS status
FROM funcional f
CROSS JOIN parcelas p
CROSS JOIN protecoes pr;

/* ============================================================================
   V4.1.2.15 — VALIDACAO BLOQUEANTE FINAL
   ============================================================================ */

DO $$
DECLARE
    v_lanc bigint;
    v_parc bigint;
    v_prot bigint;
    v_total bigint;
BEGIN
    SELECT COUNT(*)
    INTO v_lanc
    FROM financeiro.lancamento
    WHERE numero IN (
        'F1FIN-V412-REC-001',
        'F1FIN-V412-PAG-001'
    )
      AND saldo = 0
      AND valor_pago = valor_liquido;

    SELECT COUNT(*)
    INTO v_parc
    FROM financeiro.lancamento_parcela p
    JOIN financeiro.lancamento l
      ON l.id_lancamento = p.id_lancamento
    WHERE l.numero IN (
        'F1FIN-V412-REC-001',
        'F1FIN-V412-PAG-001'
    )
      AND p.saldo = 0
      AND p.valor_pago = p.valor;

    SELECT
        COUNT(*) FILTER (WHERE resultado = 'PROTEGIDO'),
        COUNT(*)
    INTO
        v_prot,
        v_total
    FROM f1_fin_v412_testes;

    IF v_lanc <> 2
       OR v_parc <> 3
       OR v_prot <> v_total THEN
        RAISE EXCEPTION
            'V4.1.2 falhou: lancamentos=% parcelas=% protecoes=%/%',
            v_lanc,
            v_parc,
            v_prot,
            v_total;
    END IF;
END
$$;

/* ============================================================================
   ENCERRAMENTO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN MASTER V4.1.2 CONCLUIDA'
\echo '============================================================'
\echo ' CONTAS A RECEBER ................ TESTADO'
\echo ' CONTAS A PAGAR .................. TESTADO'
\echo ' PARCELAMENTO .................... TESTADO'
\echo ' RECEBIMENTO PARCIAL ............. TESTADO'
\echo ' LIQUIDACAO TOTAL ................ TESTADO'
\echo ' COLUNAS GENERATED ............... RESPEITADAS'
\echo ' PROTECOES DE CONSTRAINT ......... TESTADAS'
\echo ''
\echo ' NENHUM DADO DE TESTE SERA PERSISTIDO.'
\echo ' ROLLBACK OBRIGATORIO A SEGUIR.'
\echo '============================================================'

ROLLBACK;

\echo ''
\echo '============================================================'
\echo ' ROLLBACK CONCLUIDO'
\echo ' F1-FIN.6 TESTADA SEM PERSISTENCIA DE DADOS ARTIFICIAIS'
\echo '============================================================'
