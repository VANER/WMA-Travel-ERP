"""Testes unitários do domínio Turismo."""

from datetime import date, datetime, timedelta
from decimal import Decimal
from unittest.mock import MagicMock, patch

import pytest
from fastapi import HTTPException
from pydantic import ValidationError

from app.modules.turismo import router
from app.modules.turismo.models import AlocacaoVaga, PacoteViagem, Reserva, SaidaTuristica
from app.modules.turismo.repositories import ReservaRepository, SaidaRepository
from app.modules.turismo.schemas import ReservaAcao, ReservaCreate, SaidaCreate
from app.modules.turismo.services import (
    RegraTurismoError,
    cancelar_reserva,
    confirmar_reserva,
    criar_reserva,
    criar_saida,
    obter_disponibilidade,
)

HOJE = date(2026, 9, 5)


def _saida() -> SaidaTuristica:
    return SaidaTuristica(
        id_saida=1,
        id_pacote=2,
        codigo="S-1",
        data_inicio=HOJE,
        data_fim=HOJE + timedelta(days=2),
        capacidade=10,
        status="ABERTA",
        versao=1,
    )


def _reserva_payload(**changes: object) -> ReservaCreate:
    data: dict[str, object] = {
        "codigo_reserva": "R-1",
        "id_cliente": 3,
        "id_saida": 1,
        "quantidade_passageiros": 2,
        "valor_total": Decimal("100"),
        "chave_idempotencia": "reserva:1",
    }
    data.update(changes)
    return ReservaCreate.model_validate(data)


def test_schemas_validate_period_and_quantities() -> None:
    assert (
        SaidaCreate(
            id_pacote=1,
            codigo="S",
            data_inicio=HOJE,
            data_fim=HOJE,
            capacidade=0,
        ).capacidade
        == 0
    )
    with pytest.raises(ValidationError, match="não pode anteceder"):
        SaidaCreate(
            id_pacote=1,
            codigo="S",
            data_inicio=HOJE,
            data_fim=HOJE - timedelta(days=1),
            capacidade=1,
        )
    with pytest.raises(ValidationError):
        _reserva_payload(quantidade_passageiros=0)
    with pytest.raises(ValidationError, match="deve estar no futuro"):
        _reserva_payload(expira_em=datetime(2000, 1, 1))


def test_repositories_list_lock_occupancy_and_idempotency() -> None:
    session = MagicMock()
    session.scalar.return_value = _saida()
    repository = SaidaRepository(session)
    assert repository.obter(1) is session.scalar.return_value
    assert repository.obter(1, bloquear=True) is session.scalar.return_value
    session.scalars.return_value.all.return_value = [_saida()]
    assert len(repository.listar(0, 10)) == 1
    session.scalar.side_effect = [2, 3]
    assert repository.ocupacao(1, datetime.now()) == (2, 3)
    session.scalar.side_effect = None
    reserva = Reserva(id_reserva=1)
    session.scalar.return_value = reserva
    reservas = ReservaRepository(session)
    assert reservas.por_chave("x") is reserva
    assert reservas.obter(1) is reserva
    assert reservas.obter(1, bloquear=True) is reserva


def test_create_departure_validates_package_and_commit() -> None:
    session = MagicMock()
    payload = SaidaCreate(
        id_pacote=1,
        codigo="S",
        data_inicio=HOJE,
        data_fim=HOJE,
        capacidade=2,
    )
    session.get.return_value = None
    with pytest.raises(RegraTurismoError, match="pacote"):
        criar_saida(session, payload)
    session.get.return_value = PacoteViagem(id_pacote=1)
    result = criar_saida(session, payload)
    assert result.status == "PLANEJADA"
    session.commit.assert_called_once()
    session.commit.side_effect = RuntimeError("commit")
    with pytest.raises(RuntimeError, match="commit"):
        criar_saida(session, payload)
    session.rollback.assert_called_once()


def test_availability_success_and_missing() -> None:
    session = MagicMock()
    repository = MagicMock()
    repository.obter.return_value = None
    with (
        patch("app.modules.turismo.services.SaidaRepository", return_value=repository),
        pytest.raises(RegraTurismoError, match="saída"),
    ):
        obter_disponibilidade(session, 1)
    repository.obter.return_value = _saida()
    repository.ocupacao.return_value = (2, 3)
    with patch("app.modules.turismo.services.SaidaRepository", return_value=repository):
        result = obter_disponibilidade(session, 1)
    assert result.disponibilidade == 5


