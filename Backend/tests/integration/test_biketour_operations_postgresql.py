"""Catalogo, integridade e reversao do delta 130500 em PostgreSQL real."""

import importlib.util
from collections.abc import Generator
from datetime import UTC, datetime, timedelta
from importlib import import_module
from pathlib import Path
from typing import Any
from unittest.mock import patch
from uuid import uuid4

import pytest
from alembic.migration import MigrationContext
from alembic.operations import Operations
from fastapi.testclient import TestClient
from sqlalchemy import Connection, MetaData, Table, create_engine, inspect, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.db.base import Base
from app.db.session import get_session
from app.main import create_app
from app.modules.biketour.models import (
    AvaliacaoBikeTour,
    EquipeBikeTour,
    LogisticaBikeTour,
    OcorrenciaBikeTour,
    PassagemBikeTour,
    PontoControleBikeTour,
)
from app.modules.biketour.operational_schemas import (
    ApoioInput,
    LogisticaRequest,
    Reacomodacao,
)
from app.modules.biketour.operations import OperacoesBikeTour
from app.modules.biketour.uow import (
    BikeTourUnitOfWork,
    ContextoComando,
    ResultadoComando,
)
from app.modules.seguranca.authorization import (
    exigir_bike_tour_gerenciar,
    exigir_bike_tour_operar,
    exigir_bike_tour_visualizar,
    obter_contexto_rbac,
)
from app.modules.seguranca.rbac import ContextoRbac

pytestmark = pytest.mark.postgresql
MODELS = (
    EquipeBikeTour,
    LogisticaBikeTour,
    PontoControleBikeTour,
    PassagemBikeTour,
    OcorrenciaBikeTour,
    AvaliacaoBikeTour,
)
BUSINESS = {
    "equipe_bike_tour": {"id_evento_bike_tour", "id_recurso_bike_tour", "papel"},
    "logistica_bike_tour": {"id_evento_bike_tour", "id_recurso_bike_tour", "finalidade"},
    "ponto_controle_bike_tour": {"id_evento_bike_tour", "ordem", "id_localidade", "distancia_km"},
    "passagem_bike_tour": {"id_inscricao_bike_tour", "id_ponto_controle_bike_tour", "instante"},
    "ocorrencia_bike_tour": {
        "id_evento_bike_tour",
        "id_inscricao_bike_tour",
        "tipo",
        "gravidade",
        "status",
        "motivo",
    },
    "avaliacao_bike_tour": {"id_inscricao_bike_tour", "nota"},
}
UNIQUES: dict[str, set[tuple[str, ...]]] = {
    "equipe_bike_tour": {("id_evento_bike_tour", "id_recurso_bike_tour")},
    "logistica_bike_tour": {("id_evento_bike_tour", "id_recurso_bike_tour")},
    "ponto_controle_bike_tour": {("id_evento_bike_tour", "ordem")},
    "passagem_bike_tour": {("id_inscricao_bike_tour", "id_ponto_controle_bike_tour")},
    "ocorrencia_bike_tour": set(),
    "avaliacao_bike_tour": {("id_inscricao_bike_tour",)},
}
TABLES = tuple(BUSINESS)


@pytest.fixture
def connection(postgresql_test_url: str) -> Generator[Connection]:
    """Todas as escritas de fixtures e auditoria sofrem rollback, inclusive DDL."""
    engine = create_engine(postgresql_test_url, isolation_level="READ COMMITTED")
    with engine.connect() as conn:
        with conn.begin():
            assert str(conn.scalar(text("SELECT current_database()"))).endswith("_test")
            assert conn.scalar(text("SELECT version_num FROM alembic_version")) == "202609170300"
            assert conn.scalar(text("SHOW transaction_isolation")) == "read committed"
        before = _counts(conn)
        conn.rollback()
        transaction = conn.begin()
        try:
            conn.execute(text("SET LOCAL lock_timeout = '5s'"))
            conn.execute(text("SELECT pg_advisory_xact_lock(2700, 1)"))
            yield conn
        finally:
            transaction.rollback()
            assert _counts(conn) == before, (
                "Rollback deve preservar contagens de origem e auditoria"
            )
    engine.dispose()


def _counts(conn: Connection) -> dict[str, int]:
    tables = (
        *TABLES,
        "evento_bike_tour",
        "recurso_bike_tour",
        "inscricao_bike_tour",
        "alocacao_recurso_bike_tour",
        "produto_turistico",
        "pacote_viagem",
        "saida_turistica",
        "reserva",
        "passageiro_reserva",
        "localidade",
        "pessoa",
        "cliente",
        "guia_turistico",
        "transporte",
        "log_auditoria",
    )
    return {
        table: int(conn.execute(text(f"SELECT count(*) FROM public.{table}")).scalar_one())
        for table in tables
    }


