"""Testes da fronteira publica Turismo consumida pelo Bike Tour."""

from dataclasses import FrozenInstanceError, asdict
from datetime import date
from decimal import Decimal
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest

from app.modules.turismo.models import PassageiroReserva, Reserva, SaidaTuristica
from app.modules.turismo.repositories import PassageiroReservaRepository
from app.modules.turismo.schemas import PassageiroReservaCreate
from app.modules.turismo.services import (
    RecursoTurismoNaoEncontradoError,
    RegraTurismoError,
    cadastrar_passageiro_reserva,
    listar_passageiros_reserva,
)
from app.shared.turismo import (
    ContextoInscricao,
    ContextoSaida,
    OrigemReserva,
    RecursoOrigem,
    obter_contexto_inscricao,
    obter_origem_reserva,
)


@pytest.mark.parametrize("bloquear", [False, True])
def test_contexto_real_converte_orm_e_preserva_transacao(bloquear: bool) -> None:
    session = MagicMock()
    passageiro = PassageiroReserva(**asdict(_passageiro()))
    records = [
        SaidaTuristica(**asdict(_saida())),
        Reserva(**asdict(_reserva())),
        passageiro,
    ]
    session.scalar.side_effect = records

    contexto = obter_contexto_inscricao(session, 10, 30, 50, bloquear=bloquear)

    assert contexto == ContextoInscricao(_saida(), _reserva(), _passageiro())
    for call, table, identifier in zip(
        session.scalar.call_args_list,
        ["saida_turistica", "reserva", "passageiro_reserva"],
        [10, 30, 50],
        strict=True,
    ):
        statement = call.args[0]
        compiled = statement.compile()
        assert f"FROM {table}" in str(compiled)
        assert identifier in compiled.params.values()
        assert ("FOR UPDATE" in str(compiled)) is bloquear
        assert bool(statement.get_execution_options().get("populate_existing")) is bloquear
    passageiro.status = "INATIVO"
    assert contexto is not None
    assert contexto.passageiro.status == "ATIVO"
    session.commit.assert_not_called()
    session.rollback.assert_not_called()
    session.add.assert_not_called()


@pytest.mark.parametrize("ausente", [0, 1, 2])
def test_contexto_interrompe_consultas_quando_origem_ausente(ausente: int) -> None:
    session = MagicMock()
    records: list[object] = [
        SaidaTuristica(**asdict(_saida())),
        Reserva(**asdict(_reserva())),
        PassageiroReserva(**asdict(_passageiro())),
    ]
    records[ausente] = None
    session.scalar.side_effect = records
    assert obter_contexto_inscricao(session, 10, 30, 50, bloquear=True) is None
    assert session.scalar.call_count == ausente + 1
    session.commit.assert_not_called()


@pytest.mark.parametrize("versao", [None, 0, -1])
def test_projecao_recusa_reserva_sem_versao_valida(versao: int | None) -> None:
    session = MagicMock()
    record = Reserva(**asdict(_reserva()))
    record.versao = versao
    session.scalar.return_value = record
    with pytest.raises(ValueError, match="sem versao valida"):
        obter_origem_reserva(session, 30)
    session.commit.assert_not_called()


@pytest.mark.parametrize("bloquear", [False, True])
def test_repositorio_lista_passageiros_da_reserva_em_ordem(bloquear: bool) -> None:
    session = MagicMock()
    records = [PassageiroReserva(**asdict(_passageiro()))]
    session.scalars.return_value.all.return_value = records
    assert PassageiroReservaRepository(session).listar_por_reserva(30, bloquear=bloquear) == records
    statement = session.scalars.call_args.args[0]
    compiled = statement.compile()
    assert "WHERE passageiro_reserva.id_reserva =" in str(compiled)
    assert list(compiled.params.values()) == [30]
    assert "ORDER BY passageiro_reserva.ordem" in str(compiled)
    assert ("FOR UPDATE" in str(compiled)) is bloquear
    assert bool(statement.get_execution_options().get("populate_existing")) is bloquear
    session.commit.assert_not_called()


@pytest.mark.parametrize("quantidade", [None, 0, 2])
def test_repositorio_conta_passageiros_somente_da_reserva(quantidade: int | None) -> None:
    session = MagicMock()
    session.scalar.return_value = quantidade
    assert PassageiroReservaRepository(session).quantidade_por_reserva(30) == (quantidade or 0)
    compiled = session.scalar.call_args.args[0].compile()
    assert "count(passageiro_reserva.id_passageiro)" in str(compiled)
    assert "WHERE passageiro_reserva.id_reserva =" in str(compiled)
    assert list(compiled.params.values()) == [30]
    session.commit.assert_not_called()


