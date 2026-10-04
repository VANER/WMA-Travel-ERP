"""PostgreSQL real regression for Bike Tour resource hardening 130600."""

from collections.abc import Generator
from uuid import uuid4

import pytest
from sqlalchemy import Connection, create_engine, text
from sqlalchemy.exc import IntegrityError

pytestmark = pytest.mark.postgresql

EXPECTED_REVISION = "202609170300"
LEGACY_ORIGIN_CONSTRAINT = "ck_recurso_bike_tour_ck_recurso_bike_tour_origem_unica"


def _fixture_counts(conn: Connection) -> dict[str, int]:
    counts = {
        table: int(
            conn.execute(
                text(f"SELECT count(*) FROM public.{table} WHERE created_by = 'pytest-bt600'")
            ).scalar_one()
        )
        for table in (
            "recurso_bike_tour",
            "guia_turistico",
            "transporte",
            "ativo_imobilizado",
            "categoria_ativo",
        )
    }
    counts["log_auditoria"] = int(
        conn.execute(
            text(
                "SELECT count(*) FROM public.log_auditoria "
                "WHERE dados_novos->>'created_by' = 'pytest-bt600' "
                "OR dados_antigos->>'created_by' = 'pytest-bt600'"
            )
        ).scalar_one()
    )
    return counts


@pytest.fixture
def connection(postgresql_test_url: str) -> Generator[Connection]:
    engine = create_engine(
        postgresql_test_url,
        isolation_level="READ COMMITTED",
    )

    try:
        with engine.connect() as conn:
            # Encerra a transacao de diagnostico antes de iniciar a fixture.
            with conn.begin():
                assert str(conn.scalar(text("SELECT current_database()"))).endswith("_test")
                assert (
                    conn.scalar(text("SELECT version_num FROM alembic_version"))
                    == EXPECTED_REVISION
                )
                assert conn.scalar(text("SHOW transaction_isolation")) == "read committed"
                before = _fixture_counts(conn)

            transaction = conn.begin()
            try:
                conn.execute(text("SET LOCAL lock_timeout = '5s'"))
                conn.execute(text("SELECT pg_advisory_xact_lock(2700, 1)"))
                yield conn
            finally:
                transaction.rollback()
                assert _fixture_counts(conn) == before
    finally:
        engine.dispose()


def _code(prefix: str) -> str:
    return f"{prefix}-{uuid4().hex[:12].upper()}"


def _sqlstate(error: IntegrityError) -> str | None:
    return getattr(error.orig, "sqlstate", None)


def _constraint(error: IntegrityError) -> str | None:
    return getattr(
        getattr(error.orig, "diag", None),
        "constraint_name",
        None,
    )


def _guide(conn: Connection) -> int:
    value = conn.scalar(
        text(
            """
            INSERT INTO public.guia_turistico (
                nome,
                created_by
            )
            VALUES (
                :nome,
                'pytest-bt600'
            )
            RETURNING id_guia
            """
        ),
        {"nome": _code("Guia-BT600")},
    )
    assert value is not None
    return int(value)


def _transport(conn: Connection) -> int:
    value = conn.scalar(
        text(
            """
            INSERT INTO public.transporte (
                tipo_transporte,
                created_by
            )
            VALUES (
                'APOIO',
                'pytest-bt600'
            )
            RETURNING id_transporte
            """
        )
    )
    assert value is not None
    return int(value)


def _asset(conn: Connection) -> int:
    """Cria patrimonio sintetico conforme schema real, na transacao da fixture."""
    category = conn.execute(
        text(
            "INSERT INTO public.categoria_ativo (codigo, descricao, created_by) "
            "VALUES (:code, 'Categoria sintetica Bike Tour', 'pytest-bt600') "
            "RETURNING id_categoria_ativo"
        ),
        {"code": _code("CAT-BT600")},
    ).scalar_one()
    value = conn.scalar(
        text(
            """
            INSERT INTO public.ativo_imobilizado (
                codigo_patrimonio, id_categoria_ativo, descricao, created_by
            ) VALUES (
                :code, :category, 'Patrimonio sintetico Bike Tour', 'pytest-bt600'
            ) RETURNING id_ativo
            """
        ),
        {"code": _code("AT-BT600"), "category": category},
    )
    assert value is not None
    return int(value)


