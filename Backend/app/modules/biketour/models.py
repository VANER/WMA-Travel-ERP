"""Modelos operacionais do modulo Bike Tour."""

from __future__ import annotations

from datetime import datetime
from decimal import Decimal
from uuid import UUID

from sqlalchemy import (
    Boolean,
    CheckConstraint,
    DateTime,
    ForeignKey,
    Identity,
    Index,
    Integer,
    Numeric,
    SmallInteger,
    String,
    UniqueConstraint,
    text,
)
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PGUUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base
from app.db.legacy_references import ativo_imobilizado, guia_turistico, transporte


class BikeTourAuditMixin:
    """Auditoria padrao para entidades novas do Bike Tour."""

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
        server_default=text("CURRENT_TIMESTAMP"),
    )
    updated_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    deleted_at: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    created_by: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )
    updated_by: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )
    deleted_by: Mapped[str | None] = mapped_column(
        String(100),
        nullable=True,
    )
    versao: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
        server_default=text("1"),
    )


class ProdutoBikeTour(BikeTourAuditMixin, Base):
    """Especializacao Bike Tour de um produto turistico."""

    __tablename__ = "produto_bike_tour"
    __table_args__ = (
        UniqueConstraint(
            "id_produto",
            name="uq_produto_bike_tour_id_produto",
        ),
        CheckConstraint(
            "distancia_km > 0",
            name="distancia_positiva",
        ),
        CheckConstraint(
            "desnivel_m >= 0",
            name="desnivel_nao_negativo",
        ),
        CheckConstraint(
            "nivel IN ('INICIANTE', 'INTERMEDIARIO', 'AVANCADO')",
            name="nivel",
        ),
    )

    id_produto_bike_tour: Mapped[int] = mapped_column(
        Integer,
        Identity(),
        primary_key=True,
    )
    id_produto: Mapped[int] = mapped_column(
        ForeignKey(
            "produto_turistico.id_produto",
            name="fk_produto_bike_tour_produto_turistico",
        ),
        nullable=False,
    )
    distancia_km: Mapped[Decimal] = mapped_column(
        Numeric(10, 2),
        nullable=False,
    )
    desnivel_m: Mapped[Decimal] = mapped_column(
        Numeric(10, 2),
        nullable=False,
        server_default=text("0"),
    )
    nivel: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
    )
    ativo: Mapped[bool] = mapped_column(
        Boolean,
        nullable=False,
        server_default=text("true"),
    )


class EventoBikeTour(BikeTourAuditMixin, Base):
    """Operacao Bike Tour especializada sobre uma saida turistica."""

    __tablename__ = "evento_bike_tour"
    __table_args__ = (
        UniqueConstraint(
            "id_saida",
            name="uq_evento_bike_tour_id_saida",
        ),
        CheckConstraint(
            "inicio < fim",
            name="periodo",
        ),
        CheckConstraint(
            "capacidade BETWEEN 1 AND 1000",
            name="capacidade",
        ),
        CheckConstraint(
            "status IN ('PLANEJADO', 'ABERTO', 'EM_EXECUCAO', 'CONCLUIDO', 'CANCELADO')",
            name="status",
        ),
    )

    id_evento_bike_tour: Mapped[int] = mapped_column(
        Integer,
        Identity(),
        primary_key=True,
    )
    id_saida: Mapped[int] = mapped_column(
        ForeignKey(
            "saida_turistica.id_saida",
            name="fk_evento_bike_tour_saida_turistica",
        ),
        nullable=False,
    )
    inicio: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    fim: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    capacidade: Mapped[int] = mapped_column(
        Integer,
        nullable=False,
    )
    status: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        server_default=text("'PLANEJADO'"),
    )


