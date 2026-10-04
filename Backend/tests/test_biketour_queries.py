"""Leituras operacionais sem escrita, com paginaÃƒÂ§ÃƒÂ£o e respostas minimas."""

from datetime import UTC, datetime, timedelta
from types import SimpleNamespace
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest

from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import (
    AlocacaoRecursoBikeTour,
    EventoBikeTour,
    InscricaoBikeTour,
    OperacaoBikeTour,
    PendenciaBikeTour,
    RecursoBikeTour,
)
from app.modules.biketour.queries import ConsultasBikeTour
from app.shared.localidades import localidade_disponivel

NOW = datetime(2026, 9, 23, 12, tzinfo=UTC)


def evento() -> EventoBikeTour:
    return EventoBikeTour(
        id_evento_bike_tour=1, id_saida=1, inicio=NOW, fim=NOW + timedelta(hours=4), capacidade=10
    )


def test_listagem_filtra_evento_status_e_exclusao() -> None:
    session = MagicMock()
    session.get.return_value = evento()
    session.scalars.return_value.all.return_value = [
        PendenciaBikeTour(id_pendencia_bike_tour=1, status="ABERTA")
    ]
    result = ConsultasBikeTour(session).listar(PendenciaBikeTour, 0, 20, 1, "ABERTA")
    assert result[0]["status"] == "ABERTA"
    sql = str(session.scalars.call_args.args[0])
    assert "deleted_at IS NULL" in sql and "LIMIT" in sql and "ORDER BY" in sql
    session.commit.assert_not_called()


@pytest.mark.parametrize("item", [None, EventoBikeTour(deleted_at=NOW)])
def test_leitura_nao_retorna_ausente_ou_excluido(item: object) -> None:
    session = MagicMock()
    session.get.return_value = item
    with pytest.raises(BikeTourError, match="BT_RECURSO_NAO_ENCONTRADO"):
        ConsultasBikeTour(session).obter(EventoBikeTour, 1)


@pytest.mark.parametrize("valida", [False, True])
def test_inscricoes_informam_origem_e_bloqueio_sem_mutar(valida: bool) -> None:
    session = MagicMock()
    session.get.return_value = evento()
    inscricao = InscricaoBikeTour(id_inscricao_bike_tour=1, id_reserva=1, id_passageiro=1)
    alocacao = AlocacaoRecursoBikeTour(id_alocacao_recurso_bike_tour=1, expira_em=NOW)
    session.scalars.return_value.all.side_effect = [[inscricao], [alocacao]]
    origem = (
        SimpleNamespace(
            saida=SimpleNamespace(deleted_at=None, status="ABERTA"),
            reserva=SimpleNamespace(deleted_at=None, status="CONFIRMADA"),
            passageiro=SimpleNamespace(deleted_at=None, status="ATIVO"),
        )
        if valida
        else None
    )
    with patch("app.modules.biketour.queries.obter_contexto_inscricao", return_value=origem):
        result = ConsultasBikeTour(session).inscricoes(1, 0, 20)
    assert result[0]["origem_valida"] is valida
    assert result[0]["expira_em"] == NOW.isoformat()
    session.add.assert_not_called()
    session.flush.assert_not_called()


def test_correlacao_apenas_identificadores_comerciais() -> None:
    session = MagicMock()
    session.get.return_value = InscricaoBikeTour(id_reserva=1)
    origem = SimpleNamespace(id_venda=2, id_item_venda=3, id_contrato=4, valida=True)
    with patch("app.modules.biketour.queries.obter_origem_comercial_reserva", return_value=origem):
        assert ConsultasBikeTour(session).correlacao(1) == {
            "id_reserva": 1,
            "id_venda": 2,
            "id_item_venda": 3,
            "id_contrato": 4,
            "origem_valida": True,
        }


def test_disponibilidade_calcula_saldo_sem_expirar_fisicamente() -> None:
    session = MagicMock()
    session.get.return_value = evento()
    session.scalars.return_value.all.side_effect = [
        [RecursoBikeTour(id_recurso_bike_tour=1)],
        [1, 2],
    ]
    result = ConsultasBikeTour(session).disponibilidade(1, None, None, 0, 20)
    assert result["saldo"] == 8 and result["comprometidas"] == 2
    session.add.assert_not_called()
    with pytest.raises(BikeTourError, match="BT_INTERVALO_INVALIDO"):
        ConsultasBikeTour(session).disponibilidade(1, NOW, NOW, 0, 20)