def _insert_resource(
    conn: Connection,
    *,
    tipo: str,
    id_ativo: int | None = None,
    id_guia: int | None = None,
    id_transporte: int | None = None,
) -> int:
    value = conn.scalar(
        text(
            """
            INSERT INTO public.recurso_bike_tour (
                codigo,
                tipo,
                id_ativo,
                id_guia,
                id_transporte,
                created_by
            )
            VALUES (
                :codigo,
                :tipo,
                :id_ativo,
                :id_guia,
                :id_transporte,
                'pytest-bt600'
            )
            RETURNING id_recurso_bike_tour
            """
        ),
        {
            "codigo": _code("BT600"),
            "tipo": tipo,
            "id_ativo": id_ativo,
            "id_guia": id_guia,
            "id_transporte": id_transporte,
        },
    )

    assert value is not None
    return int(value)


def test_p01_bicicleta_sem_patrimonio_e_aceita(
    connection: Connection,
) -> None:
    _insert_resource(connection, tipo="BICICLETA")


def test_p02_equipamento_sem_patrimonio_e_aceito(
    connection: Connection,
) -> None:
    _insert_resource(connection, tipo="EQUIPAMENTO")


@pytest.mark.parametrize("tipo", ["BICICLETA", "EQUIPAMENTO"])
def test_p03_p04_patrimonio_opcional_e_aceito_quando_valido(
    connection: Connection,
    tipo: str,
) -> None:
    asset = _asset(connection)

    _insert_resource(
        connection,
        tipo=tipo,
        id_ativo=asset,
    )


def test_p05_guia_com_origem_valida_e_aceito(
    connection: Connection,
) -> None:
    guide = _guide(connection)

    _insert_resource(
        connection,
        tipo="GUIA",
        id_guia=guide,
    )


def test_p06_guia_sem_id_guia_rejeitado_23514(
    connection: Connection,
) -> None:
    with (
        pytest.raises(IntegrityError) as exc_info,
        connection.begin_nested(),
    ):
        _insert_resource(connection, tipo="GUIA")

    assert _sqlstate(exc_info.value) == "23514"
    assert _constraint(exc_info.value) == "ck_recurso_bike_tour_origem_compativel_tipo"


def test_p07_guia_com_id_ativo_rejeitado_23514(
    connection: Connection,
) -> None:
    asset = _asset(connection)

    with (
        pytest.raises(IntegrityError) as exc_info,
        connection.begin_nested(),
    ):
        _insert_resource(
            connection,
            tipo="GUIA",
            id_ativo=asset,
        )

    assert _sqlstate(exc_info.value) == "23514"
    assert _constraint(exc_info.value) == "ck_recurso_bike_tour_origem_compativel_tipo"


def test_p08_veiculo_com_origem_valida_e_aceito(
    connection: Connection,
) -> None:
    transport = _transport(connection)

    _insert_resource(
        connection,
        tipo="VEICULO",
        id_transporte=transport,
    )


def test_p09_veiculo_sem_transporte_rejeitado_23514(
    connection: Connection,
) -> None:
    with (
        pytest.raises(IntegrityError) as exc_info,
        connection.begin_nested(),
    ):
        _insert_resource(connection, tipo="VEICULO")

    assert _sqlstate(exc_info.value) == "23514"
    assert _constraint(exc_info.value) == "ck_recurso_bike_tour_origem_compativel_tipo"


def test_p10_veiculo_com_guia_rejeitado_23514(
    connection: Connection,
) -> None:
    guide = _guide(connection)

    with (
        pytest.raises(IntegrityError) as exc_info,
        connection.begin_nested(),
    ):
        _insert_resource(
            connection,
            tipo="VEICULO",
            id_guia=guide,
        )

    assert _sqlstate(exc_info.value) == "23514"
    assert _constraint(exc_info.value) == "ck_recurso_bike_tour_origem_compativel_tipo"


