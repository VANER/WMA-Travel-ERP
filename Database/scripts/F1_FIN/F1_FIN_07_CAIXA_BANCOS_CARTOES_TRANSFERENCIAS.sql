/* ============================================================================
   WMA TRAVEL ERP
   F1-FIN.7 — CAIXA, BANCOS, CARTOES E TRANSFERENCIAS

   PostgreSQL : 18.x
   Banco      : wma_travel
   Etapa      : F1-FIN.7
   Modo       : COMPLEMENTACAO CONTROLADA / CERTIFICACAO

   REGRA ARQUITETURAL
   ------------------
   financeiro = autoridade do dominio financeiro
   public     = corporativo / transversal

   OBJETIVO
   --------
   Consolidar em um unico script:
     1. Pre-validacao do nucleo bancario.
     2. Complementacao das lacunas reais:
        - Caixa operacional
        - Transferencias
        - Cartoes
        - Faturas de cartao
     3. Documentacao dos objetos financeiros envolvidos.
     4. Reauditoria estrutural.
     5. Certificacao final da F1-FIN.7.

   ESTRUTURA PRESERVADA
   --------------------
   financeiro.banco
   financeiro.conta_bancaria
   financeiro.tipo_movimentacao
   financeiro.movimentacao_bancaria

   SEGURANCA
   ---------
   - Transacao unica.
   - ON_ERROR_STOP.
   - Sem DROP.
   - Sem CASCADE.
   - CREATE IF NOT EXISTS quando aplicavel.
   - Seeds idempotentes.
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
\echo ' F1-FIN.7 - CAIXA, BANCOS, CARTOES E TRANSFERENCIAS'
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
   2. PRE-VALIDACAO DO NUCLEO EXISTENTE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 2 - PRE-VALIDACAO DO NUCLEO BANCARIO'
\echo '============================================================'

DO $$
DECLARE
    v_count bigint;
BEGIN
    IF current_database() <> current_setting('wma.expected_database') THEN
        RAISE EXCEPTION
            'F1-FIN.7 abortada: banco atual %, esperado %.',
            current_database(),
            current_setting('wma.expected_database');
    END IF;

    IF to_regclass('financeiro.banco') IS NULL
       OR to_regclass('financeiro.conta_bancaria') IS NULL
       OR to_regclass('financeiro.tipo_movimentacao') IS NULL
       OR to_regclass('financeiro.movimentacao_bancaria') IS NULL THEN
        RAISE EXCEPTION
            'F1-FIN.7 abortada: nucleo bancario obrigatorio incompleto.';
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.tipo_movimentacao
    WHERE ativo IS TRUE
      AND entrada_saida = 'E';

    IF v_count = 0 THEN
        RAISE EXCEPTION
            'F1-FIN.7 abortada: tipo de movimentacao ENTRADA ausente.';
    END IF;

    SELECT count(*)
    INTO v_count
    FROM financeiro.tipo_movimentacao
    WHERE ativo IS TRUE
      AND entrada_saida = 'S';

    IF v_count = 0 THEN
        RAISE EXCEPTION
            'F1-FIN.7 abortada: tipo de movimentacao SAIDA ausente.';
    END IF;

    SELECT count(*)
    INTO v_count
    FROM pg_constraint con
    JOIN pg_class c
      ON c.oid = con.conrelid
    JOIN pg_namespace n
      ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relname IN (
          'banco',
          'conta_bancaria',
          'tipo_movimentacao',
          'movimentacao_bancaria'
      )
      AND NOT con.convalidated;

    IF v_count <> 0 THEN
        RAISE EXCEPTION
            'F1-FIN.7 abortada: existem % constraints nao validadas no nucleo bancario.',
            v_count;
    END IF;
END
$$;

\echo 'PRE-VALIDACAO: PASS'

/* ============================================================================
   3. COMPLEMENTAR TIPOS DE MOVIMENTACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 3 - TIPOS DE MOVIMENTACAO'
\echo '============================================================'

/*
   O modelo existente usa entrada_saida = E/S.
   Transferencias serao representadas por dois movimentos vinculados:
     TRANSF_SAI
     TRANSF_ENT
*/

