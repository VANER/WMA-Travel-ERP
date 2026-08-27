"""Cria recuperacao de credenciais e trilha de eventos de seguranca.

Objetos: public.recuperacao_credencial e public.evento_seguranca.
Dependencias: usuario, funcoes de auditoria e revision RBAC.
Rollback: remove apenas os dois objetos desta revision.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "202608252330"
down_revision: str | Sequence[str] | None = "202608252300"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        """
        DO $$ BEGIN
            IF to_regclass('public.usuario') IS NULL THEN
                RAISE EXCEPTION 'migration requer public.usuario';
            END IF;
        END $$;
        """
    )
    op.create_table(
        "recuperacao_credencial",
        sa.Column("id_recuperacao", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("id_usuario", sa.Integer(), nullable=False),
        sa.Column("token_hash", sa.String(64), nullable=False),
        sa.Column("data_expiracao", sa.DateTime(), nullable=False),
        sa.Column("utilizado_em", sa.DateTime(), nullable=True),
        sa.Column(
            "created_at", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False
        ),
        sa.Column("updated_at", sa.DateTime(), nullable=True),
        sa.Column("deleted_at", sa.DateTime(), nullable=True),
        sa.Column("created_by", sa.String(100), nullable=True),
        sa.Column("updated_by", sa.String(100), nullable=True),
        sa.Column("deleted_by", sa.String(100), nullable=True),
        sa.Column("versao", sa.Integer(), server_default=sa.text("1"), nullable=False),
        sa.CheckConstraint(
            "char_length(token_hash) = 64", name="ck_recuperacao_credencial_token_hash"
        ),
        sa.ForeignKeyConstraint(
            ["id_usuario"], ["usuario.id_usuario"], name="fk_recuperacao_credencial_usuario"
        ),
        sa.PrimaryKeyConstraint("id_recuperacao", name="pk_recuperacao_credencial"),
        sa.UniqueConstraint("token_hash", name="uq_recuperacao_credencial_token_hash"),
        comment="Solicitacoes de uso unico para recuperacao de credenciais",
    )
    op.create_index(
        "idx_recuperacao_credencial_id_usuario", "recuperacao_credencial", ["id_usuario"]
    )
    op.create_index(
        "idx_recuperacao_credencial_data_expiracao",
        "recuperacao_credencial",
        ["data_expiracao"],
    )
    op.execute(
        "CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE "
        "ON public.recuperacao_credencial FOR EACH ROW "
        "EXECUTE FUNCTION public.fn_atualiza_updated_at()"
    )
    op.execute(
        "CREATE TRIGGER trg_log_auditoria AFTER INSERT OR UPDATE OR DELETE "
        "ON public.recuperacao_credencial FOR EACH ROW "
        "EXECUTE FUNCTION public.fn_log_auditoria()"
    )
    op.create_table(
        "evento_seguranca",
        sa.Column("id_evento", postgresql.UUID(as_uuid=True), nullable=False),
        sa.Column("codigo", sa.String(50), nullable=False),
        sa.Column("resultado", sa.String(20), nullable=False),
        sa.Column("id_usuario", sa.Integer(), nullable=True),
        sa.Column("id_sessao", postgresql.UUID(as_uuid=True), nullable=True),
        sa.Column("endereco_ip", sa.String(45), nullable=True),
        sa.Column("agente_usuario", sa.String(255), nullable=True),
        sa.Column(
            "detalhes", postgresql.JSONB(), server_default=sa.text("'{}'::jsonb"), nullable=False
        ),
        sa.Column(
            "created_at", sa.DateTime(), server_default=sa.text("CURRENT_TIMESTAMP"), nullable=False
        ),
        sa.ForeignKeyConstraint(
            ["id_usuario"], ["usuario.id_usuario"], name="fk_evento_seguranca_usuario"
        ),
        sa.PrimaryKeyConstraint("id_evento", name="pk_evento_seguranca"),
        comment="Trilha de eventos operacionais de seguranca",
    )
    op.create_index("idx_evento_seguranca_codigo", "evento_seguranca", ["codigo"])
    op.create_index("idx_evento_seguranca_created_at", "evento_seguranca", ["created_at"])


def downgrade() -> None:
    op.drop_index("idx_evento_seguranca_created_at", table_name="evento_seguranca")
    op.drop_index("idx_evento_seguranca_codigo", table_name="evento_seguranca")
    op.drop_table("evento_seguranca")
    op.execute("DROP TRIGGER IF EXISTS trg_log_auditoria ON public.recuperacao_credencial")
    op.execute("DROP TRIGGER IF EXISTS trg_atualiza_updated_at ON public.recuperacao_credencial")
    op.drop_index("idx_recuperacao_credencial_data_expiracao", table_name="recuperacao_credencial")
    op.drop_index("idx_recuperacao_credencial_id_usuario", table_name="recuperacao_credencial")
    op.drop_table("recuperacao_credencial")