def test_relatorio_agrega_sem_dados_pessoais() -> None:
    session = MagicMock()
    session.get.return_value = evento()
    session.scalars.return_value.all.side_effect = [
        [InscricaoBikeTour(id_inscricao_bike_tour=1, status="CONCLUIDA")],
        [1, 2],
        ["RESOLVIDA"],
    ]
    result = ConsultasBikeTour(session).relatorio(1)
    assert result["inscricoes"] == {"CONCLUIDA": 1} and result["passagens"] == 2


def test_auditoria_nao_expoe_hashes_ou_resposta_idempotente() -> None:
    session = MagicMock()
    session.get.return_value = evento()
    session.scalars.return_value.all.return_value = [
        OperacaoBikeTour(
            id_operacao_bike_tour=1,
            id_usuario=1,
            operacao="bloquear_inscricao",
            created_at=NOW,
            correlation_id=uuid4(),
            http_status=201,
        )
    ]
    result = ConsultasBikeTour(session).auditoria(1, 0, 20)
    assert set(result[0]) == {"id", "ator", "operacao", "instante", "correlation_id", "status_http"}


@pytest.mark.parametrize("existe", [False, True])
def test_porta_localidade_respeita_catalogo(existe: bool) -> None:
    session = MagicMock()
    session.scalar.return_value = 1 if existe else None
    assert localidade_disponivel(session, 1) is existe


@pytest.mark.parametrize("tipo", ["BICICLETA", "EQUIPAMENTO"])
def test_disponibilidade_inclui_recurso_proprio_sem_patrimonio(tipo: str) -> None:
    session = MagicMock()
    session.get.return_value = evento()
    recursos = [
        RecursoBikeTour(id_recurso_bike_tour=i, tipo=tipo, status="DISPONIVEL") for i in (1, 2)
    ]
    session.scalars.return_value.all.side_effect = [recursos, []]
    with patch("app.modules.biketour.queries.obter_situacao_recurso_origem") as origem:
        result = ConsultasBikeTour(session).disponibilidade(1, None, None, 1, 1)
    publicados = result["recursos"]
    assert isinstance(publicados, list)
    assert [item["id"] for item in publicados] == [2]
    origem.assert_not_called()
    session.add.assert_not_called()
    session.flush.assert_not_called()
    session.commit.assert_not_called()


def test_disponibilidade_revalida_origem_publica() -> None:
    session = MagicMock()
    session.get.return_value = evento()

    recurso_valido = RecursoBikeTour(
        id_recurso_bike_tour=1,
        tipo="BICICLETA",
        id_ativo=101,
        status="DISPONIVEL",
    )
    recurso_invalido = RecursoBikeTour(
        id_recurso_bike_tour=2,
        tipo="BICICLETA",
        id_ativo=102,
        status="DISPONIVEL",
    )

    session.scalars.return_value.all.side_effect = [
        [recurso_valido, recurso_invalido],
        [],
    ]

    origem_valida = MagicMock(
        existe=True,
        permitido=True,
    )
    origem_invalida = MagicMock(
        existe=True,
        permitido=False,
    )

    with patch(
        "app.modules.biketour.queries.obter_situacao_recurso_origem",
        side_effect=[origem_valida, origem_invalida],
    ) as origem:
        result = ConsultasBikeTour(session).disponibilidade(
            1,
            None,
            None,
            0,
            20,
        )

    recursos = result["recursos"]

    assert isinstance(recursos, list)
    assert len(recursos) == 1

    assert origem.call_count == 2
    origem.assert_any_call(
        session,
        "BICICLETA",
        101,
    )
    origem.assert_any_call(
        session,
        "BICICLETA",
        102,
    )

    session.add.assert_not_called()
    session.commit.assert_not_called()