INSERT INTO financeiro.tipo_movimentacao (
    codigo,
    descricao,
    entrada_saida,
    ativo
)
VALUES
    ('TRANSF_SAI', 'Transferencia - Saida',   'S', TRUE),
    ('TRANSF_ENT', 'Transferencia - Entrada', 'E', TRUE)
ON CONFLICT (codigo) DO UPDATE
SET
    descricao = EXCLUDED.descricao,
    entrada_saida = EXCLUDED.entrada_saida,
    ativo = TRUE;

/* ============================================================================
   4. CAIXA OPERACIONAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 4 - CAIXA OPERACIONAL'
\echo '============================================================'

/*
   Caixa e tratado como uma entidade operacional propria,
   vinculada opcionalmente a uma conta bancaria de suporte.
*/

CREATE TABLE IF NOT EXISTS financeiro.caixa (
    id_caixa bigint GENERATED BY DEFAULT AS IDENTITY,
    codigo character varying(30) NOT NULL,
    descricao character varying(120) NOT NULL,
    id_conta_bancaria integer,
    saldo_inicial numeric(15,2) NOT NULL DEFAULT 0,
    ativo boolean NOT NULL DEFAULT TRUE,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer NOT NULL DEFAULT 1,

    CONSTRAINT pk_caixa
        PRIMARY KEY (id_caixa),

    CONSTRAINT uk_caixa_codigo
        UNIQUE (codigo),

    CONSTRAINT chk_caixa_saldo_inicial
        CHECK (saldo_inicial >= 0),

    CONSTRAINT fk_caixa_conta_bancaria
        FOREIGN KEY (id_conta_bancaria)
        REFERENCES financeiro.conta_bancaria(id_conta_bancaria)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_caixa_created_by
        FOREIGN KEY (created_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_caixa_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_caixa_deleted_by
        FOREIGN KEY (deleted_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

/* ============================================================================
   5. TRANSFERENCIAS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 5 - TRANSFERENCIAS'
\echo '============================================================'

CREATE TABLE IF NOT EXISTS financeiro.transferencia (
    id_transferencia bigint GENERATED BY DEFAULT AS IDENTITY,
    codigo character varying(40) NOT NULL,
    id_conta_origem integer NOT NULL,
    id_conta_destino integer NOT NULL,
    data_transferencia date NOT NULL,
    valor numeric(15,2) NOT NULL,
    id_movimento_saida bigint,
    id_movimento_entrada bigint,
    historico text,
    status character varying(20) NOT NULL DEFAULT 'EFETIVADA',
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer NOT NULL DEFAULT 1,

    CONSTRAINT pk_transferencia
        PRIMARY KEY (id_transferencia),

    CONSTRAINT uk_transferencia_codigo
        UNIQUE (codigo),

    CONSTRAINT chk_transferencia_valor
        CHECK (valor > 0),

    CONSTRAINT chk_transferencia_contas
        CHECK (id_conta_origem <> id_conta_destino),

    CONSTRAINT chk_transferencia_status
        CHECK (status IN ('PREVISTA','EFETIVADA','CANCELADA','ESTORNADA')),

    CONSTRAINT fk_transferencia_conta_origem
        FOREIGN KEY (id_conta_origem)
        REFERENCES financeiro.conta_bancaria(id_conta_bancaria)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_transferencia_conta_destino
        FOREIGN KEY (id_conta_destino)
        REFERENCES financeiro.conta_bancaria(id_conta_bancaria)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_transferencia_movimento_saida
        FOREIGN KEY (id_movimento_saida)
        REFERENCES financeiro.movimentacao_bancaria(id_movimento)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_transferencia_movimento_entrada
        FOREIGN KEY (id_movimento_entrada)
        REFERENCES financeiro.movimentacao_bancaria(id_movimento)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_transferencia_created_by
        FOREIGN KEY (created_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_transferencia_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_transferencia_deleted_by
        FOREIGN KEY (deleted_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

/* ============================================================================
   6. CARTOES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 6 - CARTOES'
\echo '============================================================'

CREATE TABLE IF NOT EXISTS financeiro.cartao (
    id_cartao bigint GENERATED BY DEFAULT AS IDENTITY,
    id_conta_bancaria integer,
    nome character varying(120) NOT NULL,
    tipo character varying(20) NOT NULL,
    bandeira character varying(30),
    ultimos_quatro character(4),
    dia_fechamento smallint,
    dia_vencimento smallint,
    limite numeric(15,2),
    ativo boolean NOT NULL DEFAULT TRUE,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer NOT NULL DEFAULT 1,

    CONSTRAINT pk_cartao
        PRIMARY KEY (id_cartao),

    CONSTRAINT chk_cartao_tipo
        CHECK (tipo IN ('CREDITO','DEBITO','MULTIPLO','PRE_PAGO')),

    CONSTRAINT chk_cartao_ultimos_quatro
        CHECK (
            ultimos_quatro IS NULL
            OR ultimos_quatro ~ '^[0-9]{4}$'
        ),

    CONSTRAINT chk_cartao_fechamento
        CHECK (
            dia_fechamento IS NULL
            OR dia_fechamento BETWEEN 1 AND 31
        ),

    CONSTRAINT chk_cartao_vencimento
        CHECK (
            dia_vencimento IS NULL
            OR dia_vencimento BETWEEN 1 AND 31
        ),

    CONSTRAINT chk_cartao_limite
        CHECK (
            limite IS NULL
            OR limite >= 0
        ),

    CONSTRAINT fk_cartao_conta_bancaria
        FOREIGN KEY (id_conta_bancaria)
        REFERENCES financeiro.conta_bancaria(id_conta_bancaria)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_cartao_created_by
        FOREIGN KEY (created_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_cartao_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_cartao_deleted_by
        FOREIGN KEY (deleted_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

/* ============================================================================
   7. FATURAS DE CARTAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 7 - FATURAS DE CARTAO'
\echo '============================================================'

CREATE TABLE IF NOT EXISTS financeiro.fatura_cartao (
    id_fatura bigint GENERATED BY DEFAULT AS IDENTITY,
    id_cartao bigint NOT NULL,
    competencia date NOT NULL,
    data_fechamento date,
    data_vencimento date NOT NULL,
    valor_total numeric(15,2) NOT NULL DEFAULT 0,
    valor_pago numeric(15,2) NOT NULL DEFAULT 0,
    status character varying(20) NOT NULL DEFAULT 'ABERTA',
    id_lancamento bigint,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer NOT NULL DEFAULT 1,

    CONSTRAINT pk_fatura_cartao
        PRIMARY KEY (id_fatura),

    CONSTRAINT uk_fatura_cartao_competencia
        UNIQUE (id_cartao, competencia),

    CONSTRAINT chk_fatura_cartao_valor_total
        CHECK (valor_total >= 0),

    CONSTRAINT chk_fatura_cartao_valor_pago
        CHECK (valor_pago >= 0),

    CONSTRAINT chk_fatura_cartao_valor_pago_limite
        CHECK (valor_pago <= valor_total),

    CONSTRAINT chk_fatura_cartao_status
        CHECK (
            status IN (
                'ABERTA',
                'FECHADA',
                'PARCIAL',
                'PAGA',
                'CANCELADA'
            )
        ),

    CONSTRAINT fk_fatura_cartao_cartao
        FOREIGN KEY (id_cartao)
        REFERENCES financeiro.cartao(id_cartao)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_fatura_cartao_lancamento
        FOREIGN KEY (id_lancamento)
        REFERENCES financeiro.lancamento(id_lancamento)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_fatura_cartao_created_by
        FOREIGN KEY (created_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_fatura_cartao_updated_by
        FOREIGN KEY (updated_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL,

    CONSTRAINT fk_fatura_cartao_deleted_by
        FOREIGN KEY (deleted_by)
        REFERENCES public.usuario(id_usuario)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

/* ============================================================================
   8. ITENS DE FATURA
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 8 - ITENS DE FATURA'
\echo '============================================================'

/*
   Os itens nao duplicam AP/AR.
   Cada item pode opcionalmente apontar para um lancamento financeiro.
*/

CREATE TABLE IF NOT EXISTS financeiro.fatura_cartao_item (
    id_fatura_item bigint GENERATED BY DEFAULT AS IDENTITY,
    id_fatura bigint NOT NULL,
    id_lancamento bigint,
    data_compra date NOT NULL,
    descricao character varying(255) NOT NULL,
    valor numeric(15,2) NOT NULL,
    parcela_numero integer,
    parcela_total integer,
    created_at timestamp without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_fatura_cartao_item
        PRIMARY KEY (id_fatura_item),

    CONSTRAINT chk_fatura_cartao_item_valor
        CHECK (valor > 0),

    CONSTRAINT chk_fatura_cartao_item_parcela_numero
        CHECK (
            parcela_numero IS NULL
            OR parcela_numero > 0
        ),

    CONSTRAINT chk_fatura_cartao_item_parcela_total
        CHECK (
            parcela_total IS NULL
            OR parcela_total > 0
        ),

    CONSTRAINT chk_fatura_cartao_item_parcelas
        CHECK (
            parcela_numero IS NULL
            OR parcela_total IS NULL
            OR parcela_numero <= parcela_total
        ),

    CONSTRAINT fk_fatura_cartao_item_fatura
        FOREIGN KEY (id_fatura)
        REFERENCES financeiro.fatura_cartao(id_fatura)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_fatura_cartao_item_lancamento
        FOREIGN KEY (id_lancamento)
        REFERENCES financeiro.lancamento(id_lancamento)
        ON UPDATE CASCADE
        ON DELETE SET NULL
);

/* ============================================================================
   9. INDICES
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 9 - INDICES'
\echo '============================================================'

CREATE INDEX IF NOT EXISTS idx_caixa_conta_bancaria
    ON financeiro.caixa(id_conta_bancaria);

CREATE INDEX IF NOT EXISTS idx_transferencia_origem
    ON financeiro.transferencia(id_conta_origem);

CREATE INDEX IF NOT EXISTS idx_transferencia_destino
    ON financeiro.transferencia(id_conta_destino);

CREATE INDEX IF NOT EXISTS idx_transferencia_data
    ON financeiro.transferencia(data_transferencia);

CREATE INDEX IF NOT EXISTS idx_cartao_conta_bancaria
    ON financeiro.cartao(id_conta_bancaria);

CREATE INDEX IF NOT EXISTS idx_fatura_cartao_cartao
    ON financeiro.fatura_cartao(id_cartao);

CREATE INDEX IF NOT EXISTS idx_fatura_cartao_vencimento
    ON financeiro.fatura_cartao(data_vencimento);

CREATE INDEX IF NOT EXISTS idx_fatura_cartao_item_fatura
    ON financeiro.fatura_cartao_item(id_fatura);

CREATE INDEX IF NOT EXISTS idx_fatura_cartao_item_lancamento
    ON financeiro.fatura_cartao_item(id_lancamento);

/* ============================================================================
   10. DOCUMENTACAO
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 10 - DOCUMENTACAO'
\echo '============================================================'

COMMENT ON TABLE financeiro.banco IS
    'Cadastro de instituicoes bancarias do modulo financeiro.';

COMMENT ON TABLE financeiro.conta_bancaria IS
    'Contas bancarias sob autoridade do modulo financeiro.';

COMMENT ON TABLE financeiro.tipo_movimentacao IS
    'Dominio de tipos de entrada e saida das movimentacoes financeiras.';

COMMENT ON TABLE financeiro.movimentacao_bancaria IS
    'Movimentacoes financeiras realizadas nas contas bancarias.';

COMMENT ON TABLE financeiro.caixa IS
    'Caixas operacionais utilizados para controle financeiro de numerario.';

COMMENT ON TABLE financeiro.transferencia IS
    'Transferencias entre contas bancarias, vinculando origem, destino e movimentos gerados.';

COMMENT ON TABLE financeiro.cartao IS
    'Cartoes financeiros corporativos ou operacionais controlados pelo modulo financeiro.';

COMMENT ON TABLE financeiro.fatura_cartao IS
    'Faturas consolidadas dos cartoes controlados pelo modulo financeiro.';

COMMENT ON TABLE financeiro.fatura_cartao_item IS
    'Itens de compra ou despesa que compoem uma fatura de cartao.';

/* ============================================================================
   11. REAUDITORIA DE OBJETOS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 11 - REAUDITORIA DE OBJETOS'
\echo '============================================================'

WITH esperado(objeto) AS (
    VALUES
        ('banco'),
        ('conta_bancaria'),
        ('tipo_movimentacao'),
        ('movimentacao_bancaria'),
        ('caixa'),
        ('transferencia'),
        ('cartao'),
        ('fatura_cartao'),
        ('fatura_cartao_item')
)
SELECT
    e.objeto,
    CASE
        WHEN to_regclass('financeiro.' || e.objeto) IS NOT NULL
            THEN 'OK'
        ELSE 'AUSENTE'
    END AS status
FROM esperado e
ORDER BY e.objeto;

/* ============================================================================
   12. REAUDITORIA DE CONSTRAINTS
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 12 - REAUDITORIA DE CONSTRAINTS'
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
      'banco',
      'conta_bancaria',
      'tipo_movimentacao',
      'movimentacao_bancaria',
      'caixa',
      'transferencia',
      'cartao',
      'fatura_cartao',
      'fatura_cartao_item'
  )
GROUP BY c.relname
ORDER BY c.relname;

/* ============================================================================
   13. VALIDACAO FUNCIONAL MINIMA DE TRANSFERENCIA
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 13 - VALIDACAO FUNCIONAL DE TRANSFERENCIA'
\echo '============================================================'

/*
   Teste realizado em subtransacao logica e removido antes do COMMIT.
   Cria duas contas temporarias apenas se necessario.
*/

CREATE TEMP TABLE f1_fin_7_test_ctx (
    id_banco integer,
    id_conta_origem integer,
    id_conta_destino integer,
    id_mov_saida bigint,
    id_mov_entrada bigint,
    id_transferencia bigint
);

DO $$
DECLARE
    v_id_banco integer;
    v_origem integer;
    v_destino integer;
    v_saida smallint;
    v_entrada smallint;
    v_mov_saida bigint;
    v_mov_entrada bigint;
    v_trans bigint;
BEGIN
    SELECT id_banco
    INTO v_id_banco
    FROM financeiro.banco
    ORDER BY id_banco
    LIMIT 1;

    IF v_id_banco IS NULL THEN
        INSERT INTO financeiro.banco (
            codigo_banco,
            nome,
            ativo
        )
        VALUES (
            '998',
            'BANCO TESTE F1-FIN.7',
            TRUE
        )
        RETURNING id_banco INTO v_id_banco;
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
        'F1FIN7ORI',
        '0',
        'TESTE',
        1000.00,
        TRUE
    )
    RETURNING id_conta_bancaria INTO v_origem;

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
        'F1FIN7DES',
        '0',
        'TESTE',
        0.00,
        TRUE
    )
    RETURNING id_conta_bancaria INTO v_destino;

    SELECT id_tipo_movimentacao
    INTO v_saida
    FROM financeiro.tipo_movimentacao
    WHERE codigo = 'TRANSF_SAI'
    LIMIT 1;

    SELECT id_tipo_movimentacao
    INTO v_entrada
    FROM financeiro.tipo_movimentacao
    WHERE codigo = 'TRANSF_ENT'
    LIMIT 1;

    INSERT INTO financeiro.movimentacao_bancaria (
        id_conta_bancaria,
        id_tipo_movimentacao,
        data_movimento,
        valor,
        saldo_anterior,
        saldo_atual,
        historico
    )
    VALUES (
        v_origem,
        v_saida,
        CURRENT_DATE,
        250.00,
        1000.00,
        750.00,
        'Teste F1-FIN.7 - saida transferencia'
    )
    RETURNING id_movimento INTO v_mov_saida;

    INSERT INTO financeiro.movimentacao_bancaria (
        id_conta_bancaria,
        id_tipo_movimentacao,
        data_movimento,
        valor,
        saldo_anterior,
        saldo_atual,
        historico
    )
    VALUES (
        v_destino,
        v_entrada,
        CURRENT_DATE,
        250.00,
        0.00,
        250.00,
        'Teste F1-FIN.7 - entrada transferencia'
    )
    RETURNING id_movimento INTO v_mov_entrada;

    INSERT INTO financeiro.transferencia (
        codigo,
        id_conta_origem,
        id_conta_destino,
        data_transferencia,
        valor,
        id_movimento_saida,
        id_movimento_entrada,
        historico,
        status
    )
    VALUES (
        'F1FIN7-TESTE-001',
        v_origem,
        v_destino,
        CURRENT_DATE,
        250.00,
        v_mov_saida,
        v_mov_entrada,
        'Transferencia funcional de certificacao',
        'EFETIVADA'
    )
    RETURNING id_transferencia INTO v_trans;

    INSERT INTO f1_fin_7_test_ctx
    VALUES (
        v_id_banco,
        v_origem,
        v_destino,
        v_mov_saida,
        v_mov_entrada,
        v_trans
    );
END
$$;

SELECT
    t.codigo,
    t.valor,
    t.status,
    t.id_conta_origem,
    t.id_conta_destino,
    t.id_movimento_saida,
    t.id_movimento_entrada
FROM financeiro.transferencia t
WHERE t.codigo = 'F1FIN7-TESTE-001';

/* ============================================================================
   14. VALIDACAO BLOQUEANTE DA TRANSFERENCIA
   ============================================================================ */

DO $$
DECLARE
    v_count bigint;
BEGIN
    SELECT count(*)
    INTO v_count
    FROM financeiro.transferencia t
    JOIN financeiro.movimentacao_bancaria ms
      ON ms.id_movimento = t.id_movimento_saida
    JOIN financeiro.movimentacao_bancaria me
      ON me.id_movimento = t.id_movimento_entrada
    JOIN financeiro.tipo_movimentacao ts
      ON ts.id_tipo_movimentacao = ms.id_tipo_movimentacao
    JOIN financeiro.tipo_movimentacao te
      ON te.id_tipo_movimentacao = me.id_tipo_movimentacao
    WHERE t.codigo = 'F1FIN7-TESTE-001'
      AND t.valor = 250.00
      AND ms.valor = 250.00
      AND me.valor = 250.00
      AND ts.entrada_saida = 'S'
      AND te.entrada_saida = 'E'
      AND t.id_conta_origem <> t.id_conta_destino;

    IF v_count <> 1 THEN
        RAISE EXCEPTION
            'F1-FIN.7 falhou: teste funcional de transferencia nao aprovado.';
    END IF;
END
$$;

/* ============================================================================
   15. LIMPEZA DOS DADOS DE TESTE
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 15 - LIMPEZA DOS DADOS DE TESTE'
\echo '============================================================'

DELETE FROM financeiro.transferencia
WHERE id_transferencia IN (
    SELECT id_transferencia
    FROM f1_fin_7_test_ctx
);

DELETE FROM financeiro.movimentacao_bancaria
WHERE id_movimento IN (
    SELECT id_mov_saida FROM f1_fin_7_test_ctx
    UNION
    SELECT id_mov_entrada FROM f1_fin_7_test_ctx
);

DELETE FROM financeiro.conta_bancaria
WHERE id_conta_bancaria IN (
    SELECT id_conta_origem FROM f1_fin_7_test_ctx
    UNION
    SELECT id_conta_destino FROM f1_fin_7_test_ctx
);

/*
   Banco de teste so e removido se nao tiver nenhuma conta associada.
*/
DELETE FROM financeiro.banco b
WHERE b.id_banco IN (
    SELECT id_banco
    FROM f1_fin_7_test_ctx
)
AND b.codigo_banco = '998'
AND NOT EXISTS (
    SELECT 1
    FROM financeiro.conta_bancaria cb
    WHERE cb.id_banco = b.id_banco
);

/* ============================================================================
   16. CERTIFICACAO FINAL
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' 16 - CERTIFICACAO FINAL F1-FIN.7'
\echo '============================================================'

WITH objetos AS (
    SELECT
        COUNT(*) FILTER (
            WHERE to_regclass('financeiro.banco') IS NOT NULL
        ) AS banco,
        COUNT(*) FILTER (
            WHERE to_regclass('financeiro.conta_bancaria') IS NOT NULL
        ) AS conta_bancaria,
        COUNT(*) FILTER (
            WHERE to_regclass('financeiro.tipo_movimentacao') IS NOT NULL
        ) AS tipo_movimentacao,
        COUNT(*) FILTER (
            WHERE to_regclass('financeiro.movimentacao_bancaria') IS NOT NULL
        ) AS movimentacao_bancaria,
        COUNT(*) FILTER (
            WHERE to_regclass('financeiro.caixa') IS NOT NULL
        ) AS caixa,
        COUNT(*) FILTER (
            WHERE to_regclass('financeiro.transferencia') IS NOT NULL
        ) AS transferencia,
        COUNT(*) FILTER (
            WHERE to_regclass('financeiro.cartao') IS NOT NULL
        ) AS cartao,
        COUNT(*) FILTER (
            WHERE to_regclass('financeiro.fatura_cartao') IS NOT NULL
        ) AS fatura_cartao,
        COUNT(*) FILTER (
            WHERE to_regclass('financeiro.fatura_cartao_item') IS NOT NULL
        ) AS fatura_cartao_item
    FROM generate_series(1,1)
),
integridade AS (
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
                  'banco',
                  'conta_bancaria',
                  'tipo_movimentacao',
                  'movimentacao_bancaria',
                  'caixa',
                  'transferencia',
                  'cartao',
                  'fatura_cartao',
                  'fatura_cartao_item'
              )
              AND NOT con.convalidated
        ) AS constraints_nao_validadas,

        (
            SELECT COUNT(*)
            FROM financeiro.tipo_movimentacao
            WHERE codigo IN ('TRANSF_SAI','TRANSF_ENT')
              AND ativo IS TRUE
        ) AS tipos_transferencia,

        (
            SELECT COUNT(*)
            FROM financeiro.transferencia
            WHERE codigo = 'F1FIN7-TESTE-001'
        ) AS dados_teste_transferencia,

        (
            SELECT COUNT(*)
            FROM financeiro.conta_bancaria
            WHERE conta IN ('F1FIN7ORI','F1FIN7DES')
        ) AS dados_teste_conta
)
SELECT
    o.banco,
    o.conta_bancaria,
    o.tipo_movimentacao,
    o.movimentacao_bancaria,
    o.caixa,
    o.transferencia,
    o.cartao,
    o.fatura_cartao,
    o.fatura_cartao_item,
    i.constraints_nao_validadas,
    i.tipos_transferencia,
    i.dados_teste_transferencia,
    i.dados_teste_conta,
    CASE
        WHEN o.banco = 1
         AND o.conta_bancaria = 1
         AND o.tipo_movimentacao = 1
         AND o.movimentacao_bancaria = 1
         AND o.caixa = 1
         AND o.transferencia = 1
         AND o.cartao = 1
         AND o.fatura_cartao = 1
         AND o.fatura_cartao_item = 1
         AND i.constraints_nao_validadas = 0
         AND i.tipos_transferencia = 2
         AND i.dados_teste_transferencia = 0
         AND i.dados_teste_conta = 0
        THEN 'F1_FIN_7_APROVADA'
        ELSE 'F1_FIN_7_PENDENTE'
    END AS status
FROM objetos o
CROSS JOIN integridade i;

/* ============================================================================
   17. VALIDACAO BLOQUEANTE FINAL
   ============================================================================ */

DO $$
DECLARE
    v_missing bigint;
    v_invalid bigint;
BEGIN
    SELECT count(*)
    INTO v_missing
    FROM (
        VALUES
            ('financeiro.banco'),
            ('financeiro.conta_bancaria'),
            ('financeiro.tipo_movimentacao'),
            ('financeiro.movimentacao_bancaria'),
            ('financeiro.caixa'),
            ('financeiro.transferencia'),
            ('financeiro.cartao'),
            ('financeiro.fatura_cartao'),
            ('financeiro.fatura_cartao_item')
    ) AS x(objeto)
    WHERE to_regclass(x.objeto) IS NULL;

    SELECT count(*)
    INTO v_invalid
    FROM pg_constraint con
    JOIN pg_class c
      ON c.oid = con.conrelid
    JOIN pg_namespace n
      ON n.oid = c.relnamespace
    WHERE n.nspname = 'financeiro'
      AND c.relname IN (
          'banco',
          'conta_bancaria',
          'tipo_movimentacao',
          'movimentacao_bancaria',
          'caixa',
          'transferencia',
          'cartao',
          'fatura_cartao',
          'fatura_cartao_item'
      )
      AND NOT con.convalidated;

    IF v_missing <> 0 THEN
        RAISE EXCEPTION
            'F1-FIN.7 abortada: % objetos obrigatorios ausentes.',
            v_missing;
    END IF;

    IF v_invalid <> 0 THEN
        RAISE EXCEPTION
            'F1-FIN.7 abortada: % constraints nao validadas.',
            v_invalid;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM financeiro.transferencia
        WHERE codigo = 'F1FIN7-TESTE-001'
    ) THEN
        RAISE EXCEPTION
            'F1-FIN.7 abortada: dado de teste de transferencia permaneceu.';
    END IF;
