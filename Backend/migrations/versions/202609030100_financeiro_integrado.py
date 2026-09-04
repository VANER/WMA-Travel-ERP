"""Integra rastreabilidade e governanca ao Financeiro F1-FIN certificado."""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "202609030100"
down_revision: str | Sequence[str] | None = "202608310100"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute("""DO $$ BEGIN
      IF to_regclass('financeiro.lancamento') IS NULL
         OR to_regclass('financeiro.transferencia') IS NULL
         OR to_regclass('financeiro.depreciacao_ativo') IS NULL
         OR to_regclass('public.venda') IS NULL THEN
        RAISE EXCEPTION 'migration requer baselines Financeira e Comercial certificadas';
      END IF;
      IF EXISTS (SELECT 1 FROM financeiro.lancamento_parcela GROUP BY id_lancamento,
          numero_parcela HAVING count(*) > 1) OR EXISTS (SELECT 1 FROM
          financeiro.conciliacao_bancaria GROUP BY id_movimento HAVING count(*) > 1) THEN
        RAISE EXCEPTION 'duplicidades impedem constraints financeiras';
      END IF;
    END $$;""")
    op.create_table(
        "periodo_financeiro",
        sa.Column("id_periodo_financeiro", sa.Integer(), sa.Identity(), nullable=False),
        sa.Column("competencia", sa.Date(), nullable=False, comment="Primeiro dia do mes."),
        sa.Column("fechado", sa.Boolean(), server_default=sa.text("false"), nullable=False),
        sa.Column("fechado_em", sa.DateTime()),
        sa.Column(
            "created_at", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False
        ),
        sa.Column("updated_at", sa.DateTime()),
        sa.Column("deleted_at", sa.DateTime()),
        sa.Column("created_by", sa.Integer()),
        sa.Column("updated_by", sa.Integer()),
        sa.Column("deleted_by", sa.Integer()),
        sa.Column("versao", sa.Integer(), server_default=sa.text("1"), nullable=False),
        sa.CheckConstraint(
            "competencia = date_trunc('month', competencia)::date",
            name="ck_periodo_financeiro_competencia",
        ),
        sa.PrimaryKeyConstraint("id_periodo_financeiro", name="pk_periodo_financeiro"),
        sa.UniqueConstraint("competencia", name="uq_periodo_financeiro_competencia"),
        schema="financeiro",
        comment="Fechamentos mensais do Financeiro",
    )
    op.execute(
        "CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON financeiro.periodo_financeiro FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at()"  # noqa: E501
    )
    op.execute(
        "CREATE TRIGGER trg_log_auditoria AFTER INSERT OR UPDATE OR DELETE ON financeiro.periodo_financeiro FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria()"  # noqa: E501
    )
    op.add_column(
        "lancamento",
        sa.Column("id_venda_origem", sa.Integer(), comment="Venda de origem."),
        schema="financeiro",
    )
    op.add_column(
        "lancamento",
        sa.Column("chave_idempotencia", sa.String(100), comment="Chave unica da origem."),
        schema="financeiro",
    )
    op.create_foreign_key(
        "fk_lancamento_venda",
        "lancamento",
        "venda",
        ["id_venda_origem"],
        ["id_venda"],
        source_schema="financeiro",
        referent_schema="public",
    )
    op.create_unique_constraint(
        "uq_lancamento_chave_idempotencia",
        "lancamento",
        ["chave_idempotencia"],
        schema="financeiro",
    )
    op.add_column(
        "pagamento",
        sa.Column("chave_idempotencia", sa.String(100), comment="Chave unica da liquidacao."),
        schema="financeiro",
    )
    op.add_column(
        "pagamento",
        sa.Column("id_pagamento_estornado", sa.BigInteger(), comment="Pagamento revertido."),
        schema="financeiro",
    )
    op.create_foreign_key(
        "fk_pagamento_estornado",
        "pagamento",
        "pagamento",
        ["id_pagamento_estornado"],
        ["id_pagamento"],
        source_schema="financeiro",
        referent_schema="financeiro",
    )
    op.create_unique_constraint(
        "uq_pagamento_chave_idempotencia", "pagamento", ["chave_idempotencia"], schema="financeiro"
    )
    op.create_unique_constraint(
        "uq_parcela_lancamento_numero",
        "lancamento_parcela",
        ["id_lancamento", "numero_parcela"],
        schema="financeiro",
    )
    op.create_unique_constraint(
        "uq_conciliacao_movimento", "conciliacao_bancaria", ["id_movimento"], schema="financeiro"
    )
    op.execute("""INSERT INTO public.permissao (codigo,descricao,modulo,created_by) VALUES
      ('FINANCEIRO_VISUALIZAR','Visualizar financeiro','FINANCEIRO','migration'),
      ('FINANCEIRO_OPERAR','Operar financeiro','FINANCEIRO','migration'),
      ('FINANCEIRO_APROVAR','Aprovar financeiro','FINANCEIRO','migration')
      ON CONFLICT (codigo) DO NOTHING;
      INSERT INTO public.perfil_permissao (id_perfil,id_permissao,created_by)
      SELECT p.id_perfil,pe.id_permissao,'migration' FROM public.perfil_acesso p
      CROSS JOIN public.permissao pe WHERE p.codigo='ADMIN' AND pe.codigo LIKE 'FINANCEIRO_%'
      ON CONFLICT (id_perfil,id_permissao) DO NOTHING;""")


def downgrade() -> None:
    op.execute(
        """DELETE FROM public.perfil_permissao WHERE id_permissao IN
        (SELECT id_permissao FROM public.permissao WHERE codigo LIKE 'FINANCEIRO_%')
        AND created_by='migration';
        DELETE FROM public.permissao WHERE codigo LIKE 'FINANCEIRO_%'
        AND created_by='migration';"""
    )
    for name, table in (
        ("uq_conciliacao_movimento", "conciliacao_bancaria"),
        ("uq_parcela_lancamento_numero", "lancamento_parcela"),
        ("uq_pagamento_chave_idempotencia", "pagamento"),
    ):
        op.drop_constraint(name, table, schema="financeiro", type_="unique")
    op.drop_constraint(
        "fk_pagamento_estornado", "pagamento", schema="financeiro", type_="foreignkey"
    )
    op.drop_column("pagamento", "id_pagamento_estornado", schema="financeiro")
    op.drop_column("pagamento", "chave_idempotencia", schema="financeiro")
    op.drop_constraint(
        "uq_lancamento_chave_idempotencia", "lancamento", schema="financeiro", type_="unique"
    )
    op.drop_constraint("fk_lancamento_venda", "lancamento", schema="financeiro", type_="foreignkey")
    op.drop_column("lancamento", "chave_idempotencia", schema="financeiro")
    op.drop_column("lancamento", "id_venda_origem", schema="financeiro")
    op.execute("DROP TRIGGER IF EXISTS trg_log_auditoria ON financeiro.periodo_financeiro")
    op.execute("DROP TRIGGER IF EXISTS trg_atualiza_updated_at ON financeiro.periodo_financeiro")
    op.drop_table("periodo_financeiro", schema="financeiro")