class RecursoBikeTour(BikeTourAuditMixin, Base):
    """Recurso operacional alocavel em eventos Bike Tour."""

    __tablename__ = "recurso_bike_tour"
    __table_args__ = (
        UniqueConstraint(
            "codigo",
            name="uq_recurso_bike_tour_codigo",
        ),
        UniqueConstraint(
            "id_ativo",
            name="uq_recurso_bike_tour_id_ativo",
        ),
        UniqueConstraint(
            "id_guia",
            name="uq_recurso_bike_tour_id_guia",
        ),
        UniqueConstraint(
            "id_transporte",
            name="uq_recurso_bike_tour_id_transporte",
        ),
        CheckConstraint(
            "tipo IN ('BICICLETA', 'EQUIPAMENTO', 'GUIA', 'VEICULO')",
            name="tipo",
        ),
        CheckConstraint(
            "status IN ('DISPONIVEL', 'INDISPONIVEL', 'MANUTENCAO', 'INATIVO')",
            name="status",
        ),
        CheckConstraint(
            """
            (
                CASE WHEN id_ativo IS NOT NULL THEN 1 ELSE 0 END
                + CASE WHEN id_guia IS NOT NULL THEN 1 ELSE 0 END
                + CASE WHEN id_transporte IS NOT NULL THEN 1 ELSE 0 END
            ) <= 1
            """,
            name="origem_unica",
        ),
        CheckConstraint(
            """
            (
                tipo IN ('BICICLETA', 'EQUIPAMENTO')
                AND id_guia IS NULL
                AND id_transporte IS NULL
            )
            OR
            (
                tipo = 'GUIA'
                AND id_ativo IS NULL
                AND id_guia IS NOT NULL
                AND id_transporte IS NULL
            )
            OR
            (
                tipo = 'VEICULO'
                AND id_ativo IS NULL
                AND id_guia IS NULL
                AND id_transporte IS NOT NULL
            )
            """,
            name="origem_compativel_tipo",
        ),
    )

    id_recurso_bike_tour: Mapped[int] = mapped_column(
        Integer,
        Identity(),
        primary_key=True,
    )
    codigo: Mapped[str] = mapped_column(
        String(30),
        nullable=False,
    )
    tipo: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
    )
    status: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        server_default=text("'DISPONIVEL'"),
    )

    # Identificadores de origem sao intencionalmente desacoplados nesta
    # primeira versao. A autoridade externa sera validada pela porta publica.
    id_ativo: Mapped[int | None] = mapped_column(
        ForeignKey(
            ativo_imobilizado.c.id_ativo,
            name="fk_recurso_bike_tour_ativo_imobilizado",
        ),
        nullable=True,
    )
    id_guia: Mapped[int | None] = mapped_column(
        ForeignKey(
            guia_turistico.c.id_guia,
            name="fk_recurso_bike_tour_guia_turistico",
        ),
        nullable=True,
    )
    id_transporte: Mapped[int | None] = mapped_column(
        ForeignKey(
            transporte.c.id_transporte,
            name="fk_recurso_bike_tour_transporte",
        ),
        nullable=True,
    )


class InscricaoBikeTour(BikeTourAuditMixin, Base):
    """Vinculo operacional de passageiro com evento Bike Tour."""

    __tablename__ = "inscricao_bike_tour"
    __table_args__ = (
        UniqueConstraint(
            "id_evento_bike_tour",
            "id_passageiro",
            name="uq_inscricao_bike_tour_evento_passageiro",
        ),
        CheckConstraint(
            "papel IN ('CICLISTA', 'ACOMPANHANTE')",
            name="papel",
        ),
        CheckConstraint(
            "status IN ("
            "'PENDENTE', "
            "'CONFIRMADA', "
            "'PRESENTE', "
            "'CONCLUIDA', "
            "'CANCELADA', "
            "'EXPIRADA', "
            "'NO_SHOW'"
            ")",
            name="status",
        ),
        Index(
            "idx_inscricao_bike_tour_evento_status",
            "id_evento_bike_tour",
            "status",
        ),
        Index(
            "idx_inscricao_bike_tour_reserva",
            "id_reserva",
        ),
    )

    id_inscricao_bike_tour: Mapped[int] = mapped_column(
        Integer,
        Identity(),
        primary_key=True,
    )
    id_evento_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "evento_bike_tour.id_evento_bike_tour",
            name="fk_inscricao_bike_tour_evento_bike_tour",
        ),
        nullable=False,
    )
    id_reserva: Mapped[int] = mapped_column(
        ForeignKey(
            "reserva.id_reserva",
            name="fk_inscricao_bike_tour_reserva",
        ),
        nullable=False,
    )
    id_passageiro: Mapped[int] = mapped_column(
        ForeignKey(
            "passageiro_reserva.id_passageiro",
            name="fk_inscricao_bike_tour_passageiro_reserva",
        ),
        nullable=False,
    )
    papel: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
    )
    status: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        server_default=text("'PENDENTE'"),
    )


