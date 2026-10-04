"""Regressao Bike Tour contra PostgreSQL real descartavel."""

from collections.abc import Generator
from datetime import UTC, datetime, timedelta
from uuid import uuid4

import pytest
from sqlalchemy import create_engine, text
from sqlalchemy.engine import Connection, Engine
from sqlalchemy.exc import IntegrityError

pytestmark = pytest.mark.postgresql

EXPECTED_REVISION = "202609170300"


def _scalar(
    connection: Connection,
    statement: str,
    **parameters: object,
) -> object:
    return connection.execute(
        text(statement),
        parameters,
    ).scalar_one()


@pytest.fixture
def biketour_engine(
    postgresql_test_url: str,
) -> Generator[Engine]:
    """Usa o banco descartavel ja migrado pelo fluxo Alembic."""
    engine = create_engine(
        postgresql_test_url,
        pool_pre_ping=True,
    )

    with engine.connect() as connection:
        database = connection.execute(text("SELECT current_database()")).scalar_one()

        revision = connection.execute(text("SELECT version_num FROM alembic_version")).scalar_one()

        assert str(database).endswith("_test")
        assert revision == EXPECTED_REVISION

    try:
        yield engine
    finally:
        engine.dispose()


def _assert_fixture_absent(
    connection: Connection,
    token: str,
) -> None:
    """Confirma que a fixture transacional nao deixou residuos."""
    checks = (
        (
            "produto_turistico",
            "codigo",
            f"BTP-{token}",
        ),
        (
            "saida_turistica",
            "codigo",
            f"BTS-{token}",
        ),
        (
            "recurso_bike_tour",
            "codigo",
            f"BTR-{token}",
        ),
    )

    for table, column, value in checks:
        count = connection.execute(
            text(
                f"""
                SELECT count(*)
                FROM public.{table}
                WHERE {column} = :value
                """
            ),
            {"value": value},
        ).scalar_one()

        assert count == 0, (
            table,
            value,
            count,
        )