def test_disponibilidade_pagina_apos_revalidar_origem() -> None:
    session = MagicMock()
    session.get.return_value = evento()

    recurso_invalido = RecursoBikeTour(
        id_recurso_bike_tour=1,
        tipo="BICICLETA",
        status="DISPONIVEL",
        id_ativo=10,
    )
    recurso_valido = RecursoBikeTour(
        id_recurso_bike_tour=2,
        tipo="BICICLETA",
        status="DISPONIVEL",
        id_ativo=20,
    )

    session.scalars.return_value.all.side_effect = [
        [recurso_invalido, recurso_valido],
        [],
    ]

    origem_invalida = SimpleNamespace(
        tipo="BICICLETA",
        identificador=10,
        existe=True,
        permitido=False,
    )
    origem_valida = SimpleNamespace(
        tipo="BICICLETA",
        identificador=20,
        existe=True,
        permitido=True,
    )

    with patch(
        "app.modules.biketour.queries.obter_situacao_recurso_origem",
        side_effect=[origem_invalida, origem_valida],
    ) as origem:
        result = ConsultasBikeTour(session).disponibilidade(
            1,
            None,
            None,
            0,
            1,
        )

    recursos = result["recursos"]

    assert isinstance(recursos, list)
    assert len(recursos) == 1
    assert origem.call_count == 2
    assert origem.call_args_list[0].args[2] == 10
    assert origem.call_args_list[1].args[2] == 20


def test_disponibilidade_ignora_tipo_de_recurso_desconhecido() -> None:
    session = MagicMock()
    session.get.return_value = evento()

    recurso = RecursoBikeTour(
        id_recurso_bike_tour=1,
        tipo="DESCONHECIDO",
        id_ativo=101,
        status="DISPONIVEL",
    )

    session.scalars.return_value.all.side_effect = [
        [recurso],
        [],
    ]

    with patch(
        "app.modules.biketour.queries.obter_situacao_recurso_origem",
    ) as origem:
        result = ConsultasBikeTour(session).disponibilidade(
            1,
            None,
            None,
            0,
            20,
        )

    assert result["recursos"] == []
    origem.assert_not_called()
    session.add.assert_not_called()
    session.commit.assert_not_called()


def test_disponibilidade_exclui_origem_inexistente() -> None:
    session = MagicMock()
    session.get.return_value = evento()

    recurso = RecursoBikeTour(
        id_recurso_bike_tour=1,
        tipo="BICICLETA",
        id_ativo=101,
        status="DISPONIVEL",
    )

    session.scalars.return_value.all.side_effect = [
        [recurso],
        [],
    ]

    origem_inexistente = MagicMock(
        existe=False,
        permitido=False,
    )

    with patch(
        "app.modules.biketour.queries.obter_situacao_recurso_origem",
        return_value=origem_inexistente,
    ):
        result = ConsultasBikeTour(session).disponibilidade(
            1,
            None,
            None,
            0,
            20,
        )

    assert result["recursos"] == []
    session.add.assert_not_called()
    session.commit.assert_not_called()


def test_disponibilidade_propaga_falha_da_porta_publica() -> None:
    session = MagicMock()
    session.get.return_value = evento()

    recurso = RecursoBikeTour(
        id_recurso_bike_tour=1,
        tipo="BICICLETA",
        id_ativo=101,
        status="DISPONIVEL",
    )

    session.scalars.return_value.all.return_value = [recurso]

    with (
        patch(
            "app.modules.biketour.queries.obter_situacao_recurso_origem",
            side_effect=RuntimeError("dependencia indisponivel"),
        ),
        pytest.raises(
            RuntimeError,
            match="dependencia indisponivel",
        ),
    ):
        ConsultasBikeTour(session).disponibilidade(
            1,
            None,
            None,
            0,
            20,
        )

    session.add.assert_not_called()
    session.commit.assert_not_called()


def test_auditoria_associa_operacoes_da_inscricao_ao_evento() -> None:
    session = MagicMock()
    session.get.return_value = evento()

    operacao = OperacaoBikeTour(
        id_operacao_bike_tour=10,
        id_usuario=1,
        operacao="acao_inscricao",
        alvo=77,
        chave_hash="a" * 64,
        payload_hash="b" * 64,
        http_status=200,
        resultado={"id": 77, "status": "CONFIRMADA"},
        correlation_id=uuid4(),
        created_by="pytest",
        created_at=NOW,
    )

    session.scalars.return_value.all.return_value = [operacao]

    result = ConsultasBikeTour(session).auditoria(1, 0, 20)

    assert len(result) == 1
    assert result[0]["id"] == 10
    assert result[0]["operacao"] == "acao_inscricao"

    statement = session.scalars.call_args.args[0]
    sql = str(statement)
    params = statement.compile().params

    assert "inscricao_bike_tour" in sql
    assert "id_evento_bike_tour" in sql

    operation_values = {
        value
        for value in params.values()
        if isinstance(value, list | tuple | set)
        for value in value
    }

    assert {
        "acao_inscricao",
        "reacomodar_recursos",
        "registrar_passagem",
        "avaliar_inscricao",
    } <= operation_values