def test_cadastro_reserva_ausente_reverte_sem_escrever() -> None:
    session = MagicMock()
    session.scalar.return_value = None
    with pytest.raises(RecursoTurismoNaoEncontradoError, match="reserva nao encontrada"):
        cadastrar_passageiro_reserva(session, 30, PassageiroReservaCreate(ordem=1))
    session.rollback.assert_called_once()
    session.commit.assert_not_called()
    session.add.assert_not_called()
    session.scalars.assert_not_called()


@pytest.mark.parametrize("existe", [False, True])
def test_listagem_valida_reserva_sem_controlar_transacao(existe: bool) -> None:
    session = MagicMock()
    session.scalar.return_value = Reserva(**asdict(_reserva())) if existe else None
    records = [PassageiroReserva(**asdict(_passageiro()))]
    session.scalars.return_value.all.return_value = records
    if existe:
        assert listar_passageiros_reserva(session, 30) == records
    else:
        with pytest.raises(RecursoTurismoNaoEncontradoError, match="reserva nao encontrada"):
            listar_passageiros_reserva(session, 30)
        session.scalars.assert_not_called()
    session.commit.assert_not_called()
    session.rollback.assert_not_called()


def _saida(identifier: int = 10) -> ContextoSaida:
    return ContextoSaida(
        id_saida=identifier,
        id_pacote=20,
        codigo="BT-001",
        data_inicio=date(2026, 9, 20),
        data_fim=date(2026, 9, 20),
        capacidade=10,
        status="ABERTA",
        versao=1,
    )


def _reserva(
    identifier: int = 30,
    *,
    id_saida: int = 10,
) -> OrigemReserva:
    return OrigemReserva(
        id_reserva=identifier,
        codigo_reserva="RES-001",
        id_cliente=40,
        id_pacote=20,
        id_saida=id_saida,
        quantidade_passageiros=2,
        valor_total=Decimal("100.00"),
        status="CONFIRMADA",
        versao=1,
    )


def _passageiro(
    identifier: int = 50,
    *,
    id_reserva: int = 30,
) -> RecursoOrigem:
    return RecursoOrigem(
        id_passageiro=identifier,
        id_reserva=id_reserva,
        ordem=1,
        status="ATIVO",
        versao=1,
    )


def test_projecoes_sao_imutaveis() -> None:
    saida = _saida()

    with pytest.raises(FrozenInstanceError):
        saida.status = "CANCELADA"  # type: ignore[misc]


def test_contexto_inscricao_e_composto_por_projecoes() -> None:
    contexto = ContextoInscricao(
        saida=_saida(),
        reserva=_reserva(),
        passageiro=_passageiro(),
    )

    assert isinstance(contexto.saida, ContextoSaida)
    assert isinstance(contexto.reserva, OrigemReserva)
    assert isinstance(contexto.passageiro, RecursoOrigem)
    assert not isinstance(contexto.passageiro, PassageiroReserva)


def test_fronteira_publica_nao_controla_transacao() -> None:
    source = Path("app/shared/turismo.py").read_text(encoding="utf-8")

    assert ".commit(" not in source
    assert ".rollback(" not in source
    assert ".refresh(" not in source


def test_contexto_inscricao_respeita_ordem_de_locks() -> None:
    session = MagicMock()
    chamadas: list[str] = []

    def registrar_saida(*args: object, **kwargs: object) -> ContextoSaida:
        chamadas.append("saida")
        return _saida()

    def registrar_reserva(*args: object, **kwargs: object) -> OrigemReserva:
        chamadas.append("reserva")
        return _reserva()

    def registrar_passageiro(*args: object, **kwargs: object) -> RecursoOrigem:
        chamadas.append("passageiro")
        return _passageiro()

    with (
        patch(
            "app.shared.turismo.obter_contexto_saida",
            side_effect=registrar_saida,
        ) as obter_saida,
        patch(
            "app.shared.turismo.obter_origem_reserva",
            side_effect=registrar_reserva,
        ) as obter_reserva,
        patch(
            "app.shared.turismo.obter_recurso_origem",
            side_effect=registrar_passageiro,
        ) as obter_passageiro,
    ):
        contexto = obter_contexto_inscricao(
            session,
            10,
            30,
            50,
            bloquear=True,
        )

    assert contexto is not None
    assert chamadas == [
        "saida",
        "reserva",
        "passageiro",
    ]

    obter_saida.assert_called_once_with(
        session,
        10,
        bloquear=True,
    )
    obter_reserva.assert_called_once_with(
        session,
        30,
        bloquear=True,
    )
    obter_passageiro.assert_called_once_with(
        session,
        50,
        bloquear=True,
    )


