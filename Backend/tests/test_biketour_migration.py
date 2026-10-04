"""Static contract tests for the Bike Tour foundation migration."""

from pathlib import Path

MIGRATION = (
    Path(__file__).parents[1] / "migrations" / "versions" / "202609130100_bike_tour_foundation.py"
)


def _source() -> str:
    return MIGRATION.read_text(encoding="utf-8")


def test_biketour_foundation_revision_chain() -> None:
    source = _source()

    assert 'revision: str = "202609130100"' in source
    assert 'down_revision: str | None = "202609080100"' in source


def test_biketour_foundation_creates_canonical_passenger() -> None:
    source = _source()

    assert '"passageiro_reserva"' in source
    assert '"id_passageiro"' in source
    assert '"id_reserva"' in source
    assert '"ordem"' in source
    assert '"status"' in source

    assert "fk_passageiro_reserva_reserva" in source
    assert "uq_passageiro_reserva_reserva_ordem" in source
    assert "ck_passageiro_reserva_ordem_positiva" in source
    assert "ck_passageiro_reserva_status" in source
    assert "idx_passageiro_reserva_id_reserva" in source


def test_biketour_foundation_installs_explicit_permissions() -> None:
    source = _source()

    for permission in (
        "BIKETOUR_VISUALIZAR",
        "BIKETOUR_OPERAR",
        "BIKETOUR_GERENCIAR",
    ):
        assert permission in source

    assert "'BIKETOUR'" in source
    assert "ON CONFLICT (codigo) DO NOTHING" in source
    assert "ON CONFLICT (id_perfil, id_permissao) DO NOTHING" in source


def test_biketour_foundation_does_not_use_nonexistent_permission_name() -> None:
    source = _source()

    assert "INSERT INTO public.permissao (codigo, nome" not in source


def test_biketour_foundation_uses_audit_triggers() -> None:
    source = _source()

    assert "public.fn_atualiza_updated_at()" in source
    assert "public.fn_log_auditoria()" in source
    assert "trg_atualiza_updated_at" in source
    assert "trg_log_auditoria" in source


def test_biketour_foundation_validates_prerequisites() -> None:
    source = _source()

    for prerequisite in (
        "reserva",
        "perfil_acesso",
        "permissao",
        "perfil_permissao",
    ):
        assert f'"{prerequisite}"' in source


def test_biketour_foundation_downgrade_is_scoped() -> None:
    source = _source()

    downgrade = source.split("def downgrade() -> None:", maxsplit=1)[1]

    assert "pp.created_by = 'migration'" in downgrade
    assert "AND created_by = 'migration'" in downgrade
    assert '_drop_audit_triggers("passageiro_reserva")' in downgrade
    assert 'op.drop_table(\n        "passageiro_reserva"' in downgrade


def test_biketour_foundation_does_not_create_parallel_passenger_domain() -> None:
    source = _source()

    assert "passageiro_bike_tour" not in source
    assert "reserva_bike_tour" not in source
