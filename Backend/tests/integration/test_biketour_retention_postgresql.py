"""T23 real: transacoes revertidas, preservacao de fatos e replay seguro."""

import hashlib
from collections.abc import Generator
from contextlib import contextmanager
from datetime import UTC, datetime, timedelta
from importlib import import_module
from typing import Any
from unittest.mock import patch
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import Connection, create_engine, select, text
from sqlalchemy.orm import Session

from app.db import models as registered_models  # noqa: F401
from app.db.session import get_session
from app.main import create_app
from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import OperacaoBikeTour
from app.modules.biketour.retention import (
    RevisaoRetencao,
    RevisaoRetencaoResponse,
    revisar_retencao,
)
from app.modules.biketour.uow import BikeTourUnitOfWork
from app.modules.seguranca.authorization import obter_contexto_rbac
from app.modules.seguranca.rbac import ContextoRbac

pytestmark = pytest.mark.postgresql
NOW = datetime.now(UTC)


def fingerprint(conn: Connection) -> dict[str, str]:
    """Compara conteudo de todas as tabelas protegidas, sem imprimir dados."""
    tables = conn.execute(
        text(
            """
            SELECT n.nspname, c.relname
            FROM pg_class c
            JOIN pg_namespace n ON n.oid = c.relnamespace
            WHERE c.relkind IN ('r', 'p')
              AND n.nspname IN (
                  'public',
                  'financeiro',
                  'auditoria',
                  'config',
                  'dw',
                  'logs',
                  'seguranca',
                  'util'
              )
              AND c.relname NOT LIKE '%bike_tour'
              AND c.relname <> 'log_auditoria'
              AND has_schema_privilege(
                  current_user,
                  n.oid,
                  'USAGE'
              )
              AND has_table_privilege(
                  current_user,
                  c.oid,
                  'SELECT'
              )
            ORDER BY 1, 2
            """
        )
    ).all()
    quote = conn.dialect.identifier_preparer.quote
    result = {}
    for schema, table in tables:
        rows = conn.scalars(
            text(f"SELECT row_to_json(t)::text FROM {quote(schema)}.{quote(table)} t ORDER BY 1")
        ).all()
        result[f"{schema}.{table}"] = hashlib.sha256("\n".join(rows).encode()).hexdigest()
    return result


@pytest.fixture
def database(postgresql_test_url: str) -> Generator[tuple[Connection, ContextoRbac, int]]:
    engine = create_engine(postgresql_test_url, isolation_level="READ COMMITTED")
    with engine.connect() as conn:
        assert str(conn.scalar(text("SELECT current_database()"))).endswith("_test")
        assert conn.scalar(text("SHOW transaction_isolation")) == "read committed"
        conn.rollback()
        before = fingerprint(conn)
        conn.rollback()
        tx = conn.begin()
        actor = int(
            conn.execute(
                text(
                    "INSERT INTO usuario(nome,email) VALUES ('Retencao teste',:email) "
                    "RETURNING id_usuario"
                ),
                {"email": f"retention-{uuid4().hex}@example.invalid"},
            ).scalar_one()
        )
        origin = import_module(
            "tests.integration.test_biketour_postgresql"
        )._create_integrity_fixture(conn, uuid4().hex[:12].upper())
        ctx = ContextoRbac(actor, (), frozenset({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}))
        try:
            yield conn, ctx, int(origin["evento_1"])
        finally:
            tx.rollback()
            assert fingerprint(conn) == before
    engine.dispose()


@contextmanager
def transactional_session(conn: Connection) -> Generator[Session]:
    """Isolamento ja fixado pela fixture; a UoW confirma/reverte seu savepoint real."""
    with Session(conn, join_transaction_mode="create_savepoint") as session:
        original = session.connection
        with patch.object(session, "connection", side_effect=lambda **kw: original()):
            yield session