def test_p11_id_ativo_duplicado_rejeitado_23505(
    connection: Connection,
) -> None:
    asset = _asset(connection)

    _insert_resource(
        connection,
        tipo="BICICLETA",
        id_ativo=asset,
    )

    with (
        pytest.raises(IntegrityError) as exc_info,
        connection.begin_nested(),
    ):
        _insert_resource(
            connection,
            tipo="EQUIPAMENTO",
            id_ativo=asset,
        )

    assert _sqlstate(exc_info.value) == "23505"
    assert _constraint(exc_info.value) == "uq_recurso_bike_tour_id_ativo"


def test_p12_id_guia_duplicado_rejeitado_23505(
    connection: Connection,
) -> None:
    guide = _guide(connection)

    _insert_resource(
        connection,
        tipo="GUIA",
        id_guia=guide,
    )

    with (
        pytest.raises(IntegrityError) as exc_info,
        connection.begin_nested(),
    ):
        _insert_resource(
            connection,
            tipo="GUIA",
            id_guia=guide,
        )

    assert _sqlstate(exc_info.value) == "23505"
    assert _constraint(exc_info.value) == "uq_recurso_bike_tour_id_guia"


def test_p13_id_transporte_duplicado_rejeitado_23505(
    connection: Connection,
) -> None:
    transport = _transport(connection)

    _insert_resource(
        connection,
        tipo="VEICULO",
        id_transporte=transport,
    )

    with (
        pytest.raises(IntegrityError) as exc_info,
        connection.begin_nested(),
    ):
        _insert_resource(
            connection,
            tipo="VEICULO",
            id_transporte=transport,
        )

    assert _sqlstate(exc_info.value) == "23505"
    assert _constraint(exc_info.value) == "uq_recurso_bike_tour_id_transporte"


def test_p14_multiplos_null_sao_permitidos(
    connection: Connection,
) -> None:
    _insert_resource(connection, tipo="BICICLETA")
    _insert_resource(connection, tipo="BICICLETA")
    _insert_resource(connection, tipo="EQUIPAMENTO")
    _insert_resource(connection, tipo="EQUIPAMENTO")


def test_p15_origem_unica_anterior_permanece_ativa(
    connection: Connection,
) -> None:
    guide = _guide(connection)
    transport = _transport(connection)

    with (
        pytest.raises(IntegrityError) as exc_info,
        connection.begin_nested(),
    ):
        _insert_resource(
            connection,
            tipo="GUIA",
            id_guia=guide,
            id_transporte=transport,
        )

    assert _sqlstate(exc_info.value) == "23514"

    assert _constraint(exc_info.value) in {
        LEGACY_ORIGIN_CONSTRAINT,
        "ck_recurso_bike_tour_origem_compativel_tipo",
    }
    # A rejeicao isolada poderia vir somente da CHECK nova. Confirma tambem
    # existencia, validacao e expressao da constraint historica preservada.
    legacy = connection.execute(
        text(
            "SELECT convalidated, pg_get_constraintdef(oid) FROM pg_constraint "
            "WHERE conrelid = 'public.recurso_bike_tour'::regclass AND conname = :name"
        ),
        {"name": LEGACY_ORIGIN_CONSTRAINT},
    ).one()
    assert legacy[0] is True
    assert all(column in legacy[1] for column in ("id_ativo", "id_guia", "id_transporte"))
    assert "<= 1" in legacy[1]


def test_catalogo_130600_contem_hardening(
    connection: Connection,
) -> None:
    names = set(
        connection.scalars(
            text(
                """
                SELECT conname
                FROM pg_constraint
                WHERE conrelid =
                    'public.recurso_bike_tour'::regclass
                """
            )
        )
    )

    assert {
        "uq_recurso_bike_tour_id_ativo",
        "uq_recurso_bike_tour_id_guia",
        "uq_recurso_bike_tour_id_transporte",
        "ck_recurso_bike_tour_origem_compativel_tipo",
        LEGACY_ORIGIN_CONSTRAINT,
    } <= names
