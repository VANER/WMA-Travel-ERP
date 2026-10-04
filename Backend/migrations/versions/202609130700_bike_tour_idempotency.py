"""Persiste operacoes idempotentes e pendencias externas Bike Tour (A4-A8).

Revision ID: 202609130700
Revises: 202609130600

Pre-validacao: PKs inteiras de usuario/evento/inscricao e triggers corporativos.
Pos-validacao: duas tabelas, constraints e auditoria instalada. Transacao DDL
controlada pelo Alembic. Nao altera tabelas de origem, extensoes ou revisoes antigas.
Downgrade remove somente pendencias e operacoes; exige backup dos novos fatos.
Validar upgrade/downgrade/upgrade somente em PostgreSQL local descartavel _test.
"""

from collections.abc import Sequence
from typing import Any

import sqlalchemy as sa
from alembic import op
from sqlalchemy.dialects import postgresql

revision: str = "202609130700"
down_revision: str | None = "202609130600"
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None

TABLES = ("operacao_bike_tour", "pendencia_bike_tour")


def _validate_prerequisites() -> None:
    for table in ("usuario", "evento_bike_tour", "inscricao_bike_tour"):
        valid = (
            op.get_bind()
            .execute(
                sa.text(
                    "SELECT EXISTS (SELECT 1 FROM pg_constraint c JOIN pg_attribute a "
                    "ON a.attrelid=c.conrelid AND a.attnum=c.conkey[1] "
                    "WHERE c.conrelid=to_regclass(:table) AND c.contype='p' "
                    "AND cardinality(c.conkey)=1 AND a.attname=:column "
                    "AND a.atttypid='integer'::regtype)"
                ),
                {"table": f"public.{table}", "column": f"id_{table}"},
            )
            .scalar_one()
        )
        if not valid:
            raise RuntimeError(f"Prerequisito Bike Tour incompativel: public.{table}")
    for function in ("fn_atualiza_updated_at", "fn_log_auditoria"):
        valid = (
            op.get_bind()
            .execute(
                sa.text(
                    "SELECT EXISTS (SELECT 1 FROM pg_proc WHERE oid=to_regprocedure(:signature) "
                    "AND prorettype='trigger'::regtype)"
                ),
                {"signature": f"public.{function}()"},
            )
            .scalar_one()
        )
        if not valid:
            raise RuntimeError(f"Prerequisito Bike Tour incompativel: public.{function}")


def _audit() -> list[sa.Column[Any]]:
    return [
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.text("CURRENT_TIMESTAMP"),
            comment="Criacao com fuso.",
        ),
        sa.Column("updated_at", sa.DateTime(timezone=True), comment="Atualizacao com fuso."),
        sa.Column(
            "deleted_at",
            sa.DateTime(timezone=True),
            comment="Exclusao logica; historico preservado.",
        ),
        sa.Column("created_by", sa.String(100), comment="Ator da criacao."),
        sa.Column("updated_by", sa.String(100), comment="Ator da atualizacao."),
        sa.Column("deleted_by", sa.String(100), comment="Ator da exclusao logica."),
        sa.Column(
            "versao",
            sa.Integer(),
            nullable=False,
            server_default=sa.text("1"),
            comment="Versao positiva incrementada pelo trigger corporativo.",
        ),
    ]


def _identity(table: str) -> sa.Column[Any]:
    return sa.Column(
        f"id_{table}",
        sa.Integer(),
        sa.Identity(),
        nullable=False,
        comment="Identificador do fato operacional.",
    )


def _reference(table: str, target: str, *, nullable: bool = False) -> sa.Column[Any]:
    return sa.Column(
        f"id_{target}",
        sa.Integer(),
        sa.ForeignKey(f"public.{target}.id_{target}", name=f"fk_{table}_{target}"),
        nullable=nullable,
        comment=f"Referencia a public.{target}; sem copiar a origem.",
    )


def _check(table: str, rule: str, sql: str) -> sa.CheckConstraint:
    return sa.CheckConstraint(sql, name=op.f(f"ck_{table}_{rule}"))


def _audit_triggers(table: str) -> None:
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
                    "SELECT count(*) FROM pg_trigger WHERE tgrelid=to_regclass(:table) "
                    "AND NOT tgisinternal AND tgenabled='O' AND tgname IN (:updated,:audit)"
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
            raise RuntimeError(f"Auditoria Bike Tour incompleta: public.{table}")


