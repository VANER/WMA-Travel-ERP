"""Integridade fisica de operacao/pendencia com PostgreSQL e rollback integral."""

import importlib.util
from collections.abc import Generator
from datetime import UTC, datetime, timedelta
from importlib import import_module
from pathlib import Path
from typing import Any
from uuid import uuid4

import pytest
from alembic.migration import MigrationContext
from alembic.operations import Operations
from sqlalchemy import Connection, MetaData, Table, create_engine, inspect, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db.base import Base
from app.modules.biketour.models import OperacaoBikeTour, PendenciaBikeTour, RecursoBikeTour
from app.shared.turismo import (
    obter_bloqueio_turistico,
    obter_catalogo_saida,
    obter_contexto_inscricao,
    obter_origem_comercial_reserva,
    obter_situacao_recurso_origem,
)

pytestmark = pytest.mark.postgresql
TABLES = ("operacao_bike_tour", "pendencia_bike_tour")


@pytest.mark.parametrize("lock", [False, True])
def test_portas_operacionais_com_schema_real_e_rollback(connection: Connection, lock: bool) -> None:
    baseline = import_module("tests.integration.test_biketour_postgresql")
    hardening = import_module("tests.integration.test_biketour_resource_hardening_postgresql")
    origin = baseline._create_integrity_fixture(connection, uuid4().hex[:12].upper())
    departure = connection.execute(
        text("SELECT id_saida FROM reserva WHERE id_reserva=:id"), {"id": origin["reserva"]}
    ).scalar_one()
    expiry = datetime.now(UTC).replace(microsecond=0) + timedelta(minutes=10)
    connection.execute(
        text(
            "INSERT INTO alocacao_vaga(id_saida,id_reserva,chave_idempotencia,quantidade,"
            "status,expira_em,created_by) VALUES (:saida,:reserva,:chave,2,'BLOQUEADA',"
            ":expira,'pytest-bt700')"
        ),
        {
            "saida": departure,
            "reserva": origin["reserva"],
            "chave": uuid4().hex,
            "expira": expiry.replace(tzinfo=None),
        },
    )
    guide = hardening._guide(connection)
    transport = hardening._transport(connection)
    asset = hardening._asset(connection)
    connection.execute(
        text("UPDATE ativo_imobilizado SET status='ATIVO' WHERE id_ativo=:id"), {"id": asset}
    )
    with Session(bind=connection, join_transaction_mode="create_savepoint") as session:
        context = obter_contexto_inscricao(
            session, departure, origin["reserva"], origin["passageiro_1"], bloquear=lock
        )
        assert context is not None and context.reserva.status == "CONFIRMADA"
        catalog = obter_catalogo_saida(session, context.saida, bloquear=lock)
        assert catalog is not None and catalog.elegivel and catalog.produto.tipo == "CICLOTURISMO"
        block = obter_bloqueio_turistico(session, origin["reserva"], bloquear=lock)
        assert block is not None and block.expira_em == expiry
        assert obter_origem_comercial_reserva(session, origin["reserva"], bloquear=lock).valida
        assert obter_situacao_recurso_origem(session, "GUIA", guide, bloquear=lock).permitido
        assert obter_situacao_recurso_origem(session, "VEICULO", transport, bloquear=lock).permitido
        assert obter_situacao_recurso_origem(session, "BICICLETA", asset, bloquear=lock).permitido


def test_recurso_orm_resolve_alvos_legados_sem_criar_tabelas(connection: Connection) -> None:
    with Session(bind=connection, join_transaction_mode="create_savepoint") as session:
        recurso = RecursoBikeTour(
            codigo=f"BT-ORM-{uuid4().hex[:12]}",
            tipo="BICICLETA",
            status="DISPONIVEL",
            created_by="pytest-bt700",
        )
        session.add(recurso)
        session.flush()
        session.refresh(recurso)
        assert recurso.id_recurso_bike_tour > 0
        assert recurso.versao == 1
        assert recurso.created_at.tzinfo is not None