def seed(conn: Connection, actor: ContextoRbac, *, days: int = 366, **kw: Any) -> int:
    with transactional_session(conn) as session:
        item = OperacaoBikeTour(
            **{
                "id_usuario": actor.id_usuario,
                "operacao": "criar_recurso",
                "alvo": 0,
                "chave_hash": hashlib.sha256(uuid4().hex.encode()).hexdigest(),
                "payload_hash": hashlib.sha256(b"{}").hexdigest(),
                "http_status": 201,
                "resultado": {"id_recurso_bike_tour": 123, "status": "INATIVO"},
                "correlation_id": uuid4(),
                "created_at": NOW - timedelta(days=days),
                **kw,
            }
        )
        session.add(item)
        session.commit()
        return item.id_operacao_bike_tour


def execute(conn: Connection, actor: ContextoRbac, identifier: int, **kw: Any) -> dict[str, Any]:
    payload = RevisaoRetencao.model_validate(
        {
            "chave_idempotencia": uuid4().hex,
            "versao_esperada": 1,
            "acao": "COMPACTAR",
            "motivo": "OPERACIONAL",
            "simular": False,
            **kw,
        }
    )
    with transactional_session(conn) as session:
        result = (
            BikeTourUnitOfWork(session)
            .executar(
                ator=actor,
                permissao="BIKE_TOUR_GERENCIAR",
                correlation_id=uuid4(),
                operacao="revisar_retencao",
                alvo=identifier,
                chave=payload.chave_idempotencia,
                payload=payload.model_dump(mode="json", exclude={"chave_idempotencia"}),
                comando=lambda ctx: revisar_retencao(ctx, identifier, payload),
            )
            .corpo
        )
        assert isinstance(result, dict)
        return result


def test_prazos_compactacao_replay_e_fronteiras(
    database: tuple[Connection, ContextoRbac, int],
) -> None:
    conn, actor, _ = database
    recent = seed(conn, actor, days=89)
    old = seed(conn, actor, chave_hash=hashlib.sha256(b"original").hexdigest())
    before = fingerprint(conn)
    audit = list(conn.scalars(text("SELECT row_to_json(t)::text FROM log_auditoria t ORDER BY 1")))
    assert execute(conn, actor, recent)["processada"] == 0
    simulated = execute(conn, actor, old, simular=True)
    assert simulated["elegivel"] == 1 and simulated["processada"] == 0
    first = execute(conn, actor, old, chave_idempotencia="compactar")
    assert first["processada"] == 1
    assert execute(conn, actor, old, chave_idempotencia="compactar") == first
    with transactional_session(conn) as session:
        item = session.get(OperacaoBikeTour, old)
        assert item is not None and item.resultado == {
            "id_recurso_bike_tour": 123,
            "status": "INATIVO",
            "retencao_compactada": True,
        }
    with (
        transactional_session(conn) as session,
        pytest.raises(BikeTourError, match="BT_RESPOSTA_COMPACTADA"),
    ):
        BikeTourUnitOfWork(session).executar(
            ator=actor,
            permissao="BIKE_TOUR_GERENCIAR",
            correlation_id=uuid4(),
            operacao="criar_recurso",
            alvo=0,
            chave="original",
            payload={},
            comando=lambda ctx: pytest.fail("Chave conhecida nao pode executar novamente"),
        )
    assert fingerprint(conn) == before
    after = set(conn.scalars(text("SELECT row_to_json(t)::text FROM log_auditoria t")))
    assert set(audit) <= after


