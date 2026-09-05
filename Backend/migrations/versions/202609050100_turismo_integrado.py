"""Integra saída, vagas e correlação do domínio Turismo."""

from collections.abc import Sequence
from typing import Any

import sqlalchemy as sa
from alembic import op

revision: str = "202609050100"
down_revision: str | Sequence[str] | None = "202609030100"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _audit_columns() -> tuple[sa.Column[Any], ...]:
    return (
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
        ),
        sa.Column("updated_at", sa.DateTime()),
        sa.Column("deleted_at", sa.DateTime()),
        sa.Column("created_by", sa.String(100)),
        sa.Column("updated_by", sa.String(100)),
        sa.Column("deleted_by", sa.String(100)),
        sa.Column("versao", sa.Integer(), server_default=sa.text("1"), nullable=False),
    )


def _triggers(table: str) -> None:
    op.execute(
        f"CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.{table} "
        "FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at()"
    )
    op.execute(
        f"CREATE TRIGGER trg_log_auditoria AFTER INSERT OR UPDATE OR DELETE ON public.{table} "
        "FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria()"
    )


def upgrade() -> None:
    op.execute("""DO $$ BEGIN
      IF to_regclass('public.pacote_viagem') IS NULL
         OR to_regclass('public.reserva') IS NULL
         OR to_regclass('public.produto_turistico') IS NULL
         OR to_regclass('public.venda') IS NULL THEN
        RAISE EXCEPTION 'migration requer baselines Turismo e Comercial certificadas';
      END IF;
    END $$;""")
    op.create_table(
        "saida_turistica",
        sa.Column("id_saida", sa.Integer(), sa.Identity(), nullable=False),
        sa.Column("id_pacote", sa.Integer(), nullable=False),
        sa.Column("codigo", sa.String(30), nullable=False),
        sa.Column("data_inicio", sa.Date(), nullable=False),
        sa.Column("data_fim", sa.Date(), nullable=False),
        sa.Column("capacidade", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(20), server_default="PLANEJADA", nullable=False),
        *_audit_columns(),
        sa.CheckConstraint("data_fim >= data_inicio", name="ck_saida_turistica_periodo"),
        sa.CheckConstraint("capacidade >= 0", name="ck_saida_turistica_capacidade"),
        sa.CheckConstraint(
            "status IN ('PLANEJADA','ABERTA','ESGOTADA','EM_EXECUCAO','CONCLUIDA','CANCELADA')",
            name="ck_saida_turistica_status",
        ),
        sa.ForeignKeyConstraint(
            ["id_pacote"], ["public.pacote_viagem.id_pacote"], name="fk_saida_turistica_pacote"
        ),
        sa.PrimaryKeyConstraint("id_saida", name="pk_saida_turistica"),
        sa.UniqueConstraint("codigo", name="uq_saida_turistica_codigo"),
        comment="Execucao operacional datada de um pacote turistico.",
    )
    op.add_column("produto_turistico", sa.Column("id_destino", sa.Integer()))
    op.create_foreign_key(
        "fk_produto_turistico_destino",
        "produto_turistico",
        "destino",
        ["id_destino"],
        ["id_destino"],
    )
    op.add_column("reserva", sa.Column("id_saida", sa.Integer()))
    op.create_foreign_key(
        "fk_reserva_saida_turistica",
        "reserva",
        "saida_turistica",
        ["id_saida"],
        ["id_saida"],
    )
    op.create_table(
        "alocacao_vaga",
        sa.Column("id_alocacao", sa.Integer(), sa.Identity(), nullable=False),
        sa.Column("id_saida", sa.Integer(), nullable=False),
        sa.Column("id_reserva", sa.Integer()),
        sa.Column("chave_idempotencia", sa.String(100), nullable=False),
        sa.Column("quantidade", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(20), nullable=False),
        sa.Column("expira_em", sa.DateTime()),
        *_audit_columns(),
        sa.CheckConstraint("quantidade > 0", name="ck_alocacao_vaga_quantidade"),
        sa.CheckConstraint(
            "status IN ('BLOQUEADA','RESERVADA','EXPIRADA','LIBERADA')",
            name="ck_alocacao_vaga_status",
        ),
        sa.ForeignKeyConstraint(
            ["id_saida"], ["public.saida_turistica.id_saida"], name="fk_alocacao_vaga_saida"
        ),
        sa.ForeignKeyConstraint(
            ["id_reserva"], ["public.reserva.id_reserva"], name="fk_alocacao_vaga_reserva"
        ),
        sa.PrimaryKeyConstraint("id_alocacao", name="pk_alocacao_vaga"),
        sa.UniqueConstraint("chave_idempotencia", name="uq_alocacao_vaga_chave"),
        comment="Razao transacional de vagas por saida turistica.",
    )
    op.create_table(
        "reserva_correlacao",
        sa.Column("id_correlacao", sa.Integer(), sa.Identity(), nullable=False),
        sa.Column("id_reserva", sa.Integer(), nullable=False),
        sa.Column("id_venda", sa.Integer()),
        sa.Column("id_item_venda", sa.Integer()),
        sa.Column("id_contrato", sa.Integer()),
        sa.Column("chave_idempotencia", sa.String(100), nullable=False),
        *_audit_columns(),
        sa.ForeignKeyConstraint(
            ["id_reserva"], ["public.reserva.id_reserva"], name="fk_reserva_correlacao_reserva"
        ),
        sa.ForeignKeyConstraint(
            ["id_venda"], ["public.venda.id_venda"], name="fk_reserva_correlacao_venda"
        ),
        sa.ForeignKeyConstraint(
            ["id_item_venda"], ["public.item_venda.id_item"], name="fk_reserva_correlacao_item"
        ),
        sa.ForeignKeyConstraint(
            ["id_contrato"], ["public.contrato.id_contrato"], name="fk_reserva_correlacao_contrato"
        ),
        sa.PrimaryKeyConstraint("id_correlacao", name="pk_reserva_correlacao"),
        sa.UniqueConstraint("id_reserva", name="uq_reserva_correlacao_reserva"),
        sa.UniqueConstraint("chave_idempotencia", name="uq_reserva_correlacao_chave"),
        comment="Correlacao idempotente entre Reserva e Comercial.",
    )
    for table in ("saida_turistica", "alocacao_vaga", "reserva_correlacao"):
        _triggers(table)
    op.execute("""INSERT INTO public.permissao (codigo,descricao,modulo,created_by) VALUES
      ('TURISMO_VISUALIZAR','Visualizar turismo','TURISMO','migration'),
      ('TURISMO_OPERAR','Operar reservas e viagens','TURISMO','migration'),
      ('TURISMO_GERENCIAR','Gerenciar turismo','TURISMO','migration')
      ON CONFLICT (codigo) DO NOTHING;
      INSERT INTO public.perfil_permissao (id_perfil,id_permissao,created_by)
      SELECT p.id_perfil,pe.id_permissao,'migration' FROM public.perfil_acesso p
      CROSS JOIN public.permissao pe WHERE p.codigo='ADMIN' AND pe.codigo LIKE 'TURISMO_%'
      ON CONFLICT (id_perfil,id_permissao) DO NOTHING;""")


def downgrade() -> None:
    op.execute("""DELETE FROM public.perfil_permissao WHERE id_permissao IN
      (SELECT id_permissao FROM public.permissao WHERE codigo LIKE 'TURISMO_%')
      AND created_by='migration';
      DELETE FROM public.permissao WHERE codigo LIKE 'TURISMO_%' AND created_by='migration';""")
    for table in ("reserva_correlacao", "alocacao_vaga", "saida_turistica"):
        op.execute(f"DROP TRIGGER IF EXISTS trg_log_auditoria ON public.{table}")
        op.execute(f"DROP TRIGGER IF EXISTS trg_atualiza_updated_at ON public.{table}")
    op.drop_table("reserva_correlacao")
    op.drop_table("alocacao_vaga")
    op.drop_constraint("fk_reserva_saida_turistica", "reserva", type_="foreignkey")
    op.drop_column("reserva", "id_saida")
    op.drop_constraint("fk_produto_turistico_destino", "produto_turistico", type_="foreignkey")
    op.drop_column("produto_turistico", "id_destino")
    op.drop_table("saida_turistica")
