"""Testes adversariais PostgreSQL da certificacao Bike Tour."""

from __future__ import annotations

from collections.abc import Callable, Generator
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, datetime, timedelta
from importlib import import_module
from threading import Event
from time import monotonic
from typing import cast
from uuid import uuid4

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Connection, Engine, make_url
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db import models as registered_models  # noqa: F401
from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import (
    EventoBikeTour,
    InscricaoBikeTour,
    RecursoBikeTour,
)
from app.modules.biketour.operational_schemas import InscricaoAcao
from app.modules.biketour.operations import OperacoesBikeTour
from app.modules.biketour.uow import BikeTourUnitOfWork, ContextoComando, ResultadoComando
from app.modules.seguranca.rbac import ContextoRbac

_create_integrity_fixture = cast(
    Callable[[Connection, str], dict[str, object]],
    import_module("tests.integration.test_biketour_postgresql")._create_integrity_fixture,
)

_create_inscricao = cast(
    Callable[..., object],
    import_module("tests.integration.test_biketour_postgresql")._create_inscricao,
)
_create_pg_allocation = cast(
    Callable[..., object],
    import_module("tests.integration.test_biketour_postgresql")._create_allocation,
)

EXPECTED_REVISION = "202609170300"
pytestmark = pytest.mark.postgresql


@pytest.fixture
def biketour_engine(postgresql_test_url: str) -> Generator[Engine]:
    engine = create_engine(postgresql_test_url)

    with engine.connect() as connection:
        database = connection.execute(text("SELECT current_database()")).scalar_one()
        user = connection.execute(text("SELECT current_user")).scalar_one()

        revision = connection.execute(text("SELECT version_num FROM alembic_version")).scalar_one()

    assert str(database).endswith("_test")
    assert user == make_url(postgresql_test_url).username
    assert revision == EXPECTED_REVISION

    try:
        yield engine
    finally:
        engine.dispose()


def _scalar(
    connection: Connection,
    sql: str,
    **params: object,
) -> object:
    return connection.execute(
        text(sql),
        params,
    ).scalar_one()


def _create_resource(
    connection: Connection,
    token: str,
) -> object:
    return _scalar(
        connection,
        """
        INSERT INTO public.recurso_bike_tour (
            codigo,
            tipo,
            status,
            created_by
        )
        VALUES (
            :codigo,
            'BICICLETA',
            'DISPONIVEL',
            'pytest-adversarial'
        )
        RETURNING id_recurso_bike_tour
        """,
        codigo=f"BT-ADV-{token}",
    )


def _create_allocation(
    connection: Connection,
    *,
    evento: object,
    recurso: object,
    inicio: datetime,
    fim: datetime,
    status: str = "CONFIRMADA",
) -> object:
    expira_em = datetime.now(UTC) + timedelta(minutes=15) if status == "BLOQUEADA" else None

    return _scalar(
        connection,
        """
        INSERT INTO public.alocacao_recurso_bike_tour (
            id_evento_bike_tour,
            id_recurso_bike_tour,
            inicio,
            fim,
            expira_em,
            status,
            created_by
        )
        VALUES (
            :evento,
            :recurso,
            :inicio,
            :fim,
            :expira_em,
            :status,
            'pytest-adversarial'
        )
        RETURNING id_alocacao_recurso_bike_tour
        """,
        evento=evento,
        recurso=recurso,
        inicio=inicio,
        fim=fim,
        expira_em=expira_em,
        status=status,
    )


def _create_actor(connection: Connection) -> ContextoRbac:
    identifier = _scalar(
        connection,
        """
        INSERT INTO public.usuario (nome, email)
        VALUES (:nome, :email)
        RETURNING id_usuario
        """,
        nome="Teste adversarial Bike Tour",
        email=f"bt-adv-{uuid4().hex}@example.invalid",
    )
    return ContextoRbac(
        cast(int, identifier),
        (),
        frozenset(
            {
                "BIKE_TOUR_VISUALIZAR",
                "BIKE_TOUR_OPERAR",
                "BIKE_TOUR_GERENCIAR",
            }
        ),
    )


