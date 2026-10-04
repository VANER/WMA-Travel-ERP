"""Projecoes de leitura Bike Tour; GET nao expira nem altera registros."""

from collections import Counter
from datetime import UTC, datetime
from typing import Literal, cast

from sqlalchemy import or_, select
from sqlalchemy.orm import Session, class_mapper

from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import (
    AlocacaoRecursoBikeTour,
    BikeTourAuditMixin,
    EventoBikeTour,
    InscricaoBikeTour,
    OcorrenciaBikeTour,
    OperacaoBikeTour,
    PassagemBikeTour,
    PendenciaBikeTour,
    RecursoBikeTour,
)
from app.modules.biketour.operations import projecao
from app.shared.turismo import (
    obter_contexto_inscricao,
    obter_origem_comercial_reserva,
    obter_situacao_recurso_origem,
)


class ConsultasBikeTour:
    def __init__(self, session: Session) -> None:
        self.session = session

    def obter[T: BikeTourAuditMixin](self, model: type[T], identifier: int) -> T:
        item = self.session.get(model, identifier)
        if item is None or item.deleted_at is not None:
            raise BikeTourError(404, "BT_RECURSO_NAO_ENCONTRADO")
        return item

    def listar[T: BikeTourAuditMixin](
        self,
        model: type[T],
        offset: int,
        limite: int,
        evento: int | None = None,
        status: str | None = None,
    ) -> list[dict[str, object]]:
        statement = select(model).where(model.deleted_at.is_(None))
        if evento is not None:
            self.obter(EventoBikeTour, evento)
            statement = statement.where(
                class_mapper(model).columns["id_evento_bike_tour"] == evento
            )
        if status is not None:
            statement = statement.where(class_mapper(model).columns["status"] == status)
        statement = (
            statement.order_by(class_mapper(model).primary_key[0]).offset(offset).limit(limite)
        )
        return [projecao(item) for item in self.session.scalars(statement).all()]

    def origem_valida(self, evento: EventoBikeTour, item: InscricaoBikeTour) -> bool:
        origem = obter_contexto_inscricao(
            self.session, evento.id_saida, item.id_reserva, item.id_passageiro
        )
        return bool(
            origem
            and origem.saida.deleted_at is None
            and origem.saida.status in {"PLANEJADA", "ABERTA"}
            and origem.reserva.deleted_at is None
            and origem.reserva.status in {"PENDENTE", "CONFIRMADA"}
            and origem.passageiro.deleted_at is None
            and origem.passageiro.status == "ATIVO"
        )

    def inscricoes(self, identifier: int, offset: int, limite: int) -> list[dict[str, object]]:
        evento = self.obter(EventoBikeTour, identifier)
        inscricoes = self.session.scalars(
            select(InscricaoBikeTour)
            .where(
                InscricaoBikeTour.id_evento_bike_tour == identifier,
                InscricaoBikeTour.deleted_at.is_(None),
            )
            .order_by(InscricaoBikeTour.id_inscricao_bike_tour)
            .offset(offset)
            .limit(limite)
        ).all()
        result = []
        for item in inscricoes:
            alocacoes = self.session.scalars(
                select(AlocacaoRecursoBikeTour)
                .where(
                    AlocacaoRecursoBikeTour.id_inscricao_bike_tour == item.id_inscricao_bike_tour,
                    AlocacaoRecursoBikeTour.status.in_(("BLOQUEADA", "CONFIRMADA")),
                    AlocacaoRecursoBikeTour.deleted_at.is_(None),
                )
                .order_by(AlocacaoRecursoBikeTour.id_alocacao_recurso_bike_tour)
            ).all()
            expira = min((a.expira_em for a in alocacoes if a.expira_em is not None), default=None)
            result.append(
                {
                    **projecao(item),
                    "origem_valida": self.origem_valida(evento, item),
                    "alocacoes": [a.id_alocacao_recurso_bike_tour for a in alocacoes],
                    "expira_em": expira.isoformat() if expira else None,
                }
            )
        return result

    def correlacao(self, identifier: int) -> dict[str, object]:
        inscricao = self.obter(InscricaoBikeTour, identifier)
        origem = obter_origem_comercial_reserva(self.session, inscricao.id_reserva)
        return {
            "id_reserva": inscricao.id_reserva,
            "id_venda": origem.id_venda,
            "id_item_venda": origem.id_item_venda,
            "id_contrato": origem.id_contrato,
            "origem_valida": origem.valida,
        }

    def disponibilidade(
        self,
        identifier: int,
        inicio: datetime | None,
        fim: datetime | None,
        offset: int,
        limite: int,
    ) -> dict[str, object]:
        evento = self.obter(EventoBikeTour, identifier)
        inicio, fim = inicio or evento.inicio, fim or evento.fim
        if (
            inicio.tzinfo is None
            or fim.tzinfo is None
            or not evento.inicio <= inicio < fim <= evento.fim
        ):
            raise BikeTourError(422, "BT_INTERVALO_INVALIDO")
        agora = datetime.now(UTC)
        ativas = or_(
            AlocacaoRecursoBikeTour.status == "CONFIRMADA",
            (AlocacaoRecursoBikeTour.status == "BLOQUEADA")
            & (AlocacaoRecursoBikeTour.expira_em > agora),
        )
        ocupados = select(AlocacaoRecursoBikeTour.id_recurso_bike_tour).where(
            ativas,
            AlocacaoRecursoBikeTour.inicio < fim,
            AlocacaoRecursoBikeTour.fim > inicio,
            AlocacaoRecursoBikeTour.deleted_at.is_(None),
        )
        recursos = self.session.scalars(
            select(RecursoBikeTour)
            .where(
                RecursoBikeTour.status == "DISPONIVEL",
                RecursoBikeTour.deleted_at.is_(None),
                RecursoBikeTour.id_recurso_bike_tour.not_in(ocupados),
            )
            .order_by(RecursoBikeTour.id_recurso_bike_tour)
        ).all()

        recursos_validos: list[RecursoBikeTour] = []
        for recurso in recursos:
            identifier_origem = recurso.id_ativo or recurso.id_guia or recurso.id_transporte
            if identifier_origem is None:
                if recurso.tipo in {"BICICLETA", "EQUIPAMENTO"}:
                    recursos_validos.append(recurso)
                continue

            if recurso.tipo not in {
                "BICICLETA",
                "EQUIPAMENTO",
                "GUIA",
                "VEICULO",
            }:
                continue

            tipo_origem = cast(
                Literal[
                    "BICICLETA",
                    "EQUIPAMENTO",
                    "GUIA",
                    "VEICULO",
                ],
                recurso.tipo,
            )

            origem = obter_situacao_recurso_origem(
                self.session,
                tipo_origem,
                identifier_origem,
            )
            if origem.permitido:
                recursos_validos.append(recurso)

        recursos = recursos_validos[offset : offset + limite]

        bloqueadas = select(AlocacaoRecursoBikeTour.id_inscricao_bike_tour).where(
            AlocacaoRecursoBikeTour.status == "BLOQUEADA",
            AlocacaoRecursoBikeTour.expira_em > agora,
        )
        inscricoes = list(
            self.session.scalars(
                select(InscricaoBikeTour.id_inscricao_bike_tour).where(
                    InscricaoBikeTour.id_evento_bike_tour == identifier,
                    InscricaoBikeTour.deleted_at.is_(None),
                    or_(
                        InscricaoBikeTour.status.in_(("CONFIRMADA", "PRESENTE")),
                        (InscricaoBikeTour.status == "PENDENTE")
                        & InscricaoBikeTour.id_inscricao_bike_tour.in_(bloqueadas),
                    ),
                )
            ).all()
        )
        return {
            "id_evento_bike_tour": identifier,
            "capacidade": evento.capacidade,
            "comprometidas": len(inscricoes),
            "saldo": max(0, evento.capacidade - len(inscricoes)),
            "recursos": [projecao(r) for r in recursos],
        }

    def relatorio(self, identifier: int) -> dict[str, object]:
        self.obter(EventoBikeTour, identifier)
        inscricoes = self.session.scalars(
            select(InscricaoBikeTour).where(
                InscricaoBikeTour.id_evento_bike_tour == identifier,
                InscricaoBikeTour.deleted_at.is_(None),
            )
        ).all()
        ids = [i.id_inscricao_bike_tour for i in inscricoes]
        passagens = self.session.scalars(
            select(PassagemBikeTour.id_passagem_bike_tour).where(
                PassagemBikeTour.id_inscricao_bike_tour.in_(ids),
                PassagemBikeTour.deleted_at.is_(None),
            )
        ).all()
        ocorrencias = self.session.scalars(
            select(OcorrenciaBikeTour.status).where(
                OcorrenciaBikeTour.id_evento_bike_tour == identifier,
                OcorrenciaBikeTour.deleted_at.is_(None),
            )
        ).all()
        return {
            "id_evento_bike_tour": identifier,
            "inscricoes": dict(Counter(i.status for i in inscricoes)),
            "ids_inscricoes": ids,
            "passagens": len(passagens),
            "ocorrencias": dict(Counter(ocorrencias)),
        }

    def auditoria(self, identifier: int, offset: int, limite: int) -> list[dict[str, object]]:
        self.obter(EventoBikeTour, identifier)
        # Somente operacoes vinculadas ao evento; nunca hashes ou payloads.
        pendencias = select(PendenciaBikeTour.id_operacao_bike_tour).where(
            PendenciaBikeTour.id_evento_bike_tour == identifier,
        )
        inscricoes = select(InscricaoBikeTour.id_inscricao_bike_tour).where(
            InscricaoBikeTour.id_evento_bike_tour == identifier,
        )
        statement = (
            select(OperacaoBikeTour)
            .where(
                or_(
                    (OperacaoBikeTour.alvo == identifier)
                    & OperacaoBikeTour.operacao.in_(
                        (
                            "acao_evento",
                            "alterar_evento",
                            "definir_pontos",
                            "definir_equipe",
                            "definir_logistica",
                            "expirar_evento",
                            "reconciliar_evento",
                            "bloquear_inscricao",
                            "registrar_ocorrencia",
                        )
                    ),
                    OperacaoBikeTour.resultado["id_evento_bike_tour"].as_integer() == identifier,
                    (
                        OperacaoBikeTour.operacao.in_(
                            (
                                "acao_inscricao",
                                "reacomodar_recursos",
                                "registrar_passagem",
                                "avaliar_inscricao",
                            )
                        )
                        & OperacaoBikeTour.alvo.in_(inscricoes)
                    ),
                    OperacaoBikeTour.id_operacao_bike_tour.in_(pendencias),
                )
            )
            .order_by(OperacaoBikeTour.id_operacao_bike_tour)
            .offset(offset)
            .limit(limite)
        )
        return [
            {
                "id": o.id_operacao_bike_tour,
                "ator": o.id_usuario,
                "operacao": o.operacao,
                "instante": o.created_at.isoformat(),
                "correlation_id": str(o.correlation_id),
                "status_http": o.http_status,
            }
            for o in self.session.scalars(statement).all()
        ]
