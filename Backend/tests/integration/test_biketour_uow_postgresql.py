"""Commit, rollback, replay e contencao reais em conexoes PostgreSQL independentes."""

from collections.abc import Callable, Generator
from concurrent.futures import ThreadPoolExecutor
from threading import Event
from time import monotonic, sleep
from uuid import uuid4

import pytest
from sqlalchemy import Connection, Engine, create_engine, text
from sqlalchemy.orm import Session

from app.db import models as registered_models  # noqa: F401
from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import RecursoBikeTour
from app.modules.biketour.uow import BikeTourUnitOfWork, ContextoComando, ResultadoComando
from app.modules.seguranca.rbac import ContextoRbac

pytestmark = pytest.mark.postgresql


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
def committed_database(postgresql_test_url: str) -> Generator[tuple[Engine, ContextoRbac]]:
    """Limpa somente IDs sinteticos deste teste, incluindo sua auditoria, e compara contagens."""
    engine = create_engine(postgresql_test_url)
    with engine.begin() as conn:
        assert str(conn.scalar(text("SELECT current_database()"))).endswith("_test")
        assert conn.scalar(text("SELECT version_num FROM alembic_version")) == "202609170300"
        before = _counts(conn)
        actor_id = int(
            conn.execute(
                text(
                    "INSERT INTO public.usuario(nome,email,created_by) "
                    "VALUES ('Teste UoW',:email,'pytest-bt-uow') RETURNING id_usuario"
                ),
                {"email": f"bt-uow-{uuid4().hex}@example.invalid"},
            ).scalar_one()
        )
    try:
        yield (
            engine,
            ContextoRbac(actor_id, (), frozenset({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_OPERAR"})),
        )
    finally:
        try:
            with engine.begin() as conn:
                assert str(conn.scalar(text("SELECT current_database()"))).endswith("_test")
                conn.execute(text("SET LOCAL lock_timeout='5s'"))
                conn.execute(text("SELECT pg_advisory_xact_lock(2700,1)"))
                for table, predicate, value in (
                    ("operacao_bike_tour", "id_usuario", actor_id),
                    ("recurso_bike_tour", "created_by", str(actor_id)),
                    ("usuario", "id_usuario", actor_id),
                ):
                    identifiers = list(
                        conn.scalars(
                            text(
                                f"DELETE FROM public.{table} WHERE {predicate}=:id "
                                f"RETURNING id_{table}"
                            ),
                            {"id": value},
                        )
                    )
                    if identifiers:
                        conn.execute(
                            text(
                                "DELETE FROM public.log_auditoria "
                                "WHERE tabela_nome=:table AND registro_id = ANY(:ids)"
                            ),
                            {"table": f"public.{table}", "ids": identifiers},
                        )
                assert _counts(conn) == before
        finally:
            engine.dispose()


def _create(context: ContextoComando) -> ResultadoComando:
    assert context.session.scalar(text("SHOW transaction_isolation")) == "read committed"
    assert context.session.scalar(text("SHOW lock_timeout")) == "5s"
    resource = RecursoBikeTour(
        codigo=f"BT-UOW-{uuid4().hex[:12]}",
        tipo="BICICLETA",
        status="DISPONIVEL",
        created_by=str(context.ator.id_usuario),
    )
    context.session.add(resource)
    context.session.flush()
    return ResultadoComando(201, {"id": resource.id_recurso_bike_tour, "status": resource.status})


def _execute(
    database: tuple[Engine, ContextoRbac],
    *,
    handler: Callable[[ContextoComando], ResultadoComando] = _create,
    payload: dict[str, object] | None = None,
) -> ResultadoComando:
    engine, actor = database
    with Session(engine) as session:
        return BikeTourUnitOfWork(session).executar(
            ator=actor,
            permissao="BIKE_TOUR_OPERAR",
            correlation_id=uuid4(),
            operacao="criar_recurso",
            alvo=0,
            chave="chave-opaca",
            payload=payload or {"tipo": "BICICLETA"},
            comando=handler,
        )


def test_commit_replay_tombstone_payload_e_revogacao(
    committed_database: tuple[Engine, ContextoRbac],
) -> None:
    engine, actor = committed_database
    first = _execute(committed_database)
    assert _execute(committed_database) == first
    with engine.begin() as conn:
        assert str(conn.scalar(text("SELECT current_database()"))).endswith("_test")
        conn.execute(
            text("UPDATE recurso_bike_tour SET status='INATIVO' WHERE created_by=:actor"),
            {"actor": str(actor.id_usuario)},
        )
        conn.execute(
            text(
                "UPDATE operacao_bike_tour SET deleted_at=CURRENT_TIMESTAMP WHERE id_usuario=:actor"
            ),
            {"actor": actor.id_usuario},
        )
    assert _execute(committed_database) == first
    with pytest.raises(BikeTourError) as error:
        _execute(committed_database, payload={"tipo": "GUIA"})
    assert error.value.status_code == 409
    with pytest.raises(BikeTourError) as error:
        _execute((engine, ContextoRbac(actor.id_usuario, ("ADMIN",), frozenset())))
    assert error.value.status_code == 403
    with engine.connect() as conn:
        assert (
            conn.scalar(
                text("SELECT count(*) FROM operacao_bike_tour WHERE id_usuario=:actor"),
                {"actor": actor.id_usuario},
            )
            == 1
        )
        assert (
            conn.scalar(
                text("SELECT status FROM recurso_bike_tour WHERE created_by=:actor"),
                {"actor": str(actor.id_usuario)},
            )
            == "INATIVO"
        )


def test_erro_apos_flush_reverte_estado_auditoria_e_chave(
    committed_database: tuple[Engine, ContextoRbac],
) -> None:
    engine, _ = committed_database
    with engine.connect() as conn:
        before = _counts(conn)

    def failing(context: ContextoComando) -> ResultadoComando:
        _create(context)
        raise RuntimeError("falha injetada apos escrita")

    with pytest.raises(RuntimeError, match="falha injetada"):
        _execute(committed_database, handler=failing)
    with engine.connect() as conn:
        assert _counts(conn) == before
    assert _execute(committed_database).status == 201


def test_repeticao_concorrente_aguarda_commit_e_retorna_resultado_original(
    committed_database: tuple[Engine, ContextoRbac],
) -> None:
    entered = Event()
    release = Event()
    second_started = Event()
    invocations: list[int] = []

    def held(context: ContextoComando) -> ResultadoComando:
        invocations.append(1)
        entered.set()
        assert release.wait(timeout=10)
        return _create(context)

    def second() -> ResultadoComando:
        second_started.set()
        return _execute(committed_database, handler=held)

    with ThreadPoolExecutor(max_workers=2) as pool:
        first = pool.submit(_execute, committed_database, handler=held)
        try:
            assert entered.wait(timeout=10)
            replay = pool.submit(second)
            assert second_started.wait(timeout=10)
            engine, _ = committed_database
            with engine.connect() as observer:
                deadline = monotonic() + 3
                while not observer.scalar(
                    text(
                        "SELECT count(*) FROM pg_locks WHERE locktype='advisory' "
                        "AND classid=2700 AND objid=1 AND NOT granted"
                    )
                ):
                    assert monotonic() < deadline, "segunda conexao nao aguardou o lock real"
                    sleep(0.01)
            assert not replay.done()
        finally:
            release.set()
        assert first.result(timeout=10) == replay.result(timeout=10)
    assert invocations == [1]


def test_lock_global_em_outra_conexao_retorna_409_sem_escrita(
    committed_database: tuple[Engine, ContextoRbac],
) -> None:
    engine, _ = committed_database
    with engine.connect() as blocker, blocker.begin():
        blocker.execute(text("SELECT pg_advisory_xact_lock(2700,1)"))
        before = _counts(blocker)
        with pytest.raises(BikeTourError) as error:
            _execute(committed_database)
        assert error.value.status_code == 409
        assert error.value.code == "BT_CONTENCAO"
        assert _counts(blocker) == before