def _cleanup_integrity_fixture(
    engine: Engine,
    *,
    token: str,
    actor_id: int | None,
) -> None:
    """Remove somente o fixture commitado, apos o encerramento das threads."""
    saidas = "SELECT id_saida FROM public.saida_turistica WHERE codigo IN (:saida_1, :saida_2)"
    eventos = (
        f"SELECT id_evento_bike_tour FROM public.evento_bike_tour WHERE id_saida IN ({saidas})"
    )
    inscricoes = (
        "SELECT id_inscricao_bike_tour FROM public.inscricao_bike_tour "
        f"WHERE id_evento_bike_tour IN ({eventos})"
    )
    pontos = (
        "SELECT id_ponto_controle_bike_tour FROM public.ponto_controle_bike_tour "
        f"WHERE id_evento_bike_tour IN ({eventos})"
    )
    operacoes = (
        "SELECT id_operacao_bike_tour FROM public.operacao_bike_tour "
        "WHERE id_usuario = :actor_id "
        "AND operacao IN ('teste_t15_alocar', 't16_confirmar', 't16_expirar')"
    )
    reserva = "SELECT id_reserva FROM public.reserva WHERE codigo_reserva = :reserva"
    params = {
        "saida_1": f"BTS-I1-{token}",
        "saida_2": f"BTS-I2-{token}",
        "recurso_1": f"BTB-I1-{token}",
        "recurso_2": f"BTB-I2-{token}",
        "reserva": f"BRV-{token}",
        "pacote": f"BPK-{token}",
        "produto": f"BTP-I-{token}",
        "cliente": f"BTC-{token}",
        "pessoa": f"Bike Tour Test {token}",
        "actor_id": actor_id,
    }
    # Folhas antes das raizes; os subselects ainda encontram os pais existentes.
    # Identificadores SQL sao constantes locais; valores sempre parametrizados.
    deletes = (
        (
            "pendencia_bike_tour",
            f"id_evento_bike_tour IN ({eventos}) "
            f"OR id_inscricao_bike_tour IN ({inscricoes}) "
            f"OR id_operacao_bike_tour IN ({operacoes})",
        ),
        (
            "passagem_bike_tour",
            f"id_inscricao_bike_tour IN ({inscricoes}) "
            f"OR id_ponto_controle_bike_tour IN ({pontos})",
        ),
        ("avaliacao_bike_tour", f"id_inscricao_bike_tour IN ({inscricoes})"),
        ("ocorrencia_bike_tour", f"id_evento_bike_tour IN ({eventos})"),
        ("equipe_bike_tour", f"id_evento_bike_tour IN ({eventos})"),
        ("logistica_bike_tour", f"id_evento_bike_tour IN ({eventos})"),
        ("ponto_controle_bike_tour", f"id_evento_bike_tour IN ({eventos})"),
        ("alocacao_recurso_bike_tour", f"id_evento_bike_tour IN ({eventos})"),
        ("inscricao_bike_tour", f"id_evento_bike_tour IN ({eventos})"),
        ("operacao_bike_tour", f"id_operacao_bike_tour IN ({operacoes})"),
        ("evento_bike_tour", f"id_saida IN ({saidas})"),
        ("recurso_bike_tour", "codigo IN (:recurso_1, :recurso_2)"),
        ("passageiro_reserva", f"id_reserva IN ({reserva})"),
        ("reserva", "codigo_reserva = :reserva"),
        ("saida_turistica", "codigo IN (:saida_1, :saida_2)"),
        ("pacote_viagem", "codigo_pacote = :pacote"),
        ("produto_turistico", "codigo = :produto"),
        ("cliente", "codigo_cliente = :cliente"),
        ("pessoa", "nome_razao_social = :pessoa"),
        ("usuario", "id_usuario = :actor_id"),
    )
    # T15/T16 nao criam vinculos comerciais, financeiros ou de autenticacao.
    # FKs inesperadas abortam a limpeza atomica em vez de apagar esses vinculos.
    # localidade e log_auditoria sao compartilhados/historicos e permanecem intactos.
    with engine.begin() as connection:
        connection.execute(text("SET LOCAL lock_timeout = '5s'"))
        connection.execute(text("SELECT pg_advisory_xact_lock(2700, 1)"))
        # Integridade de inscricao/alocacao e avaliada no commit, com ambas removidas.
        for table, predicate in deletes:
            connection.execute(text(f"DELETE FROM public.{table} WHERE {predicate}"), params)


