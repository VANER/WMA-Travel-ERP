"""Adiciona as seis tabelas operacionais aprovadas no A8 de Bike Tour.

Revision ID: 202609130500
Revises: 202609130400

Dependencias: evento/recurso/inscricao Bike Tour, localidade e funcoes corporativas
de auditoria. Pre-validacao confirma PKs inteiras e funcoes sem argumentos que
retornam trigger. Pos-validacao confirma tabelas e os dois triggers de cada uma.
Alembic controla a transacao DDL; nenhuma funcao compartilhada e substituida.

Downgrade: exige aplicacao parada e backup dos fatos novos; remove exclusivamente
as seis tabelas e seus objetos dependentes, sem CASCADE ou remocao de extensoes.
Validar em PostgreSQL descartavel: upgrade -> downgrade 202609130400 -> upgrade,
catalogo, constraints, auditoria, rollback e preservacao dos objetos anteriores.

Tipos de recurso, apoio alocado e regras entre registros permanecem nos futuros
servicos transacionais conforme A2-A8. Nao cria idempotencia ou pendencias.
"""

from collections.abc import Sequence
from typing import Any

import sqlalchemy as sa
from alembic import op

revision: str = "202609130500"
down_revision: str | None = "202609130400"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

TABLES = (
    "equipe_bike_tour",
    "logistica_bike_tour",
    "ponto_controle_bike_tour",
    "passagem_bike_tour",
    "ocorrencia_bike_tour",
    "avaliacao_bike_tour",
)


def _validate_prerequisites() -> None:
    bind = op.get_bind()
    for table in ("evento_bike_tour", "recurso_bike_tour", "inscricao_bike_tour", "localidade"):
        valid = bind.execute(
            sa.text(
                """
                SELECT EXISTS (
                    SELECT 1 FROM pg_constraint c
                    JOIN pg_attribute a
                      ON a.attrelid = c.conrelid AND a.attnum = c.conkey[1]
                    WHERE c.conrelid = to_regclass(:table)
                      AND c.contype = 'p' AND cardinality(c.conkey) = 1
                      AND a.attname = :column AND a.atttypid = 'integer'::regtype
                )
                """
            ),
            {"table": f"public.{table}", "column": f"id_{table}"},
        ).scalar_one()
        if not valid:
            raise RuntimeError(f"Prerequisito Bike Tour ausente ou incompativel: public.{table}")

    for function in ("fn_atualiza_updated_at", "fn_log_auditoria"):
        valid = bind.execute(
            sa.text(
                """
                SELECT EXISTS (
                    SELECT 1 FROM pg_proc
                    WHERE oid = to_regprocedure(:signature)
                      AND prorettype = 'trigger'::regtype
                )
                """
            ),
            {"signature": f"public.{function}()"},
        ).scalar_one()
        if not valid:
            raise RuntimeError(f"Prerequisito Bike Tour ausente ou incompativel: public.{function}")


def _audit_columns() -> list[sa.Column[Any]]:
    return [
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
            comment="Instante de criacao com fuso.",
        ),
        sa.Column("updated_at", sa.DateTime(timezone=True), comment="Ultima atualizacao com fuso."),
        sa.Column(
            "deleted_at",
            sa.DateTime(timezone=True),
            comment="Exclusao logica com fuso; preserva historico.",
        ),
        sa.Column(
            "created_by",
            sa.String(100),
            comment="Ator da criacao; padrao corporativo de auditoria.",
        ),
        sa.Column("updated_by", sa.String(100), comment="Ator da ultima atualizacao."),
        sa.Column("deleted_by", sa.String(100), comment="Ator da exclusao logica."),
        sa.Column(
            "versao",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("1"),
            comment="Versao positiva incrementada pelo trigger corporativo em cada atualizacao.",
        ),
    ]


def _identity(table: str) -> sa.Column[Any]:
    return sa.Column(
        f"id_{table}",
        sa.Integer(),
        sa.Identity(),
        nullable=False,
        comment="Identificador da linha operacional, sem reutilizacao apos exclusao logica.",
    )


def _reference(table: str, target: str, *, nullable: bool = False) -> sa.Column[Any]:
    return sa.Column(
        f"id_{target}",
        sa.Integer(),
        sa.ForeignKey(f"public.{target}.id_{target}", name=f"fk_{table}_{target}"),
        nullable=nullable,
        comment=f"Referencia a public.{target}, sem duplicar dados da origem.",
    )


def _check(table: str, rule: str, expression: str) -> sa.CheckConstraint:
    # op.f impede que a convencao do metadata prefixe novamente o nome completo.
    return sa.CheckConstraint(expression, name=op.f(f"ck_{table}_{rule}"))


