"""Persistência do domínio Turismo sem controle autônomo de commit."""

from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.modules.turismo.models import AlocacaoVaga, Reserva, SaidaTuristica


class SaidaRepository:
    def __init__(self, session: Session) -> None:
        self.session = session

    def obter(self, identifier: int, *, bloquear: bool = False) -> SaidaTuristica | None:
        statement = select(SaidaTuristica).where(SaidaTuristica.id_saida == identifier)
        if bloquear:
            statement = statement.with_for_update()
        return self.session.scalar(statement)

    def listar(self, offset: int, limite: int) -> list[SaidaTuristica]:
        statement = select(SaidaTuristica).order_by(SaidaTuristica.id_saida)
        return list(self.session.scalars(statement.offset(offset).limit(limite)).all())

    def ocupacao(self, id_saida: int, agora: datetime) -> tuple[int, int]:
        bloqueadas = self.session.scalar(
            select(func.coalesce(func.sum(AlocacaoVaga.quantidade), 0)).where(
                AlocacaoVaga.id_saida == id_saida,
                AlocacaoVaga.status == "BLOQUEADA",
                AlocacaoVaga.expira_em > agora,
            )
        )
        confirmadas = self.session.scalar(
            select(func.coalesce(func.sum(AlocacaoVaga.quantidade), 0)).where(
                AlocacaoVaga.id_saida == id_saida,
                AlocacaoVaga.status == "RESERVADA",
            )
        )
        return int(bloqueadas or 0), int(confirmadas or 0)


class ReservaRepository:
    def __init__(self, session: Session) -> None:
        self.session = session

    def por_chave(self, chave: str) -> Reserva | None:
        statement = (
            select(Reserva)
            .join(AlocacaoVaga, AlocacaoVaga.id_reserva == Reserva.id_reserva)
            .where(AlocacaoVaga.chave_idempotencia == chave)
        )
        return self.session.scalar(statement)

    def obter(self, identifier: int, *, bloquear: bool = False) -> Reserva | None:
        statement = select(Reserva).where(Reserva.id_reserva == identifier)
        if bloquear:
            statement = statement.with_for_update()
        return self.session.scalar(statement)