class AlocacaoRecursoBikeTour(BikeTourAuditMixin, Base):
    """Reserva temporal de recurso operacional Bike Tour."""

    __tablename__ = "alocacao_recurso_bike_tour"
    __table_args__ = (
        CheckConstraint(
            "inicio < fim",
            name="periodo",
        ),
        CheckConstraint(
            "status IN ('BLOQUEADA', 'CONFIRMADA', 'EXPIRADA', 'LIBERADA')",
            name="status",
        ),
        CheckConstraint(
            "("
            "status = 'BLOQUEADA' "
            "AND expira_em IS NOT NULL"
            ") OR ("
            "status <> 'BLOQUEADA' "
            "AND expira_em IS NULL"
            ")",
            name="expiracao",
        ),
        Index(
            "idx_alocacao_recurso_bike_tour_evento_status_expira",
            "id_evento_bike_tour",
            "status",
            "expira_em",
        ),
        Index(
            "idx_alocacao_recurso_bike_tour_inscricao",
            "id_inscricao_bike_tour",
        ),
        Index(
            "idx_alocacao_recurso_bike_tour_recurso",
            "id_recurso_bike_tour",
        ),
    )

    id_alocacao_recurso_bike_tour: Mapped[int] = mapped_column(
        Integer,
        Identity(),
        primary_key=True,
    )
    id_evento_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "evento_bike_tour.id_evento_bike_tour",
            name="fk_alocacao_recurso_bike_tour_evento_bike_tour",
        ),
        nullable=False,
    )
    id_inscricao_bike_tour: Mapped[int | None] = mapped_column(
        ForeignKey(
            "inscricao_bike_tour.id_inscricao_bike_tour",
            name="fk_alocacao_recurso_bike_tour_inscricao_bike_tour",
        ),
        nullable=True,
    )
    id_recurso_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "recurso_bike_tour.id_recurso_bike_tour",
            name="fk_alocacao_recurso_bike_tour_recurso_bike_tour",
        ),
        nullable=False,
    )
    inicio: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    fim: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        nullable=False,
    )
    expira_em: Mapped[datetime | None] = mapped_column(
        DateTime(timezone=True),
        nullable=True,
    )
    status: Mapped[str] = mapped_column(
        String(20),
        nullable=False,
        server_default=text("'BLOQUEADA'"),
    )


class EquipeBikeTour(BikeTourAuditMixin, Base):
    """Vinculo de guia com a equipe do evento, sem duplicar sua identidade."""

    __tablename__ = "equipe_bike_tour"
    __table_args__ = (
        UniqueConstraint(
            "id_evento_bike_tour",
            "id_recurso_bike_tour",
            name="uq_equipe_bike_tour_evento_recurso",
        ),
        CheckConstraint("papel IN ('LIDER', 'APOIO')", name="papel"),
        CheckConstraint("versao >= 1", name="versao_positiva"),
        Index(
            "idx_equipe_bike_tour_lider_evento",
            "id_evento_bike_tour",
            unique=True,
            postgresql_where=text("papel = 'LIDER' AND deleted_at IS NULL"),
        ),
        Index("idx_equipe_bike_tour_recurso", "id_recurso_bike_tour"),
        {"comment": "Equipe operacional do evento Bike Tour; identidade do guia no recurso."},
    )

    id_equipe_bike_tour: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_evento_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "evento_bike_tour.id_evento_bike_tour", name="fk_equipe_bike_tour_evento_bike_tour"
        ),
        nullable=False,
    )
    id_recurso_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "recurso_bike_tour.id_recurso_bike_tour", name="fk_equipe_bike_tour_recurso_bike_tour"
        ),
        nullable=False,
    )
    papel: Mapped[str] = mapped_column(String(20), nullable=False)


