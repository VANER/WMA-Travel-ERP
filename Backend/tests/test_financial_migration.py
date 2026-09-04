"""Gates estáticos da migration Financeira 2.5."""

from pathlib import Path

MIGRATION = (
    Path(__file__).parents[1] / "migrations" / "versions" / "202609030100_financeiro_integrado.py"
)


def test_financial_migration_is_additive_and_traceable() -> None:
    source = MIGRATION.read_text(encoding="utf-8")

    assert 'revision: str = "202609030100"' in source
    assert 'down_revision: str | Sequence[str] | None = "202608310100"' in source
    assert "migration requer baselines Financeira e Comercial certificadas" in source
    assert "def downgrade() -> None:" in source


def test_financial_migration_covers_capabilities_and_governance() -> None:
    source = MIGRATION.read_text(encoding="utf-8")
    assert '"periodo_financeiro"' in source
    assert "financeiro.transferencia" in source
    assert "financeiro.depreciacao_ativo" in source
    for permission in (
        "FINANCEIRO_VISUALIZAR",
        "FINANCEIRO_OPERAR",
        "FINANCEIRO_APROVAR",
    ):
        assert permission in source
    assert "uq_lancamento_chave_idempotencia" in source
    assert "uq_pagamento_chave_idempotencia" in source
    assert "uq_conciliacao_movimento" in source
