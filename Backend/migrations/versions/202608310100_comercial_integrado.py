"""Completa o modelo transacional do modulo Comercial.

Objetos: operadora, oportunidade, proposta, item_proposta, condicao_comercial,
vinculos de conversao e permissoes RBAC.
Dependencias: baseline Comercial, Core Corporativo e funcoes de auditoria.
Pre-validacao: interrompe diante de clientes duplicados por pessoa.
Rollback: remove somente objetos e vinculos adicionados nesta revision.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = "202608310100"
down_revision: str | Sequence[str] | None = "202608262200"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def _audit_columns() -> list[sa.Column[object]]:
    return [
        sa.Column(
            "created_at",
            sa.DateTime(),
            server_default=sa.text("CURRENT_TIMESTAMP"),
            nullable=False,
            comment="Instante de criacao do registro.",
        ),
        sa.Column("updated_at", sa.DateTime(), nullable=True, comment="Ultima atualizacao."),
        sa.Column("deleted_at", sa.DateTime(), nullable=True, comment="Exclusao logica."),
        sa.Column("created_by", sa.String(100), nullable=True, comment="Autor da criacao."),
        sa.Column("updated_by", sa.String(100), nullable=True, comment="Autor da atualizacao."),
        sa.Column("deleted_by", sa.String(100), nullable=True, comment="Autor da exclusao."),
        sa.Column(
            "versao",
            sa.Integer(),
            server_default=sa.text("1"),
            nullable=False,
            comment="Versao otimista do registro.",
        ),
    ]


def _create_audit_triggers(table_name: str) -> None:
    op.execute(
        f"CREATE TRIGGER trg_atualiza_updated_at BEFORE UPDATE ON public.{table_name} "
        "FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at()"
    )
    op.execute(
        f"CREATE TRIGGER trg_log_auditoria AFTER INSERT OR UPDATE OR DELETE ON public.{table_name} "
        "FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria()"
    )


def upgrade() -> None:
    op.execute(
        """
        DO $$ BEGIN
            IF to_regclass('public.cliente') IS NULL
               OR to_regclass('public.fornecedor') IS NULL
               OR to_regclass('public.lead') IS NULL
               OR to_regclass('public.venda') IS NULL
               OR to_regclass('public.contrato') IS NULL THEN
                RAISE EXCEPTION 'migration requer a baseline Comercial certificada';
            END IF;
            IF to_regprocedure('public.fn_atualiza_updated_at()') IS NULL
               OR to_regprocedure('public.fn_log_auditoria()') IS NULL THEN
                RAISE EXCEPTION 'migration requer funcoes de auditoria da baseline';
            END IF;
            IF EXISTS (
                SELECT 1 FROM public.cliente
                 GROUP BY id_pessoa HAVING count(*) > 1
            ) THEN
                RAISE EXCEPTION 'clientes duplicados por pessoa impedem unicidade comercial';
            END IF;
        END $$;
        """
    )
    op.create_unique_constraint("uq_cliente_id_pessoa", "cliente", ["id_pessoa"])
    op.add_column(
        "lead",
        sa.Column("id_cliente", sa.Integer(), nullable=True, comment="Cliente convertido."),
    )
    op.create_foreign_key("fk_lead_cliente", "lead", "cliente", ["id_cliente"], ["id_cliente"])
    op.create_index("idx_lead_id_cliente", "lead", ["id_cliente"])

    op.create_table(
        "operadora",
        sa.Column("id_operadora", sa.Integer(), sa.Identity(), nullable=False),
        sa.Column("id_fornecedor", sa.Integer(), nullable=False, comment="Fornecedor corporativo."),
        sa.Column("codigo", sa.String(30), nullable=False, comment="Codigo comercial unico."),
        sa.Column("ativo", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        *_audit_columns(),
        sa.ForeignKeyConstraint(
            ["id_fornecedor"], ["fornecedor.id_fornecedor"], name="fk_operadora_fornecedor"
        ),
        sa.PrimaryKeyConstraint("id_operadora", name="pk_operadora"),
        sa.UniqueConstraint("id_fornecedor", name="uq_operadora_id_fornecedor"),
        sa.UniqueConstraint("codigo", name="uq_operadora_codigo"),
        comment="Papel de operadora atribuido a fornecedor corporativo",
    )
    op.create_index("idx_operadora_ativo", "operadora", ["ativo"])
    _create_audit_triggers("operadora")

    op.create_table(
        "oportunidade",
        sa.Column("id_oportunidade", sa.Integer(), sa.Identity(), nullable=False),
        sa.Column("id_lead", sa.Integer(), nullable=False, comment="Lead de origem."),
        sa.Column("id_cliente", sa.Integer(), nullable=True, comment="Cliente convertido."),
        sa.Column("titulo", sa.String(150), nullable=False),
        sa.Column("etapa", sa.String(30), server_default=sa.text("'QUALIFICACAO'"), nullable=False),
        sa.Column("probabilidade", sa.Numeric(5, 2), server_default=sa.text("0"), nullable=False),
        sa.Column("valor_estimado", sa.Numeric(15, 2), server_default=sa.text("0"), nullable=False),
        sa.Column("status", sa.String(20), server_default=sa.text("'ABERTA'"), nullable=False),
        sa.Column("data_fechamento_prevista", sa.Date(), nullable=True),
        *_audit_columns(),
        sa.CheckConstraint(
            "probabilidade >= 0 AND probabilidade <= 100",
            name="ck_oportunidade_probabilidade",
        ),
        sa.CheckConstraint("valor_estimado >= 0", name="ck_oportunidade_valor_estimado"),
        sa.ForeignKeyConstraint(["id_lead"], ["lead.id_lead"], name="fk_oportunidade_lead"),
        sa.ForeignKeyConstraint(
            ["id_cliente"], ["cliente.id_cliente"], name="fk_oportunidade_cliente"
        ),
        sa.PrimaryKeyConstraint("id_oportunidade", name="pk_oportunidade"),
        sa.UniqueConstraint("id_lead", name="uq_oportunidade_id_lead"),
        comment="Oportunidades qualificadas do pipeline Comercial",
    )
    op.create_index("idx_oportunidade_id_cliente", "oportunidade", ["id_cliente"])
    op.create_index("idx_oportunidade_status_etapa", "oportunidade", ["status", "etapa"])
    _create_audit_triggers("oportunidade")

    op.create_table(
        "proposta",
        sa.Column("id_proposta", sa.Integer(), sa.Identity(), nullable=False),
        sa.Column("id_oportunidade", sa.Integer(), nullable=False),
        sa.Column("id_cliente", sa.Integer(), nullable=False),
        sa.Column("numero", sa.String(30), nullable=False),
        sa.Column(
            "data_emissao",
            sa.Date(),
            server_default=sa.text("CURRENT_DATE"),
            nullable=False,
        ),
        sa.Column("data_validade", sa.Date(), nullable=False),
        sa.Column("status", sa.String(20), server_default=sa.text("'RASCUNHO'"), nullable=False),
        sa.Column("valor_bruto", sa.Numeric(15, 2), server_default=sa.text("0"), nullable=False),
        sa.Column("desconto", sa.Numeric(15, 2), server_default=sa.text("0"), nullable=False),
        sa.Column("valor_liquido", sa.Numeric(15, 2), server_default=sa.text("0"), nullable=False),
        *_audit_columns(),
        sa.CheckConstraint("data_validade >= data_emissao", name="ck_proposta_validade"),
        sa.CheckConstraint(
            "valor_bruto >= 0 AND desconto >= 0 AND valor_liquido >= 0",
            name="ck_proposta_valores",
        ),
        sa.ForeignKeyConstraint(
            ["id_oportunidade"],
            ["oportunidade.id_oportunidade"],
            name="fk_proposta_oportunidade",
        ),
        sa.ForeignKeyConstraint(["id_cliente"], ["cliente.id_cliente"], name="fk_proposta_cliente"),
        sa.PrimaryKeyConstraint("id_proposta", name="pk_proposta"),
        sa.UniqueConstraint("numero", name="uq_proposta_numero"),
        comment="Propostas comerciais versionadas pelo estado",
    )
    op.create_index("idx_proposta_id_oportunidade", "proposta", ["id_oportunidade"])
    op.create_index("idx_proposta_id_cliente", "proposta", ["id_cliente"])
    _create_audit_triggers("proposta")

    op.create_table(
        "item_proposta",
        sa.Column("id_item_proposta", sa.Integer(), sa.Identity(), nullable=False),
        sa.Column("id_proposta", sa.Integer(), nullable=False),
        sa.Column("descricao", sa.String(200), nullable=False),
        sa.Column("quantidade", sa.Numeric(10, 2), nullable=False),
        sa.Column("valor_unitario", sa.Numeric(15, 2), nullable=False),
        sa.Column("desconto", sa.Numeric(15, 2), server_default=sa.text("0"), nullable=False),
        sa.Column("valor_total", sa.Numeric(15, 2), nullable=False),
        *_audit_columns(),
        sa.CheckConstraint("quantidade > 0", name="ck_item_proposta_quantidade"),
        sa.CheckConstraint(
            "valor_unitario >= 0 AND desconto >= 0 AND valor_total >= 0",
            name="ck_item_proposta_valores",
        ),
        sa.ForeignKeyConstraint(
            ["id_proposta"], ["proposta.id_proposta"], name="fk_item_proposta_proposta"
        ),
        sa.PrimaryKeyConstraint("id_item_proposta", name="pk_item_proposta"),
        comment="Itens monetarios de proposta Comercial",
    )
    op.create_index("idx_item_proposta_id_proposta", "item_proposta", ["id_proposta"])
    _create_audit_triggers("item_proposta")

    op.create_table(
        "condicao_comercial",
        sa.Column("id_condicao_comercial", sa.Integer(), sa.Identity(), nullable=False),
        sa.Column("id_proposta", sa.Integer(), nullable=False),
        sa.Column("tipo", sa.String(30), nullable=False),
        sa.Column("descricao", sa.String(200), nullable=False),
        sa.Column("percentual", sa.Numeric(5, 2), nullable=True),
        sa.Column("valor", sa.Numeric(15, 2), nullable=True),
        sa.Column("data_inicio", sa.Date(), nullable=False),
        sa.Column("data_fim", sa.Date(), nullable=True),
        sa.Column("ativo", sa.Boolean(), server_default=sa.text("true"), nullable=False),
        *_audit_columns(),
        sa.CheckConstraint(
            "percentual IS NULL OR (percentual >= 0 AND percentual <= 100)",
            name="ck_condicao_comercial_percentual",
        ),
        sa.CheckConstraint("valor IS NULL OR valor >= 0", name="ck_condicao_comercial_valor"),
        sa.CheckConstraint(
            "data_fim IS NULL OR data_fim >= data_inicio", name="ck_condicao_comercial_vigencia"
        ),
        sa.ForeignKeyConstraint(
            ["id_proposta"], ["proposta.id_proposta"], name="fk_condicao_comercial_proposta"
        ),
        sa.PrimaryKeyConstraint("id_condicao_comercial", name="pk_condicao_comercial"),
        comment="Condicoes, descontos e comissoes aplicaveis a proposta",
    )
    op.create_index("idx_condicao_comercial_id_proposta", "condicao_comercial", ["id_proposta"])
    _create_audit_triggers("condicao_comercial")

    op.execute(
        """
        COMMENT ON COLUMN public.operadora.codigo IS 'Código comercial único da operadora';
        COMMENT ON COLUMN public.operadora.ativo IS 'Indica disponibilidade comercial';
        COMMENT ON COLUMN public.oportunidade.titulo IS 'Identificação da oportunidade';
        COMMENT ON COLUMN public.oportunidade.etapa IS 'Etapa atual do pipeline';
        COMMENT ON COLUMN public.oportunidade.probabilidade IS 'Probabilidade percentual de ganho';
        COMMENT ON COLUMN public.oportunidade.valor_estimado IS 'Valor monetário estimado';
        COMMENT ON COLUMN public.oportunidade.status IS 'Estado da oportunidade';
        COMMENT ON COLUMN public.oportunidade.data_fechamento_prevista IS
            'Previsão de fechamento';
        COMMENT ON COLUMN public.proposta.id_oportunidade IS 'Oportunidade de origem';
        COMMENT ON COLUMN public.proposta.id_cliente IS 'Cliente destinatário';
        COMMENT ON COLUMN public.proposta.numero IS 'Número comercial único';
        COMMENT ON COLUMN public.proposta.data_emissao IS 'Data de emissão';
        COMMENT ON COLUMN public.proposta.data_validade IS 'Data limite de validade';
        COMMENT ON COLUMN public.proposta.status IS 'Estado da proposta';
        COMMENT ON COLUMN public.proposta.valor_bruto IS 'Total anterior aos descontos';
        COMMENT ON COLUMN public.proposta.desconto IS 'Desconto monetário total';
        COMMENT ON COLUMN public.proposta.valor_liquido IS 'Total após descontos';
        COMMENT ON COLUMN public.item_proposta.id_proposta IS 'Proposta proprietária';
        COMMENT ON COLUMN public.item_proposta.descricao IS 'Descrição comercial do item';
        COMMENT ON COLUMN public.item_proposta.quantidade IS 'Quantidade negociada';
        COMMENT ON COLUMN public.item_proposta.valor_unitario IS 'Preço unitário';
        COMMENT ON COLUMN public.item_proposta.desconto IS 'Desconto monetário do item';
        COMMENT ON COLUMN public.item_proposta.valor_total IS 'Total líquido do item';
        COMMENT ON COLUMN public.condicao_comercial.id_proposta IS 'Proposta proprietária';
        COMMENT ON COLUMN public.condicao_comercial.tipo IS 'Tipo da condição';
        COMMENT ON COLUMN public.condicao_comercial.descricao IS 'Descrição da condição';
        COMMENT ON COLUMN public.condicao_comercial.percentual IS 'Percentual opcional';
        COMMENT ON COLUMN public.condicao_comercial.valor IS 'Valor monetário opcional';
        COMMENT ON COLUMN public.condicao_comercial.data_inicio IS 'Início da vigência';
        COMMENT ON COLUMN public.condicao_comercial.data_fim IS 'Fim opcional da vigência';
        COMMENT ON COLUMN public.condicao_comercial.ativo IS 'Indica aplicação vigente';
        """
    )

    op.add_column(
        "venda",
        sa.Column("id_proposta", sa.Integer(), nullable=True, comment="Proposta convertida."),
    )
    op.create_foreign_key(
        "fk_venda_proposta", "venda", "proposta", ["id_proposta"], ["id_proposta"]
    )
    op.create_unique_constraint("uq_venda_id_proposta", "venda", ["id_proposta"])
    op.add_column(
        "contrato",
        sa.Column("id_venda", sa.Integer(), nullable=True, comment="Venda contratada."),
    )
    op.add_column(
        "contrato",
        sa.Column("id_reserva", sa.Integer(), nullable=True, comment="Reserva relacionada."),
    )
    op.create_foreign_key("fk_contrato_venda", "contrato", "venda", ["id_venda"], ["id_venda"])
    op.create_foreign_key(
        "fk_contrato_reserva", "contrato", "reserva", ["id_reserva"], ["id_reserva"]
    )

    op.execute(
        """
        INSERT INTO public.permissao (codigo, descricao, modulo, created_by)
        VALUES
            ('COMERCIAL_VISUALIZAR', 'Visualizar recursos comerciais', 'COMERCIAL', 'migration'),
            ('COMERCIAL_GERENCIAR', 'Gerenciar recursos comerciais', 'COMERCIAL', 'migration')
        ON CONFLICT (codigo) DO NOTHING;
        INSERT INTO public.perfil_permissao (id_perfil, id_permissao, created_by)
        SELECT p.id_perfil, pe.id_permissao, 'migration'
          FROM public.perfil_acesso p CROSS JOIN public.permissao pe
         WHERE p.codigo = 'ADMIN'
           AND pe.codigo IN ('COMERCIAL_VISUALIZAR', 'COMERCIAL_GERENCIAR')
        ON CONFLICT (id_perfil, id_permissao) DO NOTHING;
        """
    )


def downgrade() -> None:
    op.execute(
        """
        DELETE FROM public.perfil_permissao
         WHERE id_permissao IN (
            SELECT id_permissao FROM public.permissao
             WHERE codigo IN ('COMERCIAL_VISUALIZAR', 'COMERCIAL_GERENCIAR')
         ) AND created_by = 'migration';
        DELETE FROM public.permissao
         WHERE codigo IN ('COMERCIAL_VISUALIZAR', 'COMERCIAL_GERENCIAR')
           AND created_by = 'migration';
        """
    )
    op.drop_constraint("fk_contrato_reserva", "contrato", type_="foreignkey")
    op.drop_constraint("fk_contrato_venda", "contrato", type_="foreignkey")
    op.drop_column("contrato", "id_reserva")
    op.drop_column("contrato", "id_venda")
    op.drop_constraint("uq_venda_id_proposta", "venda", type_="unique")
    op.drop_constraint("fk_venda_proposta", "venda", type_="foreignkey")
    op.drop_column("venda", "id_proposta")
    for table_name in (
        "condicao_comercial",
        "item_proposta",
        "proposta",
        "oportunidade",
        "operadora",
    ):
        op.execute(f"DROP TRIGGER IF EXISTS trg_log_auditoria ON public.{table_name}")
        op.execute(f"DROP TRIGGER IF EXISTS trg_atualiza_updated_at ON public.{table_name}")
        op.drop_table(table_name)
    op.drop_index("idx_lead_id_cliente", table_name="lead")
    op.drop_constraint("fk_lead_cliente", "lead", type_="foreignkey")
    op.drop_column("lead", "id_cliente")
    op.drop_constraint("uq_cliente_id_pessoa", "cliente", type_="unique")