def test_contexto_rejeita_reserva_de_outra_saida() -> None:
    session = MagicMock()

    with (
        patch(
            "app.shared.turismo.obter_contexto_saida",
            return_value=_saida(),
        ),
        patch(
            "app.shared.turismo.obter_origem_reserva",
            return_value=_reserva(id_saida=999),
        ),
        patch(
            "app.shared.turismo.obter_recurso_origem",
        ) as obter_passageiro,
    ):
        contexto = obter_contexto_inscricao(
            session,
            10,
            30,
            50,
            bloquear=True,
        )

    assert contexto is None
    obter_passageiro.assert_not_called()


def test_contexto_rejeita_passageiro_de_outra_reserva() -> None:
    session = MagicMock()

    with (
        patch(
            "app.shared.turismo.obter_contexto_saida",
            return_value=_saida(),
        ),
        patch(
            "app.shared.turismo.obter_origem_reserva",
            return_value=_reserva(),
        ),
        patch(
            "app.shared.turismo.obter_recurso_origem",
            return_value=_passageiro(id_reserva=999),
        ),
    ):
        contexto = obter_contexto_inscricao(
            session,
            10,
            30,
            50,
            bloquear=True,
        )

    assert contexto is None


def test_cadastro_rejeita_limite_da_reserva() -> None:
    session = MagicMock()

    reserva = SimpleNamespace(
        id_reserva=30,
        quantidade_passageiros=2,
    )
    existentes = [
        SimpleNamespace(ordem=10),
        SimpleNamespace(ordem=20),
    ]

    with (
        patch(
            "app.modules.turismo.services.ReservaRepository.obter",
            return_value=reserva,
        ),
        patch(
            "app.modules.turismo.services.PassageiroReservaRepository.listar_por_reserva",
            return_value=existentes,
        ),
        pytest.raises(
            RegraTurismoError,
            match="quantidade de passageiros",
        ),
    ):
        cadastrar_passageiro_reserva(
            session,
            30,
            PassageiroReservaCreate(ordem=2),
        )

    session.commit.assert_not_called()


def test_cadastro_rejeita_ordem_duplicada() -> None:
    session = MagicMock()

    reserva = SimpleNamespace(
        id_reserva=30,
        quantidade_passageiros=2,
    )
    existentes = [SimpleNamespace(ordem=1)]

    with (
        patch(
            "app.modules.turismo.services.ReservaRepository.obter",
            return_value=reserva,
        ),
        patch(
            "app.modules.turismo.services.PassageiroReservaRepository.listar_por_reserva",
            return_value=existentes,
        ),
        pytest.raises(
            RegraTurismoError,
            match="ordem de passageiro",
        ),
    ):
        cadastrar_passageiro_reserva(
            session,
            30,
            PassageiroReservaCreate(ordem=1),
        )

    session.commit.assert_not_called()


def test_cadastro_rejeita_ordem_acima_da_quantidade() -> None:
    session = MagicMock()

    reserva = SimpleNamespace(
        id_reserva=30,
        quantidade_passageiros=2,
    )

    with (
        patch(
            "app.modules.turismo.services.ReservaRepository.obter",
            return_value=reserva,
        ),
        patch(
            "app.modules.turismo.services.PassageiroReservaRepository.listar_por_reserva",
            return_value=[],
        ),
        pytest.raises(
            RegraTurismoError,
            match="ordem excede",
        ),
    ):
        cadastrar_passageiro_reserva(
            session,
            30,
            PassageiroReservaCreate(ordem=3),
        )

    session.commit.assert_not_called()


def test_cadastro_valido_persiste_no_owner_turismo() -> None:
    session = MagicMock()

    reserva = SimpleNamespace(
        id_reserva=30,
        quantidade_passageiros=2,
    )

    with (
        patch(
            "app.modules.turismo.services.ReservaRepository.obter",
            return_value=reserva,
        ),
        patch(
            "app.modules.turismo.services.PassageiroReservaRepository.listar_por_reserva",
            return_value=[],
        ),
    ):
        passageiro = cadastrar_passageiro_reserva(
            session,
            30,
            PassageiroReservaCreate(ordem=1),
        )

    assert isinstance(passageiro, PassageiroReserva)
    assert passageiro.id_reserva == 30
    assert passageiro.ordem == 1
    assert passageiro.status == "ATIVO"

    session.add.assert_called_once_with(passageiro)
    session.commit.assert_called_once()
    session.refresh.assert_called_once_with(passageiro)