def _counts(conn: Connection) -> dict[str, int]:
    names = conn.scalars(
        text("SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename")
    ).all()
    quote = conn.dialect.identifier_preparer.quote
    return {
        name: int(conn.execute(text(f"SELECT count(*) FROM public.{quote(name)}")).scalar_one())
        for name in names
    }


@pytest.fixture
def connection(postgresql_test_url: str) -> Generator[Connection]:
    engine = create_engine(postgresql_test_url, isolation_level="READ COMMITTED")
    try:
        with engine.connect() as conn:
            with conn.begin():
                assert str(conn.scalar(text("SELECT current_database()"))).endswith("_test")
                assert (
                    conn.scalar(text("SELECT version_num FROM alembic_version")) == "202609170300"
                )
                before = _counts(conn)
            transaction = conn.begin()
            try:
                conn.execute(text("SET LOCAL lock_timeout='5s'"))
                conn.execute(text("SELECT pg_advisory_xact_lock(2700,1)"))
                yield conn
            finally:
                transaction.rollback()
                assert _counts(conn) == before
    finally:
        engine.dispose()


def _insert(conn: Connection, table_name: str, values: dict[str, Any]) -> int:
    table = Table(table_name, MetaData(), schema="public", autoload_with=conn, resolve_fks=False)
    return int(
        conn.execute(
            table.insert().values(**values).returning(table.c[f"id_{table_name}"])
        ).scalar_one()
    )


@pytest.fixture
def rows(connection: Connection) -> dict[str, dict[str, Any]]:
    baseline = import_module("tests.integration.test_biketour_postgresql")
    token = uuid4().hex[:12].upper()
    origin = baseline._create_integrity_fixture(connection, token)
    inscription = baseline._create_inscricao(
        connection,
        evento=origin["evento_1"],
        reserva=origin["reserva"],
        passageiro=origin["passageiro_1"],
        status="CONCLUIDA",
    )
    actor = int(
        connection.execute(
            text(
                "INSERT INTO public.usuario(nome,email,created_by) "
                "VALUES ('Teste Bike Tour',:email,'pytest-bt700') RETURNING id_usuario"
            ),
            {"email": f"bt700-{token}@example.invalid"},
        ).scalar_one()
    )
    operation = {
        "id_usuario": actor,
        "operacao": "acao_inscricao",
        "alvo": inscription,
        "chave_hash": "a" * 64,
        "payload_hash": "b" * 64,
        "http_status": 200,
        "resultado": {"id": inscription, "status": "CONCLUIDA"},
        "correlation_id": uuid4(),
        "created_by": "pytest-bt700",
    }
    identifier = _insert(connection, TABLES[0], operation)
    pending = {
        "id_evento_bike_tour": origin["evento_1"],
        "id_inscricao_bike_tour": inscription,
        "id_operacao_bike_tour": identifier,
        "tipo": "ENCERRAMENTO",
        "motivo": "OPERACIONAL",
        "status": "ABERTA",
        "created_by": "pytest-bt700",
    }
    return {TABLES[0]: operation, TABLES[1]: pending}


