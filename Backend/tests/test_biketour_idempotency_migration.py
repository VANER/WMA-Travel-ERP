"""Contrato fisico da infraestrutura de replay e pendencias, sem PII duplicada."""

import hashlib
import importlib.util
from io import StringIO
from pathlib import Path
from types import ModuleType
from unittest.mock import MagicMock

import pytest
from alembic.migration import MigrationContext
from alembic.operations import Operations
from sqlalchemy import CheckConstraint, DateTime, Table, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.schema import CreateTable

from app.db import models as _models  # noqa: F401
from app.db.base import Base
from app.modules.biketour.models import OperacaoBikeTour, PendenciaBikeTour

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "migrations/versions/202609130700_bike_tour_idempotency.py"
TABLES = ("operacao_bike_tour", "pendencia_bike_tour")
AUDIT = {
    "created_at",
    "updated_at",
    "deleted_at",
    "created_by",
    "updated_by",
    "deleted_by",
    "versao",
}
FIELDS = {
    "operacao_bike_tour": {
        "id_usuario",
        "operacao",
        "alvo",
        "chave_hash",
        "payload_hash",
        "http_status",
        "resultado",
        "correlation_id",
    },
    "pendencia_bike_tour": {
        "id_evento_bike_tour",
        "id_inscricao_bike_tour",
        "id_operacao_bike_tour",
        "tipo",
        "status",
        "motivo",
        "referencia_tratamento",
    },
}
FROZEN = {
    "202609130100_bike_tour_foundation.py": (
        "17ea083821e3e97ce8af0e30e9ef23b1f4274e6ecbf2f6850bf358cc2e6eb7e0"
    ),
    "202609130200_bike_tour_core.py": (
        "15766127590e950663a32db1d49b50fee7de8df1e404adb2f721d20bc4957cfd"
    ),
    "202609130300_bike_tour_allocations.py": (
        "3949abe1a058e3f63605b5f9de11da3b6851318e6e4a70819f38196d30f96f19"
    ),
    "202609130400_bike_tour_integrity.py": (
        "51bb855d8ffb4d1c2cf119bdf364193dbe1b6489fc51216bdb93dc11c4fc9119"
    ),
    "202609130500_bike_tour_operations.py": (
        "221ea91b8de2513cff0a0000196c07e42bbe0119543941035c909be7a1fc83fc"
    ),
    "202609130600_bike_tour_resource_hardening.py": (
        "062ebf4508d893681e4282dc19becff2c872beee959717497181f5cac08ba331"
    ),
}


@pytest.fixture
def migration() -> ModuleType:
    spec = importlib.util.spec_from_file_location("bt_idempotency", PATH)
    assert spec and spec.loader
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def test_cadeia_e_migrations_congeladas(migration: ModuleType) -> None:
    assert migration.revision == "202609130700"
    assert migration.down_revision == "202609130600"
    assert migration.TABLES == TABLES
    for name, expected in FROZEN.items():
        assert (
            hashlib.sha256((PATH.parent / name).read_bytes().replace(b"\r\n", b"\n")).hexdigest()
            == expected
        )


@pytest.mark.parametrize("model", [OperacaoBikeTour, PendenciaBikeTour])
def test_models_pk_fks_tipos_auditoria_sem_pii(model: type[Base]) -> None:
    table = model.__table__
    assert isinstance(table, Table)
    assert set(table.c.keys()) == FIELDS[table.name] | AUDIT | {f"id_{table.name}"}
    assert table.primary_key.name == f"pk_{table.name}"
    assert list(table.primary_key.columns.keys()) == [f"id_{table.name}"]
    assert table.c[f"id_{table.name}"].identity is not None
    optional = (AUDIT - {"created_at", "versao"}) | {
        "id_inscricao_bike_tour",
        "referencia_tratamento",
    }
    for col in table.c:
        assert col.nullable == (col.name in optional)
        if col.name.endswith("_at"):
            assert isinstance(col.type, DateTime) and col.type.timezone
        if col.name.startswith("id_") and not col.primary_key:
            (fk,) = col.foreign_keys
            target = col.name.removeprefix("id_")
            assert fk.target_fullname == f"{target}.{col.name}"
            assert fk.constraint and fk.constraint.name == f"fk_{table.name}_{target}"
    assert any(
        isinstance(c, CheckConstraint) and str(c.sqltext) == "versao >= 1"
        for c in table.constraints
    )
    ddl = str(
        CreateTable(table).compile(
            dialect=MigrationContext.configure(dialect_name="postgresql").dialect
        )
    )
    assert "TIMESTAMP WITH TIME ZONE" in ddl


