"""Contrato estrutural de inscricao e alocacao Bike Tour."""

from typing import cast

from sqlalchemy import CheckConstraint, Index, Table, UniqueConstraint

from app.modules.biketour.models import (
    AlocacaoRecursoBikeTour,
    InscricaoBikeTour,
)


def _checks(model: type[object]) -> str:
    table = model.__table__  # type: ignore[attr-defined]

    return " ".join(
        str(item.sqltext) for item in table.constraints if isinstance(item, CheckConstraint)
    )


def _uniques(model: type[object]) -> set[tuple[str, ...]]:
    table = model.__table__  # type: ignore[attr-defined]

    return {
        tuple(column.name for column in item.columns)
        for item in table.constraints
        if isinstance(item, UniqueConstraint)
    }


def _indexes(model: type[object]) -> set[tuple[str, ...]]:
    table = model.__table__  # type: ignore[attr-defined]

    return {
        tuple(column.name for column in item.columns)
        for item in table.indexes
        if isinstance(item, Index)
    }


def test_inscricao_tem_identidade_canonica() -> None:
    table = cast(Table, InscricaoBikeTour.__table__)

    assert table.name == "inscricao_bike_tour"

    assert (
        "id_evento_bike_tour",
        "id_passageiro",
    ) in _uniques(InscricaoBikeTour)


def test_inscricao_tem_fks_explicitas() -> None:
    table = InscricaoBikeTour.__table__

    expected = {
        "id_evento_bike_tour": ("evento_bike_tour.id_evento_bike_tour"),
        "id_reserva": "reserva.id_reserva",
        "id_passageiro": ("passageiro_reserva.id_passageiro"),
    }

    for column, target in expected.items():
        fk = next(iter(table.c[column].foreign_keys))
        assert fk.target_fullname == target


def test_inscricao_estados_fechados() -> None:
    checks = _checks(InscricaoBikeTour)

    for status in (
        "PENDENTE",
        "CONFIRMADA",
        "PRESENTE",
        "CONCLUIDA",
        "CANCELADA",
        "EXPIRADA",
        "NO_SHOW",
    ):
        assert status in checks


def test_inscricao_tem_indices_operacionais() -> None:
    indexes = _indexes(InscricaoBikeTour)

    assert (
        "id_evento_bike_tour",
        "status",
    ) in indexes

    assert ("id_reserva",) in indexes


def test_alocacao_tem_fks_explicitas() -> None:
    table = AlocacaoRecursoBikeTour.__table__

    expected = {
        "id_evento_bike_tour": ("evento_bike_tour.id_evento_bike_tour"),
        "id_inscricao_bike_tour": ("inscricao_bike_tour.id_inscricao_bike_tour"),
        "id_recurso_bike_tour": ("recurso_bike_tour.id_recurso_bike_tour"),
    }

    for column, target in expected.items():
        fk = next(iter(table.c[column].foreign_keys))
        assert fk.target_fullname == target

    assert table.c.id_inscricao_bike_tour.nullable is True


def test_alocacao_tem_intervalo_positivo() -> None:
    checks = _checks(AlocacaoRecursoBikeTour)

    assert "inicio < fim" in checks


def test_alocacao_tem_estados_fechados() -> None:
    checks = _checks(AlocacaoRecursoBikeTour)

    for status in (
        "BLOQUEADA",
        "CONFIRMADA",
        "EXPIRADA",
        "LIBERADA",
    ):
        assert status in checks
    assert "CANCELADA" not in checks


def test_alocacao_expiracao_so_em_bloqueio() -> None:
    checks = _checks(AlocacaoRecursoBikeTour)

    assert "status = 'BLOQUEADA'" in checks
    assert "expira_em IS NOT NULL" in checks
    assert "status <> 'BLOQUEADA'" in checks
    assert "expira_em IS NULL" in checks


def test_alocacao_tem_indices_operacionais() -> None:
    indexes = _indexes(AlocacaoRecursoBikeTour)

    assert (
        "id_evento_bike_tour",
        "status",
        "expira_em",
    ) in indexes

    assert ("id_inscricao_bike_tour",) in indexes
    assert ("id_recurso_bike_tour",) in indexes


def test_entidades_tem_auditoria_e_versao() -> None:
    for model in (
        InscricaoBikeTour,
        AlocacaoRecursoBikeTour,
    ):
        columns = model.__table__.c

        for column in (
            "created_at",
            "updated_at",
            "deleted_at",
            "created_by",
            "updated_by",
            "deleted_by",
            "versao",
        ):
            assert column in columns

        assert columns.versao.nullable is False
