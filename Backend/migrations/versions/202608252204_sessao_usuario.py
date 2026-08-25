"""Cria a persistencia de sessoes humanas renovaveis.

Objetos: public.sessao_usuario, constraints, indices, comentarios e triggers.
Dependencias: public.usuario, public.fn_atualiza_updated_at e public.fn_log_auditoria.
Pre-validacao: interrompe se qualquer dependencia certificada estiver ausente.
Pos-validacao: constraints impedem hash duplicado e sessao substituta inconsistente.
Rollback: remove triggers, indices e tabela, sem alterar a baseline historica.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "202608252204"
down_revision: str | Sequence[str] | None = None
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        """
        DO $$
        BEGIN
            IF to_regclass('public.usuario') IS NULL THEN
                RAISE EXCEPTION 'migration requer a baseline certificada: public.usuario ausente';
            END IF;
            IF to_regprocedure('public.fn_atualiza_updated_at()') IS NULL THEN
                RAISE EXCEPTION 'migration requer public.fn_atualiza_updated_at()';
            END IF;
            IF to_regprocedure('public.fn_log_auditoria()') IS NULL THEN
                RAISE EXCEPTION 'migration requer public.fn_log_auditoria()';
            END IF;
        END $$;
        """
    )
    op.create_table(
        "sessao_usuario",
        sa.Column("id_sessao", sa.UUID(), nullable=False, comment="Identificador opaco da sessão."),
        sa.Column(
            "id_usuario", sa.Integer(), nullable=False, comment="Identidade humana da sessão."
        ),
        sa.Column(
            "id_familia", sa.UUID(), nullable=False, comment="Família usada na rotação e revogação."
        ),
        sa.Column(
            "token_refresh_hash",
            sa.String(length=64),
            nullable=False,
            comment="SHA-256 hexadecimal do refresh token opaco.",
        ),
        sa.Column(
            "data_expiracao",
            sa.DateTime(),
            nullable=False,
            comment="Expiração UTC da capacidade de renovação.",
        ),
        sa.Column(
            "revogado_em", sa.DateTime(), nullable=True, comment="Instante UTC da revogação."
        ),
        sa.Column(
            "id_sessao_substituta",
            sa.UUID(),
            nullable=True,
            comment="Sessão sucessora criada pela rotação.",
        ),
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
            comment="Instante de criação do registro.",
        ),
        sa.Column(
            "updated_at", sa.DateTime(), nullable=True, comment="Instante da última atualização."
        ),
        sa.Column(
            "deleted_at", sa.DateTime(), nullable=True, comment="Instante de exclusão lógica."
        ),
        sa.Column(
            "created_by", sa.String(length=100), nullable=True, comment="Responsável pela criação."
        ),
        sa.Column(
            "updated_by",
            sa.String(length=100),
            nullable=True,
            comment="Responsável pela última atualização.",
        ),
        sa.Column(
            "deleted_by",
            sa.String(length=100),
            nullable=True,
            comment="Responsável pela exclusão lógica.",
        ),
        sa.Column(
            "versao",
            sa.Integer(),
            server_default=sa.text("1"),
            nullable=False,
            comment="Versão otimista incrementada pelo trigger de atualização.",
        ),
        sa.CheckConstraint(
            "char_length(token_refresh_hash) = 64",
            name="ck_sessao_usuario_token_refresh_hash",
        ),
        sa.ForeignKeyConstraint(
            ["id_sessao_substituta"],
            ["sessao_usuario.id_sessao"],
            name="fk_sessao_usuario_sessao_substituta",
        ),
        sa.ForeignKeyConstraint(
            ["id_usuario"], ["usuario.id_usuario"], name="fk_sessao_usuario_usuario"
        ),
        sa.PrimaryKeyConstraint("id_sessao", name="pk_sessao_usuario"),
        sa.UniqueConstraint("token_refresh_hash", name="uq_sessao_usuario_token_refresh_hash"),
        comment="Sessões renováveis das identidades humanas autenticadas",
    )
    op.create_index("idx_sessao_usuario_data_expiracao", "sessao_usuario", ["data_expiracao"])
    op.create_index("idx_sessao_usuario_id_familia", "sessao_usuario", ["id_familia"])
    op.create_index("idx_sessao_usuario_id_usuario", "sessao_usuario", ["id_usuario"])
    op.execute(
        "CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.sessao_usuario "
        "FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at()"
    )
    op.execute(
        "CREATE TRIGGER trg_log_auditoria AFTER INSERT OR UPDATE OR DELETE "
        "ON public.sessao_usuario FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria()"
    )
    op.execute(
        "COMMENT ON TRIGGER trg_atualiza_updated_at ON public.sessao_usuario IS "
        "'Atualiza updated_at e versao em cada alteração da sessão.'"
    )
    op.execute(
        "COMMENT ON TRIGGER trg_log_auditoria ON public.sessao_usuario IS "
        "'Registra inserções, alterações e exclusões da sessão na auditoria da baseline.'"
    )


def downgrade() -> None:
    op.execute("DROP TRIGGER IF EXISTS trg_log_auditoria ON public.sessao_usuario")
    op.execute("DROP TRIGGER IF EXISTS trg_atualiza_updated_at ON public.sessao_usuario")
    op.drop_index("idx_sessao_usuario_id_usuario", table_name="sessao_usuario")
    op.drop_index("idx_sessao_usuario_id_familia", table_name="sessao_usuario")
    op.drop_index("idx_sessao_usuario_data_expiracao", table_name="sessao_usuario")
    op.drop_table("sessao_usuario")