def _execute_command(
    engine: Engine,
    actor: ContextoRbac,
    *,
    operacao: str,
    alvo: int,
    payload: dict[str, object],
    comando: Callable[[ContextoComando], ResultadoComando],
) -> ResultadoComando:
    with Session(engine, expire_on_commit=False) as session:
        return BikeTourUnitOfWork(session).executar(
            ator=actor,
            permissao="BIKE_TOUR_OPERAR",
            correlation_id=uuid4(),
            operacao=operacao,
            alvo=alvo,
            chave=uuid4().hex,
            payload=payload,
            comando=comando,
        )


def test_t15_duas_conexoes_disputam_ultima_bicicleta(
    biketour_engine: Engine,
) -> None:
    # Duas sessoes concorrentes nao podem confirmar a mesma bicicleta.
    token = uuid4().hex[:12].upper()
    actor_id: int | None = None

    try:
        with biketour_engine.begin() as connection:
            origin = _create_integrity_fixture(connection, token)
            actor = _create_actor(connection)
            actor_id = actor.id_usuario
            evento_id = cast(int, origin["evento_1"])
            recurso_id = cast(int, origin["bicicleta_1"])

        primeiro_entrou = Event()
        liberar_primeiro = Event()
        segundo_iniciou = Event()

        def disputar(*, primeiro: bool) -> ResultadoComando:
            def comando(context: ContextoComando) -> ResultadoComando:
                evento = context.session.get(EventoBikeTour, evento_id)
                recurso = context.session.get(RecursoBikeTour, recurso_id)
                assert evento is not None
                assert recurso is not None

                OperacoesBikeTour(context).alocar(evento, recurso)

                if primeiro:
                    primeiro_entrou.set()
                    assert liberar_primeiro.wait(timeout=10)

                return ResultadoComando(
                    200,
                    {"evento": evento_id, "recurso": recurso_id},
                )

            return _execute_command(
                biketour_engine,
                actor,
                operacao="teste_t15_alocar",
                alvo=evento_id,
                payload={"evento": evento_id, "recurso": recurso_id},
                comando=comando,
            )

        def disputar_segundo() -> ResultadoComando:
            segundo_iniciou.set()
            return disputar(primeiro=False)

        with ThreadPoolExecutor(max_workers=2) as executor:
            primeiro = executor.submit(disputar, primeiro=True)

            try:
                assert primeiro_entrou.wait(timeout=10)

                segundo = executor.submit(disputar_segundo)
                assert segundo_iniciou.wait(timeout=10)

                with biketour_engine.connect() as observer:
                    deadline = monotonic() + 3

                    while not observer.scalar(
                        text(
                            "SELECT count(*) "
                            "FROM pg_locks "
                            "WHERE locktype = 'advisory' "
                            "AND classid = 2700 "
                            "AND objid = 1 "
                            "AND NOT granted"
                        )
                    ):
                        assert monotonic() < deadline, (
                            "segunda conexao nao aguardou o advisory lock real"
                        )
                        segundo_iniciou.wait(timeout=0.01)

                assert not segundo.done()
            finally:
                liberar_primeiro.set()

            resultado = primeiro.result(timeout=15)
            assert resultado.status == 200

            with pytest.raises(BikeTourError) as erro:
                segundo.result(timeout=15)

        assert erro.value.status_code == 409
        assert erro.value.code == "BT_RECURSO_OCUPADO"

        with biketour_engine.connect() as connection:
            quantidade = connection.execute(
                text(
                    "SELECT COUNT(*) "
                    "FROM public.alocacao_recurso_bike_tour "
                    "WHERE id_recurso_bike_tour = :recurso "
                    "AND status IN ('BLOQUEADA', 'CONFIRMADA')"
                ),
                {"recurso": recurso_id},
            ).scalar_one()

        assert quantidade == 1
    finally:
        _cleanup_integrity_fixture(biketour_engine, token=token, actor_id=actor_id)