@pytest.fixture
def rows(connection: Connection) -> dict[str, dict[str, Any]]:
    """Referencias reais e sinteticas, reaproveitando a fixture de integridade."""
    token = uuid4().hex[:12].upper()
    # A suite legada usa arquivos sem pacote. Importacao em runtime evita registrar
    # o mesmo teste sob dois nomes no Mypy, sem alterar sua configuracao ou fixtures.
    baseline = import_module("tests.integration.test_biketour_postgresql")
    origin = baseline._create_integrity_fixture(connection, token)
    inscription = baseline._create_inscricao(
        connection,
        evento=origin["evento_1"],
        reserva=origin["reserva"],
        passageiro=origin["passageiro_1"],
        status="CONCLUIDA",
    )
    guide = connection.scalar(
        text(
            "INSERT INTO public.guia_turistico (nome, created_by) VALUES (:name, 'pytest-bt500') "
            "RETURNING id_guia"
        ),
        {"name": f"Guia sintetico {token}"},
    )
    guide_resource = connection.scalar(
        text(
            "INSERT INTO public.recurso_bike_tour (codigo,tipo,id_guia,created_by) "
            "VALUES (:code,'GUIA',:guide,'pytest-bt500') RETURNING id_recurso_bike_tour"
        ),
        {"code": f"BT500-G-{token}", "guide": guide},
    )
    vehicle = connection.scalar(
        text(
            "INSERT INTO public.transporte (tipo_transporte,created_by) "
            "VALUES ('APOIO','pytest-bt500') RETURNING id_transporte"
        )
    )
    vehicle_resource = connection.scalar(
        text(
            "INSERT INTO public.recurso_bike_tour (codigo,tipo,id_transporte,created_by) "
            "VALUES (:code,'VEICULO',:vehicle,'pytest-bt500') RETURNING id_recurso_bike_tour"
        ),
        {"code": f"BT500-V-{token}", "vehicle": vehicle},
    )
    for resource in (guide_resource, vehicle_resource):
        connection.execute(
            text(
                "INSERT INTO public.alocacao_recurso_bike_tour "
                "(id_evento_bike_tour,id_recurso_bike_tour,inicio,fim,status,created_by) "
                "VALUES (:event,:resource,:start,:end,'CONFIRMADA','pytest-bt500')"
            ),
            {
                "event": origin["evento_1"],
                "resource": resource,
                "start": origin["inicio"],
                "end": origin["fim"],
            },
        )
    locality = connection.scalar(text("SELECT min(id_localidade) FROM public.localidade"))
    point = _insert(
        connection,
        "ponto_controle_bike_tour",
        {
            "id_evento_bike_tour": origin["evento_1"],
            "ordem": 1,
            "id_localidade": locality,
            "distancia_km": 0,
        },
    )
    return {
        "equipe_bike_tour": {
            "id_evento_bike_tour": origin["evento_1"],
            "id_recurso_bike_tour": guide_resource,
            "papel": "LIDER",
        },
        "logistica_bike_tour": {
            "id_evento_bike_tour": origin["evento_1"],
            "id_recurso_bike_tour": vehicle_resource,
            "finalidade": "APOIO",
        },
        "ponto_controle_bike_tour": {
            "id_evento_bike_tour": origin["evento_1"],
            "ordem": 2,
            "id_localidade": locality,
            "distancia_km": 5,
        },
        "passagem_bike_tour": {
            "id_inscricao_bike_tour": inscription,
            "id_ponto_controle_bike_tour": point,
            "instante": datetime.now(UTC),
        },
        "ocorrencia_bike_tour": {
            "id_evento_bike_tour": origin["evento_1"],
            "id_inscricao_bike_tour": inscription,
            "tipo": "MECANICA",
            "gravidade": "BAIXA",
            "motivo": "OPERACIONAL",
            "status": "ABERTA",
        },
        "avaliacao_bike_tour": {"id_inscricao_bike_tour": inscription, "nota": 5},
    }


def _insert(conn: Connection, name: str, values: dict[str, Any]) -> int:
    table = Table(name, MetaData(), schema="public", autoload_with=conn, resolve_fks=False)
    result = conn.execute(
        table.insert().values(created_by="pytest-bt500", **values).returning(table.c[f"id_{name}"])
    ).scalar_one()
    return int(result)