def test_hold_extensao_e_rollback(database: tuple[Connection, ContextoRbac, int]) -> None:
    conn, actor, _ = database
    identifier = seed(conn, actor)
    assert execute(conn, actor, identifier, acao="PRESERVAR")["preservacao_expressa"]
    held = execute(conn, actor, identifier, versao_esperada=2)
    assert held["processada"] == 0 and "PRESERVACAO_EXPRESSA" in held["impedimentos"]
    execute(conn, actor, identifier, acao="LIBERAR_HOLD", versao_esperada=3)
    execute(
        conn,
        actor,
        identifier,
        acao="PRORROGAR",
        versao_esperada=4,
        nova_data=(NOW + timedelta(days=90)).isoformat(),
    )
    extended = execute(conn, actor, identifier, versao_esperada=5)
    assert extended["processada"] == 0 and "RETENCAO_ADICIONAL" in extended["impedimentos"]
    before = list(
        conn.scalars(text("SELECT row_to_json(t)::text FROM operacao_bike_tour t ORDER BY 1"))
    )
    audit = list(conn.scalars(text("SELECT row_to_json(t)::text FROM log_auditoria t ORDER BY 1")))
    with (
        patch(
            "app.modules.biketour.uow.OperacaoRepository.adicionar",
            side_effect=RuntimeError("falha"),
        ),
        pytest.raises(RuntimeError, match="falha"),
    ):
        execute(conn, actor, identifier, acao="LIBERAR_HOLD", versao_esperada=6)
    assert (
        list(conn.scalars(text("SELECT row_to_json(t)::text FROM operacao_bike_tour t ORDER BY 1")))
        == before
    )
    assert (
        list(conn.scalars(text("SELECT row_to_json(t)::text FROM log_auditoria t ORDER BY 1")))
        == audit
    )


@pytest.mark.parametrize("days", [364, 366])
def test_evento_terminal_e_pendencia(
    database: tuple[Connection, ContextoRbac, int], days: int
) -> None:
    conn, actor, event = database
    conn.execute(
        text("UPDATE evento_bike_tour SET status='CANCELADO' WHERE id_evento_bike_tour=:id"),
        {"id": event},
    )
    terminal = seed(
        conn,
        actor,
        days=days,
        operacao="acao_evento",
        alvo=event,
        resultado={"id_evento_bike_tour": event, "status": "CANCELADO"},
    )
    conn.execute(
        text(
            "INSERT INTO pendencia_bike_tour"
            "(id_evento_bike_tour,id_operacao_bike_tour,tipo,status,motivo) "
            "VALUES (:event,:op,'CANCELAMENTO','ABERTA','OPERACIONAL')"
        ),
        {"event": event, "op": terminal},
    )
    result = execute(conn, actor, terminal)
    assert result["elegivel"] == int(days >= 365)
    assert result["processada"] == 0
    assert "PENDENCIA_ABERTA" in result["impedimentos"]


def test_http_real_administrativo(database: tuple[Connection, ContextoRbac, int]) -> None:
    conn, actor, _ = database
    identifier = seed(conn, actor)
    app = create_app()

    def session_dependency() -> Generator[Session]:
        with transactional_session(conn) as session:
            yield session

    app.dependency_overrides[get_session] = session_dependency
    app.dependency_overrides[obter_contexto_rbac] = lambda: actor
    body = {
        "chave_idempotencia": "http-retencao",
        "versao_esperada": 1,
        "acao": "REVISAR",
        "motivo": "OPERACIONAL",
        "simular": False,
    }
    with TestClient(app) as client:
        response = client.post(f"/api/v1/biketour/operacoes/{identifier}/retencao", json=body)
        assert response.status_code == 200, response.text
        assert response.json()["ator"] == actor.id_usuario
        assert (
            client.post(f"/api/v1/biketour/operacoes/{identifier}/retencao", json=body).json()
            == response.json()
        )
        app.dependency_overrides[obter_contexto_rbac] = lambda: ContextoRbac(
            actor.id_usuario, (), frozenset({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_OPERAR"})
        )
        assert (
            client.post(f"/api/v1/biketour/operacoes/{identifier}/retencao", json=body).status_code
            == 403
        )
        app.dependency_overrides.pop(obter_contexto_rbac)
        assert (
            client.post(f"/api/v1/biketour/operacoes/{identifier}/retencao", json=body).status_code
            == 401
        )
    with transactional_session(conn) as session:
        record = session.scalar(
            select(OperacaoBikeTour).where(
                OperacaoBikeTour.operacao == "revisar_retencao",
                OperacaoBikeTour.alvo == identifier,
            )
        )
        assert record is not None
        assert (
            RevisaoRetencaoResponse.model_validate(record.resultado).model_dump(mode="json")
            == response.json()
        )
