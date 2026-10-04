import importlib.util
from io import StringIO
from pathlib import Path
from typing import cast

import pytest
from alembic.migration import MigrationContext
from alembic.operations import Operations
from sqlalchemy import CheckConstraint, Table, UniqueConstraint

from app.db.base import Base
from app.modules.biketour.models import RecursoBikeTour

MIGRATION = (
    Path(__file__).parents[1]
    / "migrations"
    / "versions"
    / "202609130600_bike_tour_resource_hardening.py"
)


def _unique_columns(table: Table) -> set[tuple[str, ...]]:
    return {
        tuple(column.name for column in constraint.columns)
        for constraint in table.constraints
        if isinstance(constraint, UniqueConstraint)
    }


def test_130600_existe() -> None:
    assert MIGRATION.is_file()


def test_modelo_pos_130600_tem_unicidade_historica_das_origens() -> None:
    table = cast(Table, RecursoBikeTour.__table__)
    uniques = _unique_columns(table)

    assert ("id_ativo",) in uniques
    assert ("id_guia",) in uniques
    assert ("id_transporte",) in uniques


def test_modelo_pos_130600_tem_compatibilidade_tipo_origem() -> None:
    table = cast(Table, RecursoBikeTour.__table__)

    checks = {
        str(constraint.sqltext)
        for constraint in table.constraints
        if isinstance(constraint, CheckConstraint)
    }

    sql = "\n".join(checks)

    assert "tipo IN ('BICICLETA', 'EQUIPAMENTO')" in sql
    assert "tipo = 'GUIA'" in sql
    assert "tipo = 'VEICULO'" in sql

    assert "id_guia IS NOT NULL" in sql
    assert "id_transporte IS NOT NULL" in sql


def test_130600_encadeia_exclusivamente_130500() -> None:
    source = MIGRATION.read_text(encoding="utf-8")

    assert 'revision: str = "202609130600"' in source
    assert 'down_revision: str | None = "202609130500"' in source


def test_130600_cria_unicidades_de_origem() -> None:
    source = MIGRATION.read_text(encoding="utf-8")

    expected = (
        "uq_recurso_bike_tour_id_ativo",
        "uq_recurso_bike_tour_id_guia",
        "uq_recurso_bike_tour_id_transporte",
    )

    for constraint in expected:
        assert constraint in source


def test_130600_cria_compatibilidade_tipo_origem(monkeypatch: pytest.MonkeyPatch) -> None:
    source = MIGRATION.read_text(encoding="utf-8")

    assert "ck_recurso_bike_tour_origem_compativel_tipo" in source

    assert "tipo IN ('BICICLETA', 'EQUIPAMENTO')" in source
    assert "tipo = 'GUIA'" in source
    assert "tipo = 'VEICULO'" in source

    # Reproduz a convencao Alembic para detectar prefixo duplicado e truncamento.
    spec = importlib.util.spec_from_file_location("resource_hardening", MIGRATION)
    assert spec and spec.loader
    migration = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(migration)
    monkeypatch.setattr(migration, "_validate_existing_rows", lambda: None)
    output = StringIO()
    context = MigrationContext.configure(
        dialect_name="postgresql",
        opts={
            "as_sql": True,
            "output_buffer": output,
            "target_metadata": Base.metadata,
        },
    )
    with Operations.context(context):
        migration.upgrade()
        migration.downgrade()
    sql = output.getvalue()
    name = "ck_recurso_bike_tour_origem_compativel_tipo"
    assert f"ADD CONSTRAINT {name} CHECK" in sql
    assert f"DROP CONSTRAINT {name};" in sql
    assert "ck_recurso_bike_tour_ck_" not in sql


def test_130600_nao_exige_patrimonio_para_bicicleta_e_equipamento() -> None:
    source = MIGRATION.read_text(encoding="utf-8")

    marker = "tipo IN ('BICICLETA', 'EQUIPAMENTO')"

    assert marker in source

    # A classificação patrimonial não é autoridade do Bike Tour.
    assert "id_ativo IS NOT NULL" not in (source[source.index(marker) : source.index(marker) + 250])


def test_130600_nao_implementa_operacao_ou_pendencia() -> None:
    source = MIGRATION.read_text(encoding="utf-8")

    assert "operacao_bike_tour" not in source
    assert "pendencia_bike_tour" not in source
