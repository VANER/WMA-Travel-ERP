"""Contrato estatico da migration core Bike Tour."""

from pathlib import Path

MIGRATION = (
    Path(__file__).resolve().parents[1]
    / "migrations"
    / "versions"
    / "202609130200_bike_tour_core.py"
)


def _source() -> str:
    return MIGRATION.read_text(encoding="utf-8")


def test_revision_chain() -> None:
    source = _source()

    assert 'revision: str = "202609130200"' in source
    assert 'down_revision: str | None = "202609130100"' in source


def test_cria_tres_tabelas_core() -> None:
    source = _source()

    for table in (
        "produto_bike_tour",
        "evento_bike_tour",
        "recurso_bike_tour",
    ):
        assert f'"{table}"' in source


def test_produto_referencia_produto_turistico() -> None:
    source = _source()

    assert "produto_turistico.id_produto" in source
    assert "uq_produto_bike_tour_id_produto" in source
    assert "distancia_km > 0" in source
    assert "desnivel_m >= 0" in source


def test_evento_referencia_saida_turistica() -> None:
    source = _source()

    assert "saida_turistica.id_saida" in source
    assert "uq_evento_bike_tour_id_saida" in source
    assert "capacidade BETWEEN 1 AND 1000" in source
    assert "inicio < fim" in source


def test_recurso_tem_origem_unica_sem_fk_inventada() -> None:
    source = _source()

    assert "id_ativo" in source
    assert "id_guia" in source
    assert "id_transporte" in source
    assert "<= 1" in source

    assert "ativo.id_" not in source
    assert "guia.id_" not in source
    assert "transporte.id_" not in source


def test_instala_auditoria_nas_tres_tabelas() -> None:
    source = _source()

    assert "fn_atualiza_updated_at" in source
    assert "fn_log_auditoria" in source
    assert "for table_name in TABLES" in source


def test_downgrade_remove_somente_delta_core() -> None:
    source = _source()

    assert "reversed(TABLES)" in source
    assert "op.drop_table(" in source

    assert 'op.drop_table(\n        "passageiro_reserva"' not in source
    assert "DROP EXTENSION" not in source


def test_nao_instala_btree_gist_antes_da_alocacao() -> None:
    source = _source()

    assert "CREATE EXTENSION" not in source
    assert "btree_gist" not in source