@pytest.mark.parametrize("model", [OperacaoBikeTour, PendenciaBikeTour])
def test_catalogo_exato(connection: Connection, model: type[Base]) -> None:
    table = model.__table__
    assert isinstance(table, Table)
    inspector = inspect(connection)
    columns = inspector.get_columns(table.name, schema="public")
    assert {c["name"] for c in columns} == set(table.c.keys())
    for column in columns:
        assert column["nullable"] == table.c[column["name"]].nullable
        assert column["comment"]
        assert str(column["type"].compile(dialect=connection.dialect)) == str(
            table.c[column["name"]].type.compile(dialect=connection.dialect)
        )
    assert inspector.get_pk_constraint(table.name, schema="public")["constrained_columns"] == [
        f"id_{table.name}"
    ]
    assert {f["name"] for f in inspector.get_foreign_keys(table.name, schema="public")} == {
        f.name for f in table.foreign_key_constraints
    }
    checks = inspector.get_check_constraints(table.name, schema="public")
    assert all(str(c["name"]).count("ck_") == 1 for c in checks)
    triggers = connection.scalars(
        text(
            "SELECT tgname FROM pg_trigger WHERE tgrelid=to_regclass(:table) "
            "AND NOT tgisinternal AND tgenabled='O'"
        ),
        {"table": f"public.{table.name}"},
    ).all()
    assert set(triggers) == {f"trg_{table.name}_updated_at", f"trg_{table.name}_auditoria"}


@pytest.mark.parametrize(
    ("table", "change"),
    [
        (TABLES[0], {"chave_hash": "not-a-hash"}),
        (TABLES[0], {"payload_hash": "A" * 64}),
        (TABLES[0], {"alvo": -1}),
        (TABLES[0], {"operacao": ""}),
        (TABLES[0], {"http_status": 500}),
        (TABLES[0], {"resultado": "free text"}),
        (TABLES[0], {"resultado": None}),
        (TABLES[0], {"versao": 0}),
        (TABLES[1], {"tipo": "FINANCEIRO"}),
        (TABLES[1], {"status": "PAGA"}),
        (TABLES[1], {"motivo": "texto livre"}),
        (TABLES[1], {"status": "TRATADA"}),
        (TABLES[1], {"status": "TRATADA", "referencia_tratamento": " "}),
        (TABLES[1], {"referencia_tratamento": "TICKET-1"}),
        (TABLES[1], {"versao": 0}),
    ],
)
def test_checks_sqlstate_23514(
    connection: Connection, rows: dict[str, dict[str, Any]], table: str, change: dict[str, Any]
) -> None:
    values = dict(rows[table])
    if table == TABLES[0]:
        values["chave_hash"] = "c" * 64
    values.update(change)
    with pytest.raises(IntegrityError) as error, connection.begin_nested():
        _insert(connection, table, values)
    assert getattr(error.value.orig, "sqlstate", None) == "23514"


@pytest.mark.parametrize(
    ("table", "column"),
    [
        (TABLES[0], "id_usuario"),
        (TABLES[1], "id_evento_bike_tour"),
        (TABLES[1], "id_inscricao_bike_tour"),
        (TABLES[1], "id_operacao_bike_tour"),
    ],
)
def test_fks_reais_23503(
    connection: Connection, rows: dict[str, dict[str, Any]], table: str, column: str
) -> None:
    values = dict(rows[table])
    values[column] = -1
    with pytest.raises(IntegrityError) as error, connection.begin_nested():
        _insert(connection, table, values)
    assert getattr(error.value.orig, "sqlstate", None) == "23503"


@pytest.mark.parametrize(
    ("table", "column"),
    [
        (TABLES[0], "id_usuario"),
        (TABLES[0], "chave_hash"),
        (TABLES[0], "correlation_id"),
        (TABLES[1], "id_evento_bike_tour"),
        (TABLES[1], "id_operacao_bike_tour"),
        (TABLES[1], "motivo"),
    ],
)
def test_not_null_23502(
    connection: Connection, rows: dict[str, dict[str, Any]], table: str, column: str
) -> None:
    values = dict(rows[table])
    values[column] = None
    with pytest.raises(IntegrityError) as error, connection.begin_nested():
        _insert(connection, table, values)
    assert getattr(error.value.orig, "sqlstate", None) == "23502"


