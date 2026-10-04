"""Contrato fisico A8 das seis tabelas operacionais Bike Tour."""

import pytest
from alembic.migration import MigrationContext
from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Integer,
    Numeric,
    SmallInteger,
    String,
    Table,
    UniqueConstraint,
)
from sqlalchemy.schema import CreateIndex, CreateTable, DefaultClause

from app.db import models as _models  # noqa: F401
from app.db.base import Base
from app.modules.biketour.models import (
    AvaliacaoBikeTour,
    EquipeBikeTour,
    LogisticaBikeTour,
    OcorrenciaBikeTour,
    PassagemBikeTour,
    PontoControleBikeTour,
)

MODELS = (
    EquipeBikeTour,
    LogisticaBikeTour,
    PontoControleBikeTour,
    PassagemBikeTour,
    OcorrenciaBikeTour,
    AvaliacaoBikeTour,
)
AUDIT = {
    "created_at",
    "updated_at",
    "deleted_at",
    "created_by",
    "updated_by",
    "deleted_by",
    "versao",
}
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


@pytest.mark.parametrize("model", MODELS)
def test_colunas_exatas_sem_pii_e_auditoria(model: type[Base]) -> None:
    table = model.__table__
    assert isinstance(table, Table)
    name = table.name
    assert set(table.c.keys()) == BUSINESS[name] | AUDIT | {f"id_{name}"}
    assert table.primary_key.name == f"pk_{name}"
    assert list(table.primary_key.columns.keys()) == [f"id_{name}"]
    assert isinstance(table.c[f"id_{name}"].type, Integer)
    assert table.c[f"id_{name}"].identity is not None
    for column in table.c:
        optional = column.name in AUDIT - {"created_at", "versao"} or (
            name == "ocorrencia_bike_tour" and column.name == "id_inscricao_bike_tour"
        )
        assert column.nullable == optional
    for name in ("created_at", "updated_at", "deleted_at"):
        column_type = table.c[name].type
        assert isinstance(column_type, DateTime)
        assert column_type.timezone
    version_default = table.c.versao.server_default
    created_default = table.c.created_at.server_default
    assert isinstance(version_default, DefaultClause)
    assert isinstance(created_default, DefaultClause)
    assert str(version_default.arg) == "1"
    assert str(created_default.arg) == "CURRENT_TIMESTAMP"
    assert table.comment


@pytest.mark.parametrize("model", MODELS)
def test_fks_unicidades_e_checks_nomeados(model: type[Base]) -> None:
    table = model.__table__
    assert isinstance(table, Table)
    for name in BUSINESS[table.name]:
        if name.startswith("id_"):
            (foreign_key,) = table.c[name].foreign_keys
            target = name.removeprefix("id_")
            assert foreign_key.target_fullname == f"{target}.{name}"
            assert foreign_key.constraint is not None
            assert foreign_key.constraint.name == f"fk_{table.name}_{target}"
            assert foreign_key.ondelete is None
    assert {
        tuple(item.columns.keys())
        for item in table.constraints
        if isinstance(item, UniqueConstraint)
    } == UNIQUES[table.name]
    checks = [item for item in table.constraints if isinstance(item, CheckConstraint)]
    assert any(str(item.sqltext) == "versao >= 1" for item in checks)
    for item in checks:
        assert str(item.name).startswith(f"ck_{table.name}_")
        assert str(item.name).count("ck_") == 1
    # Compilacao de cada tabela usa FKs ja mapeadas, sem criar tabelas legadas ficticias.
    assert f"CREATE TABLE {table.name}" in str(
        CreateTable(table).compile(
            dialect=MigrationContext.configure(dialect_name="postgresql").dialect
        )
    )


def test_tipos_e_indice_parcial_lider() -> None:
    distance = PontoControleBikeTour.__table__.c.distancia_km.type
    assert isinstance(distance, Numeric)
    assert (distance.precision, distance.scale) == (10, 2)
    assert isinstance(AvaliacaoBikeTour.__table__.c.nota.type, SmallInteger)
    instante_type = PassagemBikeTour.__table__.c.instante.type
    assert isinstance(instante_type, DateTime) and instante_type.timezone
    motivo_type = OcorrenciaBikeTour.__table__.c.motivo.type
    assert isinstance(motivo_type, String) and motivo_type.length == 30
    table = EquipeBikeTour.__table__
    assert isinstance(table, Table)
    leader = next(i for i in table.indexes if i.unique)
    sql = str(
        CreateIndex(leader).compile(
            dialect=MigrationContext.configure(dialect_name="postgresql").dialect
        )
    )
    assert "WHERE papel = 'LIDER' AND deleted_at IS NULL" in sql
    assert "now()" not in sql.lower()


@pytest.mark.parametrize("model", MODELS)
def test_indices_cobrem_fks_sem_repetir_unicidades(model: type[Base]) -> None:
    table = model.__table__
    assert isinstance(table, Table)
    uniques = UNIQUES[table.name]
    indexes = {tuple(index.columns.keys()) for index in table.indexes}
    assert not indexes.intersection(uniques)
    for column in table.c:
        if column.foreign_keys:
            assert any(columns[0] == column.name for columns in uniques | indexes)