def test_biketour_audit_triggers_increment_version_and_rollback(
    biketour_engine: Engine,
) -> None:
    """Prova versionamento 1->2 e rollback integral no PostgreSQL."""
    token = uuid4().hex[:12].upper()

    inicio = datetime.now(UTC) + timedelta(days=60)
    fim = inicio + timedelta(hours=4)

    with biketour_engine.connect() as connection:
        transaction = connection.begin()

        try:
            produto = _scalar(
                connection,
                """
                INSERT INTO public.produto_turistico (
                    codigo,
                    nome,
                    tipo_produto,
                    created_by
                )
                VALUES (
                    :codigo,
                    :nome,
                    'CICLOTURISMO',
                    'pytest-biketour'
                )
                RETURNING id_produto
                """,
                codigo=f"BTP-{token}",
                nome=f"Bike Tour PostgreSQL {token}",
            )

            pacote = _scalar(
                connection,
                """
                INSERT INTO public.pacote_viagem (
                    id_produto,
                    created_by
                )
                VALUES (
                    :produto,
                    'pytest-biketour'
                )
                RETURNING id_pacote
                """,
                produto=produto,
            )

            saida = _scalar(
                connection,
                """
                INSERT INTO public.saida_turistica (
                    id_pacote,
                    codigo,
                    data_inicio,
                    data_fim,
                    capacidade,
                    status,
                    created_by
                )
                VALUES (
                    :pacote,
                    :codigo,
                    :inicio,
                    :fim,
                    10,
                    'PLANEJADA',
                    'pytest-biketour'
                )
                RETURNING id_saida
                """,
                pacote=pacote,
                codigo=f"BTS-{token}",
                inicio=inicio,
                fim=fim,
            )

            produto_bike_tour = _scalar(
                connection,
                """
                INSERT INTO public.produto_bike_tour (
                    id_produto,
                    distancia_km,
                    desnivel_m,
                    nivel,
                    ativo,
                    created_by
                )
                VALUES (
                    :produto,
                    25.00,
                    300.00,
                    'INTERMEDIARIO',
                    true,
                    'pytest-biketour'
                )
                RETURNING id_produto_bike_tour
                """,
                produto=produto,
            )

            evento = _scalar(
                connection,
                """
                INSERT INTO public.evento_bike_tour (
                    id_saida,
                    inicio,
                    fim,
                    capacidade,
                    status,
                    created_by
                )
                VALUES (
                    :saida,
                    :inicio,
                    :fim,
                    10,
                    'ABERTO',
                    'pytest-biketour'
                )
                RETURNING id_evento_bike_tour
                """,
                saida=saida,
                inicio=inicio,
                fim=fim,
            )

            recurso = _scalar(
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
                    'pytest-biketour'
                )
                RETURNING id_recurso_bike_tour
                """,
                codigo=f"BTR-{token}",
            )

            cases = (
                (
                    "produto_bike_tour",
                    "id_produto_bike_tour",
                    produto_bike_tour,
                    """
                    UPDATE public.produto_bike_tour
                    SET
                        distancia_km = 26.00,
                        updated_by = 'pytest-biketour'
                    WHERE id_produto_bike_tour = :id
                    """,
                ),
                (
                    "evento_bike_tour",
                    "id_evento_bike_tour",
                    evento,
                    """
                    UPDATE public.evento_bike_tour
                    SET
                        capacidade = 11,
                        updated_by = 'pytest-biketour'
                    WHERE id_evento_bike_tour = :id
                    """,
                ),
                (
                    "recurso_bike_tour",
                    "id_recurso_bike_tour",
                    recurso,
                    """
                    UPDATE public.recurso_bike_tour
                    SET
                        status = 'MANUTENCAO',
                        updated_by = 'pytest-biketour'
                    WHERE id_recurso_bike_tour = :id
                    """,
                ),
            )

            for (
                table,
                primary_key,
                identifier,
                update_statement,
            ) in cases:
                before = connection.execute(
                    text(
                        f"""
                        SELECT
                            versao,
                            updated_at,
                            updated_by
                        FROM public.{table}
                        WHERE {primary_key} = :id
                        """
                    ),
                    {"id": identifier},
                ).one()

                assert before.versao == 1
                assert before.updated_at is None
                assert before.updated_by is None

                connection.execute(
                    text(update_statement),
                    {"id": identifier},
                )

                after = connection.execute(
                    text(
                        f"""
                        SELECT
                            versao,
                            updated_at,
                            updated_by
                        FROM public.{table}
                        WHERE {primary_key} = :id
                        """
                    ),
                    {"id": identifier},
                ).one()

                assert after.versao == 2
                assert after.updated_at is not None
                assert after.updated_by == "pytest-biketour"

        finally:
            transaction.rollback()

    with biketour_engine.connect() as connection:
        _assert_fixture_absent(
            connection,
            token,
        )


def _create_integrity_fixture(
    connection: Connection,
    token: str,
) -> dict[str, object]:
    """Cria fixture minima para integridade Bike Tour."""
    inicio = datetime.now(UTC) + timedelta(days=90)
    fim = inicio + timedelta(hours=4)

    localidade = connection.execute(
        text(
            """
            SELECT id_localidade
            FROM public.localidade
            WHERE cidade = 'Curitiba'
              AND uf = 'PR'
              AND pais = 'Brasil'
            ORDER BY id_localidade
            LIMIT 1
            """
        )
    ).scalar_one_or_none()

    if localidade is None:
        localidade = _scalar(
            connection,
            """
            INSERT INTO public.localidade (
                cidade,
                uf,
                pais
            )
            VALUES (
                'Curitiba',
                'PR',
                'Brasil'
            )
            RETURNING id_localidade
            """,
        )

    pessoa = _scalar(
        connection,
        """
        INSERT INTO public.pessoa (
            tipo_pessoa,
            nome_razao_social,
            id_localidade
        )
        VALUES (
            'FISICA',
            :nome,
            :localidade
        )
        RETURNING id_pessoa
        """,
        nome=f"Bike Tour Test {token}",
        localidade=localidade,
    )

    cliente = _scalar(
        connection,
        """
        INSERT INTO public.cliente (
            id_pessoa,
            codigo_cliente
        )
        VALUES (
            :pessoa,
            :codigo
        )
        RETURNING id_cliente
        """,
        pessoa=pessoa,
        codigo=f"BTC-{token}",
    )

    produto = _scalar(
        connection,
        """
        INSERT INTO public.produto_turistico (
            codigo,
            nome,
            tipo_produto,
            created_by
        )
        VALUES (
            :codigo,
            :nome,
            'CICLOTURISMO',
            'pytest-biketour'
        )
        RETURNING id_produto
        """,
        codigo=f"BTP-I-{token}",
        nome=f"Bike Tour Integridade {token}",
    )

    pacote = _scalar(
        connection,
        """
        INSERT INTO public.pacote_viagem (
            id_produto,
            codigo_pacote,
            created_by
        )
        VALUES (
            :produto,
            :codigo,
            'pytest-biketour'
        )
        RETURNING id_pacote
        """,
        produto=produto,
        codigo=f"BPK-{token}",
    )

    saida_1 = _scalar(
        connection,
        """
        INSERT INTO public.saida_turistica (
            id_pacote,
            codigo,
            data_inicio,
            data_fim,
            capacidade,
            status,
            created_by
        )
        VALUES (
            :pacote,
            :codigo,
            :inicio,
            :fim,
            10,
            'ABERTA',
            'pytest-biketour'
        )
        RETURNING id_saida
        """,
        pacote=pacote,
        codigo=f"BTS-I1-{token}",
        inicio=inicio.date(),
        fim=(inicio + timedelta(days=1)).date(),
    )

    saida_2 = _scalar(
        connection,
        """
        INSERT INTO public.saida_turistica (
            id_pacote,
            codigo,
            data_inicio,
            data_fim,
            capacidade,
            status,
            created_by
        )
        VALUES (
            :pacote,
            :codigo,
            :inicio,
            :fim,
            10,
            'ABERTA',
            'pytest-biketour'
        )
        RETURNING id_saida
        """,
        pacote=pacote,
        codigo=f"BTS-I2-{token}",
        inicio=inicio.date(),
        fim=(inicio + timedelta(days=1)).date(),
    )

    reserva = _scalar(
        connection,
        """
        INSERT INTO public.reserva (
            codigo_reserva,
            id_cliente,
            id_pacote,
            id_saida,
            data_reserva,
            quantidade_passageiros,
            status,
            created_by
        )
        VALUES (
            :codigo,
            :cliente,
            :pacote,
            :saida,
            CURRENT_DATE,
            2,
            'CONFIRMADA',
            'pytest-biketour'
        )
        RETURNING id_reserva
        """,
        codigo=f"BRV-{token}",
        cliente=cliente,
        pacote=pacote,
        saida=saida_1,
    )

    passageiro_1 = _scalar(
        connection,
        """
        INSERT INTO public.passageiro_reserva (
            id_reserva,
            ordem,
            status,
            created_by
        )
        VALUES (
            :reserva,
            1,
            'ATIVO',
            'pytest-biketour'
        )
        RETURNING id_passageiro
        """,
        reserva=reserva,
    )

    passageiro_2 = _scalar(
        connection,
        """
        INSERT INTO public.passageiro_reserva (
            id_reserva,
            ordem,
            status,
            created_by
        )
        VALUES (
            :reserva,
            2,
            'ATIVO',
            'pytest-biketour'
        )
        RETURNING id_passageiro
        """,
        reserva=reserva,
    )

    evento_1 = _scalar(
        connection,
        """
        INSERT INTO public.evento_bike_tour (
            id_saida,
            inicio,
            fim,
            capacidade,
            status,
            created_by
        )
        VALUES (
            :saida,
            :inicio,
            :fim,
            10,
            'ABERTO',
            'pytest-biketour'
        )
        RETURNING id_evento_bike_tour
        """,
        saida=saida_1,
        inicio=inicio,
        fim=fim,
    )

    evento_2 = _scalar(
        connection,
        """
        INSERT INTO public.evento_bike_tour (
            id_saida,
            inicio,
            fim,
            capacidade,
            status,
            created_by
        )
        VALUES (
            :saida,
            :inicio,
            :fim,
            10,
            'ABERTO',
            'pytest-biketour'
        )
        RETURNING id_evento_bike_tour
        """,
        saida=saida_2,
        inicio=inicio,
        fim=fim,
    )

    bicicleta_1 = _scalar(
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
            'pytest-biketour'
        )
        RETURNING id_recurso_bike_tour
        """,
        codigo=f"BTB-I1-{token}",
    )

    bicicleta_2 = _scalar(
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
            'pytest-biketour'
        )
        RETURNING id_recurso_bike_tour
        """,
        codigo=f"BTB-I2-{token}",
    )

    return {
        "inicio": inicio,
        "fim": fim,
        "reserva": reserva,
        "passageiro_1": passageiro_1,
        "passageiro_2": passageiro_2,
        "evento_1": evento_1,
        "evento_2": evento_2,
        "bicicleta_1": bicicleta_1,
        "bicicleta_2": bicicleta_2,
    }


def _create_inscricao(
    connection: Connection,
    *,
    evento: object,
    reserva: object,
    passageiro: object,
    status: str = "PENDENTE",
) -> object:
    return _scalar(
        connection,
        """
        INSERT INTO public.inscricao_bike_tour (
            id_evento_bike_tour,
            id_reserva,
            id_passageiro,
            papel,
            status,
            created_by
        )
        VALUES (
            :evento,
            :reserva,
            :passageiro,
            'CICLISTA',
            :status,
            'pytest-biketour'
        )
        RETURNING id_inscricao_bike_tour
        """,
        evento=evento,
        reserva=reserva,
        passageiro=passageiro,
        status=status,
    )


def _create_allocation(
    connection: Connection,
    *,
    evento: object,
    inscricao: object,
    recurso: object,
    inicio: object,
    fim: object,
    status: str,
) -> object:
    expira_em = datetime.now(UTC) + timedelta(minutes=15) if status == "BLOQUEADA" else None

    return _scalar(
        connection,
        """
        INSERT INTO public.alocacao_recurso_bike_tour (
            id_evento_bike_tour,
            id_inscricao_bike_tour,
            id_recurso_bike_tour,
            inicio,
            fim,
            expira_em,
            status,
            created_by
        )
        VALUES (
            :evento,
            :inscricao,
            :recurso,
            :inicio,
            :fim,
            :expira_em,
            :status,
            'pytest-biketour'
        )
        RETURNING id_alocacao_recurso_bike_tour
        """,
        evento=evento,
        inscricao=inscricao,
        recurso=recurso,
        inicio=inicio,
        fim=fim,
        expira_em=expira_em,
        status=status,
    )


def _assert_integrity_error(
    error: IntegrityError,
    expected_code: str,
) -> None:
    """Valida erro de integridade PostgreSQL do Bike Tour."""
    original = error.orig

    sqlstate = getattr(
        original,
        "sqlstate",
        None,
    )

    assert sqlstate == "23514"
    assert expected_code in str(original)


def _force_constraints(connection: Connection) -> None:
    connection.execute(text("SET CONSTRAINTS ALL IMMEDIATE"))


def test_c01_confirmada_temporariamente_sem_bicicleta_pode_ser_corrigida(
    biketour_engine: Engine,
) -> None:
    token = uuid4().hex[:12].upper()

    with biketour_engine.connect() as connection:
        transaction = connection.begin()

        try:
            fixture = _create_integrity_fixture(
                connection,
                token,
            )

            inscricao = _create_inscricao(
                connection,
                evento=fixture["evento_1"],
                reserva=fixture["reserva"],
                passageiro=fixture["passageiro_1"],
                status="CONFIRMADA",
            )

            _create_allocation(
                connection,
                evento=fixture["evento_1"],
                inscricao=inscricao,
                recurso=fixture["bicicleta_1"],
                inicio=fixture["inicio"],
                fim=fixture["fim"],
                status="CONFIRMADA",
            )

            _force_constraints(connection)

        finally:
            transaction.rollback()


def test_c02_confirmada_sem_bicicleta_e_rejeitada(
    biketour_engine: Engine,
) -> None:
    token = uuid4().hex[:12].upper()

    with biketour_engine.connect() as connection:
        transaction = connection.begin()

        try:
            fixture = _create_integrity_fixture(
                connection,
                token,
            )

            _create_inscricao(
                connection,
                evento=fixture["evento_1"],
                reserva=fixture["reserva"],
                passageiro=fixture["passageiro_1"],
                status="CONFIRMADA",
            )

            with pytest.raises(IntegrityError) as exc_info:
                _force_constraints(connection)

            _assert_integrity_error(
                exc_info.value,
                "BT_INTEGRITY_CONFIRMED_BICYCLE_COUNT",
            )

        finally:
            transaction.rollback()


def test_c03_confirmada_com_duas_bicicletas_e_rejeitada(
    biketour_engine: Engine,
) -> None:
    token = uuid4().hex[:12].upper()

    with biketour_engine.connect() as connection:
        transaction = connection.begin()

        try:
            fixture = _create_integrity_fixture(
                connection,
                token,
            )

            inscricao = _create_inscricao(
                connection,
                evento=fixture["evento_1"],
                reserva=fixture["reserva"],
                passageiro=fixture["passageiro_1"],
                status="CONFIRMADA",
            )

            for recurso in (
                fixture["bicicleta_1"],
                fixture["bicicleta_2"],
            ):
                _create_allocation(
                    connection,
                    evento=fixture["evento_1"],
                    inscricao=inscricao,
                    recurso=recurso,
                    inicio=fixture["inicio"],
                    fim=fixture["fim"],
                    status="CONFIRMADA",
                )

            with pytest.raises(IntegrityError) as exc_info:
                _force_constraints(connection)

            _assert_integrity_error(
                exc_info.value,
                "BT_INTEGRITY_CONFIRMED_BICYCLE_COUNT",
            )

        finally:
            transaction.rollback()


def test_c04_terminal_com_alocacao_ativa_e_rejeitada(
    biketour_engine: Engine,
) -> None:
    token = uuid4().hex[:12].upper()

    with biketour_engine.connect() as connection:
        transaction = connection.begin()

        try:
            fixture = _create_integrity_fixture(
                connection,
                token,
            )

            inscricao = _create_inscricao(
                connection,
                evento=fixture["evento_1"],
                reserva=fixture["reserva"],
                passageiro=fixture["passageiro_1"],
            )

            _create_allocation(
                connection,
                evento=fixture["evento_1"],
                inscricao=inscricao,
                recurso=fixture["bicicleta_1"],
                inicio=fixture["inicio"],
                fim=fixture["fim"],
                status="BLOQUEADA",
            )

            connection.execute(
                text(
                    """
                    UPDATE public.inscricao_bike_tour
                    SET
                        status = 'CANCELADA',
                        updated_by = 'pytest-biketour'
                    WHERE id_inscricao_bike_tour = :id
                    """
                ),
                {"id": inscricao},
            )

            with pytest.raises(IntegrityError) as exc_info:
                _force_constraints(connection)

            _assert_integrity_error(
                exc_info.value,
                "BT_INTEGRITY_TERMINAL_WITH_ACTIVE_ALLOCATION",
            )

        finally:
            transaction.rollback()


def test_c05_alocacao_em_evento_diferente_e_rejeitada(
    biketour_engine: Engine,
) -> None:
    token = uuid4().hex[:12].upper()

    with biketour_engine.connect() as connection:
        transaction = connection.begin()

        try:
            fixture = _create_integrity_fixture(
                connection,
                token,
            )

            inscricao = _create_inscricao(
                connection,
                evento=fixture["evento_1"],
                reserva=fixture["reserva"],
                passageiro=fixture["passageiro_1"],
            )

            _create_allocation(
                connection,
                evento=fixture["evento_2"],
                inscricao=inscricao,
                recurso=fixture["bicicleta_1"],
                inicio=fixture["inicio"],
                fim=fixture["fim"],
                status="BLOQUEADA",
            )

            with pytest.raises(IntegrityError) as exc_info:
                _force_constraints(connection)

            _assert_integrity_error(
                exc_info.value,
                "BT_INTEGRITY_ALLOCATION_EVENT_MISMATCH",
            )

        finally:
            transaction.rollback()


def test_c06_reassociacao_invalida_preserva_integridade_da_origem(
    biketour_engine: Engine,
) -> None:
    """Reassociar bicicleta nao pode invalidar inscricao origem."""
    token = uuid4().hex[:12].upper()

    with biketour_engine.connect() as connection:
        transaction = connection.begin()

        try:
            fixture = _create_integrity_fixture(
                connection,
                token,
            )

            inscricao_1 = _create_inscricao(
                connection,
                evento=fixture["evento_1"],
                reserva=fixture["reserva"],
                passageiro=fixture["passageiro_1"],
                status="CONFIRMADA",
            )

            inscricao_2 = _create_inscricao(
                connection,
                evento=fixture["evento_1"],
                reserva=fixture["reserva"],
                passageiro=fixture["passageiro_2"],
                status="PENDENTE",
            )

            alocacao = _create_allocation(
                connection,
                evento=fixture["evento_1"],
                inscricao=inscricao_1,
                recurso=fixture["bicicleta_1"],
                inicio=fixture["inicio"],
                fim=fixture["fim"],
                status="CONFIRMADA",
            )

            connection.execute(
                text(
                    """
                    UPDATE public.alocacao_recurso_bike_tour
                    SET
                        id_inscricao_bike_tour = :destino,
                        updated_by = 'pytest-biketour'
                    WHERE
                        id_alocacao_recurso_bike_tour = :id
                    """
                ),
                {
                    "destino": inscricao_2,
                    "id": alocacao,
                },
            )

            with pytest.raises(IntegrityError) as exc_info:
                _force_constraints(connection)

            _assert_integrity_error(
                exc_info.value,
                "BT_INTEGRITY_CONFIRMED_BICYCLE_COUNT",
            )

        finally:
            transaction.rollback()


def test_c07_mudar_tipo_da_bicicleta_confirmada_e_rejeitado(
    biketour_engine: Engine,
) -> None:
    """Recurso confirmado nao pode deixar de ser bicicleta."""
    token = uuid4().hex[:12].upper()

    with biketour_engine.connect() as connection:
        transaction = connection.begin()

        try:
            fixture = _create_integrity_fixture(
                connection,
                token,
            )

            inscricao = _create_inscricao(
                connection,
                evento=fixture["evento_1"],
                reserva=fixture["reserva"],
                passageiro=fixture["passageiro_1"],
                status="CONFIRMADA",
            )

            _create_allocation(
                connection,
                evento=fixture["evento_1"],
                inscricao=inscricao,
                recurso=fixture["bicicleta_1"],
                inicio=fixture["inicio"],
                fim=fixture["fim"],
                status="CONFIRMADA",
            )

            connection.execute(
                text(
                    """
                    UPDATE public.recurso_bike_tour
                    SET
                        tipo = 'EQUIPAMENTO',
                        updated_by = 'pytest-biketour'
                    WHERE
                        id_recurso_bike_tour = :id
                    """
                ),
                {
                    "id": fixture["bicicleta_1"],
                },
            )

            with pytest.raises(IntegrityError) as exc_info:
                _force_constraints(connection)

            _assert_integrity_error(
                exc_info.value,
                "BT_INTEGRITY_CONFIRMED_BICYCLE_COUNT",
            )

        finally:
            transaction.rollback()


def test_c08_soft_delete_da_bicicleta_confirmada_e_rejeitado(
    biketour_engine: Engine,
) -> None:
    """Soft delete nao pode remover bicicleta de confirmada."""
    token = uuid4().hex[:12].upper()

    with biketour_engine.connect() as connection:
        transaction = connection.begin()

        try:
            fixture = _create_integrity_fixture(
                connection,
                token,
            )

            inscricao = _create_inscricao(
                connection,
                evento=fixture["evento_1"],
                reserva=fixture["reserva"],
                passageiro=fixture["passageiro_1"],
                status="CONFIRMADA",
            )

            _create_allocation(
                connection,
                evento=fixture["evento_1"],
                inscricao=inscricao,
                recurso=fixture["bicicleta_1"],
                inicio=fixture["inicio"],
                fim=fixture["fim"],
                status="CONFIRMADA",
            )

            connection.execute(
                text(
                    """
                    UPDATE public.recurso_bike_tour
                    SET
                        deleted_at = CURRENT_TIMESTAMP,
                        deleted_by = 'pytest-biketour',
                        updated_by = 'pytest-biketour'
                    WHERE
                        id_recurso_bike_tour = :id
                    """
                ),
                {
                    "id": fixture["bicicleta_1"],
                },
            )

            with pytest.raises(IntegrityError) as exc_info:
                _force_constraints(connection)

            _assert_integrity_error(
                exc_info.value,
                "BT_INTEGRITY_CONFIRMED_BICYCLE_COUNT",
            )

        finally:
            transaction.rollback()


def test_c09_liberar_alocacao_antes_de_cancelar_preserva_historico(
    biketour_engine: Engine,
) -> None:
    """LIBERADA + CANCELADA e combinacao terminal valida."""
    token = uuid4().hex[:12].upper()

    with biketour_engine.connect() as connection:
        transaction = connection.begin()

        try:
            fixture = _create_integrity_fixture(
                connection,
                token,
            )

            inscricao = _create_inscricao(
                connection,
                evento=fixture["evento_1"],
                reserva=fixture["reserva"],
                passageiro=fixture["passageiro_1"],
                status="CONFIRMADA",
            )

            alocacao = _create_allocation(
                connection,
                evento=fixture["evento_1"],
                inscricao=inscricao,
                recurso=fixture["bicicleta_1"],
                inicio=fixture["inicio"],
                fim=fixture["fim"],
                status="CONFIRMADA",
            )

            connection.execute(
                text(
                    """
                    UPDATE public.alocacao_recurso_bike_tour
                    SET
                        status = 'LIBERADA',
                        expira_em = NULL,
                        updated_by = 'pytest-biketour'
                    WHERE
                        id_alocacao_recurso_bike_tour = :id
                    """
                ),
                {
                    "id": alocacao,
                },
            )

            connection.execute(
                text(
                    """
                    UPDATE public.inscricao_bike_tour
                    SET
                        status = 'CANCELADA',
                        updated_by = 'pytest-biketour'
                    WHERE
                        id_inscricao_bike_tour = :id
                    """
                ),
                {
                    "id": inscricao,
                },
            )

            _force_constraints(connection)

            result = connection.execute(
                text(
                    """
                    SELECT
                        i.status AS inscricao_status,
                        a.status AS alocacao_status,
                        a.id_inscricao_bike_tour,
                        a.id_recurso_bike_tour
                    FROM public.inscricao_bike_tour AS i
                    JOIN public.alocacao_recurso_bike_tour AS a
                      ON a.id_inscricao_bike_tour =
                         i.id_inscricao_bike_tour
                    WHERE
                        i.id_inscricao_bike_tour = :id
                    """
                ),
                {
                    "id": inscricao,
                },
            ).one()

            assert result.inscricao_status == "CANCELADA"
            assert result.alocacao_status == "LIBERADA"
            assert result.id_inscricao_bike_tour == inscricao
            assert result.id_recurso_bike_tour == fixture["bicicleta_1"]

        finally:
            transaction.rollback()