def test_create_reservation_idempotency_validation_and_correlation() -> None:
    session = MagicMock()
    existing = Reserva(id_reserva=1)
    reservas = MagicMock()
    reservas.por_chave.return_value = existing
    with patch("app.modules.turismo.services.ReservaRepository", return_value=reservas):
        assert criar_reserva(session, _reserva_payload()) is existing
    reservas.por_chave.return_value = None
    saidas = MagicMock()
    saidas.obter.return_value = None
    with (
        patch("app.modules.turismo.services.ReservaRepository", return_value=reservas),
        patch("app.modules.turismo.services.SaidaRepository", return_value=saidas),
        pytest.raises(RegraTurismoError, match="saída"),
    ):
        criar_reserva(session, _reserva_payload())
    saida = _saida()
    saidas.obter.return_value = saida
    saida.status = "CANCELADA"
    with (
        patch("app.modules.turismo.services.ReservaRepository", return_value=reservas),
        patch("app.modules.turismo.services.SaidaRepository", return_value=saidas),
        pytest.raises(RegraTurismoError, match="não aceita"),
    ):
        criar_reserva(session, _reserva_payload())
    saida.status = "ABERTA"
    saidas.ocupacao.return_value = (9, 0)
    with (
        patch("app.modules.turismo.services.ReservaRepository", return_value=reservas),
        patch("app.modules.turismo.services.SaidaRepository", return_value=saidas),
        pytest.raises(RegraTurismoError, match="capacidade"),
    ):
        criar_reserva(session, _reserva_payload())
    saidas.ocupacao.return_value = (0, 0)
    with (
        patch("app.modules.turismo.services.ReservaRepository", return_value=reservas),
        patch("app.modules.turismo.services.SaidaRepository", return_value=saidas),
    ):
        result = criar_reserva(session, _reserva_payload(id_venda=4))
    assert result.status == "PENDENTE"
    assert session.add.call_count == 3


def test_confirm_and_cancel_reservation_rules() -> None:
    session = MagicMock()
    repository = MagicMock()
    repository.obter.return_value = None
    action = ReservaAcao(chave_idempotencia="action:1")
    with (
        patch("app.modules.turismo.services.ReservaRepository", return_value=repository),
        pytest.raises(RegraTurismoError, match="reserva"),
    ):
        confirmar_reserva(session, 1, action)
    reserva = Reserva(id_reserva=1, status="CONFIRMADA")
    repository.obter.return_value = reserva
    with patch("app.modules.turismo.services.ReservaRepository", return_value=repository):
        assert confirmar_reserva(session, 1, action) is reserva
    reserva.status = "PENDENTE"
    session.scalar.return_value = None
    with (
        patch("app.modules.turismo.services.ReservaRepository", return_value=repository),
        pytest.raises(RegraTurismoError, match="alocação"),
    ):
        confirmar_reserva(session, 1, action)
    allocation = AlocacaoVaga(
        id_alocacao=1,
        id_saida=1,
        id_reserva=1,
        chave_idempotencia="x",
        quantidade=1,
        status="BLOQUEADA",
        expira_em=datetime(2000, 1, 1),
    )
    session.scalar.return_value = allocation
    with (
        patch("app.modules.turismo.services.ReservaRepository", return_value=repository),
        pytest.raises(RegraTurismoError, match="expirado"),
    ):
        confirmar_reserva(session, 1, action)
    allocation.expira_em = datetime(2099, 1, 1)
    with patch("app.modules.turismo.services.ReservaRepository", return_value=repository):
        assert confirmar_reserva(session, 1, action).status == "CONFIRMADA"
    repository.obter.return_value = None
    with (
        patch("app.modules.turismo.services.ReservaRepository", return_value=repository),
        pytest.raises(RegraTurismoError, match="reserva"),
    ):
        cancelar_reserva(session, 1, action)
    repository.obter.return_value = reserva
    reserva.status = "CONCLUIDA"
    with (
        patch("app.modules.turismo.services.ReservaRepository", return_value=repository),
        pytest.raises(RegraTurismoError, match="não pode"),
    ):
        cancelar_reserva(session, 1, action)
    reserva.status = "PENDENTE"
    allocation.status = "RESERVADA"
    with patch("app.modules.turismo.services.ReservaRepository", return_value=repository):
        assert cancelar_reserva(session, 1, action).status == "CANCELADA"
    with patch("app.modules.turismo.services.ReservaRepository", return_value=repository):
        assert cancelar_reserva(session, 1, action) is reserva


def test_router_maps_success_and_conflicts() -> None:
    session = MagicMock()
    saida = _saida()
    with patch("app.modules.turismo.router.SaidaRepository.listar", return_value=[saida]):
        assert router.listar_saidas(session) == [saida]
    payload = SaidaCreate(
        id_pacote=1,
        codigo="S",
        data_inicio=HOJE,
        data_fim=HOJE,
        capacidade=1,
    )
    with patch.object(router, "criar_saida", return_value=saida):
        assert router.cadastrar_saida(payload, session) is saida
    with patch.object(router, "criar_saida", side_effect=RegraTurismoError("regra")):
        with pytest.raises(HTTPException) as exc:
            router.cadastrar_saida(payload, session)
        assert exc.value.status_code == 409
    for target, function, arguments in (
        ("obter_disponibilidade", router.consultar_disponibilidade, (1, session)),
        ("criar_reserva", router.cadastrar_reserva, (_reserva_payload(), session)),
        (
            "confirmar_reserva",
            router.confirmar,
            (1, ReservaAcao(chave_idempotencia="x"), session),
        ),
        (
            "cancelar_reserva",
            router.cancelar,
            (1, ReservaAcao(chave_idempotencia="x"), session),
        ),
    ):
        with (
            patch.object(router, target, side_effect=RegraTurismoError("regra")),
            pytest.raises(HTTPException),
        ):
            function(*arguments)