def test_fluxo_operacional_http_com_postgresql_e_rollback(
    connection: Connection, rows: dict[str, dict[str, Any]]
) -> None:
    """Configura, bloqueia, confirma, percorre e conclui; transacao externa sempre revertida."""
    evento = int(rows["equipe_bike_tour"]["id_evento_bike_tour"])
    connection.execute(
        text("UPDATE evento_bike_tour SET status='PLANEJADO' WHERE id_evento_bike_tour=:id"),
        {"id": evento},
    )
    connection.execute(
        text(
            "UPDATE alocacao_recurso_bike_tour SET status='LIBERADA',expira_em=NULL "
            "WHERE id_evento_bike_tour=:id"
        ),
        {"id": evento},
    )
    inscricao_origem = rows["passagem_bike_tour"]["id_inscricao_bike_tour"]
    reserva = connection.scalar(
        text("SELECT id_reserva FROM inscricao_bike_tour WHERE id_inscricao_bike_tour=:id"),
        {"id": inscricao_origem},
    )
    passageiro = connection.scalar(
        text("SELECT max(id_passageiro) FROM passageiro_reserva WHERE id_reserva=:id"),
        {"id": reserva},
    )
    usuario = connection.scalar(
        text("INSERT INTO usuario(nome,email) VALUES ('Teste fluxo',:email) RETURNING id_usuario"),
        {"email": f"bt-{uuid4().hex}@example.invalid"},
    )
    ator = ContextoRbac(
        int(usuario),
        (),
        frozenset({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_OPERAR", "BIKE_TOUR_GERENCIAR"}),
    )
    app = create_app()

    def session_dependency() -> Generator[Session]:
        with Session(
            bind=connection, join_transaction_mode="create_savepoint", expire_on_commit=False
        ) as session:
            # O isolamento e validado pela fixture externa. UoW continua controlando o savepoint.
            original = session.connection
            with patch.object(session, "connection", side_effect=lambda **kw: original()):
                yield session

    app.dependency_overrides[get_session] = session_dependency
    for dependency in (
        obter_contexto_rbac,
        exigir_bike_tour_visualizar,
        exigir_bike_tour_operar,
        exigir_bike_tour_gerenciar,
    ):
        app.dependency_overrides[dependency] = lambda: ator

    def versao(tabela: str, identifier: int) -> int:
        return int(
            connection.scalar(
                text(f"SELECT versao FROM {tabela} WHERE id_{tabela}=:id"), {"id": identifier}
            )
        )

    try:
        with TestClient(app) as client, patch("app.modules.biketour.uow.datetime") as clock:
            clock.now.return_value = datetime.now(UTC)

            def comando(
                path: str, data: dict[str, Any], *, code: int = 200, method: str = "POST"
            ) -> Any:
                data.setdefault("chave_idempotencia", uuid4().hex)
                response = client.request(method, "/api/v1/biketour" + path, json=data)
                assert response.status_code == code, response.text
                return response.json()

            bicicleta = comando(
                "/recursos", {"codigo": f"BT-F-{uuid4().hex[:12]}", "tipo": "BICICLETA"}, code=201
            )
            pontos = comando(
                f"/eventos/{evento}/pontos",
                {
                    "versao_esperada": versao("evento_bike_tour", evento),
                    "pontos": [
                        {
                            "ordem": i,
                            "id_localidade": rows["ponto_controle_bike_tour"]["id_localidade"],
                            "distancia_km": (i - 1) * 5,
                        }
                        for i in (1, 2)
                    ],
                },
            )
            for path, campo, entrada in (
                (
                    "equipe",
                    "equipe",
                    {
                        "id_recurso": rows["equipe_bike_tour"]["id_recurso_bike_tour"],
                        "papel": "LIDER",
                    },
                ),
                (
                    "logistica",
                    "apoio",
                    {
                        "id_recurso": rows["logistica_bike_tour"]["id_recurso_bike_tour"],
                        "finalidade": "APOIO",
                    },
                ),
            ):
                comando(
                    f"/eventos/{evento}/{path}",
                    {campo: [entrada], "versao_esperada": versao("evento_bike_tour", evento)},
                )
            comando(
                f"/eventos/{evento}/acoes",
                {"acao": "ABRIR", "versao_esperada": versao("evento_bike_tour", evento)},
            )
            bloqueio = {
                "id_reserva": reserva,
                "id_passageiro": passageiro,
                "papel": "PARTICIPANTE",
                "id_bicicleta": bicicleta["id"],
            }
            inscricao = comando(f"/eventos/{evento}/inscricoes", bloqueio, code=201)
            assert comando(f"/eventos/{evento}/inscricoes", bloqueio, code=201) == inscricao
            identifier = inscricao["id"]
            segunda = comando(
                "/recursos", {"codigo": f"BT-R-{uuid4().hex[:12]}", "tipo": "BICICLETA"}, code=201
            )
            trocada = comando(
                f"/inscricoes/{identifier}/recursos",
                {
                    "id_bicicleta": segunda["id"],
                    "versao_esperada": inscricao["versao"],
                },
            )
            assert trocada["versao"] > inscricao["versao"]
            comando(
                f"/inscricoes/{identifier}/acoes",
                {
                    "acao": "CANCELAR",
                    "motivo": "SOLICITACAO",
                    "versao_esperada": trocada["versao"],
                },
            )
            pendencias = client.get(f"/api/v1/biketour/eventos/{evento}/pendencias").json()
            assert len(pendencias) == 1 and pendencias[0]["status"] == "ABERTA"
            comando(
                f"/pendencias/{pendencias[0]['id']}/tratamento",
                {
                    "versao_esperada": pendencias[0]["versao"],
                    "motivo": "TRATAMENTO_CONCLUIDO",
                    "referencia_tratamento": "SEM-EFEITO-FINANCEIRO-TESTE",
                },
            )

            def rebloquear() -> dict[str, Any]:
                resultado = comando(
                    f"/eventos/{evento}/inscricoes",
                    {
                        **bloqueio,
                        "chave_idempotencia": uuid4().hex,
                        "versao_esperada": versao("inscricao_bike_tour", identifier),
                    },
                )
                assert resultado["id"] == identifier
                return dict(resultado)

            rebloquear()
            connection.execute(
                text("UPDATE reserva SET status='CANCELADA' WHERE id_reserva=:id"), {"id": reserva}
            )
            reconciliada = comando(
                f"/eventos/{evento}/reconciliacao",
                {
                    "versao_esperada": versao("evento_bike_tour", evento),
                    "limite": 1,
                },
            )
            assert reconciliada["tratadas"] == [identifier]
            connection.execute(
                text("UPDATE reserva SET status='CONFIRMADA' WHERE id_reserva=:id"), {"id": reserva}
            )
            rebloquear()
            clock.now.return_value += timedelta(minutes=16)
            expiradas = comando(
                f"/eventos/{evento}/expiracao",
                {
                    "versao_esperada": versao("evento_bike_tour", evento),
                },
            )
            assert expiradas["expiradas"] == [identifier]
            inscricao = rebloquear()
            ocorrencia = comando(
                f"/eventos/{evento}/ocorrencias",
                {
                    "id_inscricao": identifier,
                    "tipo": "MECANICA",
                    "gravidade": "ALTA",
                    "motivo": "OPERACIONAL",
                },
                code=201,
            )
            for estado in ("EM_ANALISE", "RESOLVIDA"):
                ocorrencia = comando(
                    f"/ocorrencias/{ocorrencia['id']}",
                    {
                        "status": estado,
                        "motivo": "TRATAMENTO_CONCLUIDO",
                        "versao_esperada": ocorrencia["versao"],
                    },
                    method="PATCH",
                )
            confirmada = comando(
                f"/inscricoes/{identifier}/acoes",
                {"acao": "CONFIRMAR", "versao_esperada": inscricao["versao"]},
            )
            assert confirmada["status"] == "CONFIRMADA"
            inicio = connection.scalar(
                text("SELECT inicio FROM evento_bike_tour WHERE id_evento_bike_tour=:id"),
                {"id": evento},
            )
            clock.now.return_value = inicio + timedelta(minutes=1)
            comando(
                f"/eventos/{evento}/acoes",
                {"acao": "INICIAR", "versao_esperada": versao("evento_bike_tour", evento)},
            )
            comando(
                f"/inscricoes/{identifier}/acoes",
                {
                    "acao": "PRESENCA",
                    "motivo": "OPERACIONAL",
                    "versao_esperada": confirmada["versao"],
                },
            )
            for ponto in pontos:
                comando(
                    f"/inscricoes/{identifier}/passagens",
                    {
                        "id_ponto": ponto["id"],
                        "instante": clock.now.return_value.isoformat(),
                        "versao_esperada": versao("inscricao_bike_tour", identifier),
                    },
                    code=201,
                )
            concluida = comando(
                f"/inscricoes/{identifier}/acoes",
                {"acao": "CONCLUIR", "versao_esperada": versao("inscricao_bike_tour", identifier)},
            )
            assert concluida["status"] == "CONCLUIDA"
            comando(
                f"/inscricoes/{identifier}/avaliacao",
                {"nota": 5, "versao_esperada": concluida["versao"]},
                code=201,
            )
            encerrado = comando(
                f"/eventos/{evento}/acoes",
                {
                    "acao": "CONCLUIR",
                    "motivo": "OPERACIONAL",
                    "versao_esperada": versao("evento_bike_tour", evento),
                },
            )
            assert encerrado["status"] == "CONCLUIDO"
            for path in (
                f"/eventos/{evento}/relatorio",
                f"/eventos/{evento}/inscricoes",
                f"/eventos/{evento}/auditoria",
                f"/eventos/{evento}/disponibilidade",
                "/recursos",
                f"/inscricoes/{identifier}/origem",
            ):
                response = client.get("/api/v1/biketour" + path)
                assert response.status_code == 200, response.text
            connection.execute(text("SET CONSTRAINTS ALL IMMEDIATE"))
    finally:
        app.dependency_overrides.clear()


@pytest.mark.parametrize("model", MODELS)
def test_catalogo_corresponde_ao_model_e_a8(connection: Connection, model: type[Base]) -> None:
    table = model.__table__
    assert isinstance(table, Table)
    inspector = inspect(connection)
    columns = {c["name"]: c for c in inspector.get_columns(table.name, schema="public")}
    assert columns.keys() == set(table.c.keys())
    for name, column in columns.items():
        expected = table.c[name]
        assert column["nullable"] == expected.nullable
        assert str(column["type"].compile(dialect=connection.dialect)) == str(
            expected.type.compile(dialect=connection.dialect)
        )
        assert column["comment"]
    assert columns[f"id_{table.name}"]["identity"]
    assert inspector.get_table_comment(table.name, schema="public")["text"] == table.comment
    assert inspector.get_pk_constraint(table.name, schema="public")["name"] == f"pk_{table.name}"
    assert {
        tuple(u["column_names"])
        for u in inspector.get_unique_constraints(table.name, schema="public")
    } == UNIQUES[table.name]
    fks = inspector.get_foreign_keys(table.name, schema="public")
    assert {fk["name"] for fk in fks} == {fk.name for fk in table.foreign_key_constraints}
    for fk in fks:
        assert fk["referred_schema"] == "public"
        assert fk["referred_columns"] == fk["constrained_columns"]
        assert fk["referred_table"] == fk["constrained_columns"][0].removeprefix("id_")
    checks = inspector.get_check_constraints(table.name, schema="public")
    assert all(c["name"] and c["name"].count("ck_") == 1 for c in checks)
    assert {
        i["name"]
        for i in inspector.get_indexes(table.name, schema="public")
        if not i.get("duplicates_constraint")
    } == {i.name for i in table.indexes}
    triggers = connection.execute(
        text(
            "SELECT tgname, pg_get_triggerdef(oid) FROM pg_trigger "
            "WHERE tgrelid=to_regclass(:table) AND NOT tgisinternal ORDER BY tgname"
        ),
        {"table": f"public.{table.name}"},
    ).all()
    assert len(triggers) == 2
    assert any("BEFORE UPDATE" in r[1] and "fn_atualiza_updated_at()" in r[1] for r in triggers)
    assert any(
        "AFTER INSERT OR DELETE OR UPDATE" in r[1] and "fn_log_auditoria()" in r[1]
        for r in triggers
    )


@pytest.mark.parametrize("table", TABLES)
def test_auditoria_versao_soft_delete_e_rollback(
    connection: Connection,
    rows: dict[str, dict[str, Any]],
    table: str,
) -> None:
    identifier = _insert(connection, table, rows[table])
    query = text(f"SELECT * FROM public.{table} WHERE id_{table}=:id")
    before = connection.execute(query, {"id": identifier}).mappings().one()
    assert before["versao"] == 1 and before["created_at"].tzinfo is not None
    assert before["updated_at"] is None and before["deleted_at"] is None
    connection.execute(
        text(
            f"UPDATE public.{table} SET deleted_at=CURRENT_TIMESTAMP, deleted_by='pytest-bt500', "
            f"updated_by='pytest-bt500' WHERE id_{table}=:id"
        ),
        {"id": identifier},
    )
    after = connection.execute(query, {"id": identifier}).mappings().one()
    assert after["versao"] == 2 and after["updated_at"] is not None
    assert after["deleted_at"] is not None and after["deleted_by"] == "pytest-bt500"
    for field in BUSINESS[table]:
        assert after[field] == before[field]
    audit = connection.execute(
        text(
            "SELECT acao,dados_novos FROM public.log_auditoria WHERE tabela_nome=:table "
            "AND registro_id=:id ORDER BY acao"
        ),
        {"table": f"public.{table}", "id": identifier},
    ).all()
    assert {r[0] for r in audit} == {"INSERT", "UPDATE"}
    assert {r[1]["versao"] for r in audit} == {1, 2}
    connection.execute(text("SET CONSTRAINTS ALL IMMEDIATE"))


NEGATIVE = [
    ("equipe_bike_tour", "papel", "GESTOR"),
    ("logistica_bike_tour", "finalidade", "OUTRA"),
    ("ponto_controle_bike_tour", "ordem", 0),
    ("ponto_controle_bike_tour", "distancia_km", -1),
    ("ocorrencia_bike_tour", "tipo", "CLINICA"),
    ("ocorrencia_bike_tour", "gravidade", "CRITICA"),
    ("ocorrencia_bike_tour", "status", "FECHADA"),
    ("ocorrencia_bike_tour", "motivo", "texto livre"),
    ("avaliacao_bike_tour", "nota", 0),
    ("avaliacao_bike_tour", "nota", 6),
    *((table, "versao", 0) for table in TABLES),
]


@pytest.mark.parametrize("table,column,value", NEGATIVE)
def test_checks_rejeitam_sql_invalido(
    connection: Connection,
    rows: dict[str, dict[str, Any]],
    table: str,
    column: str,
    value: object,
) -> None:
    with pytest.raises(IntegrityError) as error, connection.begin_nested():
        _insert(connection, table, rows[table] | {column: value})
    assert getattr(error.value.orig, "sqlstate", None) == "23514"


@pytest.mark.parametrize("table", TABLES)
def test_campos_obrigatorios_e_fks_reais(
    connection: Connection,
    rows: dict[str, dict[str, Any]],
    table: str,
) -> None:
    for column in BUSINESS[table] | {"created_at", "versao"}:
        if table == "ocorrencia_bike_tour" and column == "id_inscricao_bike_tour":
            _insert(connection, table, rows[table] | {column: None})
        else:
            with pytest.raises(IntegrityError) as error, connection.begin_nested():
                _insert(connection, table, rows[table] | {column: None})
            assert getattr(error.value.orig, "sqlstate", None) == "23502"
        if column.startswith("id_"):
            with pytest.raises(IntegrityError) as error, connection.begin_nested():
                _insert(connection, table, rows[table] | {column: -1})
            assert getattr(error.value.orig, "sqlstate", None) == "23503"


@pytest.mark.parametrize("table", [t for t in TABLES if UNIQUES[t]])
def test_unicidade_preservada_apos_soft_delete(
    connection: Connection,
    rows: dict[str, dict[str, Any]],
    table: str,
) -> None:
    identifier = _insert(connection, table, rows[table])
    for deleted in (False, True):
        if deleted:
            connection.execute(
                text(
                    f"UPDATE public.{table} SET deleted_at=CURRENT_TIMESTAMP WHERE id_{table}=:id"
                ),
                {"id": identifier},
            )
        with pytest.raises(IntegrityError) as error, connection.begin_nested():
            _insert(connection, table, rows[table])
        assert getattr(error.value.orig, "sqlstate", None) == "23505"


def test_lider_unico_e_substituicao_preserva_historico(
    connection: Connection,
    rows: dict[str, dict[str, Any]],
) -> None:
    leader = _insert(connection, "equipe_bike_tour", rows["equipe_bike_tour"])
    guide = connection.scalar(
        text(
            "INSERT INTO public.guia_turistico(nome) VALUES ('Guia sintetico substituto') "
            "RETURNING id_guia"
        )
    )
    resource = connection.scalar(
        text(
            "INSERT INTO public.recurso_bike_tour(codigo,tipo,id_guia) "
            "VALUES (:code,'GUIA',:guide) "
            "RETURNING id_recurso_bike_tour"
        ),
        {"code": f"BT500-{uuid4().hex[:12]}", "guide": guide},
    )
    replacement = rows["equipe_bike_tour"] | {"id_recurso_bike_tour": resource}
    with pytest.raises(IntegrityError) as error, connection.begin_nested():
        _insert(connection, "equipe_bike_tour", replacement)
    assert getattr(error.value.orig, "sqlstate", None) == "23505"
    assert (
        getattr(getattr(error.value.orig, "diag", None), "constraint_name", None)
        == "idx_equipe_bike_tour_lider_evento"
    )
    connection.execute(
        text(
            "UPDATE public.equipe_bike_tour SET deleted_at=CURRENT_TIMESTAMP "
            "WHERE id_equipe_bike_tour=:id"
        ),
        {"id": leader},
    )
    new = _insert(connection, "equipe_bike_tour", replacement)
    assert new != leader
    assert connection.scalar(
        text(
            "SELECT deleted_at IS NOT NULL FROM public.equipe_bike_tour "
            "WHERE id_equipe_bike_tour=:id"
        ),
        {"id": leader},
    )


def _catalog(conn: Connection) -> list[tuple[Any, ...]]:
    """Definicoes de objetos de usuario; nao le dados pessoais nem estado de sequences."""
    return [
        tuple(row)
        for row in conn.execute(
            text(
                """
        SELECT 'relation', n.nspname || '.' || c.relname, c.relkind::text
        FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
        WHERE n.nspname NOT IN ('pg_catalog','information_schema')
          AND n.nspname NOT LIKE 'pg_toast%'
        UNION ALL
        SELECT 'column', c.oid::regclass::text || '.' || a.attname,
               format_type(a.atttypid,a.atttypmod) || ':' || a.attnotnull::text
               || ':' || coalesce(pg_get_expr(d.adbin,d.adrelid),'')
               || ':' || coalesce(col_description(c.oid,a.attnum),'')
        FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid
        JOIN pg_namespace n ON n.oid=c.relnamespace
        LEFT JOIN pg_attrdef d ON d.adrelid=c.oid AND d.adnum=a.attnum
        WHERE a.attnum > 0 AND NOT a.attisdropped
          AND n.nspname NOT IN ('pg_catalog','information_schema')
          AND n.nspname NOT LIKE 'pg_toast%'
        UNION ALL
        SELECT 'constraint', conrelid::regclass::text || '.' || conname, pg_get_constraintdef(c.oid)
        FROM pg_constraint c JOIN pg_namespace n ON n.oid=c.connamespace
        WHERE n.nspname NOT IN ('pg_catalog','information_schema')
        UNION ALL
        SELECT 'index', schemaname || '.' || indexname, indexdef FROM pg_indexes
        WHERE schemaname NOT IN ('pg_catalog','information_schema')
        UNION ALL
        SELECT 'trigger', tgrelid::regclass::text || '.' || tgname, pg_get_triggerdef(oid)
        FROM pg_trigger WHERE NOT tgisinternal
        UNION ALL
        SELECT 'function', p.oid::regprocedure::text, pg_get_functiondef(p.oid)
        FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
        WHERE n.nspname NOT IN ('pg_catalog','information_schema') AND p.prokind IN ('f','p')
        ORDER BY 1,2,3
        """
            )
        )
    ]


def test_downgrade_reupgrade_preserva_catalogo_e_dados_anteriores(connection: Connection) -> None:
    """Exercita o DDL real dentro de transacao revertida; nao troca head de outros testes."""
    assert all(connection.scalar(text(f"SELECT count(*) FROM public.{t}")) == 0 for t in TABLES)
    path = (
        Path(__file__).resolve().parents[2]
        / "migrations/versions/202609130500_bike_tour_operations.py"
    )
    spec = importlib.util.spec_from_file_location("bike_operations_cycle", path)
    assert spec and spec.loader
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)
    before = _catalog(connection)
    counts = _counts(connection)
    context = MigrationContext.configure(connection, opts={"target_metadata": Base.metadata})
    with Operations.context(context):
        migration.downgrade()
        assert all(
            connection.scalar(text("SELECT to_regclass(:table)"), {"table": f"public.{t}"}) is None
            for t in TABLES
        )
        for table, count in counts.items():
            if table not in TABLES:
                assert connection.scalar(text(f"SELECT count(*) FROM public.{table}")) == count
        migration.upgrade()
    assert _catalog(connection) == before
    assert _counts(connection) == counts
    assert connection.scalar(text("SELECT version_num FROM alembic_version")) == "202609170300"


def test_t09_substituicao_apoio_falha_restaura_plano_anterior(
    connection: Connection,
    rows: dict[str, dict[str, Any]],
) -> None:
    """T09: falha na substituicao restaura apoio e alocacao anteriores."""
    evento = int(rows["logistica_bike_tour"]["id_evento_bike_tour"])
    recurso_anterior = int(rows["logistica_bike_tour"]["id_recurso_bike_tour"])

    logistica_anterior = _insert(
        connection,
        "logistica_bike_tour",
        rows["logistica_bike_tour"],
    )

    connection.execute(
        text(
            """
            UPDATE evento_bike_tour
            SET status='PLANEJADO'
            WHERE id_evento_bike_tour=:evento
            """
        ),
        {"evento": evento},
    )

    estado_antes = connection.execute(
        text(
            """
            SELECT
                l.deleted_at,
                a.status
            FROM logistica_bike_tour AS l
            JOIN alocacao_recurso_bike_tour AS a
              ON a.id_evento_bike_tour =
                 l.id_evento_bike_tour
             AND a.id_recurso_bike_tour =
                 l.id_recurso_bike_tour
            WHERE l.id_logistica_bike_tour=:logistica
            """
        ),
        {"logistica": logistica_anterior},
    ).one()

    novo_transporte = connection.scalar(
        text(
            """
            INSERT INTO transporte (
                tipo_transporte,
                created_by
            )
            VALUES (
                'APOIO',
                'pytest-t09'
            )
            RETURNING id_transporte
            """
        )
    )

    assert novo_transporte is not None

    novo_recurso = connection.scalar(
        text(
            """
            INSERT INTO recurso_bike_tour (
                codigo,
                tipo,
                id_transporte,
                created_by
            )
            VALUES (
                :codigo,
                'VEICULO',
                :transporte,
                'pytest-t09'
            )
            RETURNING id_recurso_bike_tour
            """
        ),
        {
            "codigo": f"BT-T09-{uuid4().hex[:12]}",
            "transporte": novo_transporte,
        },
    )

    assert novo_recurso is not None

    session = Session(
        bind=connection,
        join_transaction_mode="create_savepoint",
        expire_on_commit=False,
    )

    try:
        original_connection = session.connection

        with patch.object(
            session,
            "connection",
            side_effect=lambda **_kw: original_connection(),
        ):
            ator = ContextoRbac(
                1,
                (),
                frozenset(
                    {
                        "BIKE_TOUR_VISUALIZAR",
                        "BIKE_TOUR_OPERAR",
                        "BIKE_TOUR_GERENCIAR",
                    }
                ),
            )

            def comando(
                context: ContextoComando,
            ) -> ResultadoComando:
                original_flush = context.session.flush
                flushes = 0

                def falhar_apos_nova_alocacao(
                    *args: Any,
                    **kwargs: Any,
                ) -> None:
                    nonlocal flushes

                    original_flush(*args, **kwargs)
                    flushes += 1

                    if flushes == 2:
                        raise RuntimeError("T09_FALHA_INJETADA")

                with patch.object(
                    context.session,
                    "flush",
                    side_effect=falhar_apos_nova_alocacao,
                ):
                    return OperacoesBikeTour(context).definir_apoio(
                        evento,
                        LogisticaRequest(
                            chave_idempotencia="t09-rollback-apoio",
                            apoio=[
                                ApoioInput(
                                    id_recurso=int(novo_recurso),
                                    finalidade="APOIO",
                                )
                            ],
                            versao_esperada=int(
                                connection.scalar(
                                    text(
                                        """
                                        SELECT versao
                                        FROM evento_bike_tour
                                        WHERE
                                            id_evento_bike_tour
                                            = :evento
                                        """
                                    ),
                                    {"evento": evento},
                                )
                            ),
                        ),
                    )

            with pytest.raises(
                RuntimeError,
                match="T09_FALHA_INJETADA",
            ):
                BikeTourUnitOfWork(session).executar(
                    ator=ator,
                    permissao="BIKE_TOUR_GERENCIAR",
                    correlation_id=uuid4(),
                    operacao="t09_rollback_apoio",
                    alvo=evento,
                    chave=uuid4().hex,
                    payload={"evento": evento},
                    comando=comando,
                )
    finally:
        session.close()

    estado_depois = connection.execute(
        text(
            """
            SELECT
                l.deleted_at,
                a.status
            FROM logistica_bike_tour AS l
            JOIN alocacao_recurso_bike_tour AS a
              ON a.id_evento_bike_tour =
                 l.id_evento_bike_tour
             AND a.id_recurso_bike_tour =
                 l.id_recurso_bike_tour
            WHERE l.id_logistica_bike_tour=:logistica
            """
        ),
        {"logistica": logistica_anterior},
    ).one()

    assert estado_depois == estado_antes

    assert (
        connection.scalar(
            text(
                """
                SELECT count(*)
                FROM logistica_bike_tour
                WHERE id_evento_bike_tour=:evento
                  AND id_recurso_bike_tour=:recurso
                  AND deleted_at IS NULL
                """
            ),
            {
                "evento": evento,
                "recurso": int(novo_recurso),
            },
        )
        == 0
    )

    assert (
        connection.scalar(
            text(
                """
                SELECT count(*)
                FROM alocacao_recurso_bike_tour
                WHERE id_evento_bike_tour=:evento
                  AND id_recurso_bike_tour=:recurso
                  AND status IN (
                      'BLOQUEADA',
                      'CONFIRMADA'
                  )
                """
            ),
            {
                "evento": evento,
                "recurso": int(novo_recurso),
            },
        )
        == 0
    )

    assert (
        connection.scalar(
            text(
                """
                SELECT status
                FROM alocacao_recurso_bike_tour
                WHERE id_evento_bike_tour=:evento
                  AND id_recurso_bike_tour=:recurso
                """
            ),
            {
                "evento": evento,
                "recurso": recurso_anterior,
            },
        )
        == "CONFIRMADA"
    )


def test_t18_reacomodacao_falha_restaura_alocacao_origem(
    connection: Connection,
) -> None:
    """T18: falha apos destino alocado restaura a origem."""
    baseline = import_module("tests.integration.test_biketour_postgresql")

    token = uuid4().hex[:12].upper()
    origin = baseline._create_integrity_fixture(
        connection,
        token,
    )

    evento = int(origin["evento_1"])
    reserva = int(origin["reserva"])
    passageiro = int(origin["passageiro_1"])
    bicicleta_origem = int(origin["bicicleta_1"])
    bicicleta_destino = int(origin["bicicleta_2"])

    inscricao = baseline._create_inscricao(
        connection,
        evento=evento,
        reserva=reserva,
        passageiro=passageiro,
        status="PENDENTE",
    )

    baseline._create_allocation(
        connection,
        evento=evento,
        inscricao=inscricao,
        recurso=bicicleta_origem,
        inicio=origin["inicio"],
        fim=origin["fim"],
        status="BLOQUEADA",
    )

    connection.execute(
        text(
            """
            UPDATE evento_bike_tour
            SET status='ABERTO'
            WHERE id_evento_bike_tour=:evento
            """
        ),
        {"evento": evento},
    )

    estado_origem_antes = connection.execute(
        text(
            """
            SELECT status, expira_em
            FROM alocacao_recurso_bike_tour
            WHERE id_evento_bike_tour=:evento
              AND id_inscricao_bike_tour=:inscricao
              AND id_recurso_bike_tour=:recurso
            """
        ),
        {
            "evento": evento,
            "inscricao": inscricao,
            "recurso": bicicleta_origem,
        },
    ).one()

    session = Session(
        bind=connection,
        join_transaction_mode="create_savepoint",
        expire_on_commit=False,
    )

    try:
        original_connection = session.connection

        with patch.object(
            session,
            "connection",
            side_effect=lambda **_kw: original_connection(),
        ):
            ator = ContextoRbac(
                1,
                (),
                frozenset(
                    {
                        "BIKE_TOUR_VISUALIZAR",
                        "BIKE_TOUR_OPERAR",
                        "BIKE_TOUR_GERENCIAR",
                    }
                ),
            )

            def comando(
                context: ContextoComando,
            ) -> ResultadoComando:
                original_flush = context.session.flush

                def falhar_apos_destino(
                    *args: Any,
                    **kwargs: Any,
                ) -> None:
                    original_flush(*args, **kwargs)

                    destino = context.session.scalar(
                        text(
                            """
                            SELECT count(*)
                            FROM alocacao_recurso_bike_tour
                            WHERE
                                id_evento_bike_tour=:evento
                            AND
                                id_inscricao_bike_tour=:inscricao
                            AND
                                id_recurso_bike_tour=:recurso
                            AND status IN (
                                'BLOQUEADA',
                                'CONFIRMADA'
                            )
                            """
                        ),
                        {
                            "evento": evento,
                            "inscricao": inscricao,
                            "recurso": bicicleta_destino,
                        },
                    )

                    if destino == 1:
                        raise RuntimeError("T18_FALHA_INJETADA")

                with patch.object(
                    context.session,
                    "flush",
                    side_effect=falhar_apos_destino,
                ):
                    return OperacoesBikeTour(context).reacomodar(
                        inscricao,
                        Reacomodacao(
                            chave_idempotencia="t18-rollback-reacomodacao",
                            id_bicicleta=bicicleta_destino,
                            versao_esperada=1,
                        ),
                    )

            with pytest.raises(
                RuntimeError,
                match="T18_FALHA_INJETADA",
            ):
                BikeTourUnitOfWork(session).executar(
                    ator=ator,
                    permissao="BIKE_TOUR_OPERAR",
                    correlation_id=uuid4(),
                    operacao="t18_rollback_reacomodacao",
                    alvo=inscricao,
                    chave=uuid4().hex,
                    payload={"inscricao": inscricao},
                    comando=comando,
                )
    finally:
        session.close()

    estado_origem_depois = connection.execute(
        text(
            """
            SELECT status, expira_em
            FROM alocacao_recurso_bike_tour
            WHERE id_evento_bike_tour=:evento
              AND id_inscricao_bike_tour=:inscricao
              AND id_recurso_bike_tour=:recurso
            """
        ),
        {
            "evento": evento,
            "inscricao": inscricao,
            "recurso": bicicleta_origem,
        },
    ).one()

    assert estado_origem_depois == estado_origem_antes

    assert (
        connection.scalar(
            text(
                """
                SELECT count(*)
                FROM alocacao_recurso_bike_tour
                WHERE id_evento_bike_tour=:evento
                  AND id_inscricao_bike_tour=:inscricao
                  AND id_recurso_bike_tour=:recurso
                """
            ),
            {
                "evento": evento,
                "inscricao": inscricao,
                "recurso": bicicleta_destino,
            },
        )
        == 0
    )

    assert (
        connection.scalar(
            text(
                """
                SELECT versao
                FROM inscricao_bike_tour
                WHERE id_inscricao_bike_tour=:inscricao
                """
            ),
            {"inscricao": inscricao},
        )
        == 1
    )
