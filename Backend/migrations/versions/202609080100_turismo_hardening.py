"""Hardening aditivo de Turismo; requer 202609050100.

Constraints validam os dados antes de concluir a transação Alembic.
Rollback remove somente objetos desta revisão; snapshots são perdidos no downgrade.
A aplicação deve ser interrompida antes do downgrade.
"""

from collections.abc import Sequence
from pathlib import Path

from alembic import op

revision: str = "202609080100"
down_revision: str | Sequence[str] | None = "202609050100"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    source = (
        Path(__file__).resolve().parents[3]
        / "Database/migrations/202609080100_turismo_hardening.sql"
    )
    op.execute(source.read_text(encoding="utf-8"))


def downgrade() -> None:
    op.execute("DROP TRIGGER trg_reserva_coerencia ON public.reserva")
    op.execute("DROP TRIGGER trg_alocacao_vaga_coerencia ON public.alocacao_vaga")
    op.execute("DROP FUNCTION public.fn_validar_reserva_alocacao()")
    op.drop_table("reserva_operacao")
    op.drop_index("idx_alocacao_vaga_id_saida_status_expira_em", table_name="alocacao_vaga")
    op.drop_constraint("uq_alocacao_vaga_id_reserva", "alocacao_vaga", type_="unique")
    op.drop_constraint(op.f("ck_reserva_valor_total"), "reserva", type_="check")
    op.drop_constraint(op.f("ck_reserva_quantidade_passageiros"), "reserva", type_="check")