def test_t03_intervalos_consecutivos_do_mesmo_recurso_sao_permitidos(
    biketour_engine: Engine,
) -> None:
    """Intervalos [inicio,fim) adjacentes nao devem se sobrepor."""
    token = uuid4().hex[:12].upper()

    with biketour_engine.connect() as connection:
        transaction = connection.begin()

        try:
            origin = _create_integrity_fixture(connection, token)

            evento = origin["evento_1"]
            evento_inicio = cast(datetime, origin["inicio"])
            evento_fim = cast(datetime, origin["fim"])

            recurso = _create_resource(
                connection,
                token,
            )

            meio = evento_inicio + ((evento_fim - evento_inicio) / 2)

            _create_allocation(
                connection,
                evento=evento,
                recurso=recurso,
                inicio=evento_inicio,
                fim=meio,
            )

            _create_allocation(
                connection,
                evento=evento,
                recurso=recurso,
                inicio=meio,
                fim=evento_fim,
            )

            connection.execute(text("SET CONSTRAINTS ALL IMMEDIATE"))

            quantidade = connection.execute(
                text(
                    """
                    SELECT count(*)
                    FROM public.alocacao_recurso_bike_tour
                    WHERE id_recurso_bike_tour = :recurso
                      AND status = 'CONFIRMADA'
                    """
                ),
                {"recurso": recurso},
            ).scalar_one()

            assert quantidade == 2

        finally:
            transaction.rollback()


def test_t03_sobreposicao_real_do_mesmo_recurso_e_rejeitada(
    biketour_engine: Engine,
) -> None:
    """Intervalos ativos realmente sobrepostos devem ser rejeitados."""
    token = uuid4().hex[:12].upper()

    with biketour_engine.connect() as connection:
        transaction = connection.begin()

        try:
            origin = _create_integrity_fixture(connection, token)

            evento = origin["evento_1"]
            evento_inicio = cast(datetime, origin["inicio"])
            evento_fim = cast(datetime, origin["fim"])

            recurso = _create_resource(
                connection,
                token,
            )

            meio = evento_inicio + ((evento_fim - evento_inicio) / 2)

            _create_allocation(
                connection,
                evento=evento,
                recurso=recurso,
                inicio=evento_inicio,
                fim=meio + timedelta(minutes=1),
            )

            with pytest.raises(IntegrityError) as exc_info:
                _create_allocation(
                    connection,
                    evento=evento,
                    recurso=recurso,
                    inicio=meio,
                    fim=evento_fim,
                )

            original = exc_info.value.orig
            sqlstate = getattr(original, "sqlstate", None)

            assert sqlstate == "23P01"
            assert "ex_alocacao_recurso_bike_tour_periodo_ativo" in str(original)

        finally:
            transaction.rollback()