def upgrade() -> None:
    _validate_prerequisites()
    table = "operacao_bike_tour"
    op.create_table(
        table,
        _identity(table),
        _reference(table, "usuario"),
        sa.Column(
            "operacao", sa.String(50), nullable=False, comment="Codigo do caso de uso de A3."
        ),
        sa.Column(
            "alvo", sa.Integer(), nullable=False, comment="Escopo polimorfico; zero para criacao."
        ),
        sa.Column(
            "chave_hash",
            sa.String(64),
            nullable=False,
            comment="SHA-256 hexadecimal da chave opaca.",
        ),
        sa.Column(
            "payload_hash",
            sa.String(64),
            nullable=False,
            comment="SHA-256 do payload canonico sem chave.",
        ),
        sa.Column(
            "http_status",
            sa.SmallInteger(),
            nullable=False,
            comment="Status HTTP original de sucesso.",
        ),
        sa.Column(
            "resultado",
            postgresql.JSONB(),
            nullable=False,
            comment="Resposta minima reproduzivel sem PII.",
        ),
        sa.Column(
            "correlation_id",
            postgresql.UUID(as_uuid=True),
            nullable=False,
            comment="Correlacao UUID validada pela infraestrutura HTTP existente.",
        ),
        *_audit(),
        sa.PrimaryKeyConstraint(f"id_{table}", name=f"pk_{table}"),
        sa.UniqueConstraint(
            "id_usuario", "operacao", "alvo", "chave_hash", name=f"uq_{table}_intencao"
        ),
        _check(table, "operacao", "operacao ~ '^[a-z][a-z0-9_]{0,49}$'"),
        _check(table, "alvo", "alvo >= 0"),
        _check(table, "chave_hash", "chave_hash ~ '^[0-9a-f]{64}$'"),
        _check(table, "payload_hash", "payload_hash ~ '^[0-9a-f]{64}$'"),
        _check(table, "http_status", "http_status BETWEEN 200 AND 299"),
        _check(table, "resultado", "jsonb_typeof(resultado) IN ('object', 'array')"),
        _check(table, "versao_positiva", "versao >= 1"),
        schema="public",
        comment="Resultado idempotente minimo; chave e payload originais nao persistidos.",
    )
    table = "pendencia_bike_tour"
    op.create_table(
        table,
        _identity(table),
        _reference(table, "evento_bike_tour"),
        _reference(table, "inscricao_bike_tour", nullable=True),
        _reference(table, "operacao_bike_tour"),
        sa.Column(
            "tipo", sa.String(20), nullable=False, comment="CANCELAMENTO, NO_SHOW ou ENCERRAMENTO."
        ),
        sa.Column(
            "status",
            sa.String(20),
            nullable=False,
            server_default=sa.text("'ABERTA'"),
            comment="Estado ABERTA ou TRATADA; sem automacao financeira.",
        ),
        sa.Column("motivo", sa.String(30), nullable=False, comment="Motivo enumerado de A3."),
        sa.Column(
            "referencia_tratamento",
            sa.String(100),
            comment="Referencia externa obrigatoria em TRATADA.",
        ),
        *_audit(),
        sa.PrimaryKeyConstraint(f"id_{table}", name=f"pk_{table}"),
        _check(table, "tipo", "tipo IN ('CANCELAMENTO', 'NO_SHOW', 'ENCERRAMENTO')"),
        _check(table, "status", "status IN ('ABERTA', 'TRATADA')"),
        _check(
            table,
            "motivo",
            "motivo IN ('SOLICITACAO', 'CLIMA', 'RECURSO_INDISPONIVEL', "
            "'ORIGEM_INVALIDA', 'OPERACIONAL', 'TRATAMENTO_CONCLUIDO')",
        ),
        _check(
            table,
            "tratamento",
            "(status = 'ABERTA' AND referencia_tratamento IS NULL) OR "
            "(status = 'TRATADA' AND referencia_tratamento IS NOT NULL "
            "AND length(btrim(referencia_tratamento)) > 0)",
        ),
        _check(table, "versao_positiva", "versao >= 1"),
        schema="public",
        comment="Pendencia explicita para a autoridade de origem, sem valores monetarios.",
    )
    op.create_index(
        "idx_pendencia_bike_tour_evento_status",
        table,
        ["id_evento_bike_tour", "status"],
        schema="public",
    )
    op.create_index(
        "idx_pendencia_bike_tour_inscricao", table, ["id_inscricao_bike_tour"], schema="public"
    )
    op.create_index(
        "idx_pendencia_bike_tour_operacao_tipo_sem_inscricao",
        table,
        ["id_operacao_bike_tour", "tipo"],
        unique=True,
        schema="public",
        postgresql_where=sa.text("id_inscricao_bike_tour IS NULL"),
    )
    op.create_index(
        "idx_pendencia_bike_tour_operacao_tipo_inscricao",
        table,
        ["id_operacao_bike_tour", "tipo", "id_inscricao_bike_tour"],
        unique=True,
        schema="public",
        postgresql_where=sa.text("id_inscricao_bike_tour IS NOT NULL"),
    )
    for name in TABLES:
        _audit_triggers(name)
    _validate_created_tables()


def downgrade() -> None:
    for table in reversed(TABLES):
        op.drop_table(table, schema="public")