class LogisticaBikeTour(BikeTourAuditMixin, Base):
    """Plano de apoio; a reserva temporal permanece na alocacao existente."""

    __tablename__ = "logistica_bike_tour"
    __table_args__ = (
        UniqueConstraint(
            "id_evento_bike_tour",
            "id_recurso_bike_tour",
            name="uq_logistica_bike_tour_evento_recurso",
        ),
        CheckConstraint("finalidade IN ('TRANSPORTE', 'APOIO', 'MATERIAL')", name="finalidade"),
        CheckConstraint("versao >= 1", name="versao_positiva"),
        Index("idx_logistica_bike_tour_recurso", "id_recurso_bike_tour"),
        {"comment": "Plano logistico Bike Tour; apoio alocado validado pelo servico."},
    )

    id_logistica_bike_tour: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_evento_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "evento_bike_tour.id_evento_bike_tour", name="fk_logistica_bike_tour_evento_bike_tour"
        ),
        nullable=False,
    )
    id_recurso_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "recurso_bike_tour.id_recurso_bike_tour",
            name="fk_logistica_bike_tour_recurso_bike_tour",
        ),
        nullable=False,
    )
    finalidade: Mapped[str] = mapped_column(String(20), nullable=False)


class PontoControleBikeTour(BikeTourAuditMixin, Base):
    """Ponto ordenado da rota, referenciando a localidade corporativa."""

    __tablename__ = "ponto_controle_bike_tour"
    __table_args__ = (
        UniqueConstraint(
            "id_evento_bike_tour",
            "ordem",
            name="uq_ponto_controle_bike_tour_evento_ordem",
        ),
        CheckConstraint("ordem > 0", name="ordem_positiva"),
        CheckConstraint("distancia_km >= 0", name="distancia_nao_negativa"),
        CheckConstraint("versao >= 1", name="versao_positiva"),
        Index("idx_ponto_controle_bike_tour_localidade", "id_localidade"),
        {"comment": "Ponto Bike Tour; ordem e distancia crescentes validadas pelo servico."},
    )

    id_ponto_controle_bike_tour: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_evento_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "evento_bike_tour.id_evento_bike_tour",
            name="fk_ponto_controle_bike_tour_evento_bike_tour",
        ),
        nullable=False,
    )
    ordem: Mapped[int] = mapped_column(Integer, nullable=False)
    id_localidade: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("localidade.id_localidade", name="fk_ponto_controle_bike_tour_localidade"),
        nullable=False,
    )
    distancia_km: Mapped[Decimal] = mapped_column(Numeric(10, 2), nullable=False)


class PassagemBikeTour(BikeTourAuditMixin, Base):
    """Registro pontual de passagem, sem rastreamento continuo."""

    __tablename__ = "passagem_bike_tour"
    __table_args__ = (
        UniqueConstraint(
            "id_inscricao_bike_tour",
            "id_ponto_controle_bike_tour",
            name="uq_passagem_bike_tour_inscricao_ponto",
        ),
        CheckConstraint("versao >= 1", name="versao_positiva"),
        Index("idx_passagem_bike_tour_ponto", "id_ponto_controle_bike_tour"),
        {"comment": "Passagem unica por inscricao e ponto; mesmo evento validado pelo servico."},
    )

    id_passagem_bike_tour: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_inscricao_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "inscricao_bike_tour.id_inscricao_bike_tour",
            name="fk_passagem_bike_tour_inscricao_bike_tour",
        ),
        nullable=False,
    )
    id_ponto_controle_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "ponto_controle_bike_tour.id_ponto_controle_bike_tour",
            name="fk_passagem_bike_tour_ponto_controle_bike_tour",
        ),
        nullable=False,
    )
    instante: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)


