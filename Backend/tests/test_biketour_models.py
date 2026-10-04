"""Testes estruturais do nucleo inicial Bike Tour."""

from typing import cast

from sqlalchemy import CheckConstraint, Integer, Table, UniqueConstraint

from app.db.base import Base
from app.modules.biketour.models import (
    EventoBikeTour,
    ProdutoBikeTour,
    RecursoBikeTour,
)


def _unique_columns(model: type[object]) -> set[tuple[str, ...]]:
    table = model.__table__  # type: ignore[attr-defined]
    return {
        tuple(column.name for column in constraint.columns)
        for constraint in table.constraints
        if isinstance(constraint, UniqueConstraint)
    }


def _check_sql(model: type[object]) -> str:
    table = model.__table__  # type: ignore[attr-defined]
    return " ".join(
        str(constraint.sqltext)
        for constraint in table.constraints
        if isinstance(constraint, CheckConstraint)
    )


def test_produto_especializa_produto_turistico() -> None:
    table = cast(Table, ProdutoBikeTour.__table__)

    assert table.name == "produto_bike_tour"
    assert ("id_produto",) in _unique_columns(ProdutoBikeTour)

    fk = next(iter(table.c.id_produto.foreign_keys))

    assert fk.target_fullname == "produto_turistico.id_produto"


def test_produto_tem_regras_operacionais() -> None:
    checks = _check_sql(ProdutoBikeTour)

    assert "distancia_km > 0" in checks
    assert "desnivel_m >= 0" in checks
    assert "INICIANTE" in checks
    assert "AVANCADO" in checks


def test_evento_especializa_saida_turistica() -> None:
    table = cast(Table, EventoBikeTour.__table__)

    assert table.name == "evento_bike_tour"
    assert ("id_saida",) in _unique_columns(EventoBikeTour)

    fk = next(iter(table.c.id_saida.foreign_keys))

    assert fk.target_fullname == "saida_turistica.id_saida"


def test_evento_tem_periodo_capacidade_e_estados() -> None:
    checks = _check_sql(EventoBikeTour)

    assert "inicio < fim" in checks
    assert "BETWEEN 1 AND 1000" in checks
    assert "PLANEJADO" in checks
    assert "ABERTO" in checks
    assert "EM_EXECUCAO" in checks
    assert "CONCLUIDO" in checks
    assert "CANCELADO" in checks


def test_recurso_tem_codigo_unico() -> None:
    table = cast(Table, RecursoBikeTour.__table__)

    assert table.name == "recurso_bike_tour"
    assert ("codigo",) in _unique_columns(RecursoBikeTour)


def test_recurso_referencia_autoridades_existentes() -> None:
    table = RecursoBikeTour.__table__

    expected = {
        "id_ativo": "ativo_imobilizado.id_ativo",
        "id_guia": "guia_turistico.id_guia",
        "id_transporte": "transporte.id_transporte",
    }

    for column, target in expected.items():
        fk = next(iter(table.c[column].foreign_keys))
        assert fk.target_fullname == target
        assert isinstance(fk.column.type, Integer)
        assert fk.column.table.metadata is not Base.metadata
        assert fk.column.table.name not in Base.metadata.tables


def test_recurso_tem_tipos_e_estados_controlados() -> None:
    checks = _check_sql(RecursoBikeTour)

    for tipo in (
        "BICICLETA",
        "EQUIPAMENTO",
        "GUIA",
        "VEICULO",
    ):
        assert tipo in checks

    for status in (
        "DISPONIVEL",
        "INDISPONIVEL",
        "MANUTENCAO",
        "INATIVO",
    ):
        assert status in checks


def test_recurso_permite_no_maximo_uma_origem() -> None:
    checks = _check_sql(RecursoBikeTour)

    assert "id_ativo IS NOT NULL" in checks
    assert "id_guia IS NOT NULL" in checks
    assert "id_transporte IS NOT NULL" in checks
    assert "<= 1" in checks


def test_core_biketour_tem_auditoria_e_versao() -> None:
    for model in (
        ProdutoBikeTour,
        EventoBikeTour,
        RecursoBikeTour,
    ):
        columns = model.__table__.c

        assert "created_at" in columns
        assert "updated_at" in columns
        assert "deleted_at" in columns
        assert "created_by" in columns
        assert "updated_by" in columns
        assert "deleted_by" in columns
        assert "versao" in columns
        assert columns.versao.nullable is False