def test_t16_expiracao_concorrente_com_confirmacao_mantem_estado_consistente(
    biketour_engine: Engine,
) -> None:
    """T16: expiracao e confirmacao concorrentes nunca produzem estado impossivel."""
    token = uuid4().hex[:12].upper()
    actor_id: int | None = None

    try:
        with biketour_engine.begin() as connection:
            origin = _create_integrity_fixture(connection, token)
            actor = _create_actor(connection)
            actor_id = actor.id_usuario

            evento_id = cast(int, origin["evento_1"])
            recurso_id = cast(int, origin["bicicleta_1"])

            reserva_id = cast(int, origin["reserva"])
            passageiro_id = cast(int, origin["passageiro_1"])

            connection.execute(
                text(
                    """
                    UPDATE evento_bike_tour
                    SET status = 'ABERTO'
                    WHERE id_evento_bike_tour = :evento
                    """
                ),
                {"evento": evento_id},
            )

            inscricao_id = cast(
                int,
                _create_inscricao(
                    connection,
                    evento=evento_id,
                    reserva=reserva_id,
                    passageiro=passageiro_id,
                    status="PENDENTE",
                ),
            )

            inicio_fim = (
                connection.execute(
                    text(
                        """
                    SELECT inicio, fim
                    FROM evento_bike_tour
                    WHERE id_evento_bike_tour = :evento
                    """
                    ),
                    {"evento": evento_id},
                )
                .mappings()
                .one()
            )

            alocacao_id = cast(
                int,
                _create_pg_allocation(
                    connection,
                    evento=evento_id,
                    inscricao=inscricao_id,
                    recurso=recurso_id,
                    inicio=inicio_fim["inicio"],
                    fim=inicio_fim["fim"],
                    status="BLOQUEADA",
                ),
            )

            # A alocacao nasce com a validade normal do helper.
            # O vencimento adversarial sera armado somente depois que a
            # confirmacao tiver capturado ctx.agora dentro do UoW.

        confirmacao_entrou = Event()
        liberar_confirmacao = Event()
        expiracao_iniciou = Event()

        def confirmar() -> ResultadoComando:
            def comando(context: ContextoComando) -> ResultadoComando:
                # ctx.agora ja foi capturado apos o advisory lock.
                # Rearma o vencimento para um instante posterior a ctx.agora,
                # mantendo a confirmacao elegivel segundo o proprio contrato.
                context.session.execute(
                    text(
                        """
                        UPDATE alocacao_recurso_bike_tour
                        SET expira_em = :expira_em
                        WHERE id_alocacao_recurso_bike_tour = :id
                        """
                    ),
                    {
                        "expira_em": context.agora + timedelta(milliseconds=250),
                        "id": alocacao_id,
                    },
                )
                context.session.flush()

                confirmacao_entrou.set()
                assert liberar_confirmacao.wait(timeout=10)

                operacoes = OperacoesBikeTour(context)
                inscricao = context.session.get(InscricaoBikeTour, inscricao_id)
                assert inscricao is not None

                payload = InscricaoAcao(
                    acao="CONFIRMAR",
                    chave_idempotencia=f"t16-acao-confirmar-{token}",
                    versao_esperada=inscricao.versao,
                )

                return operacoes.acionar_inscricao(inscricao_id, payload)

            return _execute_command(
                biketour_engine,
                actor=actor,
                operacao="t16_confirmar",
                alvo=inscricao_id,
                payload={"acao": "CONFIRMAR"},
                comando=comando,
            )

        def expirar() -> ResultadoComando:
            expiracao_iniciou.set()

            def comando(context: ContextoComando) -> ResultadoComando:
                expiradas = OperacoesBikeTour(context).expirar()
                return ResultadoComando(200, {"expiradas": expiradas})

            return _execute_command(
                biketour_engine,
                actor=actor,
                operacao="t16_expirar",
                alvo=evento_id,
                payload={"evento": evento_id},
                comando=comando,
            )

        with ThreadPoolExecutor(max_workers=2) as executor:
            futuro_confirmar = executor.submit(confirmar)

            if not confirmacao_entrou.wait(timeout=10):
                if futuro_confirmar.done():
                    futuro_confirmar.result()
                pytest.fail("confirmacao nao entrou no handler e a Future permaneceu ativa")

            futuro_expirar = executor.submit(expirar)
            assert expiracao_iniciou.wait(timeout=10)

            # A segunda operacao precisa estar bloqueada no advisory lock global.
            with biketour_engine.connect() as observer:
                deadline = monotonic() + 3

                while monotonic() < deadline:
                    waiting = observer.scalar(
                        text(
                            """
                            SELECT count(*)
                            FROM pg_locks
                            WHERE locktype = 'advisory'
                              AND classid = 2700
                              AND objid = 1
                              AND NOT granted
                            """
                        )
                    )

                    if waiting and int(waiting) >= 1:
                        break

                    expiracao_iniciou.wait(timeout=0.01)
                else:
                    raise AssertionError("expiracao concorrente nao aguardou advisory lock")

            assert not futuro_expirar.done()

            # Libera a operacao que adquiriu o lock primeiro.
            liberar_confirmacao.set()

            resultado_confirmacao = futuro_confirmar.result(timeout=10)
            resultado_expiracao = futuro_expirar.result(timeout=10)

        assert resultado_confirmacao.status == 200
        assert resultado_expiracao.status == 200

        with biketour_engine.connect() as connection:
            estado = (
                connection.execute(
                    text(
                        """
                    SELECT
                        i.status AS inscricao_status,
                        a.status AS alocacao_status,
                        a.expira_em AS alocacao_expira_em
                    FROM inscricao_bike_tour i
                    JOIN alocacao_recurso_bike_tour a
                      ON a.id_inscricao_bike_tour = i.id_inscricao_bike_tour
                    WHERE i.id_inscricao_bike_tour = :inscricao
                      AND a.id_alocacao_recurso_bike_tour = :alocacao
                    """
                    ),
                    {
                        "inscricao": inscricao_id,
                        "alocacao": alocacao_id,
                    },
                )
                .mappings()
                .one()
            )

            assert estado["inscricao_status"] == "CONFIRMADA"
            assert estado["alocacao_status"] == "CONFIRMADA"
            assert estado["alocacao_expira_em"] is None

            impossiveis = connection.scalar(
                text(
                    """
                    SELECT count(*)
                    FROM inscricao_bike_tour i
                    JOIN alocacao_recurso_bike_tour a
                      ON a.id_inscricao_bike_tour = i.id_inscricao_bike_tour
                    WHERE i.id_inscricao_bike_tour = :inscricao
                      AND i.status = 'CONFIRMADA'
                      AND a.status IN ('EXPIRADA', 'LIBERADA')
                    """
                ),
                {"inscricao": inscricao_id},
            )

            assert impossiveis == 0
    finally:
        _cleanup_integrity_fixture(biketour_engine, token=token, actor_id=actor_id)