class OcorrenciaBikeTour(BikeTourAuditMixin, Base):
    """Ocorrencia classificada, sem texto livre ou dados clinicos."""

    __tablename__ = "ocorrencia_bike_tour"
    __table_args__ = (
        CheckConstraint("tipo IN ('ATRASO', 'MECANICA', 'INTERRUPCAO', 'OUTRA')", name="tipo"),
        CheckConstraint("gravidade IN ('BAIXA', 'MEDIA', 'ALTA')", name="gravidade"),
        CheckConstraint(
            "status IN ('ABERTA', 'EM_ANALISE', 'RESOLVIDA', 'DESCARTADA')",
            name="status",
        ),
        CheckConstraint(
            "motivo IN ('SOLICITACAO', 'CLIMA', 'RECURSO_INDISPONIVEL', "
            "'ORIGEM_INVALIDA', 'OPERACIONAL', 'TRATAMENTO_CONCLUIDO')",
            name="motivo",
        ),
        CheckConstraint("versao >= 1", name="versao_positiva"),
        Index(
            "idx_ocorrencia_bike_tour_evento_status_gravidade",
            "id_evento_bike_tour",
            "status",
            "gravidade",
        ),
        Index("idx_ocorrencia_bike_tour_inscricao", "id_inscricao_bike_tour"),
        {"comment": "Ocorrencia Bike Tour estruturada, sem texto livre ou dados clinicos."},
    )

    id_ocorrencia_bike_tour: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_evento_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "evento_bike_tour.id_evento_bike_tour", name="fk_ocorrencia_bike_tour_evento_bike_tour"
        ),
        nullable=False,
    )
    id_inscricao_bike_tour: Mapped[int | None] = mapped_column(
        ForeignKey(
            "inscricao_bike_tour.id_inscricao_bike_tour",
            name="fk_ocorrencia_bike_tour_inscricao_bike_tour",
        ),
        nullable=True,
    )
    tipo: Mapped[str] = mapped_column(String(20), nullable=False)
    gravidade: Mapped[str] = mapped_column(String(20), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, server_default=text("'ABERTA'"))
    motivo: Mapped[str] = mapped_column(String(30), nullable=False)


class AvaliacaoBikeTour(BikeTourAuditMixin, Base):
    """Nota operacional por inscricao, distinta da avaliacao turistica da reserva."""

    __tablename__ = "avaliacao_bike_tour"
    __table_args__ = (
        UniqueConstraint("id_inscricao_bike_tour", name="uq_avaliacao_bike_tour_inscricao"),
        CheckConstraint("nota BETWEEN 1 AND 5", name="nota"),
        CheckConstraint("versao >= 1", name="versao_positiva"),
        {"comment": "Nota unica por inscricao Bike Tour; conclusao validada pelo servico."},
    )

    id_avaliacao_bike_tour: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_inscricao_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "inscricao_bike_tour.id_inscricao_bike_tour",
            name="fk_avaliacao_bike_tour_inscricao_bike_tour",
        ),
        nullable=False,
    )
    nota: Mapped[int] = mapped_column(SmallInteger, nullable=False)


class OperacaoBikeTour(BikeTourAuditMixin, Base):
    """Resultado original de um comando; unicidade preservada mesmo apos soft delete."""

    __tablename__ = "operacao_bike_tour"
    __table_args__ = (
        UniqueConstraint(
            "id_usuario", "operacao", "alvo", "chave_hash", name="uq_operacao_bike_tour_intencao"
        ),
        CheckConstraint("operacao ~ '^[a-z][a-z0-9_]{0,49}$'", name="operacao"),
        CheckConstraint("alvo >= 0", name="alvo"),
        CheckConstraint("chave_hash ~ '^[0-9a-f]{64}$'", name="chave_hash"),
        CheckConstraint("payload_hash ~ '^[0-9a-f]{64}$'", name="payload_hash"),
        CheckConstraint("http_status BETWEEN 200 AND 299", name="http_status"),
        CheckConstraint("jsonb_typeof(resultado) IN ('object', 'array')", name="resultado"),
        CheckConstraint("versao >= 1", name="versao_positiva"),
        {"comment": "Resultado idempotente minimo; chave e payload originais nao persistidos."},
    )

    id_operacao_bike_tour: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_usuario: Mapped[int] = mapped_column(
        Integer,
        ForeignKey("usuario.id_usuario", name="fk_operacao_bike_tour_usuario"),
        nullable=False,
    )
    operacao: Mapped[str] = mapped_column(String(50), nullable=False)
    alvo: Mapped[int] = mapped_column(Integer, nullable=False)
    chave_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    payload_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    http_status: Mapped[int] = mapped_column(SmallInteger, nullable=False)
    resultado: Mapped[dict[str, object] | list[dict[str, object]]] = mapped_column(
        JSONB, nullable=False
    )
    correlation_id: Mapped[UUID] = mapped_column(PGUUID(as_uuid=True), nullable=False)


