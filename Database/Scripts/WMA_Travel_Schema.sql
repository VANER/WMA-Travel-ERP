--
-- PostgreSQL database dump
--

\restrict tBnlGCIfBLQl1Rr5YlnPONTGyjntm8su1O9Rm6wxuUA8RrVBEXcTQZzcVEl7Z6g

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

-- Started on 2026-08-16 11:49:57

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 10 (class 2615 OID 41444)
-- Name: auditoria; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA auditoria;


ALTER SCHEMA auditoria OWNER TO postgres;

--
-- TOC entry 8030 (class 0 OID 0)
-- Dependencies: 10
-- Name: SCHEMA auditoria; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA auditoria IS 'Objetos utilizados para auditoria estrutural, integridade e conformidade do WMA Travel ERP.';


--
-- TOC entry 11 (class 2615 OID 41755)
-- Name: config; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA config;


ALTER SCHEMA config OWNER TO postgres;

--
-- TOC entry 9 (class 2615 OID 27208)
-- Name: dw; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA dw;


ALTER SCHEMA dw OWNER TO postgres;

--
-- TOC entry 8 (class 2615 OID 24626)
-- Name: financeiro; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA financeiro;


ALTER SCHEMA financeiro OWNER TO postgres;

--
-- TOC entry 8031 (class 0 OID 0)
-- Dependencies: 8
-- Name: SCHEMA financeiro; Type: COMMENT; Schema: -; Owner: postgres
--

COMMENT ON SCHEMA financeiro IS 'ERP Financeiro WMA Travel';


--
-- TOC entry 13 (class 2615 OID 41757)
-- Name: logs; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA logs;


ALTER SCHEMA logs OWNER TO postgres;

--
-- TOC entry 14 (class 2615 OID 41758)
-- Name: seguranca; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA seguranca;


ALTER SCHEMA seguranca OWNER TO postgres;

--
-- TOC entry 12 (class 2615 OID 41756)
-- Name: util; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA util;


ALTER SCHEMA util OWNER TO postgres;

--
-- TOC entry 3 (class 3079 OID 24588)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 8032 (class 0 OID 0)
-- Dependencies: 3
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 2 (class 3079 OID 24577)
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- TOC entry 8033 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- TOC entry 748 (class 1255 OID 41637)
-- Name: fn_calcular_score(bigint); Type: FUNCTION; Schema: auditoria; Owner: postgres
--

CREATE FUNCTION auditoria.fn_calcular_score(p_execucao bigint) RETURNS numeric
    LANGUAGE plpgsql
    AS $$

DECLARE

    v_total NUMERIC;

BEGIN

    SELECT
        COALESCE(SUM(peso),0)
    INTO v_total
    FROM auditoria.resultado r
         INNER JOIN auditoria.item i
             ON i.id_item = r.id_item
    WHERE r.id_execucao = p_execucao
      AND r.status='OK';

    RETURN v_total;

END;

$$;


ALTER FUNCTION auditoria.fn_calcular_score(p_execucao bigint) OWNER TO postgres;

--
-- TOC entry 8034 (class 0 OID 0)
-- Dependencies: 748
-- Name: FUNCTION fn_calcular_score(p_execucao bigint); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON FUNCTION auditoria.fn_calcular_score(p_execucao bigint) IS 'Calcula o score consolidado de uma execução de auditoria com base nos resultados registrados.';


--
-- TOC entry 742 (class 1255 OID 41807)
-- Name: fn_classificacao_score(numeric); Type: FUNCTION; Schema: auditoria; Owner: postgres
--

CREATE FUNCTION auditoria.fn_classificacao_score(p_score numeric) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN

    IF p_score >= 98 THEN
        RETURN 'EXCELENTE';
    ELSIF p_score >= 95 THEN
        RETURN 'MUITO BOM';
    ELSIF p_score >= 90 THEN
        RETURN 'BOM';
    ELSIF p_score >= 80 THEN
        RETURN 'REGULAR';
    ELSIF p_score >= 70 THEN
        RETURN 'ATENCAO';
    ELSE
        RETURN 'CRITICO';
    END IF;

END;
$$;


ALTER FUNCTION auditoria.fn_classificacao_score(p_score numeric) OWNER TO postgres;

--
-- TOC entry 8035 (class 0 OID 0)
-- Dependencies: 742
-- Name: FUNCTION fn_classificacao_score(p_score numeric); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON FUNCTION auditoria.fn_classificacao_score(p_score numeric) IS 'Classifica o score de auditoria de acordo com as faixas de classificação definidas pelo framework de governança.';


--
-- TOC entry 744 (class 1255 OID 41633)
-- Name: fn_finalizar_execucao(bigint, numeric, character varying); Type: FUNCTION; Schema: auditoria; Owner: postgres
--

CREATE FUNCTION auditoria.fn_finalizar_execucao(p_execucao bigint, p_score numeric, p_classificacao character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$

BEGIN

UPDATE auditoria.execucao

SET

data_fim=CURRENT_TIMESTAMP,

tempo_execucao_ms=

EXTRACT(EPOCH FROM

(CURRENT_TIMESTAMP-data_inicio)

)*1000,

score_final=p_score,

classificacao=p_classificacao,

status_execucao='FINALIZADO',

updated_at=CURRENT_TIMESTAMP

WHERE id_execucao=p_execucao;

END;

$$;


ALTER FUNCTION auditoria.fn_finalizar_execucao(p_execucao bigint, p_score numeric, p_classificacao character varying) OWNER TO postgres;

--
-- TOC entry 8036 (class 0 OID 0)
-- Dependencies: 744
-- Name: FUNCTION fn_finalizar_execucao(p_execucao bigint, p_score numeric, p_classificacao character varying); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON FUNCTION auditoria.fn_finalizar_execucao(p_execucao bigint, p_score numeric, p_classificacao character varying) IS 'Finaliza uma execução de auditoria, registrando o score e a classificação final da execução.';


--
-- TOC entry 762 (class 1255 OID 41640)
-- Name: fn_health_check(); Type: FUNCTION; Schema: auditoria; Owner: postgres
--

CREATE FUNCTION auditoria.fn_health_check() RETURNS TABLE(score numeric, classificacao character varying, execucao bigint, data_execucao timestamp without time zone)
    LANGUAGE plpgsql
    AS $$

BEGIN

RETURN QUERY

SELECT

e.score_final,

e.classificacao,

e.id_execucao,

e.data_inicio

FROM auditoria.execucao e

ORDER BY e.id_execucao DESC

LIMIT 1;

END;

$$;


ALTER FUNCTION auditoria.fn_health_check() OWNER TO postgres;

--
-- TOC entry 8037 (class 0 OID 0)
-- Dependencies: 762
-- Name: FUNCTION fn_health_check(); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON FUNCTION auditoria.fn_health_check() IS 'Executa verificações básicas de disponibilidade e integridade operacional do framework de auditoria.';


--
-- TOC entry 743 (class 1255 OID 41632)
-- Name: fn_iniciar_execucao(character varying, character varying); Type: FUNCTION; Schema: auditoria; Owner: postgres
--

CREATE FUNCTION auditoria.fn_iniciar_execucao(p_versao_script character varying, p_schema character varying DEFAULT 'financeiro'::character varying) RETURNS bigint
    LANGUAGE plpgsql
    AS $$

DECLARE

    v_execucao BIGINT;

BEGIN

INSERT INTO auditoria.execucao
(
versao_banco,
versao_script,
schema_auditado,
usuario_execucao,
host_execucao,
banco,
status_execucao
)

VALUES
(

current_setting('server_version'),

p_versao_script,

p_schema,

current_user,

inet_server_addr()::text,

current_database(),

'EXECUTANDO'

)

RETURNING id_execucao

INTO v_execucao;

RETURN v_execucao;

END;

$$;


ALTER FUNCTION auditoria.fn_iniciar_execucao(p_versao_script character varying, p_schema character varying) OWNER TO postgres;

--
-- TOC entry 8038 (class 0 OID 0)
-- Dependencies: 743
-- Name: FUNCTION fn_iniciar_execucao(p_versao_script character varying, p_schema character varying); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON FUNCTION auditoria.fn_iniciar_execucao(p_versao_script character varying, p_schema character varying) IS 'Inicia uma nova execução do framework de auditoria para o schema informado e registra seus dados de controle.';


--
-- TOC entry 747 (class 1255 OID 41636)
-- Name: fn_obter_configuracao(character varying); Type: FUNCTION; Schema: auditoria; Owner: postgres
--

CREATE FUNCTION auditoria.fn_obter_configuracao(p_chave character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$

DECLARE

    v_valor VARCHAR;

BEGIN

    SELECT valor
      INTO v_valor
      FROM auditoria.configuracao
     WHERE chave = p_chave
       AND ativo = TRUE;

    RETURN v_valor;

END;

$$;


ALTER FUNCTION auditoria.fn_obter_configuracao(p_chave character varying) OWNER TO postgres;

--
-- TOC entry 8039 (class 0 OID 0)
-- Dependencies: 747
-- Name: FUNCTION fn_obter_configuracao(p_chave character varying); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON FUNCTION auditoria.fn_obter_configuracao(p_chave character varying) IS 'Obtém o valor de uma configuração do framework de auditoria a partir de sua chave.';


--
-- TOC entry 749 (class 1255 OID 41808)
-- Name: fn_prioridade(character varying); Type: FUNCTION; Schema: auditoria; Owner: postgres
--

CREATE FUNCTION auditoria.fn_prioridade(p_criticidade character varying) RETURNS smallint
    LANGUAGE plpgsql
    AS $$
BEGIN

    RETURN CASE UPPER(TRIM(p_criticidade))

        WHEN 'CRITICA'      THEN 1
        WHEN 'ALTA'         THEN 2
        WHEN 'MEDIA'        THEN 3
        WHEN 'BAIXA'        THEN 4
        ELSE 5

    END;

END;
$$;


ALTER FUNCTION auditoria.fn_prioridade(p_criticidade character varying) OWNER TO postgres;

--
-- TOC entry 8040 (class 0 OID 0)
-- Dependencies: 749
-- Name: FUNCTION fn_prioridade(p_criticidade character varying); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON FUNCTION auditoria.fn_prioridade(p_criticidade character varying) IS 'Determina a prioridade associada à criticidade informada para fins de classificação e governança.';


--
-- TOC entry 755 (class 1255 OID 41639)
-- Name: fn_registrar_erro(bigint, character varying, character varying, text); Type: FUNCTION; Schema: auditoria; Owner: postgres
--

CREATE FUNCTION auditoria.fn_registrar_erro(p_execucao bigint, p_script character varying, p_sqlstate character varying, p_mensagem text) RETURNS void
    LANGUAGE plpgsql
    AS $$

BEGIN

PERFORM auditoria.fn_registrar_log
(

p_execucao,

p_script,

'ERRO',

p_sqlstate,

p_mensagem,

'CRITICA'

);

END;

$$;


ALTER FUNCTION auditoria.fn_registrar_erro(p_execucao bigint, p_script character varying, p_sqlstate character varying, p_mensagem text) OWNER TO postgres;

--
-- TOC entry 8041 (class 0 OID 0)
-- Dependencies: 755
-- Name: FUNCTION fn_registrar_erro(p_execucao bigint, p_script character varying, p_sqlstate character varying, p_mensagem text); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON FUNCTION auditoria.fn_registrar_erro(p_execucao bigint, p_script character varying, p_sqlstate character varying, p_mensagem text) IS 'Registra um erro ocorrido durante uma execução de auditoria, incluindo script, SQLSTATE e mensagem.';


--
-- TOC entry 745 (class 1255 OID 41634)
-- Name: fn_registrar_log(bigint, character varying, character varying, character varying, text, character varying); Type: FUNCTION; Schema: auditoria; Owner: postgres
--

CREATE FUNCTION auditoria.fn_registrar_log(p_execucao bigint, p_script character varying, p_etapa character varying, p_sqlstate character varying, p_mensagem text, p_severidade character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$

BEGIN

INSERT INTO auditoria.log
(

id_execucao,

script,

etapa,

sqlstate,

mensagem,

severidade

)

VALUES
(

p_execucao,

p_script,

p_etapa,

p_sqlstate,

p_mensagem,

p_severidade

);

END;

$$;


ALTER FUNCTION auditoria.fn_registrar_log(p_execucao bigint, p_script character varying, p_etapa character varying, p_sqlstate character varying, p_mensagem text, p_severidade character varying) OWNER TO postgres;

--
-- TOC entry 8042 (class 0 OID 0)
-- Dependencies: 745
-- Name: FUNCTION fn_registrar_log(p_execucao bigint, p_script character varying, p_etapa character varying, p_sqlstate character varying, p_mensagem text, p_severidade character varying); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON FUNCTION auditoria.fn_registrar_log(p_execucao bigint, p_script character varying, p_etapa character varying, p_sqlstate character varying, p_mensagem text, p_severidade character varying) IS 'Registra eventos e mensagens de execução no histórico operacional do framework de auditoria.';


--
-- TOC entry 754 (class 1255 OID 41638)
-- Name: fn_registrar_recomendacao(bigint, character varying, character varying, character varying, character varying, text, character varying); Type: FUNCTION; Schema: auditoria; Owner: postgres
--

CREATE FUNCTION auditoria.fn_registrar_recomendacao(p_execucao bigint, p_prioridade character varying, p_categoria character varying, p_tabela character varying, p_coluna character varying, p_descricao text, p_script character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$

BEGIN

INSERT INTO auditoria.recomendacao
(

id_execucao,

prioridade,

categoria,

tabela_nome,

coluna_nome,

descricao,

script_sugerido

)

VALUES
(

p_execucao,

p_prioridade,

p_categoria,

p_tabela,

p_coluna,

p_descricao,

p_script

);

END;

$$;


ALTER FUNCTION auditoria.fn_registrar_recomendacao(p_execucao bigint, p_prioridade character varying, p_categoria character varying, p_tabela character varying, p_coluna character varying, p_descricao text, p_script character varying) OWNER TO postgres;

--
-- TOC entry 8043 (class 0 OID 0)
-- Dependencies: 754
-- Name: FUNCTION fn_registrar_recomendacao(p_execucao bigint, p_prioridade character varying, p_categoria character varying, p_tabela character varying, p_coluna character varying, p_descricao text, p_script character varying); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON FUNCTION auditoria.fn_registrar_recomendacao(p_execucao bigint, p_prioridade character varying, p_categoria character varying, p_tabela character varying, p_coluna character varying, p_descricao text, p_script character varying) IS 'Registra uma recomendação de auditoria vinculada a uma execução, incluindo prioridade, categoria e objeto analisado.';


--
-- TOC entry 746 (class 1255 OID 41635)
-- Name: fn_registrar_resultado(bigint, bigint, character varying, character varying, character varying, character varying, text); Type: FUNCTION; Schema: auditoria; Owner: postgres
--

CREATE FUNCTION auditoria.fn_registrar_resultado(p_execucao bigint, p_item bigint, p_tabela character varying, p_coluna character varying, p_status character varying, p_severidade character varying, p_observacao text) RETURNS void
    LANGUAGE plpgsql
    AS $$

BEGIN

INSERT INTO auditoria.resultado
(

id_execucao,

id_item,

tabela_nome,

coluna_nome,

status,

severidade,

observacao

)

VALUES
(

p_execucao,

p_item,

p_tabela,

p_coluna,

p_status,

p_severidade,

p_observacao

);

END;

$$;


ALTER FUNCTION auditoria.fn_registrar_resultado(p_execucao bigint, p_item bigint, p_tabela character varying, p_coluna character varying, p_status character varying, p_severidade character varying, p_observacao text) OWNER TO postgres;

--
-- TOC entry 8044 (class 0 OID 0)
-- Dependencies: 746
-- Name: FUNCTION fn_registrar_resultado(p_execucao bigint, p_item bigint, p_tabela character varying, p_coluna character varying, p_status character varying, p_severidade character varying, p_observacao text); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON FUNCTION auditoria.fn_registrar_resultado(p_execucao bigint, p_item bigint, p_tabela character varying, p_coluna character varying, p_status character varying, p_severidade character varying, p_observacao text) IS 'Registra o resultado de uma verificação de auditoria e seus respectivos status, severidade e observação.';


--
-- TOC entry 763 (class 1255 OID 41809)
-- Name: fn_tempo_execucao(timestamp without time zone, timestamp without time zone); Type: FUNCTION; Schema: auditoria; Owner: postgres
--

CREATE FUNCTION auditoria.fn_tempo_execucao(p_inicio timestamp without time zone, p_fim timestamp without time zone) RETURNS bigint
    LANGUAGE sql
    AS $$

SELECT
EXTRACT(EPOCH FROM (p_fim-p_inicio))*1000;

$$;


ALTER FUNCTION auditoria.fn_tempo_execucao(p_inicio timestamp without time zone, p_fim timestamp without time zone) OWNER TO postgres;

--
-- TOC entry 8045 (class 0 OID 0)
-- Dependencies: 763
-- Name: FUNCTION fn_tempo_execucao(p_inicio timestamp without time zone, p_fim timestamp without time zone); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON FUNCTION auditoria.fn_tempo_execucao(p_inicio timestamp without time zone, p_fim timestamp without time zone) IS 'Calcula o intervalo de tempo entre o início e o término de uma execução.';


--
-- TOC entry 770 (class 1255 OID 41691)
-- Name: sp_auditoria_estrutura(bigint, character varying); Type: PROCEDURE; Schema: auditoria; Owner: postgres
--

CREATE PROCEDURE auditoria.sp_auditoria_estrutura(IN p_execucao bigint, IN p_schema character varying DEFAULT 'financeiro'::character varying)
    LANGUAGE plpgsql
    AS $$

DECLARE

    r RECORD;

    v_item BIGINT;

BEGIN

    -------------------------------------------------------------------
    -- AUD001
    -------------------------------------------------------------------

    SELECT id_item

    INTO v_item

    FROM auditoria.item

    WHERE codigo='AUD001';

    -------------------------------------------------------------------

    FOR r IN

        SELECT

            table_name

        FROM information_schema.tables

        WHERE table_schema=p_schema

        ORDER BY table_name

    LOOP

        -------------------------------------------------------------

        IF EXISTS
        (

            SELECT 1

            FROM information_schema.table_constraints

            WHERE

                table_schema=p_schema

                AND table_name=r.table_name

                AND constraint_type='PRIMARY KEY'

        )

        THEN

            PERFORM auditoria.fn_registrar_resultado
            (

                p_execucao,

                v_item,

                r.table_name,

                NULL,

                'OK',

                'BAIXA',

                'Tabela possui Primary Key.'

            );

        ELSE

            PERFORM auditoria.fn_registrar_resultado
            (

                p_execucao,

                v_item,

                r.table_name,

                NULL,

                'ERRO',

                'CRITICA',

                'Tabela sem Primary Key.'

            );

            PERFORM auditoria.fn_registrar_recomendacao
            (

                p_execucao,

                'ALTA',

                'ESTRUTURA',

                r.table_name,

                NULL,

                'Criar Primary Key.',

                'ALTER TABLE ... ADD PRIMARY KEY'

            );

        END IF;

    END LOOP;

END;

$$;


ALTER PROCEDURE auditoria.sp_auditoria_estrutura(IN p_execucao bigint, IN p_schema character varying) OWNER TO postgres;

--
-- TOC entry 8046 (class 0 OID 0)
-- Dependencies: 770
-- Name: PROCEDURE sp_auditoria_estrutura(IN p_execucao bigint, IN p_schema character varying); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON PROCEDURE auditoria.sp_auditoria_estrutura(IN p_execucao bigint, IN p_schema character varying) IS 'Executa a auditoria estrutural do schema informado e registra os resultados associados à execução.';


--
-- TOC entry 774 (class 1255 OID 41821)
-- Name: sp_executar_framework(bigint); Type: PROCEDURE; Schema: auditoria; Owner: postgres
--

CREATE PROCEDURE auditoria.sp_executar_framework(IN p_execucao bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE

    v_regra RECORD;

BEGIN

    FOR v_regra IN

        SELECT *

        FROM auditoria.regra

        WHERE ativo

        ORDER BY

            prioridade,

            ordem_execucao,

            id_regra

    LOOP

        CALL auditoria.sp_executar_regra
        (
            p_execucao,
            v_regra.id_regra
        );

    END LOOP;

END;

$$;


ALTER PROCEDURE auditoria.sp_executar_framework(IN p_execucao bigint) OWNER TO postgres;

--
-- TOC entry 8047 (class 0 OID 0)
-- Dependencies: 774
-- Name: PROCEDURE sp_executar_framework(IN p_execucao bigint); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON PROCEDURE auditoria.sp_executar_framework(IN p_execucao bigint) IS 'Executa o conjunto de regras do framework de auditoria associado à execução informada.';


--
-- TOC entry 765 (class 1255 OID 41641)
-- Name: sp_executar_governanca(character varying); Type: PROCEDURE; Schema: auditoria; Owner: postgres
--

CREATE PROCEDURE auditoria.sp_executar_governanca(IN p_schema character varying DEFAULT 'financeiro'::character varying)
    LANGUAGE plpgsql
    AS $$

DECLARE

    v_execucao BIGINT;

    v_score NUMERIC;

    v_classificacao VARCHAR;

BEGIN

    ---------------------------------------------------------
    -- INICIA EXECUÇÃO
    ---------------------------------------------------------

    v_execucao :=
        auditoria.fn_iniciar_execucao
        (
            '04.00',
            p_schema
        );

    RAISE NOTICE 'Execução % iniciada.', v_execucao;

    ---------------------------------------------------------
    -- EXECUTA AUDITORIAS
    ---------------------------------------------------------

    CALL auditoria.sp_auditoria_estrutura(v_execucao,p_schema);

    CALL auditoria.sp_auditoria_chaves(v_execucao,p_schema);

    CALL auditoria.sp_auditoria_indices(v_execucao,p_schema);

    CALL auditoria.sp_auditoria_constraints(v_execucao,p_schema);

    CALL auditoria.sp_auditoria_dominios(v_execucao,p_schema);

    CALL auditoria.sp_auditoria_campos_auditoria(v_execucao,p_schema);

    CALL auditoria.sp_auditoria_normalizacao(v_execucao,p_schema);

    CALL auditoria.sp_auditoria_performance(v_execucao,p_schema);

    CALL auditoria.sp_auditoria_modelagem(v_execucao,p_schema);

    CALL auditoria.sp_auditoria_documentacao(v_execucao,p_schema);

    CALL auditoria.sp_auditoria_seguranca(v_execucao,p_schema);

    ---------------------------------------------------------
    -- CALCULA SCORE
    ---------------------------------------------------------

    v_score :=
        auditoria.fn_calcular_score(v_execucao);

    v_classificacao :=
        auditoria.fn_classificar_score(v_score);

    ---------------------------------------------------------
    -- FINALIZA
    ---------------------------------------------------------

    PERFORM auditoria.fn_finalizar_execucao
    (
        v_execucao,
        v_score,
        v_classificacao
    );

    RAISE NOTICE 'Auditoria finalizada.';

    RAISE NOTICE 'Score: %',v_score;

    RAISE NOTICE 'Classificação: %',v_classificacao;

END;

$$;


ALTER PROCEDURE auditoria.sp_executar_governanca(IN p_schema character varying) OWNER TO postgres;

--
-- TOC entry 8048 (class 0 OID 0)
-- Dependencies: 765
-- Name: PROCEDURE sp_executar_governanca(IN p_schema character varying); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON PROCEDURE auditoria.sp_executar_governanca(IN p_schema character varying) IS 'Executa verificações de governança aplicáveis ao schema informado.';


--
-- TOC entry 775 (class 1255 OID 41822)
-- Name: sp_executar_regra(bigint, bigint); Type: PROCEDURE; Schema: auditoria; Owner: postgres
--

CREATE PROCEDURE auditoria.sp_executar_regra(IN p_execucao bigint, IN p_regra bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE

    v_sql TEXT;

    v_regra auditoria.regra%ROWTYPE;

BEGIN

    SELECT *

    INTO v_regra

    FROM auditoria.regra

    WHERE id_regra=p_regra;

    v_sql:=v_regra.sql_diagnostico;

    ------------------------------------------------
    -- executa dinamicamente
    ------------------------------------------------

    EXECUTE v_sql;

END;

$$;


ALTER PROCEDURE auditoria.sp_executar_regra(IN p_execucao bigint, IN p_regra bigint) OWNER TO postgres;

--
-- TOC entry 8049 (class 0 OID 0)
-- Dependencies: 775
-- Name: PROCEDURE sp_executar_regra(IN p_execucao bigint, IN p_regra bigint); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON PROCEDURE auditoria.sp_executar_regra(IN p_execucao bigint, IN p_regra bigint) IS 'Executa uma regra de auditoria específica para determinada execução, utilizando a definição parametrizada da regra.';


--
-- TOC entry 769 (class 1255 OID 41645)
-- Name: sp_exportar_relatorio(bigint); Type: PROCEDURE; Schema: auditoria; Owner: postgres
--

CREATE PROCEDURE auditoria.sp_exportar_relatorio(IN p_execucao bigint)
    LANGUAGE plpgsql
    AS $$

BEGIN

RAISE NOTICE 'Relatório da execução % pronto para exportação.',p_execucao;

END;

$$;


ALTER PROCEDURE auditoria.sp_exportar_relatorio(IN p_execucao bigint) OWNER TO postgres;

--
-- TOC entry 8050 (class 0 OID 0)
-- Dependencies: 769
-- Name: PROCEDURE sp_exportar_relatorio(IN p_execucao bigint); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON PROCEDURE auditoria.sp_exportar_relatorio(IN p_execucao bigint) IS 'Processa os dados de uma execução de auditoria para geração ou disponibilização de seu relatório consolidado.';


--
-- TOC entry 772 (class 1255 OID 41811)
-- Name: sp_finalizar_execucao(bigint, character varying); Type: PROCEDURE; Schema: auditoria; Owner: postgres
--

CREATE PROCEDURE auditoria.sp_finalizar_execucao(IN p_id_execucao bigint, IN p_status character varying DEFAULT 'FINALIZADO'::character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE

    v_inicio TIMESTAMP;

BEGIN

    SELECT data_inicio
    INTO v_inicio
    FROM auditoria.execucao
    WHERE id_execucao=p_id_execucao;

    UPDATE auditoria.execucao

       SET data_fim=CURRENT_TIMESTAMP,

           tempo_execucao_ms=
           EXTRACT(EPOCH FROM
           (CURRENT_TIMESTAMP-v_inicio))*1000,

           status_execucao=p_status,

           updated_at=CURRENT_TIMESTAMP,

           versao=versao+1

    WHERE id_execucao=p_id_execucao;

END;
$$;


ALTER PROCEDURE auditoria.sp_finalizar_execucao(IN p_id_execucao bigint, IN p_status character varying) OWNER TO postgres;

--
-- TOC entry 8051 (class 0 OID 0)
-- Dependencies: 772
-- Name: PROCEDURE sp_finalizar_execucao(IN p_id_execucao bigint, IN p_status character varying); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON PROCEDURE auditoria.sp_finalizar_execucao(IN p_id_execucao bigint, IN p_status character varying) IS 'Finaliza uma execução de auditoria e registra o status final informado.';


--
-- TOC entry 771 (class 1255 OID 41810)
-- Name: sp_iniciar_execucao(character varying, character varying, text); Type: PROCEDURE; Schema: auditoria; Owner: postgres
--

CREATE PROCEDURE auditoria.sp_iniciar_execucao(IN p_schema character varying, IN p_versao_script character varying, IN p_observacao text DEFAULT NULL::text)
    LANGUAGE plpgsql
    AS $$
BEGIN

    INSERT INTO auditoria.execucao
    (
        versao_banco,
        versao_script,
        schema_auditado,
        usuario_execucao,
        host_execucao,
        banco,
        data_inicio,
        status_execucao,
        observacao,
        created_at,
        versao
    )
    VALUES
    (
        current_setting('server_version'),
        p_versao_script,
        p_schema,
        CURRENT_USER,
        COALESCE(inet_client_addr()::TEXT,'LOCALHOST'),
        current_database(),
        CURRENT_TIMESTAMP,
        'EXECUTANDO',
        p_observacao,
        CURRENT_TIMESTAMP,
        1
    );

END;
$$;


ALTER PROCEDURE auditoria.sp_iniciar_execucao(IN p_schema character varying, IN p_versao_script character varying, IN p_observacao text) OWNER TO postgres;

--
-- TOC entry 8052 (class 0 OID 0)
-- Dependencies: 771
-- Name: PROCEDURE sp_iniciar_execucao(IN p_schema character varying, IN p_versao_script character varying, IN p_observacao text); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON PROCEDURE auditoria.sp_iniciar_execucao(IN p_schema character varying, IN p_versao_script character varying, IN p_observacao text) IS 'Cria e inicializa uma execução do framework de auditoria para o schema e versão de script informados.';


--
-- TOC entry 767 (class 1255 OID 41643)
-- Name: sp_limpar_historico(integer); Type: PROCEDURE; Schema: auditoria; Owner: postgres
--

CREATE PROCEDURE auditoria.sp_limpar_historico(IN p_dias integer DEFAULT 180)
    LANGUAGE plpgsql
    AS $$

BEGIN

DELETE

FROM auditoria.execucao

WHERE data_inicio<
CURRENT_TIMESTAMP-
(p_dias||' days')::interval;

END;

$$;


ALTER PROCEDURE auditoria.sp_limpar_historico(IN p_dias integer) OWNER TO postgres;

--
-- TOC entry 8053 (class 0 OID 0)
-- Dependencies: 767
-- Name: PROCEDURE sp_limpar_historico(IN p_dias integer); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON PROCEDURE auditoria.sp_limpar_historico(IN p_dias integer) IS 'Executa a limpeza controlada do histórico de auditoria conforme o período de retenção informado em dias.';


--
-- TOC entry 766 (class 1255 OID 41642)
-- Name: sp_recalcular_score(bigint); Type: PROCEDURE; Schema: auditoria; Owner: postgres
--

CREATE PROCEDURE auditoria.sp_recalcular_score(IN p_execucao bigint)
    LANGUAGE plpgsql
    AS $$

DECLARE

v_score NUMERIC;

BEGIN

v_score :=
auditoria.fn_calcular_score(p_execucao);

UPDATE auditoria.execucao

SET

score_final=v_score,

classificacao=
auditoria.fn_classificar_score(v_score),

updated_at=CURRENT_TIMESTAMP

WHERE id_execucao=p_execucao;

END;

$$;


ALTER PROCEDURE auditoria.sp_recalcular_score(IN p_execucao bigint) OWNER TO postgres;

--
-- TOC entry 8054 (class 0 OID 0)
-- Dependencies: 766
-- Name: PROCEDURE sp_recalcular_score(IN p_execucao bigint); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON PROCEDURE auditoria.sp_recalcular_score(IN p_execucao bigint) IS 'Recalcula o score consolidado de uma execução de auditoria com base nos resultados registrados.';


--
-- TOC entry 773 (class 1255 OID 41812)
-- Name: sp_registrar_resultado(bigint, bigint, character varying, character varying, character varying, character varying, character varying, character varying, text, text, text); Type: PROCEDURE; Schema: auditoria; Owner: postgres
--

CREATE PROCEDURE auditoria.sp_registrar_resultado(IN p_execucao bigint, IN p_item bigint, IN p_schema character varying, IN p_tabela character varying, IN p_coluna character varying, IN p_objeto character varying, IN p_status character varying, IN p_severidade character varying, IN p_valor_encontrado text, IN p_valor_esperado text, IN p_observacao text)
    LANGUAGE plpgsql
    AS $$
BEGIN

    INSERT INTO auditoria.resultado
    (
        id_execucao,

        id_item,

        schema_nome,

        tabela_nome,

        coluna_nome,

        objeto_nome,

        status,

        severidade,

        valor_encontrado,

        valor_esperado,

        observacao,

        data_execucao,

        created_at,

        versao
    )

    VALUES
    (
        p_execucao,

        p_item,

        p_schema,

        p_tabela,

        p_coluna,

        p_objeto,

        p_status,

        p_severidade,

        p_valor_encontrado,

        p_valor_esperado,

        p_observacao,

        CURRENT_TIMESTAMP,

        CURRENT_TIMESTAMP,

        1
    );

END;
$$;


ALTER PROCEDURE auditoria.sp_registrar_resultado(IN p_execucao bigint, IN p_item bigint, IN p_schema character varying, IN p_tabela character varying, IN p_coluna character varying, IN p_objeto character varying, IN p_status character varying, IN p_severidade character varying, IN p_valor_encontrado text, IN p_valor_esperado text, IN p_observacao text) OWNER TO postgres;

--
-- TOC entry 8055 (class 0 OID 0)
-- Dependencies: 773
-- Name: PROCEDURE sp_registrar_resultado(IN p_execucao bigint, IN p_item bigint, IN p_schema character varying, IN p_tabela character varying, IN p_coluna character varying, IN p_objeto character varying, IN p_status character varying, IN p_severidade character varying, IN p_valor_encontrado text, IN p_valor_esperado text, IN p_observacao text); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON PROCEDURE auditoria.sp_registrar_resultado(IN p_execucao bigint, IN p_item bigint, IN p_schema character varying, IN p_tabela character varying, IN p_coluna character varying, IN p_objeto character varying, IN p_status character varying, IN p_severidade character varying, IN p_valor_encontrado text, IN p_valor_esperado text, IN p_observacao text) IS 'Registra detalhadamente o resultado de uma regra de auditoria, incluindo objeto, status, severidade, valores encontrado e esperado e observação.';


--
-- TOC entry 768 (class 1255 OID 41644)
-- Name: sp_reprocessar_execucao(bigint); Type: PROCEDURE; Schema: auditoria; Owner: postgres
--

CREATE PROCEDURE auditoria.sp_reprocessar_execucao(IN p_execucao bigint)
    LANGUAGE plpgsql
    AS $$

BEGIN

DELETE

FROM auditoria.resultado

WHERE id_execucao=p_execucao;

DELETE

FROM auditoria.score

WHERE id_execucao=p_execucao;

DELETE

FROM auditoria.recomendacao

WHERE id_execucao=p_execucao;

END;

$$;


ALTER PROCEDURE auditoria.sp_reprocessar_execucao(IN p_execucao bigint) OWNER TO postgres;

--
-- TOC entry 8056 (class 0 OID 0)
-- Dependencies: 768
-- Name: PROCEDURE sp_reprocessar_execucao(IN p_execucao bigint); Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON PROCEDURE auditoria.sp_reprocessar_execucao(IN p_execucao bigint) IS 'Reprocessa uma execução de auditoria utilizando as regras e informações disponíveis no framework.';


--
-- TOC entry 738 (class 1255 OID 25072)
-- Name: fn_atualiza_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_atualiza_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

NEW.updated_at = CURRENT_TIMESTAMP;
NEW.versao = OLD.versao + 1;

RETURN NEW;

END;

$$;


ALTER FUNCTION public.fn_atualiza_updated_at() OWNER TO postgres;

--
-- TOC entry 8057 (class 0 OID 0)
-- Dependencies: 738
-- Name: FUNCTION fn_atualiza_updated_at(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_atualiza_updated_at() IS 'Atualiza automaticamente o campo de data de atualização do registro durante operações controladas por trigger.';


--
-- TOC entry 740 (class 1255 OID 33283)
-- Name: fn_incrementar_versao(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_incrementar_versao() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

    NEW.versao := OLD.versao + 1;

    RETURN NEW;

END;

$$;


ALTER FUNCTION public.fn_incrementar_versao() OWNER TO postgres;

--
-- TOC entry 8058 (class 0 OID 0)
-- Dependencies: 740
-- Name: FUNCTION fn_incrementar_versao(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_incrementar_versao() IS 'Incrementa a versão do registro conforme a regra de versionamento definida para o objeto.';


--
-- TOC entry 776 (class 1255 OID 25901)
-- Name: fn_log_auditoria(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_log_auditoria() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_pk_column text;
    v_registro_id integer;
BEGIN
    -- Descobre dinamicamente o nome da coluna de PK da tabela que disparou o trigger
    SELECT a.attname INTO v_pk_column
    FROM pg_index i
    JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = ANY (i.indkey)
    WHERE i.indrelid = (TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME)::regclass
      AND i.indisprimary
    LIMIT 1;

    IF TG_OP = 'INSERT' THEN
        IF v_pk_column IS NOT NULL THEN
            BEGIN
                v_registro_id := (to_jsonb(NEW) ->> v_pk_column)::integer;
            EXCEPTION WHEN OTHERS THEN
                v_registro_id := NULL;
            END;
        END IF;
        INSERT INTO public.log_auditoria (tabela_nome, registro_id, acao, dados_novos)
        VALUES (TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME, v_registro_id, 'INSERT', to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        IF v_pk_column IS NOT NULL THEN
            BEGIN
                v_registro_id := (to_jsonb(NEW) ->> v_pk_column)::integer;
            EXCEPTION WHEN OTHERS THEN
                v_registro_id := NULL;
            END;
        END IF;
        INSERT INTO public.log_auditoria (tabela_nome, registro_id, acao, dados_antigos, dados_novos)
        VALUES (TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME, v_registro_id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;

    ELSIF TG_OP = 'DELETE' THEN
        IF v_pk_column IS NOT NULL THEN
            BEGIN
                v_registro_id := (to_jsonb(OLD) ->> v_pk_column)::integer;
            EXCEPTION WHEN OTHERS THEN
                v_registro_id := NULL;
            END;
        END IF;
        INSERT INTO public.log_auditoria (tabela_nome, registro_id, acao, dados_antigos)
        VALUES (TG_TABLE_SCHEMA || '.' || TG_TABLE_NAME, v_registro_id, 'DELETE', to_jsonb(OLD));
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.fn_log_auditoria() OWNER TO postgres;

--
-- TOC entry 8059 (class 0 OID 0)
-- Dependencies: 776
-- Name: FUNCTION fn_log_auditoria(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_log_auditoria() IS 'Registra informações de auditoria associadas às operações executadas nos objetos vinculados ao trigger.';


--
-- TOC entry 739 (class 1255 OID 33282)
-- Name: fn_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

    NEW.updated_at := CURRENT_TIMESTAMP;

    RETURN NEW;

END;

$$;


ALTER FUNCTION public.fn_updated_at() OWNER TO postgres;

--
-- TOC entry 8060 (class 0 OID 0)
-- Dependencies: 739
-- Name: FUNCTION fn_updated_at(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_updated_at() IS 'Fornece o mecanismo de atualização automática do campo de controle temporal utilizado pelos objetos associados.';


--
-- TOC entry 741 (class 1255 OID 33284)
-- Name: fn_usuario_logado(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.fn_usuario_logado() RETURNS character varying
    LANGUAGE sql
    AS $$

SELECT CURRENT_USER;

$$;


ALTER FUNCTION public.fn_usuario_logado() OWNER TO postgres;

--
-- TOC entry 8061 (class 0 OID 0)
-- Dependencies: 741
-- Name: FUNCTION fn_usuario_logado(); Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON FUNCTION public.fn_usuario_logado() IS 'Obtém a identificação do usuário atualmente associado à sessão do banco de dados.';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 690 (class 1259 OID 43274)
-- Name: auditoria_pos_padronizacao_10_4_5; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.auditoria_pos_padronizacao_10_4_5 (
    id_auditoria bigint NOT NULL,
    id_mapa bigint,
    auditado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    schema_name character varying(63) NOT NULL,
    table_name character varying(63) NOT NULL,
    constraint_name_sugerido character varying(255),
    constraint_name_fisico character varying(63),
    constraint_type character varying(30) NOT NULL,
    colunas text,
    tabela_referenciada character varying(63),
    colunas_referenciadas text,
    definicao_constraint text,
    encontrada boolean DEFAULT false NOT NULL,
    nome_exato boolean DEFAULT false NOT NULL,
    nome_truncado boolean DEFAULT false NOT NULL,
    nome_divergente boolean DEFAULT false NOT NULL,
    constraint_validada boolean,
    integridade_ok boolean,
    duplicada boolean DEFAULT false NOT NULL,
    colisao boolean DEFAULT false NOT NULL,
    resultado character varying(30) NOT NULL,
    observacao text
);


ALTER TABLE auditoria.auditoria_pos_padronizacao_10_4_5 OWNER TO postgres;

--
-- TOC entry 689 (class 1259 OID 43273)
-- Name: auditoria_pos_padronizacao_10_4_5_id_auditoria_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

CREATE SEQUENCE auditoria.auditoria_pos_padronizacao_10_4_5_id_auditoria_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.auditoria_pos_padronizacao_10_4_5_id_auditoria_seq OWNER TO postgres;

--
-- TOC entry 8062 (class 0 OID 0)
-- Dependencies: 689
-- Name: auditoria_pos_padronizacao_10_4_5_id_auditoria_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.auditoria_pos_padronizacao_10_4_5_id_auditoria_seq OWNED BY auditoria.auditoria_pos_padronizacao_10_4_5.id_auditoria;


--
-- TOC entry 640 (class 1259 OID 41747)
-- Name: catalogo_coluna; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.catalogo_coluna (
    id_coluna bigint NOT NULL,
    id_tabela bigint,
    nome character varying(120),
    tipo character varying(80),
    tamanho integer,
    nullable boolean,
    default_value text,
    pk boolean,
    fk boolean,
    unique_key boolean,
    indice boolean,
    comentario text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE auditoria.catalogo_coluna OWNER TO postgres;

--
-- TOC entry 639 (class 1259 OID 41746)
-- Name: catalogo_coluna_id_coluna_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.catalogo_coluna ALTER COLUMN id_coluna ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.catalogo_coluna_id_coluna_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 636 (class 1259 OID 41725)
-- Name: catalogo_schema; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.catalogo_schema (
    id_schema bigint NOT NULL,
    schema_nome character varying(100),
    owner_name character varying(100),
    comentario text,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE auditoria.catalogo_schema OWNER TO postgres;

--
-- TOC entry 635 (class 1259 OID 41724)
-- Name: catalogo_schema_id_schema_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.catalogo_schema ALTER COLUMN id_schema ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.catalogo_schema_id_schema_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 638 (class 1259 OID 41737)
-- Name: catalogo_tabela; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.catalogo_tabela (
    id_tabela bigint NOT NULL,
    id_schema bigint,
    nome character varying(120),
    tipo character varying(30),
    owner_name character varying(100),
    comentario text,
    possui_pk boolean,
    possui_fk boolean,
    possui_indice boolean,
    possui_trigger boolean,
    possui_auditoria boolean,
    quantidade_colunas integer,
    quantidade_registros bigint,
    tamanho_mb numeric(12,2),
    ultimo_vacuum timestamp without time zone,
    ultimo_analyze timestamp without time zone,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE auditoria.catalogo_tabela OWNER TO postgres;

--
-- TOC entry 637 (class 1259 OID 41736)
-- Name: catalogo_tabela_id_tabela_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.catalogo_tabela ALTER COLUMN id_tabela ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.catalogo_tabela_id_tabela_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 608 (class 1259 OID 41469)
-- Name: categoria; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.categoria (
    id_categoria smallint NOT NULL,
    codigo character varying(30) NOT NULL,
    descricao character varying(200) NOT NULL,
    peso numeric(5,2) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1 NOT NULL
);


ALTER TABLE auditoria.categoria OWNER TO postgres;

--
-- TOC entry 8063 (class 0 OID 0)
-- Dependencies: 608
-- Name: TABLE categoria; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.categoria IS 'Categorias utilizadas no cálculo do ICB.';


--
-- TOC entry 607 (class 1259 OID 41468)
-- Name: categoria_id_categoria_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.categoria ALTER COLUMN id_categoria ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.categoria_id_categoria_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 677 (class 1259 OID 42870)
-- Name: colunas_identificadoras; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.colunas_identificadoras (
    id bigint NOT NULL,
    schema_name character varying(255) NOT NULL,
    table_name character varying(255) NOT NULL,
    column_name character varying(255) NOT NULL,
    data_type character varying(255) NOT NULL,
    is_nullable character varying(3) NOT NULL,
    column_default text,
    auditado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auditoria.colunas_identificadoras OWNER TO postgres;

--
-- TOC entry 676 (class 1259 OID 42869)
-- Name: colunas_identificadoras_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.colunas_identificadoras ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.colunas_identificadoras_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 663 (class 1259 OID 42755)
-- Name: colunas_not_null_sem_default; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.colunas_not_null_sem_default (
    id bigint NOT NULL,
    schema_name character varying(255) NOT NULL,
    table_name character varying(255) NOT NULL,
    column_name character varying(255) NOT NULL,
    data_type character varying(255) NOT NULL,
    detectado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auditoria.colunas_not_null_sem_default OWNER TO postgres;

--
-- TOC entry 662 (class 1259 OID 42754)
-- Name: colunas_not_null_sem_default_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.colunas_not_null_sem_default ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.colunas_not_null_sem_default_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 661 (class 1259 OID 42738)
-- Name: colunas_sem_comentario; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.colunas_sem_comentario (
    id bigint NOT NULL,
    schema_name character varying(255) NOT NULL,
    table_name character varying(255) NOT NULL,
    column_name character varying(255) NOT NULL,
    data_type character varying(255) NOT NULL,
    detectado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auditoria.colunas_sem_comentario OWNER TO postgres;

--
-- TOC entry 8064 (class 0 OID 0)
-- Dependencies: 661
-- Name: TABLE colunas_sem_comentario; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.colunas_sem_comentario IS 'Colunas que ainda não possuem documentação estrutural.';


--
-- TOC entry 660 (class 1259 OID 42737)
-- Name: colunas_sem_comentario_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.colunas_sem_comentario ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.colunas_sem_comentario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 620 (class 1259 OID 41615)
-- Name: configuracao; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.configuracao (
    id_configuracao smallint NOT NULL,
    chave character varying(100) NOT NULL,
    valor character varying(500),
    descricao text,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1 NOT NULL
);


ALTER TABLE auditoria.configuracao OWNER TO postgres;

--
-- TOC entry 619 (class 1259 OID 41614)
-- Name: configuracao_id_configuracao_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.configuracao ALTER COLUMN id_configuracao ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.configuracao_id_configuracao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 651 (class 1259 OID 41853)
-- Name: core; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.core (
    id_core bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(200) NOT NULL,
    descricao text,
    versao character varying(20),
    status character varying(30),
    ambiente character varying(20),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    revisao integer DEFAULT 1
);


ALTER TABLE auditoria.core OWNER TO postgres;

--
-- TOC entry 8065 (class 0 OID 0)
-- Dependencies: 651
-- Name: TABLE core; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.core IS 'Cadastro do núcleo do Framework Enterprise';


--
-- TOC entry 650 (class 1259 OID 41852)
-- Name: core_id_core_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

CREATE SEQUENCE auditoria.core_id_core_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.core_id_core_seq OWNER TO postgres;

--
-- TOC entry 8066 (class 0 OID 0)
-- Dependencies: 650
-- Name: core_id_core_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.core_id_core_seq OWNED BY auditoria.core.id_core;


--
-- TOC entry 686 (class 1259 OID 43184)
-- Name: etapa_10_4_4_snapshot; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.etapa_10_4_4_snapshot (
    snapshot_id bigint NOT NULL,
    snapshot_em timestamp with time zone DEFAULT clock_timestamp() NOT NULL,
    schema_name text NOT NULL,
    table_name text NOT NULL,
    constraint_type text NOT NULL,
    constraint_name_atual text NOT NULL,
    nome_padrao_sugerido text NOT NULL,
    constraint_definition text,
    constraint_oid oid,
    aplicado boolean DEFAULT false NOT NULL,
    aplicado_em timestamp with time zone
);


ALTER TABLE auditoria.etapa_10_4_4_snapshot OWNER TO postgres;

--
-- TOC entry 685 (class 1259 OID 43183)
-- Name: etapa_10_4_4_snapshot_snapshot_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.etapa_10_4_4_snapshot ALTER COLUMN snapshot_id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.etapa_10_4_4_snapshot_snapshot_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 606 (class 1259 OID 41446)
-- Name: execucao; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.execucao (
    id_execucao bigint NOT NULL,
    versao_banco character varying(30) NOT NULL,
    versao_script character varying(30) NOT NULL,
    schema_auditado character varying(100) NOT NULL,
    usuario_execucao character varying(100) NOT NULL,
    host_execucao character varying(200),
    banco character varying(100),
    data_inicio timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    data_fim timestamp without time zone,
    tempo_execucao_ms bigint,
    score_final numeric(5,2),
    classificacao character varying(30),
    status_execucao character varying(30),
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1 NOT NULL
);


ALTER TABLE auditoria.execucao OWNER TO postgres;

--
-- TOC entry 8067 (class 0 OID 0)
-- Dependencies: 606
-- Name: TABLE execucao; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.execucao IS 'Cabeçalho das execuções de auditoria do banco.';


--
-- TOC entry 8068 (class 0 OID 0)
-- Dependencies: 606
-- Name: COLUMN execucao.score_final; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.execucao.score_final IS 'Índice Geral de Conformidade do Banco (ICB).';


--
-- TOC entry 8069 (class 0 OID 0)
-- Dependencies: 606
-- Name: COLUMN execucao.classificacao; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.execucao.classificacao IS 'Excelente, Muito Bom, Bom, Regular ou Crítico.';


--
-- TOC entry 8070 (class 0 OID 0)
-- Dependencies: 606
-- Name: COLUMN execucao.status_execucao; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.execucao.status_execucao IS 'EXECUTANDO, FINALIZADO ou ERRO.';


--
-- TOC entry 688 (class 1259 OID 43260)
-- Name: execucao_auditoria; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.execucao_auditoria (
    id_execucao bigint NOT NULL,
    etapa character varying(20) NOT NULL,
    iniciado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    finalizado_em timestamp with time zone,
    status character varying(30) NOT NULL,
    descricao text
);


ALTER TABLE auditoria.execucao_auditoria OWNER TO postgres;

--
-- TOC entry 687 (class 1259 OID 43259)
-- Name: execucao_auditoria_id_execucao_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

CREATE SEQUENCE auditoria.execucao_auditoria_id_execucao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.execucao_auditoria_id_execucao_seq OWNER TO postgres;

--
-- TOC entry 8071 (class 0 OID 0)
-- Dependencies: 687
-- Name: execucao_auditoria_id_execucao_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.execucao_auditoria_id_execucao_seq OWNED BY auditoria.execucao_auditoria.id_execucao;


--
-- TOC entry 653 (class 1259 OID 42667)
-- Name: execucao_correcao; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.execucao_correcao (
    id_execucao bigint NOT NULL,
    script character varying(200) NOT NULL,
    etapa character varying(200) NOT NULL,
    iniciado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    finalizado_em timestamp with time zone,
    status character varying(30) DEFAULT 'EM_EXECUCAO'::character varying NOT NULL,
    observacao text,
    CONSTRAINT ck_execucao_correcao_status CHECK (((status)::text = ANY ((ARRAY['EM_EXECUCAO'::character varying, 'CONCLUIDA'::character varying, 'CONCLUIDO'::character varying, 'ERRO'::character varying, 'FALHA'::character varying, 'CANCELADA'::character varying, 'CANCELADO'::character varying])::text[])))
);


ALTER TABLE auditoria.execucao_correcao OWNER TO postgres;

--
-- TOC entry 652 (class 1259 OID 42666)
-- Name: execucao_correcao_id_execucao_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.execucao_correcao ALTER COLUMN id_execucao ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.execucao_correcao_id_execucao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 605 (class 1259 OID 41445)
-- Name: execucao_id_execucao_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.execucao ALTER COLUMN id_execucao ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.execucao_id_execucao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 649 (class 1259 OID 41824)
-- Name: executor; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.executor (
    id_executor bigint NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    descricao text,
    tipo_objeto character varying(50),
    procedure_execucao character varying(200) NOT NULL,
    aceita_parametros boolean DEFAULT true,
    permite_correcao boolean DEFAULT false,
    ordem_execucao integer DEFAULT 0,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE auditoria.executor OWNER TO postgres;

--
-- TOC entry 8072 (class 0 OID 0)
-- Dependencies: 649
-- Name: TABLE executor; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.executor IS 'Cadastro dos executores do Framework Enterprise';


--
-- TOC entry 648 (class 1259 OID 41823)
-- Name: executor_id_executor_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

CREATE SEQUENCE auditoria.executor_id_executor_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.executor_id_executor_seq OWNER TO postgres;

--
-- TOC entry 8073 (class 0 OID 0)
-- Dependencies: 648
-- Name: executor_id_executor_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.executor_id_executor_seq OWNED BY auditoria.executor.id_executor;


--
-- TOC entry 665 (class 1259 OID 42772)
-- Name: fks_sem_indice; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.fks_sem_indice (
    id bigint NOT NULL,
    schema_name character varying(255) NOT NULL,
    table_name character varying(255) NOT NULL,
    constraint_name character varying(255) NOT NULL,
    detectado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auditoria.fks_sem_indice OWNER TO postgres;

--
-- TOC entry 664 (class 1259 OID 42771)
-- Name: fks_sem_indice_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.fks_sem_indice ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.fks_sem_indice_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 671 (class 1259 OID 42823)
-- Name: indices_potencialmente_duplicados; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.indices_potencialmente_duplicados (
    id bigint NOT NULL,
    schema_name character varying(255) NOT NULL,
    table_name character varying(255) NOT NULL,
    index_1 character varying(255) NOT NULL,
    index_2 character varying(255) NOT NULL,
    definicao text NOT NULL,
    detectado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auditoria.indices_potencialmente_duplicados OWNER TO postgres;

--
-- TOC entry 670 (class 1259 OID 42822)
-- Name: indices_potencialmente_duplicados_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.indices_potencialmente_duplicados ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.indices_potencialmente_duplicados_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 667 (class 1259 OID 42788)
-- Name: inventario_constraints; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.inventario_constraints (
    id bigint NOT NULL,
    schema_name character varying(255) NOT NULL,
    table_name character varying(255) NOT NULL,
    constraint_name character varying(255) NOT NULL,
    constraint_type character varying(50) NOT NULL,
    definition text NOT NULL,
    auditado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auditoria.inventario_constraints OWNER TO postgres;

--
-- TOC entry 8074 (class 0 OID 0)
-- Dependencies: 667
-- Name: TABLE inventario_constraints; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.inventario_constraints IS 'Inventário das constraints existentes no banco.';


--
-- TOC entry 666 (class 1259 OID 42787)
-- Name: inventario_constraints_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.inventario_constraints ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.inventario_constraints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 675 (class 1259 OID 42854)
-- Name: inventario_identity; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.inventario_identity (
    id bigint NOT NULL,
    schema_name character varying(255) NOT NULL,
    table_name character varying(255) NOT NULL,
    column_name character varying(255) NOT NULL,
    identity_generation character varying(30),
    auditado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auditoria.inventario_identity OWNER TO postgres;

--
-- TOC entry 674 (class 1259 OID 42853)
-- Name: inventario_identity_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.inventario_identity ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.inventario_identity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 669 (class 1259 OID 42806)
-- Name: inventario_indices; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.inventario_indices (
    id bigint NOT NULL,
    schema_name character varying(255) NOT NULL,
    table_name character varying(255) NOT NULL,
    index_name character varying(255) NOT NULL,
    index_definition text NOT NULL,
    tamanho_bytes bigint,
    tamanho_formatado text,
    auditado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auditoria.inventario_indices OWNER TO postgres;

--
-- TOC entry 8075 (class 0 OID 0)
-- Dependencies: 669
-- Name: TABLE inventario_indices; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.inventario_indices IS 'Inventário dos índices existentes no banco.';


--
-- TOC entry 668 (class 1259 OID 42805)
-- Name: inventario_indices_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.inventario_indices ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.inventario_indices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 673 (class 1259 OID 42839)
-- Name: inventario_sequences; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.inventario_sequences (
    id bigint NOT NULL,
    sequence_schema character varying(255) NOT NULL,
    sequence_name character varying(255) NOT NULL,
    auditado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auditoria.inventario_sequences OWNER TO postgres;

--
-- TOC entry 672 (class 1259 OID 42838)
-- Name: inventario_sequences_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.inventario_sequences ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.inventario_sequences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 655 (class 1259 OID 42685)
-- Name: inventario_tabelas; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.inventario_tabelas (
    id_inventario bigint NOT NULL,
    schema_name character varying(255) NOT NULL,
    table_name character varying(255) NOT NULL,
    row_estimate bigint,
    tamanho_bytes bigint,
    tamanho_formatado text,
    possui_pk boolean DEFAULT false NOT NULL,
    possui_fk boolean DEFAULT false NOT NULL,
    possui_indices boolean DEFAULT false NOT NULL,
    possui_comentario boolean DEFAULT false NOT NULL,
    auditado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auditoria.inventario_tabelas OWNER TO postgres;

--
-- TOC entry 8076 (class 0 OID 0)
-- Dependencies: 655
-- Name: TABLE inventario_tabelas; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.inventario_tabelas IS 'Inventário estrutural das tabelas existentes no WMA Travel ERP.';


--
-- TOC entry 654 (class 1259 OID 42684)
-- Name: inventario_tabelas_id_inventario_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.inventario_tabelas ALTER COLUMN id_inventario ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.inventario_tabelas_id_inventario_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 610 (class 1259 OID 41489)
-- Name: item; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.item (
    id_item bigint NOT NULL,
    id_categoria smallint NOT NULL,
    codigo character varying(30) NOT NULL,
    descricao character varying(500) NOT NULL,
    criticidade character varying(20) NOT NULL,
    peso numeric(5,2) DEFAULT 1 NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1 NOT NULL,
    tipo_verificacao character varying(30),
    objeto_alvo character varying(30),
    script_origem character varying(100),
    procedure_execucao character varying(100),
    habilitado boolean DEFAULT true NOT NULL,
    ordem_execucao integer,
    versao_minima character varying(20),
    versao_maxima character varying(20),
    categoria_tecnica character varying(50),
    tempo_estimado_ms integer,
    observacao_tecnica text
);


ALTER TABLE auditoria.item OWNER TO postgres;

--
-- TOC entry 8077 (class 0 OID 0)
-- Dependencies: 610
-- Name: TABLE item; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.item IS 'Catálogo das regras de auditoria.';


--
-- TOC entry 609 (class 1259 OID 41488)
-- Name: item_id_item_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.item ALTER COLUMN id_item ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.item_id_item_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 618 (class 1259 OID 41595)
-- Name: log; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.log (
    id_log bigint NOT NULL,
    id_execucao bigint,
    script character varying(200),
    etapa character varying(100),
    sqlstate character varying(10),
    mensagem text,
    detalhe text,
    hint text,
    contexto text,
    severidade character varying(20),
    data_log timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1 NOT NULL
);


ALTER TABLE auditoria.log OWNER TO postgres;

--
-- TOC entry 8078 (class 0 OID 0)
-- Dependencies: 618
-- Name: TABLE log; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.log IS 'Registro de erros, avisos e mensagens produzidos durante a execução da auditoria.';


--
-- TOC entry 646 (class 1259 OID 41788)
-- Name: log_correcao; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.log_correcao (
    id_log bigint NOT NULL,
    data_execucao timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    schema_nome character varying(100),
    tabela_nome character varying(100),
    objeto character varying(100),
    tipo_correcao character varying(100),
    descricao text,
    sql_executado text,
    resultado character varying(20),
    erro text
);


ALTER TABLE auditoria.log_correcao OWNER TO postgres;

--
-- TOC entry 645 (class 1259 OID 41787)
-- Name: log_correcao_id_log_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

CREATE SEQUENCE auditoria.log_correcao_id_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE auditoria.log_correcao_id_log_seq OWNER TO postgres;

--
-- TOC entry 8079 (class 0 OID 0)
-- Dependencies: 645
-- Name: log_correcao_id_log_seq; Type: SEQUENCE OWNED BY; Schema: auditoria; Owner: postgres
--

ALTER SEQUENCE auditoria.log_correcao_id_log_seq OWNED BY auditoria.log_correcao.id_log;


--
-- TOC entry 617 (class 1259 OID 41594)
-- Name: log_id_log_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.log ALTER COLUMN id_log ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.log_id_log_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 681 (class 1259 OID 43064)
-- Name: mapa_padronizacao_constraints; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.mapa_padronizacao_constraints (
    id_mapa bigint NOT NULL,
    criado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    schema_name character varying(128) NOT NULL,
    table_name character varying(128) NOT NULL,
    constraint_name_atual character varying(255) NOT NULL,
    constraint_type character varying(30) NOT NULL,
    colunas text,
    tabela_referenciada character varying(255),
    colunas_referenciadas text,
    definicao_constraint text,
    prefixo_padrao character varying(20),
    nome_padrao_sugerido character varying(255),
    fora_do_padrao boolean DEFAULT false NOT NULL,
    status_mapa character varying(30) DEFAULT 'PENDENTE'::character varying NOT NULL,
    observacao text,
    CONSTRAINT ck_mapa_padronizacao_status CHECK (((status_mapa)::text = ANY ((ARRAY['PADRAO'::character varying, 'PENDENTE'::character varying, 'VALIDADO'::character varying, 'APLICADO'::character varying, 'IGNORADO'::character varying, 'ERRO'::character varying])::text[])))
);


ALTER TABLE auditoria.mapa_padronizacao_constraints OWNER TO postgres;

--
-- TOC entry 8080 (class 0 OID 0)
-- Dependencies: 681
-- Name: TABLE mapa_padronizacao_constraints; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.mapa_padronizacao_constraints IS 'ETAPA 10.4.2 - Mapa permanente de padronizacao das constraints do WMA Travel ERP. Esta tabela registra o nome atual, tipo, definicao e nome profissional sugerido sem alterar as constraints reais.';


--
-- TOC entry 8081 (class 0 OID 0)
-- Dependencies: 681
-- Name: COLUMN mapa_padronizacao_constraints.constraint_name_atual; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.mapa_padronizacao_constraints.constraint_name_atual IS 'Nome atualmente utilizado pela constraint no banco.';


--
-- TOC entry 8082 (class 0 OID 0)
-- Dependencies: 681
-- Name: COLUMN mapa_padronizacao_constraints.nome_padrao_sugerido; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.mapa_padronizacao_constraints.nome_padrao_sugerido IS 'Nome profissional recomendado para futura aplicação da padronização.';


--
-- TOC entry 8083 (class 0 OID 0)
-- Dependencies: 681
-- Name: COLUMN mapa_padronizacao_constraints.fora_do_padrao; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.mapa_padronizacao_constraints.fora_do_padrao IS 'Indica se o nome atual não utiliza o prefixo padronizado definido para o tipo da constraint.';


--
-- TOC entry 680 (class 1259 OID 43063)
-- Name: mapa_padronizacao_constraints_id_mapa_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.mapa_padronizacao_constraints ALTER COLUMN id_mapa ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.mapa_padronizacao_constraints_id_mapa_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 616 (class 1259 OID 41569)
-- Name: recomendacao; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.recomendacao (
    id_recomendacao bigint NOT NULL,
    id_execucao bigint NOT NULL,
    prioridade character varying(20) NOT NULL,
    categoria character varying(50),
    tabela_nome character varying(100),
    coluna_nome character varying(100),
    descricao text NOT NULL,
    script_sugerido character varying(255),
    corrigido boolean DEFAULT false NOT NULL,
    data_correcao timestamp without time zone,
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1 NOT NULL
);


ALTER TABLE auditoria.recomendacao OWNER TO postgres;

--
-- TOC entry 8084 (class 0 OID 0)
-- Dependencies: 616
-- Name: TABLE recomendacao; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.recomendacao IS 'Recomendações automáticas geradas durante a auditoria.';


--
-- TOC entry 615 (class 1259 OID 41568)
-- Name: recomendacao_id_recomendacao_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.recomendacao ALTER COLUMN id_recomendacao ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.recomendacao_id_recomendacao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 634 (class 1259 OID 41711)
-- Name: regra; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.regra (
    id_regra bigint NOT NULL,
    codigo character varying(30),
    descricao character varying(300),
    categoria character varying(50),
    objeto character varying(50),
    consulta_sql text,
    script_recomendado text,
    peso numeric(5,2),
    criticidade character varying(20),
    habilitado boolean DEFAULT true,
    ordem integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1,
    tipo_objeto character varying(30),
    objeto_alvo character varying(100),
    sql_diagnostico text,
    sql_correcao text,
    correcao_automatica boolean DEFAULT false,
    ativo boolean DEFAULT true,
    prioridade smallint DEFAULT 3,
    ordem_execucao integer DEFAULT 0,
    tempo_estimado_ms integer,
    versao_minima character varying(20),
    versao_maxima character varying(20),
    observacao text,
    id_executor bigint
);


ALTER TABLE auditoria.regra OWNER TO postgres;

--
-- TOC entry 8085 (class 0 OID 0)
-- Dependencies: 634
-- Name: TABLE regra; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.regra IS 'Cadastro central de todas as regras de diagnóstico do Framework.';


--
-- TOC entry 8086 (class 0 OID 0)
-- Dependencies: 634
-- Name: COLUMN regra.sql_diagnostico; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.regra.sql_diagnostico IS 'SQL responsável por localizar inconsistências.';


--
-- TOC entry 8087 (class 0 OID 0)
-- Dependencies: 634
-- Name: COLUMN regra.sql_correcao; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.regra.sql_correcao IS 'SQL utilizado para corrigir automaticamente o problema.';


--
-- TOC entry 8088 (class 0 OID 0)
-- Dependencies: 634
-- Name: COLUMN regra.correcao_automatica; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON COLUMN auditoria.regra.correcao_automatica IS 'Indica se a regra pode ser corrigida automaticamente.';


--
-- TOC entry 633 (class 1259 OID 41710)
-- Name: regra_id_regra_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.regra ALTER COLUMN id_regra ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.regra_id_regra_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 612 (class 1259 OID 41520)
-- Name: resultado; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.resultado (
    id_resultado bigint NOT NULL,
    id_execucao bigint NOT NULL,
    id_item bigint NOT NULL,
    schema_nome character varying(100),
    tabela_nome character varying(100),
    coluna_nome character varying(100),
    objeto_nome character varying(200),
    status character varying(20) NOT NULL,
    severidade character varying(20),
    valor_encontrado text,
    valor_esperado text,
    observacao text,
    sqlstate character varying(10),
    data_execucao timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1 NOT NULL
);


ALTER TABLE auditoria.resultado OWNER TO postgres;

--
-- TOC entry 8089 (class 0 OID 0)
-- Dependencies: 612
-- Name: TABLE resultado; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.resultado IS 'Resultado individual de cada verificação executada.';


--
-- TOC entry 611 (class 1259 OID 41519)
-- Name: resultado_id_resultado_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.resultado ALTER COLUMN id_resultado ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.resultado_id_resultado_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 614 (class 1259 OID 41552)
-- Name: score; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.score (
    id_score bigint NOT NULL,
    id_execucao bigint NOT NULL,
    estrutura numeric(5,2),
    integridade numeric(5,2),
    auditoria numeric(5,2),
    performance numeric(5,2),
    seguranca numeric(5,2),
    normalizacao numeric(5,2),
    padronizacao numeric(5,2),
    documentacao numeric(5,2),
    score_final numeric(5,2),
    classificacao character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE auditoria.score OWNER TO postgres;

--
-- TOC entry 613 (class 1259 OID 41551)
-- Name: score_id_score_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.score ALTER COLUMN id_score ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.score_id_score_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 632 (class 1259 OID 41695)
-- Name: script; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.script (
    id_script bigint NOT NULL,
    codigo character varying(30) NOT NULL,
    descricao character varying(200) NOT NULL,
    procedure_name character varying(150) NOT NULL,
    ordem_execucao integer NOT NULL,
    categoria character varying(50),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE auditoria.script OWNER TO postgres;

--
-- TOC entry 631 (class 1259 OID 41694)
-- Name: script_id_script_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.script ALTER COLUMN id_script ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.script_id_script_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 659 (class 1259 OID 42723)
-- Name: tabelas_sem_indices; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.tabelas_sem_indices (
    id bigint NOT NULL,
    schema_name character varying(255) NOT NULL,
    table_name character varying(255) NOT NULL,
    detectado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auditoria.tabelas_sem_indices OWNER TO postgres;

--
-- TOC entry 8090 (class 0 OID 0)
-- Dependencies: 659
-- Name: TABLE tabelas_sem_indices; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.tabelas_sem_indices IS 'Tabelas detectadas sem índices.';


--
-- TOC entry 658 (class 1259 OID 42722)
-- Name: tabelas_sem_indices_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.tabelas_sem_indices ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.tabelas_sem_indices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 657 (class 1259 OID 42708)
-- Name: tabelas_sem_pk; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.tabelas_sem_pk (
    id bigint NOT NULL,
    schema_name character varying(255) NOT NULL,
    table_name character varying(255) NOT NULL,
    detectado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE auditoria.tabelas_sem_pk OWNER TO postgres;

--
-- TOC entry 8091 (class 0 OID 0)
-- Dependencies: 657
-- Name: TABLE tabelas_sem_pk; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TABLE auditoria.tabelas_sem_pk IS 'Tabelas detectadas sem chave primária.';


--
-- TOC entry 656 (class 1259 OID 42707)
-- Name: tabelas_sem_pk_id_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.tabelas_sem_pk ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.tabelas_sem_pk_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 683 (class 1259 OID 43118)
-- Name: validacao_padronizacao_constraints; Type: TABLE; Schema: auditoria; Owner: postgres
--

CREATE TABLE auditoria.validacao_padronizacao_constraints (
    id_validacao bigint NOT NULL,
    criado_em timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    id_mapa bigint,
    schema_name character varying(128) NOT NULL,
    table_name character varying(128) NOT NULL,
    constraint_name_atual character varying(255) CONSTRAINT validacao_padronizacao_constrain_constraint_name_atual_not_null NOT NULL,
    constraint_type character varying(50) NOT NULL,
    colunas text,
    tabela_referenciada character varying(255),
    colunas_referenciadas text,
    nome_padrao_sugerido character varying(255),
    prefixo_padrao character varying(20),
    fora_do_padrao boolean DEFAULT false NOT NULL,
    possui_colisao boolean DEFAULT false NOT NULL,
    possui_conflito boolean DEFAULT false NOT NULL,
    tipo_validacao character varying(50),
    status_validacao character varying(50) DEFAULT 'PENDENTE'::character varying NOT NULL,
    observacao text,
    CONSTRAINT ck_validacao_padronizacao_status CHECK (((status_validacao)::text = ANY ((ARRAY['PENDENTE'::character varying, 'VALIDADO'::character varying, 'COLISAO'::character varying, 'CONFLITO'::character varying, 'ESPECIAL'::character varying, 'IGNORADO'::character varying, 'ERRO'::character varying])::text[])))
);


ALTER TABLE auditoria.validacao_padronizacao_constraints OWNER TO postgres;

--
-- TOC entry 682 (class 1259 OID 43117)
-- Name: validacao_padronizacao_constraints_id_validacao_seq; Type: SEQUENCE; Schema: auditoria; Owner: postgres
--

ALTER TABLE auditoria.validacao_padronizacao_constraints ALTER COLUMN id_validacao ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME auditoria.validacao_padronizacao_constraints_id_validacao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 629 (class 1259 OID 41682)
-- Name: vw_configuracao; Type: VIEW; Schema: auditoria; Owner: postgres
--

CREATE VIEW auditoria.vw_configuracao AS
 SELECT chave,
    valor,
    descricao
   FROM auditoria.configuracao
  WHERE (ativo = true);


ALTER VIEW auditoria.vw_configuracao OWNER TO postgres;

--
-- TOC entry 8092 (class 0 OID 0)
-- Dependencies: 629
-- Name: VIEW vw_configuracao; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON VIEW auditoria.vw_configuracao IS 'Apresenta as configurações cadastradas no framework de auditoria, permitindo consulta padronizada dos parâmetros operacionais e de governança.';


--
-- TOC entry 626 (class 1259 OID 41669)
-- Name: vw_dashboard_governanca; Type: VIEW; Schema: auditoria; Owner: postgres
--

CREATE VIEW auditoria.vw_dashboard_governanca AS
 SELECT id_execucao,
    data_inicio,
    score_final,
    classificacao,
    ( SELECT count(*) AS count
           FROM auditoria.resultado r
          WHERE (r.id_execucao = e.id_execucao)) AS total_itens,
    ( SELECT count(*) AS count
           FROM auditoria.resultado r
          WHERE ((r.id_execucao = e.id_execucao) AND ((r.status)::text = 'ERRO'::text))) AS erros,
    ( SELECT count(*) AS count
           FROM auditoria.resultado r
          WHERE ((r.id_execucao = e.id_execucao) AND ((r.status)::text = 'ATENCAO'::text))) AS alertas,
    ( SELECT count(*) AS count
           FROM auditoria.recomendacao x
          WHERE ((x.id_execucao = e.id_execucao) AND (x.corrigido = false))) AS recomendacoes
   FROM auditoria.execucao e
  ORDER BY id_execucao DESC;


ALTER VIEW auditoria.vw_dashboard_governanca OWNER TO postgres;

--
-- TOC entry 8093 (class 0 OID 0)
-- Dependencies: 626
-- Name: VIEW vw_dashboard_governanca; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON VIEW auditoria.vw_dashboard_governanca IS 'Consolida indicadores de governança do framework de auditoria para acompanhamento executivo da conformidade estrutural e operacional.';


--
-- TOC entry 623 (class 1259 OID 41656)
-- Name: vw_execucao_resumo; Type: VIEW; Schema: auditoria; Owner: postgres
--

CREATE VIEW auditoria.vw_execucao_resumo AS
 SELECT id_execucao,
    versao_banco,
    versao_script,
    usuario_execucao,
    data_inicio,
    tempo_execucao_ms,
    score_final,
    classificacao,
    status_execucao
   FROM auditoria.execucao
  ORDER BY id_execucao DESC;


ALTER VIEW auditoria.vw_execucao_resumo OWNER TO postgres;

--
-- TOC entry 8094 (class 0 OID 0)
-- Dependencies: 623
-- Name: VIEW vw_execucao_resumo; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON VIEW auditoria.vw_execucao_resumo IS 'Apresenta o resumo das execuções de auditoria, incluindo informações de controle, status e resultados consolidados.';


--
-- TOC entry 621 (class 1259 OID 41646)
-- Name: vw_health_check; Type: VIEW; Schema: auditoria; Owner: postgres
--

CREATE VIEW auditoria.vw_health_check AS
 SELECT id_execucao,
    data_inicio,
    data_fim,
    score_final,
    classificacao,
    status_execucao,
    ( SELECT count(*) AS count
           FROM auditoria.resultado r
          WHERE ((r.id_execucao = e.id_execucao) AND ((r.status)::text = 'ERRO'::text))) AS erros,
    ( SELECT count(*) AS count
           FROM auditoria.resultado r
          WHERE ((r.id_execucao = e.id_execucao) AND ((r.status)::text = 'ATENCAO'::text))) AS alertas,
    ( SELECT count(*) AS count
           FROM auditoria.resultado r
          WHERE ((r.id_execucao = e.id_execucao) AND ((r.status)::text = 'OK'::text))) AS conformes
   FROM auditoria.execucao e
  ORDER BY id_execucao DESC;


ALTER VIEW auditoria.vw_health_check OWNER TO postgres;

--
-- TOC entry 8095 (class 0 OID 0)
-- Dependencies: 621
-- Name: VIEW vw_health_check; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON VIEW auditoria.vw_health_check IS 'Apresenta os resultados das verificações de disponibilidade e integridade operacional do framework de auditoria.';


--
-- TOC entry 627 (class 1259 OID 41674)
-- Name: vw_historico_score; Type: VIEW; Schema: auditoria; Owner: postgres
--

CREATE VIEW auditoria.vw_historico_score AS
 SELECT id_execucao,
    data_inicio,
    score_final,
    classificacao
   FROM auditoria.execucao
  ORDER BY id_execucao;


ALTER VIEW auditoria.vw_historico_score OWNER TO postgres;

--
-- TOC entry 8096 (class 0 OID 0)
-- Dependencies: 627
-- Name: VIEW vw_historico_score; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON VIEW auditoria.vw_historico_score IS 'Apresenta o histórico dos scores obtidos nas execuções de auditoria para acompanhamento da evolução da qualidade e governança.';


--
-- TOC entry 624 (class 1259 OID 41660)
-- Name: vw_itens_criticos; Type: VIEW; Schema: auditoria; Owner: postgres
--

CREATE VIEW auditoria.vw_itens_criticos AS
 SELECT r.id_execucao,
    i.codigo,
    i.descricao,
    r.tabela_nome,
    r.coluna_nome,
    r.observacao,
    r.severidade
   FROM (auditoria.resultado r
     JOIN auditoria.item i ON ((i.id_item = r.id_item)))
  WHERE ((r.severidade)::text = 'CRITICA'::text)
  ORDER BY r.id_execucao DESC;


ALTER VIEW auditoria.vw_itens_criticos OWNER TO postgres;

--
-- TOC entry 8097 (class 0 OID 0)
-- Dependencies: 624
-- Name: VIEW vw_itens_criticos; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON VIEW auditoria.vw_itens_criticos IS 'Relaciona os itens críticos identificados nas auditorias, permitindo priorização de riscos e ações corretivas.';


--
-- TOC entry 628 (class 1259 OID 41678)
-- Name: vw_logs; Type: VIEW; Schema: auditoria; Owner: postgres
--

CREATE VIEW auditoria.vw_logs AS
 SELECT id_execucao,
    script,
    etapa,
    sqlstate,
    mensagem,
    severidade,
    data_log
   FROM auditoria.log
  ORDER BY data_log DESC;


ALTER VIEW auditoria.vw_logs OWNER TO postgres;

--
-- TOC entry 8098 (class 0 OID 0)
-- Dependencies: 628
-- Name: VIEW vw_logs; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON VIEW auditoria.vw_logs IS 'Apresenta os registros de log gerados pelo framework de auditoria para rastreabilidade das execuções e eventos operacionais.';


--
-- TOC entry 679 (class 1259 OID 42891)
-- Name: vw_problemas_estruturais; Type: VIEW; Schema: auditoria; Owner: postgres
--

CREATE VIEW auditoria.vw_problemas_estruturais AS
 SELECT 'TABELA_SEM_PK'::text AS tipo_problema,
    tabelas_sem_pk.schema_name,
    tabelas_sem_pk.table_name,
    NULL::text AS objeto
   FROM auditoria.tabelas_sem_pk
UNION ALL
 SELECT 'TABELA_SEM_INDICE'::text AS tipo_problema,
    tabelas_sem_indices.schema_name,
    tabelas_sem_indices.table_name,
    NULL::text AS objeto
   FROM auditoria.tabelas_sem_indices
UNION ALL
 SELECT 'COLUNA_SEM_COMENTARIO'::text AS tipo_problema,
    colunas_sem_comentario.schema_name,
    colunas_sem_comentario.table_name,
    colunas_sem_comentario.column_name AS objeto
   FROM auditoria.colunas_sem_comentario
UNION ALL
 SELECT 'NOT_NULL_SEM_DEFAULT'::text AS tipo_problema,
    colunas_not_null_sem_default.schema_name,
    colunas_not_null_sem_default.table_name,
    colunas_not_null_sem_default.column_name AS objeto
   FROM auditoria.colunas_not_null_sem_default;


ALTER VIEW auditoria.vw_problemas_estruturais OWNER TO postgres;

--
-- TOC entry 8099 (class 0 OID 0)
-- Dependencies: 679
-- Name: VIEW vw_problemas_estruturais; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON VIEW auditoria.vw_problemas_estruturais IS 'Consolida problemas estruturais identificados durante as auditorias do banco de dados para fins de análise e correção.';


--
-- TOC entry 625 (class 1259 OID 41665)
-- Name: vw_recomendacoes; Type: VIEW; Schema: auditoria; Owner: postgres
--

CREATE VIEW auditoria.vw_recomendacoes AS
 SELECT id_execucao,
    prioridade,
    categoria,
    tabela_nome,
    descricao,
    script_sugerido,
    corrigido
   FROM auditoria.recomendacao
  ORDER BY id_execucao DESC, prioridade;


ALTER VIEW auditoria.vw_recomendacoes OWNER TO postgres;

--
-- TOC entry 8100 (class 0 OID 0)
-- Dependencies: 625
-- Name: VIEW vw_recomendacoes; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON VIEW auditoria.vw_recomendacoes IS 'Apresenta as recomendações registradas pelo framework de auditoria, incluindo prioridade, categoria e objeto relacionado.';


--
-- TOC entry 678 (class 1259 OID 42887)
-- Name: vw_resumo_estrutura; Type: VIEW; Schema: auditoria; Owner: postgres
--

CREATE VIEW auditoria.vw_resumo_estrutura AS
 SELECT count(*) AS total_tabelas,
    count(*) FILTER (WHERE possui_pk) AS tabelas_com_pk,
    count(*) FILTER (WHERE (NOT possui_pk)) AS tabelas_sem_pk,
    count(*) FILTER (WHERE possui_fk) AS tabelas_com_fk,
    count(*) FILTER (WHERE possui_indices) AS tabelas_com_indices,
    count(*) FILTER (WHERE (NOT possui_indices)) AS tabelas_sem_indices
   FROM auditoria.inventario_tabelas;


ALTER VIEW auditoria.vw_resumo_estrutura OWNER TO postgres;

--
-- TOC entry 8101 (class 0 OID 0)
-- Dependencies: 678
-- Name: VIEW vw_resumo_estrutura; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON VIEW auditoria.vw_resumo_estrutura IS 'Apresenta um resumo da estrutura do banco de dados avaliada pelo framework de auditoria.';


--
-- TOC entry 630 (class 1259 OID 41686)
-- Name: vw_resumo_execucao; Type: VIEW; Schema: auditoria; Owner: postgres
--

CREATE VIEW auditoria.vw_resumo_execucao AS
 SELECT e.id_execucao,
    e.score_final,
    e.classificacao,
    count(r.id_resultado) AS total_verificacoes,
    sum(
        CASE
            WHEN ((r.status)::text = 'OK'::text) THEN 1
            ELSE 0
        END) AS conformes,
    sum(
        CASE
            WHEN ((r.status)::text = 'ATENCAO'::text) THEN 1
            ELSE 0
        END) AS alertas,
    sum(
        CASE
            WHEN ((r.status)::text = 'ERRO'::text) THEN 1
            ELSE 0
        END) AS erros
   FROM (auditoria.execucao e
     LEFT JOIN auditoria.resultado r ON ((r.id_execucao = e.id_execucao)))
  GROUP BY e.id_execucao, e.score_final, e.classificacao;


ALTER VIEW auditoria.vw_resumo_execucao OWNER TO postgres;

--
-- TOC entry 8102 (class 0 OID 0)
-- Dependencies: 630
-- Name: VIEW vw_resumo_execucao; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON VIEW auditoria.vw_resumo_execucao IS 'Consolida informações essenciais das execuções do framework de auditoria para consulta e acompanhamento operacional.';


--
-- TOC entry 622 (class 1259 OID 41651)
-- Name: vw_score_categoria; Type: VIEW; Schema: auditoria; Owner: postgres
--

CREATE VIEW auditoria.vw_score_categoria AS
 SELECT e.id_execucao,
    s.estrutura,
    s.integridade,
    s.auditoria,
    s.performance,
    s.seguranca,
    s.normalizacao,
    s.padronizacao,
    s.documentacao,
    s.score_final,
    s.classificacao
   FROM (auditoria.score s
     JOIN auditoria.execucao e ON ((e.id_execucao = s.id_execucao)));


ALTER VIEW auditoria.vw_score_categoria OWNER TO postgres;

--
-- TOC entry 8103 (class 0 OID 0)
-- Dependencies: 622
-- Name: VIEW vw_score_categoria; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON VIEW auditoria.vw_score_categoria IS 'Apresenta a composição dos scores de auditoria por categoria, permitindo análise detalhada dos critérios de governança.';


--
-- TOC entry 644 (class 1259 OID 41774)
-- Name: migracao; Type: TABLE; Schema: config; Owner: postgres
--

CREATE TABLE config.migracao (
    id bigint NOT NULL,
    script character varying(200),
    descricao character varying(500),
    executado_em timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    executado_por character varying(100),
    sucesso boolean DEFAULT true
);


ALTER TABLE config.migracao OWNER TO postgres;

--
-- TOC entry 643 (class 1259 OID 41773)
-- Name: migracao_id_seq; Type: SEQUENCE; Schema: config; Owner: postgres
--

CREATE SEQUENCE config.migracao_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE config.migracao_id_seq OWNER TO postgres;

--
-- TOC entry 8104 (class 0 OID 0)
-- Dependencies: 643
-- Name: migracao_id_seq; Type: SEQUENCE OWNED BY; Schema: config; Owner: postgres
--

ALTER SEQUENCE config.migracao_id_seq OWNED BY config.migracao.id;


--
-- TOC entry 647 (class 1259 OID 41799)
-- Name: parametro; Type: TABLE; Schema: config; Owner: postgres
--

CREATE TABLE config.parametro (
    chave character varying(100) NOT NULL,
    valor character varying(500),
    descricao character varying(500)
);


ALTER TABLE config.parametro OWNER TO postgres;

--
-- TOC entry 642 (class 1259 OID 41760)
-- Name: versao_banco; Type: TABLE; Schema: config; Owner: postgres
--

CREATE TABLE config.versao_banco (
    id bigint NOT NULL,
    versao character varying(30) NOT NULL,
    descricao character varying(500),
    script character varying(200),
    data_execucao timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    usuario_execucao character varying(100) DEFAULT CURRENT_USER
);


ALTER TABLE config.versao_banco OWNER TO postgres;

--
-- TOC entry 641 (class 1259 OID 41759)
-- Name: versao_banco_id_seq; Type: SEQUENCE; Schema: config; Owner: postgres
--

CREATE SEQUENCE config.versao_banco_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE config.versao_banco_id_seq OWNER TO postgres;

--
-- TOC entry 8105 (class 0 OID 0)
-- Dependencies: 641
-- Name: versao_banco_id_seq; Type: SEQUENCE OWNED BY; Schema: config; Owner: postgres
--

ALTER SEQUENCE config.versao_banco_id_seq OWNED BY config.versao_banco.id;


--
-- TOC entry 527 (class 1259 OID 27221)
-- Name: dim_cliente; Type: TABLE; Schema: dw; Owner: postgres
--

CREATE TABLE dw.dim_cliente (
    id_cliente_dw integer NOT NULL,
    id_cliente_origem integer,
    nome character varying(150),
    cidade character varying(100),
    estado character varying(50),
    data_cadastro date,
    ativo boolean
);


ALTER TABLE dw.dim_cliente OWNER TO postgres;

--
-- TOC entry 526 (class 1259 OID 27220)
-- Name: dim_cliente_id_cliente_dw_seq; Type: SEQUENCE; Schema: dw; Owner: postgres
--

CREATE SEQUENCE dw.dim_cliente_id_cliente_dw_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dw.dim_cliente_id_cliente_dw_seq OWNER TO postgres;

--
-- TOC entry 8106 (class 0 OID 0)
-- Dependencies: 526
-- Name: dim_cliente_id_cliente_dw_seq; Type: SEQUENCE OWNED BY; Schema: dw; Owner: postgres
--

ALTER SEQUENCE dw.dim_cliente_id_cliente_dw_seq OWNED BY dw.dim_cliente.id_cliente_dw;


--
-- TOC entry 531 (class 1259 OID 27239)
-- Name: dim_destino; Type: TABLE; Schema: dw; Owner: postgres
--

CREATE TABLE dw.dim_destino (
    id_destino_dw integer NOT NULL,
    id_destino_origem integer,
    nome character varying(150),
    cidade character varying(100),
    estado character varying(50),
    pais character varying(100)
);


ALTER TABLE dw.dim_destino OWNER TO postgres;

--
-- TOC entry 530 (class 1259 OID 27238)
-- Name: dim_destino_id_destino_dw_seq; Type: SEQUENCE; Schema: dw; Owner: postgres
--

CREATE SEQUENCE dw.dim_destino_id_destino_dw_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dw.dim_destino_id_destino_dw_seq OWNER TO postgres;

--
-- TOC entry 8107 (class 0 OID 0)
-- Dependencies: 530
-- Name: dim_destino_id_destino_dw_seq; Type: SEQUENCE OWNED BY; Schema: dw; Owner: postgres
--

ALTER SEQUENCE dw.dim_destino_id_destino_dw_seq OWNED BY dw.dim_destino.id_destino_dw;


--
-- TOC entry 533 (class 1259 OID 27247)
-- Name: dim_fornecedor; Type: TABLE; Schema: dw; Owner: postgres
--

CREATE TABLE dw.dim_fornecedor (
    id_fornecedor_dw integer NOT NULL,
    id_fornecedor_origem integer,
    nome character varying(150),
    categoria character varying(100)
);


ALTER TABLE dw.dim_fornecedor OWNER TO postgres;

--
-- TOC entry 532 (class 1259 OID 27246)
-- Name: dim_fornecedor_id_fornecedor_dw_seq; Type: SEQUENCE; Schema: dw; Owner: postgres
--

CREATE SEQUENCE dw.dim_fornecedor_id_fornecedor_dw_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dw.dim_fornecedor_id_fornecedor_dw_seq OWNER TO postgres;

--
-- TOC entry 8108 (class 0 OID 0)
-- Dependencies: 532
-- Name: dim_fornecedor_id_fornecedor_dw_seq; Type: SEQUENCE OWNED BY; Schema: dw; Owner: postgres
--

ALTER SEQUENCE dw.dim_fornecedor_id_fornecedor_dw_seq OWNED BY dw.dim_fornecedor.id_fornecedor_dw;


--
-- TOC entry 535 (class 1259 OID 27255)
-- Name: dim_plano_conta; Type: TABLE; Schema: dw; Owner: postgres
--

CREATE TABLE dw.dim_plano_conta (
    id_conta_dw integer NOT NULL,
    id_conta_origem integer,
    grupo character varying(100),
    categoria character varying(100),
    subcategoria character varying(100)
);


ALTER TABLE dw.dim_plano_conta OWNER TO postgres;

--
-- TOC entry 534 (class 1259 OID 27254)
-- Name: dim_plano_conta_id_conta_dw_seq; Type: SEQUENCE; Schema: dw; Owner: postgres
--

CREATE SEQUENCE dw.dim_plano_conta_id_conta_dw_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dw.dim_plano_conta_id_conta_dw_seq OWNER TO postgres;

--
-- TOC entry 8109 (class 0 OID 0)
-- Dependencies: 534
-- Name: dim_plano_conta_id_conta_dw_seq; Type: SEQUENCE OWNED BY; Schema: dw; Owner: postgres
--

ALTER SEQUENCE dw.dim_plano_conta_id_conta_dw_seq OWNED BY dw.dim_plano_conta.id_conta_dw;


--
-- TOC entry 529 (class 1259 OID 27229)
-- Name: dim_produto_turistico; Type: TABLE; Schema: dw; Owner: postgres
--

CREATE TABLE dw.dim_produto_turistico (
    id_produto_dw integer NOT NULL,
    id_produto_origem integer,
    nome character varying(200),
    categoria character varying(100),
    tipo character varying(50),
    ativo boolean
);


ALTER TABLE dw.dim_produto_turistico OWNER TO postgres;

--
-- TOC entry 528 (class 1259 OID 27228)
-- Name: dim_produto_turistico_id_produto_dw_seq; Type: SEQUENCE; Schema: dw; Owner: postgres
--

CREATE SEQUENCE dw.dim_produto_turistico_id_produto_dw_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dw.dim_produto_turistico_id_produto_dw_seq OWNER TO postgres;

--
-- TOC entry 8110 (class 0 OID 0)
-- Dependencies: 528
-- Name: dim_produto_turistico_id_produto_dw_seq; Type: SEQUENCE OWNED BY; Schema: dw; Owner: postgres
--

ALTER SEQUENCE dw.dim_produto_turistico_id_produto_dw_seq OWNED BY dw.dim_produto_turistico.id_produto_dw;


--
-- TOC entry 525 (class 1259 OID 27210)
-- Name: dim_tempo; Type: TABLE; Schema: dw; Owner: postgres
--

CREATE TABLE dw.dim_tempo (
    id_tempo integer NOT NULL,
    data date NOT NULL,
    ano integer,
    mes integer,
    nome_mes character varying(20),
    trimestre integer,
    semestre integer,
    dia integer,
    dia_semana integer,
    nome_dia character varying(20)
);


ALTER TABLE dw.dim_tempo OWNER TO postgres;

--
-- TOC entry 524 (class 1259 OID 27209)
-- Name: dim_tempo_id_tempo_seq; Type: SEQUENCE; Schema: dw; Owner: postgres
--

CREATE SEQUENCE dw.dim_tempo_id_tempo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dw.dim_tempo_id_tempo_seq OWNER TO postgres;

--
-- TOC entry 8111 (class 0 OID 0)
-- Dependencies: 524
-- Name: dim_tempo_id_tempo_seq; Type: SEQUENCE OWNED BY; Schema: dw; Owner: postgres
--

ALTER SEQUENCE dw.dim_tempo_id_tempo_seq OWNED BY dw.dim_tempo.id_tempo;


--
-- TOC entry 539 (class 1259 OID 27272)
-- Name: fato_financeiro; Type: TABLE; Schema: dw; Owner: postgres
--

CREATE TABLE dw.fato_financeiro (
    id_financeiro_dw integer NOT NULL,
    id_tempo integer,
    id_conta integer,
    tipo_movimento character varying(30),
    valor numeric(15,2)
);


ALTER TABLE dw.fato_financeiro OWNER TO postgres;

--
-- TOC entry 538 (class 1259 OID 27271)
-- Name: fato_financeiro_id_financeiro_dw_seq; Type: SEQUENCE; Schema: dw; Owner: postgres
--

CREATE SEQUENCE dw.fato_financeiro_id_financeiro_dw_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dw.fato_financeiro_id_financeiro_dw_seq OWNER TO postgres;

--
-- TOC entry 8112 (class 0 OID 0)
-- Dependencies: 538
-- Name: fato_financeiro_id_financeiro_dw_seq; Type: SEQUENCE OWNED BY; Schema: dw; Owner: postgres
--

ALTER SEQUENCE dw.fato_financeiro_id_financeiro_dw_seq OWNED BY dw.fato_financeiro.id_financeiro_dw;


--
-- TOC entry 541 (class 1259 OID 27280)
-- Name: fato_marketing; Type: TABLE; Schema: dw; Owner: postgres
--

CREATE TABLE dw.fato_marketing (
    id_marketing_dw integer NOT NULL,
    id_tempo integer,
    canal character varying(100),
    investimento numeric(15,2),
    leads integer,
    vendas integer,
    receita numeric(15,2)
);


ALTER TABLE dw.fato_marketing OWNER TO postgres;

--
-- TOC entry 540 (class 1259 OID 27279)
-- Name: fato_marketing_id_marketing_dw_seq; Type: SEQUENCE; Schema: dw; Owner: postgres
--

CREATE SEQUENCE dw.fato_marketing_id_marketing_dw_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dw.fato_marketing_id_marketing_dw_seq OWNER TO postgres;

--
-- TOC entry 8113 (class 0 OID 0)
-- Dependencies: 540
-- Name: fato_marketing_id_marketing_dw_seq; Type: SEQUENCE OWNED BY; Schema: dw; Owner: postgres
--

ALTER SEQUENCE dw.fato_marketing_id_marketing_dw_seq OWNED BY dw.fato_marketing.id_marketing_dw;


--
-- TOC entry 537 (class 1259 OID 27264)
-- Name: fato_vendas; Type: TABLE; Schema: dw; Owner: postgres
--

CREATE TABLE dw.fato_vendas (
    id_venda_dw integer NOT NULL,
    id_tempo integer,
    id_cliente integer,
    id_produto integer,
    id_destino integer,
    quantidade integer,
    valor_venda numeric(15,2),
    valor_custo numeric(15,2),
    margem numeric(15,2)
);


ALTER TABLE dw.fato_vendas OWNER TO postgres;

--
-- TOC entry 536 (class 1259 OID 27263)
-- Name: fato_vendas_id_venda_dw_seq; Type: SEQUENCE; Schema: dw; Owner: postgres
--

CREATE SEQUENCE dw.fato_vendas_id_venda_dw_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dw.fato_vendas_id_venda_dw_seq OWNER TO postgres;

--
-- TOC entry 8114 (class 0 OID 0)
-- Dependencies: 536
-- Name: fato_vendas_id_venda_dw_seq; Type: SEQUENCE OWNED BY; Schema: dw; Owner: postgres
--

ALTER SEQUENCE dw.fato_vendas_id_venda_dw_seq OWNED BY dw.fato_vendas.id_venda_dw;


--
-- TOC entry 543 (class 1259 OID 27288)
-- Name: log_etl; Type: TABLE; Schema: dw; Owner: postgres
--

CREATE TABLE dw.log_etl (
    id_execucao integer NOT NULL,
    processo character varying(100),
    inicio timestamp without time zone,
    fim timestamp without time zone,
    registros_processados integer,
    status character varying(30),
    mensagem text
);


ALTER TABLE dw.log_etl OWNER TO postgres;

--
-- TOC entry 542 (class 1259 OID 27287)
-- Name: log_etl_id_execucao_seq; Type: SEQUENCE; Schema: dw; Owner: postgres
--

CREATE SEQUENCE dw.log_etl_id_execucao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE dw.log_etl_id_execucao_seq OWNER TO postgres;

--
-- TOC entry 8115 (class 0 OID 0)
-- Dependencies: 542
-- Name: log_etl_id_execucao_seq; Type: SEQUENCE OWNED BY; Schema: dw; Owner: postgres
--

ALTER SEQUENCE dw.log_etl_id_execucao_seq OWNED BY dw.log_etl.id_execucao;


--
-- TOC entry 544 (class 1259 OID 27298)
-- Name: vw_faturamento_mensal; Type: VIEW; Schema: dw; Owner: postgres
--

CREATE VIEW dw.vw_faturamento_mensal AS
 SELECT t.ano,
    t.mes,
    sum(v.valor_venda) AS faturamento
   FROM (dw.fato_vendas v
     JOIN dw.dim_tempo t ON ((t.id_tempo = v.id_tempo)))
  GROUP BY t.ano, t.mes;


ALTER VIEW dw.vw_faturamento_mensal OWNER TO postgres;

--
-- TOC entry 8116 (class 0 OID 0)
-- Dependencies: 544
-- Name: VIEW vw_faturamento_mensal; Type: COMMENT; Schema: dw; Owner: postgres
--

COMMENT ON VIEW dw.vw_faturamento_mensal IS 'Apresenta informações consolidadas de faturamento mensal destinadas à análise gerencial e inteligência de negócios.';


--
-- TOC entry 289 (class 1259 OID 25024)
-- Name: anexo; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.anexo (
    id_anexo bigint NOT NULL,
    id_lancamento bigint NOT NULL,
    nome_original character varying(255),
    nome_servidor character varying(255),
    extensao character varying(20),
    tamanho bigint,
    mime_type character varying(100),
    caminho text,
    data_upload timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1,
    CONSTRAINT chk_anexo_tamanho CHECK ((tamanho >= 0))
);


ALTER TABLE financeiro.anexo OWNER TO postgres;

--
-- TOC entry 288 (class 1259 OID 25023)
-- Name: anexo_id_anexo_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.anexo_id_anexo_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.anexo_id_anexo_seq OWNER TO postgres;

--
-- TOC entry 8117 (class 0 OID 0)
-- Dependencies: 288
-- Name: anexo_id_anexo_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.anexo_id_anexo_seq OWNED BY financeiro.anexo.id_anexo;


--
-- TOC entry 255 (class 1259 OID 24739)
-- Name: banco; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.banco (
    id_banco integer NOT NULL,
    codigo_banco character varying(10),
    nome character varying(120) NOT NULL,
    ativo boolean DEFAULT true
);


ALTER TABLE financeiro.banco OWNER TO postgres;

--
-- TOC entry 254 (class 1259 OID 24738)
-- Name: banco_id_banco_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.banco_id_banco_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.banco_id_banco_seq OWNER TO postgres;

--
-- TOC entry 8118 (class 0 OID 0)
-- Dependencies: 254
-- Name: banco_id_banco_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.banco_id_banco_seq OWNED BY financeiro.banco.id_banco;


--
-- TOC entry 245 (class 1259 OID 24674)
-- Name: categoria; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.categoria (
    id_categoria integer NOT NULL,
    id_grupo integer NOT NULL,
    codigo character varying(20) NOT NULL,
    descricao character varying(120) NOT NULL,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE financeiro.categoria OWNER TO postgres;

--
-- TOC entry 244 (class 1259 OID 24673)
-- Name: categoria_id_categoria_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.categoria_id_categoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.categoria_id_categoria_seq OWNER TO postgres;

--
-- TOC entry 8119 (class 0 OID 0)
-- Dependencies: 244
-- Name: categoria_id_categoria_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.categoria_id_categoria_seq OWNED BY financeiro.categoria.id_categoria;


--
-- TOC entry 253 (class 1259 OID 24727)
-- Name: centro_custo; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.centro_custo (
    id_centro_custo integer NOT NULL,
    codigo character varying(20),
    descricao character varying(150) NOT NULL,
    ativo boolean DEFAULT true
);


ALTER TABLE financeiro.centro_custo OWNER TO postgres;

--
-- TOC entry 252 (class 1259 OID 24726)
-- Name: centro_custo_id_centro_custo_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.centro_custo_id_centro_custo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.centro_custo_id_centro_custo_seq OWNER TO postgres;

--
-- TOC entry 8120 (class 0 OID 0)
-- Dependencies: 252
-- Name: centro_custo_id_centro_custo_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.centro_custo_id_centro_custo_seq OWNED BY financeiro.centro_custo.id_centro_custo;


--
-- TOC entry 249 (class 1259 OID 24698)
-- Name: classificacao; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.classificacao (
    id_classificacao integer NOT NULL,
    id_subcategoria integer NOT NULL,
    codigo character varying(20) NOT NULL,
    descricao character varying(180) NOT NULL,
    ativo boolean DEFAULT true,
    id_natureza_financeira integer,
    id_tipo_dre integer,
    ordem_dre smallint DEFAULT 0,
    gera_fluxo_caixa boolean DEFAULT true,
    gera_dre boolean DEFAULT true,
    aceita_cliente boolean DEFAULT false,
    aceita_fornecedor boolean DEFAULT false,
    aceita_centro_custo boolean DEFAULT true,
    aceita_conta_bancaria boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_at timestamp without time zone,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE financeiro.classificacao OWNER TO postgres;

--
-- TOC entry 8121 (class 0 OID 0)
-- Dependencies: 249
-- Name: TABLE classificacao; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TABLE financeiro.classificacao IS 'Tabela de Classificações Financeiras do Plano de Contas';


--
-- TOC entry 8122 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.id_natureza_financeira; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.id_natureza_financeira IS 'FK para Natureza Financeira';


--
-- TOC entry 8123 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.id_tipo_dre; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.id_tipo_dre IS 'FK para Tipo DRE';


--
-- TOC entry 8124 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.ordem_dre; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.ordem_dre IS 'Ordem de exibição na DRE';


--
-- TOC entry 8125 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.gera_fluxo_caixa; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.gera_fluxo_caixa IS 'Indica se participa do Fluxo de Caixa';


--
-- TOC entry 8126 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.gera_dre; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.gera_dre IS 'Indica se participa da DRE';


--
-- TOC entry 8127 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.aceita_cliente; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.aceita_cliente IS 'Permite vínculo com Cliente';


--
-- TOC entry 8128 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.aceita_fornecedor; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.aceita_fornecedor IS 'Permite vínculo com Fornecedor';


--
-- TOC entry 8129 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.aceita_centro_custo; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.aceita_centro_custo IS 'Permite Centro de Custo';


--
-- TOC entry 8130 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.aceita_conta_bancaria; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.aceita_conta_bancaria IS 'Permite Conta Bancária';


--
-- TOC entry 8131 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.created_at; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.created_at IS 'Data de criação';


--
-- TOC entry 8132 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.updated_at; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.updated_at IS 'Data da última alteração';


--
-- TOC entry 8133 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.created_by; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.created_by IS 'Usuário criador';


--
-- TOC entry 8134 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.updated_by; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.updated_by IS 'Usuário que alterou';


--
-- TOC entry 8135 (class 0 OID 0)
-- Dependencies: 249
-- Name: COLUMN classificacao.deleted_at; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON COLUMN financeiro.classificacao.deleted_at IS 'Soft Delete';


--
-- TOC entry 248 (class 1259 OID 24697)
-- Name: classificacao_id_classificacao_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.classificacao_id_classificacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.classificacao_id_classificacao_seq OWNER TO postgres;

--
-- TOC entry 8136 (class 0 OID 0)
-- Dependencies: 248
-- Name: classificacao_id_classificacao_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.classificacao_id_classificacao_seq OWNED BY financeiro.classificacao.id_classificacao;


--
-- TOC entry 259 (class 1259 OID 24760)
-- Name: cliente; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.cliente (
    id_cliente integer NOT NULL,
    nome character varying(150) NOT NULL,
    cpf_cnpj character varying(20),
    telefone character varying(30),
    email character varying(120),
    cidade character varying(80),
    uf character(2),
    ativo boolean DEFAULT true,
    id_pessoa integer NOT NULL
);


ALTER TABLE financeiro.cliente OWNER TO postgres;

--
-- TOC entry 258 (class 1259 OID 24759)
-- Name: cliente_id_cliente_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.cliente_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.cliente_id_cliente_seq OWNER TO postgres;

--
-- TOC entry 8137 (class 0 OID 0)
-- Dependencies: 258
-- Name: cliente_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.cliente_id_cliente_seq OWNED BY financeiro.cliente.id_cliente;


--
-- TOC entry 283 (class 1259 OID 24990)
-- Name: conciliacao_bancaria; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.conciliacao_bancaria (
    id_conciliacao bigint NOT NULL,
    id_movimento bigint NOT NULL,
    data_conciliacao date,
    conciliado boolean DEFAULT false,
    observacao text
);


ALTER TABLE financeiro.conciliacao_bancaria OWNER TO postgres;

--
-- TOC entry 282 (class 1259 OID 24989)
-- Name: conciliacao_bancaria_id_conciliacao_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.conciliacao_bancaria_id_conciliacao_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.conciliacao_bancaria_id_conciliacao_seq OWNER TO postgres;

--
-- TOC entry 8138 (class 0 OID 0)
-- Dependencies: 282
-- Name: conciliacao_bancaria_id_conciliacao_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.conciliacao_bancaria_id_conciliacao_seq OWNED BY financeiro.conciliacao_bancaria.id_conciliacao;


--
-- TOC entry 265 (class 1259 OID 24790)
-- Name: configuracao; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.configuracao (
    id_configuracao integer NOT NULL,
    empresa_padrao integer,
    moeda character varying(10) DEFAULT 'BRL'::character varying,
    idioma character varying(10) DEFAULT 'pt-BR'::character varying,
    tema character varying(20) DEFAULT 'Claro'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE financeiro.configuracao OWNER TO postgres;

--
-- TOC entry 264 (class 1259 OID 24789)
-- Name: configuracao_id_configuracao_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.configuracao_id_configuracao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.configuracao_id_configuracao_seq OWNER TO postgres;

--
-- TOC entry 8139 (class 0 OID 0)
-- Dependencies: 264
-- Name: configuracao_id_configuracao_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.configuracao_id_configuracao_seq OWNED BY financeiro.configuracao.id_configuracao;


--
-- TOC entry 251 (class 1259 OID 24712)
-- Name: conta; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.conta (
    id_conta integer NOT NULL,
    id_classificacao integer NOT NULL,
    codigo character varying(20) NOT NULL,
    descricao character varying(180) NOT NULL,
    aceita_lancamento boolean DEFAULT true,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE financeiro.conta OWNER TO postgres;

--
-- TOC entry 257 (class 1259 OID 24749)
-- Name: conta_bancaria; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.conta_bancaria (
    id_conta_bancaria integer NOT NULL,
    id_banco integer NOT NULL,
    agencia character varying(20),
    conta character varying(30),
    digito character varying(5),
    tipo character varying(20),
    pix character varying(150),
    saldo_inicial numeric(15,2) DEFAULT 0,
    ativo boolean DEFAULT true,
    CONSTRAINT chk_saldo CHECK ((saldo_inicial >= (0)::numeric))
);


ALTER TABLE financeiro.conta_bancaria OWNER TO postgres;

--
-- TOC entry 256 (class 1259 OID 24748)
-- Name: conta_bancaria_id_conta_bancaria_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.conta_bancaria_id_conta_bancaria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.conta_bancaria_id_conta_bancaria_seq OWNER TO postgres;

--
-- TOC entry 8140 (class 0 OID 0)
-- Dependencies: 256
-- Name: conta_bancaria_id_conta_bancaria_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.conta_bancaria_id_conta_bancaria_seq OWNED BY financeiro.conta_bancaria.id_conta_bancaria;


--
-- TOC entry 250 (class 1259 OID 24711)
-- Name: conta_id_conta_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.conta_id_conta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.conta_id_conta_seq OWNER TO postgres;

--
-- TOC entry 8141 (class 0 OID 0)
-- Dependencies: 250
-- Name: conta_id_conta_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.conta_id_conta_seq OWNED BY financeiro.conta.id_conta;


--
-- TOC entry 239 (class 1259 OID 24628)
-- Name: empresa; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.empresa (
    id_empresa integer NOT NULL,
    razao_social character varying(150) NOT NULL,
    nome_fantasia character varying(150),
    cnpj character(14),
    inscricao_estadual character varying(30),
    inscricao_municipal character varying(30),
    telefone character varying(20),
    email character varying(150),
    site character varying(150),
    cep character varying(10),
    endereco character varying(150),
    numero character varying(20),
    complemento character varying(100),
    bairro character varying(80),
    cidade character varying(80),
    uf character(2),
    ativo boolean DEFAULT true,
    data_cadastro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    data_alteracao timestamp without time zone,
    id_localidade integer
);


ALTER TABLE financeiro.empresa OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 24627)
-- Name: empresa_id_empresa_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.empresa_id_empresa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.empresa_id_empresa_seq OWNER TO postgres;

--
-- TOC entry 8142 (class 0 OID 0)
-- Dependencies: 238
-- Name: empresa_id_empresa_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.empresa_id_empresa_seq OWNED BY financeiro.empresa.id_empresa;


--
-- TOC entry 263 (class 1259 OID 24780)
-- Name: forma_pagamento; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.forma_pagamento (
    id_forma_pagamento integer NOT NULL,
    descricao character varying(80) NOT NULL,
    ativo boolean DEFAULT true
);


ALTER TABLE financeiro.forma_pagamento OWNER TO postgres;

--
-- TOC entry 262 (class 1259 OID 24779)
-- Name: forma_pagamento_id_forma_pagamento_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.forma_pagamento_id_forma_pagamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.forma_pagamento_id_forma_pagamento_seq OWNER TO postgres;

--
-- TOC entry 8143 (class 0 OID 0)
-- Dependencies: 262
-- Name: forma_pagamento_id_forma_pagamento_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.forma_pagamento_id_forma_pagamento_seq OWNED BY financeiro.forma_pagamento.id_forma_pagamento;


--
-- TOC entry 261 (class 1259 OID 24770)
-- Name: fornecedor; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.fornecedor (
    id_fornecedor integer NOT NULL,
    nome character varying(150) NOT NULL,
    cpf_cnpj character varying(20),
    telefone character varying(30),
    email character varying(120),
    cidade character varying(80),
    uf character(2),
    ativo boolean DEFAULT true
);


ALTER TABLE financeiro.fornecedor OWNER TO postgres;

--
-- TOC entry 260 (class 1259 OID 24769)
-- Name: fornecedor_id_fornecedor_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.fornecedor_id_fornecedor_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.fornecedor_id_fornecedor_seq OWNER TO postgres;

--
-- TOC entry 8144 (class 0 OID 0)
-- Dependencies: 260
-- Name: fornecedor_id_fornecedor_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.fornecedor_id_fornecedor_seq OWNED BY financeiro.fornecedor.id_fornecedor;


--
-- TOC entry 243 (class 1259 OID 24660)
-- Name: grupo; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.grupo (
    id_grupo integer NOT NULL,
    codigo character varying(10) NOT NULL,
    descricao character varying(120) NOT NULL,
    natureza character(1) NOT NULL,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE financeiro.grupo OWNER TO postgres;

--
-- TOC entry 242 (class 1259 OID 24659)
-- Name: grupo_id_grupo_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.grupo_id_grupo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.grupo_id_grupo_seq OWNER TO postgres;

--
-- TOC entry 8145 (class 0 OID 0)
-- Dependencies: 242
-- Name: grupo_id_grupo_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.grupo_id_grupo_seq OWNED BY financeiro.grupo.id_grupo;


--
-- TOC entry 287 (class 1259 OID 25012)
-- Name: historico_lancamento; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.historico_lancamento (
    id_historico bigint NOT NULL,
    id_lancamento bigint NOT NULL,
    id_usuario integer,
    operacao character varying(40),
    antes jsonb,
    depois jsonb,
    data_hora timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE financeiro.historico_lancamento OWNER TO postgres;

--
-- TOC entry 286 (class 1259 OID 25011)
-- Name: historico_lancamento_id_historico_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.historico_lancamento_id_historico_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.historico_lancamento_id_historico_seq OWNER TO postgres;

--
-- TOC entry 8146 (class 0 OID 0)
-- Dependencies: 286
-- Name: historico_lancamento_id_historico_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.historico_lancamento_id_historico_seq OWNED BY financeiro.historico_lancamento.id_historico;


--
-- TOC entry 275 (class 1259 OID 24914)
-- Name: lancamento; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.lancamento (
    id_lancamento bigint NOT NULL,
    numero character varying(30) NOT NULL,
    id_empresa integer NOT NULL,
    id_tipo_lancamento smallint NOT NULL,
    id_status smallint NOT NULL,
    id_conta integer NOT NULL,
    id_cliente integer,
    id_fornecedor integer,
    id_conta_bancaria integer,
    id_forma_pagamento integer,
    id_tipo_documento smallint,
    competencia date NOT NULL,
    emissao date NOT NULL,
    vencimento date NOT NULL,
    pagamento date,
    documento character varying(100),
    descricao character varying(300),
    observacao text,
    valor_bruto numeric(15,2) NOT NULL,
    desconto numeric(15,2) DEFAULT 0,
    acrescimo numeric(15,2) DEFAULT 0,
    juros numeric(15,2) DEFAULT 0,
    multa numeric(15,2) DEFAULT 0,
    valor_liquido numeric(15,2) GENERATED ALWAYS AS (((((valor_bruto - desconto) + acrescimo) + juros) + multa)) STORED,
    valor_pago numeric(15,2) DEFAULT 0,
    saldo numeric(15,2) GENERATED ALWAYS AS ((((((valor_bruto - desconto) + acrescimo) + juros) + multa) - valor_pago)) STORED,
    ativo boolean DEFAULT true,
    data_cadastro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    data_alteracao timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1,
    CONSTRAINT chk_lancamento_acrescimo CHECK ((acrescimo >= (0)::numeric)),
    CONSTRAINT chk_lancamento_datas CHECK ((competencia >= emissao)),
    CONSTRAINT chk_lancamento_desconto CHECK ((desconto >= (0)::numeric)),
    CONSTRAINT chk_lancamento_juros CHECK ((juros >= (0)::numeric)),
    CONSTRAINT chk_lancamento_multa CHECK ((multa >= (0)::numeric)),
    CONSTRAINT chk_lancamento_pagamento CHECK (((pagamento IS NULL) OR (pagamento >= emissao))),
    CONSTRAINT chk_lancamento_valor_bruto CHECK ((valor_bruto > (0)::numeric)),
    CONSTRAINT chk_lancamento_valor_pago CHECK ((valor_pago >= (0)::numeric)),
    CONSTRAINT chk_numero_lancamento CHECK ((TRIM(BOTH FROM numero) <> ''::text))
);


ALTER TABLE financeiro.lancamento OWNER TO postgres;

--
-- TOC entry 8147 (class 0 OID 0)
-- Dependencies: 275
-- Name: CONSTRAINT chk_lancamento_valor_bruto ON lancamento; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON CONSTRAINT chk_lancamento_valor_bruto ON financeiro.lancamento IS 'Valor bruto deve ser maior que zero.';


--
-- TOC entry 274 (class 1259 OID 24913)
-- Name: lancamento_id_lancamento_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.lancamento_id_lancamento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.lancamento_id_lancamento_seq OWNER TO postgres;

--
-- TOC entry 8148 (class 0 OID 0)
-- Dependencies: 274
-- Name: lancamento_id_lancamento_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.lancamento_id_lancamento_seq OWNED BY financeiro.lancamento.id_lancamento;


--
-- TOC entry 277 (class 1259 OID 24944)
-- Name: lancamento_parcela; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.lancamento_parcela (
    id_parcela bigint NOT NULL,
    id_lancamento bigint NOT NULL,
    numero_parcela integer NOT NULL,
    vencimento date NOT NULL,
    valor numeric(15,2) NOT NULL,
    valor_pago numeric(15,2) DEFAULT 0,
    saldo numeric(15,2),
    id_status smallint,
    observacao text,
    CONSTRAINT chk_parcela_numero CHECK ((numero_parcela > 0)),
    CONSTRAINT chk_parcela_saldo CHECK ((saldo >= (0)::numeric)),
    CONSTRAINT chk_parcela_valor CHECK ((valor > (0)::numeric)),
    CONSTRAINT chk_parcela_valor_pago CHECK ((valor_pago >= (0)::numeric))
);


ALTER TABLE financeiro.lancamento_parcela OWNER TO postgres;

--
-- TOC entry 276 (class 1259 OID 24943)
-- Name: lancamento_parcela_id_parcela_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.lancamento_parcela_id_parcela_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.lancamento_parcela_id_parcela_seq OWNER TO postgres;

--
-- TOC entry 8149 (class 0 OID 0)
-- Dependencies: 276
-- Name: lancamento_parcela_id_parcela_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.lancamento_parcela_id_parcela_seq OWNED BY financeiro.lancamento_parcela.id_parcela;


--
-- TOC entry 281 (class 1259 OID 24978)
-- Name: movimentacao_bancaria; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.movimentacao_bancaria (
    id_movimento bigint NOT NULL,
    id_conta_bancaria integer NOT NULL,
    id_pagamento bigint,
    id_tipo_movimentacao smallint NOT NULL,
    data_movimento date,
    valor numeric(15,2),
    saldo_anterior numeric(15,2),
    saldo_atual numeric(15,2),
    historico text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1,
    CONSTRAINT chk_movimentacao_valor CHECK ((valor > (0)::numeric))
);


ALTER TABLE financeiro.movimentacao_bancaria OWNER TO postgres;

--
-- TOC entry 280 (class 1259 OID 24977)
-- Name: movimentacao_bancaria_id_movimento_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.movimentacao_bancaria_id_movimento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.movimentacao_bancaria_id_movimento_seq OWNER TO postgres;

--
-- TOC entry 8150 (class 0 OID 0)
-- Dependencies: 280
-- Name: movimentacao_bancaria_id_movimento_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.movimentacao_bancaria_id_movimento_seq OWNED BY financeiro.movimentacao_bancaria.id_movimento;


--
-- TOC entry 279 (class 1259 OID 24959)
-- Name: pagamento; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.pagamento (
    id_pagamento bigint NOT NULL,
    id_parcela bigint NOT NULL,
    id_conta_bancaria integer NOT NULL,
    id_forma_pagamento integer NOT NULL,
    data_pagamento date NOT NULL,
    valor numeric(15,2) NOT NULL,
    juros numeric(15,2) DEFAULT 0,
    desconto numeric(15,2) DEFAULT 0,
    multa numeric(15,2) DEFAULT 0,
    documento character varying(100),
    observacao text,
    data_cadastro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1,
    CONSTRAINT chk_documento CHECK (((documento IS NULL) OR (TRIM(BOTH FROM documento) <> ''::text))),
    CONSTRAINT chk_pagamento_desconto CHECK ((desconto >= (0)::numeric)),
    CONSTRAINT chk_pagamento_juros CHECK ((juros >= (0)::numeric)),
    CONSTRAINT chk_pagamento_multa CHECK ((multa >= (0)::numeric)),
    CONSTRAINT chk_pagamento_valor CHECK ((valor > (0)::numeric))
);


ALTER TABLE financeiro.pagamento OWNER TO postgres;

--
-- TOC entry 278 (class 1259 OID 24958)
-- Name: pagamento_id_pagamento_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.pagamento_id_pagamento_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.pagamento_id_pagamento_seq OWNER TO postgres;

--
-- TOC entry 8151 (class 0 OID 0)
-- Dependencies: 278
-- Name: pagamento_id_pagamento_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.pagamento_id_pagamento_seq OWNED BY financeiro.pagamento.id_pagamento;


--
-- TOC entry 285 (class 1259 OID 25002)
-- Name: rateio_centro_custo; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.rateio_centro_custo (
    id_rateio bigint NOT NULL,
    id_lancamento bigint NOT NULL,
    id_centro_custo integer NOT NULL,
    percentual numeric(6,2),
    valor numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1,
    CONSTRAINT chk_rateio_percentual CHECK (((percentual > (0)::numeric) AND (percentual <= (100)::numeric))),
    CONSTRAINT chk_rateio_valor CHECK ((valor >= (0)::numeric))
);


ALTER TABLE financeiro.rateio_centro_custo OWNER TO postgres;

--
-- TOC entry 8152 (class 0 OID 0)
-- Dependencies: 285
-- Name: CONSTRAINT chk_rateio_percentual ON rateio_centro_custo; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON CONSTRAINT chk_rateio_percentual ON financeiro.rateio_centro_custo IS 'Percentual deve estar entre 0 e 100.';


--
-- TOC entry 284 (class 1259 OID 25001)
-- Name: rateio_centro_custo_id_rateio_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.rateio_centro_custo_id_rateio_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.rateio_centro_custo_id_rateio_seq OWNER TO postgres;

--
-- TOC entry 8153 (class 0 OID 0)
-- Dependencies: 284
-- Name: rateio_centro_custo_id_rateio_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.rateio_centro_custo_id_rateio_seq OWNED BY financeiro.rateio_centro_custo.id_rateio;


--
-- TOC entry 269 (class 1259 OID 24881)
-- Name: status_lancamento; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.status_lancamento (
    id_status smallint NOT NULL,
    codigo character varying(20),
    descricao character varying(80),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE financeiro.status_lancamento OWNER TO postgres;

--
-- TOC entry 268 (class 1259 OID 24880)
-- Name: status_lancamento_id_status_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.status_lancamento_id_status_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.status_lancamento_id_status_seq OWNER TO postgres;

--
-- TOC entry 8154 (class 0 OID 0)
-- Dependencies: 268
-- Name: status_lancamento_id_status_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.status_lancamento_id_status_seq OWNED BY financeiro.status_lancamento.id_status;


--
-- TOC entry 247 (class 1259 OID 24686)
-- Name: subcategoria; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.subcategoria (
    id_subcategoria integer NOT NULL,
    id_categoria integer NOT NULL,
    codigo character varying(30) NOT NULL,
    descricao character varying(150) NOT NULL,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1
);


ALTER TABLE financeiro.subcategoria OWNER TO postgres;

--
-- TOC entry 246 (class 1259 OID 24685)
-- Name: subcategoria_id_subcategoria_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.subcategoria_id_subcategoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.subcategoria_id_subcategoria_seq OWNER TO postgres;

--
-- TOC entry 8155 (class 0 OID 0)
-- Dependencies: 246
-- Name: subcategoria_id_subcategoria_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.subcategoria_id_subcategoria_seq OWNED BY financeiro.subcategoria.id_subcategoria;


--
-- TOC entry 271 (class 1259 OID 24892)
-- Name: tipo_documento; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.tipo_documento (
    id_tipo_documento smallint NOT NULL,
    codigo character varying(20),
    descricao character varying(80),
    ativo boolean DEFAULT true
);


ALTER TABLE financeiro.tipo_documento OWNER TO postgres;

--
-- TOC entry 270 (class 1259 OID 24891)
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.tipo_documento_id_tipo_documento_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.tipo_documento_id_tipo_documento_seq OWNER TO postgres;

--
-- TOC entry 8156 (class 0 OID 0)
-- Dependencies: 270
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.tipo_documento_id_tipo_documento_seq OWNED BY financeiro.tipo_documento.id_tipo_documento;


--
-- TOC entry 267 (class 1259 OID 24867)
-- Name: tipo_lancamento; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.tipo_lancamento (
    id_tipo_lancamento smallint NOT NULL,
    codigo character varying(10) NOT NULL,
    descricao character varying(80) NOT NULL,
    natureza character(1) NOT NULL,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1,
    CONSTRAINT chk_tipo_natureza CHECK ((natureza = ANY (ARRAY['R'::bpchar, 'D'::bpchar, 'T'::bpchar, 'A'::bpchar, 'I'::bpchar, 'P'::bpchar, 'L'::bpchar])))
);


ALTER TABLE financeiro.tipo_lancamento OWNER TO postgres;

--
-- TOC entry 8157 (class 0 OID 0)
-- Dependencies: 267
-- Name: CONSTRAINT chk_tipo_natureza ON tipo_lancamento; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON CONSTRAINT chk_tipo_natureza ON financeiro.tipo_lancamento IS 'Natureza permitida: R,D,T,A,I,P,L';


--
-- TOC entry 266 (class 1259 OID 24866)
-- Name: tipo_lancamento_id_tipo_lancamento_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.tipo_lancamento_id_tipo_lancamento_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.tipo_lancamento_id_tipo_lancamento_seq OWNER TO postgres;

--
-- TOC entry 8158 (class 0 OID 0)
-- Dependencies: 266
-- Name: tipo_lancamento_id_tipo_lancamento_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.tipo_lancamento_id_tipo_lancamento_seq OWNED BY financeiro.tipo_lancamento.id_tipo_lancamento;


--
-- TOC entry 273 (class 1259 OID 24903)
-- Name: tipo_movimentacao; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.tipo_movimentacao (
    id_tipo_movimentacao smallint NOT NULL,
    codigo character varying(20),
    descricao character varying(80),
    entrada_saida character(1),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by integer,
    updated_by integer,
    deleted_by integer,
    versao integer DEFAULT 1,
    CONSTRAINT chk_tipo_movimentacao CHECK ((entrada_saida = ANY (ARRAY['E'::bpchar, 'S'::bpchar])))
);


ALTER TABLE financeiro.tipo_movimentacao OWNER TO postgres;

--
-- TOC entry 272 (class 1259 OID 24902)
-- Name: tipo_movimentacao_id_tipo_movimentacao_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.tipo_movimentacao_id_tipo_movimentacao_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.tipo_movimentacao_id_tipo_movimentacao_seq OWNER TO postgres;

--
-- TOC entry 8159 (class 0 OID 0)
-- Dependencies: 272
-- Name: tipo_movimentacao_id_tipo_movimentacao_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.tipo_movimentacao_id_tipo_movimentacao_seq OWNED BY financeiro.tipo_movimentacao.id_tipo_movimentacao;


--
-- TOC entry 241 (class 1259 OID 24642)
-- Name: usuario; Type: TABLE; Schema: financeiro; Owner: postgres
--

CREATE TABLE financeiro.usuario (
    id_usuario integer NOT NULL,
    nome character varying(120) NOT NULL,
    email character varying(120) NOT NULL,
    senha_hash text NOT NULL,
    administrador boolean DEFAULT false,
    ativo boolean DEFAULT true,
    data_cadastro timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    ultimo_login timestamp without time zone
);


ALTER TABLE financeiro.usuario OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 24641)
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: financeiro; Owner: postgres
--

CREATE SEQUENCE financeiro.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE financeiro.usuario_id_usuario_seq OWNER TO postgres;

--
-- TOC entry 8160 (class 0 OID 0)
-- Dependencies: 240
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: financeiro; Owner: postgres
--

ALTER SEQUENCE financeiro.usuario_id_usuario_seq OWNED BY financeiro.usuario.id_usuario;


--
-- TOC entry 426 (class 1259 OID 26383)
-- Name: agenda; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agenda (
    id_agenda integer NOT NULL,
    id_colaborador integer,
    titulo character varying(150),
    descricao text,
    tipo_evento character varying(50),
    data_inicio timestamp without time zone,
    data_fim timestamp without time zone,
    status character varying(30) DEFAULT 'AGENDADO'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.agenda OWNER TO postgres;

--
-- TOC entry 425 (class 1259 OID 26382)
-- Name: agenda_id_agenda_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.agenda_id_agenda_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.agenda_id_agenda_seq OWNER TO postgres;

--
-- TOC entry 8161 (class 0 OID 0)
-- Dependencies: 425
-- Name: agenda_id_agenda_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.agenda_id_agenda_seq OWNED BY public.agenda.id_agenda;


--
-- TOC entry 507 (class 1259 OID 27076)
-- Name: agendamento_rotina; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.agendamento_rotina (
    id_rotina integer NOT NULL,
    codigo character varying(50),
    descricao character varying(150),
    expressao_cron character varying(100),
    ultima_execucao timestamp without time zone,
    proxima_execucao timestamp without time zone,
    status character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.agendamento_rotina OWNER TO postgres;

--
-- TOC entry 506 (class 1259 OID 27075)
-- Name: agendamento_rotina_id_rotina_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.agendamento_rotina_id_rotina_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.agendamento_rotina_id_rotina_seq OWNER TO postgres;

--
-- TOC entry 8162 (class 0 OID 0)
-- Dependencies: 506
-- Name: agendamento_rotina_id_rotina_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.agendamento_rotina_id_rotina_seq OWNED BY public.agendamento_rotina.id_rotina;


--
-- TOC entry 492 (class 1259 OID 26965)
-- Name: anexo_projeto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.anexo_projeto (
    id_anexo integer NOT NULL,
    id_projeto integer NOT NULL,
    nome_arquivo character varying(255),
    caminho text,
    tipo character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.anexo_projeto OWNER TO postgres;

--
-- TOC entry 491 (class 1259 OID 26964)
-- Name: anexo_projeto_id_anexo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.anexo_projeto_id_anexo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.anexo_projeto_id_anexo_seq OWNER TO postgres;

--
-- TOC entry 8163 (class 0 OID 0)
-- Dependencies: 491
-- Name: anexo_projeto_id_anexo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.anexo_projeto_id_anexo_seq OWNED BY public.anexo_projeto.id_anexo;


--
-- TOC entry 510 (class 1259 OID 27091)
-- Name: aplicacao_api; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.aplicacao_api (
    id_aplicacao integer NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    descricao text,
    tipo character varying(50),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.aplicacao_api OWNER TO postgres;

--
-- TOC entry 509 (class 1259 OID 27090)
-- Name: aplicacao_api_id_aplicacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.aplicacao_api_id_aplicacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.aplicacao_api_id_aplicacao_seq OWNER TO postgres;

--
-- TOC entry 8164 (class 0 OID 0)
-- Dependencies: 509
-- Name: aplicacao_api_id_aplicacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.aplicacao_api_id_aplicacao_seq OWNED BY public.aplicacao_api.id_aplicacao;


--
-- TOC entry 348 (class 1259 OID 25695)
-- Name: aporte_capital; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.aporte_capital (
    id_aporte integer NOT NULL,
    id_empresa integer NOT NULL,
    data_aporte date,
    valor numeric(15,2),
    tipo character varying(30),
    descricao character varying(200),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.aporte_capital OWNER TO postgres;

--
-- TOC entry 347 (class 1259 OID 25694)
-- Name: aporte_capital_id_aporte_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.aporte_capital_id_aporte_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.aporte_capital_id_aporte_seq OWNER TO postgres;

--
-- TOC entry 8165 (class 0 OID 0)
-- Dependencies: 347
-- Name: aporte_capital_id_aporte_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.aporte_capital_id_aporte_seq OWNED BY public.aporte_capital.id_aporte;


--
-- TOC entry 548 (class 1259 OID 27328)
-- Name: aprovacao_processo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.aprovacao_processo (
    id_aprovacao integer NOT NULL,
    tipo_processo character varying(100),
    registro_id integer,
    solicitante character varying(100),
    aprovador character varying(100),
    status character varying(30) DEFAULT 'PENDENTE'::character varying,
    data_solicitacao timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    data_aprovacao timestamp without time zone,
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.aprovacao_processo OWNER TO postgres;

--
-- TOC entry 547 (class 1259 OID 27327)
-- Name: aprovacao_processo_id_aprovacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.aprovacao_processo_id_aprovacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.aprovacao_processo_id_aprovacao_seq OWNER TO postgres;

--
-- TOC entry 8166 (class 0 OID 0)
-- Dependencies: 547
-- Name: aprovacao_processo_id_aprovacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.aprovacao_processo_id_aprovacao_seq OWNED BY public.aprovacao_processo.id_aprovacao;


--
-- TOC entry 469 (class 1259 OID 26769)
-- Name: arquivo_digital; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.arquivo_digital (
    id_arquivo integer NOT NULL,
    id_documento integer NOT NULL,
    nome_arquivo character varying(255),
    extensao character varying(10),
    caminho_arquivo text,
    tamanho_bytes bigint,
    hash_arquivo character varying(255),
    versao_arquivo integer DEFAULT 1,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.arquivo_digital OWNER TO postgres;

--
-- TOC entry 468 (class 1259 OID 26768)
-- Name: arquivo_digital_id_arquivo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.arquivo_digital_id_arquivo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.arquivo_digital_id_arquivo_seq OWNER TO postgres;

--
-- TOC entry 8167 (class 0 OID 0)
-- Dependencies: 468
-- Name: arquivo_digital_id_arquivo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.arquivo_digital_id_arquivo_seq OWNED BY public.arquivo_digital.id_arquivo;


--
-- TOC entry 473 (class 1259 OID 26803)
-- Name: assinatura_digital; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.assinatura_digital (
    id_assinatura integer NOT NULL,
    id_documento integer NOT NULL,
    assinante character varying(150),
    email character varying(150),
    data_solicitacao timestamp without time zone,
    data_assinatura timestamp without time zone,
    status character varying(30),
    codigo_externo character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.assinatura_digital OWNER TO postgres;

--
-- TOC entry 472 (class 1259 OID 26802)
-- Name: assinatura_digital_id_assinatura_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.assinatura_digital_id_assinatura_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.assinatura_digital_id_assinatura_seq OWNER TO postgres;

--
-- TOC entry 8168 (class 0 OID 0)
-- Dependencies: 472
-- Name: assinatura_digital_id_assinatura_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.assinatura_digital_id_assinatura_seq OWNED BY public.assinatura_digital.id_assinatura;


--
-- TOC entry 435 (class 1259 OID 26459)
-- Name: ativo_imobilizado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ativo_imobilizado (
    id_ativo integer NOT NULL,
    codigo_patrimonio character varying(30) NOT NULL,
    id_categoria_ativo integer NOT NULL,
    descricao character varying(200) NOT NULL,
    marca character varying(100),
    modelo character varying(100),
    numero_serie character varying(100),
    data_aquisicao date,
    valor_aquisicao numeric(15,2),
    valor_residual numeric(15,2) DEFAULT 0,
    status character varying(30) DEFAULT 'ATIVO'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.ativo_imobilizado OWNER TO postgres;

--
-- TOC entry 434 (class 1259 OID 26458)
-- Name: ativo_imobilizado_id_ativo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ativo_imobilizado_id_ativo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ativo_imobilizado_id_ativo_seq OWNER TO postgres;

--
-- TOC entry 8169 (class 0 OID 0)
-- Dependencies: 434
-- Name: ativo_imobilizado_id_ativo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ativo_imobilizado_id_ativo_seq OWNED BY public.ativo_imobilizado.id_ativo;


--
-- TOC entry 415 (class 1259 OID 26285)
-- Name: avaliacao_pos_viagem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.avaliacao_pos_viagem (
    id_avaliacao integer NOT NULL,
    id_reserva integer NOT NULL,
    nota integer,
    comentario text,
    recomendaria boolean,
    data_avaliacao date DEFAULT CURRENT_DATE,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_nota_avaliacao CHECK (((nota >= 1) AND (nota <= 5)))
);


ALTER TABLE public.avaliacao_pos_viagem OWNER TO postgres;

--
-- TOC entry 414 (class 1259 OID 26284)
-- Name: avaliacao_pos_viagem_id_avaliacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.avaliacao_pos_viagem_id_avaliacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.avaliacao_pos_viagem_id_avaliacao_seq OWNER TO postgres;

--
-- TOC entry 8170 (class 0 OID 0)
-- Dependencies: 414
-- Name: avaliacao_pos_viagem_id_avaliacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.avaliacao_pos_viagem_id_avaliacao_seq OWNED BY public.avaliacao_pos_viagem.id_avaliacao;


--
-- TOC entry 301 (class 1259 OID 25164)
-- Name: banco; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.banco (
    id_banco integer NOT NULL,
    codigo_banco character varying(10),
    nome_banco character varying(100) NOT NULL,
    agencia character varying(20),
    conta character varying(30),
    tipo_conta character varying(30),
    saldo_inicial numeric(15,2) DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.banco OWNER TO postgres;

--
-- TOC entry 300 (class 1259 OID 25163)
-- Name: banco_id_banco_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.banco_id_banco_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.banco_id_banco_seq OWNER TO postgres;

--
-- TOC entry 8171 (class 0 OID 0)
-- Dependencies: 300
-- Name: banco_id_banco_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.banco_id_banco_seq OWNED BY public.banco.id_banco;


--
-- TOC entry 407 (class 1259 OID 26218)
-- Name: campanha; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.campanha (
    id_campanha integer NOT NULL,
    codigo character varying(30),
    nome character varying(150),
    canal character varying(50),
    data_inicio date,
    data_fim date,
    orcamento numeric(15,2),
    investimento_real numeric(15,2),
    status character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.campanha OWNER TO postgres;

--
-- TOC entry 406 (class 1259 OID 26217)
-- Name: campanha_id_campanha_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.campanha_id_campanha_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.campanha_id_campanha_seq OWNER TO postgres;

--
-- TOC entry 8172 (class 0 OID 0)
-- Dependencies: 406
-- Name: campanha_id_campanha_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.campanha_id_campanha_seq OWNED BY public.campanha.id_campanha;


--
-- TOC entry 418 (class 1259 OID 26309)
-- Name: cargo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cargo (
    id_cargo integer NOT NULL,
    codigo character varying(30) NOT NULL,
    descricao character varying(100) NOT NULL,
    tipo character varying(50),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.cargo OWNER TO postgres;

--
-- TOC entry 417 (class 1259 OID 26308)
-- Name: cargo_id_cargo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cargo_id_cargo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cargo_id_cargo_seq OWNER TO postgres;

--
-- TOC entry 8173 (class 0 OID 0)
-- Dependencies: 417
-- Name: cargo_id_cargo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cargo_id_cargo_seq OWNED BY public.cargo.id_cargo;


--
-- TOC entry 433 (class 1259 OID 26443)
-- Name: categoria_ativo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categoria_ativo (
    id_categoria_ativo integer NOT NULL,
    codigo character varying(30) NOT NULL,
    descricao character varying(100) NOT NULL,
    vida_util_anos integer,
    taxa_depreciacao numeric(5,2),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.categoria_ativo OWNER TO postgres;

--
-- TOC entry 432 (class 1259 OID 26442)
-- Name: categoria_ativo_id_categoria_ativo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categoria_ativo_id_categoria_ativo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categoria_ativo_id_categoria_ativo_seq OWNER TO postgres;

--
-- TOC entry 8174 (class 0 OID 0)
-- Dependencies: 432
-- Name: categoria_ativo_id_categoria_ativo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categoria_ativo_id_categoria_ativo_seq OWNED BY public.categoria_ativo.id_categoria_ativo;


--
-- TOC entry 307 (class 1259 OID 25218)
-- Name: categoria_conta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.categoria_conta (
    id_categoria integer NOT NULL,
    id_grupo integer NOT NULL,
    codigo character varying(20) NOT NULL,
    descricao character varying(150) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.categoria_conta OWNER TO postgres;

--
-- TOC entry 306 (class 1259 OID 25217)
-- Name: categoria_conta_id_categoria_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.categoria_conta_id_categoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.categoria_conta_id_categoria_seq OWNER TO postgres;

--
-- TOC entry 8175 (class 0 OID 0)
-- Dependencies: 306
-- Name: categoria_conta_id_categoria_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.categoria_conta_id_categoria_seq OWNED BY public.categoria_conta.id_categoria;


--
-- TOC entry 311 (class 1259 OID 25259)
-- Name: centro_custo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.centro_custo (
    id_centro_custo integer NOT NULL,
    codigo character varying(20) NOT NULL,
    descricao character varying(100) NOT NULL,
    tipo character varying(50),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.centro_custo OWNER TO postgres;

--
-- TOC entry 310 (class 1259 OID 25258)
-- Name: centro_custo_id_centro_custo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.centro_custo_id_centro_custo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.centro_custo_id_centro_custo_seq OWNER TO postgres;

--
-- TOC entry 8176 (class 0 OID 0)
-- Dependencies: 310
-- Name: centro_custo_id_centro_custo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.centro_custo_id_centro_custo_seq OWNED BY public.centro_custo.id_centro_custo;


--
-- TOC entry 514 (class 1259 OID 27128)
-- Name: chave_api; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.chave_api (
    id_chave integer NOT NULL,
    id_aplicacao integer NOT NULL,
    nome_chave character varying(100),
    api_key_hash text NOT NULL,
    permissoes jsonb,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.chave_api OWNER TO postgres;

--
-- TOC entry 513 (class 1259 OID 27127)
-- Name: chave_api_id_chave_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.chave_api_id_chave_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.chave_api_id_chave_seq OWNER TO postgres;

--
-- TOC entry 8177 (class 0 OID 0)
-- Dependencies: 513
-- Name: chave_api_id_chave_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.chave_api_id_chave_seq OWNED BY public.chave_api.id_chave;


--
-- TOC entry 399 (class 1259 OID 26142)
-- Name: checklist_viagem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.checklist_viagem (
    id_checklist integer NOT NULL,
    id_pacote integer NOT NULL,
    item character varying(200),
    responsavel character varying(100),
    status character varying(30) DEFAULT 'PENDENTE'::character varying,
    data_execucao date,
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.checklist_viagem OWNER TO postgres;

--
-- TOC entry 398 (class 1259 OID 26141)
-- Name: checklist_viagem_id_checklist_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.checklist_viagem_id_checklist_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.checklist_viagem_id_checklist_seq OWNER TO postgres;

--
-- TOC entry 8178 (class 0 OID 0)
-- Dependencies: 398
-- Name: checklist_viagem_id_checklist_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.checklist_viagem_id_checklist_seq OWNED BY public.checklist_viagem.id_checklist;


--
-- TOC entry 313 (class 1259 OID 25274)
-- Name: classificacao_dre; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.classificacao_dre (
    id_classificacao integer NOT NULL,
    codigo character varying(20) NOT NULL,
    descricao character varying(150) NOT NULL,
    grupo_dre character varying(50) NOT NULL,
    ordem_exibicao integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.classificacao_dre OWNER TO postgres;

--
-- TOC entry 312 (class 1259 OID 25273)
-- Name: classificacao_dre_id_classificacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.classificacao_dre_id_classificacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.classificacao_dre_id_classificacao_seq OWNER TO postgres;

--
-- TOC entry 8179 (class 0 OID 0)
-- Dependencies: 312
-- Name: classificacao_dre_id_classificacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.classificacao_dre_id_classificacao_seq OWNED BY public.classificacao_dre.id_classificacao;


--
-- TOC entry 297 (class 1259 OID 25124)
-- Name: cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.cliente (
    id_cliente integer NOT NULL,
    id_pessoa integer NOT NULL,
    codigo_cliente character varying(20),
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.cliente OWNER TO postgres;

--
-- TOC entry 296 (class 1259 OID 25123)
-- Name: cliente_id_cliente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.cliente_id_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.cliente_id_cliente_seq OWNER TO postgres;

--
-- TOC entry 8180 (class 0 OID 0)
-- Dependencies: 296
-- Name: cliente_id_cliente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.cliente_id_cliente_seq OWNED BY public.cliente.id_cliente;


--
-- TOC entry 420 (class 1259 OID 26325)
-- Name: colaborador; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.colaborador (
    id_colaborador integer NOT NULL,
    id_pessoa integer NOT NULL,
    id_cargo integer,
    data_admissao date,
    tipo_vinculo character varying(50),
    valor_base numeric(15,2),
    status character varying(30) DEFAULT 'ATIVO'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.colaborador OWNER TO postgres;

--
-- TOC entry 419 (class 1259 OID 26324)
-- Name: colaborador_id_colaborador_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.colaborador_id_colaborador_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.colaborador_id_colaborador_seq OWNER TO postgres;

--
-- TOC entry 8181 (class 0 OID 0)
-- Dependencies: 419
-- Name: colaborador_id_colaborador_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.colaborador_id_colaborador_seq OWNED BY public.colaborador.id_colaborador;


--
-- TOC entry 334 (class 1259 OID 25518)
-- Name: comissao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comissao (
    id_comissao integer NOT NULL,
    id_reserva integer NOT NULL,
    id_fornecedor integer,
    percentual numeric(5,2),
    valor_comissao numeric(15,2),
    status character varying(30) DEFAULT 'PENDENTE'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.comissao OWNER TO postgres;

--
-- TOC entry 424 (class 1259 OID 26361)
-- Name: comissao_colaborador; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.comissao_colaborador (
    id_comissao integer NOT NULL,
    id_colaborador integer,
    id_venda integer NOT NULL,
    percentual numeric(5,2),
    valor numeric(15,2),
    status character varying(30) DEFAULT 'PENDENTE'::character varying,
    data_pagamento date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.comissao_colaborador OWNER TO postgres;

--
-- TOC entry 423 (class 1259 OID 26360)
-- Name: comissao_colaborador_id_comissao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comissao_colaborador_id_comissao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.comissao_colaborador_id_comissao_seq OWNER TO postgres;

--
-- TOC entry 8182 (class 0 OID 0)
-- Dependencies: 423
-- Name: comissao_colaborador_id_comissao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comissao_colaborador_id_comissao_seq OWNED BY public.comissao_colaborador.id_comissao;


--
-- TOC entry 333 (class 1259 OID 25517)
-- Name: comissao_id_comissao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.comissao_id_comissao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.comissao_id_comissao_seq OWNER TO postgres;

--
-- TOC entry 8183 (class 0 OID 0)
-- Dependencies: 333
-- Name: comissao_id_comissao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.comissao_id_comissao_seq OWNED BY public.comissao.id_comissao;


--
-- TOC entry 324 (class 1259 OID 25401)
-- Name: conciliacao_bancaria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conciliacao_bancaria (
    id_conciliacao integer NOT NULL,
    id_conta_bancaria integer NOT NULL,
    data_movimento date NOT NULL,
    descricao_banco character varying(200),
    valor numeric(15,2),
    conciliado boolean DEFAULT false,
    id_lancamento integer,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.conciliacao_bancaria OWNER TO postgres;

--
-- TOC entry 323 (class 1259 OID 25400)
-- Name: conciliacao_bancaria_id_conciliacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.conciliacao_bancaria_id_conciliacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.conciliacao_bancaria_id_conciliacao_seq OWNER TO postgres;

--
-- TOC entry 8184 (class 0 OID 0)
-- Dependencies: 323
-- Name: conciliacao_bancaria_id_conciliacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.conciliacao_bancaria_id_conciliacao_seq OWNED BY public.conciliacao_bancaria.id_conciliacao;


--
-- TOC entry 559 (class 1259 OID 27417)
-- Name: conector_integracao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conector_integracao (
    id_conector integer NOT NULL,
    id_sistema_externo integer NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    tipo_integracao character varying(50) NOT NULL,
    protocolo character varying(30),
    metodo_http character varying(20),
    endpoint text,
    timeout_segundos integer DEFAULT 30,
    limite_tentativas integer DEFAULT 3,
    autenticacao character varying(50),
    configuracao jsonb,
    ativo boolean DEFAULT true,
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.conector_integracao OWNER TO postgres;

--
-- TOC entry 558 (class 1259 OID 27416)
-- Name: conector_integracao_id_conector_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.conector_integracao_id_conector_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.conector_integracao_id_conector_seq OWNER TO postgres;

--
-- TOC entry 8185 (class 0 OID 0)
-- Dependencies: 558
-- Name: conector_integracao_id_conector_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.conector_integracao_id_conector_seq OWNED BY public.conector_integracao.id_conector;


--
-- TOC entry 497 (class 1259 OID 27003)
-- Name: configuracao_empresa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.configuracao_empresa (
    id_configuracao integer NOT NULL,
    id_empresa integer NOT NULL,
    nome_sistema character varying(100),
    logo text,
    email_padrao character varying(150),
    telefone_padrao character varying(30),
    site character varying(150),
    timezone character varying(50) DEFAULT 'America/Sao_Paulo'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


ALTER TABLE public.configuracao_empresa OWNER TO postgres;

--
-- TOC entry 496 (class 1259 OID 27002)
-- Name: configuracao_empresa_id_configuracao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.configuracao_empresa_id_configuracao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.configuracao_empresa_id_configuracao_seq OWNER TO postgres;

--
-- TOC entry 8186 (class 0 OID 0)
-- Dependencies: 496
-- Name: configuracao_empresa_id_configuracao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.configuracao_empresa_id_configuracao_seq OWNED BY public.configuracao_empresa.id_configuracao;


--
-- TOC entry 554 (class 1259 OID 27374)
-- Name: conformidade_lgpd; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conformidade_lgpd (
    id_lgpd integer NOT NULL,
    tipo_dado character varying(100),
    finalidade character varying(200),
    base_legal character varying(100),
    retencao_dias integer,
    responsavel character varying(100),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.conformidade_lgpd OWNER TO postgres;

--
-- TOC entry 553 (class 1259 OID 27373)
-- Name: conformidade_lgpd_id_lgpd_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.conformidade_lgpd_id_lgpd_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.conformidade_lgpd_id_lgpd_seq OWNER TO postgres;

--
-- TOC entry 8187 (class 0 OID 0)
-- Dependencies: 553
-- Name: conformidade_lgpd_id_lgpd_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.conformidade_lgpd_id_lgpd_seq OWNED BY public.conformidade_lgpd.id_lgpd;


--
-- TOC entry 315 (class 1259 OID 25291)
-- Name: conta_bancaria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.conta_bancaria (
    id_conta_bancaria integer NOT NULL,
    id_empresa integer NOT NULL,
    banco character varying(100) NOT NULL,
    codigo_banco character varying(10),
    agencia character varying(20),
    numero_conta character varying(30),
    tipo_conta character varying(30),
    saldo_inicial numeric(15,2) DEFAULT 0,
    saldo_atual numeric(15,2) DEFAULT 0,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1,
    id_banco integer
);


ALTER TABLE public.conta_bancaria OWNER TO postgres;

--
-- TOC entry 314 (class 1259 OID 25290)
-- Name: conta_bancaria_id_conta_bancaria_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.conta_bancaria_id_conta_bancaria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.conta_bancaria_id_conta_bancaria_seq OWNER TO postgres;

--
-- TOC entry 8188 (class 0 OID 0)
-- Dependencies: 314
-- Name: conta_bancaria_id_conta_bancaria_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.conta_bancaria_id_conta_bancaria_seq OWNED BY public.conta_bancaria.id_conta_bancaria;


--
-- TOC entry 409 (class 1259 OID 26232)
-- Name: contato_cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contato_cliente (
    id_contato integer NOT NULL,
    id_cliente integer,
    tipo_contato character varying(50),
    descricao text,
    data_contato timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    usuario character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.contato_cliente OWNER TO postgres;

--
-- TOC entry 408 (class 1259 OID 26231)
-- Name: contato_cliente_id_contato_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.contato_cliente_id_contato_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.contato_cliente_id_contato_seq OWNER TO postgres;

--
-- TOC entry 8189 (class 0 OID 0)
-- Dependencies: 408
-- Name: contato_cliente_id_contato_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.contato_cliente_id_contato_seq OWNED BY public.contato_cliente.id_contato;


--
-- TOC entry 471 (class 1259 OID 26787)
-- Name: contrato; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.contrato (
    id_contrato integer NOT NULL,
    id_documento integer NOT NULL,
    parte_contratante character varying(150),
    parte_contratada character varying(150),
    data_inicio date,
    data_fim date,
    valor_contrato numeric(15,2),
    tipo_contrato character varying(50),
    status character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


ALTER TABLE public.contrato OWNER TO postgres;

--
-- TOC entry 470 (class 1259 OID 26786)
-- Name: contrato_id_contrato_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.contrato_id_contrato_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.contrato_id_contrato_seq OWNER TO postgres;

--
-- TOC entry 8190 (class 0 OID 0)
-- Dependencies: 470
-- Name: contrato_id_contrato_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.contrato_id_contrato_seq OWNED BY public.contrato.id_contrato;


--
-- TOC entry 475 (class 1259 OID 26818)
-- Name: controle_vencimento_documento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.controle_vencimento_documento (
    id_controle integer NOT NULL,
    id_documento integer NOT NULL,
    dias_alerta integer DEFAULT 30,
    alerta_enviado boolean DEFAULT false,
    data_alerta date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.controle_vencimento_documento OWNER TO postgres;

--
-- TOC entry 474 (class 1259 OID 26817)
-- Name: controle_vencimento_documento_id_controle_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.controle_vencimento_documento_id_controle_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.controle_vencimento_documento_id_controle_seq OWNER TO postgres;

--
-- TOC entry 8191 (class 0 OID 0)
-- Dependencies: 474
-- Name: controle_vencimento_documento_id_controle_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.controle_vencimento_documento_id_controle_seq OWNED BY public.controle_vencimento_documento.id_controle;


--
-- TOC entry 401 (class 1259 OID 26162)
-- Name: custo_pacote; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.custo_pacote (
    id_custo integer NOT NULL,
    id_pacote integer NOT NULL,
    tipo_custo character varying(50),
    descricao character varying(200),
    quantidade numeric(10,2),
    valor_unitario numeric(15,2),
    valor_total numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.custo_pacote OWNER TO postgres;

--
-- TOC entry 400 (class 1259 OID 26161)
-- Name: custo_pacote_id_custo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.custo_pacote_id_custo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.custo_pacote_id_custo_seq OWNER TO postgres;

--
-- TOC entry 8192 (class 0 OID 0)
-- Dependencies: 400
-- Name: custo_pacote_id_custo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.custo_pacote_id_custo_seq OWNED BY public.custo_pacote.id_custo;


--
-- TOC entry 488 (class 1259 OID 26933)
-- Name: custo_projeto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.custo_projeto (
    id_custo_projeto integer NOT NULL,
    id_projeto integer NOT NULL,
    descricao character varying(200),
    categoria character varying(100),
    valor_previsto numeric(15,2),
    valor_real numeric(15,2),
    data_lancamento date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.custo_projeto OWNER TO postgres;

--
-- TOC entry 487 (class 1259 OID 26932)
-- Name: custo_projeto_id_custo_projeto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.custo_projeto_id_custo_projeto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.custo_projeto_id_custo_projeto_seq OWNER TO postgres;

--
-- TOC entry 8193 (class 0 OID 0)
-- Dependencies: 487
-- Name: custo_projeto_id_custo_projeto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.custo_projeto_id_custo_projeto_seq OWNED BY public.custo_projeto.id_custo_projeto;


--
-- TOC entry 346 (class 1259 OID 25641)
-- Name: das; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.das (
    id_das integer NOT NULL,
    id_empresa integer NOT NULL,
    competencia date NOT NULL,
    receita_bruta numeric(15,2),
    aliquota numeric(5,2),
    valor_das numeric(15,2),
    data_vencimento date,
    data_pagamento date,
    status character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.das OWNER TO postgres;

--
-- TOC entry 345 (class 1259 OID 25640)
-- Name: das_id_das_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.das_id_das_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.das_id_das_seq OWNER TO postgres;

--
-- TOC entry 8194 (class 0 OID 0)
-- Dependencies: 345
-- Name: das_id_das_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.das_id_das_seq OWNED BY public.das.id_das;


--
-- TOC entry 572 (class 1259 OID 27578)
-- Name: data_mart_execucao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.data_mart_execucao (
    id_execucao integer NOT NULL,
    processo character varying(100) NOT NULL,
    data_inicio timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    data_fim timestamp without time zone,
    registros_processados integer DEFAULT 0,
    status character varying(30) DEFAULT 'PROCESSANDO'::character varying,
    mensagem text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.data_mart_execucao OWNER TO postgres;

--
-- TOC entry 571 (class 1259 OID 27577)
-- Name: data_mart_execucao_id_execucao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.data_mart_execucao_id_execucao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.data_mart_execucao_id_execucao_seq OWNER TO postgres;

--
-- TOC entry 8195 (class 0 OID 0)
-- Dependencies: 571
-- Name: data_mart_execucao_id_execucao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.data_mart_execucao_id_execucao_seq OWNED BY public.data_mart_execucao.id_execucao;


--
-- TOC entry 354 (class 1259 OID 25765)
-- Name: declaracao_fiscal; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.declaracao_fiscal (
    id_declaracao integer NOT NULL,
    id_empresa integer NOT NULL,
    tipo_declaracao character varying(50) NOT NULL,
    ano integer,
    periodo character varying(20),
    data_entrega date,
    status character varying(30) DEFAULT 'PENDENTE'::character varying,
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.declaracao_fiscal OWNER TO postgres;

--
-- TOC entry 353 (class 1259 OID 25764)
-- Name: declaracao_fiscal_id_declaracao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.declaracao_fiscal_id_declaracao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.declaracao_fiscal_id_declaracao_seq OWNER TO postgres;

--
-- TOC entry 8196 (class 0 OID 0)
-- Dependencies: 353
-- Name: declaracao_fiscal_id_declaracao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.declaracao_fiscal_id_declaracao_seq OWNED BY public.declaracao_fiscal.id_declaracao;


--
-- TOC entry 437 (class 1259 OID 26483)
-- Name: depreciacao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.depreciacao (
    id_depreciacao integer NOT NULL,
    id_ativo integer NOT NULL,
    competencia date NOT NULL,
    valor_depreciacao numeric(15,2),
    valor_contabil numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.depreciacao OWNER TO postgres;

--
-- TOC entry 436 (class 1259 OID 26482)
-- Name: depreciacao_id_depreciacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.depreciacao_id_depreciacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.depreciacao_id_depreciacao_seq OWNER TO postgres;

--
-- TOC entry 8197 (class 0 OID 0)
-- Dependencies: 436
-- Name: depreciacao_id_depreciacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.depreciacao_id_depreciacao_seq OWNED BY public.depreciacao.id_depreciacao;


--
-- TOC entry 387 (class 1259 OID 26031)
-- Name: destino; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.destino (
    id_destino integer NOT NULL,
    codigo character varying(20) NOT NULL,
    nome character varying(150) NOT NULL,
    descricao text,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1,
    id_localidade integer NOT NULL
);


ALTER TABLE public.destino OWNER TO postgres;

--
-- TOC entry 386 (class 1259 OID 26030)
-- Name: destino_id_destino_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.destino_id_destino_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.destino_id_destino_seq OWNER TO postgres;

--
-- TOC entry 8198 (class 0 OID 0)
-- Dependencies: 386
-- Name: destino_id_destino_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.destino_id_destino_seq OWNED BY public.destino.id_destino;


--
-- TOC entry 581 (class 1259 OID 27659)
-- Name: dim_cliente; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_cliente (
    id_dim_cliente integer NOT NULL,
    id_cliente_origem integer,
    nome_cliente character varying(150),
    cidade character varying(100),
    estado character varying(50),
    segmento character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    versao integer DEFAULT 1
);


ALTER TABLE public.dim_cliente OWNER TO postgres;

--
-- TOC entry 580 (class 1259 OID 27658)
-- Name: dim_cliente_id_dim_cliente_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dim_cliente_id_dim_cliente_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dim_cliente_id_dim_cliente_seq OWNER TO postgres;

--
-- TOC entry 8199 (class 0 OID 0)
-- Dependencies: 580
-- Name: dim_cliente_id_dim_cliente_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dim_cliente_id_dim_cliente_seq OWNED BY public.dim_cliente.id_dim_cliente;


--
-- TOC entry 579 (class 1259 OID 27644)
-- Name: dim_data; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_data (
    id_data integer NOT NULL,
    data date NOT NULL,
    ano integer,
    mes integer,
    nome_mes character varying(20),
    trimestre integer,
    semana integer,
    dia integer,
    dia_semana character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    versao integer DEFAULT 1
);


ALTER TABLE public.dim_data OWNER TO postgres;

--
-- TOC entry 578 (class 1259 OID 27643)
-- Name: dim_data_id_data_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dim_data_id_data_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dim_data_id_data_seq OWNER TO postgres;

--
-- TOC entry 8200 (class 0 OID 0)
-- Dependencies: 578
-- Name: dim_data_id_data_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dim_data_id_data_seq OWNED BY public.dim_data.id_data;


--
-- TOC entry 585 (class 1259 OID 27681)
-- Name: dim_destino; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_destino (
    id_dim_destino integer NOT NULL,
    id_destino_origem integer,
    nome_destino character varying(150),
    cidade character varying(100),
    estado character varying(50),
    pais character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    versao integer DEFAULT 1
);


ALTER TABLE public.dim_destino OWNER TO postgres;

--
-- TOC entry 584 (class 1259 OID 27680)
-- Name: dim_destino_id_dim_destino_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dim_destino_id_dim_destino_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dim_destino_id_dim_destino_seq OWNER TO postgres;

--
-- TOC entry 8201 (class 0 OID 0)
-- Dependencies: 584
-- Name: dim_destino_id_dim_destino_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dim_destino_id_dim_destino_seq OWNED BY public.dim_destino.id_dim_destino;


--
-- TOC entry 587 (class 1259 OID 27692)
-- Name: dim_plano_contas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_plano_contas (
    id_dim_plano integer NOT NULL,
    id_plano_origem integer,
    codigo character varying(50),
    descricao character varying(150),
    grupo character varying(100),
    categoria character varying(100),
    natureza character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    versao integer DEFAULT 1
);


ALTER TABLE public.dim_plano_contas OWNER TO postgres;

--
-- TOC entry 586 (class 1259 OID 27691)
-- Name: dim_plano_contas_id_dim_plano_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dim_plano_contas_id_dim_plano_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dim_plano_contas_id_dim_plano_seq OWNER TO postgres;

--
-- TOC entry 8202 (class 0 OID 0)
-- Dependencies: 586
-- Name: dim_plano_contas_id_dim_plano_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dim_plano_contas_id_dim_plano_seq OWNED BY public.dim_plano_contas.id_dim_plano;


--
-- TOC entry 583 (class 1259 OID 27670)
-- Name: dim_produto_turistico; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dim_produto_turistico (
    id_dim_produto integer NOT NULL,
    id_produto_origem integer,
    nome_produto character varying(150),
    categoria character varying(100),
    tipo_produto character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    versao integer DEFAULT 1
);


ALTER TABLE public.dim_produto_turistico OWNER TO postgres;

--
-- TOC entry 582 (class 1259 OID 27669)
-- Name: dim_produto_turistico_id_dim_produto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.dim_produto_turistico_id_dim_produto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.dim_produto_turistico_id_dim_produto_seq OWNER TO postgres;

--
-- TOC entry 8203 (class 0 OID 0)
-- Dependencies: 582
-- Name: dim_produto_turistico_id_dim_produto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.dim_produto_turistico_id_dim_produto_seq OWNED BY public.dim_produto_turistico.id_dim_produto;


--
-- TOC entry 350 (class 1259 OID 25713)
-- Name: distribuicao_lucros; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.distribuicao_lucros (
    id_distribuicao integer NOT NULL,
    id_empresa integer NOT NULL,
    data_distribuicao date,
    periodo character varying(20),
    valor numeric(15,2),
    socio character varying(150),
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.distribuicao_lucros OWNER TO postgres;

--
-- TOC entry 349 (class 1259 OID 25712)
-- Name: distribuicao_lucros_id_distribuicao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.distribuicao_lucros_id_distribuicao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.distribuicao_lucros_id_distribuicao_seq OWNER TO postgres;

--
-- TOC entry 8204 (class 0 OID 0)
-- Dependencies: 349
-- Name: distribuicao_lucros_id_distribuicao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.distribuicao_lucros_id_distribuicao_seq OWNED BY public.distribuicao_lucros.id_distribuicao;


--
-- TOC entry 467 (class 1259 OID 26750)
-- Name: documento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.documento (
    id_documento integer NOT NULL,
    id_tipo_documento integer NOT NULL,
    descricao character varying(200),
    entidade_tipo character varying(50),
    entidade_id integer,
    data_documento date,
    data_validade date,
    status character varying(30) DEFAULT 'ATIVO'::character varying,
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.documento OWNER TO postgres;

--
-- TOC entry 466 (class 1259 OID 26749)
-- Name: documento_id_documento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.documento_id_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.documento_id_documento_seq OWNER TO postgres;

--
-- TOC entry 8205 (class 0 OID 0)
-- Dependencies: 466
-- Name: documento_id_documento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.documento_id_documento_seq OWNED BY public.documento.id_documento;


--
-- TOC entry 503 (class 1259 OID 27051)
-- Name: email_sistema; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.email_sistema (
    id_email integer NOT NULL,
    servidor_smtp character varying(150),
    porta integer,
    usuario character varying(150),
    senha_criptografada text,
    email_remetente character varying(150),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.email_sistema OWNER TO postgres;

--
-- TOC entry 502 (class 1259 OID 27050)
-- Name: email_sistema_id_email_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.email_sistema_id_email_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.email_sistema_id_email_seq OWNER TO postgres;

--
-- TOC entry 8206 (class 0 OID 0)
-- Dependencies: 502
-- Name: email_sistema_id_email_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.email_sistema_id_email_seq OWNED BY public.email_sistema.id_email;


--
-- TOC entry 291 (class 1259 OID 25074)
-- Name: empresa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.empresa (
    id_empresa integer NOT NULL,
    razao_social character varying(150) NOT NULL,
    nome_fantasia character varying(100) NOT NULL,
    cnpj character varying(18),
    inscricao_municipal character varying(30),
    regime_tributario character varying(50),
    data_abertura date,
    capital_social numeric(15,2),
    telefone character varying(30),
    email character varying(150),
    site character varying(150),
    logradouro character varying(150),
    numero character varying(20),
    complemento character varying(100),
    bairro character varying(100),
    cep character varying(10),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1 NOT NULL,
    id_localidade integer NOT NULL
);


ALTER TABLE public.empresa OWNER TO postgres;

--
-- TOC entry 8207 (class 0 OID 0)
-- Dependencies: 291
-- Name: TABLE empresa; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.empresa IS 'Cadastro das empresas pertencentes ao sistema WMA Travel';


--
-- TOC entry 290 (class 1259 OID 25073)
-- Name: empresa_id_empresa_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.empresa_id_empresa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.empresa_id_empresa_seq OWNER TO postgres;

--
-- TOC entry 8208 (class 0 OID 0)
-- Dependencies: 290
-- Name: empresa_id_empresa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.empresa_id_empresa_seq OWNED BY public.empresa.id_empresa;


--
-- TOC entry 456 (class 1259 OID 26659)
-- Name: estoque; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.estoque (
    id_estoque integer NOT NULL,
    id_produto_estoque integer NOT NULL,
    quantidade_atual numeric(10,2) DEFAULT 0,
    localizacao character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone
);


ALTER TABLE public.estoque OWNER TO postgres;

--
-- TOC entry 455 (class 1259 OID 26658)
-- Name: estoque_id_estoque_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.estoque_id_estoque_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.estoque_id_estoque_seq OWNER TO postgres;

--
-- TOC entry 8209 (class 0 OID 0)
-- Dependencies: 455
-- Name: estoque_id_estoque_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.estoque_id_estoque_seq OWNED BY public.estoque.id_estoque;


--
-- TOC entry 482 (class 1259 OID 26875)
-- Name: etapa_projeto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.etapa_projeto (
    id_etapa integer NOT NULL,
    id_projeto integer NOT NULL,
    ordem integer,
    nome character varying(150),
    descricao text,
    status character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone
);


ALTER TABLE public.etapa_projeto OWNER TO postgres;

--
-- TOC entry 481 (class 1259 OID 26874)
-- Name: etapa_projeto_id_etapa_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.etapa_projeto_id_etapa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.etapa_projeto_id_etapa_seq OWNER TO postgres;

--
-- TOC entry 8210 (class 0 OID 0)
-- Dependencies: 481
-- Name: etapa_projeto_id_etapa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.etapa_projeto_id_etapa_seq OWNED BY public.etapa_projeto.id_etapa;


--
-- TOC entry 576 (class 1259 OID 27619)
-- Name: fato_financeiro; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fato_financeiro (
    id_fato_financeiro integer NOT NULL,
    data_movimento date NOT NULL,
    id_lancamento_origem integer,
    id_plano_contas integer,
    id_centro_custo integer,
    tipo_movimento character varying(30),
    natureza character varying(20),
    grupo_financeiro character varying(100),
    categoria_financeira character varying(100),
    valor numeric(14,2) DEFAULT 0,
    competencia date,
    status character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.fato_financeiro OWNER TO postgres;

--
-- TOC entry 575 (class 1259 OID 27618)
-- Name: fato_financeiro_id_fato_financeiro_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fato_financeiro_id_fato_financeiro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fato_financeiro_id_fato_financeiro_seq OWNER TO postgres;

--
-- TOC entry 8211 (class 0 OID 0)
-- Dependencies: 575
-- Name: fato_financeiro_id_fato_financeiro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fato_financeiro_id_fato_financeiro_seq OWNED BY public.fato_financeiro.id_fato_financeiro;


--
-- TOC entry 574 (class 1259 OID 27595)
-- Name: fato_vendas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fato_vendas (
    id_fato_venda integer NOT NULL,
    data_venda date NOT NULL,
    id_venda_origem integer,
    id_cliente integer,
    id_produto_turistico integer,
    id_destino integer,
    canal_venda character varying(50),
    quantidade integer DEFAULT 1,
    valor_bruto numeric(12,2) DEFAULT 0,
    valor_desconto numeric(12,2) DEFAULT 0,
    valor_liquido numeric(12,2) DEFAULT 0,
    custo numeric(12,2) DEFAULT 0,
    comissao numeric(12,2) DEFAULT 0,
    margem numeric(12,2) DEFAULT 0,
    status_venda character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.fato_vendas OWNER TO postgres;

--
-- TOC entry 573 (class 1259 OID 27594)
-- Name: fato_vendas_id_fato_venda_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fato_vendas_id_fato_venda_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fato_vendas_id_fato_venda_seq OWNER TO postgres;

--
-- TOC entry 8212 (class 0 OID 0)
-- Dependencies: 573
-- Name: fato_vendas_id_fato_venda_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fato_vendas_id_fato_venda_seq OWNED BY public.fato_vendas.id_fato_venda;


--
-- TOC entry 565 (class 1259 OID 27494)
-- Name: fila_integracao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fila_integracao (
    id_fila_integracao integer NOT NULL,
    id_conector integer NOT NULL,
    tipo_evento character varying(100) NOT NULL,
    entidade character varying(100),
    chave_registro character varying(100),
    payload jsonb NOT NULL,
    prioridade integer DEFAULT 5,
    tentativas integer DEFAULT 0,
    limite_tentativas integer DEFAULT 3,
    status character varying(30) DEFAULT 'PENDENTE'::character varying,
    mensagem_erro text,
    data_processamento timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.fila_integracao OWNER TO postgres;

--
-- TOC entry 564 (class 1259 OID 27493)
-- Name: fila_integracao_id_fila_integracao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fila_integracao_id_fila_integracao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fila_integracao_id_fila_integracao_seq OWNER TO postgres;

--
-- TOC entry 8213 (class 0 OID 0)
-- Dependencies: 564
-- Name: fila_integracao_id_fila_integracao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fila_integracao_id_fila_integracao_seq OWNED BY public.fila_integracao.id_fila_integracao;


--
-- TOC entry 518 (class 1259 OID 27159)
-- Name: fila_processamento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fila_processamento (
    id_fila integer NOT NULL,
    tipo_processo character varying(100),
    dados jsonb,
    prioridade integer DEFAULT 5,
    status character varying(30) DEFAULT 'PENDENTE'::character varying,
    tentativas integer DEFAULT 0,
    data_criacao timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    data_processamento timestamp without time zone
);


ALTER TABLE public.fila_processamento OWNER TO postgres;

--
-- TOC entry 517 (class 1259 OID 27158)
-- Name: fila_processamento_id_fila_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fila_processamento_id_fila_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fila_processamento_id_fila_seq OWNER TO postgres;

--
-- TOC entry 8214 (class 0 OID 0)
-- Dependencies: 517
-- Name: fila_processamento_id_fila_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fila_processamento_id_fila_seq OWNED BY public.fila_processamento.id_fila;


--
-- TOC entry 317 (class 1259 OID 25314)
-- Name: forma_pagamento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.forma_pagamento (
    id_forma_pagamento integer NOT NULL,
    codigo character varying(20) NOT NULL,
    descricao character varying(100) NOT NULL,
    tipo character varying(50),
    prazo_dias integer DEFAULT 0,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.forma_pagamento OWNER TO postgres;

--
-- TOC entry 316 (class 1259 OID 25313)
-- Name: forma_pagamento_id_forma_pagamento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.forma_pagamento_id_forma_pagamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.forma_pagamento_id_forma_pagamento_seq OWNER TO postgres;

--
-- TOC entry 8215 (class 0 OID 0)
-- Dependencies: 316
-- Name: forma_pagamento_id_forma_pagamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.forma_pagamento_id_forma_pagamento_seq OWNED BY public.forma_pagamento.id_forma_pagamento;


--
-- TOC entry 299 (class 1259 OID 25144)
-- Name: fornecedor; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fornecedor (
    id_fornecedor integer NOT NULL,
    id_pessoa integer NOT NULL,
    codigo_fornecedor character varying(20),
    tipo_fornecedor character varying(50),
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.fornecedor OWNER TO postgres;

--
-- TOC entry 298 (class 1259 OID 25143)
-- Name: fornecedor_id_fornecedor_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fornecedor_id_fornecedor_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fornecedor_id_fornecedor_seq OWNER TO postgres;

--
-- TOC entry 8216 (class 0 OID 0)
-- Dependencies: 298
-- Name: fornecedor_id_fornecedor_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fornecedor_id_fornecedor_seq OWNED BY public.fornecedor.id_fornecedor;


--
-- TOC entry 391 (class 1259 OID 26075)
-- Name: fornecedor_turistico; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.fornecedor_turistico (
    id_fornecedor_turistico integer NOT NULL,
    id_fornecedor integer NOT NULL,
    tipo_fornecedor character varying(50),
    categoria character varying(100),
    registro_turismo character varying(50),
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.fornecedor_turistico OWNER TO postgres;

--
-- TOC entry 390 (class 1259 OID 26074)
-- Name: fornecedor_turistico_id_fornecedor_turistico_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.fornecedor_turistico_id_fornecedor_turistico_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.fornecedor_turistico_id_fornecedor_turistico_seq OWNER TO postgres;

--
-- TOC entry 8217 (class 0 OID 0)
-- Dependencies: 390
-- Name: fornecedor_turistico_id_fornecedor_turistico_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.fornecedor_turistico_id_fornecedor_turistico_seq OWNED BY public.fornecedor_turistico.id_fornecedor_turistico;


--
-- TOC entry 411 (class 1259 OID 26250)
-- Name: funil_vendas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.funil_vendas (
    id_funil integer NOT NULL,
    id_lead integer NOT NULL,
    etapa character varying(50),
    probabilidade numeric(5,2),
    valor_negociacao numeric(15,2),
    data_movimento date DEFAULT CURRENT_DATE,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.funil_vendas OWNER TO postgres;

--
-- TOC entry 410 (class 1259 OID 26249)
-- Name: funil_vendas_id_funil_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.funil_vendas_id_funil_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.funil_vendas_id_funil_seq OWNER TO postgres;

--
-- TOC entry 8218 (class 0 OID 0)
-- Dependencies: 410
-- Name: funil_vendas_id_funil_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.funil_vendas_id_funil_seq OWNED BY public.funil_vendas.id_funil;


--
-- TOC entry 373 (class 1259 OID 25923)
-- Name: gateway_pagamento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.gateway_pagamento (
    id_gateway integer NOT NULL,
    codigo character varying(30) NOT NULL,
    descricao character varying(100),
    tipo character varying(50),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.gateway_pagamento OWNER TO postgres;

--
-- TOC entry 372 (class 1259 OID 25922)
-- Name: gateway_pagamento_id_gateway_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.gateway_pagamento_id_gateway_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.gateway_pagamento_id_gateway_seq OWNER TO postgres;

--
-- TOC entry 8219 (class 0 OID 0)
-- Dependencies: 372
-- Name: gateway_pagamento_id_gateway_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.gateway_pagamento_id_gateway_seq OWNED BY public.gateway_pagamento.id_gateway;


--
-- TOC entry 305 (class 1259 OID 25201)
-- Name: grupo_conta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.grupo_conta (
    id_grupo integer NOT NULL,
    codigo character varying(10) NOT NULL,
    descricao character varying(100) NOT NULL,
    natureza character varying(20) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1,
    CONSTRAINT ck_grupo_natureza CHECK (((natureza)::text = ANY ((ARRAY['DEVEDORA'::character varying, 'CREDORA'::character varying])::text[])))
);


ALTER TABLE public.grupo_conta OWNER TO postgres;

--
-- TOC entry 304 (class 1259 OID 25200)
-- Name: grupo_conta_id_grupo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.grupo_conta_id_grupo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.grupo_conta_id_grupo_seq OWNER TO postgres;

--
-- TOC entry 8220 (class 0 OID 0)
-- Dependencies: 304
-- Name: grupo_conta_id_grupo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.grupo_conta_id_grupo_seq OWNED BY public.grupo_conta.id_grupo;


--
-- TOC entry 397 (class 1259 OID 26129)
-- Name: guia_turistico; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.guia_turistico (
    id_guia integer NOT NULL,
    nome character varying(150) NOT NULL,
    cadastur character varying(50),
    telefone character varying(30),
    email character varying(150),
    valor_diaria numeric(15,2),
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.guia_turistico OWNER TO postgres;

--
-- TOC entry 396 (class 1259 OID 26128)
-- Name: guia_turistico_id_guia_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.guia_turistico_id_guia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.guia_turistico_id_guia_seq OWNER TO postgres;

--
-- TOC entry 8221 (class 0 OID 0)
-- Dependencies: 396
-- Name: guia_turistico_id_guia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.guia_turistico_id_guia_seq OWNED BY public.guia_turistico.id_guia;


--
-- TOC entry 369 (class 1259 OID 25891)
-- Name: historico_alteracao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.historico_alteracao (
    id_historico integer NOT NULL,
    tabela_nome character varying(100),
    registro_id integer,
    campo_alterado character varying(100),
    valor_anterior text,
    valor_novo text,
    usuario character varying(100),
    data_alteracao timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.historico_alteracao OWNER TO postgres;

--
-- TOC entry 368 (class 1259 OID 25890)
-- Name: historico_alteracao_id_historico_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.historico_alteracao_id_historico_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.historico_alteracao_id_historico_seq OWNER TO postgres;

--
-- TOC entry 8222 (class 0 OID 0)
-- Dependencies: 368
-- Name: historico_alteracao_id_historico_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.historico_alteracao_id_historico_seq OWNED BY public.historico_alteracao.id_historico;


--
-- TOC entry 477 (class 1259 OID 26835)
-- Name: historico_documento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.historico_documento (
    id_historico integer NOT NULL,
    id_documento integer NOT NULL,
    acao character varying(50),
    descricao text,
    usuario character varying(100),
    data_evento timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.historico_documento OWNER TO postgres;

--
-- TOC entry 476 (class 1259 OID 26834)
-- Name: historico_documento_id_historico_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.historico_documento_id_historico_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.historico_documento_id_historico_seq OWNER TO postgres;

--
-- TOC entry 8223 (class 0 OID 0)
-- Dependencies: 476
-- Name: historico_documento_id_historico_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.historico_documento_id_historico_seq OWNED BY public.historico_documento.id_historico;


--
-- TOC entry 430 (class 1259 OID 26421)
-- Name: horas_atividade; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.horas_atividade (
    id_hora integer NOT NULL,
    id_colaborador integer NOT NULL,
    data_atividade date,
    atividade character varying(150),
    quantidade_horas numeric(5,2),
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.horas_atividade OWNER TO postgres;

--
-- TOC entry 429 (class 1259 OID 26420)
-- Name: horas_atividade_id_hora_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.horas_atividade_id_hora_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.horas_atividade_id_hora_seq OWNER TO postgres;

--
-- TOC entry 8224 (class 0 OID 0)
-- Dependencies: 429
-- Name: horas_atividade_id_hora_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.horas_atividade_id_hora_seq OWNED BY public.horas_atividade.id_hora;


--
-- TOC entry 393 (class 1259 OID 26094)
-- Name: hospedagem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.hospedagem (
    id_hospedagem integer NOT NULL,
    id_fornecedor_turistico integer NOT NULL,
    nome character varying(150),
    categoria character varying(50),
    tipo_acomodacao character varying(100),
    quantidade_quartos integer,
    valor_diaria numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.hospedagem OWNER TO postgres;

--
-- TOC entry 392 (class 1259 OID 26093)
-- Name: hospedagem_id_hospedagem_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.hospedagem_id_hospedagem_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.hospedagem_id_hospedagem_seq OWNER TO postgres;

--
-- TOC entry 8225 (class 0 OID 0)
-- Dependencies: 392
-- Name: hospedagem_id_hospedagem_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.hospedagem_id_hospedagem_seq OWNED BY public.hospedagem.id_hospedagem;


--
-- TOC entry 383 (class 1259 OID 26009)
-- Name: importacao_dados; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.importacao_dados (
    id_importacao integer NOT NULL,
    tipo_importacao character varying(50),
    nome_arquivo character varying(255),
    quantidade_registros integer,
    registros_processados integer,
    registros_erro integer,
    status character varying(30),
    mensagem text,
    data_importacao timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.importacao_dados OWNER TO postgres;

--
-- TOC entry 382 (class 1259 OID 26008)
-- Name: importacao_dados_id_importacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.importacao_dados_id_importacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.importacao_dados_id_importacao_seq OWNER TO postgres;

--
-- TOC entry 8226 (class 0 OID 0)
-- Dependencies: 382
-- Name: importacao_dados_id_importacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.importacao_dados_id_importacao_seq OWNED BY public.importacao_dados.id_importacao;


--
-- TOC entry 342 (class 1259 OID 25612)
-- Name: imposto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.imposto (
    id_imposto integer NOT NULL,
    codigo character varying(20),
    descricao character varying(100),
    tipo character varying(50),
    aliquota numeric(5,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.imposto OWNER TO postgres;

--
-- TOC entry 341 (class 1259 OID 25611)
-- Name: imposto_id_imposto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.imposto_id_imposto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.imposto_id_imposto_seq OWNER TO postgres;

--
-- TOC entry 8227 (class 0 OID 0)
-- Dependencies: 341
-- Name: imposto_id_imposto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.imposto_id_imposto_seq OWNED BY public.imposto.id_imposto;


--
-- TOC entry 381 (class 1259 OID 25992)
-- Name: integracao_nfse; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integracao_nfse (
    id_integracao integer NOT NULL,
    id_nota_fiscal integer NOT NULL,
    provedor character varying(100),
    codigo_retorno character varying(50),
    mensagem text,
    xml_envio text,
    xml_retorno text,
    status character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.integracao_nfse OWNER TO postgres;

--
-- TOC entry 380 (class 1259 OID 25991)
-- Name: integracao_nfse_id_integracao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.integracao_nfse_id_integracao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.integracao_nfse_id_integracao_seq OWNER TO postgres;

--
-- TOC entry 8228 (class 0 OID 0)
-- Dependencies: 380
-- Name: integracao_nfse_id_integracao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.integracao_nfse_id_integracao_seq OWNED BY public.integracao_nfse.id_integracao;


--
-- TOC entry 371 (class 1259 OID 25903)
-- Name: integracao_woocommerce; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.integracao_woocommerce (
    id_integracao integer NOT NULL,
    id_empresa integer NOT NULL,
    id_pedido_externo character varying(50),
    tipo_evento character varying(50),
    data_evento timestamp without time zone,
    status character varying(30),
    json_dados jsonb,
    sincronizado boolean DEFAULT false,
    data_sincronizacao timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.integracao_woocommerce OWNER TO postgres;

--
-- TOC entry 370 (class 1259 OID 25902)
-- Name: integracao_woocommerce_id_integracao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.integracao_woocommerce_id_integracao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.integracao_woocommerce_id_integracao_seq OWNER TO postgres;

--
-- TOC entry 8229 (class 0 OID 0)
-- Dependencies: 370
-- Name: integracao_woocommerce_id_integracao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.integracao_woocommerce_id_integracao_seq OWNED BY public.integracao_woocommerce.id_integracao;


--
-- TOC entry 413 (class 1259 OID 26267)
-- Name: interacao_lead; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.interacao_lead (
    id_interacao integer NOT NULL,
    id_lead integer NOT NULL,
    tipo character varying(50),
    descricao text,
    data_interacao timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    responsavel character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.interacao_lead OWNER TO postgres;

--
-- TOC entry 412 (class 1259 OID 26266)
-- Name: interacao_lead_id_interacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.interacao_lead_id_interacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.interacao_lead_id_interacao_seq OWNER TO postgres;

--
-- TOC entry 8230 (class 0 OID 0)
-- Dependencies: 412
-- Name: interacao_lead_id_interacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.interacao_lead_id_interacao_seq OWNED BY public.interacao_lead.id_interacao;


--
-- TOC entry 460 (class 1259 OID 26695)
-- Name: inventario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.inventario (
    id_inventario integer NOT NULL,
    data_inventario date DEFAULT CURRENT_DATE,
    responsavel character varying(100),
    status character varying(30),
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.inventario OWNER TO postgres;

--
-- TOC entry 459 (class 1259 OID 26694)
-- Name: inventario_id_inventario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.inventario_id_inventario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.inventario_id_inventario_seq OWNER TO postgres;

--
-- TOC entry 8231 (class 0 OID 0)
-- Dependencies: 459
-- Name: inventario_id_inventario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.inventario_id_inventario_seq OWNED BY public.inventario.id_inventario;


--
-- TOC entry 462 (class 1259 OID 26707)
-- Name: item_inventario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_inventario (
    id_item integer NOT NULL,
    id_inventario integer NOT NULL,
    id_produto_estoque integer NOT NULL,
    quantidade_sistema numeric(10,2),
    quantidade_contada numeric(10,2),
    diferenca numeric(10,2)
);


ALTER TABLE public.item_inventario OWNER TO postgres;

--
-- TOC entry 461 (class 1259 OID 26706)
-- Name: item_inventario_id_item_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.item_inventario_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_inventario_id_item_seq OWNER TO postgres;

--
-- TOC entry 8232 (class 0 OID 0)
-- Dependencies: 461
-- Name: item_inventario_id_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.item_inventario_id_item_seq OWNED BY public.item_inventario.id_item;


--
-- TOC entry 454 (class 1259 OID 26638)
-- Name: item_pedido_compra; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_pedido_compra (
    id_item_pedido integer NOT NULL,
    id_pedido integer NOT NULL,
    id_produto_estoque integer NOT NULL,
    quantidade numeric(10,2),
    valor_unitario numeric(15,2),
    valor_total numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.item_pedido_compra OWNER TO postgres;

--
-- TOC entry 453 (class 1259 OID 26637)
-- Name: item_pedido_compra_id_item_pedido_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.item_pedido_compra_id_item_pedido_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_pedido_compra_id_item_pedido_seq OWNER TO postgres;

--
-- TOC entry 8233 (class 0 OID 0)
-- Dependencies: 453
-- Name: item_pedido_compra_id_item_pedido_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.item_pedido_compra_id_item_pedido_seq OWNED BY public.item_pedido_compra.id_item_pedido;


--
-- TOC entry 450 (class 1259 OID 26594)
-- Name: item_requisicao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_requisicao (
    id_item integer NOT NULL,
    id_requisicao integer NOT NULL,
    id_produto_estoque integer NOT NULL,
    quantidade numeric(10,2),
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.item_requisicao OWNER TO postgres;

--
-- TOC entry 449 (class 1259 OID 26593)
-- Name: item_requisicao_id_item_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.item_requisicao_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_requisicao_id_item_seq OWNER TO postgres;

--
-- TOC entry 8234 (class 0 OID 0)
-- Dependencies: 449
-- Name: item_requisicao_id_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.item_requisicao_id_item_seq OWNED BY public.item_requisicao.id_item;


--
-- TOC entry 338 (class 1259 OID 25563)
-- Name: item_venda; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.item_venda (
    id_item integer NOT NULL,
    id_venda integer NOT NULL,
    id_produto integer NOT NULL,
    quantidade integer DEFAULT 1,
    valor_unitario numeric(15,2),
    valor_total numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.item_venda OWNER TO postgres;

--
-- TOC entry 337 (class 1259 OID 25562)
-- Name: item_venda_id_item_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.item_venda_id_item_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.item_venda_id_item_seq OWNER TO postgres;

--
-- TOC entry 8235 (class 0 OID 0)
-- Dependencies: 337
-- Name: item_venda_id_item_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.item_venda_id_item_seq OWNED BY public.item_venda.id_item;


--
-- TOC entry 589 (class 1259 OID 27708)
-- Name: kpi_turismo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.kpi_turismo (
    id_kpi integer NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    descricao text,
    unidade character varying(30),
    categoria character varying(50),
    valor numeric(14,2) DEFAULT 0,
    periodo date,
    origem character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.kpi_turismo OWNER TO postgres;

--
-- TOC entry 588 (class 1259 OID 27707)
-- Name: kpi_turismo_id_kpi_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.kpi_turismo_id_kpi_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.kpi_turismo_id_kpi_seq OWNER TO postgres;

--
-- TOC entry 8236 (class 0 OID 0)
-- Dependencies: 588
-- Name: kpi_turismo_id_kpi_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.kpi_turismo_id_kpi_seq OWNED BY public.kpi_turismo.id_kpi;


--
-- TOC entry 319 (class 1259 OID 25330)
-- Name: lancamento_financeiro; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lancamento_financeiro (
    id_lancamento integer NOT NULL,
    id_empresa integer NOT NULL,
    tipo_lancamento character varying(20) NOT NULL,
    descricao character varying(200) NOT NULL,
    data_lancamento date NOT NULL,
    data_competencia date NOT NULL,
    data_pagamento date,
    valor numeric(15,2) NOT NULL,
    status character varying(30) DEFAULT 'ABERTO'::character varying,
    id_pessoa integer,
    id_conta_bancaria integer,
    id_forma_pagamento integer,
    id_centro_custo integer,
    id_subcategoria integer,
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1,
    id_conta_plano integer,
    id_grupo integer,
    id_categoria integer,
    CONSTRAINT ck_tipo_lancamento CHECK (((tipo_lancamento)::text = ANY ((ARRAY['RECEITA'::character varying, 'DESPESA'::character varying])::text[])))
);


ALTER TABLE public.lancamento_financeiro OWNER TO postgres;

--
-- TOC entry 318 (class 1259 OID 25329)
-- Name: lancamento_financeiro_id_lancamento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lancamento_financeiro_id_lancamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lancamento_financeiro_id_lancamento_seq OWNER TO postgres;

--
-- TOC entry 8237 (class 0 OID 0)
-- Dependencies: 318
-- Name: lancamento_financeiro_id_lancamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lancamento_financeiro_id_lancamento_seq OWNED BY public.lancamento_financeiro.id_lancamento;


--
-- TOC entry 321 (class 1259 OID 25376)
-- Name: lancamento_parcela; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lancamento_parcela (
    id_parcela integer NOT NULL,
    id_lancamento integer NOT NULL,
    numero_parcela integer NOT NULL,
    total_parcelas integer NOT NULL,
    data_vencimento date NOT NULL,
    data_pagamento date,
    valor_parcela numeric(15,2) NOT NULL,
    status character varying(20) DEFAULT 'ABERTO'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1,
    id_status_parcela integer
);


ALTER TABLE public.lancamento_parcela OWNER TO postgres;

--
-- TOC entry 320 (class 1259 OID 25375)
-- Name: lancamento_parcela_id_parcela_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lancamento_parcela_id_parcela_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lancamento_parcela_id_parcela_seq OWNER TO postgres;

--
-- TOC entry 8238 (class 0 OID 0)
-- Dependencies: 320
-- Name: lancamento_parcela_id_parcela_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lancamento_parcela_id_parcela_seq OWNED BY public.lancamento_parcela.id_parcela;


--
-- TOC entry 405 (class 1259 OID 26197)
-- Name: lead; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.lead (
    id_lead integer NOT NULL,
    id_origem integer,
    nome character varying(150) NOT NULL,
    email character varying(150),
    telefone character varying(30),
    cidade character varying(100),
    interesse character varying(150),
    valor_estimado numeric(15,2),
    status character varying(30) DEFAULT 'NOVO'::character varying,
    data_cadastro date DEFAULT CURRENT_DATE,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.lead OWNER TO postgres;

--
-- TOC entry 404 (class 1259 OID 26196)
-- Name: lead_id_lead_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.lead_id_lead_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.lead_id_lead_seq OWNER TO postgres;

--
-- TOC entry 8239 (class 0 OID 0)
-- Dependencies: 404
-- Name: lead_id_lead_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.lead_id_lead_seq OWNED BY public.lead.id_lead;


--
-- TOC entry 601 (class 1259 OID 33391)
-- Name: localidade; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.localidade (
    id_localidade integer NOT NULL,
    cidade character varying(100) NOT NULL,
    uf character(2),
    pais character varying(100) DEFAULT 'Brasil'::character varying NOT NULL
);


ALTER TABLE public.localidade OWNER TO postgres;

--
-- TOC entry 600 (class 1259 OID 33390)
-- Name: localidade_id_localidade_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.localidade ALTER COLUMN id_localidade ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.localidade_id_localidade_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 441 (class 1259 OID 26519)
-- Name: localizacao_ativo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.localizacao_ativo (
    id_localizacao integer NOT NULL,
    codigo character varying(30),
    descricao character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.localizacao_ativo OWNER TO postgres;

--
-- TOC entry 440 (class 1259 OID 26518)
-- Name: localizacao_ativo_id_localizacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.localizacao_ativo_id_localizacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.localizacao_ativo_id_localizacao_seq OWNER TO postgres;

--
-- TOC entry 8240 (class 0 OID 0)
-- Dependencies: 440
-- Name: localizacao_ativo_id_localizacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.localizacao_ativo_id_localizacao_seq OWNED BY public.localizacao_ativo.id_localizacao;


--
-- TOC entry 520 (class 1259 OID 27173)
-- Name: log_api; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log_api (
    id_log integer NOT NULL,
    id_aplicacao integer,
    endpoint character varying(255),
    metodo character varying(20),
    request jsonb,
    response jsonb,
    status_http integer,
    tempo_execucao_ms integer,
    data_execucao timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.log_api OWNER TO postgres;

--
-- TOC entry 519 (class 1259 OID 27172)
-- Name: log_api_id_log_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.log_api_id_log_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_api_id_log_seq OWNER TO postgres;

--
-- TOC entry 8241 (class 0 OID 0)
-- Dependencies: 519
-- Name: log_api_id_log_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_api_id_log_seq OWNED BY public.log_api.id_log;


--
-- TOC entry 367 (class 1259 OID 25877)
-- Name: log_auditoria; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log_auditoria (
    id_log integer NOT NULL,
    tabela_nome character varying(100) NOT NULL,
    registro_id integer,
    acao character varying(20) NOT NULL,
    usuario character varying(100),
    data_evento timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    dados_antigos jsonb,
    dados_novos jsonb,
    CONSTRAINT ck_log_acao CHECK (((acao)::text = ANY ((ARRAY['INSERT'::character varying, 'UPDATE'::character varying, 'DELETE'::character varying])::text[])))
);


ALTER TABLE public.log_auditoria OWNER TO postgres;

--
-- TOC entry 366 (class 1259 OID 25876)
-- Name: log_auditoria_id_log_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.log_auditoria_id_log_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_auditoria_id_log_seq OWNER TO postgres;

--
-- TOC entry 8242 (class 0 OID 0)
-- Dependencies: 366
-- Name: log_auditoria_id_log_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_auditoria_id_log_seq OWNED BY public.log_auditoria.id_log;


--
-- TOC entry 385 (class 1259 OID 26020)
-- Name: log_integracao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log_integracao (
    id_log integer NOT NULL,
    sistema character varying(100),
    endpoint character varying(255),
    metodo character varying(20),
    request jsonb,
    response jsonb,
    status_http integer,
    data_execucao timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.log_integracao OWNER TO postgres;

--
-- TOC entry 567 (class 1259 OID 27519)
-- Name: log_integracao_detalhado; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log_integracao_detalhado (
    id_log_integracao integer NOT NULL,
    id_conector integer NOT NULL,
    id_sincronizacao integer,
    tipo_operacao character varying(50) NOT NULL,
    endpoint text,
    metodo_http character varying(20),
    requisicao jsonb,
    resposta jsonb,
    codigo_http integer,
    tempo_resposta_ms integer,
    status character varying(30) DEFAULT 'PROCESSANDO'::character varying,
    mensagem_erro text,
    data_execucao timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.log_integracao_detalhado OWNER TO postgres;

--
-- TOC entry 566 (class 1259 OID 27518)
-- Name: log_integracao_detalhado_id_log_integracao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.log_integracao_detalhado_id_log_integracao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_integracao_detalhado_id_log_integracao_seq OWNER TO postgres;

--
-- TOC entry 8243 (class 0 OID 0)
-- Dependencies: 566
-- Name: log_integracao_detalhado_id_log_integracao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_integracao_detalhado_id_log_integracao_seq OWNED BY public.log_integracao_detalhado.id_log_integracao;


--
-- TOC entry 384 (class 1259 OID 26019)
-- Name: log_integracao_id_log_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.log_integracao_id_log_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_integracao_id_log_seq OWNER TO postgres;

--
-- TOC entry 8244 (class 0 OID 0)
-- Dependencies: 384
-- Name: log_integracao_id_log_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_integracao_id_log_seq OWNED BY public.log_integracao.id_log;


--
-- TOC entry 505 (class 1259 OID 27063)
-- Name: log_sistema; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log_sistema (
    id_log integer NOT NULL,
    nivel character varying(20),
    modulo character varying(100),
    mensagem text,
    stack_trace text,
    usuario character varying(100),
    data_evento timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.log_sistema OWNER TO postgres;

--
-- TOC entry 504 (class 1259 OID 27062)
-- Name: log_sistema_id_log_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.log_sistema_id_log_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_sistema_id_log_seq OWNER TO postgres;

--
-- TOC entry 8245 (class 0 OID 0)
-- Dependencies: 504
-- Name: log_sistema_id_log_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_sistema_id_log_seq OWNED BY public.log_sistema.id_log;


--
-- TOC entry 439 (class 1259 OID 26500)
-- Name: manutencao_ativo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.manutencao_ativo (
    id_manutencao integer NOT NULL,
    id_ativo integer NOT NULL,
    data_manutencao date,
    tipo character varying(50),
    descricao text,
    valor numeric(15,2),
    fornecedor character varying(150),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.manutencao_ativo OWNER TO postgres;

--
-- TOC entry 438 (class 1259 OID 26499)
-- Name: manutencao_ativo_id_manutencao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.manutencao_ativo_id_manutencao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.manutencao_ativo_id_manutencao_seq OWNER TO postgres;

--
-- TOC entry 8246 (class 0 OID 0)
-- Dependencies: 438
-- Name: manutencao_ativo_id_manutencao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.manutencao_ativo_id_manutencao_seq OWNED BY public.manutencao_ativo.id_manutencao;


--
-- TOC entry 561 (class 1259 OID 27444)
-- Name: mapeamento_campo_integracao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.mapeamento_campo_integracao (
    id_mapeamento integer NOT NULL,
    id_conector integer NOT NULL,
    entidade_interna character varying(100) NOT NULL,
    campo_interno character varying(100) NOT NULL,
    entidade_externa character varying(100),
    campo_externo character varying(150) NOT NULL,
    tipo_dado character varying(50),
    regra_transformacao text,
    obrigatorio boolean DEFAULT false,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.mapeamento_campo_integracao OWNER TO postgres;

--
-- TOC entry 560 (class 1259 OID 27443)
-- Name: mapeamento_campo_integracao_id_mapeamento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.mapeamento_campo_integracao_id_mapeamento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.mapeamento_campo_integracao_id_mapeamento_seq OWNER TO postgres;

--
-- TOC entry 8247 (class 0 OID 0)
-- Dependencies: 560
-- Name: mapeamento_campo_integracao_id_mapeamento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.mapeamento_campo_integracao_id_mapeamento_seq OWNED BY public.mapeamento_campo_integracao.id_mapeamento;


--
-- TOC entry 546 (class 1259 OID 27306)
-- Name: modelo_ml; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.modelo_ml (
    id_modelo integer NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    tipo_modelo character varying(50),
    algoritmo character varying(100),
    versao_modelo character varying(30),
    status character varying(30) DEFAULT 'DESENVOLVIMENTO'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.modelo_ml OWNER TO postgres;

--
-- TOC entry 545 (class 1259 OID 27305)
-- Name: modelo_ml_id_modelo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.modelo_ml_id_modelo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.modelo_ml_id_modelo_seq OWNER TO postgres;

--
-- TOC entry 8248 (class 0 OID 0)
-- Dependencies: 545
-- Name: modelo_ml_id_modelo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.modelo_ml_id_modelo_seq OWNED BY public.modelo_ml.id_modelo;


--
-- TOC entry 443 (class 1259 OID 26531)
-- Name: movimentacao_ativo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movimentacao_ativo (
    id_movimentacao integer NOT NULL,
    id_ativo integer NOT NULL,
    id_localizacao integer,
    tipo_movimento character varying(50),
    data_movimento date,
    responsavel character varying(100),
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.movimentacao_ativo OWNER TO postgres;

--
-- TOC entry 442 (class 1259 OID 26530)
-- Name: movimentacao_ativo_id_movimentacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.movimentacao_ativo_id_movimentacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.movimentacao_ativo_id_movimentacao_seq OWNER TO postgres;

--
-- TOC entry 8249 (class 0 OID 0)
-- Dependencies: 442
-- Name: movimentacao_ativo_id_movimentacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.movimentacao_ativo_id_movimentacao_seq OWNED BY public.movimentacao_ativo.id_movimentacao;


--
-- TOC entry 458 (class 1259 OID 26676)
-- Name: movimento_estoque; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.movimento_estoque (
    id_movimento integer NOT NULL,
    id_produto_estoque integer NOT NULL,
    tipo_movimento character varying(20),
    quantidade numeric(10,2),
    origem character varying(100),
    data_movimento date DEFAULT CURRENT_DATE,
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ck_tipo_movimento CHECK (((tipo_movimento)::text = ANY ((ARRAY['ENTRADA'::character varying, 'SAIDA'::character varying, 'AJUSTE'::character varying])::text[])))
);


ALTER TABLE public.movimento_estoque OWNER TO postgres;

--
-- TOC entry 457 (class 1259 OID 26675)
-- Name: movimento_estoque_id_movimento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.movimento_estoque_id_movimento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.movimento_estoque_id_movimento_seq OWNER TO postgres;

--
-- TOC entry 8250 (class 0 OID 0)
-- Dependencies: 457
-- Name: movimento_estoque_id_movimento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.movimento_estoque_id_movimento_seq OWNED BY public.movimento_estoque.id_movimento;


--
-- TOC entry 340 (class 1259 OID 25586)
-- Name: nota_fiscal; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.nota_fiscal (
    id_nota_fiscal integer NOT NULL,
    id_empresa integer NOT NULL,
    id_cliente integer,
    numero_nf character varying(30),
    serie character varying(10),
    tipo_documento character varying(30),
    data_emissao date NOT NULL,
    competencia date NOT NULL,
    valor_servico numeric(15,2),
    base_calculo numeric(15,2),
    valor_iss numeric(15,2),
    status character varying(30) DEFAULT 'EMITIDA'::character varying,
    chave_acesso character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.nota_fiscal OWNER TO postgres;

--
-- TOC entry 339 (class 1259 OID 25585)
-- Name: nota_fiscal_id_nota_fiscal_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.nota_fiscal_id_nota_fiscal_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.nota_fiscal_id_nota_fiscal_seq OWNER TO postgres;

--
-- TOC entry 8251 (class 0 OID 0)
-- Dependencies: 339
-- Name: nota_fiscal_id_nota_fiscal_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.nota_fiscal_id_nota_fiscal_seq OWNED BY public.nota_fiscal.id_nota_fiscal;


--
-- TOC entry 501 (class 1259 OID 27033)
-- Name: notificacao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notificacao (
    id_notificacao integer NOT NULL,
    id_usuario integer,
    titulo character varying(150),
    mensagem text,
    tipo character varying(30),
    lida boolean DEFAULT false,
    data_envio timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.notificacao OWNER TO postgres;

--
-- TOC entry 500 (class 1259 OID 27032)
-- Name: notificacao_id_notificacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.notificacao_id_notificacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.notificacao_id_notificacao_seq OWNER TO postgres;

--
-- TOC entry 8252 (class 0 OID 0)
-- Dependencies: 500
-- Name: notificacao_id_notificacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.notificacao_id_notificacao_seq OWNED BY public.notificacao.id_notificacao;


--
-- TOC entry 377 (class 1259 OID 25958)
-- Name: openfinance_conexao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.openfinance_conexao (
    id_conexao integer NOT NULL,
    id_empresa integer NOT NULL,
    instituicao character varying(100),
    token_api text,
    data_expiracao timestamp without time zone,
    status character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.openfinance_conexao OWNER TO postgres;

--
-- TOC entry 376 (class 1259 OID 25957)
-- Name: openfinance_conexao_id_conexao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.openfinance_conexao_id_conexao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.openfinance_conexao_id_conexao_seq OWNER TO postgres;

--
-- TOC entry 8253 (class 0 OID 0)
-- Dependencies: 376
-- Name: openfinance_conexao_id_conexao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.openfinance_conexao_id_conexao_seq OWNED BY public.openfinance_conexao.id_conexao;


--
-- TOC entry 379 (class 1259 OID 25976)
-- Name: openfinance_movimento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.openfinance_movimento (
    id_movimento integer NOT NULL,
    id_conexao integer,
    data_movimento date,
    descricao character varying(200),
    valor numeric(15,2),
    tipo character varying(20),
    conciliado boolean DEFAULT false,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.openfinance_movimento OWNER TO postgres;

--
-- TOC entry 378 (class 1259 OID 25975)
-- Name: openfinance_movimento_id_movimento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.openfinance_movimento_id_movimento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.openfinance_movimento_id_movimento_seq OWNER TO postgres;

--
-- TOC entry 8254 (class 0 OID 0)
-- Dependencies: 378
-- Name: openfinance_movimento_id_movimento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.openfinance_movimento_id_movimento_seq OWNED BY public.openfinance_movimento.id_movimento;


--
-- TOC entry 403 (class 1259 OID 26181)
-- Name: origem_lead; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.origem_lead (
    id_origem integer NOT NULL,
    codigo character varying(30) NOT NULL,
    descricao character varying(100) NOT NULL,
    tipo character varying(50),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.origem_lead OWNER TO postgres;

--
-- TOC entry 402 (class 1259 OID 26180)
-- Name: origem_lead_id_origem_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.origem_lead_id_origem_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.origem_lead_id_origem_seq OWNER TO postgres;

--
-- TOC entry 8255 (class 0 OID 0)
-- Dependencies: 402
-- Name: origem_lead_id_origem_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.origem_lead_id_origem_seq OWNED BY public.origem_lead.id_origem;


--
-- TOC entry 328 (class 1259 OID 25451)
-- Name: pacote_viagem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pacote_viagem (
    id_pacote integer NOT NULL,
    id_produto integer NOT NULL,
    codigo_pacote character varying(30),
    data_inicio date,
    data_fim date,
    quantidade_vagas integer,
    valor_venda numeric(15,2),
    custo_estimado numeric(15,2),
    status character varying(30) DEFAULT 'ATIVO'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1,
    CONSTRAINT ck_periodo_pacote CHECK ((data_fim >= data_inicio))
);


ALTER TABLE public.pacote_viagem OWNER TO postgres;

--
-- TOC entry 327 (class 1259 OID 25450)
-- Name: pacote_viagem_id_pacote_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pacote_viagem_id_pacote_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pacote_viagem_id_pacote_seq OWNER TO postgres;

--
-- TOC entry 8256 (class 0 OID 0)
-- Dependencies: 327
-- Name: pacote_viagem_id_pacote_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pacote_viagem_id_pacote_seq OWNED BY public.pacote_viagem.id_pacote;


--
-- TOC entry 375 (class 1259 OID 25937)
-- Name: pagamento_transacao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pagamento_transacao (
    id_transacao integer NOT NULL,
    id_venda integer NOT NULL,
    id_gateway integer,
    codigo_transacao character varying(100),
    valor numeric(15,2),
    status character varying(30),
    data_pagamento timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.pagamento_transacao OWNER TO postgres;

--
-- TOC entry 374 (class 1259 OID 25936)
-- Name: pagamento_transacao_id_transacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pagamento_transacao_id_transacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pagamento_transacao_id_transacao_seq OWNER TO postgres;

--
-- TOC entry 8257 (class 0 OID 0)
-- Dependencies: 374
-- Name: pagamento_transacao_id_transacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pagamento_transacao_id_transacao_seq OWNED BY public.pagamento_transacao.id_transacao;


--
-- TOC entry 495 (class 1259 OID 26986)
-- Name: parametro_sistema; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parametro_sistema (
    id_parametro integer NOT NULL,
    codigo character varying(50) NOT NULL,
    descricao character varying(150),
    valor character varying(255),
    tipo character varying(30),
    grupo character varying(50),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.parametro_sistema OWNER TO postgres;

--
-- TOC entry 494 (class 1259 OID 26985)
-- Name: parametro_sistema_id_parametro_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parametro_sistema_id_parametro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parametro_sistema_id_parametro_seq OWNER TO postgres;

--
-- TOC entry 8258 (class 0 OID 0)
-- Dependencies: 494
-- Name: parametro_sistema_id_parametro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parametro_sistema_id_parametro_seq OWNED BY public.parametro_sistema.id_parametro;


--
-- TOC entry 422 (class 1259 OID 26347)
-- Name: parceiro_comercial; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parceiro_comercial (
    id_parceiro integer NOT NULL,
    nome character varying(150) NOT NULL,
    documento character varying(30),
    telefone character varying(30),
    email character varying(150),
    percentual_comissao numeric(5,2),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.parceiro_comercial OWNER TO postgres;

--
-- TOC entry 421 (class 1259 OID 26346)
-- Name: parceiro_comercial_id_parceiro_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parceiro_comercial_id_parceiro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parceiro_comercial_id_parceiro_seq OWNER TO postgres;

--
-- TOC entry 8259 (class 0 OID 0)
-- Dependencies: 421
-- Name: parceiro_comercial_id_parceiro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parceiro_comercial_id_parceiro_seq OWNED BY public.parceiro_comercial.id_parceiro;


--
-- TOC entry 332 (class 1259 OID 25499)
-- Name: passageiro; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.passageiro (
    id_passageiro integer NOT NULL,
    id_reserva integer NOT NULL,
    nome character varying(150) NOT NULL,
    cpf character varying(14),
    data_nascimento date,
    documento character varying(30),
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.passageiro OWNER TO postgres;

--
-- TOC entry 331 (class 1259 OID 25498)
-- Name: passageiro_id_passageiro_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.passageiro_id_passageiro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.passageiro_id_passageiro_seq OWNER TO postgres;

--
-- TOC entry 8260 (class 0 OID 0)
-- Dependencies: 331
-- Name: passageiro_id_passageiro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.passageiro_id_passageiro_seq OWNED BY public.passageiro.id_passageiro;


--
-- TOC entry 452 (class 1259 OID 26617)
-- Name: pedido_compra; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pedido_compra (
    id_pedido integer NOT NULL,
    numero_pedido character varying(30),
    id_fornecedor integer NOT NULL,
    data_pedido date DEFAULT CURRENT_DATE,
    valor_total numeric(15,2),
    status character varying(30) DEFAULT 'PENDENTE'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.pedido_compra OWNER TO postgres;

--
-- TOC entry 451 (class 1259 OID 26616)
-- Name: pedido_compra_id_pedido_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pedido_compra_id_pedido_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pedido_compra_id_pedido_seq OWNER TO postgres;

--
-- TOC entry 8261 (class 0 OID 0)
-- Dependencies: 451
-- Name: pedido_compra_id_pedido_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pedido_compra_id_pedido_seq OWNED BY public.pedido_compra.id_pedido;


--
-- TOC entry 362 (class 1259 OID 25827)
-- Name: perfil_acesso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.perfil_acesso (
    id_perfil integer NOT NULL,
    codigo character varying(30) NOT NULL,
    descricao character varying(100) NOT NULL,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.perfil_acesso OWNER TO postgres;

--
-- TOC entry 361 (class 1259 OID 25826)
-- Name: perfil_acesso_id_perfil_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.perfil_acesso_id_perfil_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.perfil_acesso_id_perfil_seq OWNER TO postgres;

--
-- TOC entry 8262 (class 0 OID 0)
-- Dependencies: 361
-- Name: perfil_acesso_id_perfil_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.perfil_acesso_id_perfil_seq OWNED BY public.perfil_acesso.id_perfil;


--
-- TOC entry 364 (class 1259 OID 25843)
-- Name: permissao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.permissao (
    id_permissao integer NOT NULL,
    codigo character varying(50) NOT NULL,
    descricao character varying(150) NOT NULL,
    modulo character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.permissao OWNER TO postgres;

--
-- TOC entry 363 (class 1259 OID 25842)
-- Name: permissao_id_permissao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.permissao_id_permissao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.permissao_id_permissao_seq OWNER TO postgres;

--
-- TOC entry 8263 (class 0 OID 0)
-- Dependencies: 363
-- Name: permissao_id_permissao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.permissao_id_permissao_seq OWNED BY public.permissao.id_permissao;


--
-- TOC entry 295 (class 1259 OID 25108)
-- Name: pessoa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pessoa (
    id_pessoa integer NOT NULL,
    tipo_pessoa character varying(20) NOT NULL,
    nome_razao_social character varying(150) NOT NULL,
    nome_fantasia character varying(100),
    cpf_cnpj character varying(18),
    rg_ie character varying(30),
    data_nascimento date,
    telefone character varying(30),
    email character varying(150),
    logradouro character varying(150),
    numero character varying(20),
    bairro character varying(100),
    cep character varying(10),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1,
    id_localidade integer NOT NULL,
    CONSTRAINT ck_tipo_pessoa CHECK (((tipo_pessoa)::text = ANY ((ARRAY['FISICA'::character varying, 'JURIDICA'::character varying])::text[])))
);


ALTER TABLE public.pessoa OWNER TO postgres;

--
-- TOC entry 294 (class 1259 OID 25107)
-- Name: pessoa_id_pessoa_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pessoa_id_pessoa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pessoa_id_pessoa_seq OWNER TO postgres;

--
-- TOC entry 8264 (class 0 OID 0)
-- Dependencies: 294
-- Name: pessoa_id_pessoa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pessoa_id_pessoa_seq OWNED BY public.pessoa.id_pessoa;


--
-- TOC entry 303 (class 1259 OID 25178)
-- Name: plano_contas; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.plano_contas (
    id_conta integer NOT NULL,
    codigo character varying(20) NOT NULL,
    nivel integer NOT NULL,
    descricao character varying(150) NOT NULL,
    id_conta_pai integer,
    natureza character varying(20),
    tipo_conta character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.plano_contas OWNER TO postgres;

--
-- TOC entry 302 (class 1259 OID 25177)
-- Name: plano_contas_id_conta_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.plano_contas_id_conta_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.plano_contas_id_conta_seq OWNER TO postgres;

--
-- TOC entry 8265 (class 0 OID 0)
-- Dependencies: 302
-- Name: plano_contas_id_conta_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.plano_contas_id_conta_seq OWNED BY public.plano_contas.id_conta;


--
-- TOC entry 550 (class 1259 OID 27343)
-- Name: politica_acesso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.politica_acesso (
    id_politica integer NOT NULL,
    codigo character varying(50) NOT NULL,
    descricao character varying(150),
    modulo character varying(100),
    acao character varying(50),
    nivel character varying(30),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.politica_acesso OWNER TO postgres;

--
-- TOC entry 549 (class 1259 OID 27342)
-- Name: politica_acesso_id_politica_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.politica_acesso_id_politica_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.politica_acesso_id_politica_seq OWNER TO postgres;

--
-- TOC entry 8266 (class 0 OID 0)
-- Dependencies: 549
-- Name: politica_acesso_id_politica_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.politica_acesso_id_politica_seq OWNED BY public.politica_acesso.id_politica;


--
-- TOC entry 352 (class 1259 OID 25731)
-- Name: pro_labore; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.pro_labore (
    id_pro_labore integer NOT NULL,
    id_empresa integer NOT NULL,
    competencia date,
    socio character varying(150),
    valor_bruto numeric(15,2),
    inss numeric(15,2),
    irrf numeric(15,2),
    valor_liquido numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.pro_labore OWNER TO postgres;

--
-- TOC entry 351 (class 1259 OID 25730)
-- Name: pro_labore_id_pro_labore_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.pro_labore_id_pro_labore_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.pro_labore_id_pro_labore_seq OWNER TO postgres;

--
-- TOC entry 8267 (class 0 OID 0)
-- Dependencies: 351
-- Name: pro_labore_id_pro_labore_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.pro_labore_id_pro_labore_seq OWNED BY public.pro_labore.id_pro_labore;


--
-- TOC entry 446 (class 1259 OID 26558)
-- Name: produto_estoque; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.produto_estoque (
    id_produto_estoque integer NOT NULL,
    codigo character varying(30) NOT NULL,
    descricao character varying(150) NOT NULL,
    categoria character varying(50),
    unidade_medida character varying(20),
    estoque_minimo numeric(10,2) DEFAULT 0,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.produto_estoque OWNER TO postgres;

--
-- TOC entry 445 (class 1259 OID 26557)
-- Name: produto_estoque_id_produto_estoque_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.produto_estoque_id_produto_estoque_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.produto_estoque_id_produto_estoque_seq OWNER TO postgres;

--
-- TOC entry 8268 (class 0 OID 0)
-- Dependencies: 445
-- Name: produto_estoque_id_produto_estoque_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.produto_estoque_id_produto_estoque_seq OWNED BY public.produto_estoque.id_produto_estoque;


--
-- TOC entry 326 (class 1259 OID 25431)
-- Name: produto_turistico; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.produto_turistico (
    id_produto integer NOT NULL,
    codigo character varying(20) NOT NULL,
    nome character varying(150) NOT NULL,
    tipo_produto character varying(50) NOT NULL,
    descricao text,
    duracao_dias integer,
    destino character varying(150),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1,
    CONSTRAINT ck_tipo_produto CHECK (((tipo_produto)::text = ANY ((ARRAY['PACOTE'::character varying, 'EXCURSAO'::character varying, 'CICLOTURISMO'::character varying, 'HOSPEDAGEM'::character varying, 'INGRESSO'::character varying, 'OUTRO'::character varying])::text[])))
);


ALTER TABLE public.produto_turistico OWNER TO postgres;

--
-- TOC entry 325 (class 1259 OID 25430)
-- Name: produto_turistico_id_produto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.produto_turistico_id_produto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.produto_turistico_id_produto_seq OWNER TO postgres;

--
-- TOC entry 8269 (class 0 OID 0)
-- Dependencies: 325
-- Name: produto_turistico_id_produto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.produto_turistico_id_produto_seq OWNED BY public.produto_turistico.id_produto;


--
-- TOC entry 480 (class 1259 OID 26857)
-- Name: projeto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.projeto (
    id_projeto integer NOT NULL,
    codigo character varying(30) NOT NULL,
    nome character varying(200) NOT NULL,
    descricao text,
    tipo_projeto character varying(50),
    data_inicio date,
    data_fim_prevista date,
    data_fim_real date,
    status character varying(30) DEFAULT 'PLANEJAMENTO'::character varying,
    orcamento numeric(15,2),
    responsavel character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.projeto OWNER TO postgres;

--
-- TOC entry 479 (class 1259 OID 26856)
-- Name: projeto_id_projeto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.projeto_id_projeto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.projeto_id_projeto_seq OWNER TO postgres;

--
-- TOC entry 8270 (class 0 OID 0)
-- Dependencies: 479
-- Name: projeto_id_projeto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.projeto_id_projeto_seq OWNED BY public.projeto.id_projeto;


--
-- TOC entry 552 (class 1259 OID 27360)
-- Name: rastreabilidade; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rastreabilidade (
    id_rastreabilidade integer NOT NULL,
    origem character varying(100),
    evento character varying(100),
    referencia character varying(100),
    descricao text,
    usuario character varying(100),
    data_evento timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    versao integer DEFAULT 1
);


ALTER TABLE public.rastreabilidade OWNER TO postgres;

--
-- TOC entry 551 (class 1259 OID 27359)
-- Name: rastreabilidade_id_rastreabilidade_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rastreabilidade_id_rastreabilidade_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rastreabilidade_id_rastreabilidade_seq OWNER TO postgres;

--
-- TOC entry 8271 (class 0 OID 0)
-- Dependencies: 551
-- Name: rastreabilidade_id_rastreabilidade_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rastreabilidade_id_rastreabilidade_seq OWNED BY public.rastreabilidade.id_rastreabilidade;


--
-- TOC entry 522 (class 1259 OID 27190)
-- Name: rate_limit_api; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rate_limit_api (
    id_rate integer NOT NULL,
    id_aplicacao integer NOT NULL,
    limite_requisicoes integer,
    periodo_segundos integer,
    ativo boolean DEFAULT true
);


ALTER TABLE public.rate_limit_api OWNER TO postgres;

--
-- TOC entry 521 (class 1259 OID 27189)
-- Name: rate_limit_api_id_rate_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rate_limit_api_id_rate_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rate_limit_api_id_rate_seq OWNER TO postgres;

--
-- TOC entry 8272 (class 0 OID 0)
-- Dependencies: 521
-- Name: rate_limit_api_id_rate_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rate_limit_api_id_rate_seq OWNED BY public.rate_limit_api.id_rate;


--
-- TOC entry 592 (class 1259 OID 27730)
-- Name: rentabilidade_produto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.rentabilidade_produto (
    id_rentabilidade integer NOT NULL,
    periodo date NOT NULL,
    id_produto_origem integer,
    id_destino_origem integer,
    receita_total numeric(14,2) DEFAULT 0,
    custo_total numeric(14,2) DEFAULT 0,
    comissao_total numeric(14,2) DEFAULT 0,
    lucro_bruto numeric(14,2) DEFAULT 0,
    margem_percentual numeric(6,2) DEFAULT 0,
    quantidade_vendida integer DEFAULT 0,
    roi_percentual numeric(6,2) DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.rentabilidade_produto OWNER TO postgres;

--
-- TOC entry 591 (class 1259 OID 27729)
-- Name: rentabilidade_produto_id_rentabilidade_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.rentabilidade_produto_id_rentabilidade_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.rentabilidade_produto_id_rentabilidade_seq OWNER TO postgres;

--
-- TOC entry 8273 (class 0 OID 0)
-- Dependencies: 591
-- Name: rentabilidade_produto_id_rentabilidade_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.rentabilidade_produto_id_rentabilidade_seq OWNED BY public.rentabilidade_produto.id_rentabilidade;


--
-- TOC entry 448 (class 1259 OID 26577)
-- Name: requisicao_compra; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.requisicao_compra (
    id_requisicao integer NOT NULL,
    numero_requisicao character varying(30),
    data_solicitacao date DEFAULT CURRENT_DATE,
    solicitante character varying(100),
    status character varying(30) DEFAULT 'ABERTA'::character varying,
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.requisicao_compra OWNER TO postgres;

--
-- TOC entry 447 (class 1259 OID 26576)
-- Name: requisicao_compra_id_requisicao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.requisicao_compra_id_requisicao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.requisicao_compra_id_requisicao_seq OWNER TO postgres;

--
-- TOC entry 8274 (class 0 OID 0)
-- Dependencies: 447
-- Name: requisicao_compra_id_requisicao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.requisicao_compra_id_requisicao_seq OWNED BY public.requisicao_compra.id_requisicao;


--
-- TOC entry 330 (class 1259 OID 25471)
-- Name: reserva; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reserva (
    id_reserva integer NOT NULL,
    codigo_reserva character varying(30) NOT NULL,
    id_cliente integer NOT NULL,
    id_pacote integer NOT NULL,
    data_reserva date NOT NULL,
    quantidade_passageiros integer DEFAULT 1,
    valor_total numeric(15,2),
    status character varying(30) DEFAULT 'PENDENTE'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.reserva OWNER TO postgres;

--
-- TOC entry 329 (class 1259 OID 25470)
-- Name: reserva_id_reserva_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reserva_id_reserva_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reserva_id_reserva_seq OWNER TO postgres;

--
-- TOC entry 8275 (class 0 OID 0)
-- Dependencies: 329
-- Name: reserva_id_reserva_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reserva_id_reserva_seq OWNED BY public.reserva.id_reserva;


--
-- TOC entry 486 (class 1259 OID 26913)
-- Name: responsavel_projeto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.responsavel_projeto (
    id_responsavel integer NOT NULL,
    id_projeto integer NOT NULL,
    id_colaborador integer,
    papel character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.responsavel_projeto OWNER TO postgres;

--
-- TOC entry 485 (class 1259 OID 26912)
-- Name: responsavel_projeto_id_responsavel_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.responsavel_projeto_id_responsavel_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.responsavel_projeto_id_responsavel_seq OWNER TO postgres;

--
-- TOC entry 8276 (class 0 OID 0)
-- Dependencies: 485
-- Name: responsavel_projeto_id_responsavel_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.responsavel_projeto_id_responsavel_seq OWNED BY public.responsavel_projeto.id_responsavel;


--
-- TOC entry 490 (class 1259 OID 26948)
-- Name: risco_projeto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.risco_projeto (
    id_risco integer NOT NULL,
    id_projeto integer NOT NULL,
    descricao text,
    probabilidade character varying(20),
    impacto character varying(20),
    acao_mitigacao text,
    status character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.risco_projeto OWNER TO postgres;

--
-- TOC entry 489 (class 1259 OID 26947)
-- Name: risco_projeto_id_risco_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.risco_projeto_id_risco_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.risco_projeto_id_risco_seq OWNER TO postgres;

--
-- TOC entry 8277 (class 0 OID 0)
-- Dependencies: 489
-- Name: risco_projeto_id_risco_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.risco_projeto_id_risco_seq OWNED BY public.risco_projeto.id_risco;


--
-- TOC entry 389 (class 1259 OID 26051)
-- Name: roteiro_viagem; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.roteiro_viagem (
    id_roteiro integer NOT NULL,
    id_pacote integer NOT NULL,
    id_destino integer NOT NULL,
    titulo character varying(150),
    descricao text,
    dia_inicio date,
    dia_fim date,
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.roteiro_viagem OWNER TO postgres;

--
-- TOC entry 388 (class 1259 OID 26050)
-- Name: roteiro_viagem_id_roteiro_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.roteiro_viagem_id_roteiro_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.roteiro_viagem_id_roteiro_seq OWNER TO postgres;

--
-- TOC entry 8278 (class 0 OID 0)
-- Dependencies: 388
-- Name: roteiro_viagem_id_roteiro_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.roteiro_viagem_id_roteiro_seq OWNED BY public.roteiro_viagem.id_roteiro;


--
-- TOC entry 499 (class 1259 OID 27021)
-- Name: sequencia_documento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sequencia_documento (
    id_sequencia integer NOT NULL,
    tipo_documento character varying(50),
    ano integer,
    proximo_numero integer DEFAULT 1,
    prefixo character varying(20),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone
);


ALTER TABLE public.sequencia_documento OWNER TO postgres;

--
-- TOC entry 498 (class 1259 OID 27020)
-- Name: sequencia_documento_id_sequencia_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sequencia_documento_id_sequencia_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sequencia_documento_id_sequencia_seq OWNER TO postgres;

--
-- TOC entry 8279 (class 0 OID 0)
-- Dependencies: 498
-- Name: sequencia_documento_id_sequencia_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sequencia_documento_id_sequencia_seq OWNED BY public.sequencia_documento.id_sequencia;


--
-- TOC entry 344 (class 1259 OID 25624)
-- Name: simples_nacional; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.simples_nacional (
    id_simples integer NOT NULL,
    id_empresa integer NOT NULL,
    ano integer NOT NULL,
    anexo character varying(10),
    aliquota_efetiva numeric(5,2),
    faturamento_12_meses numeric(15,2),
    faixa integer,
    rbt12 numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.simples_nacional OWNER TO postgres;

--
-- TOC entry 343 (class 1259 OID 25623)
-- Name: simples_nacional_id_simples_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.simples_nacional_id_simples_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.simples_nacional_id_simples_seq OWNER TO postgres;

--
-- TOC entry 8280 (class 0 OID 0)
-- Dependencies: 343
-- Name: simples_nacional_id_simples_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.simples_nacional_id_simples_seq OWNED BY public.simples_nacional.id_simples;


--
-- TOC entry 563 (class 1259 OID 27468)
-- Name: sincronizacao_integracao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sincronizacao_integracao (
    id_sincronizacao integer NOT NULL,
    id_conector integer NOT NULL,
    tipo_operacao character varying(30) NOT NULL,
    entidade character varying(100),
    data_inicio timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    data_fim timestamp without time zone,
    quantidade_processada integer DEFAULT 0,
    quantidade_sucesso integer DEFAULT 0,
    quantidade_erro integer DEFAULT 0,
    status character varying(30) DEFAULT 'PROCESSANDO'::character varying,
    mensagem_retorno text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.sincronizacao_integracao OWNER TO postgres;

--
-- TOC entry 562 (class 1259 OID 27467)
-- Name: sincronizacao_integracao_id_sincronizacao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sincronizacao_integracao_id_sincronizacao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sincronizacao_integracao_id_sincronizacao_seq OWNER TO postgres;

--
-- TOC entry 8281 (class 0 OID 0)
-- Dependencies: 562
-- Name: sincronizacao_integracao_id_sincronizacao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sincronizacao_integracao_id_sincronizacao_seq OWNED BY public.sincronizacao_integracao.id_sincronizacao;


--
-- TOC entry 557 (class 1259 OID 27397)
-- Name: sistema_externo; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.sistema_externo (
    id_sistema_externo integer NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    tipo_sistema character varying(50) NOT NULL,
    fornecedor character varying(150),
    url_api text,
    ambiente character varying(30) DEFAULT 'PRODUCAO'::character varying,
    autenticacao character varying(50),
    ativo boolean DEFAULT true,
    observacao text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.sistema_externo OWNER TO postgres;

--
-- TOC entry 556 (class 1259 OID 27396)
-- Name: sistema_externo_id_sistema_externo_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.sistema_externo_id_sistema_externo_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.sistema_externo_id_sistema_externo_seq OWNER TO postgres;

--
-- TOC entry 8282 (class 0 OID 0)
-- Dependencies: 556
-- Name: sistema_externo_id_sistema_externo_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.sistema_externo_id_sistema_externo_seq OWNED BY public.sistema_externo.id_sistema_externo;


--
-- TOC entry 569 (class 1259 OID 27547)
-- Name: status_integracao; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.status_integracao (
    id_status_integracao integer NOT NULL,
    id_conector integer NOT NULL,
    ultima_execucao timestamp without time zone,
    ultima_situacao character varying(30),
    total_execucoes integer DEFAULT 0,
    total_sucesso integer DEFAULT 0,
    total_erro integer DEFAULT 0,
    percentual_sucesso numeric(5,2) DEFAULT 0,
    tempo_medio_resposta_ms integer DEFAULT 0,
    disponivel boolean DEFAULT true,
    mensagem_status text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.status_integracao OWNER TO postgres;

--
-- TOC entry 568 (class 1259 OID 27546)
-- Name: status_integracao_id_status_integracao_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.status_integracao_id_status_integracao_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.status_integracao_id_status_integracao_seq OWNER TO postgres;

--
-- TOC entry 8283 (class 0 OID 0)
-- Dependencies: 568
-- Name: status_integracao_id_status_integracao_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.status_integracao_id_status_integracao_seq OWNED BY public.status_integracao.id_status_integracao;


--
-- TOC entry 604 (class 1259 OID 33438)
-- Name: status_parcela; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.status_parcela (
    id_status_parcela integer NOT NULL,
    codigo character varying(20) NOT NULL,
    descricao character varying(60) NOT NULL
);


ALTER TABLE public.status_parcela OWNER TO postgres;

--
-- TOC entry 603 (class 1259 OID 33437)
-- Name: status_parcela_id_status_parcela_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.status_parcela ALTER COLUMN id_status_parcela ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.status_parcela_id_status_parcela_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 309 (class 1259 OID 25238)
-- Name: subcategoria_conta; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.subcategoria_conta (
    id_subcategoria integer NOT NULL,
    id_categoria integer NOT NULL,
    codigo character varying(20) NOT NULL,
    descricao character varying(150) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.subcategoria_conta OWNER TO postgres;

--
-- TOC entry 308 (class 1259 OID 25237)
-- Name: subcategoria_conta_id_subcategoria_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.subcategoria_conta_id_subcategoria_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.subcategoria_conta_id_subcategoria_seq OWNER TO postgres;

--
-- TOC entry 8284 (class 0 OID 0)
-- Dependencies: 308
-- Name: subcategoria_conta_id_subcategoria_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.subcategoria_conta_id_subcategoria_seq OWNED BY public.subcategoria_conta.id_subcategoria;


--
-- TOC entry 428 (class 1259 OID 26402)
-- Name: tarefa; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tarefa (
    id_tarefa integer NOT NULL,
    titulo character varying(200) NOT NULL,
    descricao text,
    responsavel integer,
    prioridade character varying(20),
    status character varying(30) DEFAULT 'ABERTA'::character varying,
    data_limite date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.tarefa OWNER TO postgres;

--
-- TOC entry 427 (class 1259 OID 26401)
-- Name: tarefa_id_tarefa_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tarefa_id_tarefa_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tarefa_id_tarefa_seq OWNER TO postgres;

--
-- TOC entry 8285 (class 0 OID 0)
-- Dependencies: 427
-- Name: tarefa_id_tarefa_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tarefa_id_tarefa_seq OWNED BY public.tarefa.id_tarefa;


--
-- TOC entry 484 (class 1259 OID 26892)
-- Name: tarefa_projeto; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tarefa_projeto (
    id_tarefa_projeto integer NOT NULL,
    id_etapa integer NOT NULL,
    titulo character varying(200),
    descricao text,
    prioridade character varying(20),
    responsavel character varying(100),
    data_inicio date,
    data_limite date,
    percentual_conclusao integer DEFAULT 0,
    status character varying(30) DEFAULT 'ABERTA'::character varying,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    CONSTRAINT ck_percentual CHECK (((percentual_conclusao >= 0) AND (percentual_conclusao <= 100)))
);


ALTER TABLE public.tarefa_projeto OWNER TO postgres;

--
-- TOC entry 483 (class 1259 OID 26891)
-- Name: tarefa_projeto_id_tarefa_projeto_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tarefa_projeto_id_tarefa_projeto_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tarefa_projeto_id_tarefa_projeto_seq OWNER TO postgres;

--
-- TOC entry 8286 (class 0 OID 0)
-- Dependencies: 483
-- Name: tarefa_projeto_id_tarefa_projeto_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tarefa_projeto_id_tarefa_projeto_seq OWNED BY public.tarefa_projeto.id_tarefa_projeto;


--
-- TOC entry 465 (class 1259 OID 26731)
-- Name: tipo_documento; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.tipo_documento (
    id_tipo_documento integer NOT NULL,
    codigo character varying(30) NOT NULL,
    descricao character varying(150) NOT NULL,
    categoria character varying(50),
    prazo_validade_dias integer,
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.tipo_documento OWNER TO postgres;

--
-- TOC entry 464 (class 1259 OID 26730)
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.tipo_documento_id_tipo_documento_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.tipo_documento_id_tipo_documento_seq OWNER TO postgres;

--
-- TOC entry 8287 (class 0 OID 0)
-- Dependencies: 464
-- Name: tipo_documento_id_tipo_documento_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.tipo_documento_id_tipo_documento_seq OWNED BY public.tipo_documento.id_tipo_documento;


--
-- TOC entry 512 (class 1259 OID 27109)
-- Name: token_acesso; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.token_acesso (
    id_token integer NOT NULL,
    id_aplicacao integer NOT NULL,
    token_hash text NOT NULL,
    data_criacao timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    data_expiracao timestamp without time zone,
    revogado boolean DEFAULT false
);


ALTER TABLE public.token_acesso OWNER TO postgres;

--
-- TOC entry 511 (class 1259 OID 27108)
-- Name: token_acesso_id_token_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.token_acesso_id_token_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.token_acesso_id_token_seq OWNER TO postgres;

--
-- TOC entry 8288 (class 0 OID 0)
-- Dependencies: 511
-- Name: token_acesso_id_token_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.token_acesso_id_token_seq OWNED BY public.token_acesso.id_token;


--
-- TOC entry 395 (class 1259 OID 26112)
-- Name: transporte; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transporte (
    id_transporte integer NOT NULL,
    id_fornecedor_turistico integer,
    tipo_transporte character varying(50),
    empresa character varying(150),
    placa character varying(20),
    capacidade integer,
    valor_contratado numeric(15,2),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.transporte OWNER TO postgres;

--
-- TOC entry 394 (class 1259 OID 26111)
-- Name: transporte_id_transporte_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transporte_id_transporte_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transporte_id_transporte_seq OWNER TO postgres;

--
-- TOC entry 8289 (class 0 OID 0)
-- Dependencies: 394
-- Name: transporte_id_transporte_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transporte_id_transporte_seq OWNED BY public.transporte.id_transporte;


--
-- TOC entry 293 (class 1259 OID 25090)
-- Name: usuario; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario (
    id_usuario integer NOT NULL,
    nome character varying(100) NOT NULL,
    email character varying(150) NOT NULL,
    senha_hash character varying(255),
    perfil character varying(50),
    ativo boolean DEFAULT true,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.usuario OWNER TO postgres;

--
-- TOC entry 8290 (class 0 OID 0)
-- Dependencies: 293
-- Name: TABLE usuario; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.usuario IS 'Usuários autorizados do sistema';


--
-- TOC entry 292 (class 1259 OID 25089)
-- Name: usuario_id_usuario_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.usuario_id_usuario_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.usuario_id_usuario_seq OWNER TO postgres;

--
-- TOC entry 8291 (class 0 OID 0)
-- Dependencies: 292
-- Name: usuario_id_usuario_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.usuario_id_usuario_seq OWNED BY public.usuario.id_usuario;


--
-- TOC entry 365 (class 1259 OID 25858)
-- Name: usuario_perfil; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.usuario_perfil (
    id_usuario integer NOT NULL,
    id_perfil integer NOT NULL,
    data_inicio date DEFAULT CURRENT_DATE,
    data_fim date
);


ALTER TABLE public.usuario_perfil OWNER TO postgres;

--
-- TOC entry 684 (class 1259 OID 43165)
-- Name: v_total; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.v_total (
    count bigint
);


ALTER TABLE public.v_total OWNER TO postgres;

--
-- TOC entry 336 (class 1259 OID 25540)
-- Name: venda; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.venda (
    id_venda integer NOT NULL,
    numero_venda character varying(30) NOT NULL,
    id_cliente integer NOT NULL,
    data_venda date NOT NULL,
    valor_bruto numeric(15,2),
    desconto numeric(15,2) DEFAULT 0,
    valor_liquido numeric(15,2),
    status character varying(30),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1
);


ALTER TABLE public.venda OWNER TO postgres;

--
-- TOC entry 335 (class 1259 OID 25539)
-- Name: venda_id_venda_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.venda_id_venda_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.venda_id_venda_seq OWNER TO postgres;

--
-- TOC entry 8292 (class 0 OID 0)
-- Dependencies: 335
-- Name: venda_id_venda_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.venda_id_venda_seq OWNED BY public.venda.id_venda;


--
-- TOC entry 356 (class 1259 OID 25801)
-- Name: vw_balancete; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_balancete AS
 SELECT g.codigo,
    g.descricao AS grupo,
    c.descricao AS categoria,
    sum(l.valor) AS saldo
   FROM ((public.lancamento_financeiro l
     LEFT JOIN public.grupo_conta g ON ((l.id_grupo = g.id_grupo)))
     LEFT JOIN public.categoria_conta c ON ((l.id_categoria = c.id_categoria)))
  WHERE (l.deleted_at IS NULL)
  GROUP BY g.codigo, g.descricao, c.descricao;


ALTER VIEW public.vw_balancete OWNER TO postgres;

--
-- TOC entry 8293 (class 0 OID 0)
-- Dependencies: 356
-- Name: VIEW vw_balancete; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_balancete IS 'Apresenta o balancete contábil gerencial da organização, consolidando saldos e movimentações para acompanhamento financeiro.';


--
-- TOC entry 596 (class 1259 OID 33252)
-- Name: vw_dashboard_comercial_bi; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_dashboard_comercial_bi AS
 SELECT canal_venda,
    count(*) AS quantidade_vendas,
    sum(valor_liquido) AS receita,
    avg(valor_liquido) AS ticket_medio,
    sum(margem) AS margem_total
   FROM public.fato_vendas
  GROUP BY canal_venda;


ALTER VIEW public.vw_dashboard_comercial_bi OWNER TO postgres;

--
-- TOC entry 8294 (class 0 OID 0)
-- Dependencies: 596
-- Name: VIEW vw_dashboard_comercial_bi; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_dashboard_comercial_bi IS 'Fornece indicadores comerciais consolidados destinados aos dashboards de Business Intelligence do WMA Travel ERP.';


--
-- TOC entry 594 (class 1259 OID 27752)
-- Name: vw_dashboard_executivo; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_dashboard_executivo AS
 SELECT CURRENT_DATE AS data_referencia,
    COALESCE(( SELECT sum(fato_vendas.valor_liquido) AS sum
           FROM public.fato_vendas), (0)::numeric) AS receita_total,
    COALESCE(( SELECT sum(fato_vendas.custo) AS sum
           FROM public.fato_vendas), (0)::numeric) AS custo_total,
    COALESCE(( SELECT sum(fato_vendas.margem) AS sum
           FROM public.fato_vendas), (0)::numeric) AS lucro_estimado,
    COALESCE(( SELECT count(*) AS count
           FROM public.fato_vendas), (0)::bigint) AS quantidade_vendas,
        CASE
            WHEN (( SELECT count(*) AS count
               FROM public.fato_vendas) > 0) THEN (( SELECT sum(fato_vendas.valor_liquido) AS sum
               FROM public.fato_vendas) / (( SELECT count(*) AS count
               FROM public.fato_vendas))::numeric)
            ELSE (0)::numeric
        END AS ticket_medio;


ALTER VIEW public.vw_dashboard_executivo OWNER TO postgres;

--
-- TOC entry 8295 (class 0 OID 0)
-- Dependencies: 594
-- Name: VIEW vw_dashboard_executivo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_dashboard_executivo IS 'Consolida indicadores estratégicos do WMA Travel ERP para acompanhamento executivo do desempenho empresarial.';


--
-- TOC entry 360 (class 1259 OID 25821)
-- Name: vw_dashboard_financeiro; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_dashboard_financeiro AS
 SELECT date_trunc('mês'::text, (data_competencia)::timestamp with time zone) AS periodo,
    sum(
        CASE
            WHEN ((tipo_lancamento)::text = 'RECEITA'::text) THEN valor
            ELSE (0)::numeric
        END) AS receita,
    sum(
        CASE
            WHEN ((tipo_lancamento)::text = 'DESPESA'::text) THEN valor
            ELSE (0)::numeric
        END) AS despesa,
    sum(
        CASE
            WHEN ((tipo_lancamento)::text = 'RECEITA'::text) THEN valor
            ELSE (- valor)
        END) AS resultado
   FROM public.lancamento_financeiro l
  WHERE (deleted_at IS NULL)
  GROUP BY (date_trunc('mês'::text, (data_competencia)::timestamp with time zone))
  ORDER BY (date_trunc('mês'::text, (data_competencia)::timestamp with time zone));


ALTER VIEW public.vw_dashboard_financeiro OWNER TO postgres;

--
-- TOC entry 8296 (class 0 OID 0)
-- Dependencies: 360
-- Name: VIEW vw_dashboard_financeiro; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_dashboard_financeiro IS 'Consolida informações financeiras destinadas ao acompanhamento gerencial de receitas, despesas, saldos e desempenho financeiro.';


--
-- TOC entry 595 (class 1259 OID 27757)
-- Name: vw_dashboard_financeiro_bi; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_dashboard_financeiro_bi AS
 SELECT natureza,
    sum(valor) AS total_valor,
    count(*) AS quantidade_lancamentos
   FROM public.fato_financeiro
  GROUP BY natureza;


ALTER VIEW public.vw_dashboard_financeiro_bi OWNER TO postgres;

--
-- TOC entry 8297 (class 0 OID 0)
-- Dependencies: 595
-- Name: VIEW vw_dashboard_financeiro_bi; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_dashboard_financeiro_bi IS 'Fornece indicadores financeiros consolidados para utilização em dashboards e análises de Business Intelligence.';


--
-- TOC entry 597 (class 1259 OID 33257)
-- Name: vw_dashboard_rentabilidade_bi; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_dashboard_rentabilidade_bi AS
 SELECT periodo,
    receita_total,
    custo_total,
    lucro_bruto,
    margem_percentual,
    roi_percentual
   FROM public.rentabilidade_produto;


ALTER VIEW public.vw_dashboard_rentabilidade_bi OWNER TO postgres;

--
-- TOC entry 8298 (class 0 OID 0)
-- Dependencies: 597
-- Name: VIEW vw_dashboard_rentabilidade_bi; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_dashboard_rentabilidade_bi IS 'Consolida indicadores de rentabilidade para análises de desempenho econômico e Business Intelligence.';


--
-- TOC entry 355 (class 1259 OID 25796)
-- Name: vw_dre_gerencial; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_dre_gerencial AS
 SELECT EXTRACT(year FROM l.data_competencia) AS ano,
    EXTRACT(month FROM l.data_competencia) AS mes,
    g.codigo AS grupo_codigo,
    g.descricao AS grupo,
    c.codigo AS categoria_codigo,
    c.descricao AS categoria,
    s.codigo AS subcategoria_codigo,
    s.descricao AS subcategoria,
    sum(
        CASE
            WHEN ((g.descricao)::text = 'RECEITAS'::text) THEN l.valor
            ELSE (0)::numeric
        END) AS receita,
    sum(
        CASE
            WHEN ((g.descricao)::text = 'CUSTOS'::text) THEN l.valor
            ELSE (0)::numeric
        END) AS custos,
    sum(
        CASE
            WHEN ((g.descricao)::text = 'DESPESAS'::text) THEN l.valor
            ELSE (0)::numeric
        END) AS despesas,
    (sum(
        CASE
            WHEN ((g.descricao)::text = 'RECEITAS'::text) THEN l.valor
            ELSE (0)::numeric
        END) - sum(
        CASE
            WHEN ((g.descricao)::text = ANY ((ARRAY['CUSTOS'::character varying, 'DESPESAS'::character varying])::text[])) THEN l.valor
            ELSE (0)::numeric
        END)) AS resultado_operacional
   FROM (((public.lancamento_financeiro l
     LEFT JOIN public.grupo_conta g ON ((l.id_grupo = g.id_grupo)))
     LEFT JOIN public.categoria_conta c ON ((l.id_categoria = c.id_categoria)))
     LEFT JOIN public.subcategoria_conta s ON ((l.id_subcategoria = s.id_subcategoria)))
  WHERE (l.deleted_at IS NULL)
  GROUP BY (EXTRACT(year FROM l.data_competencia)), (EXTRACT(month FROM l.data_competencia)), g.codigo, g.descricao, c.codigo, c.descricao, s.codigo, s.descricao;


ALTER VIEW public.vw_dre_gerencial OWNER TO postgres;

--
-- TOC entry 8299 (class 0 OID 0)
-- Dependencies: 355
-- Name: VIEW vw_dre_gerencial; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_dre_gerencial IS 'Apresenta a Demonstração do Resultado do Exercício em visão gerencial para análise de receitas, custos, despesas e resultado.';


--
-- TOC entry 322 (class 1259 OID 25396)
-- Name: vw_fluxo_caixa; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_fluxo_caixa AS
 SELECT id_lancamento,
    data_pagamento,
    data_competencia,
    descricao,
        CASE
            WHEN ((tipo_lancamento)::text = 'RECEITA'::text) THEN valor
            ELSE (0)::numeric
        END AS entrada,
        CASE
            WHEN ((tipo_lancamento)::text = 'DESPESA'::text) THEN valor
            ELSE (0)::numeric
        END AS saida,
        CASE
            WHEN ((tipo_lancamento)::text = 'RECEITA'::text) THEN valor
            ELSE (- valor)
        END AS saldo_movimento
   FROM public.lancamento_financeiro l
  WHERE (deleted_at IS NULL);


ALTER VIEW public.vw_fluxo_caixa OWNER TO postgres;

--
-- TOC entry 8300 (class 0 OID 0)
-- Dependencies: 322
-- Name: VIEW vw_fluxo_caixa; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_fluxo_caixa IS 'Consolida informações de fluxo de caixa para acompanhamento das entradas, saídas e disponibilidade financeira.';


--
-- TOC entry 358 (class 1259 OID 25811)
-- Name: vw_fluxo_caixa_projetado; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_fluxo_caixa_projetado AS
 SELECT date_trunc('mês'::text, (COALESCE(data_pagamento, data_competencia))::timestamp with time zone) AS competencia,
    sum(
        CASE
            WHEN ((tipo_lancamento)::text = 'RECEITA'::text) THEN valor
            ELSE (0)::numeric
        END) AS recebimentos_previstos,
    sum(
        CASE
            WHEN ((tipo_lancamento)::text = 'DESPESA'::text) THEN valor
            ELSE (0)::numeric
        END) AS pagamentos_previstos
   FROM public.lancamento_financeiro l
  WHERE (deleted_at IS NULL)
  GROUP BY (date_trunc('mês'::text, (COALESCE(data_pagamento, data_competencia))::timestamp with time zone));


ALTER VIEW public.vw_fluxo_caixa_projetado OWNER TO postgres;

--
-- TOC entry 8301 (class 0 OID 0)
-- Dependencies: 358
-- Name: VIEW vw_fluxo_caixa_projetado; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_fluxo_caixa_projetado IS 'Apresenta projeções de fluxo de caixa para suporte ao planejamento financeiro e tomada de decisão.';


--
-- TOC entry 357 (class 1259 OID 25806)
-- Name: vw_fluxo_caixa_realizado; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_fluxo_caixa_realizado AS
 SELECT date_trunc('mês'::text, (data_pagamento)::timestamp with time zone) AS competencia,
    sum(
        CASE
            WHEN ((tipo_lancamento)::text = 'RECEITA'::text) THEN valor
            ELSE (0)::numeric
        END) AS entradas,
    sum(
        CASE
            WHEN ((tipo_lancamento)::text = 'DESPESA'::text) THEN valor
            ELSE (0)::numeric
        END) AS saidas,
    sum(
        CASE
            WHEN ((tipo_lancamento)::text = 'RECEITA'::text) THEN valor
            ELSE (- valor)
        END) AS saldo
   FROM public.lancamento_financeiro l
  WHERE ((data_pagamento IS NOT NULL) AND (deleted_at IS NULL))
  GROUP BY (date_trunc('mês'::text, (data_pagamento)::timestamp with time zone))
  ORDER BY (date_trunc('mês'::text, (data_pagamento)::timestamp with time zone));


ALTER VIEW public.vw_fluxo_caixa_realizado OWNER TO postgres;

--
-- TOC entry 8302 (class 0 OID 0)
-- Dependencies: 357
-- Name: VIEW vw_fluxo_caixa_realizado; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_fluxo_caixa_realizado IS 'Apresenta o fluxo de caixa realizado com base nas movimentações financeiras registradas no sistema.';


--
-- TOC entry 523 (class 1259 OID 27204)
-- Name: vw_indicadores_api; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_indicadores_api AS
 SELECT count(*) AS total_chamadas,
    count(
        CASE
            WHEN ((status_http >= 200) AND (status_http <= 299)) THEN 1
            ELSE NULL::integer
        END) AS sucesso,
    count(
        CASE
            WHEN (status_http >= 400) THEN 1
            ELSE NULL::integer
        END) AS erros
   FROM public.log_api;


ALTER VIEW public.vw_indicadores_api OWNER TO postgres;

--
-- TOC entry 8303 (class 0 OID 0)
-- Dependencies: 523
-- Name: VIEW vw_indicadores_api; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_indicadores_api IS 'Disponibiliza indicadores consolidados destinados ao consumo por integrações e serviços de API.';


--
-- TOC entry 444 (class 1259 OID 26553)
-- Name: vw_indicadores_ativo; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_indicadores_ativo AS
 SELECT count(*) AS quantidade_ativos,
    sum(valor_aquisicao) AS valor_total_aquisicao,
    sum(valor_residual) AS valor_residual_total
   FROM public.ativo_imobilizado
  WHERE (deleted_at IS NULL);


ALTER VIEW public.vw_indicadores_ativo OWNER TO postgres;

--
-- TOC entry 8304 (class 0 OID 0)
-- Dependencies: 444
-- Name: VIEW vw_indicadores_ativo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_indicadores_ativo IS 'Apresenta indicadores relacionados aos ativos registrados no sistema para acompanhamento patrimonial e gerencial.';


--
-- TOC entry 555 (class 1259 OID 27392)
-- Name: vw_indicadores_auditoria; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_indicadores_auditoria AS
 SELECT count(*) AS total_eventos,
    count(
        CASE
            WHEN ((acao)::text = 'INSERT'::text) THEN 1
            ELSE NULL::integer
        END) AS inclusoes,
    count(
        CASE
            WHEN ((acao)::text = 'UPDATE'::text) THEN 1
            ELSE NULL::integer
        END) AS alteracoes,
    count(
        CASE
            WHEN ((acao)::text = 'DELETE'::text) THEN 1
            ELSE NULL::integer
        END) AS exclusoes,
    count(
        CASE
            WHEN ((acao)::text = 'LOGIN'::text) THEN 1
            ELSE NULL::integer
        END) AS acessos,
    max(data_evento) AS ultimo_evento
   FROM public.log_auditoria;


ALTER VIEW public.vw_indicadores_auditoria OWNER TO postgres;

--
-- TOC entry 8305 (class 0 OID 0)
-- Dependencies: 555
-- Name: VIEW vw_indicadores_auditoria; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_indicadores_auditoria IS 'Consolida indicadores relacionados às auditorias e controles de conformidade do banco de dados.';


--
-- TOC entry 416 (class 1259 OID 26303)
-- Name: vw_indicadores_crm; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_indicadores_crm AS
 SELECT count(*) AS total_leads,
    count(
        CASE
            WHEN ((status)::text = 'FECHADO'::text) THEN 1
            ELSE NULL::integer
        END) AS vendas_convertidas,
    round((((count(
        CASE
            WHEN ((status)::text = 'FECHADO'::text) THEN 1
            ELSE NULL::integer
        END))::numeric * 100.0) / (NULLIF(count(*), 0))::numeric), 2) AS taxa_conversao
   FROM public.lead
  WHERE (deleted_at IS NULL);


ALTER VIEW public.vw_indicadores_crm OWNER TO postgres;

--
-- TOC entry 8306 (class 0 OID 0)
-- Dependencies: 416
-- Name: VIEW vw_indicadores_crm; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_indicadores_crm IS 'Apresenta indicadores consolidados de relacionamento com clientes para acompanhamento comercial e operacional.';


--
-- TOC entry 478 (class 1259 OID 26851)
-- Name: vw_indicadores_documentos; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_indicadores_documentos AS
 SELECT count(*) AS total_documentos,
    count(
        CASE
            WHEN (data_validade < CURRENT_DATE) THEN 1
            ELSE NULL::integer
        END) AS documentos_vencidos,
    count(
        CASE
            WHEN ((data_validade >= CURRENT_DATE) AND (data_validade <= (CURRENT_DATE + '30 days'::interval))) THEN 1
            ELSE NULL::integer
        END) AS vencendo_30_dias
   FROM public.documento
  WHERE (deleted_at IS NULL);


ALTER VIEW public.vw_indicadores_documentos OWNER TO postgres;

--
-- TOC entry 8307 (class 0 OID 0)
-- Dependencies: 478
-- Name: VIEW vw_indicadores_documentos; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_indicadores_documentos IS 'Apresenta indicadores relacionados ao gerenciamento de documentos e seus respectivos controles operacionais.';


--
-- TOC entry 463 (class 1259 OID 26726)
-- Name: vw_indicadores_estoque; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_indicadores_estoque AS
 SELECT count(*) AS total_itens,
    sum(quantidade_atual) AS quantidade_total
   FROM public.estoque;


ALTER VIEW public.vw_indicadores_estoque OWNER TO postgres;

--
-- TOC entry 8308 (class 0 OID 0)
-- Dependencies: 463
-- Name: VIEW vw_indicadores_estoque; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_indicadores_estoque IS 'Apresenta indicadores relacionados ao controle de estoque e disponibilidade dos itens registrados no sistema.';


--
-- TOC entry 359 (class 1259 OID 25816)
-- Name: vw_indicadores_financeiros; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_indicadores_financeiros AS
 SELECT count(*) AS quantidade_lancamentos,
    sum(
        CASE
            WHEN ((tipo_lancamento)::text = 'RECEITA'::text) THEN valor
            ELSE (0)::numeric
        END) AS faturamento,
    sum(
        CASE
            WHEN ((tipo_lancamento)::text = 'DESPESA'::text) THEN valor
            ELSE (0)::numeric
        END) AS despesas,
    sum(
        CASE
            WHEN ((tipo_lancamento)::text = 'RECEITA'::text) THEN valor
            ELSE (- valor)
        END) AS resultado
   FROM public.lancamento_financeiro
  WHERE (deleted_at IS NULL);


ALTER VIEW public.vw_indicadores_financeiros OWNER TO postgres;

--
-- TOC entry 8309 (class 0 OID 0)
-- Dependencies: 359
-- Name: VIEW vw_indicadores_financeiros; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_indicadores_financeiros IS 'Consolida indicadores financeiros para acompanhamento gerencial do desempenho econômico e financeiro da organização.';


--
-- TOC entry 570 (class 1259 OID 27572)
-- Name: vw_indicadores_integracao; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_indicadores_integracao AS
 SELECT c.codigo,
    c.nome AS sistema,
    s.ultima_situacao,
    s.total_execucoes,
    s.total_sucesso,
    s.total_erro,
    s.percentual_sucesso,
    s.tempo_medio_resposta_ms,
    s.disponivel
   FROM (public.status_integracao s
     JOIN public.conector_integracao c ON ((c.id_conector = s.id_conector)));


ALTER VIEW public.vw_indicadores_integracao OWNER TO postgres;

--
-- TOC entry 8310 (class 0 OID 0)
-- Dependencies: 570
-- Name: VIEW vw_indicadores_integracao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_indicadores_integracao IS 'Apresenta indicadores relacionados às integrações do sistema para acompanhamento de disponibilidade, processamento e operação.';


--
-- TOC entry 493 (class 1259 OID 26981)
-- Name: vw_indicadores_projeto; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_indicadores_projeto AS
 SELECT count(*) AS total_projetos,
    count(
        CASE
            WHEN ((status)::text = 'CONCLUIDO'::text) THEN 1
            ELSE NULL::integer
        END) AS projetos_concluidos,
    sum(orcamento) AS investimento_planejado
   FROM public.projeto
  WHERE (deleted_at IS NULL);


ALTER VIEW public.vw_indicadores_projeto OWNER TO postgres;

--
-- TOC entry 8311 (class 0 OID 0)
-- Dependencies: 493
-- Name: VIEW vw_indicadores_projeto; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_indicadores_projeto IS 'Apresenta indicadores relacionados ao gerenciamento de projetos e acompanhamento de desempenho operacional.';


--
-- TOC entry 431 (class 1259 OID 26438)
-- Name: vw_indicadores_rh; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_indicadores_rh AS
 SELECT count(*) AS total_colaboradores,
    count(
        CASE
            WHEN ((status)::text = 'ATIVO'::text) THEN 1
            ELSE NULL::integer
        END) AS ativos
   FROM public.colaborador
  WHERE (deleted_at IS NULL);


ALTER VIEW public.vw_indicadores_rh OWNER TO postgres;

--
-- TOC entry 8312 (class 0 OID 0)
-- Dependencies: 431
-- Name: VIEW vw_indicadores_rh; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_indicadores_rh IS 'Apresenta indicadores relacionados aos processos de recursos humanos e gestão de colaboradores.';


--
-- TOC entry 508 (class 1259 OID 27086)
-- Name: vw_indicadores_sistema; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_indicadores_sistema AS
 SELECT count(*) AS total_parametros
   FROM public.parametro_sistema
  WHERE (deleted_at IS NULL);


ALTER VIEW public.vw_indicadores_sistema OWNER TO postgres;

--
-- TOC entry 8313 (class 0 OID 0)
-- Dependencies: 508
-- Name: VIEW vw_indicadores_sistema; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_indicadores_sistema IS 'Apresenta indicadores gerais de funcionamento e situação operacional do sistema.';


--
-- TOC entry 590 (class 1259 OID 27725)
-- Name: vw_kpis_turismo; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_kpis_turismo AS
 SELECT codigo,
    nome,
    categoria,
    valor,
    periodo
   FROM public.kpi_turismo
  WHERE (deleted_at IS NULL);


ALTER VIEW public.vw_kpis_turismo OWNER TO postgres;

--
-- TOC entry 8314 (class 0 OID 0)
-- Dependencies: 590
-- Name: VIEW vw_kpis_turismo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_kpis_turismo IS 'Consolida indicadores-chave de desempenho do negócio de turismo para análise operacional, comercial e gerencial.';


--
-- TOC entry 602 (class 1259 OID 33422)
-- Name: vw_lancamento_parcela; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_lancamento_parcela AS
 SELECT id_parcela,
    id_lancamento,
    numero_parcela,
    total_parcelas,
    data_vencimento,
    data_pagamento,
    valor_parcela,
    status,
    created_at,
    updated_at,
    deleted_at,
    created_by,
    updated_by,
    deleted_by,
    versao,
    count(*) OVER (PARTITION BY id_lancamento) AS total_parcelas_calc
   FROM public.lancamento_parcela lp;


ALTER VIEW public.vw_lancamento_parcela OWNER TO postgres;

--
-- TOC entry 8315 (class 0 OID 0)
-- Dependencies: 602
-- Name: VIEW vw_lancamento_parcela; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_lancamento_parcela IS 'Apresenta os lançamentos financeiros relacionados às parcelas para controle de recebimentos, pagamentos e obrigações.';


--
-- TOC entry 593 (class 1259 OID 27748)
-- Name: vw_rentabilidade_turismo; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_rentabilidade_turismo AS
 SELECT periodo,
    receita_total,
    custo_total,
    comissao_total,
    lucro_bruto,
    margem_percentual,
    quantidade_vendida,
    roi_percentual
   FROM public.rentabilidade_produto
  WHERE (deleted_at IS NULL);


ALTER VIEW public.vw_rentabilidade_turismo OWNER TO postgres;

--
-- TOC entry 8316 (class 0 OID 0)
-- Dependencies: 593
-- Name: VIEW vw_rentabilidade_turismo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_rentabilidade_turismo IS 'Apresenta indicadores de rentabilidade das operações de turismo para análise de receitas, custos, margens e desempenho.';


--
-- TOC entry 577 (class 1259 OID 27639)
-- Name: vw_resultado_financeiro_bi; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.vw_resultado_financeiro_bi AS
 SELECT sum(
        CASE
            WHEN ((natureza)::text = 'CREDITO'::text) THEN valor
            ELSE (0)::numeric
        END) AS receitas,
    sum(
        CASE
            WHEN ((natureza)::text = 'DEBITO'::text) THEN valor
            ELSE (0)::numeric
        END) AS despesas,
    sum(
        CASE
            WHEN ((natureza)::text = 'CREDITO'::text) THEN valor
            ELSE (- valor)
        END) AS resultado
   FROM public.fato_financeiro;


ALTER VIEW public.vw_resultado_financeiro_bi OWNER TO postgres;

--
-- TOC entry 8317 (class 0 OID 0)
-- Dependencies: 577
-- Name: VIEW vw_resultado_financeiro_bi; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON VIEW public.vw_resultado_financeiro_bi IS 'Consolida informações de resultado financeiro destinadas à análise gerencial e aos painéis de Business Intelligence.';


--
-- TOC entry 516 (class 1259 OID 27147)
-- Name: webhook; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.webhook (
    id_webhook integer NOT NULL,
    sistema_origem character varying(100),
    evento character varying(100),
    url_destino text,
    ativo boolean DEFAULT true,
    ultimo_evento timestamp without time zone,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.webhook OWNER TO postgres;

--
-- TOC entry 515 (class 1259 OID 27146)
-- Name: webhook_id_webhook_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.webhook_id_webhook_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.webhook_id_webhook_seq OWNER TO postgres;

--
-- TOC entry 8318 (class 0 OID 0)
-- Dependencies: 515
-- Name: webhook_id_webhook_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.webhook_id_webhook_seq OWNED BY public.webhook.id_webhook;


--
-- TOC entry 599 (class 1259 OID 33262)
-- Name: workflow; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.workflow (
    id_workflow integer NOT NULL,
    codigo character varying(50) NOT NULL,
    nome character varying(150) NOT NULL,
    descricao text,
    modulo character varying(100) NOT NULL,
    ativo boolean DEFAULT true NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp without time zone,
    deleted_at timestamp without time zone,
    created_by character varying(100),
    updated_by character varying(100),
    deleted_by character varying(100),
    versao integer DEFAULT 1 NOT NULL
);


ALTER TABLE public.workflow OWNER TO postgres;

--
-- TOC entry 8319 (class 0 OID 0)
-- Dependencies: 599
-- Name: TABLE workflow; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.workflow IS 'Cadastro dos fluxos de trabalho do ERP';


--
-- TOC entry 8320 (class 0 OID 0)
-- Dependencies: 599
-- Name: COLUMN workflow.codigo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow.codigo IS 'Código único do workflow';


--
-- TOC entry 8321 (class 0 OID 0)
-- Dependencies: 599
-- Name: COLUMN workflow.modulo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON COLUMN public.workflow.modulo IS 'Módulo do ERP responsável pelo workflow';


--
-- TOC entry 598 (class 1259 OID 33261)
-- Name: workflow_id_workflow_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.workflow_id_workflow_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.workflow_id_workflow_seq OWNER TO postgres;

--
-- TOC entry 8322 (class 0 OID 0)
-- Dependencies: 598
-- Name: workflow_id_workflow_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.workflow_id_workflow_seq OWNED BY public.workflow.id_workflow;


--
-- TOC entry 6826 (class 2604 OID 43277)
-- Name: auditoria_pos_padronizacao_10_4_5 id_auditoria; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_pos_padronizacao_10_4_5 ALTER COLUMN id_auditoria SET DEFAULT nextval('auditoria.auditoria_pos_padronizacao_10_4_5_id_auditoria_seq'::regclass);


--
-- TOC entry 6792 (class 2604 OID 41856)
-- Name: core id_core; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.core ALTER COLUMN id_core SET DEFAULT nextval('auditoria.core_id_core_seq'::regclass);


--
-- TOC entry 6824 (class 2604 OID 43263)
-- Name: execucao_auditoria id_execucao; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.execucao_auditoria ALTER COLUMN id_execucao SET DEFAULT nextval('auditoria.execucao_auditoria_id_execucao_seq'::regclass);


--
-- TOC entry 6785 (class 2604 OID 41827)
-- Name: executor id_executor; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.executor ALTER COLUMN id_executor SET DEFAULT nextval('auditoria.executor_id_executor_seq'::regclass);


--
-- TOC entry 6783 (class 2604 OID 41791)
-- Name: log_correcao id_log; Type: DEFAULT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.log_correcao ALTER COLUMN id_log SET DEFAULT nextval('auditoria.log_correcao_id_log_seq'::regclass);


--
-- TOC entry 6780 (class 2604 OID 41777)
-- Name: migracao id; Type: DEFAULT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.migracao ALTER COLUMN id SET DEFAULT nextval('config.migracao_id_seq'::regclass);


--
-- TOC entry 6777 (class 2604 OID 41763)
-- Name: versao_banco id; Type: DEFAULT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.versao_banco ALTER COLUMN id SET DEFAULT nextval('config.versao_banco_id_seq'::regclass);


--
-- TOC entry 6605 (class 2604 OID 27224)
-- Name: dim_cliente id_cliente_dw; Type: DEFAULT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.dim_cliente ALTER COLUMN id_cliente_dw SET DEFAULT nextval('dw.dim_cliente_id_cliente_dw_seq'::regclass);


--
-- TOC entry 6607 (class 2604 OID 27242)
-- Name: dim_destino id_destino_dw; Type: DEFAULT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.dim_destino ALTER COLUMN id_destino_dw SET DEFAULT nextval('dw.dim_destino_id_destino_dw_seq'::regclass);


--
-- TOC entry 6608 (class 2604 OID 27250)
-- Name: dim_fornecedor id_fornecedor_dw; Type: DEFAULT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.dim_fornecedor ALTER COLUMN id_fornecedor_dw SET DEFAULT nextval('dw.dim_fornecedor_id_fornecedor_dw_seq'::regclass);


--
-- TOC entry 6609 (class 2604 OID 27258)
-- Name: dim_plano_conta id_conta_dw; Type: DEFAULT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.dim_plano_conta ALTER COLUMN id_conta_dw SET DEFAULT nextval('dw.dim_plano_conta_id_conta_dw_seq'::regclass);


--
-- TOC entry 6606 (class 2604 OID 27232)
-- Name: dim_produto_turistico id_produto_dw; Type: DEFAULT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.dim_produto_turistico ALTER COLUMN id_produto_dw SET DEFAULT nextval('dw.dim_produto_turistico_id_produto_dw_seq'::regclass);


--
-- TOC entry 6604 (class 2604 OID 27213)
-- Name: dim_tempo id_tempo; Type: DEFAULT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.dim_tempo ALTER COLUMN id_tempo SET DEFAULT nextval('dw.dim_tempo_id_tempo_seq'::regclass);


--
-- TOC entry 6611 (class 2604 OID 27275)
-- Name: fato_financeiro id_financeiro_dw; Type: DEFAULT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.fato_financeiro ALTER COLUMN id_financeiro_dw SET DEFAULT nextval('dw.fato_financeiro_id_financeiro_dw_seq'::regclass);


--
-- TOC entry 6612 (class 2604 OID 27283)
-- Name: fato_marketing id_marketing_dw; Type: DEFAULT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.fato_marketing ALTER COLUMN id_marketing_dw SET DEFAULT nextval('dw.fato_marketing_id_marketing_dw_seq'::regclass);


--
-- TOC entry 6610 (class 2604 OID 27267)
-- Name: fato_vendas id_venda_dw; Type: DEFAULT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.fato_vendas ALTER COLUMN id_venda_dw SET DEFAULT nextval('dw.fato_vendas_id_venda_dw_seq'::regclass);


--
-- TOC entry 6613 (class 2604 OID 27291)
-- Name: log_etl id_execucao; Type: DEFAULT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.log_etl ALTER COLUMN id_execucao SET DEFAULT nextval('dw.log_etl_id_execucao_seq'::regclass);


--
-- TOC entry 6240 (class 2604 OID 25027)
-- Name: anexo id_anexo; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.anexo ALTER COLUMN id_anexo SET DEFAULT nextval('financeiro.anexo_id_anexo_seq'::regclass);


--
-- TOC entry 6176 (class 2604 OID 24742)
-- Name: banco id_banco; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.banco ALTER COLUMN id_banco SET DEFAULT nextval('financeiro.banco_id_banco_seq'::regclass);


--
-- TOC entry 6150 (class 2604 OID 24677)
-- Name: categoria id_categoria; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.categoria ALTER COLUMN id_categoria SET DEFAULT nextval('financeiro.categoria_id_categoria_seq'::regclass);


--
-- TOC entry 6174 (class 2604 OID 24730)
-- Name: centro_custo id_centro_custo; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.centro_custo ALTER COLUMN id_centro_custo SET DEFAULT nextval('financeiro.centro_custo_id_centro_custo_seq'::regclass);


--
-- TOC entry 6158 (class 2604 OID 24701)
-- Name: classificacao id_classificacao; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.classificacao ALTER COLUMN id_classificacao SET DEFAULT nextval('financeiro.classificacao_id_classificacao_seq'::regclass);


--
-- TOC entry 6181 (class 2604 OID 24763)
-- Name: cliente id_cliente; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.cliente ALTER COLUMN id_cliente SET DEFAULT nextval('financeiro.cliente_id_cliente_seq'::regclass);


--
-- TOC entry 6231 (class 2604 OID 24993)
-- Name: conciliacao_bancaria id_conciliacao; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.conciliacao_bancaria ALTER COLUMN id_conciliacao SET DEFAULT nextval('financeiro.conciliacao_bancaria_id_conciliacao_seq'::regclass);


--
-- TOC entry 6187 (class 2604 OID 24793)
-- Name: configuracao id_configuracao; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.configuracao ALTER COLUMN id_configuracao SET DEFAULT nextval('financeiro.configuracao_id_configuracao_seq'::regclass);


--
-- TOC entry 6169 (class 2604 OID 24715)
-- Name: conta id_conta; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.conta ALTER COLUMN id_conta SET DEFAULT nextval('financeiro.conta_id_conta_seq'::regclass);


--
-- TOC entry 6178 (class 2604 OID 24752)
-- Name: conta_bancaria id_conta_bancaria; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.conta_bancaria ALTER COLUMN id_conta_bancaria SET DEFAULT nextval('financeiro.conta_bancaria_id_conta_bancaria_seq'::regclass);


--
-- TOC entry 6139 (class 2604 OID 24631)
-- Name: empresa id_empresa; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.empresa ALTER COLUMN id_empresa SET DEFAULT nextval('financeiro.empresa_id_empresa_seq'::regclass);


--
-- TOC entry 6185 (class 2604 OID 24783)
-- Name: forma_pagamento id_forma_pagamento; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.forma_pagamento ALTER COLUMN id_forma_pagamento SET DEFAULT nextval('financeiro.forma_pagamento_id_forma_pagamento_seq'::regclass);


--
-- TOC entry 6183 (class 2604 OID 24773)
-- Name: fornecedor id_fornecedor; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.fornecedor ALTER COLUMN id_fornecedor SET DEFAULT nextval('financeiro.fornecedor_id_fornecedor_seq'::regclass);


--
-- TOC entry 6146 (class 2604 OID 24663)
-- Name: grupo id_grupo; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.grupo ALTER COLUMN id_grupo SET DEFAULT nextval('financeiro.grupo_id_grupo_seq'::regclass);


--
-- TOC entry 6236 (class 2604 OID 25015)
-- Name: historico_lancamento id_historico; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.historico_lancamento ALTER COLUMN id_historico SET DEFAULT nextval('financeiro.historico_lancamento_id_historico_seq'::regclass);


--
-- TOC entry 6207 (class 2604 OID 24917)
-- Name: lancamento id_lancamento; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento ALTER COLUMN id_lancamento SET DEFAULT nextval('financeiro.lancamento_id_lancamento_seq'::regclass);


--
-- TOC entry 6219 (class 2604 OID 24947)
-- Name: lancamento_parcela id_parcela; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento_parcela ALTER COLUMN id_parcela SET DEFAULT nextval('financeiro.lancamento_parcela_id_parcela_seq'::regclass);


--
-- TOC entry 6228 (class 2604 OID 24981)
-- Name: movimentacao_bancaria id_movimento; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.movimentacao_bancaria ALTER COLUMN id_movimento SET DEFAULT nextval('financeiro.movimentacao_bancaria_id_movimento_seq'::regclass);


--
-- TOC entry 6221 (class 2604 OID 24962)
-- Name: pagamento id_pagamento; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.pagamento ALTER COLUMN id_pagamento SET DEFAULT nextval('financeiro.pagamento_id_pagamento_seq'::regclass);


--
-- TOC entry 6233 (class 2604 OID 25005)
-- Name: rateio_centro_custo id_rateio; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.rateio_centro_custo ALTER COLUMN id_rateio SET DEFAULT nextval('financeiro.rateio_centro_custo_id_rateio_seq'::regclass);


--
-- TOC entry 6197 (class 2604 OID 24884)
-- Name: status_lancamento id_status; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.status_lancamento ALTER COLUMN id_status SET DEFAULT nextval('financeiro.status_lancamento_id_status_seq'::regclass);


--
-- TOC entry 6154 (class 2604 OID 24689)
-- Name: subcategoria id_subcategoria; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.subcategoria ALTER COLUMN id_subcategoria SET DEFAULT nextval('financeiro.subcategoria_id_subcategoria_seq'::regclass);


--
-- TOC entry 6201 (class 2604 OID 24895)
-- Name: tipo_documento id_tipo_documento; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_documento ALTER COLUMN id_tipo_documento SET DEFAULT nextval('financeiro.tipo_documento_id_tipo_documento_seq'::regclass);


--
-- TOC entry 6193 (class 2604 OID 24870)
-- Name: tipo_lancamento id_tipo_lancamento; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_lancamento ALTER COLUMN id_tipo_lancamento SET DEFAULT nextval('financeiro.tipo_lancamento_id_tipo_lancamento_seq'::regclass);


--
-- TOC entry 6203 (class 2604 OID 24906)
-- Name: tipo_movimentacao id_tipo_movimentacao; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_movimentacao ALTER COLUMN id_tipo_movimentacao SET DEFAULT nextval('financeiro.tipo_movimentacao_id_tipo_movimentacao_seq'::regclass);


--
-- TOC entry 6142 (class 2604 OID 24645)
-- Name: usuario id_usuario; Type: DEFAULT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('financeiro.usuario_id_usuario_seq'::regclass);


--
-- TOC entry 6463 (class 2604 OID 26386)
-- Name: agenda id_agenda; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda ALTER COLUMN id_agenda SET DEFAULT nextval('public.agenda_id_agenda_seq'::regclass);


--
-- TOC entry 6580 (class 2604 OID 27079)
-- Name: agendamento_rotina id_rotina; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agendamento_rotina ALTER COLUMN id_rotina SET DEFAULT nextval('public.agendamento_rotina_id_rotina_seq'::regclass);


--
-- TOC entry 6559 (class 2604 OID 26968)
-- Name: anexo_projeto id_anexo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anexo_projeto ALTER COLUMN id_anexo SET DEFAULT nextval('public.anexo_projeto_id_anexo_seq'::regclass);


--
-- TOC entry 6582 (class 2604 OID 27094)
-- Name: aplicacao_api id_aplicacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aplicacao_api ALTER COLUMN id_aplicacao SET DEFAULT nextval('public.aplicacao_api_id_aplicacao_seq'::regclass);


--
-- TOC entry 6347 (class 2604 OID 25698)
-- Name: aporte_capital id_aporte; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aporte_capital ALTER COLUMN id_aporte SET DEFAULT nextval('public.aporte_capital_id_aporte_seq'::regclass);


--
-- TOC entry 6618 (class 2604 OID 27331)
-- Name: aprovacao_processo id_aprovacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aprovacao_processo ALTER COLUMN id_aprovacao SET DEFAULT nextval('public.aprovacao_processo_id_aprovacao_seq'::regclass);


--
-- TOC entry 6530 (class 2604 OID 26772)
-- Name: arquivo_digital id_arquivo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.arquivo_digital ALTER COLUMN id_arquivo SET DEFAULT nextval('public.arquivo_digital_id_arquivo_seq'::regclass);


--
-- TOC entry 6535 (class 2604 OID 26806)
-- Name: assinatura_digital id_assinatura; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assinatura_digital ALTER COLUMN id_assinatura SET DEFAULT nextval('public.assinatura_digital_id_assinatura_seq'::regclass);


--
-- TOC entry 6477 (class 2604 OID 26462)
-- Name: ativo_imobilizado id_ativo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ativo_imobilizado ALTER COLUMN id_ativo SET DEFAULT nextval('public.ativo_imobilizado_id_ativo_seq'::regclass);


--
-- TOC entry 6444 (class 2604 OID 26288)
-- Name: avaliacao_pos_viagem id_avaliacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.avaliacao_pos_viagem ALTER COLUMN id_avaliacao SET DEFAULT nextval('public.avaliacao_pos_viagem_id_avaliacao_seq'::regclass);


--
-- TOC entry 6260 (class 2604 OID 25167)
-- Name: banco id_banco; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.banco ALTER COLUMN id_banco SET DEFAULT nextval('public.banco_id_banco_seq'::regclass);


--
-- TOC entry 6430 (class 2604 OID 26221)
-- Name: campanha id_campanha; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campanha ALTER COLUMN id_campanha SET DEFAULT nextval('public.campanha_id_campanha_seq'::regclass);


--
-- TOC entry 6447 (class 2604 OID 26312)
-- Name: cargo id_cargo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cargo ALTER COLUMN id_cargo SET DEFAULT nextval('public.cargo_id_cargo_seq'::regclass);


--
-- TOC entry 6473 (class 2604 OID 26446)
-- Name: categoria_ativo id_categoria_ativo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria_ativo ALTER COLUMN id_categoria_ativo SET DEFAULT nextval('public.categoria_ativo_id_categoria_ativo_seq'::regclass);


--
-- TOC entry 6270 (class 2604 OID 25221)
-- Name: categoria_conta id_categoria; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria_conta ALTER COLUMN id_categoria SET DEFAULT nextval('public.categoria_conta_id_categoria_seq'::regclass);


--
-- TOC entry 6276 (class 2604 OID 25262)
-- Name: centro_custo id_centro_custo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.centro_custo ALTER COLUMN id_centro_custo SET DEFAULT nextval('public.centro_custo_id_centro_custo_seq'::regclass);


--
-- TOC entry 6589 (class 2604 OID 27131)
-- Name: chave_api id_chave; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chave_api ALTER COLUMN id_chave SET DEFAULT nextval('public.chave_api_id_chave_seq'::regclass);


--
-- TOC entry 6414 (class 2604 OID 26145)
-- Name: checklist_viagem id_checklist; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checklist_viagem ALTER COLUMN id_checklist SET DEFAULT nextval('public.checklist_viagem_id_checklist_seq'::regclass);


--
-- TOC entry 6280 (class 2604 OID 25277)
-- Name: classificacao_dre id_classificacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classificacao_dre ALTER COLUMN id_classificacao SET DEFAULT nextval('public.classificacao_dre_id_classificacao_seq'::regclass);


--
-- TOC entry 6254 (class 2604 OID 25127)
-- Name: cliente id_cliente; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente ALTER COLUMN id_cliente SET DEFAULT nextval('public.cliente_id_cliente_seq'::regclass);


--
-- TOC entry 6451 (class 2604 OID 26328)
-- Name: colaborador id_colaborador; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.colaborador ALTER COLUMN id_colaborador SET DEFAULT nextval('public.colaborador_id_colaborador_seq'::regclass);


--
-- TOC entry 6322 (class 2604 OID 25521)
-- Name: comissao id_comissao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comissao ALTER COLUMN id_comissao SET DEFAULT nextval('public.comissao_id_comissao_seq'::regclass);


--
-- TOC entry 6459 (class 2604 OID 26364)
-- Name: comissao_colaborador id_comissao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comissao_colaborador ALTER COLUMN id_comissao SET DEFAULT nextval('public.comissao_colaborador_id_comissao_seq'::regclass);


--
-- TOC entry 6302 (class 2604 OID 25404)
-- Name: conciliacao_bancaria id_conciliacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conciliacao_bancaria ALTER COLUMN id_conciliacao SET DEFAULT nextval('public.conciliacao_bancaria_id_conciliacao_seq'::regclass);


--
-- TOC entry 6640 (class 2604 OID 27420)
-- Name: conector_integracao id_conector; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conector_integracao ALTER COLUMN id_conector SET DEFAULT nextval('public.conector_integracao_id_conector_seq'::regclass);


--
-- TOC entry 6565 (class 2604 OID 27006)
-- Name: configuracao_empresa id_configuracao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracao_empresa ALTER COLUMN id_configuracao SET DEFAULT nextval('public.configuracao_empresa_id_configuracao_seq'::regclass);


--
-- TOC entry 6631 (class 2604 OID 27377)
-- Name: conformidade_lgpd id_lgpd; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conformidade_lgpd ALTER COLUMN id_lgpd SET DEFAULT nextval('public.conformidade_lgpd_id_lgpd_seq'::regclass);


--
-- TOC entry 6283 (class 2604 OID 25294)
-- Name: conta_bancaria id_conta_bancaria; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_bancaria ALTER COLUMN id_conta_bancaria SET DEFAULT nextval('public.conta_bancaria_id_conta_bancaria_seq'::regclass);


--
-- TOC entry 6433 (class 2604 OID 26235)
-- Name: contato_cliente id_contato; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contato_cliente ALTER COLUMN id_contato SET DEFAULT nextval('public.contato_cliente_id_contato_seq'::regclass);


--
-- TOC entry 6533 (class 2604 OID 26790)
-- Name: contrato id_contrato; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contrato ALTER COLUMN id_contrato SET DEFAULT nextval('public.contrato_id_contrato_seq'::regclass);


--
-- TOC entry 6537 (class 2604 OID 26821)
-- Name: controle_vencimento_documento id_controle; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.controle_vencimento_documento ALTER COLUMN id_controle SET DEFAULT nextval('public.controle_vencimento_documento_id_controle_seq'::regclass);


--
-- TOC entry 6418 (class 2604 OID 26165)
-- Name: custo_pacote id_custo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custo_pacote ALTER COLUMN id_custo SET DEFAULT nextval('public.custo_pacote_id_custo_seq'::regclass);


--
-- TOC entry 6555 (class 2604 OID 26936)
-- Name: custo_projeto id_custo_projeto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custo_projeto ALTER COLUMN id_custo_projeto SET DEFAULT nextval('public.custo_projeto_id_custo_projeto_seq'::regclass);


--
-- TOC entry 6344 (class 2604 OID 25644)
-- Name: das id_das; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.das ALTER COLUMN id_das SET DEFAULT nextval('public.das_id_das_seq'::regclass);


--
-- TOC entry 6680 (class 2604 OID 27581)
-- Name: data_mart_execucao id_execucao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.data_mart_execucao ALTER COLUMN id_execucao SET DEFAULT nextval('public.data_mart_execucao_id_execucao_seq'::regclass);


--
-- TOC entry 6356 (class 2604 OID 25768)
-- Name: declaracao_fiscal id_declaracao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.declaracao_fiscal ALTER COLUMN id_declaracao SET DEFAULT nextval('public.declaracao_fiscal_id_declaracao_seq'::regclass);


--
-- TOC entry 6482 (class 2604 OID 26486)
-- Name: depreciacao id_depreciacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.depreciacao ALTER COLUMN id_depreciacao SET DEFAULT nextval('public.depreciacao_id_depreciacao_seq'::regclass);


--
-- TOC entry 6395 (class 2604 OID 26034)
-- Name: destino id_destino; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.destino ALTER COLUMN id_destino SET DEFAULT nextval('public.destino_id_destino_seq'::regclass);


--
-- TOC entry 6703 (class 2604 OID 27662)
-- Name: dim_cliente id_dim_cliente; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_cliente ALTER COLUMN id_dim_cliente SET DEFAULT nextval('public.dim_cliente_id_dim_cliente_seq'::regclass);


--
-- TOC entry 6700 (class 2604 OID 27647)
-- Name: dim_data id_data; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_data ALTER COLUMN id_data SET DEFAULT nextval('public.dim_data_id_data_seq'::regclass);


--
-- TOC entry 6709 (class 2604 OID 27684)
-- Name: dim_destino id_dim_destino; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_destino ALTER COLUMN id_dim_destino SET DEFAULT nextval('public.dim_destino_id_dim_destino_seq'::regclass);


--
-- TOC entry 6712 (class 2604 OID 27695)
-- Name: dim_plano_contas id_dim_plano; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_plano_contas ALTER COLUMN id_dim_plano SET DEFAULT nextval('public.dim_plano_contas_id_dim_plano_seq'::regclass);


--
-- TOC entry 6706 (class 2604 OID 27673)
-- Name: dim_produto_turistico id_dim_produto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_produto_turistico ALTER COLUMN id_dim_produto SET DEFAULT nextval('public.dim_produto_turistico_id_dim_produto_seq'::regclass);


--
-- TOC entry 6350 (class 2604 OID 25716)
-- Name: distribuicao_lucros id_distribuicao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.distribuicao_lucros ALTER COLUMN id_distribuicao SET DEFAULT nextval('public.distribuicao_lucros_id_distribuicao_seq'::regclass);


--
-- TOC entry 6526 (class 2604 OID 26753)
-- Name: documento id_documento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documento ALTER COLUMN id_documento SET DEFAULT nextval('public.documento_id_documento_seq'::regclass);


--
-- TOC entry 6575 (class 2604 OID 27054)
-- Name: email_sistema id_email; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_sistema ALTER COLUMN id_email SET DEFAULT nextval('public.email_sistema_id_email_seq'::regclass);


--
-- TOC entry 6244 (class 2604 OID 25077)
-- Name: empresa id_empresa; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empresa ALTER COLUMN id_empresa SET DEFAULT nextval('public.empresa_id_empresa_seq'::regclass);


--
-- TOC entry 6512 (class 2604 OID 26662)
-- Name: estoque id_estoque; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estoque ALTER COLUMN id_estoque SET DEFAULT nextval('public.estoque_id_estoque_seq'::regclass);


--
-- TOC entry 6547 (class 2604 OID 26878)
-- Name: etapa_projeto id_etapa; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.etapa_projeto ALTER COLUMN id_etapa SET DEFAULT nextval('public.etapa_projeto_id_etapa_seq'::regclass);


--
-- TOC entry 6696 (class 2604 OID 27622)
-- Name: fato_financeiro id_fato_financeiro; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fato_financeiro ALTER COLUMN id_fato_financeiro SET DEFAULT nextval('public.fato_financeiro_id_fato_financeiro_seq'::regclass);


--
-- TOC entry 6686 (class 2604 OID 27598)
-- Name: fato_vendas id_fato_venda; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fato_vendas ALTER COLUMN id_fato_venda SET DEFAULT nextval('public.fato_vendas_id_fato_venda_seq'::regclass);


--
-- TOC entry 6659 (class 2604 OID 27497)
-- Name: fila_integracao id_fila_integracao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fila_integracao ALTER COLUMN id_fila_integracao SET DEFAULT nextval('public.fila_integracao_id_fila_integracao_seq'::regclass);


--
-- TOC entry 6595 (class 2604 OID 27162)
-- Name: fila_processamento id_fila; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fila_processamento ALTER COLUMN id_fila SET DEFAULT nextval('public.fila_processamento_id_fila_seq'::regclass);


--
-- TOC entry 6289 (class 2604 OID 25317)
-- Name: forma_pagamento id_forma_pagamento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forma_pagamento ALTER COLUMN id_forma_pagamento SET DEFAULT nextval('public.forma_pagamento_id_forma_pagamento_seq'::regclass);


--
-- TOC entry 6257 (class 2604 OID 25147)
-- Name: fornecedor id_fornecedor; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fornecedor ALTER COLUMN id_fornecedor SET DEFAULT nextval('public.fornecedor_id_fornecedor_seq'::regclass);


--
-- TOC entry 6402 (class 2604 OID 26078)
-- Name: fornecedor_turistico id_fornecedor_turistico; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fornecedor_turistico ALTER COLUMN id_fornecedor_turistico SET DEFAULT nextval('public.fornecedor_turistico_id_fornecedor_turistico_seq'::regclass);


--
-- TOC entry 6437 (class 2604 OID 26253)
-- Name: funil_vendas id_funil; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.funil_vendas ALTER COLUMN id_funil SET DEFAULT nextval('public.funil_vendas_id_funil_seq'::regclass);


--
-- TOC entry 6376 (class 2604 OID 25926)
-- Name: gateway_pagamento id_gateway; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gateway_pagamento ALTER COLUMN id_gateway SET DEFAULT nextval('public.gateway_pagamento_id_gateway_seq'::regclass);


--
-- TOC entry 6267 (class 2604 OID 25204)
-- Name: grupo_conta id_grupo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grupo_conta ALTER COLUMN id_grupo SET DEFAULT nextval('public.grupo_conta_id_grupo_seq'::regclass);


--
-- TOC entry 6411 (class 2604 OID 26132)
-- Name: guia_turistico id_guia; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guia_turistico ALTER COLUMN id_guia SET DEFAULT nextval('public.guia_turistico_id_guia_seq'::regclass);


--
-- TOC entry 6370 (class 2604 OID 25894)
-- Name: historico_alteracao id_historico; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historico_alteracao ALTER COLUMN id_historico SET DEFAULT nextval('public.historico_alteracao_id_historico_seq'::regclass);


--
-- TOC entry 6541 (class 2604 OID 26838)
-- Name: historico_documento id_historico; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historico_documento ALTER COLUMN id_historico SET DEFAULT nextval('public.historico_documento_id_historico_seq'::regclass);


--
-- TOC entry 6471 (class 2604 OID 26424)
-- Name: horas_atividade id_hora; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horas_atividade ALTER COLUMN id_hora SET DEFAULT nextval('public.horas_atividade_id_hora_seq'::regclass);


--
-- TOC entry 6405 (class 2604 OID 26097)
-- Name: hospedagem id_hospedagem; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hospedagem ALTER COLUMN id_hospedagem SET DEFAULT nextval('public.hospedagem_id_hospedagem_seq'::regclass);


--
-- TOC entry 6391 (class 2604 OID 26012)
-- Name: importacao_dados id_importacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.importacao_dados ALTER COLUMN id_importacao SET DEFAULT nextval('public.importacao_dados_id_importacao_seq'::regclass);


--
-- TOC entry 6338 (class 2604 OID 25615)
-- Name: imposto id_imposto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.imposto ALTER COLUMN id_imposto SET DEFAULT nextval('public.imposto_id_imposto_seq'::regclass);


--
-- TOC entry 6389 (class 2604 OID 25995)
-- Name: integracao_nfse id_integracao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integracao_nfse ALTER COLUMN id_integracao SET DEFAULT nextval('public.integracao_nfse_id_integracao_seq'::regclass);


--
-- TOC entry 6372 (class 2604 OID 25906)
-- Name: integracao_woocommerce id_integracao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integracao_woocommerce ALTER COLUMN id_integracao SET DEFAULT nextval('public.integracao_woocommerce_id_integracao_seq'::regclass);


--
-- TOC entry 6441 (class 2604 OID 26270)
-- Name: interacao_lead id_interacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interacao_lead ALTER COLUMN id_interacao SET DEFAULT nextval('public.interacao_lead_id_interacao_seq'::regclass);


--
-- TOC entry 6518 (class 2604 OID 26698)
-- Name: inventario id_inventario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario ALTER COLUMN id_inventario SET DEFAULT nextval('public.inventario_id_inventario_seq'::regclass);


--
-- TOC entry 6521 (class 2604 OID 26710)
-- Name: item_inventario id_item; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_inventario ALTER COLUMN id_item SET DEFAULT nextval('public.item_inventario_id_item_seq'::regclass);


--
-- TOC entry 6510 (class 2604 OID 26641)
-- Name: item_pedido_compra id_item_pedido; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_pedido_compra ALTER COLUMN id_item_pedido SET DEFAULT nextval('public.item_pedido_compra_id_item_pedido_seq'::regclass);


--
-- TOC entry 6503 (class 2604 OID 26597)
-- Name: item_requisicao id_item; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_requisicao ALTER COLUMN id_item SET DEFAULT nextval('public.item_requisicao_id_item_seq'::regclass);


--
-- TOC entry 6330 (class 2604 OID 25566)
-- Name: item_venda id_item; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_venda ALTER COLUMN id_item SET DEFAULT nextval('public.item_venda_id_item_seq'::regclass);


--
-- TOC entry 6715 (class 2604 OID 27711)
-- Name: kpi_turismo id_kpi; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kpi_turismo ALTER COLUMN id_kpi SET DEFAULT nextval('public.kpi_turismo_id_kpi_seq'::regclass);


--
-- TOC entry 6294 (class 2604 OID 25333)
-- Name: lancamento_financeiro id_lancamento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_financeiro ALTER COLUMN id_lancamento SET DEFAULT nextval('public.lancamento_financeiro_id_lancamento_seq'::regclass);


--
-- TOC entry 6298 (class 2604 OID 25379)
-- Name: lancamento_parcela id_parcela; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_parcela ALTER COLUMN id_parcela SET DEFAULT nextval('public.lancamento_parcela_id_parcela_seq'::regclass);


--
-- TOC entry 6425 (class 2604 OID 26200)
-- Name: lead id_lead; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead ALTER COLUMN id_lead SET DEFAULT nextval('public.lead_id_lead_seq'::regclass);


--
-- TOC entry 6488 (class 2604 OID 26522)
-- Name: localizacao_ativo id_localizacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localizacao_ativo ALTER COLUMN id_localizacao SET DEFAULT nextval('public.localizacao_ativo_id_localizacao_seq'::regclass);


--
-- TOC entry 6600 (class 2604 OID 27176)
-- Name: log_api id_log; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_api ALTER COLUMN id_log SET DEFAULT nextval('public.log_api_id_log_seq'::regclass);


--
-- TOC entry 6368 (class 2604 OID 25880)
-- Name: log_auditoria id_log; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_auditoria ALTER COLUMN id_log SET DEFAULT nextval('public.log_auditoria_id_log_seq'::regclass);


--
-- TOC entry 6393 (class 2604 OID 26023)
-- Name: log_integracao id_log; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_integracao ALTER COLUMN id_log SET DEFAULT nextval('public.log_integracao_id_log_seq'::regclass);


--
-- TOC entry 6666 (class 2604 OID 27522)
-- Name: log_integracao_detalhado id_log_integracao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_integracao_detalhado ALTER COLUMN id_log_integracao SET DEFAULT nextval('public.log_integracao_detalhado_id_log_integracao_seq'::regclass);


--
-- TOC entry 6578 (class 2604 OID 27066)
-- Name: log_sistema id_log; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_sistema ALTER COLUMN id_log SET DEFAULT nextval('public.log_sistema_id_log_seq'::regclass);


--
-- TOC entry 6485 (class 2604 OID 26503)
-- Name: manutencao_ativo id_manutencao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manutencao_ativo ALTER COLUMN id_manutencao SET DEFAULT nextval('public.manutencao_ativo_id_manutencao_seq'::regclass);


--
-- TOC entry 6646 (class 2604 OID 27447)
-- Name: mapeamento_campo_integracao id_mapeamento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapeamento_campo_integracao ALTER COLUMN id_mapeamento SET DEFAULT nextval('public.mapeamento_campo_integracao_id_mapeamento_seq'::regclass);


--
-- TOC entry 6614 (class 2604 OID 27309)
-- Name: modelo_ml id_modelo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modelo_ml ALTER COLUMN id_modelo SET DEFAULT nextval('public.modelo_ml_id_modelo_seq'::regclass);


--
-- TOC entry 6491 (class 2604 OID 26534)
-- Name: movimentacao_ativo id_movimentacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimentacao_ativo ALTER COLUMN id_movimentacao SET DEFAULT nextval('public.movimentacao_ativo_id_movimentacao_seq'::regclass);


--
-- TOC entry 6515 (class 2604 OID 26679)
-- Name: movimento_estoque id_movimento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimento_estoque ALTER COLUMN id_movimento SET DEFAULT nextval('public.movimento_estoque_id_movimento_seq'::regclass);


--
-- TOC entry 6334 (class 2604 OID 25589)
-- Name: nota_fiscal id_nota_fiscal; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nota_fiscal ALTER COLUMN id_nota_fiscal SET DEFAULT nextval('public.nota_fiscal_id_nota_fiscal_seq'::regclass);


--
-- TOC entry 6571 (class 2604 OID 27036)
-- Name: notificacao id_notificacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificacao ALTER COLUMN id_notificacao SET DEFAULT nextval('public.notificacao_id_notificacao_seq'::regclass);


--
-- TOC entry 6383 (class 2604 OID 25961)
-- Name: openfinance_conexao id_conexao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.openfinance_conexao ALTER COLUMN id_conexao SET DEFAULT nextval('public.openfinance_conexao_id_conexao_seq'::regclass);


--
-- TOC entry 6386 (class 2604 OID 25979)
-- Name: openfinance_movimento id_movimento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.openfinance_movimento ALTER COLUMN id_movimento SET DEFAULT nextval('public.openfinance_movimento_id_movimento_seq'::regclass);


--
-- TOC entry 6421 (class 2604 OID 26184)
-- Name: origem_lead id_origem; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.origem_lead ALTER COLUMN id_origem SET DEFAULT nextval('public.origem_lead_id_origem_seq'::regclass);


--
-- TOC entry 6310 (class 2604 OID 25454)
-- Name: pacote_viagem id_pacote; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacote_viagem ALTER COLUMN id_pacote SET DEFAULT nextval('public.pacote_viagem_id_pacote_seq'::regclass);


--
-- TOC entry 6380 (class 2604 OID 25940)
-- Name: pagamento_transacao id_transacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamento_transacao ALTER COLUMN id_transacao SET DEFAULT nextval('public.pagamento_transacao_id_transacao_seq'::regclass);


--
-- TOC entry 6561 (class 2604 OID 26989)
-- Name: parametro_sistema id_parametro; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parametro_sistema ALTER COLUMN id_parametro SET DEFAULT nextval('public.parametro_sistema_id_parametro_seq'::regclass);


--
-- TOC entry 6455 (class 2604 OID 26350)
-- Name: parceiro_comercial id_parceiro; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parceiro_comercial ALTER COLUMN id_parceiro SET DEFAULT nextval('public.parceiro_comercial_id_parceiro_seq'::regclass);


--
-- TOC entry 6319 (class 2604 OID 25502)
-- Name: passageiro id_passageiro; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passageiro ALTER COLUMN id_passageiro SET DEFAULT nextval('public.passageiro_id_passageiro_seq'::regclass);


--
-- TOC entry 6505 (class 2604 OID 26620)
-- Name: pedido_compra id_pedido; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido_compra ALTER COLUMN id_pedido SET DEFAULT nextval('public.pedido_compra_id_pedido_seq'::regclass);


--
-- TOC entry 6360 (class 2604 OID 25830)
-- Name: perfil_acesso id_perfil; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfil_acesso ALTER COLUMN id_perfil SET DEFAULT nextval('public.perfil_acesso_id_perfil_seq'::regclass);


--
-- TOC entry 6364 (class 2604 OID 25846)
-- Name: permissao id_permissao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissao ALTER COLUMN id_permissao SET DEFAULT nextval('public.permissao_id_permissao_seq'::regclass);


--
-- TOC entry 6251 (class 2604 OID 25111)
-- Name: pessoa id_pessoa; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pessoa ALTER COLUMN id_pessoa SET DEFAULT nextval('public.pessoa_id_pessoa_seq'::regclass);


--
-- TOC entry 6264 (class 2604 OID 25181)
-- Name: plano_contas id_conta; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plano_contas ALTER COLUMN id_conta SET DEFAULT nextval('public.plano_contas_id_conta_seq'::regclass);


--
-- TOC entry 6623 (class 2604 OID 27346)
-- Name: politica_acesso id_politica; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.politica_acesso ALTER COLUMN id_politica SET DEFAULT nextval('public.politica_acesso_id_politica_seq'::regclass);


--
-- TOC entry 6353 (class 2604 OID 25734)
-- Name: pro_labore id_pro_labore; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pro_labore ALTER COLUMN id_pro_labore SET DEFAULT nextval('public.pro_labore_id_pro_labore_seq'::regclass);


--
-- TOC entry 6493 (class 2604 OID 26561)
-- Name: produto_estoque id_produto_estoque; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto_estoque ALTER COLUMN id_produto_estoque SET DEFAULT nextval('public.produto_estoque_id_produto_estoque_seq'::regclass);


--
-- TOC entry 6306 (class 2604 OID 25434)
-- Name: produto_turistico id_produto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto_turistico ALTER COLUMN id_produto SET DEFAULT nextval('public.produto_turistico_id_produto_seq'::regclass);


--
-- TOC entry 6543 (class 2604 OID 26860)
-- Name: projeto id_projeto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projeto ALTER COLUMN id_projeto SET DEFAULT nextval('public.projeto_id_projeto_seq'::regclass);


--
-- TOC entry 6627 (class 2604 OID 27363)
-- Name: rastreabilidade id_rastreabilidade; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rastreabilidade ALTER COLUMN id_rastreabilidade SET DEFAULT nextval('public.rastreabilidade_id_rastreabilidade_seq'::regclass);


--
-- TOC entry 6602 (class 2604 OID 27193)
-- Name: rate_limit_api id_rate; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rate_limit_api ALTER COLUMN id_rate SET DEFAULT nextval('public.rate_limit_api_id_rate_seq'::regclass);


--
-- TOC entry 6719 (class 2604 OID 27733)
-- Name: rentabilidade_produto id_rentabilidade; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rentabilidade_produto ALTER COLUMN id_rentabilidade SET DEFAULT nextval('public.rentabilidade_produto_id_rentabilidade_seq'::regclass);


--
-- TOC entry 6498 (class 2604 OID 26580)
-- Name: requisicao_compra id_requisicao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.requisicao_compra ALTER COLUMN id_requisicao SET DEFAULT nextval('public.requisicao_compra_id_requisicao_seq'::regclass);


--
-- TOC entry 6314 (class 2604 OID 25474)
-- Name: reserva id_reserva; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva ALTER COLUMN id_reserva SET DEFAULT nextval('public.reserva_id_reserva_seq'::regclass);


--
-- TOC entry 6553 (class 2604 OID 26916)
-- Name: responsavel_projeto id_responsavel; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.responsavel_projeto ALTER COLUMN id_responsavel SET DEFAULT nextval('public.responsavel_projeto_id_responsavel_seq'::regclass);


--
-- TOC entry 6557 (class 2604 OID 26951)
-- Name: risco_projeto id_risco; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risco_projeto ALTER COLUMN id_risco SET DEFAULT nextval('public.risco_projeto_id_risco_seq'::regclass);


--
-- TOC entry 6399 (class 2604 OID 26054)
-- Name: roteiro_viagem id_roteiro; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roteiro_viagem ALTER COLUMN id_roteiro SET DEFAULT nextval('public.roteiro_viagem_id_roteiro_seq'::regclass);


--
-- TOC entry 6568 (class 2604 OID 27024)
-- Name: sequencia_documento id_sequencia; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sequencia_documento ALTER COLUMN id_sequencia SET DEFAULT nextval('public.sequencia_documento_id_sequencia_seq'::regclass);


--
-- TOC entry 6341 (class 2604 OID 25627)
-- Name: simples_nacional id_simples; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.simples_nacional ALTER COLUMN id_simples SET DEFAULT nextval('public.simples_nacional_id_simples_seq'::regclass);


--
-- TOC entry 6651 (class 2604 OID 27471)
-- Name: sincronizacao_integracao id_sincronizacao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sincronizacao_integracao ALTER COLUMN id_sincronizacao SET DEFAULT nextval('public.sincronizacao_integracao_id_sincronizacao_seq'::regclass);


--
-- TOC entry 6635 (class 2604 OID 27400)
-- Name: sistema_externo id_sistema_externo; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sistema_externo ALTER COLUMN id_sistema_externo SET DEFAULT nextval('public.sistema_externo_id_sistema_externo_seq'::regclass);


--
-- TOC entry 6671 (class 2604 OID 27550)
-- Name: status_integracao id_status_integracao; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_integracao ALTER COLUMN id_status_integracao SET DEFAULT nextval('public.status_integracao_id_status_integracao_seq'::regclass);


--
-- TOC entry 6273 (class 2604 OID 25241)
-- Name: subcategoria_conta id_subcategoria; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subcategoria_conta ALTER COLUMN id_subcategoria SET DEFAULT nextval('public.subcategoria_conta_id_subcategoria_seq'::regclass);


--
-- TOC entry 6467 (class 2604 OID 26405)
-- Name: tarefa id_tarefa; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarefa ALTER COLUMN id_tarefa SET DEFAULT nextval('public.tarefa_id_tarefa_seq'::regclass);


--
-- TOC entry 6549 (class 2604 OID 26895)
-- Name: tarefa_projeto id_tarefa_projeto; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarefa_projeto ALTER COLUMN id_tarefa_projeto SET DEFAULT nextval('public.tarefa_projeto_id_tarefa_projeto_seq'::regclass);


--
-- TOC entry 6522 (class 2604 OID 26734)
-- Name: tipo_documento id_tipo_documento; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_documento ALTER COLUMN id_tipo_documento SET DEFAULT nextval('public.tipo_documento_id_tipo_documento_seq'::regclass);


--
-- TOC entry 6586 (class 2604 OID 27112)
-- Name: token_acesso id_token; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.token_acesso ALTER COLUMN id_token SET DEFAULT nextval('public.token_acesso_id_token_seq'::regclass);


--
-- TOC entry 6408 (class 2604 OID 26115)
-- Name: transporte id_transporte; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transporte ALTER COLUMN id_transporte SET DEFAULT nextval('public.transporte_id_transporte_seq'::regclass);


--
-- TOC entry 6247 (class 2604 OID 25093)
-- Name: usuario id_usuario; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario ALTER COLUMN id_usuario SET DEFAULT nextval('public.usuario_id_usuario_seq'::regclass);


--
-- TOC entry 6326 (class 2604 OID 25543)
-- Name: venda id_venda; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venda ALTER COLUMN id_venda SET DEFAULT nextval('public.venda_id_venda_seq'::regclass);


--
-- TOC entry 6592 (class 2604 OID 27150)
-- Name: webhook id_webhook; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.webhook ALTER COLUMN id_webhook SET DEFAULT nextval('public.webhook_id_webhook_seq'::regclass);


--
-- TOC entry 6729 (class 2604 OID 33265)
-- Name: workflow id_workflow; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow ALTER COLUMN id_workflow SET DEFAULT nextval('public.workflow_id_workflow_seq'::regclass);


--
-- TOC entry 7510 (class 2606 OID 43300)
-- Name: auditoria_pos_padronizacao_10_4_5 auditoria_pos_padronizacao_10_4_5_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.auditoria_pos_padronizacao_10_4_5
    ADD CONSTRAINT auditoria_pos_padronizacao_10_4_5_pkey PRIMARY KEY (id_auditoria);


--
-- TOC entry 7508 (class 2606 OID 43272)
-- Name: execucao_auditoria execucao_auditoria_pkey; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.execucao_auditoria
    ADD CONSTRAINT execucao_auditoria_pkey PRIMARY KEY (id_execucao);


--
-- TOC entry 7422 (class 2606 OID 42145)
-- Name: catalogo_coluna pk_catalogo_coluna; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.catalogo_coluna
    ADD CONSTRAINT pk_catalogo_coluna PRIMARY KEY (id_coluna);


--
-- TOC entry 7418 (class 2606 OID 41735)
-- Name: catalogo_schema pk_catalogo_schema; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.catalogo_schema
    ADD CONSTRAINT pk_catalogo_schema PRIMARY KEY (id_schema);


--
-- TOC entry 7420 (class 2606 OID 42143)
-- Name: catalogo_tabela pk_catalogo_tabela; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.catalogo_tabela
    ADD CONSTRAINT pk_catalogo_tabela PRIMARY KEY (id_tabela);


--
-- TOC entry 7374 (class 2606 OID 41483)
-- Name: categoria pk_categoria; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.categoria
    ADD CONSTRAINT pk_categoria PRIMARY KEY (id_categoria);


--
-- TOC entry 7490 (class 2606 OID 42884)
-- Name: colunas_identificadoras pk_colunas_identificadoras; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.colunas_identificadoras
    ADD CONSTRAINT pk_colunas_identificadoras PRIMARY KEY (id);


--
-- TOC entry 7464 (class 2606 OID 42768)
-- Name: colunas_not_null_sem_default pk_colunas_not_null_sem_default; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.colunas_not_null_sem_default
    ADD CONSTRAINT pk_colunas_not_null_sem_default PRIMARY KEY (id);


--
-- TOC entry 7460 (class 2606 OID 42751)
-- Name: colunas_sem_comentario pk_colunas_sem_comentario; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.colunas_sem_comentario
    ADD CONSTRAINT pk_colunas_sem_comentario PRIMARY KEY (id);


--
-- TOC entry 7402 (class 2606 OID 41629)
-- Name: configuracao pk_configuracao; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.configuracao
    ADD CONSTRAINT pk_configuracao PRIMARY KEY (id_configuracao);


--
-- TOC entry 7440 (class 2606 OID 41866)
-- Name: core pk_core; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.core
    ADD CONSTRAINT pk_core PRIMARY KEY (id_core);


--
-- TOC entry 7506 (class 2606 OID 43200)
-- Name: etapa_10_4_4_snapshot pk_etapa_10_4_4_snapshot; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.etapa_10_4_4_snapshot
    ADD CONSTRAINT pk_etapa_10_4_4_snapshot PRIMARY KEY (snapshot_id);


--
-- TOC entry 7370 (class 2606 OID 41463)
-- Name: execucao pk_execucao; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.execucao
    ADD CONSTRAINT pk_execucao PRIMARY KEY (id_execucao);


--
-- TOC entry 7446 (class 2606 OID 42681)
-- Name: execucao_correcao pk_execucao_correcao; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.execucao_correcao
    ADD CONSTRAINT pk_execucao_correcao PRIMARY KEY (id_execucao);


--
-- TOC entry 7436 (class 2606 OID 41841)
-- Name: executor pk_executor; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.executor
    ADD CONSTRAINT pk_executor PRIMARY KEY (id_executor);


--
-- TOC entry 7468 (class 2606 OID 42784)
-- Name: fks_sem_indice pk_fks_sem_indice; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.fks_sem_indice
    ADD CONSTRAINT pk_fks_sem_indice PRIMARY KEY (id);


--
-- TOC entry 7480 (class 2606 OID 42837)
-- Name: indices_potencialmente_duplicados pk_indices_potencialmente_duplicados; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.indices_potencialmente_duplicados
    ADD CONSTRAINT pk_indices_potencialmente_duplicados PRIMARY KEY (id);


--
-- TOC entry 7472 (class 2606 OID 42802)
-- Name: inventario_constraints pk_inventario_constraints; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.inventario_constraints
    ADD CONSTRAINT pk_inventario_constraints PRIMARY KEY (id);


--
-- TOC entry 7486 (class 2606 OID 42866)
-- Name: inventario_identity pk_inventario_identity; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.inventario_identity
    ADD CONSTRAINT pk_inventario_identity PRIMARY KEY (id);


--
-- TOC entry 7476 (class 2606 OID 42819)
-- Name: inventario_indices pk_inventario_indices; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.inventario_indices
    ADD CONSTRAINT pk_inventario_indices PRIMARY KEY (id);


--
-- TOC entry 7482 (class 2606 OID 42850)
-- Name: inventario_sequences pk_inventario_sequences; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.inventario_sequences
    ADD CONSTRAINT pk_inventario_sequences PRIMARY KEY (id);


--
-- TOC entry 7448 (class 2606 OID 42704)
-- Name: inventario_tabelas pk_inventario_tabelas; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.inventario_tabelas
    ADD CONSTRAINT pk_inventario_tabelas PRIMARY KEY (id_inventario);


--
-- TOC entry 7381 (class 2606 OID 41508)
-- Name: item pk_item; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.item
    ADD CONSTRAINT pk_item PRIMARY KEY (id_item);


--
-- TOC entry 7400 (class 2606 OID 41608)
-- Name: log pk_log; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.log
    ADD CONSTRAINT pk_log PRIMARY KEY (id_log);


--
-- TOC entry 7430 (class 2606 OID 41798)
-- Name: log_correcao pk_log_correcao; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.log_correcao
    ADD CONSTRAINT pk_log_correcao PRIMARY KEY (id_log);


--
-- TOC entry 7498 (class 2606 OID 43082)
-- Name: mapa_padronizacao_constraints pk_mapa_padronizacao_constraints; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.mapa_padronizacao_constraints
    ADD CONSTRAINT pk_mapa_padronizacao_constraints PRIMARY KEY (id_mapa);


--
-- TOC entry 7398 (class 2606 OID 41585)
-- Name: recomendacao pk_recomendacao; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.recomendacao
    ADD CONSTRAINT pk_recomendacao PRIMARY KEY (id_recomendacao);


--
-- TOC entry 7414 (class 2606 OID 41721)
-- Name: regra pk_regra; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.regra
    ADD CONSTRAINT pk_regra PRIMARY KEY (id_regra);


--
-- TOC entry 7390 (class 2606 OID 41535)
-- Name: resultado pk_resultado; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.resultado
    ADD CONSTRAINT pk_resultado PRIMARY KEY (id_resultado);


--
-- TOC entry 7393 (class 2606 OID 41561)
-- Name: score pk_score; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.score
    ADD CONSTRAINT pk_score PRIMARY KEY (id_score);


--
-- TOC entry 7406 (class 2606 OID 41707)
-- Name: script pk_script; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.script
    ADD CONSTRAINT pk_script PRIMARY KEY (id_script);


--
-- TOC entry 7456 (class 2606 OID 42734)
-- Name: tabelas_sem_indices pk_tabelas_sem_indices; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.tabelas_sem_indices
    ADD CONSTRAINT pk_tabelas_sem_indices PRIMARY KEY (id);


--
-- TOC entry 7452 (class 2606 OID 42719)
-- Name: tabelas_sem_pk pk_tabelas_sem_pk; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.tabelas_sem_pk
    ADD CONSTRAINT pk_tabelas_sem_pk PRIMARY KEY (id);


--
-- TOC entry 7504 (class 2606 OID 43139)
-- Name: validacao_padronizacao_constraints pk_validacao_padronizacao_constraints; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.validacao_padronizacao_constraints
    ADD CONSTRAINT pk_validacao_padronizacao_constraints PRIMARY KEY (id_validacao);


--
-- TOC entry 7376 (class 2606 OID 41485)
-- Name: categoria uk_categoria_codigo; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.categoria
    ADD CONSTRAINT uk_categoria_codigo UNIQUE (codigo);


--
-- TOC entry 7492 (class 2606 OID 42886)
-- Name: colunas_identificadoras uk_colunas_identificadoras_schema_name_table_name_column_name; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.colunas_identificadoras
    ADD CONSTRAINT uk_colunas_identificadoras_schema_name_table_name_column_name UNIQUE (schema_name, table_name, column_name);


--
-- TOC entry 7466 (class 2606 OID 42770)
-- Name: colunas_not_null_sem_default uk_colunas_not_null_sem_default; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.colunas_not_null_sem_default
    ADD CONSTRAINT uk_colunas_not_null_sem_default UNIQUE (schema_name, table_name, column_name);


--
-- TOC entry 7462 (class 2606 OID 42753)
-- Name: colunas_sem_comentario uk_colunas_sem_comentario_schema_name_table_name_column_name; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.colunas_sem_comentario
    ADD CONSTRAINT uk_colunas_sem_comentario_schema_name_table_name_column_name UNIQUE (schema_name, table_name, column_name);


--
-- TOC entry 7404 (class 2606 OID 41631)
-- Name: configuracao uk_configuracao; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.configuracao
    ADD CONSTRAINT uk_configuracao UNIQUE (chave);


--
-- TOC entry 7442 (class 2606 OID 41868)
-- Name: core uk_core_codigo; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.core
    ADD CONSTRAINT uk_core_codigo UNIQUE (codigo);


--
-- TOC entry 7438 (class 2606 OID 41843)
-- Name: executor uk_executor_codigo; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.executor
    ADD CONSTRAINT uk_executor_codigo UNIQUE (codigo);


--
-- TOC entry 7470 (class 2606 OID 42786)
-- Name: fks_sem_indice uk_fks_sem_indice_schema_name_table_name_constraint_name; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.fks_sem_indice
    ADD CONSTRAINT uk_fks_sem_indice_schema_name_table_name_constraint_name UNIQUE (schema_name, table_name, constraint_name);


--
-- TOC entry 7474 (class 2606 OID 42804)
-- Name: inventario_constraints uk_inventario_constraints; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.inventario_constraints
    ADD CONSTRAINT uk_inventario_constraints UNIQUE (schema_name, table_name, constraint_name);


--
-- TOC entry 7488 (class 2606 OID 42868)
-- Name: inventario_identity uk_inventario_identity_schema_name_table_name_column_name; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.inventario_identity
    ADD CONSTRAINT uk_inventario_identity_schema_name_table_name_column_name UNIQUE (schema_name, table_name, column_name);


--
-- TOC entry 7478 (class 2606 OID 42821)
-- Name: inventario_indices uk_inventario_indices_schema_name_table_name_index_name; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.inventario_indices
    ADD CONSTRAINT uk_inventario_indices_schema_name_table_name_index_name UNIQUE (schema_name, table_name, index_name);


--
-- TOC entry 7484 (class 2606 OID 42852)
-- Name: inventario_sequences uk_inventario_sequences_sequence_schema_sequence_name; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.inventario_sequences
    ADD CONSTRAINT uk_inventario_sequences_sequence_schema_sequence_name UNIQUE (sequence_schema, sequence_name);


--
-- TOC entry 7450 (class 2606 OID 42706)
-- Name: inventario_tabelas uk_inventario_tabelas_schema_name_table_name; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.inventario_tabelas
    ADD CONSTRAINT uk_inventario_tabelas_schema_name_table_name UNIQUE (schema_name, table_name);


--
-- TOC entry 7383 (class 2606 OID 41510)
-- Name: item uk_item_codigo; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.item
    ADD CONSTRAINT uk_item_codigo UNIQUE (codigo);


--
-- TOC entry 7416 (class 2606 OID 41723)
-- Name: regra uk_regra_codigo; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.regra
    ADD CONSTRAINT uk_regra_codigo UNIQUE (codigo);


--
-- TOC entry 7408 (class 2606 OID 41709)
-- Name: script uk_script_codigo; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.script
    ADD CONSTRAINT uk_script_codigo UNIQUE (codigo);


--
-- TOC entry 7458 (class 2606 OID 42736)
-- Name: tabelas_sem_indices uk_tabelas_sem_indices_schema_name_table_name; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.tabelas_sem_indices
    ADD CONSTRAINT uk_tabelas_sem_indices_schema_name_table_name UNIQUE (schema_name, table_name);


--
-- TOC entry 7454 (class 2606 OID 42721)
-- Name: tabelas_sem_pk uk_tabelas_sem_pk_schema_name_table_name; Type: CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.tabelas_sem_pk
    ADD CONSTRAINT uk_tabelas_sem_pk_schema_name_table_name UNIQUE (schema_name, table_name);


--
-- TOC entry 7426 (class 2606 OID 41784)
-- Name: migracao pk_migracao; Type: CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.migracao
    ADD CONSTRAINT pk_migracao PRIMARY KEY (id);


--
-- TOC entry 7432 (class 2606 OID 41806)
-- Name: parametro pk_parametro; Type: CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.parametro
    ADD CONSTRAINT pk_parametro PRIMARY KEY (chave);


--
-- TOC entry 7424 (class 2606 OID 41772)
-- Name: versao_banco pk_versao_banco; Type: CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.versao_banco
    ADD CONSTRAINT pk_versao_banco PRIMARY KEY (id);


--
-- TOC entry 7428 (class 2606 OID 41786)
-- Name: migracao uk_migracao_script; Type: CONSTRAINT; Schema: config; Owner: postgres
--

ALTER TABLE ONLY config.migracao
    ADD CONSTRAINT uk_migracao_script UNIQUE (script);


--
-- TOC entry 7268 (class 2606 OID 27227)
-- Name: dim_cliente pk_dim_cliente; Type: CONSTRAINT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.dim_cliente
    ADD CONSTRAINT pk_dim_cliente PRIMARY KEY (id_cliente_dw);


--
-- TOC entry 7272 (class 2606 OID 27245)
-- Name: dim_destino pk_dim_destino; Type: CONSTRAINT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.dim_destino
    ADD CONSTRAINT pk_dim_destino PRIMARY KEY (id_destino_dw);


--
-- TOC entry 7274 (class 2606 OID 27253)
-- Name: dim_fornecedor pk_dim_fornecedor; Type: CONSTRAINT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.dim_fornecedor
    ADD CONSTRAINT pk_dim_fornecedor PRIMARY KEY (id_fornecedor_dw);


--
-- TOC entry 7276 (class 2606 OID 27261)
-- Name: dim_plano_conta pk_dim_plano_conta; Type: CONSTRAINT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.dim_plano_conta
    ADD CONSTRAINT pk_dim_plano_conta PRIMARY KEY (id_conta_dw);


--
-- TOC entry 7270 (class 2606 OID 27235)
-- Name: dim_produto_turistico pk_dim_produto_turistico; Type: CONSTRAINT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.dim_produto_turistico
    ADD CONSTRAINT pk_dim_produto_turistico PRIMARY KEY (id_produto_dw);


--
-- TOC entry 7264 (class 2606 OID 27217)
-- Name: dim_tempo pk_dim_tempo; Type: CONSTRAINT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.dim_tempo
    ADD CONSTRAINT pk_dim_tempo PRIMARY KEY (id_tempo);


--
-- TOC entry 7280 (class 2606 OID 27278)
-- Name: fato_financeiro pk_fato_financeiro; Type: CONSTRAINT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.fato_financeiro
    ADD CONSTRAINT pk_fato_financeiro PRIMARY KEY (id_financeiro_dw);


--
-- TOC entry 7282 (class 2606 OID 27286)
-- Name: fato_marketing pk_fato_marketing; Type: CONSTRAINT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.fato_marketing
    ADD CONSTRAINT pk_fato_marketing PRIMARY KEY (id_marketing_dw);


--
-- TOC entry 7278 (class 2606 OID 27270)
-- Name: fato_vendas pk_fato_vendas; Type: CONSTRAINT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.fato_vendas
    ADD CONSTRAINT pk_fato_vendas PRIMARY KEY (id_venda_dw);


--
-- TOC entry 7284 (class 2606 OID 27296)
-- Name: log_etl pk_log_etl; Type: CONSTRAINT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.log_etl
    ADD CONSTRAINT pk_log_etl PRIMARY KEY (id_execucao);


--
-- TOC entry 7266 (class 2606 OID 27219)
-- Name: dim_tempo uk_dim_tempo_data; Type: CONSTRAINT; Schema: dw; Owner: postgres
--

ALTER TABLE ONLY dw.dim_tempo
    ADD CONSTRAINT uk_dim_tempo_data UNIQUE (data);


--
-- TOC entry 6974 (class 2606 OID 25034)
-- Name: anexo pk_anexo; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.anexo
    ADD CONSTRAINT pk_anexo PRIMARY KEY (id_anexo);


--
-- TOC entry 6919 (class 2606 OID 24747)
-- Name: banco pk_banco; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.banco
    ADD CONSTRAINT pk_banco PRIMARY KEY (id_banco);


--
-- TOC entry 6888 (class 2606 OID 24684)
-- Name: categoria pk_categoria; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.categoria
    ADD CONSTRAINT pk_categoria PRIMARY KEY (id_categoria);


--
-- TOC entry 6914 (class 2606 OID 24735)
-- Name: centro_custo pk_centro_custo; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.centro_custo
    ADD CONSTRAINT pk_centro_custo PRIMARY KEY (id_centro_custo);


--
-- TOC entry 6904 (class 2606 OID 24708)
-- Name: classificacao pk_classificacao; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.classificacao
    ADD CONSTRAINT pk_classificacao PRIMARY KEY (id_classificacao);


--
-- TOC entry 6928 (class 2606 OID 24768)
-- Name: cliente pk_cliente; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.cliente
    ADD CONSTRAINT pk_cliente PRIMARY KEY (id_cliente);


--
-- TOC entry 6968 (class 2606 OID 25000)
-- Name: conciliacao_bancaria pk_conciliacao_bancaria; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.conciliacao_bancaria
    ADD CONSTRAINT pk_conciliacao_bancaria PRIMARY KEY (id_conciliacao);


--
-- TOC entry 6940 (class 2606 OID 24799)
-- Name: configuracao pk_configuracao; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.configuracao
    ADD CONSTRAINT pk_configuracao PRIMARY KEY (id_configuracao);


--
-- TOC entry 6910 (class 2606 OID 24723)
-- Name: conta pk_conta; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.conta
    ADD CONSTRAINT pk_conta PRIMARY KEY (id_conta);


--
-- TOC entry 6924 (class 2606 OID 24758)
-- Name: conta_bancaria pk_conta_bancaria; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.conta_bancaria
    ADD CONSTRAINT pk_conta_bancaria PRIMARY KEY (id_conta_bancaria);


--
-- TOC entry 6873 (class 2606 OID 24639)
-- Name: empresa pk_empresa; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.empresa
    ADD CONSTRAINT pk_empresa PRIMARY KEY (id_empresa);


--
-- TOC entry 6938 (class 2606 OID 24788)
-- Name: forma_pagamento pk_forma_pagamento; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.forma_pagamento
    ADD CONSTRAINT pk_forma_pagamento PRIMARY KEY (id_forma_pagamento);


--
-- TOC entry 6934 (class 2606 OID 24778)
-- Name: fornecedor pk_fornecedor; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.fornecedor
    ADD CONSTRAINT pk_fornecedor PRIMARY KEY (id_fornecedor);


--
-- TOC entry 6882 (class 2606 OID 24670)
-- Name: grupo pk_grupo; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.grupo
    ADD CONSTRAINT pk_grupo PRIMARY KEY (id_grupo);


--
-- TOC entry 6972 (class 2606 OID 25022)
-- Name: historico_lancamento pk_historico_lancamento; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.historico_lancamento
    ADD CONSTRAINT pk_historico_lancamento PRIMARY KEY (id_historico);


--
-- TOC entry 6958 (class 2606 OID 24940)
-- Name: lancamento pk_lancamento; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT pk_lancamento PRIMARY KEY (id_lancamento);


--
-- TOC entry 6962 (class 2606 OID 24957)
-- Name: lancamento_parcela pk_lancamento_parcela; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento_parcela
    ADD CONSTRAINT pk_lancamento_parcela PRIMARY KEY (id_parcela);


--
-- TOC entry 6966 (class 2606 OID 24988)
-- Name: movimentacao_bancaria pk_movimentacao_bancaria; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.movimentacao_bancaria
    ADD CONSTRAINT pk_movimentacao_bancaria PRIMARY KEY (id_movimento);


--
-- TOC entry 6964 (class 2606 OID 24976)
-- Name: pagamento pk_pagamento; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.pagamento
    ADD CONSTRAINT pk_pagamento PRIMARY KEY (id_pagamento);


--
-- TOC entry 6970 (class 2606 OID 25010)
-- Name: rateio_centro_custo pk_rateio_centro_custo; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.rateio_centro_custo
    ADD CONSTRAINT pk_rateio_centro_custo PRIMARY KEY (id_rateio);


--
-- TOC entry 6946 (class 2606 OID 24888)
-- Name: status_lancamento pk_status_lancamento; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.status_lancamento
    ADD CONSTRAINT pk_status_lancamento PRIMARY KEY (id_status);


--
-- TOC entry 6894 (class 2606 OID 24696)
-- Name: subcategoria pk_subcategoria; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.subcategoria
    ADD CONSTRAINT pk_subcategoria PRIMARY KEY (id_subcategoria);


--
-- TOC entry 6950 (class 2606 OID 24899)
-- Name: tipo_documento pk_tipo_documento; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_documento
    ADD CONSTRAINT pk_tipo_documento PRIMARY KEY (id_tipo_documento);


--
-- TOC entry 6942 (class 2606 OID 24877)
-- Name: tipo_lancamento pk_tipo_lancamento; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_lancamento
    ADD CONSTRAINT pk_tipo_lancamento PRIMARY KEY (id_tipo_lancamento);


--
-- TOC entry 6954 (class 2606 OID 24910)
-- Name: tipo_movimentacao pk_tipo_movimentacao; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_movimentacao
    ADD CONSTRAINT pk_tipo_movimentacao PRIMARY KEY (id_tipo_movimentacao);


--
-- TOC entry 6877 (class 2606 OID 24656)
-- Name: usuario pk_usuario; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.usuario
    ADD CONSTRAINT pk_usuario PRIMARY KEY (id_usuario);


--
-- TOC entry 6921 (class 2606 OID 24854)
-- Name: banco uk_banco_codigo; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.banco
    ADD CONSTRAINT uk_banco_codigo UNIQUE (codigo_banco);


--
-- TOC entry 6916 (class 2606 OID 24737)
-- Name: centro_custo uk_centro_custo_codigo; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.centro_custo
    ADD CONSTRAINT uk_centro_custo_codigo UNIQUE (codigo);


--
-- TOC entry 6906 (class 2606 OID 24710)
-- Name: classificacao uk_classificacao_codigo; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.classificacao
    ADD CONSTRAINT uk_classificacao_codigo UNIQUE (codigo);


--
-- TOC entry 6930 (class 2606 OID 24850)
-- Name: cliente uk_cliente_documento; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.cliente
    ADD CONSTRAINT uk_cliente_documento UNIQUE (cpf_cnpj);


--
-- TOC entry 6890 (class 2606 OID 24863)
-- Name: categoria uk_codigo_categoria; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.categoria
    ADD CONSTRAINT uk_codigo_categoria UNIQUE (codigo);


--
-- TOC entry 6896 (class 2606 OID 24861)
-- Name: subcategoria uk_codigo_subcategoria; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.subcategoria
    ADD CONSTRAINT uk_codigo_subcategoria UNIQUE (codigo);


--
-- TOC entry 6912 (class 2606 OID 24725)
-- Name: conta uk_conta_codigo; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.conta
    ADD CONSTRAINT uk_conta_codigo UNIQUE (codigo);


--
-- TOC entry 6875 (class 2606 OID 24848)
-- Name: empresa uk_empresa_cnpj; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.empresa
    ADD CONSTRAINT uk_empresa_cnpj UNIQUE (cnpj);


--
-- TOC entry 6936 (class 2606 OID 24852)
-- Name: fornecedor uk_fornecedor_documento; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.fornecedor
    ADD CONSTRAINT uk_fornecedor_documento UNIQUE (cpf_cnpj);


--
-- TOC entry 6884 (class 2606 OID 24672)
-- Name: grupo uk_grupo_codigo; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.grupo
    ADD CONSTRAINT uk_grupo_codigo UNIQUE (codigo);


--
-- TOC entry 6960 (class 2606 OID 24942)
-- Name: lancamento uk_lancamento_numero; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT uk_lancamento_numero UNIQUE (numero);


--
-- TOC entry 6948 (class 2606 OID 24890)
-- Name: status_lancamento uk_status_lancamento_codigo; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.status_lancamento
    ADD CONSTRAINT uk_status_lancamento_codigo UNIQUE (codigo);


--
-- TOC entry 6952 (class 2606 OID 24901)
-- Name: tipo_documento uk_tipo_documento_codigo; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_documento
    ADD CONSTRAINT uk_tipo_documento_codigo UNIQUE (codigo);


--
-- TOC entry 6944 (class 2606 OID 24879)
-- Name: tipo_lancamento uk_tipo_lancamento_codigo; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_lancamento
    ADD CONSTRAINT uk_tipo_lancamento_codigo UNIQUE (codigo);


--
-- TOC entry 6956 (class 2606 OID 24912)
-- Name: tipo_movimentacao uk_tipo_movimentacao_codigo; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_movimentacao
    ADD CONSTRAINT uk_tipo_movimentacao_codigo UNIQUE (codigo);


--
-- TOC entry 6879 (class 2606 OID 24658)
-- Name: usuario uk_usuario_email; Type: CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.usuario
    ADD CONSTRAINT uk_usuario_email UNIQUE (email);


--
-- TOC entry 7148 (class 2606 OID 26394)
-- Name: agenda pk_agenda; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT pk_agenda PRIMARY KEY (id_agenda);


--
-- TOC entry 7244 (class 2606 OID 27083)
-- Name: agendamento_rotina pk_agendamento_rotina; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agendamento_rotina
    ADD CONSTRAINT pk_agendamento_rotina PRIMARY KEY (id_rotina);


--
-- TOC entry 7226 (class 2606 OID 26975)
-- Name: anexo_projeto pk_anexo_projeto; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anexo_projeto
    ADD CONSTRAINT pk_anexo_projeto PRIMARY KEY (id_anexo);


--
-- TOC entry 7248 (class 2606 OID 27105)
-- Name: aplicacao_api pk_aplicacao_api; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aplicacao_api
    ADD CONSTRAINT pk_aplicacao_api PRIMARY KEY (id_aplicacao);


--
-- TOC entry 7062 (class 2606 OID 25706)
-- Name: aporte_capital pk_aporte_capital; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aporte_capital
    ADD CONSTRAINT pk_aporte_capital PRIMARY KEY (id_aporte);


--
-- TOC entry 7290 (class 2606 OID 27341)
-- Name: aprovacao_processo pk_aprovacao_processo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aprovacao_processo
    ADD CONSTRAINT pk_aprovacao_processo PRIMARY KEY (id_aprovacao);


--
-- TOC entry 7202 (class 2606 OID 26780)
-- Name: arquivo_digital pk_arquivo_digital; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.arquivo_digital
    ADD CONSTRAINT pk_arquivo_digital PRIMARY KEY (id_arquivo);


--
-- TOC entry 7206 (class 2606 OID 26811)
-- Name: assinatura_digital pk_assinatura_digital; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assinatura_digital
    ADD CONSTRAINT pk_assinatura_digital PRIMARY KEY (id_assinatura);


--
-- TOC entry 7158 (class 2606 OID 26474)
-- Name: ativo_imobilizado pk_ativo_imobilizado; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ativo_imobilizado
    ADD CONSTRAINT pk_ativo_imobilizado PRIMARY KEY (id_ativo);


--
-- TOC entry 7136 (class 2606 OID 26297)
-- Name: avaliacao_pos_viagem pk_avaliacao_pos_viagem; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.avaliacao_pos_viagem
    ADD CONSTRAINT pk_avaliacao_pos_viagem PRIMARY KEY (id_avaliacao);


--
-- TOC entry 6992 (class 2606 OID 25176)
-- Name: banco pk_banco; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.banco
    ADD CONSTRAINT pk_banco PRIMARY KEY (id_banco);


--
-- TOC entry 7126 (class 2606 OID 26228)
-- Name: campanha pk_campanha; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campanha
    ADD CONSTRAINT pk_campanha PRIMARY KEY (id_campanha);


--
-- TOC entry 7138 (class 2606 OID 26321)
-- Name: cargo pk_cargo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cargo
    ADD CONSTRAINT pk_cargo PRIMARY KEY (id_cargo);


--
-- TOC entry 7154 (class 2606 OID 26455)
-- Name: categoria_ativo pk_categoria_ativo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria_ativo
    ADD CONSTRAINT pk_categoria_ativo PRIMARY KEY (id_categoria_ativo);


--
-- TOC entry 7002 (class 2606 OID 25229)
-- Name: categoria_conta pk_categoria_conta; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria_conta
    ADD CONSTRAINT pk_categoria_conta PRIMARY KEY (id_categoria);


--
-- TOC entry 7010 (class 2606 OID 25270)
-- Name: centro_custo pk_centro_custo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.centro_custo
    ADD CONSTRAINT pk_centro_custo PRIMARY KEY (id_centro_custo);


--
-- TOC entry 7254 (class 2606 OID 27140)
-- Name: chave_api pk_chave_api; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chave_api
    ADD CONSTRAINT pk_chave_api PRIMARY KEY (id_chave);


--
-- TOC entry 7116 (class 2606 OID 26154)
-- Name: checklist_viagem pk_checklist_viagem; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checklist_viagem
    ADD CONSTRAINT pk_checklist_viagem PRIMARY KEY (id_checklist);


--
-- TOC entry 7014 (class 2606 OID 25287)
-- Name: classificacao_dre pk_classificacao_dre; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classificacao_dre
    ADD CONSTRAINT pk_classificacao_dre PRIMARY KEY (id_classificacao);


--
-- TOC entry 6984 (class 2606 OID 25135)
-- Name: cliente pk_cliente; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT pk_cliente PRIMARY KEY (id_cliente);


--
-- TOC entry 7142 (class 2606 OID 26335)
-- Name: colaborador pk_colaborador; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.colaborador
    ADD CONSTRAINT pk_colaborador PRIMARY KEY (id_colaborador);


--
-- TOC entry 7044 (class 2606 OID 25528)
-- Name: comissao pk_comissao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comissao
    ADD CONSTRAINT pk_comissao PRIMARY KEY (id_comissao);


--
-- TOC entry 7146 (class 2606 OID 26371)
-- Name: comissao_colaborador pk_comissao_colaborador; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comissao_colaborador
    ADD CONSTRAINT pk_comissao_colaborador PRIMARY KEY (id_comissao);


--
-- TOC entry 7028 (class 2606 OID 25414)
-- Name: conciliacao_bancaria pk_conciliacao_bancaria; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conciliacao_bancaria
    ADD CONSTRAINT pk_conciliacao_bancaria PRIMARY KEY (id_conciliacao);


--
-- TOC entry 7304 (class 2606 OID 27435)
-- Name: conector_integracao pk_conector_integracao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conector_integracao
    ADD CONSTRAINT pk_conector_integracao PRIMARY KEY (id_conector);


--
-- TOC entry 7232 (class 2606 OID 27014)
-- Name: configuracao_empresa pk_configuracao_empresa; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracao_empresa
    ADD CONSTRAINT pk_configuracao_empresa PRIMARY KEY (id_configuracao);


--
-- TOC entry 7298 (class 2606 OID 27386)
-- Name: conformidade_lgpd pk_conformidade_lgpd; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conformidade_lgpd
    ADD CONSTRAINT pk_conformidade_lgpd PRIMARY KEY (id_lgpd);


--
-- TOC entry 7018 (class 2606 OID 25307)
-- Name: conta_bancaria pk_conta_bancaria; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_bancaria
    ADD CONSTRAINT pk_conta_bancaria PRIMARY KEY (id_conta_bancaria);


--
-- TOC entry 7130 (class 2606 OID 26243)
-- Name: contato_cliente pk_contato_cliente; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contato_cliente
    ADD CONSTRAINT pk_contato_cliente PRIMARY KEY (id_contato);


--
-- TOC entry 7204 (class 2606 OID 26795)
-- Name: contrato pk_contrato; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contrato
    ADD CONSTRAINT pk_contrato PRIMARY KEY (id_contrato);


--
-- TOC entry 7208 (class 2606 OID 26828)
-- Name: controle_vencimento_documento pk_controle_vencimento_documento; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.controle_vencimento_documento
    ADD CONSTRAINT pk_controle_vencimento_documento PRIMARY KEY (id_controle);


--
-- TOC entry 7118 (class 2606 OID 26173)
-- Name: custo_pacote pk_custo_pacote; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custo_pacote
    ADD CONSTRAINT pk_custo_pacote PRIMARY KEY (id_custo);


--
-- TOC entry 7222 (class 2606 OID 26941)
-- Name: custo_projeto pk_custo_projeto; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custo_projeto
    ADD CONSTRAINT pk_custo_projeto PRIMARY KEY (id_custo_projeto);


--
-- TOC entry 7060 (class 2606 OID 25651)
-- Name: das pk_das; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.das
    ADD CONSTRAINT pk_das PRIMARY KEY (id_das);


--
-- TOC entry 7318 (class 2606 OID 27593)
-- Name: data_mart_execucao pk_data_mart_execucao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.data_mart_execucao
    ADD CONSTRAINT pk_data_mart_execucao PRIMARY KEY (id_execucao);


--
-- TOC entry 7068 (class 2606 OID 25780)
-- Name: declaracao_fiscal pk_declaracao_fiscal; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.declaracao_fiscal
    ADD CONSTRAINT pk_declaracao_fiscal PRIMARY KEY (id_declaracao);


--
-- TOC entry 7162 (class 2606 OID 26493)
-- Name: depreciacao pk_depreciacao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.depreciacao
    ADD CONSTRAINT pk_depreciacao PRIMARY KEY (id_depreciacao);


--
-- TOC entry 7102 (class 2606 OID 26046)
-- Name: destino pk_destino; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.destino
    ADD CONSTRAINT pk_destino PRIMARY KEY (id_destino);


--
-- TOC entry 7338 (class 2606 OID 27668)
-- Name: dim_cliente pk_dim_cliente; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_cliente
    ADD CONSTRAINT pk_dim_cliente PRIMARY KEY (id_dim_cliente);


--
-- TOC entry 7333 (class 2606 OID 27654)
-- Name: dim_data pk_dim_data; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_data
    ADD CONSTRAINT pk_dim_data PRIMARY KEY (id_data);


--
-- TOC entry 7343 (class 2606 OID 27690)
-- Name: dim_destino pk_dim_destino; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_destino
    ADD CONSTRAINT pk_dim_destino PRIMARY KEY (id_dim_destino);


--
-- TOC entry 7346 (class 2606 OID 27701)
-- Name: dim_plano_contas pk_dim_plano_contas; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_plano_contas
    ADD CONSTRAINT pk_dim_plano_contas PRIMARY KEY (id_dim_plano);


--
-- TOC entry 7340 (class 2606 OID 27679)
-- Name: dim_produto_turistico pk_dim_produto_turistico; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_produto_turistico
    ADD CONSTRAINT pk_dim_produto_turistico PRIMARY KEY (id_dim_produto);


--
-- TOC entry 7064 (class 2606 OID 25724)
-- Name: distribuicao_lucros pk_distribuicao_lucros; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.distribuicao_lucros
    ADD CONSTRAINT pk_distribuicao_lucros PRIMARY KEY (id_distribuicao);


--
-- TOC entry 7200 (class 2606 OID 26762)
-- Name: documento pk_documento; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT pk_documento PRIMARY KEY (id_documento);


--
-- TOC entry 7240 (class 2606 OID 27061)
-- Name: email_sistema pk_email_sistema; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.email_sistema
    ADD CONSTRAINT pk_email_sistema PRIMARY KEY (id_email);


--
-- TOC entry 6976 (class 2606 OID 25088)
-- Name: empresa pk_empresa; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empresa
    ADD CONSTRAINT pk_empresa PRIMARY KEY (id_empresa);


--
-- TOC entry 7188 (class 2606 OID 26668)
-- Name: estoque pk_estoque; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estoque
    ADD CONSTRAINT pk_estoque PRIMARY KEY (id_estoque);


--
-- TOC entry 7216 (class 2606 OID 26885)
-- Name: etapa_projeto pk_etapa_projeto; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.etapa_projeto
    ADD CONSTRAINT pk_etapa_projeto PRIMARY KEY (id_etapa);


--
-- TOC entry 7330 (class 2606 OID 27632)
-- Name: fato_financeiro pk_fato_financeiro; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fato_financeiro
    ADD CONSTRAINT pk_fato_financeiro PRIMARY KEY (id_fato_financeiro);


--
-- TOC entry 7324 (class 2606 OID 27612)
-- Name: fato_vendas pk_fato_vendas; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fato_vendas
    ADD CONSTRAINT pk_fato_vendas PRIMARY KEY (id_fato_venda);


--
-- TOC entry 7312 (class 2606 OID 27512)
-- Name: fila_integracao pk_fila_integracao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fila_integracao
    ADD CONSTRAINT pk_fila_integracao PRIMARY KEY (id_fila_integracao);


--
-- TOC entry 7258 (class 2606 OID 27171)
-- Name: fila_processamento pk_fila_processamento; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fila_processamento
    ADD CONSTRAINT pk_fila_processamento PRIMARY KEY (id_fila);


--
-- TOC entry 7020 (class 2606 OID 25326)
-- Name: forma_pagamento pk_forma_pagamento; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forma_pagamento
    ADD CONSTRAINT pk_forma_pagamento PRIMARY KEY (id_forma_pagamento);


--
-- TOC entry 6988 (class 2606 OID 25155)
-- Name: fornecedor pk_fornecedor; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fornecedor
    ADD CONSTRAINT pk_fornecedor PRIMARY KEY (id_fornecedor);


--
-- TOC entry 7108 (class 2606 OID 26086)
-- Name: fornecedor_turistico pk_fornecedor_turistico; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fornecedor_turistico
    ADD CONSTRAINT pk_fornecedor_turistico PRIMARY KEY (id_fornecedor_turistico);


--
-- TOC entry 7132 (class 2606 OID 26260)
-- Name: funil_vendas pk_funil_vendas; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.funil_vendas
    ADD CONSTRAINT pk_funil_vendas PRIMARY KEY (id_funil);


--
-- TOC entry 7086 (class 2606 OID 25933)
-- Name: gateway_pagamento pk_gateway_pagamento; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gateway_pagamento
    ADD CONSTRAINT pk_gateway_pagamento PRIMARY KEY (id_gateway);


--
-- TOC entry 6998 (class 2606 OID 25213)
-- Name: grupo_conta pk_grupo_conta; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grupo_conta
    ADD CONSTRAINT pk_grupo_conta PRIMARY KEY (id_grupo);


--
-- TOC entry 7114 (class 2606 OID 26140)
-- Name: guia_turistico pk_guia_turistico; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.guia_turistico
    ADD CONSTRAINT pk_guia_turistico PRIMARY KEY (id_guia);


--
-- TOC entry 7082 (class 2606 OID 25900)
-- Name: historico_alteracao pk_historico_alteracao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historico_alteracao
    ADD CONSTRAINT pk_historico_alteracao PRIMARY KEY (id_historico);


--
-- TOC entry 7210 (class 2606 OID 26845)
-- Name: historico_documento pk_historico_documento; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historico_documento
    ADD CONSTRAINT pk_historico_documento PRIMARY KEY (id_historico);


--
-- TOC entry 7152 (class 2606 OID 26431)
-- Name: horas_atividade pk_horas_atividade; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horas_atividade
    ADD CONSTRAINT pk_horas_atividade PRIMARY KEY (id_hora);


--
-- TOC entry 7110 (class 2606 OID 26105)
-- Name: hospedagem pk_hospedagem; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hospedagem
    ADD CONSTRAINT pk_hospedagem PRIMARY KEY (id_hospedagem);


--
-- TOC entry 7098 (class 2606 OID 26018)
-- Name: importacao_dados pk_importacao_dados; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.importacao_dados
    ADD CONSTRAINT pk_importacao_dados PRIMARY KEY (id_importacao);


--
-- TOC entry 7054 (class 2606 OID 25620)
-- Name: imposto pk_imposto; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.imposto
    ADD CONSTRAINT pk_imposto PRIMARY KEY (id_imposto);


--
-- TOC entry 7096 (class 2606 OID 26002)
-- Name: integracao_nfse pk_integracao_nfse; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integracao_nfse
    ADD CONSTRAINT pk_integracao_nfse PRIMARY KEY (id_integracao);


--
-- TOC entry 7084 (class 2606 OID 25915)
-- Name: integracao_woocommerce pk_integracao_woocommerce; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integracao_woocommerce
    ADD CONSTRAINT pk_integracao_woocommerce PRIMARY KEY (id_integracao);


--
-- TOC entry 7134 (class 2606 OID 26278)
-- Name: interacao_lead pk_interacao_lead; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interacao_lead
    ADD CONSTRAINT pk_interacao_lead PRIMARY KEY (id_interacao);


--
-- TOC entry 7192 (class 2606 OID 26705)
-- Name: inventario pk_inventario; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.inventario
    ADD CONSTRAINT pk_inventario PRIMARY KEY (id_inventario);


--
-- TOC entry 7194 (class 2606 OID 26715)
-- Name: item_inventario pk_item_inventario; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_inventario
    ADD CONSTRAINT pk_item_inventario PRIMARY KEY (id_item);


--
-- TOC entry 7186 (class 2606 OID 26647)
-- Name: item_pedido_compra pk_item_pedido_compra; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_pedido_compra
    ADD CONSTRAINT pk_item_pedido_compra PRIMARY KEY (id_item_pedido);


--
-- TOC entry 7180 (class 2606 OID 26605)
-- Name: item_requisicao pk_item_requisicao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_requisicao
    ADD CONSTRAINT pk_item_requisicao PRIMARY KEY (id_item);


--
-- TOC entry 7050 (class 2606 OID 25574)
-- Name: item_venda pk_item_venda; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_venda
    ADD CONSTRAINT pk_item_venda PRIMARY KEY (id_item);


--
-- TOC entry 7348 (class 2606 OID 27722)
-- Name: kpi_turismo pk_kpi_turismo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kpi_turismo
    ADD CONSTRAINT pk_kpi_turismo PRIMARY KEY (id_kpi);


--
-- TOC entry 7024 (class 2606 OID 25348)
-- Name: lancamento_financeiro pk_lancamento_financeiro; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_financeiro
    ADD CONSTRAINT pk_lancamento_financeiro PRIMARY KEY (id_lancamento);


--
-- TOC entry 7026 (class 2606 OID 25390)
-- Name: lancamento_parcela pk_lancamento_parcela; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_parcela
    ADD CONSTRAINT pk_lancamento_parcela PRIMARY KEY (id_parcela);


--
-- TOC entry 7124 (class 2606 OID 26210)
-- Name: lead pk_lead; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead
    ADD CONSTRAINT pk_lead PRIMARY KEY (id_lead);


--
-- TOC entry 7358 (class 2606 OID 33399)
-- Name: localidade pk_localidade; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localidade
    ADD CONSTRAINT pk_localidade PRIMARY KEY (id_localidade);


--
-- TOC entry 7166 (class 2606 OID 26527)
-- Name: localizacao_ativo pk_localizacao_ativo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localizacao_ativo
    ADD CONSTRAINT pk_localizacao_ativo PRIMARY KEY (id_localizacao);


--
-- TOC entry 7260 (class 2606 OID 27182)
-- Name: log_api pk_log_api; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_api
    ADD CONSTRAINT pk_log_api PRIMARY KEY (id_log);


--
-- TOC entry 7080 (class 2606 OID 25888)
-- Name: log_auditoria pk_log_auditoria; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_auditoria
    ADD CONSTRAINT pk_log_auditoria PRIMARY KEY (id_log);


--
-- TOC entry 7100 (class 2606 OID 26029)
-- Name: log_integracao pk_log_integracao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_integracao
    ADD CONSTRAINT pk_log_integracao PRIMARY KEY (id_log);


--
-- TOC entry 7314 (class 2606 OID 27535)
-- Name: log_integracao_detalhado pk_log_integracao_detalhado; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_integracao_detalhado
    ADD CONSTRAINT pk_log_integracao_detalhado PRIMARY KEY (id_log_integracao);


--
-- TOC entry 7242 (class 2606 OID 27072)
-- Name: log_sistema pk_log_sistema; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_sistema
    ADD CONSTRAINT pk_log_sistema PRIMARY KEY (id_log);


--
-- TOC entry 7164 (class 2606 OID 26511)
-- Name: manutencao_ativo pk_manutencao_ativo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manutencao_ativo
    ADD CONSTRAINT pk_manutencao_ativo PRIMARY KEY (id_manutencao);


--
-- TOC entry 7308 (class 2606 OID 27461)
-- Name: mapeamento_campo_integracao pk_mapeamento_campo_integracao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapeamento_campo_integracao
    ADD CONSTRAINT pk_mapeamento_campo_integracao PRIMARY KEY (id_mapeamento);


--
-- TOC entry 7286 (class 2606 OID 27320)
-- Name: modelo_ml pk_modelo_ml; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modelo_ml
    ADD CONSTRAINT pk_modelo_ml PRIMARY KEY (id_modelo);


--
-- TOC entry 7170 (class 2606 OID 26541)
-- Name: movimentacao_ativo pk_movimentacao_ativo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimentacao_ativo
    ADD CONSTRAINT pk_movimentacao_ativo PRIMARY KEY (id_movimentacao);


--
-- TOC entry 7190 (class 2606 OID 26687)
-- Name: movimento_estoque pk_movimento_estoque; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimento_estoque
    ADD CONSTRAINT pk_movimento_estoque PRIMARY KEY (id_movimento);


--
-- TOC entry 7052 (class 2606 OID 25600)
-- Name: nota_fiscal pk_nota_fiscal; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nota_fiscal
    ADD CONSTRAINT pk_nota_fiscal PRIMARY KEY (id_nota_fiscal);


--
-- TOC entry 7238 (class 2606 OID 27044)
-- Name: notificacao pk_notificacao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificacao
    ADD CONSTRAINT pk_notificacao PRIMARY KEY (id_notificacao);


--
-- TOC entry 7092 (class 2606 OID 25969)
-- Name: openfinance_conexao pk_openfinance_conexao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.openfinance_conexao
    ADD CONSTRAINT pk_openfinance_conexao PRIMARY KEY (id_conexao);


--
-- TOC entry 7094 (class 2606 OID 25984)
-- Name: openfinance_movimento pk_openfinance_movimento; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.openfinance_movimento
    ADD CONSTRAINT pk_openfinance_movimento PRIMARY KEY (id_movimento);


--
-- TOC entry 7120 (class 2606 OID 26193)
-- Name: origem_lead pk_origem_lead; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.origem_lead
    ADD CONSTRAINT pk_origem_lead PRIMARY KEY (id_origem);


--
-- TOC entry 7034 (class 2606 OID 25462)
-- Name: pacote_viagem pk_pacote_viagem; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacote_viagem
    ADD CONSTRAINT pk_pacote_viagem PRIMARY KEY (id_pacote);


--
-- TOC entry 7090 (class 2606 OID 25946)
-- Name: pagamento_transacao pk_pagamento_transacao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamento_transacao
    ADD CONSTRAINT pk_pagamento_transacao PRIMARY KEY (id_transacao);


--
-- TOC entry 7228 (class 2606 OID 26999)
-- Name: parametro_sistema pk_parametro_sistema; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parametro_sistema
    ADD CONSTRAINT pk_parametro_sistema PRIMARY KEY (id_parametro);


--
-- TOC entry 7144 (class 2606 OID 26359)
-- Name: parceiro_comercial pk_parceiro_comercial; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parceiro_comercial
    ADD CONSTRAINT pk_parceiro_comercial PRIMARY KEY (id_parceiro);


--
-- TOC entry 7042 (class 2606 OID 25511)
-- Name: passageiro pk_passageiro; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passageiro
    ADD CONSTRAINT pk_passageiro PRIMARY KEY (id_passageiro);


--
-- TOC entry 7182 (class 2606 OID 26628)
-- Name: pedido_compra pk_pedido_compra; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido_compra
    ADD CONSTRAINT pk_pedido_compra PRIMARY KEY (id_pedido);


--
-- TOC entry 7070 (class 2606 OID 25839)
-- Name: perfil_acesso pk_perfil_acesso; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfil_acesso
    ADD CONSTRAINT pk_perfil_acesso PRIMARY KEY (id_perfil);


--
-- TOC entry 7074 (class 2606 OID 25855)
-- Name: permissao pk_permissao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissao
    ADD CONSTRAINT pk_permissao PRIMARY KEY (id_permissao);


--
-- TOC entry 6982 (class 2606 OID 25121)
-- Name: pessoa pk_pessoa; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pessoa
    ADD CONSTRAINT pk_pessoa PRIMARY KEY (id_pessoa);


--
-- TOC entry 6994 (class 2606 OID 25191)
-- Name: plano_contas pk_plano_contas; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plano_contas
    ADD CONSTRAINT pk_plano_contas PRIMARY KEY (id_conta);


--
-- TOC entry 7292 (class 2606 OID 27356)
-- Name: politica_acesso pk_politica_acesso; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.politica_acesso
    ADD CONSTRAINT pk_politica_acesso PRIMARY KEY (id_politica);


--
-- TOC entry 7066 (class 2606 OID 25740)
-- Name: pro_labore pk_pro_labore; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pro_labore
    ADD CONSTRAINT pk_pro_labore PRIMARY KEY (id_pro_labore);


--
-- TOC entry 7172 (class 2606 OID 26573)
-- Name: produto_estoque pk_produto_estoque; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto_estoque
    ADD CONSTRAINT pk_produto_estoque PRIMARY KEY (id_produto_estoque);


--
-- TOC entry 7030 (class 2606 OID 25446)
-- Name: produto_turistico pk_produto_turistico; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto_turistico
    ADD CONSTRAINT pk_produto_turistico PRIMARY KEY (id_produto);


--
-- TOC entry 7212 (class 2606 OID 26871)
-- Name: projeto pk_projeto; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projeto
    ADD CONSTRAINT pk_projeto PRIMARY KEY (id_projeto);


--
-- TOC entry 7296 (class 2606 OID 27372)
-- Name: rastreabilidade pk_rastreabilidade; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rastreabilidade
    ADD CONSTRAINT pk_rastreabilidade PRIMARY KEY (id_rastreabilidade);


--
-- TOC entry 7262 (class 2606 OID 27198)
-- Name: rate_limit_api pk_rate_limit_api; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rate_limit_api
    ADD CONSTRAINT pk_rate_limit_api PRIMARY KEY (id_rate);


--
-- TOC entry 7352 (class 2606 OID 27747)
-- Name: rentabilidade_produto pk_rentabilidade_produto; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rentabilidade_produto
    ADD CONSTRAINT pk_rentabilidade_produto PRIMARY KEY (id_rentabilidade);


--
-- TOC entry 7176 (class 2606 OID 26589)
-- Name: requisicao_compra pk_requisicao_compra; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.requisicao_compra
    ADD CONSTRAINT pk_requisicao_compra PRIMARY KEY (id_requisicao);


--
-- TOC entry 7038 (class 2606 OID 25485)
-- Name: reserva pk_reserva; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva
    ADD CONSTRAINT pk_reserva PRIMARY KEY (id_reserva);


--
-- TOC entry 7220 (class 2606 OID 26921)
-- Name: responsavel_projeto pk_responsavel_projeto; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.responsavel_projeto
    ADD CONSTRAINT pk_responsavel_projeto PRIMARY KEY (id_responsavel);


--
-- TOC entry 7224 (class 2606 OID 26958)
-- Name: risco_projeto pk_risco_projeto; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risco_projeto
    ADD CONSTRAINT pk_risco_projeto PRIMARY KEY (id_risco);


--
-- TOC entry 7106 (class 2606 OID 26063)
-- Name: roteiro_viagem pk_roteiro_viagem; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roteiro_viagem
    ADD CONSTRAINT pk_roteiro_viagem PRIMARY KEY (id_roteiro);


--
-- TOC entry 7234 (class 2606 OID 27029)
-- Name: sequencia_documento pk_sequencia_documento; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sequencia_documento
    ADD CONSTRAINT pk_sequencia_documento PRIMARY KEY (id_sequencia);


--
-- TOC entry 7058 (class 2606 OID 25634)
-- Name: simples_nacional pk_simples_nacional; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.simples_nacional
    ADD CONSTRAINT pk_simples_nacional PRIMARY KEY (id_simples);


--
-- TOC entry 7310 (class 2606 OID 27487)
-- Name: sincronizacao_integracao pk_sincronizacao_integracao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sincronizacao_integracao
    ADD CONSTRAINT pk_sincronizacao_integracao PRIMARY KEY (id_sincronizacao);


--
-- TOC entry 7300 (class 2606 OID 27413)
-- Name: sistema_externo pk_sistema_externo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sistema_externo
    ADD CONSTRAINT pk_sistema_externo PRIMARY KEY (id_sistema_externo);


--
-- TOC entry 7316 (class 2606 OID 27565)
-- Name: status_integracao pk_status_integracao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_integracao
    ADD CONSTRAINT pk_status_integracao PRIMARY KEY (id_status_integracao);


--
-- TOC entry 7362 (class 2606 OID 33445)
-- Name: status_parcela pk_status_parcela; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_parcela
    ADD CONSTRAINT pk_status_parcela PRIMARY KEY (id_status_parcela);


--
-- TOC entry 7006 (class 2606 OID 25249)
-- Name: subcategoria_conta pk_subcategoria_conta; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subcategoria_conta
    ADD CONSTRAINT pk_subcategoria_conta PRIMARY KEY (id_subcategoria);


--
-- TOC entry 7150 (class 2606 OID 26414)
-- Name: tarefa pk_tarefa; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarefa
    ADD CONSTRAINT pk_tarefa PRIMARY KEY (id_tarefa);


--
-- TOC entry 7218 (class 2606 OID 26905)
-- Name: tarefa_projeto pk_tarefa_projeto; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarefa_projeto
    ADD CONSTRAINT pk_tarefa_projeto PRIMARY KEY (id_tarefa_projeto);


--
-- TOC entry 7196 (class 2606 OID 26745)
-- Name: tipo_documento pk_tipo_documento; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_documento
    ADD CONSTRAINT pk_tipo_documento PRIMARY KEY (id_tipo_documento);


--
-- TOC entry 7252 (class 2606 OID 27121)
-- Name: token_acesso pk_token_acesso; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.token_acesso
    ADD CONSTRAINT pk_token_acesso PRIMARY KEY (id_token);


--
-- TOC entry 7112 (class 2606 OID 26122)
-- Name: transporte pk_transporte; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transporte
    ADD CONSTRAINT pk_transporte PRIMARY KEY (id_transporte);


--
-- TOC entry 6978 (class 2606 OID 25104)
-- Name: usuario pk_usuario; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT pk_usuario PRIMARY KEY (id_usuario);


--
-- TOC entry 7078 (class 2606 OID 25865)
-- Name: usuario_perfil pk_usuario_perfil; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_perfil
    ADD CONSTRAINT pk_usuario_perfil PRIMARY KEY (id_usuario, id_perfil);


--
-- TOC entry 7046 (class 2606 OID 25552)
-- Name: venda pk_venda; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venda
    ADD CONSTRAINT pk_venda PRIMARY KEY (id_venda);


--
-- TOC entry 7256 (class 2606 OID 27157)
-- Name: webhook pk_webhook; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.webhook
    ADD CONSTRAINT pk_webhook PRIMARY KEY (id_webhook);


--
-- TOC entry 7354 (class 2606 OID 33279)
-- Name: workflow pk_workflow; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow
    ADD CONSTRAINT pk_workflow PRIMARY KEY (id_workflow);


--
-- TOC entry 7246 (class 2606 OID 27085)
-- Name: agendamento_rotina uk_agendamento_rotina_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agendamento_rotina
    ADD CONSTRAINT uk_agendamento_rotina_codigo UNIQUE (codigo);


--
-- TOC entry 7250 (class 2606 OID 27107)
-- Name: aplicacao_api uk_aplicacao_api_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aplicacao_api
    ADD CONSTRAINT uk_aplicacao_api_codigo UNIQUE (codigo);


--
-- TOC entry 7160 (class 2606 OID 26476)
-- Name: ativo_imobilizado uk_ativo_imobilizado_codigo_patrimonio; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ativo_imobilizado
    ADD CONSTRAINT uk_ativo_imobilizado_codigo_patrimonio UNIQUE (codigo_patrimonio);


--
-- TOC entry 7128 (class 2606 OID 26230)
-- Name: campanha uk_campanha_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.campanha
    ADD CONSTRAINT uk_campanha_codigo UNIQUE (codigo);


--
-- TOC entry 7140 (class 2606 OID 26323)
-- Name: cargo uk_cargo_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cargo
    ADD CONSTRAINT uk_cargo_codigo UNIQUE (codigo);


--
-- TOC entry 7156 (class 2606 OID 26457)
-- Name: categoria_ativo uk_categoria_ativo_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria_ativo
    ADD CONSTRAINT uk_categoria_ativo_codigo UNIQUE (codigo);


--
-- TOC entry 7004 (class 2606 OID 25231)
-- Name: categoria_conta uk_categoria_conta_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria_conta
    ADD CONSTRAINT uk_categoria_conta_codigo UNIQUE (codigo);


--
-- TOC entry 7012 (class 2606 OID 25272)
-- Name: centro_custo uk_centro_custo_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.centro_custo
    ADD CONSTRAINT uk_centro_custo_codigo UNIQUE (codigo);


--
-- TOC entry 7016 (class 2606 OID 25289)
-- Name: classificacao_dre uk_classificacao_dre_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.classificacao_dre
    ADD CONSTRAINT uk_classificacao_dre_codigo UNIQUE (codigo);


--
-- TOC entry 6986 (class 2606 OID 25137)
-- Name: cliente uk_cliente_codigo_cliente; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT uk_cliente_codigo_cliente UNIQUE (codigo_cliente);


--
-- TOC entry 7306 (class 2606 OID 27437)
-- Name: conector_integracao uk_conector_integracao_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conector_integracao
    ADD CONSTRAINT uk_conector_integracao_codigo UNIQUE (codigo);


--
-- TOC entry 7104 (class 2606 OID 26048)
-- Name: destino uk_destino_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.destino
    ADD CONSTRAINT uk_destino_codigo UNIQUE (codigo);


--
-- TOC entry 7335 (class 2606 OID 27656)
-- Name: dim_data uk_dim_data_data; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dim_data
    ADD CONSTRAINT uk_dim_data_data UNIQUE (data);


--
-- TOC entry 7022 (class 2606 OID 25328)
-- Name: forma_pagamento uk_forma_pagamento_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.forma_pagamento
    ADD CONSTRAINT uk_forma_pagamento_codigo UNIQUE (codigo);


--
-- TOC entry 6990 (class 2606 OID 25157)
-- Name: fornecedor uk_fornecedor_codigo_fornecedor; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fornecedor
    ADD CONSTRAINT uk_fornecedor_codigo_fornecedor UNIQUE (codigo_fornecedor);


--
-- TOC entry 7088 (class 2606 OID 25935)
-- Name: gateway_pagamento uk_gateway_pagamento_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.gateway_pagamento
    ADD CONSTRAINT uk_gateway_pagamento_codigo UNIQUE (codigo);


--
-- TOC entry 7000 (class 2606 OID 25215)
-- Name: grupo_conta uk_grupo_conta_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.grupo_conta
    ADD CONSTRAINT uk_grupo_conta_codigo UNIQUE (codigo);


--
-- TOC entry 7056 (class 2606 OID 25622)
-- Name: imposto uk_imposto_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.imposto
    ADD CONSTRAINT uk_imposto_codigo UNIQUE (codigo);


--
-- TOC entry 7350 (class 2606 OID 27724)
-- Name: kpi_turismo uk_kpi_turismo_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.kpi_turismo
    ADD CONSTRAINT uk_kpi_turismo_codigo UNIQUE (codigo);


--
-- TOC entry 7360 (class 2606 OID 33401)
-- Name: localidade uk_localidade_cidade_uf_pais; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localidade
    ADD CONSTRAINT uk_localidade_cidade_uf_pais UNIQUE (cidade, uf, pais);


--
-- TOC entry 7168 (class 2606 OID 26529)
-- Name: localizacao_ativo uk_localizacao_ativo_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.localizacao_ativo
    ADD CONSTRAINT uk_localizacao_ativo_codigo UNIQUE (codigo);


--
-- TOC entry 7288 (class 2606 OID 27322)
-- Name: modelo_ml uk_modelo_ml_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.modelo_ml
    ADD CONSTRAINT uk_modelo_ml_codigo UNIQUE (codigo);


--
-- TOC entry 7122 (class 2606 OID 26195)
-- Name: origem_lead uk_origem_lead_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.origem_lead
    ADD CONSTRAINT uk_origem_lead_codigo UNIQUE (codigo);


--
-- TOC entry 7036 (class 2606 OID 25464)
-- Name: pacote_viagem uk_pacote_viagem_codigo_pacote; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacote_viagem
    ADD CONSTRAINT uk_pacote_viagem_codigo_pacote UNIQUE (codigo_pacote);


--
-- TOC entry 7230 (class 2606 OID 27001)
-- Name: parametro_sistema uk_parametro_sistema_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parametro_sistema
    ADD CONSTRAINT uk_parametro_sistema_codigo UNIQUE (codigo);


--
-- TOC entry 7184 (class 2606 OID 26630)
-- Name: pedido_compra uk_pedido_compra_numero_pedido; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido_compra
    ADD CONSTRAINT uk_pedido_compra_numero_pedido UNIQUE (numero_pedido);


--
-- TOC entry 7072 (class 2606 OID 25841)
-- Name: perfil_acesso uk_perfil_acesso_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.perfil_acesso
    ADD CONSTRAINT uk_perfil_acesso_codigo UNIQUE (codigo);


--
-- TOC entry 7076 (class 2606 OID 25857)
-- Name: permissao uk_permissao_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.permissao
    ADD CONSTRAINT uk_permissao_codigo UNIQUE (codigo);


--
-- TOC entry 6996 (class 2606 OID 25193)
-- Name: plano_contas uk_plano_contas_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plano_contas
    ADD CONSTRAINT uk_plano_contas_codigo UNIQUE (codigo);


--
-- TOC entry 7294 (class 2606 OID 27358)
-- Name: politica_acesso uk_politica_acesso_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.politica_acesso
    ADD CONSTRAINT uk_politica_acesso_codigo UNIQUE (codigo);


--
-- TOC entry 7174 (class 2606 OID 26575)
-- Name: produto_estoque uk_produto_estoque_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto_estoque
    ADD CONSTRAINT uk_produto_estoque_codigo UNIQUE (codigo);


--
-- TOC entry 7032 (class 2606 OID 25448)
-- Name: produto_turistico uk_produto_turistico_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.produto_turistico
    ADD CONSTRAINT uk_produto_turistico_codigo UNIQUE (codigo);


--
-- TOC entry 7214 (class 2606 OID 26873)
-- Name: projeto uk_projeto_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.projeto
    ADD CONSTRAINT uk_projeto_codigo UNIQUE (codigo);


--
-- TOC entry 7178 (class 2606 OID 26591)
-- Name: requisicao_compra uk_requisicao_compra_numero_requisicao; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.requisicao_compra
    ADD CONSTRAINT uk_requisicao_compra_numero_requisicao UNIQUE (numero_requisicao);


--
-- TOC entry 7040 (class 2606 OID 25487)
-- Name: reserva uk_reserva_codigo_reserva; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva
    ADD CONSTRAINT uk_reserva_codigo_reserva UNIQUE (codigo_reserva);


--
-- TOC entry 7236 (class 2606 OID 27031)
-- Name: sequencia_documento uk_sequencia_documento_tipo_documento_ano; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sequencia_documento
    ADD CONSTRAINT uk_sequencia_documento_tipo_documento_ano UNIQUE (tipo_documento, ano);


--
-- TOC entry 7302 (class 2606 OID 27415)
-- Name: sistema_externo uk_sistema_externo_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sistema_externo
    ADD CONSTRAINT uk_sistema_externo_codigo UNIQUE (codigo);


--
-- TOC entry 7364 (class 2606 OID 33447)
-- Name: status_parcela uk_status_parcela_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_parcela
    ADD CONSTRAINT uk_status_parcela_codigo UNIQUE (codigo);


--
-- TOC entry 7008 (class 2606 OID 25251)
-- Name: subcategoria_conta uk_subcategoria_conta_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subcategoria_conta
    ADD CONSTRAINT uk_subcategoria_conta_codigo UNIQUE (codigo);


--
-- TOC entry 7198 (class 2606 OID 26747)
-- Name: tipo_documento uk_tipo_documento_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tipo_documento
    ADD CONSTRAINT uk_tipo_documento_codigo UNIQUE (codigo);


--
-- TOC entry 6980 (class 2606 OID 25106)
-- Name: usuario uk_usuario_email; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT uk_usuario_email UNIQUE (email);


--
-- TOC entry 7048 (class 2606 OID 25554)
-- Name: venda uk_venda_numero_venda; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venda
    ADD CONSTRAINT uk_venda_numero_venda UNIQUE (numero_venda);


--
-- TOC entry 7356 (class 2606 OID 33281)
-- Name: workflow uk_workflow_codigo; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.workflow
    ADD CONSTRAINT uk_workflow_codigo UNIQUE (codigo);


--
-- TOC entry 7511 (class 1259 OID 43301)
-- Name: idx_auditoria_pos_1045_resultado; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_auditoria_pos_1045_resultado ON auditoria.auditoria_pos_padronizacao_10_4_5 USING btree (resultado);


--
-- TOC entry 7512 (class 1259 OID 43303)
-- Name: idx_auditoria_pos_1045_schema_table; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_auditoria_pos_1045_schema_table ON auditoria.auditoria_pos_padronizacao_10_4_5 USING btree (schema_name, table_name);


--
-- TOC entry 7513 (class 1259 OID 43302)
-- Name: idx_auditoria_pos_1045_tipo; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_auditoria_pos_1045_tipo ON auditoria.auditoria_pos_padronizacao_10_4_5 USING btree (constraint_type);


--
-- TOC entry 7514 (class 1259 OID 43304)
-- Name: idx_auditoria_pos_1045_truncado; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_auditoria_pos_1045_truncado ON auditoria.auditoria_pos_padronizacao_10_4_5 USING btree (nome_truncado);


--
-- TOC entry 7371 (class 1259 OID 41487)
-- Name: idx_categoria_ativo; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_categoria_ativo ON auditoria.categoria USING btree (ativo);


--
-- TOC entry 7372 (class 1259 OID 41486)
-- Name: idx_categoria_codigo; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_categoria_codigo ON auditoria.categoria USING btree (codigo);


--
-- TOC entry 7443 (class 1259 OID 42682)
-- Name: idx_execucao_correcao_script; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_execucao_correcao_script ON auditoria.execucao_correcao USING btree (script);


--
-- TOC entry 7444 (class 1259 OID 42683)
-- Name: idx_execucao_correcao_status; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_execucao_correcao_status ON auditoria.execucao_correcao USING btree (status);


--
-- TOC entry 7365 (class 1259 OID 41464)
-- Name: idx_execucao_data; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_execucao_data ON auditoria.execucao USING btree (data_inicio);


--
-- TOC entry 7366 (class 1259 OID 41466)
-- Name: idx_execucao_score; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_execucao_score ON auditoria.execucao USING btree (score_final);


--
-- TOC entry 7367 (class 1259 OID 41465)
-- Name: idx_execucao_status; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_execucao_status ON auditoria.execucao USING btree (status_execucao);


--
-- TOC entry 7368 (class 1259 OID 41467)
-- Name: idx_execucao_usuario; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_execucao_usuario ON auditoria.execucao USING btree (usuario_execucao);


--
-- TOC entry 7433 (class 1259 OID 41845)
-- Name: idx_executor_ativo; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_executor_ativo ON auditoria.executor USING btree (ativo);


--
-- TOC entry 7434 (class 1259 OID 41844)
-- Name: idx_executor_codigo; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_executor_codigo ON auditoria.executor USING btree (codigo);


--
-- TOC entry 7377 (class 1259 OID 41516)
-- Name: idx_item_categoria; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_item_categoria ON auditoria.item USING btree (id_categoria);


--
-- TOC entry 7378 (class 1259 OID 41517)
-- Name: idx_item_codigo; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_item_codigo ON auditoria.item USING btree (codigo);


--
-- TOC entry 7379 (class 1259 OID 41518)
-- Name: idx_item_criticidade; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_item_criticidade ON auditoria.item USING btree (criticidade);


--
-- TOC entry 7493 (class 1259 OID 43085)
-- Name: idx_mapa_padronizacao_fora_padrao; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_mapa_padronizacao_fora_padrao ON auditoria.mapa_padronizacao_constraints USING btree (fora_do_padrao);


--
-- TOC entry 7494 (class 1259 OID 43083)
-- Name: idx_mapa_padronizacao_schema_tabela; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_mapa_padronizacao_schema_tabela ON auditoria.mapa_padronizacao_constraints USING btree (schema_name, table_name);


--
-- TOC entry 7495 (class 1259 OID 43086)
-- Name: idx_mapa_padronizacao_status; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_mapa_padronizacao_status ON auditoria.mapa_padronizacao_constraints USING btree (status_mapa);


--
-- TOC entry 7496 (class 1259 OID 43084)
-- Name: idx_mapa_padronizacao_tipo; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_mapa_padronizacao_tipo ON auditoria.mapa_padronizacao_constraints USING btree (constraint_type);


--
-- TOC entry 7394 (class 1259 OID 41593)
-- Name: idx_recomendacao_corrigido; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_recomendacao_corrigido ON auditoria.recomendacao USING btree (corrigido);


--
-- TOC entry 7395 (class 1259 OID 41591)
-- Name: idx_recomendacao_execucao; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_recomendacao_execucao ON auditoria.recomendacao USING btree (id_execucao);


--
-- TOC entry 7396 (class 1259 OID 41592)
-- Name: idx_recomendacao_prioridade; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_recomendacao_prioridade ON auditoria.recomendacao USING btree (prioridade);


--
-- TOC entry 7409 (class 1259 OID 41817)
-- Name: idx_regra_ativo; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_regra_ativo ON auditoria.regra USING btree (ativo);


--
-- TOC entry 7410 (class 1259 OID 41818)
-- Name: idx_regra_objeto; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_regra_objeto ON auditoria.regra USING btree (tipo_objeto);


--
-- TOC entry 7411 (class 1259 OID 41819)
-- Name: idx_regra_ordem; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_regra_ordem ON auditoria.regra USING btree (ordem_execucao);


--
-- TOC entry 7412 (class 1259 OID 41820)
-- Name: idx_regra_prioridade; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_regra_prioridade ON auditoria.regra USING btree (prioridade);


--
-- TOC entry 7384 (class 1259 OID 41546)
-- Name: idx_resultado_execucao; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_resultado_execucao ON auditoria.resultado USING btree (id_execucao);


--
-- TOC entry 7385 (class 1259 OID 41547)
-- Name: idx_resultado_item; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_resultado_item ON auditoria.resultado USING btree (id_item);


--
-- TOC entry 7386 (class 1259 OID 41550)
-- Name: idx_resultado_severidade; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_resultado_severidade ON auditoria.resultado USING btree (severidade);


--
-- TOC entry 7387 (class 1259 OID 41548)
-- Name: idx_resultado_status; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_resultado_status ON auditoria.resultado USING btree (status);


--
-- TOC entry 7388 (class 1259 OID 41549)
-- Name: idx_resultado_tabela; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_resultado_tabela ON auditoria.resultado USING btree (tabela_nome);


--
-- TOC entry 7391 (class 1259 OID 41567)
-- Name: idx_score_execucao; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_score_execucao ON auditoria.score USING btree (id_execucao);


--
-- TOC entry 7499 (class 1259 OID 43143)
-- Name: idx_validacao_padronizacao_colisao; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_validacao_padronizacao_colisao ON auditoria.validacao_padronizacao_constraints USING btree (possui_colisao);


--
-- TOC entry 7500 (class 1259 OID 43142)
-- Name: idx_validacao_padronizacao_schema_table; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_validacao_padronizacao_schema_table ON auditoria.validacao_padronizacao_constraints USING btree (schema_name, table_name);


--
-- TOC entry 7501 (class 1259 OID 43140)
-- Name: idx_validacao_padronizacao_status; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_validacao_padronizacao_status ON auditoria.validacao_padronizacao_constraints USING btree (status_validacao);


--
-- TOC entry 7502 (class 1259 OID 43141)
-- Name: idx_validacao_padronizacao_tipo; Type: INDEX; Schema: auditoria; Owner: postgres
--

CREATE INDEX idx_validacao_padronizacao_tipo ON auditoria.validacao_padronizacao_constraints USING btree (constraint_type);


--
-- TOC entry 6917 (class 1259 OID 24844)
-- Name: idx_banco_codigo; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_banco_codigo ON financeiro.banco USING btree (codigo_banco);


--
-- TOC entry 6885 (class 1259 OID 24833)
-- Name: idx_categoria_codigo; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_categoria_codigo ON financeiro.categoria USING btree (codigo);


--
-- TOC entry 6886 (class 1259 OID 24832)
-- Name: idx_categoria_grupo; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_categoria_grupo ON financeiro.categoria USING btree (id_grupo);


--
-- TOC entry 6897 (class 1259 OID 25070)
-- Name: idx_classificacao_ativo; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_classificacao_ativo ON financeiro.classificacao USING btree (ativo);


--
-- TOC entry 6898 (class 1259 OID 24837)
-- Name: idx_classificacao_codigo; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_classificacao_codigo ON financeiro.classificacao USING btree (codigo);


--
-- TOC entry 6899 (class 1259 OID 25071)
-- Name: idx_classificacao_deleted; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_classificacao_deleted ON financeiro.classificacao USING btree (deleted_at);


--
-- TOC entry 6900 (class 1259 OID 25068)
-- Name: idx_classificacao_dre; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_classificacao_dre ON financeiro.classificacao USING btree (id_tipo_dre);


--
-- TOC entry 6901 (class 1259 OID 25069)
-- Name: idx_classificacao_natureza; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_classificacao_natureza ON financeiro.classificacao USING btree (id_natureza_financeira);


--
-- TOC entry 6902 (class 1259 OID 24836)
-- Name: idx_classificacao_subcategoria; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_classificacao_subcategoria ON financeiro.classificacao USING btree (id_subcategoria);


--
-- TOC entry 6925 (class 1259 OID 24841)
-- Name: idx_cliente_documento; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_cliente_documento ON financeiro.cliente USING btree (cpf_cnpj);


--
-- TOC entry 6926 (class 1259 OID 24840)
-- Name: idx_cliente_nome; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_cliente_nome ON financeiro.cliente USING btree (nome);


--
-- TOC entry 6922 (class 1259 OID 24845)
-- Name: idx_conta_bancaria_banco; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_conta_bancaria_banco ON financeiro.conta_bancaria USING btree (id_banco);


--
-- TOC entry 6907 (class 1259 OID 24838)
-- Name: idx_conta_classificacao; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_conta_classificacao ON financeiro.conta USING btree (id_classificacao);


--
-- TOC entry 6908 (class 1259 OID 24839)
-- Name: idx_conta_codigo; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_conta_codigo ON financeiro.conta USING btree (codigo);


--
-- TOC entry 6871 (class 1259 OID 24846)
-- Name: idx_empresa_cnpj; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_empresa_cnpj ON financeiro.empresa USING btree (cnpj);


--
-- TOC entry 6931 (class 1259 OID 24843)
-- Name: idx_fornecedor_documento; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_fornecedor_documento ON financeiro.fornecedor USING btree (cpf_cnpj);


--
-- TOC entry 6932 (class 1259 OID 24842)
-- Name: idx_fornecedor_nome; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_fornecedor_nome ON financeiro.fornecedor USING btree (nome);


--
-- TOC entry 6880 (class 1259 OID 24831)
-- Name: idx_grupo_codigo; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_grupo_codigo ON financeiro.grupo USING btree (codigo);


--
-- TOC entry 6891 (class 1259 OID 24834)
-- Name: idx_subcategoria_categoria; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_subcategoria_categoria ON financeiro.subcategoria USING btree (id_categoria);


--
-- TOC entry 6892 (class 1259 OID 24835)
-- Name: idx_subcategoria_codigo; Type: INDEX; Schema: financeiro; Owner: postgres
--

CREATE INDEX idx_subcategoria_codigo ON financeiro.subcategoria USING btree (codigo);


--
-- TOC entry 7336 (class 1259 OID 27703)
-- Name: idx_dim_cliente_nome; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dim_cliente_nome ON public.dim_cliente USING btree (nome_cliente);


--
-- TOC entry 7331 (class 1259 OID 27702)
-- Name: idx_dim_data_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dim_data_data ON public.dim_data USING btree (data);


--
-- TOC entry 7341 (class 1259 OID 27704)
-- Name: idx_dim_destino_nome; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dim_destino_nome ON public.dim_destino USING btree (nome_destino);


--
-- TOC entry 7344 (class 1259 OID 27705)
-- Name: idx_dim_plano_codigo; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_dim_plano_codigo ON public.dim_plano_contas USING btree (codigo);


--
-- TOC entry 7325 (class 1259 OID 27637)
-- Name: idx_fato_financeiro_centro; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fato_financeiro_centro ON public.fato_financeiro USING btree (id_centro_custo);


--
-- TOC entry 7326 (class 1259 OID 27635)
-- Name: idx_fato_financeiro_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fato_financeiro_data ON public.fato_financeiro USING btree (data_movimento);


--
-- TOC entry 7327 (class 1259 OID 27638)
-- Name: idx_fato_financeiro_natureza; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fato_financeiro_natureza ON public.fato_financeiro USING btree (natureza);


--
-- TOC entry 7328 (class 1259 OID 27636)
-- Name: idx_fato_financeiro_plano; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fato_financeiro_plano ON public.fato_financeiro USING btree (id_plano_contas);


--
-- TOC entry 7319 (class 1259 OID 27615)
-- Name: idx_fato_vendas_cliente; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fato_vendas_cliente ON public.fato_vendas USING btree (id_cliente);


--
-- TOC entry 7320 (class 1259 OID 27614)
-- Name: idx_fato_vendas_data; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fato_vendas_data ON public.fato_vendas USING btree (data_venda);


--
-- TOC entry 7321 (class 1259 OID 27617)
-- Name: idx_fato_vendas_destino; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fato_vendas_destino ON public.fato_vendas USING btree (id_destino);


--
-- TOC entry 7322 (class 1259 OID 27616)
-- Name: idx_fato_vendas_produto; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_fato_vendas_produto ON public.fato_vendas USING btree (id_produto_turistico);


--
-- TOC entry 7837 (class 2620 OID 42332)
-- Name: catalogo_coluna trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.catalogo_coluna FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8323 (class 0 OID 0)
-- Dependencies: 7837
-- Name: TRIGGER trg_atualiza_updated_at ON catalogo_coluna; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.catalogo_coluna IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela catalogo_coluna é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7835 (class 2620 OID 42330)
-- Name: catalogo_schema trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.catalogo_schema FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8324 (class 0 OID 0)
-- Dependencies: 7835
-- Name: TRIGGER trg_atualiza_updated_at ON catalogo_schema; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.catalogo_schema IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela catalogo_schema é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7836 (class 2620 OID 42331)
-- Name: catalogo_tabela trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.catalogo_tabela FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8325 (class 0 OID 0)
-- Dependencies: 7836
-- Name: TRIGGER trg_atualiza_updated_at ON catalogo_tabela; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.catalogo_tabela IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela catalogo_tabela é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7826 (class 2620 OID 42321)
-- Name: categoria trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.categoria FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8326 (class 0 OID 0)
-- Dependencies: 7826
-- Name: TRIGGER trg_atualiza_updated_at ON categoria; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.categoria IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela categoria é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7832 (class 2620 OID 42327)
-- Name: configuracao trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.configuracao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8327 (class 0 OID 0)
-- Dependencies: 7832
-- Name: TRIGGER trg_atualiza_updated_at ON configuracao; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.configuracao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela configuracao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7839 (class 2620 OID 42334)
-- Name: core trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.core FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8328 (class 0 OID 0)
-- Dependencies: 7839
-- Name: TRIGGER trg_atualiza_updated_at ON core; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.core IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela core é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7825 (class 2620 OID 42320)
-- Name: execucao trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.execucao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8329 (class 0 OID 0)
-- Dependencies: 7825
-- Name: TRIGGER trg_atualiza_updated_at ON execucao; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.execucao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela execucao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7838 (class 2620 OID 42333)
-- Name: executor trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.executor FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8330 (class 0 OID 0)
-- Dependencies: 7838
-- Name: TRIGGER trg_atualiza_updated_at ON executor; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.executor IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela executor é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7827 (class 2620 OID 42322)
-- Name: item trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.item FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8331 (class 0 OID 0)
-- Dependencies: 7827
-- Name: TRIGGER trg_atualiza_updated_at ON item; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.item IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela item é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7831 (class 2620 OID 42326)
-- Name: log trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.log FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8332 (class 0 OID 0)
-- Dependencies: 7831
-- Name: TRIGGER trg_atualiza_updated_at ON log; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.log IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela log é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7830 (class 2620 OID 42325)
-- Name: recomendacao trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.recomendacao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8333 (class 0 OID 0)
-- Dependencies: 7830
-- Name: TRIGGER trg_atualiza_updated_at ON recomendacao; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.recomendacao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela recomendacao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7834 (class 2620 OID 42329)
-- Name: regra trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.regra FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8334 (class 0 OID 0)
-- Dependencies: 7834
-- Name: TRIGGER trg_atualiza_updated_at ON regra; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.regra IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela regra é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7828 (class 2620 OID 42323)
-- Name: resultado trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.resultado FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8335 (class 0 OID 0)
-- Dependencies: 7828
-- Name: TRIGGER trg_atualiza_updated_at ON resultado; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.resultado IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela resultado é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7829 (class 2620 OID 42324)
-- Name: score trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.score FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8336 (class 0 OID 0)
-- Dependencies: 7829
-- Name: TRIGGER trg_atualiza_updated_at ON score; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.score IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela score é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7833 (class 2620 OID 42328)
-- Name: script trg_atualiza_updated_at; Type: TRIGGER; Schema: auditoria; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON auditoria.script FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8337 (class 0 OID 0)
-- Dependencies: 7833
-- Name: TRIGGER trg_atualiza_updated_at ON script; Type: COMMENT; Schema: auditoria; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON auditoria.script IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela script é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7730 (class 2620 OID 42335)
-- Name: anexo trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.anexo FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8338 (class 0 OID 0)
-- Dependencies: 7730
-- Name: TRIGGER trg_atualiza_updated_at ON anexo; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.anexo IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela anexo é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7704 (class 2620 OID 42336)
-- Name: categoria trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.categoria FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8339 (class 0 OID 0)
-- Dependencies: 7704
-- Name: TRIGGER trg_atualiza_updated_at ON categoria; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.categoria IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela categoria é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7708 (class 2620 OID 42337)
-- Name: classificacao trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.classificacao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8340 (class 0 OID 0)
-- Dependencies: 7708
-- Name: TRIGGER trg_atualiza_updated_at ON classificacao; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.classificacao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela classificacao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7712 (class 2620 OID 42338)
-- Name: configuracao trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.configuracao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8341 (class 0 OID 0)
-- Dependencies: 7712
-- Name: TRIGGER trg_atualiza_updated_at ON configuracao; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.configuracao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela configuracao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7710 (class 2620 OID 42339)
-- Name: conta trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.conta FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8342 (class 0 OID 0)
-- Dependencies: 7710
-- Name: TRIGGER trg_atualiza_updated_at ON conta; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.conta IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela conta é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7702 (class 2620 OID 42340)
-- Name: grupo trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.grupo FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8343 (class 0 OID 0)
-- Dependencies: 7702
-- Name: TRIGGER trg_atualiza_updated_at ON grupo; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.grupo IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela grupo é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7728 (class 2620 OID 42341)
-- Name: historico_lancamento trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.historico_lancamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8344 (class 0 OID 0)
-- Dependencies: 7728
-- Name: TRIGGER trg_atualiza_updated_at ON historico_lancamento; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.historico_lancamento IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela historico_lancamento é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7720 (class 2620 OID 42342)
-- Name: lancamento trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.lancamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8345 (class 0 OID 0)
-- Dependencies: 7720
-- Name: TRIGGER trg_atualiza_updated_at ON lancamento; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.lancamento IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela lancamento é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7724 (class 2620 OID 42343)
-- Name: movimentacao_bancaria trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.movimentacao_bancaria FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8346 (class 0 OID 0)
-- Dependencies: 7724
-- Name: TRIGGER trg_atualiza_updated_at ON movimentacao_bancaria; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.movimentacao_bancaria IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela movimentacao_bancaria é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7722 (class 2620 OID 42344)
-- Name: pagamento trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.pagamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8347 (class 0 OID 0)
-- Dependencies: 7722
-- Name: TRIGGER trg_atualiza_updated_at ON pagamento; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.pagamento IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela pagamento é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7726 (class 2620 OID 42345)
-- Name: rateio_centro_custo trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.rateio_centro_custo FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8348 (class 0 OID 0)
-- Dependencies: 7726
-- Name: TRIGGER trg_atualiza_updated_at ON rateio_centro_custo; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.rateio_centro_custo IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela rateio_centro_custo é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7716 (class 2620 OID 42346)
-- Name: status_lancamento trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.status_lancamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8349 (class 0 OID 0)
-- Dependencies: 7716
-- Name: TRIGGER trg_atualiza_updated_at ON status_lancamento; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.status_lancamento IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela status_lancamento é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7706 (class 2620 OID 42347)
-- Name: subcategoria trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.subcategoria FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8350 (class 0 OID 0)
-- Dependencies: 7706
-- Name: TRIGGER trg_atualiza_updated_at ON subcategoria; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.subcategoria IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela subcategoria é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7714 (class 2620 OID 42348)
-- Name: tipo_lancamento trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.tipo_lancamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8351 (class 0 OID 0)
-- Dependencies: 7714
-- Name: TRIGGER trg_atualiza_updated_at ON tipo_lancamento; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.tipo_lancamento IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela tipo_lancamento é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7718 (class 2620 OID 42349)
-- Name: tipo_movimentacao trg_atualiza_updated_at; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.tipo_movimentacao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8352 (class 0 OID 0)
-- Dependencies: 7718
-- Name: TRIGGER trg_atualiza_updated_at ON tipo_movimentacao; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON financeiro.tipo_movimentacao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela tipo_movimentacao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7731 (class 2620 OID 42356)
-- Name: anexo trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.anexo FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8353 (class 0 OID 0)
-- Dependencies: 7731
-- Name: TRIGGER trg_log_auditoria ON anexo; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.anexo IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela anexo por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7705 (class 2620 OID 42357)
-- Name: categoria trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.categoria FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8354 (class 0 OID 0)
-- Dependencies: 7705
-- Name: TRIGGER trg_log_auditoria ON categoria; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.categoria IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela categoria por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7709 (class 2620 OID 42358)
-- Name: classificacao trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.classificacao FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8355 (class 0 OID 0)
-- Dependencies: 7709
-- Name: TRIGGER trg_log_auditoria ON classificacao; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.classificacao IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela classificacao por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7713 (class 2620 OID 42359)
-- Name: configuracao trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.configuracao FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8356 (class 0 OID 0)
-- Dependencies: 7713
-- Name: TRIGGER trg_log_auditoria ON configuracao; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.configuracao IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela configuracao por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7711 (class 2620 OID 42360)
-- Name: conta trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.conta FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8357 (class 0 OID 0)
-- Dependencies: 7711
-- Name: TRIGGER trg_log_auditoria ON conta; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.conta IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela conta por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7703 (class 2620 OID 42361)
-- Name: grupo trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.grupo FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8358 (class 0 OID 0)
-- Dependencies: 7703
-- Name: TRIGGER trg_log_auditoria ON grupo; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.grupo IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela grupo por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7729 (class 2620 OID 42362)
-- Name: historico_lancamento trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.historico_lancamento FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8359 (class 0 OID 0)
-- Dependencies: 7729
-- Name: TRIGGER trg_log_auditoria ON historico_lancamento; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.historico_lancamento IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela historico_lancamento por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7721 (class 2620 OID 42363)
-- Name: lancamento trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.lancamento FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8360 (class 0 OID 0)
-- Dependencies: 7721
-- Name: TRIGGER trg_log_auditoria ON lancamento; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.lancamento IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela lancamento por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7725 (class 2620 OID 42364)
-- Name: movimentacao_bancaria trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.movimentacao_bancaria FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8361 (class 0 OID 0)
-- Dependencies: 7725
-- Name: TRIGGER trg_log_auditoria ON movimentacao_bancaria; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.movimentacao_bancaria IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela movimentacao_bancaria por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7723 (class 2620 OID 42365)
-- Name: pagamento trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.pagamento FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8362 (class 0 OID 0)
-- Dependencies: 7723
-- Name: TRIGGER trg_log_auditoria ON pagamento; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.pagamento IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela pagamento por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7727 (class 2620 OID 42366)
-- Name: rateio_centro_custo trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.rateio_centro_custo FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8363 (class 0 OID 0)
-- Dependencies: 7727
-- Name: TRIGGER trg_log_auditoria ON rateio_centro_custo; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.rateio_centro_custo IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela rateio_centro_custo por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7717 (class 2620 OID 42367)
-- Name: status_lancamento trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.status_lancamento FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8364 (class 0 OID 0)
-- Dependencies: 7717
-- Name: TRIGGER trg_log_auditoria ON status_lancamento; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.status_lancamento IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela status_lancamento por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7707 (class 2620 OID 42368)
-- Name: subcategoria trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.subcategoria FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8365 (class 0 OID 0)
-- Dependencies: 7707
-- Name: TRIGGER trg_log_auditoria ON subcategoria; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.subcategoria IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela subcategoria por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7715 (class 2620 OID 42369)
-- Name: tipo_lancamento trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.tipo_lancamento FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8366 (class 0 OID 0)
-- Dependencies: 7715
-- Name: TRIGGER trg_log_auditoria ON tipo_lancamento; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.tipo_lancamento IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela tipo_lancamento por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7719 (class 2620 OID 42370)
-- Name: tipo_movimentacao trg_log_auditoria; Type: TRIGGER; Schema: financeiro; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON financeiro.tipo_movimentacao FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8367 (class 0 OID 0)
-- Dependencies: 7719
-- Name: TRIGGER trg_log_auditoria ON tipo_movimentacao; Type: COMMENT; Schema: financeiro; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON financeiro.tipo_movimentacao IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela tipo_movimentacao por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7793 (class 2620 OID 42288)
-- Name: agenda trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.agenda FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8368 (class 0 OID 0)
-- Dependencies: 7793
-- Name: TRIGGER trg_atualiza_updated_at ON agenda; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.agenda IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela agenda é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7807 (class 2620 OID 42303)
-- Name: aplicacao_api trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.aplicacao_api FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8369 (class 0 OID 0)
-- Dependencies: 7807
-- Name: TRIGGER trg_atualiza_updated_at ON aplicacao_api; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.aplicacao_api IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela aplicacao_api é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7765 (class 2620 OID 42263)
-- Name: aporte_capital trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.aporte_capital FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8370 (class 0 OID 0)
-- Dependencies: 7765
-- Name: TRIGGER trg_atualiza_updated_at ON aporte_capital; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.aporte_capital IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela aporte_capital é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7809 (class 2620 OID 42305)
-- Name: aprovacao_processo trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.aprovacao_processo FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8371 (class 0 OID 0)
-- Dependencies: 7809
-- Name: TRIGGER trg_atualiza_updated_at ON aprovacao_processo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.aprovacao_processo IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela aprovacao_processo é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7796 (class 2620 OID 42291)
-- Name: ativo_imobilizado trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.ativo_imobilizado FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8372 (class 0 OID 0)
-- Dependencies: 7796
-- Name: TRIGGER trg_atualiza_updated_at ON ativo_imobilizado; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.ativo_imobilizado IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela ativo_imobilizado é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7740 (class 2620 OID 42239)
-- Name: banco trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.banco FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8373 (class 0 OID 0)
-- Dependencies: 7740
-- Name: TRIGGER trg_atualiza_updated_at ON banco; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.banco IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela banco é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7786 (class 2620 OID 42281)
-- Name: campanha trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.campanha FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8374 (class 0 OID 0)
-- Dependencies: 7786
-- Name: TRIGGER trg_atualiza_updated_at ON campanha; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.campanha IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela campanha é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7789 (class 2620 OID 42284)
-- Name: cargo trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.cargo FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8375 (class 0 OID 0)
-- Dependencies: 7789
-- Name: TRIGGER trg_atualiza_updated_at ON cargo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.cargo IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela cargo é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7795 (class 2620 OID 42290)
-- Name: categoria_ativo trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.categoria_ativo FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8376 (class 0 OID 0)
-- Dependencies: 7795
-- Name: TRIGGER trg_atualiza_updated_at ON categoria_ativo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.categoria_ativo IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela categoria_ativo é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7743 (class 2620 OID 42242)
-- Name: categoria_conta trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.categoria_conta FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8377 (class 0 OID 0)
-- Dependencies: 7743
-- Name: TRIGGER trg_atualiza_updated_at ON categoria_conta; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.categoria_conta IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela categoria_conta é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7745 (class 2620 OID 42244)
-- Name: centro_custo trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.centro_custo FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8378 (class 0 OID 0)
-- Dependencies: 7745
-- Name: TRIGGER trg_atualiza_updated_at ON centro_custo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.centro_custo IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela centro_custo é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7782 (class 2620 OID 42277)
-- Name: checklist_viagem trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.checklist_viagem FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8379 (class 0 OID 0)
-- Dependencies: 7782
-- Name: TRIGGER trg_atualiza_updated_at ON checklist_viagem; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.checklist_viagem IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela checklist_viagem é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7746 (class 2620 OID 42245)
-- Name: classificacao_dre trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.classificacao_dre FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8380 (class 0 OID 0)
-- Dependencies: 7746
-- Name: TRIGGER trg_atualiza_updated_at ON classificacao_dre; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.classificacao_dre IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela classificacao_dre é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7738 (class 2620 OID 42237)
-- Name: cliente trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.cliente FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8381 (class 0 OID 0)
-- Dependencies: 7738
-- Name: TRIGGER trg_atualiza_updated_at ON cliente; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.cliente IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela cliente é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7790 (class 2620 OID 42285)
-- Name: colaborador trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.colaborador FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8382 (class 0 OID 0)
-- Dependencies: 7790
-- Name: TRIGGER trg_atualiza_updated_at ON colaborador; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.colaborador IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela colaborador é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7756 (class 2620 OID 42256)
-- Name: comissao trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.comissao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8383 (class 0 OID 0)
-- Dependencies: 7756
-- Name: TRIGGER trg_atualiza_updated_at ON comissao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.comissao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela comissao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7792 (class 2620 OID 42287)
-- Name: comissao_colaborador trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.comissao_colaborador FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8384 (class 0 OID 0)
-- Dependencies: 7792
-- Name: TRIGGER trg_atualiza_updated_at ON comissao_colaborador; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.comissao_colaborador IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela comissao_colaborador é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7751 (class 2620 OID 42251)
-- Name: conciliacao_bancaria trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.conciliacao_bancaria FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8385 (class 0 OID 0)
-- Dependencies: 7751
-- Name: TRIGGER trg_atualiza_updated_at ON conciliacao_bancaria; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.conciliacao_bancaria IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela conciliacao_bancaria é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7813 (class 2620 OID 42309)
-- Name: conector_integracao trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.conector_integracao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8386 (class 0 OID 0)
-- Dependencies: 7813
-- Name: TRIGGER trg_atualiza_updated_at ON conector_integracao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.conector_integracao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela conector_integracao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7811 (class 2620 OID 42307)
-- Name: conformidade_lgpd trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.conformidade_lgpd FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8387 (class 0 OID 0)
-- Dependencies: 7811
-- Name: TRIGGER trg_atualiza_updated_at ON conformidade_lgpd; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.conformidade_lgpd IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela conformidade_lgpd é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7747 (class 2620 OID 42246)
-- Name: conta_bancaria trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.conta_bancaria FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8388 (class 0 OID 0)
-- Dependencies: 7747
-- Name: TRIGGER trg_atualiza_updated_at ON conta_bancaria; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.conta_bancaria IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela conta_bancaria é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7787 (class 2620 OID 42282)
-- Name: contato_cliente trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.contato_cliente FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8389 (class 0 OID 0)
-- Dependencies: 7787
-- Name: TRIGGER trg_atualiza_updated_at ON contato_cliente; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.contato_cliente IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela contato_cliente é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7783 (class 2620 OID 42278)
-- Name: custo_pacote trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.custo_pacote FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8390 (class 0 OID 0)
-- Dependencies: 7783
-- Name: TRIGGER trg_atualiza_updated_at ON custo_pacote; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.custo_pacote IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela custo_pacote é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7764 (class 2620 OID 42262)
-- Name: das trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.das FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8391 (class 0 OID 0)
-- Dependencies: 7764
-- Name: TRIGGER trg_atualiza_updated_at ON das; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.das IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela das é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7819 (class 2620 OID 42315)
-- Name: data_mart_execucao trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.data_mart_execucao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8392 (class 0 OID 0)
-- Dependencies: 7819
-- Name: TRIGGER trg_atualiza_updated_at ON data_mart_execucao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.data_mart_execucao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela data_mart_execucao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7768 (class 2620 OID 42267)
-- Name: declaracao_fiscal trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.declaracao_fiscal FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8393 (class 0 OID 0)
-- Dependencies: 7768
-- Name: TRIGGER trg_atualiza_updated_at ON declaracao_fiscal; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.declaracao_fiscal IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela declaracao_fiscal é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7797 (class 2620 OID 42292)
-- Name: depreciacao trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.depreciacao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8394 (class 0 OID 0)
-- Dependencies: 7797
-- Name: TRIGGER trg_atualiza_updated_at ON depreciacao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.depreciacao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela depreciacao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7776 (class 2620 OID 42271)
-- Name: destino trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.destino FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8395 (class 0 OID 0)
-- Dependencies: 7776
-- Name: TRIGGER trg_atualiza_updated_at ON destino; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.destino IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela destino é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7766 (class 2620 OID 42264)
-- Name: distribuicao_lucros trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.distribuicao_lucros FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8396 (class 0 OID 0)
-- Dependencies: 7766
-- Name: TRIGGER trg_atualiza_updated_at ON distribuicao_lucros; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.distribuicao_lucros IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela distribuicao_lucros é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7804 (class 2620 OID 42299)
-- Name: documento trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.documento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8397 (class 0 OID 0)
-- Dependencies: 7804
-- Name: TRIGGER trg_atualiza_updated_at ON documento; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.documento IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela documento é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7732 (class 2620 OID 42233)
-- Name: empresa trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.empresa FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8398 (class 0 OID 0)
-- Dependencies: 7732
-- Name: TRIGGER trg_atualiza_updated_at ON empresa; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.empresa IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela empresa é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7821 (class 2620 OID 42302)
-- Name: fato_financeiro trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.fato_financeiro FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8399 (class 0 OID 0)
-- Dependencies: 7821
-- Name: TRIGGER trg_atualiza_updated_at ON fato_financeiro; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.fato_financeiro IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela fato_financeiro é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7820 (class 2620 OID 42316)
-- Name: fato_vendas trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.fato_vendas FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8400 (class 0 OID 0)
-- Dependencies: 7820
-- Name: TRIGGER trg_atualiza_updated_at ON fato_vendas; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.fato_vendas IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela fato_vendas é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7816 (class 2620 OID 42312)
-- Name: fila_integracao trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.fila_integracao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8401 (class 0 OID 0)
-- Dependencies: 7816
-- Name: TRIGGER trg_atualiza_updated_at ON fila_integracao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.fila_integracao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela fila_integracao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7748 (class 2620 OID 42247)
-- Name: forma_pagamento trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.forma_pagamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8402 (class 0 OID 0)
-- Dependencies: 7748
-- Name: TRIGGER trg_atualiza_updated_at ON forma_pagamento; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.forma_pagamento IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela forma_pagamento é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7739 (class 2620 OID 42238)
-- Name: fornecedor trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.fornecedor FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8403 (class 0 OID 0)
-- Dependencies: 7739
-- Name: TRIGGER trg_atualiza_updated_at ON fornecedor; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.fornecedor IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela fornecedor é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7778 (class 2620 OID 42273)
-- Name: fornecedor_turistico trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.fornecedor_turistico FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8404 (class 0 OID 0)
-- Dependencies: 7778
-- Name: TRIGGER trg_atualiza_updated_at ON fornecedor_turistico; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.fornecedor_turistico IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela fornecedor_turistico é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7788 (class 2620 OID 42283)
-- Name: funil_vendas trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.funil_vendas FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8405 (class 0 OID 0)
-- Dependencies: 7788
-- Name: TRIGGER trg_atualiza_updated_at ON funil_vendas; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.funil_vendas IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela funil_vendas é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7773 (class 2620 OID 42268)
-- Name: gateway_pagamento trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.gateway_pagamento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8406 (class 0 OID 0)
-- Dependencies: 7773
-- Name: TRIGGER trg_atualiza_updated_at ON gateway_pagamento; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.gateway_pagamento IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela gateway_pagamento é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7742 (class 2620 OID 42241)
-- Name: grupo_conta trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.grupo_conta FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8407 (class 0 OID 0)
-- Dependencies: 7742
-- Name: TRIGGER trg_atualiza_updated_at ON grupo_conta; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.grupo_conta IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela grupo_conta é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7781 (class 2620 OID 42276)
-- Name: guia_turistico trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.guia_turistico FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8408 (class 0 OID 0)
-- Dependencies: 7781
-- Name: TRIGGER trg_atualiza_updated_at ON guia_turistico; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.guia_turistico IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela guia_turistico é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7779 (class 2620 OID 42274)
-- Name: hospedagem trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.hospedagem FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8409 (class 0 OID 0)
-- Dependencies: 7779
-- Name: TRIGGER trg_atualiza_updated_at ON hospedagem; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.hospedagem IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela hospedagem é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7761 (class 2620 OID 42260)
-- Name: imposto trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.imposto FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8410 (class 0 OID 0)
-- Dependencies: 7761
-- Name: TRIGGER trg_atualiza_updated_at ON imposto; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.imposto IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela imposto é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7772 (class 2620 OID 42266)
-- Name: integracao_woocommerce trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.integracao_woocommerce FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8411 (class 0 OID 0)
-- Dependencies: 7772
-- Name: TRIGGER trg_atualiza_updated_at ON integracao_woocommerce; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.integracao_woocommerce IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela integracao_woocommerce é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7758 (class 2620 OID 42258)
-- Name: item_venda trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.item_venda FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8412 (class 0 OID 0)
-- Dependencies: 7758
-- Name: TRIGGER trg_atualiza_updated_at ON item_venda; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.item_venda IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela item_venda é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7822 (class 2620 OID 42317)
-- Name: kpi_turismo trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.kpi_turismo FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8413 (class 0 OID 0)
-- Dependencies: 7822
-- Name: TRIGGER trg_atualiza_updated_at ON kpi_turismo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.kpi_turismo IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela kpi_turismo é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7749 (class 2620 OID 42248)
-- Name: lancamento_financeiro trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.lancamento_financeiro FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8414 (class 0 OID 0)
-- Dependencies: 7749
-- Name: TRIGGER trg_atualiza_updated_at ON lancamento_financeiro; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.lancamento_financeiro IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela lancamento_financeiro é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7750 (class 2620 OID 42250)
-- Name: lancamento_parcela trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.lancamento_parcela FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8415 (class 0 OID 0)
-- Dependencies: 7750
-- Name: TRIGGER trg_atualiza_updated_at ON lancamento_parcela; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.lancamento_parcela IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela lancamento_parcela é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7785 (class 2620 OID 42280)
-- Name: lead trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.lead FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8416 (class 0 OID 0)
-- Dependencies: 7785
-- Name: TRIGGER trg_atualiza_updated_at ON lead; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.lead IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela lead é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7799 (class 2620 OID 42294)
-- Name: localizacao_ativo trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.localizacao_ativo FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8417 (class 0 OID 0)
-- Dependencies: 7799
-- Name: TRIGGER trg_atualiza_updated_at ON localizacao_ativo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.localizacao_ativo IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela localizacao_ativo é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7817 (class 2620 OID 42313)
-- Name: log_integracao_detalhado trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.log_integracao_detalhado FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8418 (class 0 OID 0)
-- Dependencies: 7817
-- Name: TRIGGER trg_atualiza_updated_at ON log_integracao_detalhado; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.log_integracao_detalhado IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela log_integracao_detalhado é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7798 (class 2620 OID 42293)
-- Name: manutencao_ativo trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.manutencao_ativo FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8419 (class 0 OID 0)
-- Dependencies: 7798
-- Name: TRIGGER trg_atualiza_updated_at ON manutencao_ativo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.manutencao_ativo IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela manutencao_ativo é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7814 (class 2620 OID 42310)
-- Name: mapeamento_campo_integracao trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.mapeamento_campo_integracao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8420 (class 0 OID 0)
-- Dependencies: 7814
-- Name: TRIGGER trg_atualiza_updated_at ON mapeamento_campo_integracao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.mapeamento_campo_integracao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela mapeamento_campo_integracao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7808 (class 2620 OID 42304)
-- Name: modelo_ml trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.modelo_ml FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8421 (class 0 OID 0)
-- Dependencies: 7808
-- Name: TRIGGER trg_atualiza_updated_at ON modelo_ml; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.modelo_ml IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela modelo_ml é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7759 (class 2620 OID 42259)
-- Name: nota_fiscal trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.nota_fiscal FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8422 (class 0 OID 0)
-- Dependencies: 7759
-- Name: TRIGGER trg_atualiza_updated_at ON nota_fiscal; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.nota_fiscal IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela nota_fiscal é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7775 (class 2620 OID 42270)
-- Name: openfinance_conexao trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.openfinance_conexao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8423 (class 0 OID 0)
-- Dependencies: 7775
-- Name: TRIGGER trg_atualiza_updated_at ON openfinance_conexao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.openfinance_conexao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela openfinance_conexao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7784 (class 2620 OID 42279)
-- Name: origem_lead trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.origem_lead FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8424 (class 0 OID 0)
-- Dependencies: 7784
-- Name: TRIGGER trg_atualiza_updated_at ON origem_lead; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.origem_lead IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela origem_lead é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7753 (class 2620 OID 42253)
-- Name: pacote_viagem trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.pacote_viagem FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8425 (class 0 OID 0)
-- Dependencies: 7753
-- Name: TRIGGER trg_atualiza_updated_at ON pacote_viagem; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.pacote_viagem IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela pacote_viagem é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7774 (class 2620 OID 42269)
-- Name: pagamento_transacao trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.pagamento_transacao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8426 (class 0 OID 0)
-- Dependencies: 7774
-- Name: TRIGGER trg_atualiza_updated_at ON pagamento_transacao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.pagamento_transacao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela pagamento_transacao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7806 (class 2620 OID 42301)
-- Name: parametro_sistema trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.parametro_sistema FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8427 (class 0 OID 0)
-- Dependencies: 7806
-- Name: TRIGGER trg_atualiza_updated_at ON parametro_sistema; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.parametro_sistema IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela parametro_sistema é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7791 (class 2620 OID 42286)
-- Name: parceiro_comercial trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.parceiro_comercial FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8428 (class 0 OID 0)
-- Dependencies: 7791
-- Name: TRIGGER trg_atualiza_updated_at ON parceiro_comercial; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.parceiro_comercial IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela parceiro_comercial é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7755 (class 2620 OID 42255)
-- Name: passageiro trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.passageiro FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8429 (class 0 OID 0)
-- Dependencies: 7755
-- Name: TRIGGER trg_atualiza_updated_at ON passageiro; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.passageiro IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela passageiro é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7802 (class 2620 OID 42298)
-- Name: pedido_compra trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.pedido_compra FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8430 (class 0 OID 0)
-- Dependencies: 7802
-- Name: TRIGGER trg_atualiza_updated_at ON pedido_compra; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.pedido_compra IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela pedido_compra é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7770 (class 2620 OID 42236)
-- Name: perfil_acesso trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.perfil_acesso FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8431 (class 0 OID 0)
-- Dependencies: 7770
-- Name: TRIGGER trg_atualiza_updated_at ON perfil_acesso; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.perfil_acesso IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela perfil_acesso é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7771 (class 2620 OID 42249)
-- Name: permissao trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.permissao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8432 (class 0 OID 0)
-- Dependencies: 7771
-- Name: TRIGGER trg_atualiza_updated_at ON permissao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.permissao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela permissao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7736 (class 2620 OID 42235)
-- Name: pessoa trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.pessoa FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8433 (class 0 OID 0)
-- Dependencies: 7736
-- Name: TRIGGER trg_atualiza_updated_at ON pessoa; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.pessoa IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela pessoa é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7741 (class 2620 OID 42240)
-- Name: plano_contas trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.plano_contas FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8434 (class 0 OID 0)
-- Dependencies: 7741
-- Name: TRIGGER trg_atualiza_updated_at ON plano_contas; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.plano_contas IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela plano_contas é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7810 (class 2620 OID 42306)
-- Name: politica_acesso trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.politica_acesso FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8435 (class 0 OID 0)
-- Dependencies: 7810
-- Name: TRIGGER trg_atualiza_updated_at ON politica_acesso; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.politica_acesso IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela politica_acesso é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7767 (class 2620 OID 42265)
-- Name: pro_labore trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.pro_labore FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8436 (class 0 OID 0)
-- Dependencies: 7767
-- Name: TRIGGER trg_atualiza_updated_at ON pro_labore; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.pro_labore IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela pro_labore é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7800 (class 2620 OID 42296)
-- Name: produto_estoque trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.produto_estoque FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8437 (class 0 OID 0)
-- Dependencies: 7800
-- Name: TRIGGER trg_atualiza_updated_at ON produto_estoque; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.produto_estoque IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela produto_estoque é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7752 (class 2620 OID 42252)
-- Name: produto_turistico trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.produto_turistico FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8438 (class 0 OID 0)
-- Dependencies: 7752
-- Name: TRIGGER trg_atualiza_updated_at ON produto_turistico; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.produto_turistico IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela produto_turistico é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7805 (class 2620 OID 42300)
-- Name: projeto trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.projeto FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8439 (class 0 OID 0)
-- Dependencies: 7805
-- Name: TRIGGER trg_atualiza_updated_at ON projeto; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.projeto IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela projeto é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7823 (class 2620 OID 42318)
-- Name: rentabilidade_produto trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.rentabilidade_produto FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8440 (class 0 OID 0)
-- Dependencies: 7823
-- Name: TRIGGER trg_atualiza_updated_at ON rentabilidade_produto; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.rentabilidade_produto IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela rentabilidade_produto é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7801 (class 2620 OID 42297)
-- Name: requisicao_compra trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.requisicao_compra FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8441 (class 0 OID 0)
-- Dependencies: 7801
-- Name: TRIGGER trg_atualiza_updated_at ON requisicao_compra; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.requisicao_compra IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela requisicao_compra é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7754 (class 2620 OID 42254)
-- Name: reserva trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.reserva FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8442 (class 0 OID 0)
-- Dependencies: 7754
-- Name: TRIGGER trg_atualiza_updated_at ON reserva; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.reserva IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela reserva é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7777 (class 2620 OID 42272)
-- Name: roteiro_viagem trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.roteiro_viagem FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8443 (class 0 OID 0)
-- Dependencies: 7777
-- Name: TRIGGER trg_atualiza_updated_at ON roteiro_viagem; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.roteiro_viagem IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela roteiro_viagem é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7763 (class 2620 OID 42261)
-- Name: simples_nacional trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.simples_nacional FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8444 (class 0 OID 0)
-- Dependencies: 7763
-- Name: TRIGGER trg_atualiza_updated_at ON simples_nacional; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.simples_nacional IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela simples_nacional é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7815 (class 2620 OID 42311)
-- Name: sincronizacao_integracao trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.sincronizacao_integracao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8445 (class 0 OID 0)
-- Dependencies: 7815
-- Name: TRIGGER trg_atualiza_updated_at ON sincronizacao_integracao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.sincronizacao_integracao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela sincronizacao_integracao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7812 (class 2620 OID 42308)
-- Name: sistema_externo trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.sistema_externo FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8446 (class 0 OID 0)
-- Dependencies: 7812
-- Name: TRIGGER trg_atualiza_updated_at ON sistema_externo; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.sistema_externo IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela sistema_externo é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7818 (class 2620 OID 42314)
-- Name: status_integracao trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.status_integracao FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8447 (class 0 OID 0)
-- Dependencies: 7818
-- Name: TRIGGER trg_atualiza_updated_at ON status_integracao; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.status_integracao IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela status_integracao é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7744 (class 2620 OID 42243)
-- Name: subcategoria_conta trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.subcategoria_conta FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8448 (class 0 OID 0)
-- Dependencies: 7744
-- Name: TRIGGER trg_atualiza_updated_at ON subcategoria_conta; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.subcategoria_conta IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela subcategoria_conta é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7794 (class 2620 OID 42289)
-- Name: tarefa trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.tarefa FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8449 (class 0 OID 0)
-- Dependencies: 7794
-- Name: TRIGGER trg_atualiza_updated_at ON tarefa; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.tarefa IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela tarefa é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7803 (class 2620 OID 42295)
-- Name: tipo_documento trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.tipo_documento FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8450 (class 0 OID 0)
-- Dependencies: 7803
-- Name: TRIGGER trg_atualiza_updated_at ON tipo_documento; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.tipo_documento IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela tipo_documento é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7780 (class 2620 OID 42275)
-- Name: transporte trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.transporte FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8451 (class 0 OID 0)
-- Dependencies: 7780
-- Name: TRIGGER trg_atualiza_updated_at ON transporte; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.transporte IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela transporte é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7734 (class 2620 OID 42234)
-- Name: usuario trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.usuario FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8452 (class 0 OID 0)
-- Dependencies: 7734
-- Name: TRIGGER trg_atualiza_updated_at ON usuario; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.usuario IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela usuario é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7757 (class 2620 OID 42257)
-- Name: venda trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.venda FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8453 (class 0 OID 0)
-- Dependencies: 7757
-- Name: TRIGGER trg_atualiza_updated_at ON venda; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.venda IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela venda é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7824 (class 2620 OID 42319)
-- Name: workflow trg_atualiza_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.workflow FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at();


--
-- TOC entry 8454 (class 0 OID 0)
-- Dependencies: 7824
-- Name: TRIGGER trg_atualiza_updated_at ON workflow; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_atualiza_updated_at ON public.workflow IS 'WMA Travel ERP | Controle temporal: atualiza automaticamente o campo updated_at quando o registro da tabela workflow é modificado. Função responsável: fn_atualiza_updated_at.';


--
-- TOC entry 7769 (class 2620 OID 42355)
-- Name: declaracao_fiscal trg_log_auditoria; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON public.declaracao_fiscal FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8455 (class 0 OID 0)
-- Dependencies: 7769
-- Name: TRIGGER trg_log_auditoria ON declaracao_fiscal; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON public.declaracao_fiscal IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela declaracao_fiscal por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7733 (class 2620 OID 42351)
-- Name: empresa trg_log_auditoria; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON public.empresa FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8456 (class 0 OID 0)
-- Dependencies: 7733
-- Name: TRIGGER trg_log_auditoria ON empresa; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON public.empresa IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela empresa por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7762 (class 2620 OID 42354)
-- Name: imposto trg_log_auditoria; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON public.imposto FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8457 (class 0 OID 0)
-- Dependencies: 7762
-- Name: TRIGGER trg_log_auditoria ON imposto; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON public.imposto IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela imposto por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7760 (class 2620 OID 42353)
-- Name: nota_fiscal trg_log_auditoria; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON public.nota_fiscal FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8458 (class 0 OID 0)
-- Dependencies: 7760
-- Name: TRIGGER trg_log_auditoria ON nota_fiscal; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON public.nota_fiscal IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela nota_fiscal por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7737 (class 2620 OID 42350)
-- Name: pessoa trg_log_auditoria; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON public.pessoa FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8459 (class 0 OID 0)
-- Dependencies: 7737
-- Name: TRIGGER trg_log_auditoria ON pessoa; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON public.pessoa IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela pessoa por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7735 (class 2620 OID 42352)
-- Name: usuario trg_log_auditoria; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_log_auditoria AFTER INSERT OR DELETE OR UPDATE ON public.usuario FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria();


--
-- TOC entry 8460 (class 0 OID 0)
-- Dependencies: 7735
-- Name: TRIGGER trg_log_auditoria ON usuario; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TRIGGER trg_log_auditoria ON public.usuario IS 'WMA Travel ERP | Auditoria: registra alterações INSERT, UPDATE e DELETE da tabela usuario por meio da função de auditoria fn_log_auditoria.';


--
-- TOC entry 7695 (class 2606 OID 41511)
-- Name: item fk_item_categoria; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.item
    ADD CONSTRAINT fk_item_categoria FOREIGN KEY (id_categoria) REFERENCES auditoria.categoria(id_categoria) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 7700 (class 2606 OID 41609)
-- Name: log fk_log_execucao; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.log
    ADD CONSTRAINT fk_log_execucao FOREIGN KEY (id_execucao) REFERENCES auditoria.execucao(id_execucao) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 7699 (class 2606 OID 41586)
-- Name: recomendacao fk_recomendacao_execucao; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.recomendacao
    ADD CONSTRAINT fk_recomendacao_execucao FOREIGN KEY (id_execucao) REFERENCES auditoria.execucao(id_execucao) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 7701 (class 2606 OID 41847)
-- Name: regra fk_regra_executor; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.regra
    ADD CONSTRAINT fk_regra_executor FOREIGN KEY (id_executor) REFERENCES auditoria.executor(id_executor);


--
-- TOC entry 7696 (class 2606 OID 41536)
-- Name: resultado fk_resultado_execucao; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.resultado
    ADD CONSTRAINT fk_resultado_execucao FOREIGN KEY (id_execucao) REFERENCES auditoria.execucao(id_execucao) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 7697 (class 2606 OID 41541)
-- Name: resultado fk_resultado_item; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.resultado
    ADD CONSTRAINT fk_resultado_item FOREIGN KEY (id_item) REFERENCES auditoria.item(id_item) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 7698 (class 2606 OID 41562)
-- Name: score fk_score_execucao; Type: FK CONSTRAINT; Schema: auditoria; Owner: postgres
--

ALTER TABLE ONLY auditoria.score
    ADD CONSTRAINT fk_score_execucao FOREIGN KEY (id_execucao) REFERENCES auditoria.execucao(id_execucao) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 7585 (class 2606 OID 41876)
-- Name: anexo fk_anexo_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.anexo
    ADD CONSTRAINT fk_anexo_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7586 (class 2606 OID 41886)
-- Name: anexo fk_anexo_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.anexo
    ADD CONSTRAINT fk_anexo_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7587 (class 2606 OID 33385)
-- Name: anexo fk_anexo_lancamento; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.anexo
    ADD CONSTRAINT fk_anexo_lancamento FOREIGN KEY (id_lancamento) REFERENCES financeiro.lancamento(id_lancamento);


--
-- TOC entry 7588 (class 2606 OID 41881)
-- Name: anexo fk_anexo_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.anexo
    ADD CONSTRAINT fk_anexo_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7519 (class 2606 OID 41894)
-- Name: categoria fk_categoria_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.categoria
    ADD CONSTRAINT fk_categoria_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7520 (class 2606 OID 41904)
-- Name: categoria fk_categoria_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.categoria
    ADD CONSTRAINT fk_categoria_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7521 (class 2606 OID 24801)
-- Name: categoria fk_categoria_grupo; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.categoria
    ADD CONSTRAINT fk_categoria_grupo FOREIGN KEY (id_grupo) REFERENCES financeiro.grupo(id_grupo) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 7522 (class 2606 OID 41899)
-- Name: categoria fk_categoria_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.categoria
    ADD CONSTRAINT fk_categoria_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7527 (class 2606 OID 41911)
-- Name: classificacao fk_classificacao_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.classificacao
    ADD CONSTRAINT fk_classificacao_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7528 (class 2606 OID 41921)
-- Name: classificacao fk_classificacao_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.classificacao
    ADD CONSTRAINT fk_classificacao_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7529 (class 2606 OID 24811)
-- Name: classificacao fk_classificacao_subcategoria; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.classificacao
    ADD CONSTRAINT fk_classificacao_subcategoria FOREIGN KEY (id_subcategoria) REFERENCES financeiro.subcategoria(id_subcategoria) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 7530 (class 2606 OID 41916)
-- Name: classificacao fk_classificacao_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.classificacao
    ADD CONSTRAINT fk_classificacao_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7536 (class 2606 OID 33432)
-- Name: cliente fk_cliente_pessoa; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.cliente
    ADD CONSTRAINT fk_cliente_pessoa FOREIGN KEY (id_pessoa) REFERENCES public.pessoa(id_pessoa);


--
-- TOC entry 7537 (class 2606 OID 24826)
-- Name: configuracao fk_config_empresa; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.configuracao
    ADD CONSTRAINT fk_config_empresa FOREIGN KEY (empresa_padrao) REFERENCES financeiro.empresa(id_empresa) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7538 (class 2606 OID 41929)
-- Name: configuracao fk_configuracao_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.configuracao
    ADD CONSTRAINT fk_configuracao_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7539 (class 2606 OID 41939)
-- Name: configuracao fk_configuracao_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.configuracao
    ADD CONSTRAINT fk_configuracao_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7540 (class 2606 OID 41934)
-- Name: configuracao fk_configuracao_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.configuracao
    ADD CONSTRAINT fk_configuracao_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7535 (class 2606 OID 24821)
-- Name: conta_bancaria fk_conta_banco; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.conta_bancaria
    ADD CONSTRAINT fk_conta_banco FOREIGN KEY (id_banco) REFERENCES financeiro.banco(id_banco) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 7531 (class 2606 OID 24816)
-- Name: conta fk_conta_classificacao; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.conta
    ADD CONSTRAINT fk_conta_classificacao FOREIGN KEY (id_classificacao) REFERENCES financeiro.classificacao(id_classificacao) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 7532 (class 2606 OID 41947)
-- Name: conta fk_conta_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.conta
    ADD CONSTRAINT fk_conta_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7533 (class 2606 OID 41957)
-- Name: conta fk_conta_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.conta
    ADD CONSTRAINT fk_conta_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7534 (class 2606 OID 41952)
-- Name: conta fk_conta_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.conta
    ADD CONSTRAINT fk_conta_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7515 (class 2606 OID 33412)
-- Name: empresa fk_empresa_fin_localidade; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.empresa
    ADD CONSTRAINT fk_empresa_fin_localidade FOREIGN KEY (id_localidade) REFERENCES public.localidade(id_localidade);


--
-- TOC entry 7516 (class 2606 OID 41965)
-- Name: grupo fk_grupo_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.grupo
    ADD CONSTRAINT fk_grupo_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7517 (class 2606 OID 41975)
-- Name: grupo fk_grupo_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.grupo
    ADD CONSTRAINT fk_grupo_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7518 (class 2606 OID 41970)
-- Name: grupo fk_grupo_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.grupo
    ADD CONSTRAINT fk_grupo_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7580 (class 2606 OID 33375)
-- Name: historico_lancamento fk_historico_lancamento; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.historico_lancamento
    ADD CONSTRAINT fk_historico_lancamento FOREIGN KEY (id_lancamento) REFERENCES financeiro.lancamento(id_lancamento);


--
-- TOC entry 7581 (class 2606 OID 41983)
-- Name: historico_lancamento fk_historico_lancamento_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.historico_lancamento
    ADD CONSTRAINT fk_historico_lancamento_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7582 (class 2606 OID 41993)
-- Name: historico_lancamento fk_historico_lancamento_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.historico_lancamento
    ADD CONSTRAINT fk_historico_lancamento_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7583 (class 2606 OID 41988)
-- Name: historico_lancamento fk_historico_lancamento_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.historico_lancamento
    ADD CONSTRAINT fk_historico_lancamento_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7584 (class 2606 OID 33380)
-- Name: historico_lancamento fk_historico_usuario; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.historico_lancamento
    ADD CONSTRAINT fk_historico_usuario FOREIGN KEY (id_usuario) REFERENCES financeiro.usuario(id_usuario);


--
-- TOC entry 7550 (class 2606 OID 33305)
-- Name: lancamento fk_lancamento_cliente; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT fk_lancamento_cliente FOREIGN KEY (id_cliente) REFERENCES financeiro.cliente(id_cliente);


--
-- TOC entry 7551 (class 2606 OID 33300)
-- Name: lancamento fk_lancamento_conta; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT fk_lancamento_conta FOREIGN KEY (id_conta) REFERENCES financeiro.conta(id_conta);


--
-- TOC entry 7552 (class 2606 OID 33315)
-- Name: lancamento fk_lancamento_conta_bancaria; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT fk_lancamento_conta_bancaria FOREIGN KEY (id_conta_bancaria) REFERENCES financeiro.conta_bancaria(id_conta_bancaria);


--
-- TOC entry 7553 (class 2606 OID 42001)
-- Name: lancamento fk_lancamento_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT fk_lancamento_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7554 (class 2606 OID 42011)
-- Name: lancamento fk_lancamento_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT fk_lancamento_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7555 (class 2606 OID 33285)
-- Name: lancamento fk_lancamento_empresa; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT fk_lancamento_empresa FOREIGN KEY (id_empresa) REFERENCES financeiro.empresa(id_empresa);


--
-- TOC entry 7556 (class 2606 OID 33320)
-- Name: lancamento fk_lancamento_forma_pagamento; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT fk_lancamento_forma_pagamento FOREIGN KEY (id_forma_pagamento) REFERENCES financeiro.forma_pagamento(id_forma_pagamento);


--
-- TOC entry 7557 (class 2606 OID 33310)
-- Name: lancamento fk_lancamento_fornecedor; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT fk_lancamento_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES financeiro.fornecedor(id_fornecedor);


--
-- TOC entry 7558 (class 2606 OID 33295)
-- Name: lancamento fk_lancamento_status; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT fk_lancamento_status FOREIGN KEY (id_status) REFERENCES financeiro.status_lancamento(id_status);


--
-- TOC entry 7559 (class 2606 OID 33290)
-- Name: lancamento fk_lancamento_tipo; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT fk_lancamento_tipo FOREIGN KEY (id_tipo_lancamento) REFERENCES financeiro.tipo_lancamento(id_tipo_lancamento);


--
-- TOC entry 7560 (class 2606 OID 33325)
-- Name: lancamento fk_lancamento_tipo_documento; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT fk_lancamento_tipo_documento FOREIGN KEY (id_tipo_documento) REFERENCES financeiro.tipo_documento(id_tipo_documento);


--
-- TOC entry 7561 (class 2606 OID 42006)
-- Name: lancamento fk_lancamento_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento
    ADD CONSTRAINT fk_lancamento_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7569 (class 2606 OID 42019)
-- Name: movimentacao_bancaria fk_movimentacao_bancaria_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.movimentacao_bancaria
    ADD CONSTRAINT fk_movimentacao_bancaria_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7570 (class 2606 OID 42029)
-- Name: movimentacao_bancaria fk_movimentacao_bancaria_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.movimentacao_bancaria
    ADD CONSTRAINT fk_movimentacao_bancaria_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7571 (class 2606 OID 42024)
-- Name: movimentacao_bancaria fk_movimentacao_bancaria_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.movimentacao_bancaria
    ADD CONSTRAINT fk_movimentacao_bancaria_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7572 (class 2606 OID 33350)
-- Name: movimentacao_bancaria fk_movimentacao_conta_bancaria; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.movimentacao_bancaria
    ADD CONSTRAINT fk_movimentacao_conta_bancaria FOREIGN KEY (id_conta_bancaria) REFERENCES financeiro.conta_bancaria(id_conta_bancaria);


--
-- TOC entry 7573 (class 2606 OID 33355)
-- Name: movimentacao_bancaria fk_movimentacao_pagamento; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.movimentacao_bancaria
    ADD CONSTRAINT fk_movimentacao_pagamento FOREIGN KEY (id_pagamento) REFERENCES financeiro.pagamento(id_pagamento);


--
-- TOC entry 7574 (class 2606 OID 33360)
-- Name: movimentacao_bancaria fk_movimentacao_tipo; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.movimentacao_bancaria
    ADD CONSTRAINT fk_movimentacao_tipo FOREIGN KEY (id_tipo_movimentacao) REFERENCES financeiro.tipo_movimentacao(id_tipo_movimentacao);


--
-- TOC entry 7563 (class 2606 OID 33340)
-- Name: pagamento fk_pagamento_conta_bancaria; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.pagamento
    ADD CONSTRAINT fk_pagamento_conta_bancaria FOREIGN KEY (id_conta_bancaria) REFERENCES financeiro.conta_bancaria(id_conta_bancaria);


--
-- TOC entry 7564 (class 2606 OID 42037)
-- Name: pagamento fk_pagamento_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.pagamento
    ADD CONSTRAINT fk_pagamento_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7565 (class 2606 OID 42047)
-- Name: pagamento fk_pagamento_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.pagamento
    ADD CONSTRAINT fk_pagamento_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7566 (class 2606 OID 33345)
-- Name: pagamento fk_pagamento_forma_pagamento; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.pagamento
    ADD CONSTRAINT fk_pagamento_forma_pagamento FOREIGN KEY (id_forma_pagamento) REFERENCES financeiro.forma_pagamento(id_forma_pagamento);


--
-- TOC entry 7567 (class 2606 OID 33335)
-- Name: pagamento fk_pagamento_parcela; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.pagamento
    ADD CONSTRAINT fk_pagamento_parcela FOREIGN KEY (id_parcela) REFERENCES financeiro.lancamento_parcela(id_parcela);


--
-- TOC entry 7568 (class 2606 OID 42042)
-- Name: pagamento fk_pagamento_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.pagamento
    ADD CONSTRAINT fk_pagamento_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7562 (class 2606 OID 33330)
-- Name: lancamento_parcela fk_parcela_lancamento; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.lancamento_parcela
    ADD CONSTRAINT fk_parcela_lancamento FOREIGN KEY (id_lancamento) REFERENCES financeiro.lancamento(id_lancamento);


--
-- TOC entry 7575 (class 2606 OID 33370)
-- Name: rateio_centro_custo fk_rateio_centro_custo; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.rateio_centro_custo
    ADD CONSTRAINT fk_rateio_centro_custo FOREIGN KEY (id_centro_custo) REFERENCES financeiro.centro_custo(id_centro_custo);


--
-- TOC entry 7576 (class 2606 OID 42055)
-- Name: rateio_centro_custo fk_rateio_centro_custo_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.rateio_centro_custo
    ADD CONSTRAINT fk_rateio_centro_custo_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7577 (class 2606 OID 42065)
-- Name: rateio_centro_custo fk_rateio_centro_custo_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.rateio_centro_custo
    ADD CONSTRAINT fk_rateio_centro_custo_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7578 (class 2606 OID 42060)
-- Name: rateio_centro_custo fk_rateio_centro_custo_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.rateio_centro_custo
    ADD CONSTRAINT fk_rateio_centro_custo_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7579 (class 2606 OID 33365)
-- Name: rateio_centro_custo fk_rateio_lancamento; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.rateio_centro_custo
    ADD CONSTRAINT fk_rateio_lancamento FOREIGN KEY (id_lancamento) REFERENCES financeiro.lancamento(id_lancamento);


--
-- TOC entry 7544 (class 2606 OID 42073)
-- Name: status_lancamento fk_status_lancamento_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.status_lancamento
    ADD CONSTRAINT fk_status_lancamento_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7545 (class 2606 OID 42083)
-- Name: status_lancamento fk_status_lancamento_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.status_lancamento
    ADD CONSTRAINT fk_status_lancamento_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7546 (class 2606 OID 42078)
-- Name: status_lancamento fk_status_lancamento_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.status_lancamento
    ADD CONSTRAINT fk_status_lancamento_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7523 (class 2606 OID 24806)
-- Name: subcategoria fk_subcategoria_categoria; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.subcategoria
    ADD CONSTRAINT fk_subcategoria_categoria FOREIGN KEY (id_categoria) REFERENCES financeiro.categoria(id_categoria) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 7524 (class 2606 OID 42091)
-- Name: subcategoria fk_subcategoria_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.subcategoria
    ADD CONSTRAINT fk_subcategoria_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7525 (class 2606 OID 42101)
-- Name: subcategoria fk_subcategoria_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.subcategoria
    ADD CONSTRAINT fk_subcategoria_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7526 (class 2606 OID 42096)
-- Name: subcategoria fk_subcategoria_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.subcategoria
    ADD CONSTRAINT fk_subcategoria_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7541 (class 2606 OID 42109)
-- Name: tipo_lancamento fk_tipo_lancamento_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_lancamento
    ADD CONSTRAINT fk_tipo_lancamento_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7542 (class 2606 OID 42119)
-- Name: tipo_lancamento fk_tipo_lancamento_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_lancamento
    ADD CONSTRAINT fk_tipo_lancamento_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7543 (class 2606 OID 42114)
-- Name: tipo_lancamento fk_tipo_lancamento_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_lancamento
    ADD CONSTRAINT fk_tipo_lancamento_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7547 (class 2606 OID 42127)
-- Name: tipo_movimentacao fk_tipo_movimentacao_created_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_movimentacao
    ADD CONSTRAINT fk_tipo_movimentacao_created_by FOREIGN KEY (created_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7548 (class 2606 OID 42137)
-- Name: tipo_movimentacao fk_tipo_movimentacao_deleted_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_movimentacao
    ADD CONSTRAINT fk_tipo_movimentacao_deleted_by FOREIGN KEY (deleted_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7549 (class 2606 OID 42132)
-- Name: tipo_movimentacao fk_tipo_movimentacao_updated_by; Type: FK CONSTRAINT; Schema: financeiro; Owner: postgres
--

ALTER TABLE ONLY financeiro.tipo_movimentacao
    ADD CONSTRAINT fk_tipo_movimentacao_updated_by FOREIGN KEY (updated_by) REFERENCES financeiro.usuario(id_usuario) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 7652 (class 2606 OID 26395)
-- Name: agenda fk_agenda_colaborador; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.agenda
    ADD CONSTRAINT fk_agenda_colaborador FOREIGN KEY (id_colaborador) REFERENCES public.colaborador(id_colaborador);


--
-- TOC entry 7681 (class 2606 OID 26976)
-- Name: anexo_projeto fk_anexo_projeto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.anexo_projeto
    ADD CONSTRAINT fk_anexo_projeto FOREIGN KEY (id_projeto) REFERENCES public.projeto(id_projeto);


--
-- TOC entry 7623 (class 2606 OID 25707)
-- Name: aporte_capital fk_aporte_empresa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.aporte_capital
    ADD CONSTRAINT fk_aporte_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa);


--
-- TOC entry 7670 (class 2606 OID 26781)
-- Name: arquivo_digital fk_arquivo_documento; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.arquivo_digital
    ADD CONSTRAINT fk_arquivo_documento FOREIGN KEY (id_documento) REFERENCES public.documento(id_documento);


--
-- TOC entry 7672 (class 2606 OID 26812)
-- Name: assinatura_digital fk_assinatura_documento; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.assinatura_digital
    ADD CONSTRAINT fk_assinatura_documento FOREIGN KEY (id_documento) REFERENCES public.documento(id_documento);


--
-- TOC entry 7655 (class 2606 OID 26477)
-- Name: ativo_imobilizado fk_ativo_categoria; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ativo_imobilizado
    ADD CONSTRAINT fk_ativo_categoria FOREIGN KEY (id_categoria_ativo) REFERENCES public.categoria_ativo(id_categoria_ativo);


--
-- TOC entry 7647 (class 2606 OID 26298)
-- Name: avaliacao_pos_viagem fk_avaliacao_reserva; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.avaliacao_pos_viagem
    ADD CONSTRAINT fk_avaliacao_reserva FOREIGN KEY (id_reserva) REFERENCES public.reserva(id_reserva);


--
-- TOC entry 7594 (class 2606 OID 25232)
-- Name: categoria_conta fk_categoria_grupo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.categoria_conta
    ADD CONSTRAINT fk_categoria_grupo FOREIGN KEY (id_grupo) REFERENCES public.grupo_conta(id_grupo);


--
-- TOC entry 7685 (class 2606 OID 27141)
-- Name: chave_api fk_chave_aplicacao; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.chave_api
    ADD CONSTRAINT fk_chave_aplicacao FOREIGN KEY (id_aplicacao) REFERENCES public.aplicacao_api(id_aplicacao);


--
-- TOC entry 7641 (class 2606 OID 26155)
-- Name: checklist_viagem fk_checklist_pacote; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.checklist_viagem
    ADD CONSTRAINT fk_checklist_pacote FOREIGN KEY (id_pacote) REFERENCES public.pacote_viagem(id_pacote);


--
-- TOC entry 7591 (class 2606 OID 25138)
-- Name: cliente fk_cliente_pessoa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.cliente
    ADD CONSTRAINT fk_cliente_pessoa FOREIGN KEY (id_pessoa) REFERENCES public.pessoa(id_pessoa);


--
-- TOC entry 7648 (class 2606 OID 26341)
-- Name: colaborador fk_colaborador_cargo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.colaborador
    ADD CONSTRAINT fk_colaborador_cargo FOREIGN KEY (id_cargo) REFERENCES public.cargo(id_cargo);


--
-- TOC entry 7649 (class 2606 OID 26336)
-- Name: colaborador fk_colaborador_pessoa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.colaborador
    ADD CONSTRAINT fk_colaborador_pessoa FOREIGN KEY (id_pessoa) REFERENCES public.pessoa(id_pessoa);


--
-- TOC entry 7650 (class 2606 OID 26372)
-- Name: comissao_colaborador fk_comissao_colaborador; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comissao_colaborador
    ADD CONSTRAINT fk_comissao_colaborador FOREIGN KEY (id_colaborador) REFERENCES public.colaborador(id_colaborador);


--
-- TOC entry 7614 (class 2606 OID 25534)
-- Name: comissao fk_comissao_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comissao
    ADD CONSTRAINT fk_comissao_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES public.fornecedor(id_fornecedor);


--
-- TOC entry 7615 (class 2606 OID 25529)
-- Name: comissao fk_comissao_reserva; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comissao
    ADD CONSTRAINT fk_comissao_reserva FOREIGN KEY (id_reserva) REFERENCES public.reserva(id_reserva);


--
-- TOC entry 7651 (class 2606 OID 26377)
-- Name: comissao_colaborador fk_comissao_venda; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.comissao_colaborador
    ADD CONSTRAINT fk_comissao_venda FOREIGN KEY (id_venda) REFERENCES public.venda(id_venda);


--
-- TOC entry 7608 (class 2606 OID 25415)
-- Name: conciliacao_bancaria fk_conciliacao_bancaria_id_conta_bancaria; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conciliacao_bancaria
    ADD CONSTRAINT fk_conciliacao_bancaria_id_conta_bancaria FOREIGN KEY (id_conta_bancaria) REFERENCES public.conta_bancaria(id_conta_bancaria);


--
-- TOC entry 7609 (class 2606 OID 25420)
-- Name: conciliacao_bancaria fk_conciliacao_bancaria_id_lancamento; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conciliacao_bancaria
    ADD CONSTRAINT fk_conciliacao_bancaria_id_lancamento FOREIGN KEY (id_lancamento) REFERENCES public.lancamento_financeiro(id_lancamento);


--
-- TOC entry 7688 (class 2606 OID 27438)
-- Name: conector_integracao fk_conector_sistema; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conector_integracao
    ADD CONSTRAINT fk_conector_sistema FOREIGN KEY (id_sistema_externo) REFERENCES public.sistema_externo(id_sistema_externo);


--
-- TOC entry 7682 (class 2606 OID 27015)
-- Name: configuracao_empresa fk_config_empresa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.configuracao_empresa
    ADD CONSTRAINT fk_config_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa);


--
-- TOC entry 7596 (class 2606 OID 33426)
-- Name: conta_bancaria fk_conta_bancaria_banco; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_bancaria
    ADD CONSTRAINT fk_conta_bancaria_banco FOREIGN KEY (id_banco) REFERENCES public.banco(id_banco);


--
-- TOC entry 7597 (class 2606 OID 25308)
-- Name: conta_bancaria fk_conta_empresa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.conta_bancaria
    ADD CONSTRAINT fk_conta_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa);


--
-- TOC entry 7593 (class 2606 OID 25194)
-- Name: plano_contas fk_conta_pai; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plano_contas
    ADD CONSTRAINT fk_conta_pai FOREIGN KEY (id_conta_pai) REFERENCES public.plano_contas(id_conta);


--
-- TOC entry 7644 (class 2606 OID 26244)
-- Name: contato_cliente fk_contato_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contato_cliente
    ADD CONSTRAINT fk_contato_cliente FOREIGN KEY (id_cliente) REFERENCES public.cliente(id_cliente);


--
-- TOC entry 7671 (class 2606 OID 26796)
-- Name: contrato fk_contrato_documento; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.contrato
    ADD CONSTRAINT fk_contrato_documento FOREIGN KEY (id_documento) REFERENCES public.documento(id_documento);


--
-- TOC entry 7673 (class 2606 OID 26829)
-- Name: controle_vencimento_documento fk_controle_documento; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.controle_vencimento_documento
    ADD CONSTRAINT fk_controle_documento FOREIGN KEY (id_documento) REFERENCES public.documento(id_documento);


--
-- TOC entry 7642 (class 2606 OID 26174)
-- Name: custo_pacote fk_custo_pacote; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custo_pacote
    ADD CONSTRAINT fk_custo_pacote FOREIGN KEY (id_pacote) REFERENCES public.pacote_viagem(id_pacote);


--
-- TOC entry 7679 (class 2606 OID 26942)
-- Name: custo_projeto fk_custo_projeto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.custo_projeto
    ADD CONSTRAINT fk_custo_projeto FOREIGN KEY (id_projeto) REFERENCES public.projeto(id_projeto);


--
-- TOC entry 7622 (class 2606 OID 25652)
-- Name: das fk_das_empresa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.das
    ADD CONSTRAINT fk_das_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa);


--
-- TOC entry 7626 (class 2606 OID 25781)
-- Name: declaracao_fiscal fk_declaracao_empresa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.declaracao_fiscal
    ADD CONSTRAINT fk_declaracao_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa);


--
-- TOC entry 7656 (class 2606 OID 26494)
-- Name: depreciacao fk_depreciacao_ativo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.depreciacao
    ADD CONSTRAINT fk_depreciacao_ativo FOREIGN KEY (id_ativo) REFERENCES public.ativo_imobilizado(id_ativo);


--
-- TOC entry 7635 (class 2606 OID 33417)
-- Name: destino fk_destino_localidade; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.destino
    ADD CONSTRAINT fk_destino_localidade FOREIGN KEY (id_localidade) REFERENCES public.localidade(id_localidade);


--
-- TOC entry 7669 (class 2606 OID 26763)
-- Name: documento fk_documento_tipo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.documento
    ADD CONSTRAINT fk_documento_tipo FOREIGN KEY (id_tipo_documento) REFERENCES public.tipo_documento(id_tipo_documento);


--
-- TOC entry 7589 (class 2606 OID 33407)
-- Name: empresa fk_empresa_localidade; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.empresa
    ADD CONSTRAINT fk_empresa_localidade FOREIGN KEY (id_localidade) REFERENCES public.localidade(id_localidade);


--
-- TOC entry 7665 (class 2606 OID 26669)
-- Name: estoque fk_estoque_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.estoque
    ADD CONSTRAINT fk_estoque_produto FOREIGN KEY (id_produto_estoque) REFERENCES public.produto_estoque(id_produto_estoque);


--
-- TOC entry 7675 (class 2606 OID 26886)
-- Name: etapa_projeto fk_etapa_projeto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.etapa_projeto
    ADD CONSTRAINT fk_etapa_projeto FOREIGN KEY (id_projeto) REFERENCES public.projeto(id_projeto);


--
-- TOC entry 7691 (class 2606 OID 27513)
-- Name: fila_integracao fk_fila_integracao_conector; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fila_integracao
    ADD CONSTRAINT fk_fila_integracao_conector FOREIGN KEY (id_conector) REFERENCES public.conector_integracao(id_conector);


--
-- TOC entry 7592 (class 2606 OID 25158)
-- Name: fornecedor fk_fornecedor_pessoa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fornecedor
    ADD CONSTRAINT fk_fornecedor_pessoa FOREIGN KEY (id_pessoa) REFERENCES public.pessoa(id_pessoa);


--
-- TOC entry 7638 (class 2606 OID 26087)
-- Name: fornecedor_turistico fk_ft_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.fornecedor_turistico
    ADD CONSTRAINT fk_ft_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES public.fornecedor(id_fornecedor);


--
-- TOC entry 7645 (class 2606 OID 26261)
-- Name: funil_vendas fk_funil_lead; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.funil_vendas
    ADD CONSTRAINT fk_funil_lead FOREIGN KEY (id_lead) REFERENCES public.lead(id_lead);


--
-- TOC entry 7674 (class 2606 OID 26846)
-- Name: historico_documento fk_historico_documento; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.historico_documento
    ADD CONSTRAINT fk_historico_documento FOREIGN KEY (id_documento) REFERENCES public.documento(id_documento);


--
-- TOC entry 7654 (class 2606 OID 26432)
-- Name: horas_atividade fk_horas_colaborador; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.horas_atividade
    ADD CONSTRAINT fk_horas_colaborador FOREIGN KEY (id_colaborador) REFERENCES public.colaborador(id_colaborador);


--
-- TOC entry 7639 (class 2606 OID 26106)
-- Name: hospedagem fk_hospedagem_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.hospedagem
    ADD CONSTRAINT fk_hospedagem_fornecedor FOREIGN KEY (id_fornecedor_turistico) REFERENCES public.fornecedor_turistico(id_fornecedor_turistico);


--
-- TOC entry 7634 (class 2606 OID 26003)
-- Name: integracao_nfse fk_integracao_nf; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integracao_nfse
    ADD CONSTRAINT fk_integracao_nf FOREIGN KEY (id_nota_fiscal) REFERENCES public.nota_fiscal(id_nota_fiscal);


--
-- TOC entry 7646 (class 2606 OID 26279)
-- Name: interacao_lead fk_interacao_lead; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.interacao_lead
    ADD CONSTRAINT fk_interacao_lead FOREIGN KEY (id_lead) REFERENCES public.lead(id_lead);


--
-- TOC entry 7667 (class 2606 OID 26721)
-- Name: item_inventario fk_item_inv_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_inventario
    ADD CONSTRAINT fk_item_inv_produto FOREIGN KEY (id_produto_estoque) REFERENCES public.produto_estoque(id_produto_estoque);


--
-- TOC entry 7668 (class 2606 OID 26716)
-- Name: item_inventario fk_item_inventario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_inventario
    ADD CONSTRAINT fk_item_inventario FOREIGN KEY (id_inventario) REFERENCES public.inventario(id_inventario);


--
-- TOC entry 7663 (class 2606 OID 26648)
-- Name: item_pedido_compra fk_item_pedido; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_pedido_compra
    ADD CONSTRAINT fk_item_pedido FOREIGN KEY (id_pedido) REFERENCES public.pedido_compra(id_pedido);


--
-- TOC entry 7664 (class 2606 OID 26653)
-- Name: item_pedido_compra fk_item_pedido_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_pedido_compra
    ADD CONSTRAINT fk_item_pedido_produto FOREIGN KEY (id_produto_estoque) REFERENCES public.produto_estoque(id_produto_estoque);


--
-- TOC entry 7617 (class 2606 OID 25580)
-- Name: item_venda fk_item_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_venda
    ADD CONSTRAINT fk_item_produto FOREIGN KEY (id_produto) REFERENCES public.produto_turistico(id_produto);


--
-- TOC entry 7660 (class 2606 OID 26611)
-- Name: item_requisicao fk_item_produto_estoque; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_requisicao
    ADD CONSTRAINT fk_item_produto_estoque FOREIGN KEY (id_produto_estoque) REFERENCES public.produto_estoque(id_produto_estoque);


--
-- TOC entry 7661 (class 2606 OID 26606)
-- Name: item_requisicao fk_item_req; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_requisicao
    ADD CONSTRAINT fk_item_req FOREIGN KEY (id_requisicao) REFERENCES public.requisicao_compra(id_requisicao);


--
-- TOC entry 7618 (class 2606 OID 25575)
-- Name: item_venda fk_item_venda; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.item_venda
    ADD CONSTRAINT fk_item_venda FOREIGN KEY (id_venda) REFERENCES public.venda(id_venda);


--
-- TOC entry 7598 (class 2606 OID 25359)
-- Name: lancamento_financeiro fk_lanc_banco; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_financeiro
    ADD CONSTRAINT fk_lanc_banco FOREIGN KEY (id_conta_bancaria) REFERENCES public.conta_bancaria(id_conta_bancaria);


--
-- TOC entry 7599 (class 2606 OID 25791)
-- Name: lancamento_financeiro fk_lanc_categoria; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_financeiro
    ADD CONSTRAINT fk_lanc_categoria FOREIGN KEY (id_categoria) REFERENCES public.categoria_conta(id_categoria);


--
-- TOC entry 7600 (class 2606 OID 25369)
-- Name: lancamento_financeiro fk_lanc_centro; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_financeiro
    ADD CONSTRAINT fk_lanc_centro FOREIGN KEY (id_centro_custo) REFERENCES public.centro_custo(id_centro_custo);


--
-- TOC entry 7601 (class 2606 OID 25349)
-- Name: lancamento_financeiro fk_lanc_empresa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_financeiro
    ADD CONSTRAINT fk_lanc_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa);


--
-- TOC entry 7602 (class 2606 OID 25786)
-- Name: lancamento_financeiro fk_lanc_grupo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_financeiro
    ADD CONSTRAINT fk_lanc_grupo FOREIGN KEY (id_grupo) REFERENCES public.grupo_conta(id_grupo);


--
-- TOC entry 7603 (class 2606 OID 25364)
-- Name: lancamento_financeiro fk_lanc_pagamento; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_financeiro
    ADD CONSTRAINT fk_lanc_pagamento FOREIGN KEY (id_forma_pagamento) REFERENCES public.forma_pagamento(id_forma_pagamento);


--
-- TOC entry 7604 (class 2606 OID 25354)
-- Name: lancamento_financeiro fk_lanc_pessoa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_financeiro
    ADD CONSTRAINT fk_lanc_pessoa FOREIGN KEY (id_pessoa) REFERENCES public.pessoa(id_pessoa);


--
-- TOC entry 7605 (class 2606 OID 25425)
-- Name: lancamento_financeiro fk_lanc_plano_contas; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_financeiro
    ADD CONSTRAINT fk_lanc_plano_contas FOREIGN KEY (id_conta_plano) REFERENCES public.plano_contas(id_conta);


--
-- TOC entry 7643 (class 2606 OID 26211)
-- Name: lead fk_lead_origem; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lead
    ADD CONSTRAINT fk_lead_origem FOREIGN KEY (id_origem) REFERENCES public.origem_lead(id_origem);


--
-- TOC entry 7686 (class 2606 OID 27183)
-- Name: log_api fk_log_api_aplicacao; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_api
    ADD CONSTRAINT fk_log_api_aplicacao FOREIGN KEY (id_aplicacao) REFERENCES public.aplicacao_api(id_aplicacao);


--
-- TOC entry 7692 (class 2606 OID 27536)
-- Name: log_integracao_detalhado fk_log_integracao_conector; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_integracao_detalhado
    ADD CONSTRAINT fk_log_integracao_conector FOREIGN KEY (id_conector) REFERENCES public.conector_integracao(id_conector);


--
-- TOC entry 7693 (class 2606 OID 27541)
-- Name: log_integracao_detalhado fk_log_integracao_sincronizacao; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_integracao_detalhado
    ADD CONSTRAINT fk_log_integracao_sincronizacao FOREIGN KEY (id_sincronizacao) REFERENCES public.sincronizacao_integracao(id_sincronizacao);


--
-- TOC entry 7624 (class 2606 OID 25725)
-- Name: distribuicao_lucros fk_lucro_empresa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.distribuicao_lucros
    ADD CONSTRAINT fk_lucro_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa);


--
-- TOC entry 7657 (class 2606 OID 26512)
-- Name: manutencao_ativo fk_manutencao_ativo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.manutencao_ativo
    ADD CONSTRAINT fk_manutencao_ativo FOREIGN KEY (id_ativo) REFERENCES public.ativo_imobilizado(id_ativo);


--
-- TOC entry 7689 (class 2606 OID 27462)
-- Name: mapeamento_campo_integracao fk_mapeamento_conector; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.mapeamento_campo_integracao
    ADD CONSTRAINT fk_mapeamento_conector FOREIGN KEY (id_conector) REFERENCES public.conector_integracao(id_conector);


--
-- TOC entry 7658 (class 2606 OID 26542)
-- Name: movimentacao_ativo fk_movimento_ativo; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimentacao_ativo
    ADD CONSTRAINT fk_movimento_ativo FOREIGN KEY (id_ativo) REFERENCES public.ativo_imobilizado(id_ativo);


--
-- TOC entry 7659 (class 2606 OID 26547)
-- Name: movimentacao_ativo fk_movimento_localizacao; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimentacao_ativo
    ADD CONSTRAINT fk_movimento_localizacao FOREIGN KEY (id_localizacao) REFERENCES public.localizacao_ativo(id_localizacao);


--
-- TOC entry 7666 (class 2606 OID 26688)
-- Name: movimento_estoque fk_movimento_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.movimento_estoque
    ADD CONSTRAINT fk_movimento_produto FOREIGN KEY (id_produto_estoque) REFERENCES public.produto_estoque(id_produto_estoque);


--
-- TOC entry 7619 (class 2606 OID 25606)
-- Name: nota_fiscal fk_nf_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nota_fiscal
    ADD CONSTRAINT fk_nf_cliente FOREIGN KEY (id_cliente) REFERENCES public.cliente(id_cliente);


--
-- TOC entry 7620 (class 2606 OID 25601)
-- Name: nota_fiscal fk_nf_empresa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.nota_fiscal
    ADD CONSTRAINT fk_nf_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa);


--
-- TOC entry 7683 (class 2606 OID 27045)
-- Name: notificacao fk_notificacao_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notificacao
    ADD CONSTRAINT fk_notificacao_usuario FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);


--
-- TOC entry 7632 (class 2606 OID 25970)
-- Name: openfinance_conexao fk_open_empresa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.openfinance_conexao
    ADD CONSTRAINT fk_open_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa);


--
-- TOC entry 7633 (class 2606 OID 25985)
-- Name: openfinance_movimento fk_open_movimento; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.openfinance_movimento
    ADD CONSTRAINT fk_open_movimento FOREIGN KEY (id_conexao) REFERENCES public.openfinance_conexao(id_conexao);


--
-- TOC entry 7610 (class 2606 OID 25465)
-- Name: pacote_viagem fk_pacote_produto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pacote_viagem
    ADD CONSTRAINT fk_pacote_produto FOREIGN KEY (id_produto) REFERENCES public.produto_turistico(id_produto);


--
-- TOC entry 7630 (class 2606 OID 25952)
-- Name: pagamento_transacao fk_pagamento_gateway; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamento_transacao
    ADD CONSTRAINT fk_pagamento_gateway FOREIGN KEY (id_gateway) REFERENCES public.gateway_pagamento(id_gateway);


--
-- TOC entry 7631 (class 2606 OID 25947)
-- Name: pagamento_transacao fk_pagamento_venda; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pagamento_transacao
    ADD CONSTRAINT fk_pagamento_venda FOREIGN KEY (id_venda) REFERENCES public.venda(id_venda);


--
-- TOC entry 7606 (class 2606 OID 25391)
-- Name: lancamento_parcela fk_parcela_lancamento; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_parcela
    ADD CONSTRAINT fk_parcela_lancamento FOREIGN KEY (id_lancamento) REFERENCES public.lancamento_financeiro(id_lancamento);


--
-- TOC entry 7607 (class 2606 OID 33448)
-- Name: lancamento_parcela fk_parcela_status; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.lancamento_parcela
    ADD CONSTRAINT fk_parcela_status FOREIGN KEY (id_status_parcela) REFERENCES public.status_parcela(id_status_parcela);


--
-- TOC entry 7613 (class 2606 OID 25512)
-- Name: passageiro fk_passageiro_reserva; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.passageiro
    ADD CONSTRAINT fk_passageiro_reserva FOREIGN KEY (id_reserva) REFERENCES public.reserva(id_reserva);


--
-- TOC entry 7662 (class 2606 OID 26631)
-- Name: pedido_compra fk_pedido_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pedido_compra
    ADD CONSTRAINT fk_pedido_fornecedor FOREIGN KEY (id_fornecedor) REFERENCES public.fornecedor(id_fornecedor);


--
-- TOC entry 7590 (class 2606 OID 33402)
-- Name: pessoa fk_pessoa_localidade; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pessoa
    ADD CONSTRAINT fk_pessoa_localidade FOREIGN KEY (id_localidade) REFERENCES public.localidade(id_localidade);


--
-- TOC entry 7625 (class 2606 OID 25741)
-- Name: pro_labore fk_prolabore_empresa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.pro_labore
    ADD CONSTRAINT fk_prolabore_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa);


--
-- TOC entry 7687 (class 2606 OID 27199)
-- Name: rate_limit_api fk_rate_aplicacao; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.rate_limit_api
    ADD CONSTRAINT fk_rate_aplicacao FOREIGN KEY (id_aplicacao) REFERENCES public.aplicacao_api(id_aplicacao);


--
-- TOC entry 7611 (class 2606 OID 25488)
-- Name: reserva fk_reserva_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva
    ADD CONSTRAINT fk_reserva_cliente FOREIGN KEY (id_cliente) REFERENCES public.cliente(id_cliente);


--
-- TOC entry 7612 (class 2606 OID 25493)
-- Name: reserva fk_reserva_pacote; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reserva
    ADD CONSTRAINT fk_reserva_pacote FOREIGN KEY (id_pacote) REFERENCES public.pacote_viagem(id_pacote);


--
-- TOC entry 7677 (class 2606 OID 26927)
-- Name: responsavel_projeto fk_resp_colaborador; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.responsavel_projeto
    ADD CONSTRAINT fk_resp_colaborador FOREIGN KEY (id_colaborador) REFERENCES public.colaborador(id_colaborador);


--
-- TOC entry 7678 (class 2606 OID 26922)
-- Name: responsavel_projeto fk_resp_projeto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.responsavel_projeto
    ADD CONSTRAINT fk_resp_projeto FOREIGN KEY (id_projeto) REFERENCES public.projeto(id_projeto);


--
-- TOC entry 7680 (class 2606 OID 26959)
-- Name: risco_projeto fk_risco_projeto; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risco_projeto
    ADD CONSTRAINT fk_risco_projeto FOREIGN KEY (id_projeto) REFERENCES public.projeto(id_projeto);


--
-- TOC entry 7636 (class 2606 OID 26069)
-- Name: roteiro_viagem fk_roteiro_destino; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roteiro_viagem
    ADD CONSTRAINT fk_roteiro_destino FOREIGN KEY (id_destino) REFERENCES public.destino(id_destino);


--
-- TOC entry 7637 (class 2606 OID 26064)
-- Name: roteiro_viagem fk_roteiro_pacote; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.roteiro_viagem
    ADD CONSTRAINT fk_roteiro_pacote FOREIGN KEY (id_pacote) REFERENCES public.pacote_viagem(id_pacote);


--
-- TOC entry 7621 (class 2606 OID 25635)
-- Name: simples_nacional fk_simples_empresa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.simples_nacional
    ADD CONSTRAINT fk_simples_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa);


--
-- TOC entry 7690 (class 2606 OID 27488)
-- Name: sincronizacao_integracao fk_sincronizacao_conector; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.sincronizacao_integracao
    ADD CONSTRAINT fk_sincronizacao_conector FOREIGN KEY (id_conector) REFERENCES public.conector_integracao(id_conector);


--
-- TOC entry 7694 (class 2606 OID 27566)
-- Name: status_integracao fk_status_integracao_conector; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.status_integracao
    ADD CONSTRAINT fk_status_integracao_conector FOREIGN KEY (id_conector) REFERENCES public.conector_integracao(id_conector);


--
-- TOC entry 7595 (class 2606 OID 25252)
-- Name: subcategoria_conta fk_subcategoria_categoria; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.subcategoria_conta
    ADD CONSTRAINT fk_subcategoria_categoria FOREIGN KEY (id_categoria) REFERENCES public.categoria_conta(id_categoria);


--
-- TOC entry 7676 (class 2606 OID 26906)
-- Name: tarefa_projeto fk_tarefa_etapa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarefa_projeto
    ADD CONSTRAINT fk_tarefa_etapa FOREIGN KEY (id_etapa) REFERENCES public.etapa_projeto(id_etapa);


--
-- TOC entry 7653 (class 2606 OID 26415)
-- Name: tarefa fk_tarefa_responsavel; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.tarefa
    ADD CONSTRAINT fk_tarefa_responsavel FOREIGN KEY (responsavel) REFERENCES public.colaborador(id_colaborador);


--
-- TOC entry 7684 (class 2606 OID 27122)
-- Name: token_acesso fk_token_aplicacao; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.token_acesso
    ADD CONSTRAINT fk_token_aplicacao FOREIGN KEY (id_aplicacao) REFERENCES public.aplicacao_api(id_aplicacao);


--
-- TOC entry 7640 (class 2606 OID 26123)
-- Name: transporte fk_transporte_fornecedor; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transporte
    ADD CONSTRAINT fk_transporte_fornecedor FOREIGN KEY (id_fornecedor_turistico) REFERENCES public.fornecedor_turistico(id_fornecedor_turistico);


--
-- TOC entry 7627 (class 2606 OID 25871)
-- Name: usuario_perfil fk_usuario_perfil_perfil; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_perfil
    ADD CONSTRAINT fk_usuario_perfil_perfil FOREIGN KEY (id_perfil) REFERENCES public.perfil_acesso(id_perfil);


--
-- TOC entry 7628 (class 2606 OID 25866)
-- Name: usuario_perfil fk_usuario_perfil_usuario; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.usuario_perfil
    ADD CONSTRAINT fk_usuario_perfil_usuario FOREIGN KEY (id_usuario) REFERENCES public.usuario(id_usuario);


--
-- TOC entry 7616 (class 2606 OID 25555)
-- Name: venda fk_venda_cliente; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.venda
    ADD CONSTRAINT fk_venda_cliente FOREIGN KEY (id_cliente) REFERENCES public.cliente(id_cliente);


--
-- TOC entry 7629 (class 2606 OID 25916)
-- Name: integracao_woocommerce fk_wc_empresa; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.integracao_woocommerce
    ADD CONSTRAINT fk_wc_empresa FOREIGN KEY (id_empresa) REFERENCES public.empresa(id_empresa);


-- Completed on 2026-08-16 11:49:58

--
-- PostgreSQL database dump complete
--

\unrestrict tBnlGCIfBLQl1Rr5YlnPONTGyjntm8su1O9Rm6wxuUA8RrVBEXcTQZzcVEl7Z6g

