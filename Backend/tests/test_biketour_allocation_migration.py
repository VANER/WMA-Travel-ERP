"""Contrato estatico da migration de inscricao e alocacao."""

from pathlib import Path

MIGRATION = (
    Path(__file__).resolve().parents[1]
    / "migrations"
    / "versions"
    / "202609130300_bike_tour_allocations.py"
)


def _source() -> str:
    return MIGRATION.read_text(encoding="utf-8")


def test_revision_chain() -> None:
    source = _source()

    assert 'revision: str = "202609130300"' in source
    assert 'down_revision: str | None = "202609130200"' in source


def test_cria_tabelas_operacionais() -> None:
    source = _source()

    assert '"inscricao_bike_tour"' in source
    assert '"alocacao_recurso_bike_tour"' in source


def test_inscricao_unica_por_evento_passageiro() -> None:
    source = _source()

    assert ("uq_inscricao_bike_tour_evento_passageiro") in source

    assert "passageiro_reserva.id_passageiro" in source
    assert "reserva.id_reserva" in source


def test_recurso_recebe_fks_reais() -> None:
    source = _source()

    expected = (
        "fk_recurso_bike_tour_ativo_imobilizado",
        "fk_recurso_bike_tour_guia_turistico",
        "fk_recurso_bike_tour_transporte",
    )

    for name in expected:
        assert name in source


def test_instala_btree_gist_se_necessario() -> None:
    source = _source()

    assert "CREATE EXTENSION IF NOT EXISTS btree_gist" in source


def test_exclusao_temporal_canonica() -> None:
    source = _source()

    assert "EXCLUDE USING gist" in source
    assert "id_recurso_bike_tour WITH =" in source

    assert "tstzrange(inicio, fim, '[)') WITH &&" in source

    assert "status IN ('BLOQUEADA', 'CONFIRMADA')" in source


def test_exclusao_nao_usa_relogio() -> None:
    source = _source().lower()

    exclusion = source[
        source.index("exclude using gist") : source.index(
            "_create_audit_triggers(",
            source.index("exclude using gist"),
        )
    ]

    assert "now()" not in exclusion
    assert "current_timestamp" not in exclusion


def test_expiracao_tem_contrato_fechado() -> None:
    source = _source()

    assert "status = 'BLOQUEADA'" in source
    assert "expira_em IS NOT NULL" in source
    assert "status <> 'BLOQUEADA'" in source
    assert "expira_em IS NULL" in source


def test_status_da_alocacao_e_fechado() -> None:
    source = _source()

    marker = "ck_alocacao_recurso_bike_tour_status"

    position = source.index(marker)
    block = source[position - 300 : position + 100]

    assert "BLOQUEADA" in block
    assert "CONFIRMADA" in block
    assert "EXPIRADA" in block
    assert "LIBERADA" not in block
    assert "CANCELADA" not in block


def test_downgrade_nao_remove_extensao() -> None:
    source = _source()

    assert "DROP EXTENSION" not in source