END
$$;

/* ============================================================================
   COMMIT
   ============================================================================ */

\echo ''
\echo '============================================================'
\echo ' F1-FIN.7 CONCLUIDA'
\echo '============================================================'
\echo ' BANCO ............................ VALIDADO'
\echo ' CONTA BANCARIA ................... VALIDADA'
\echo ' MOVIMENTACAO BANCARIA ............ VALIDADA'
\echo ' CAIXA ............................ IMPLEMENTADO'
\echo ' TRANSFERENCIA .................... IMPLEMENTADA'
\echo ' CARTAO ........................... IMPLEMENTADO'
\echo ' FATURA CARTAO .................... IMPLEMENTADA'
\echo ' ITEM FATURA ...................... IMPLEMENTADO'
\echo ' TESTE TRANSFERENCIA .............. APROVADO'
\echo ' DOCUMENTACAO ..................... APLICADA'
\echo ' PROXIMA ETAPA .................... F1-FIN.8'
\echo '============================================================'

COMMIT;

\echo ''
\echo '============================================================'
\echo ' COMMIT CONCLUIDO'
\echo ' F1-FIN.7 FINALIZADA'
\echo ' PROXIMA ETAPA: F1-FIN.8 - RATEIOS E CENTROS DE CUSTO'
\echo '============================================================'