def test_intencao_historica_e_indices_sem_null_ambiguo() -> None:
    table = OperacaoBikeTour.__table__
    assert isinstance(table, Table)
    assert isinstance(table.c.resultado.type, JSONB)
    assert any(
        isinstance(c, UniqueConstraint)
        and tuple(c.columns.keys()) == ("id_usuario", "operacao", "alvo", "chave_hash")
        for c in table.constraints
    )
    pending = PendenciaBikeTour.__table__
    assert isinstance(pending, Table)
    indexes = [i for i in pending.indexes if i.unique]
    assert len(indexes) == 2
    assert {str(i.dialect_options["postgresql"]["where"]) for i in indexes} == {
        "id_inscricao_bike_tour IS NULL",
        "id_inscricao_bike_tour IS NOT NULL",
    }
    assert all("deleted_at" not in str(i.dialect_options["postgresql"]["where"]) for i in indexes)


def test_ddl_completo_e_downgrade_somente_delta(
    migration: ModuleType, monkeypatch: pytest.MonkeyPatch
) -> None:
    monkeypatch.setattr(migration, "_validate_prerequisites", lambda: None)
    monkeypatch.setattr(migration, "_validate_created_tables", lambda: None)
    output = StringIO()
    context = MigrationContext.configure(
        dialect_name="postgresql",
        opts={"as_sql": True, "output_buffer": output, "target_metadata": Base.metadata},
    )
    with Operations.context(context):
        migration.upgrade()
    sql = output.getvalue()
    assert sql.count("CREATE TABLE public.") == 2
    assert sql.count("CREATE TRIGGER ") == 4
    for table in TABLES:
        assert f"CONSTRAINT pk_{table} PRIMARY KEY (id_{table})" in sql
        for column in FIELDS[table] | AUDIT | {f"id_{table}"}:
            assert f"COMMENT ON COLUMN public.{table}.{column}" in sql
        assert f"CONSTRAINT ck_{table}_versao_positiva CHECK (versao >= 1)" in sql
    assert "JSONB NOT NULL" in sql and "UUID NOT NULL" in sql
    assert "WHERE id_inscricao_bike_tour IS NULL" in sql
    assert "CREATE EXTENSION" not in sql and "ALTER TABLE public.usuario" not in sql
    output.seek(0)
    output.truncate()
    with Operations.context(context):
        migration.downgrade()
    assert output.getvalue().split() == [
        "DROP",
        "TABLE",
        "public.pendencia_bike_tour;",
        "DROP",
        "TABLE",
        "public.operacao_bike_tour;",
    ]


@pytest.mark.parametrize("missing", range(5))
def test_prerequisito_ausente_nao_cria_delta(
    migration: ModuleType, monkeypatch: pytest.MonkeyPatch, missing: int
) -> None:
    operations = MagicMock()
    operations.get_bind.return_value.execute.return_value.scalar_one.side_effect = [
        True
    ] * missing + [False]
    monkeypatch.setattr(migration, "op", operations)
    with pytest.raises(RuntimeError, match="Prerequisito Bike Tour"):
        migration.upgrade()
    operations.create_table.assert_not_called()


@pytest.mark.parametrize("missing", [0, 1])
def test_auditoria_incompleta_rejeitada(
    migration: ModuleType, monkeypatch: pytest.MonkeyPatch, missing: int
) -> None:
    operations = MagicMock()
    operations.get_bind.return_value.execute.return_value.scalar_one.side_effect = [2] * missing + [
        1
    ]
    monkeypatch.setattr(migration, "op", operations)
    with pytest.raises(RuntimeError, match="Auditoria Bike Tour incompleta"):
        migration._validate_created_tables()