def test_intencao_historica_nao_reutiliza_chave(
    connection: Connection, rows: dict[str, dict[str, Any]]
) -> None:
    connection.execute(
        text(
            "UPDATE public.operacao_bike_tour SET deleted_at=CURRENT_TIMESTAMP "
            "WHERE created_by='pytest-bt700'"
        )
    )
    with pytest.raises(IntegrityError) as error, connection.begin_nested():
        _insert(connection, TABLES[0], rows[TABLES[0]])
    assert getattr(error.value.orig, "sqlstate", None) == "23505"
    for change in ({"chave_hash": "d" * 64}, {"alvo": 0}, {"operacao": "cancelar_evento"}):
        assert _insert(connection, TABLES[0], rows[TABLES[0]] | change) > 0


@pytest.mark.parametrize("sem_inscricao", [False, True])
def test_pendencia_unica_com_ou_sem_inscricao(
    connection: Connection, rows: dict[str, dict[str, Any]], sem_inscricao: bool
) -> None:
    values = dict(rows[TABLES[1]])
    if sem_inscricao:
        values["id_inscricao_bike_tour"] = None
    identifier = _insert(connection, TABLES[1], values)
    connection.execute(
        text(
            "UPDATE public.pendencia_bike_tour SET deleted_at=CURRENT_TIMESTAMP "
            "WHERE id_pendencia_bike_tour=:id"
        ),
        {"id": identifier},
    )
    with pytest.raises(IntegrityError) as error, connection.begin_nested():
        _insert(connection, TABLES[1], values)
    assert getattr(error.value.orig, "sqlstate", None) == "23505"
    assert _insert(connection, TABLES[1], values | {"tipo": "CANCELAMENTO"}) > 0


def test_tratamento_auditoria_e_versao(
    connection: Connection, rows: dict[str, dict[str, Any]]
) -> None:
    identifier = _insert(connection, TABLES[1], rows[TABLES[1]])
    row = connection.execute(
        text(
            "UPDATE public.pendencia_bike_tour SET status='TRATADA', "
            "referencia_tratamento='TICKET-1', updated_by='pytest-bt700' "
            "WHERE id_pendencia_bike_tour=:id RETURNING versao,updated_at"
        ),
        {"id": identifier},
    ).one()
    assert row.versao == 2 and row.updated_at.tzinfo is not None
    operation_id = rows[TABLES[1]]["id_operacao_bike_tour"]
    operation = connection.execute(
        text(
            "UPDATE public.operacao_bike_tour SET deleted_at=CURRENT_TIMESTAMP "
            "WHERE id_operacao_bike_tour=:id RETURNING versao,resultado"
        ),
        {"id": operation_id},
    ).one()
    assert operation.versao == 2
    assert operation.resultado == rows[TABLES[0]]["resultado"]
    for table, pk in ((TABLES[0], operation_id), (TABLES[1], identifier)):
        audit = connection.execute(
            text(
                "SELECT acao,dados_novos FROM public.log_auditoria "
                "WHERE tabela_nome=:table AND registro_id=:id"
            ),
            {"table": f"public.{table}", "id": pk},
        ).all()
        assert {record.acao for record in audit} == {"INSERT", "UPDATE"}
        assert {record.dados_novos["versao"] for record in audit} == {1, 2}


def test_downgrade_reupgrade_preserva_catalogo(connection: Connection) -> None:
    previous = import_module("tests.integration.test_biketour_operations_postgresql")
    before = previous._catalog(connection)
    counts = _counts(connection)
    path = Path(__file__).parents[2] / "migrations/versions/202609130700_bike_tour_idempotency.py"
    spec = importlib.util.spec_from_file_location("bt700_physical", path)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    context = MigrationContext.configure(connection, opts={"target_metadata": Base.metadata})
    with Operations.context(context):
        module.downgrade()
    assert not set(TABLES).intersection(inspect(connection).get_table_names(schema="public"))
    assert _counts(connection) == {k: v for k, v in counts.items() if k not in TABLES}
    with Operations.context(context):
        module.upgrade()
    assert previous._catalog(connection) == before
    after = _counts(connection)
    assert after == {table: 0 if table in TABLES else count for table, count in counts.items()}