def _create_audit_triggers(table: str) -> None:
    op.execute(
        sa.text(
            f"CREATE TRIGGER trg_{table}_updated_at BEFORE UPDATE ON public.{table} "
            "FOR EACH ROW EXECUTE FUNCTION public.fn_atualiza_updated_at()"
        )
    )
    op.execute(
        sa.text(
            f"CREATE TRIGGER trg_{table}_auditoria AFTER INSERT OR UPDATE OR DELETE "
            f"ON public.{table} FOR EACH ROW EXECUTE FUNCTION public.fn_log_auditoria()"
        )
    )


def _validate_created_tables() -> None:
    for table in TABLES:
        count = (
            op.get_bind()
            .execute(
                sa.text(
                    """
                SELECT count(*) FROM pg_trigger
                WHERE tgrelid = to_regclass(:table) AND NOT tgisinternal
                  AND tgname IN (:updated, :audit) AND tgenabled = 'O'
                """
                ),
                {
                    "table": f"public.{table}",
                    "updated": f"trg_{table}_updated_at",
                    "audit": f"trg_{table}_auditoria",
                },
            )
            .scalar_one()
        )
        if count != 2:
            raise RuntimeError(f"Validacao da auditoria Bike Tour falhou: public.{table}")


def upgrade() -> None:
    _validate_prerequisites()

    table = "equipe_bike_tour"
    op.create_table(
        table,
        _identity(table),
        _reference(table, "evento_bike_tour"),
        _reference(table, "recurso_bike_tour"),
        sa.Column(
            "papel", sa.String(20), nullable=False, comment="Papel LIDER ou APOIO do recurso GUIA."
        ),
        *_audit_columns(),
        sa.PrimaryKeyConstraint(f"id_{table}", name=f"pk_{table}"),
        sa.UniqueConstraint(
            "id_evento_bike_tour", "id_recurso_bike_tour", name=f"uq_{table}_evento_recurso"
        ),
        _check(table, "papel", "papel IN ('LIDER', 'APOIO')"),
        _check(table, "versao_positiva", "versao >= 1"),
        schema="public",
        comment="Equipe operacional do evento Bike Tour; identidade do guia no recurso.",
    )
    op.create_index(
        "idx_equipe_bike_tour_lider_evento",
        table,
        ["id_evento_bike_tour"],
        unique=True,
        schema="public",
        postgresql_where=sa.text("papel = 'LIDER' AND deleted_at IS NULL"),
    )
    op.create_index(
        "idx_equipe_bike_tour_recurso", table, ["id_recurso_bike_tour"], schema="public"
    )

    table = "logistica_bike_tour"
    op.create_table(
        table,
        _identity(table),
        _reference(table, "evento_bike_tour"),
        _reference(table, "recurso_bike_tour"),
        sa.Column(
            "finalidade",
            sa.String(20),
            nullable=False,
            comment="Finalidade TRANSPORTE, APOIO ou MATERIAL.",
        ),
        *_audit_columns(),
        sa.PrimaryKeyConstraint(f"id_{table}", name=f"pk_{table}"),
        sa.UniqueConstraint(
            "id_evento_bike_tour", "id_recurso_bike_tour", name=f"uq_{table}_evento_recurso"
        ),
        _check(table, "finalidade", "finalidade IN ('TRANSPORTE', 'APOIO', 'MATERIAL')"),
        _check(table, "versao_positiva", "versao >= 1"),
        schema="public",
        comment="Plano logistico Bike Tour; apoio alocado validado pelo servico.",
    )
    op.create_index(
        "idx_logistica_bike_tour_recurso", table, ["id_recurso_bike_tour"], schema="public"
    )

    table = "ponto_controle_bike_tour"
    op.create_table(
        table,
        _identity(table),
        _reference(table, "evento_bike_tour"),
        sa.Column(
            "ordem", sa.Integer(), nullable=False, comment="Ordem positiva e unica no evento."
        ),
        _reference(table, "localidade"),
        sa.Column(
            "distancia_km",
            sa.Numeric(10, 2),
            nullable=False,
            comment="Distancia acumulada em quilometros, nao negativa.",
        ),
        *_audit_columns(),
        sa.PrimaryKeyConstraint(f"id_{table}", name=f"pk_{table}"),
        sa.UniqueConstraint("id_evento_bike_tour", "ordem", name=f"uq_{table}_evento_ordem"),
        _check(table, "ordem_positiva", "ordem > 0"),
        _check(table, "distancia_nao_negativa", "distancia_km >= 0"),
        _check(table, "versao_positiva", "versao >= 1"),
        schema="public",
        comment="Ponto Bike Tour; ordem e distancia crescentes validadas pelo servico.",
    )
    op.create_index(
        "idx_ponto_controle_bike_tour_localidade", table, ["id_localidade"], schema="public"
    )

    table = "passagem_bike_tour"
    op.create_table(
        table,
        _identity(table),
        _reference(table, "inscricao_bike_tour"),
        _reference(table, "ponto_controle_bike_tour"),
        sa.Column(
            "instante",
            sa.DateTime(timezone=True),
            nullable=False,
            comment="Instante da passagem com fuso; distinto da auditoria do servidor.",
        ),
        *_audit_columns(),
        sa.PrimaryKeyConstraint(f"id_{table}", name=f"pk_{table}"),
        sa.UniqueConstraint(
            "id_inscricao_bike_tour",
            "id_ponto_controle_bike_tour",
            name=f"uq_{table}_inscricao_ponto",
        ),
        _check(table, "versao_positiva", "versao >= 1"),
        schema="public",
        comment="Passagem unica por inscricao e ponto; mesmo evento validado pelo servico.",
    )
    op.create_index(
        "idx_passagem_bike_tour_ponto", table, ["id_ponto_controle_bike_tour"], schema="public"
    )

    table = "ocorrencia_bike_tour"
    op.create_table(
        table,
        _identity(table),
        _reference(table, "evento_bike_tour"),
        _reference(table, "inscricao_bike_tour", nullable=True),
        sa.Column(
            "tipo",
            sa.String(20),
            nullable=False,
            comment="Classificacao ATRASO, MECANICA, INTERRUPCAO ou OUTRA.",
        ),
        sa.Column(
            "gravidade", sa.String(20), nullable=False, comment="Gravidade BAIXA, MEDIA ou ALTA."
        ),
        sa.Column(
            "status",
            sa.String(20),
            nullable=False,
            server_default=sa.text("'ABERTA'"),
            comment="Estado ABERTA, EM_ANALISE, RESOLVIDA ou DESCARTADA; transicoes pelo servico.",
        ),
        sa.Column(
            "motivo",
            sa.String(30),
            nullable=False,
            comment="Motivo enumerado conforme A3; nunca texto livre.",
        ),
        *_audit_columns(),
        sa.PrimaryKeyConstraint(f"id_{table}", name=f"pk_{table}"),
        _check(table, "tipo", "tipo IN ('ATRASO', 'MECANICA', 'INTERRUPCAO', 'OUTRA')"),
        _check(table, "gravidade", "gravidade IN ('BAIXA', 'MEDIA', 'ALTA')"),
        _check(table, "status", "status IN ('ABERTA', 'EM_ANALISE', 'RESOLVIDA', 'DESCARTADA')"),
        _check(
            table,
            "motivo",
            "motivo IN ('SOLICITACAO', 'CLIMA', 'RECURSO_INDISPONIVEL', "
            "'ORIGEM_INVALIDA', 'OPERACIONAL', 'TRATAMENTO_CONCLUIDO')",
        ),
        _check(table, "versao_positiva", "versao >= 1"),
        schema="public",
        comment="Ocorrencia Bike Tour estruturada, sem texto livre ou dados clinicos.",
    )
    op.create_index(
        "idx_ocorrencia_bike_tour_evento_status_gravidade",
        table,
        ["id_evento_bike_tour", "status", "gravidade"],
        schema="public",
    )
    op.create_index(
        "idx_ocorrencia_bike_tour_inscricao", table, ["id_inscricao_bike_tour"], schema="public"
    )

    table = "avaliacao_bike_tour"
    op.create_table(
        table,
        _identity(table),
        _reference(table, "inscricao_bike_tour"),
        sa.Column(
            "nota",
            sa.SmallInteger(),
            nullable=False,
            comment="Nota inteira de 1 a 5, sem comentario.",
        ),
        *_audit_columns(),
        sa.PrimaryKeyConstraint(f"id_{table}", name=f"pk_{table}"),
        sa.UniqueConstraint("id_inscricao_bike_tour", name=f"uq_{table}_inscricao"),
        _check(table, "nota", "nota BETWEEN 1 AND 5"),
        _check(table, "versao_positiva", "versao >= 1"),
        schema="public",
        comment="Nota unica por inscricao Bike Tour; conclusao validada pelo servico.",
    )

    for table in TABLES:
        _create_audit_triggers(table)
    _validate_created_tables()


def downgrade() -> None:
    for table in reversed(TABLES):
        op.drop_table(table, schema="public")