# ============================================================================
# API-03-12.G2 â€” EVIDENCIAS ADVERSARIAIS
#
# T09 â€” rollback da substituicao de apoio/equipe
# T10 â€” mesmo guia em eventos temporalmente sobrepostos
# T15 â€” concorrencia pela ultima bicicleta
# T16 â€” corrida expiracao x confirmacao
# T18 â€” rollback da reacomodacao apos reserva do destino
#
# T20 permanece certificado pelo teste PostgreSQL dedicado do Unit of Work:
# test_erro_apos_flush_reverte_estado_auditoria_e_chave
#
# IMPORTANTE:
# Esta secao nao deve contornar OperacoesBikeTour/BikeTourUnitOfWork quando
# a regra que esta sendo certificada pertence a essas camadas.
# ============================================================================


def test_t10_mesmo_recurso_guia_nao_pode_ocupar_eventos_sobrepostos(
    biketour_engine: Engine,
) -> None:
    """T10: um recurso GUIA nao pode ocupar dois eventos sobrepostos."""
    token = uuid4().hex[:12].upper()

    with biketour_engine.connect() as connection:
        transaction = connection.begin()

        try:
            origin = _create_integrity_fixture(connection, token)

            evento_1 = origin["evento_1"]
            evento_2 = origin["evento_2"]
            inicio = cast(datetime, origin["inicio"])
            fim = cast(datetime, origin["fim"])

            id_guia = _scalar(
                connection,
                """
                INSERT INTO public.guia_turistico (
                    nome,
                    created_by
                )
                VALUES (
                    :nome,
                    'pytest-adversarial'
                )
                RETURNING id_guia
                """,
                nome=f"Guia adversarial {token}",
            )

            guia = _scalar(
                connection,
                """
                INSERT INTO public.recurso_bike_tour (
                    codigo,
                    tipo,
                    status,
                    id_guia,
                    created_by
                )
                VALUES (
                    :codigo,
                    'GUIA',
                    'DISPONIVEL',
                    :id_guia,
                    'pytest-adversarial'
                )
                RETURNING id_recurso_bike_tour
                """,
                codigo=f"BT-ADV-GUIA-{token}",
                id_guia=id_guia,
            )

            _create_allocation(
                connection,
                evento=evento_1,
                recurso=guia,
                inicio=inicio,
                fim=fim,
            )

            with (
                pytest.raises(IntegrityError) as exc_info,
                connection.begin_nested(),
            ):
                _create_allocation(
                    connection,
                    evento=evento_2,
                    recurso=guia,
                    inicio=inicio,
                    fim=fim,
                )

            constraint = getattr(
                getattr(exc_info.value.orig, "diag", None),
                "constraint_name",
                None,
            )

            assert constraint == "ex_alocacao_recurso_bike_tour_periodo_ativo"

            primeira = connection.execute(
                text(
                    """
                    SELECT count(*)
                    FROM public.alocacao_recurso_bike_tour
                    WHERE id_evento_bike_tour = :evento
                      AND id_recurso_bike_tour = :recurso
                      AND status IN ('BLOQUEADA', 'CONFIRMADA')
                    """
                ),
                {
                    "evento": evento_1,
                    "recurso": guia,
                },
            ).scalar_one()

            segunda = connection.execute(
                text(
                    """
                    SELECT count(*)
                    FROM public.alocacao_recurso_bike_tour
                    WHERE id_evento_bike_tour = :evento
                      AND id_recurso_bike_tour = :recurso
                      AND status IN ('BLOQUEADA', 'CONFIRMADA')
                    """
                ),
                {
                    "evento": evento_2,
                    "recurso": guia,
                },
            ).scalar_one()

            assert primeira == 1
            assert segunda == 0

        finally:
            transaction.rollback()