class PendenciaBikeTour(BikeTourAuditMixin, Base):
    """Intencao de tratamento externo; nunca confirma efeito financeiro."""

    __tablename__ = "pendencia_bike_tour"
    __table_args__ = (
        CheckConstraint("tipo IN ('CANCELAMENTO', 'NO_SHOW', 'ENCERRAMENTO')", name="tipo"),
        CheckConstraint("status IN ('ABERTA', 'TRATADA')", name="status"),
        CheckConstraint(
            "motivo IN ('SOLICITACAO', 'CLIMA', 'RECURSO_INDISPONIVEL', "
            "'ORIGEM_INVALIDA', 'OPERACIONAL', 'TRATAMENTO_CONCLUIDO')",
            name="motivo",
        ),
        CheckConstraint(
            "(status = 'ABERTA' AND referencia_tratamento IS NULL) OR "
            "(status = 'TRATADA' AND referencia_tratamento IS NOT NULL "
            "AND length(btrim(referencia_tratamento)) > 0)",
            name="tratamento",
        ),
        CheckConstraint("versao >= 1", name="versao_positiva"),
        Index("idx_pendencia_bike_tour_evento_status", "id_evento_bike_tour", "status"),
        Index("idx_pendencia_bike_tour_inscricao", "id_inscricao_bike_tour"),
        Index(
            "idx_pendencia_bike_tour_operacao_tipo_sem_inscricao",
            "id_operacao_bike_tour",
            "tipo",
            unique=True,
            postgresql_where=text("id_inscricao_bike_tour IS NULL"),
        ),
        Index(
            "idx_pendencia_bike_tour_operacao_tipo_inscricao",
            "id_operacao_bike_tour",
            "tipo",
            "id_inscricao_bike_tour",
            unique=True,
            postgresql_where=text("id_inscricao_bike_tour IS NOT NULL"),
        ),
        {"comment": "Pendencia explicita para a autoridade de origem, sem valores monetarios."},
    )

    id_pendencia_bike_tour: Mapped[int] = mapped_column(Integer, Identity(), primary_key=True)
    id_evento_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "evento_bike_tour.id_evento_bike_tour", name="fk_pendencia_bike_tour_evento_bike_tour"
        ),
        nullable=False,
    )
    id_inscricao_bike_tour: Mapped[int | None] = mapped_column(
        ForeignKey(
            "inscricao_bike_tour.id_inscricao_bike_tour",
            name="fk_pendencia_bike_tour_inscricao_bike_tour",
        ),
        nullable=True,
    )
    id_operacao_bike_tour: Mapped[int] = mapped_column(
        ForeignKey(
            "operacao_bike_tour.id_operacao_bike_tour",
            name="fk_pendencia_bike_tour_operacao_bike_tour",
        ),
        nullable=False,
    )
    tipo: Mapped[str] = mapped_column(String(20), nullable=False)
    status: Mapped[str] = mapped_column(String(20), nullable=False, server_default=text("'ABERTA'"))
    motivo: Mapped[str] = mapped_column(String(30), nullable=False)
    referencia_tratamento: Mapped[str | None] = mapped_column(String(100), nullable=True)
