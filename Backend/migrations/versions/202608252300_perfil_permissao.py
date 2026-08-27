"""Cria a associacao auditavel entre perfis e permissoes.

Objetos: public.perfil_permissao, constraints, indices, comentarios e triggers.
Dependencias: revision de sessoes, perfil_acesso, permissao e funcoes de auditoria da baseline.
Validacoes: pre-condicoes explicitas e FKs para as duas autoridades RBAC.
Rollback: remove somente o objeto criado por esta revision.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "202608252300"
down_revision: str | Sequence[str] | None = "202608252204"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.execute(
        """
        DO $$ BEGIN
            IF to_regclass('public.perfil_acesso') IS NULL
               OR to_regclass('public.permissao') IS NULL THEN
                RAISE EXCEPTION 'migration requer autoridades RBAC da baseline';
            END IF;
            IF to_regprocedure('public.fn_atualiza_updated_at()') IS NULL
               OR to_regprocedure('public.fn_log_auditoria()') IS NULL THEN
                RAISE EXCEPTION 'migration requer funcoes de auditoria da baseline';
            END IF;
        END $$;
        """
    )
    op.create_table(
        "perfil_permissao",
        sa.Column("id_perfil", sa.Integer(), nullable=False, comment="Papel RBAC autorizado."),
        sa.Column(
            "id_permissao", sa.Integer(), nullable=False, comment="Permissao concedida ao papel."
        ),
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
            comment="Instante de criacao do registro.",
        ),
        sa.Column(
            "updated_at", sa.DateTime(), nullable=True, comment="Instante da ultima atualizacao."
        ),
        sa.Column(
            "deleted_at", sa.DateTime(), nullable=True, comment="Instante de exclusao logica."
        ),
        sa.Column("created_by", sa.String(100), nullable=True, comment="Responsavel pela criacao."),
        sa.Column(
            "updated_by",
            sa.String(100),
            nullable=True,
            comment="Responsavel pela ultima atualizacao.",
        ),
        sa.Column(
            "deleted_by",
            sa.String(100),
            nullable=True,
            comment="Responsavel pela exclusao logica.",
        ),
        sa.Column(
            "versao",
            sa.Integer(),
            server_default=sa.text("1"),
            nullable=False,
            comment="Versao otimista incrementada pelo trigger de atualizacao.",
        ),
        sa.ForeignKeyConstraint(
            ["id_perfil"],
            ["perfil_acesso.id_perfil"],
            name="fk_perfil_permissao_perfil_acesso",
        ),
        sa.ForeignKeyConstraint(
            ["id_permissao"],
            ["permissao.id_permissao"],
            name="fk_perfil_permissao_permissao",
        ),
        sa.PrimaryKeyConstraint("id_perfil", "id_permissao", name="pk_perfil_permissao"),
        comment="Associacao auditavel entre papeis RBAC e permissoes granulares",
    )
    op.create_index("idx_perfil_permissao_id_permissao", "perfil_permissao", ["id_permissao"])
    op.execute(
        "CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.perfil_permissao "
        "FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at()"
    )
    op.execute(
        "CREATE TRIGGER trg_log_auditoria AFTER INSERT OR UPDATE OR DELETE "
        "ON public.perfil_permissao FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria()"
    )
    op.execute(
        "COMMENT ON TRIGGER trg_atualiza_updated_at ON public.perfil_permissao IS "
        "'Mantem updated_at e versao da associacao RBAC'"
    )
    op.execute(
        "COMMENT ON TRIGGER trg_log_auditoria ON public.perfil_permissao IS "
        "'Registra alteracoes da associacao RBAC na auditoria corporativa'"
    )
    op.execute(
        """
        INSERT INTO public.permissao (codigo, descricao, modulo, created_by)
        VALUES
            ('CORE_VISUALIZAR', 'Visualizar cadastros do core corporativo', 'CORE', 'migration'),
            ('CORE_CADASTRAR', 'Cadastrar registros no core corporativo', 'CORE', 'migration')
        ON CONFLICT (codigo) DO NOTHING;

        INSERT INTO public.perfil_permissao (id_perfil, id_permissao, created_by)
        SELECT perfil.id_perfil, permissao.id_permissao, 'migration'
          FROM public.perfil_acesso AS perfil
          CROSS JOIN public.permissao AS permissao
         WHERE perfil.codigo = 'ADMIN'
           AND permissao.codigo IN ('CORE_VISUALIZAR', 'CORE_CADASTRAR')
        ON CONFLICT (id_perfil, id_permissao) DO NOTHING;
        """
    )


def downgrade() -> None:
    op.execute(
        """
        DELETE FROM public.perfil_permissao
         WHERE id_permissao IN (
            SELECT id_permissao FROM public.permissao
             WHERE codigo IN ('CORE_VISUALIZAR', 'CORE_CADASTRAR')
         );
        DELETE FROM public.permissao
         WHERE codigo IN ('CORE_VISUALIZAR', 'CORE_CADASTRAR')
           AND created_by = 'migration';
        """
    )
    op.execute("DROP TRIGGER IF EXISTS trg_log_auditoria ON public.perfil_permissao")
    op.execute("DROP TRIGGER IF EXISTS trg_atualiza_updated_at ON public.perfil_permissao")
    op.drop_index("idx_perfil_permissao_id_permissao", table_name="perfil_permissao")
    op.drop_table("perfil_permissao")
