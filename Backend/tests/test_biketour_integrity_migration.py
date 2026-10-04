"""Static contract tests for Bike Tour deferred integrity migration."""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

MIGRATION = ROOT / "migrations" / "versions" / "202609130400_bike_tour_integrity.py"


def _source() -> str:
    return MIGRATION.read_text(encoding="utf-8")


def test_revision_chain() -> None:
    source = _source()

    assert 'revision: str = "202609130400"' in source
    assert 'down_revision: str | None = "202609130300"' in source


def test_liberada_is_added_only_in_new_delta() -> None:
    source = _source()

    assert "'LIBERADA'" in source
    assert "'EXPIRADA'" in source
    assert "pg_constraint" in source
    assert "v_constraint_name" in source
    assert "v_count <> 1" in source
    assert "ck_alocacao_recurso_bike_tour_status_v2" in source


def test_constraint_triggers_are_deferred() -> None:
    source = _source()

    assert source.count("CREATE CONSTRAINT TRIGGER") == 4
    assert source.count("DEFERRABLE INITIALLY DEFERRED") == 4


def test_event_coherence_is_enforced() -> None:
    source = _source()

    assert "BT_INTEGRITY_ALLOCATION_EVENT_MISMATCH" in source
    assert "a.id_evento_bike_tour" in source
    assert "<> v_evento_inscricao" in source


def test_terminal_states_cannot_keep_active_allocations() -> None:
    source = _source()

    for status in (
        "CONCLUIDA",
        "CANCELADA",
        "EXPIRADA",
        "NO_SHOW",
    ):
        assert f"'{status}'" in source

    assert "BT_INTEGRITY_TERMINAL_WITH_ACTIVE_ALLOCATION" in source


def test_confirmed_requires_one_confirmed_bicycle() -> None:
    source = _source()

    assert "BT_INTEGRITY_CONFIRMED_BICYCLE_COUNT" in source
    assert "r.tipo = 'BICICLETA'" in source
    assert "a.status = 'CONFIRMADA'" in source
    assert "v_bicicletas_confirmadas <> 1" in source


def test_active_allocation_cannot_outlive_inscription() -> None:
    source = _source()

    assert "BT_INTEGRITY_ACTIVE_ALLOCATION_WITHOUT_INSCRIPTION" in source


def test_downgrade_removes_only_integrity_delta() -> None:
    source = _source()

    assert "DROP TRIGGER IF EXISTS" in source
    assert "DROP FUNCTION IF EXISTS" in source

    downgrade = source.split("def downgrade()", maxsplit=1)[1]

    assert "'LIBERADA'" not in downgrade
    assert "'BLOQUEADA'" in downgrade
    assert "'CONFIRMADA'" in downgrade
    assert "'EXPIRADA'" in downgrade


def test_integrity_hardening_covers_allocation_origin_and_resource() -> None:
    source = _source()

    assert "trg_integridade_alocacao_origem_bike_tour" in source
    assert "trg_integridade_recurso_bike_tour" in source

    assert "fn_validar_integridade_alocacao_origem_bike_tour" in source
    assert "fn_validar_integridade_recurso_bike_tour" in source

    assert "OLD.id_inscricao_bike_tour IS DISTINCT FROM" in source
    assert "NEW.id_inscricao_bike_tour" in source

    assert "ON public.recurso_bike_tour" in source
    assert "r.tipo = 'BICICLETA'" in source

    assert source.count("DEFERRABLE INITIALLY DEFERRED") >= 4
