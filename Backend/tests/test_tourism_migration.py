"""Gates estáticos da migration de Turismo 2.6."""

from pathlib import Path

MIGRATION = (
    Path(__file__).parents[1] / "migrations" / "versions" / "202609050100_turismo_integrado.py"
)


def test_tourism_migration_is_additive_linear_and_reversible() -> None:
    source = MIGRATION.read_text(encoding="utf-8")
    assert 'revision: str = "202609050100"' in source
    assert 'down_revision: str | Sequence[str] | None = "202609030100"' in source
    assert "def downgrade() -> None:" in source
    for name in ("saida_turistica", "alocacao_vaga", "reserva_correlacao"):
        assert name in source
    for permission in ("TURISMO_VISUALIZAR", "TURISMO_OPERAR", "TURISMO_GERENCIAR"):
        assert permission in source
