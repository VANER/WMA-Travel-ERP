"""Projecoes operacionais imutaveis, sem PII, escrita ou controle de transacao."""

from dataclasses import FrozenInstanceError, asdict
from datetime import UTC, datetime
from typing import Any, Literal, cast
from unittest.mock import MagicMock, patch

import pytest
from sqlalchemy.dialects import postgresql
from sqlalchemy.engine import Dialect

from app.modules.comercial.models import Contrato, ItemVenda, Venda
from app.modules.turismo.models import (
    AlocacaoVaga,
    PacoteViagem,
    ProdutoTuristico,
    ReservaCorrelacao,
)
from app.shared.turismo import (
    ContextoSaida,
    OrigemComercialReserva,
    obter_bloqueio_turistico,
    obter_catalogo_saida,
    obter_origem_comercial_reserva,
    obter_produto_origem,
    obter_situacao_recurso_origem,
)
from app.shared.vendas import obter_contrato, obter_item_venda, obter_venda_financeira

NOW = datetime(2026, 9, 15, tzinfo=UTC)


def _postgresql_dialect() -> Dialect:
    factory = cast(Any, postgresql.dialect)
    return cast(Dialect, factory())


@pytest.mark.parametrize("lock", [False, True])
def test_produto_imutavel_sem_pii_com_leitura_protegida(lock: bool) -> None:
    session = MagicMock()
    record = ProdutoTuristico(id_produto=1, tipo_produto="CICLOTURISMO", ativo=True, versao=2)
    session.scalar.return_value = record
    result = obter_produto_origem(session, 1, bloquear=lock)
    assert result is not None
    assert asdict(result) == {"id_produto": 1, "tipo": "CICLOTURISMO", "ativo": True, "versao": 2}
    sql = str(session.scalar.call_args.args[0].compile(dialect=_postgresql_dialect()))
    assert ("FOR SHARE" in sql) is lock
    record.ativo = False
    assert result.ativo
    with pytest.raises(FrozenInstanceError):
        result.ativo = False  # type: ignore[misc]
    session.commit.assert_not_called()
    session.add.assert_not_called()


def test_produto_ausente_ou_excluido() -> None:
    session = MagicMock()
    session.scalar.return_value = None
    assert obter_produto_origem(session, 1) is None
    session.scalar.return_value = ProdutoTuristico(
        id_produto=1, tipo_produto="CICLOTURISMO", ativo=True, deleted_at=NOW
    )
    result = obter_produto_origem(session, 1)
    assert result is not None and not result.ativo


@pytest.mark.parametrize("lock", [False, True])
@pytest.mark.parametrize("missing", [None, "pacote", "produto"])
def test_catalogo_reutiliza_pacote_e_produto(lock: bool, missing: str | None) -> None:
    session = MagicMock()
    departure = ContextoSaida(1, 2, "S1", NOW.date(), NOW.date(), 10, "PLANEJADA", 1)
    package = PacoteViagem(id_pacote=2, id_produto=3, status="ATIVO")
    product = ProdutoTuristico(id_produto=3, tipo_produto="CICLOTURISMO", ativo=True)
    session.scalar.side_effect = [
        None if missing == "pacote" else package,
        None if missing == "produto" else product,
    ]
    result = obter_catalogo_saida(session, departure, bloquear=lock)
    if missing is None:
        assert result is not None and result.elegivel and result.produto.id_produto == 3
    else:
        assert result is None
    session.commit.assert_not_called()


@pytest.mark.parametrize("expiry", [None, NOW, NOW.replace(tzinfo=None)])
@pytest.mark.parametrize("lock", [False, True])
def test_bloqueio_converte_utc_legado_sem_horario_local(
    expiry: datetime | None, lock: bool
) -> None:
    session = MagicMock()
    session.scalar.return_value = AlocacaoVaga(status="BLOQUEADA", expira_em=expiry)
    result = obter_bloqueio_turistico(session, 1, bloquear=lock)
    assert result is not None and result.status == "BLOQUEADA"
    assert result.expira_em == (NOW if expiry is not None else None)
    sql = str(session.scalar.call_args.args[0].compile(dialect=_postgresql_dialect()))
    assert ("FOR SHARE" in sql) is lock
    session.commit.assert_not_called()


def test_bloqueio_e_correlacao_ausentes_sao_distintos_de_falha() -> None:
    session = MagicMock()
    session.scalar.return_value = None
    assert obter_bloqueio_turistico(session, 1) is None
    assert obter_origem_comercial_reserva(session, 1) == OrigemComercialReserva(
        None, None, None, True
    )
    session.scalar.side_effect = RuntimeError("fonte indisponivel")
    with pytest.raises(RuntimeError, match="fonte indisponivel"):
        obter_origem_comercial_reserva(session, 1)


@pytest.mark.parametrize(
    "failure",
    [None, "venda", "item", "contrato", "item_incompativel", "contrato_incompativel", "excluido"],
)
@pytest.mark.parametrize("lock", [False, True])
def test_correlacao_valida_preserva_somente_ids(failure: str | None, lock: bool) -> None:
    session = MagicMock()
    session.scalar.return_value = ReservaCorrelacao(id_venda=1, id_item_venda=2, id_contrato=3)
    venda = Venda(id_venda=1, deleted_at=NOW if failure == "excluido" else None)
    item = ItemVenda(id_item=2, id_venda=9 if failure == "item_incompativel" else 1)
    contract = Contrato(id_contrato=3, id_venda=9 if failure == "contrato_incompativel" else 1)
    with (
        patch(
            "app.shared.turismo.obter_venda_financeira",
            return_value=None if failure == "venda" else venda,
        ),
        patch(
            "app.shared.turismo.obter_item_venda", return_value=None if failure == "item" else item
        ),
        patch(
            "app.shared.turismo.obter_contrato",
            return_value=None if failure == "contrato" else contract,
        ),
    ):
        result = obter_origem_comercial_reserva(session, 10, bloquear=lock)
    assert result == OrigemComercialReserva(1, 2, 3, failure is None)
    sql = str(session.scalar.call_args.args[0].compile(dialect=_postgresql_dialect()))
    assert ("FOR SHARE" in sql) is lock
    session.commit.assert_not_called()
    session.add.assert_not_called()


def test_portas_comerciais_protegem_referencias_sem_commit() -> None:
    session = MagicMock()
    for function, table in [
        (obter_venda_financeira, "venda"),
        (obter_item_venda, "item_venda"),
        (obter_contrato, "contrato"),
    ]:
        function(session, 7, bloquear=True)
        statement = session.scalar.call_args.args[0]
        sql = str(statement.compile(dialect=_postgresql_dialect()))
        assert f"FROM {table}" in sql and "FOR SHARE" in sql
        assert statement.get_execution_options()["populate_existing"]
    session.commit.assert_not_called()
    session.add.assert_not_called()


def test_correlacao_com_contrato_sem_venda_permitida() -> None:
    session = MagicMock()
    session.scalar.return_value = ReservaCorrelacao(id_contrato=3)
    with patch("app.shared.turismo.obter_contrato", return_value=Contrato(id_contrato=3)):
        assert obter_origem_comercial_reserva(session, 10) == OrigemComercialReserva(
            None, None, 3, True
        )


@pytest.mark.parametrize("kind", ["BICICLETA", "EQUIPAMENTO", "GUIA", "VEICULO"])
@pytest.mark.parametrize("lock", [False, True])
def test_recurso_le_apenas_colunas_existentes(
    kind: Literal["BICICLETA", "EQUIPAMENTO", "GUIA", "VEICULO"], lock: bool
) -> None:
    session = MagicMock()
    query = session.execute.return_value.mappings.return_value.one_or_none
    query.return_value = {"deleted_at": None, "status": "ATIVO"}
    result = obter_situacao_recurso_origem(session, kind, 7, bloquear=lock)
    assert result.existe and result.permitido and result.identificador == 7
    sql = str(session.execute.call_args.args[0])
    assert ("FOR SHARE" in sql) is lock
    if kind in {"GUIA", "VEICULO"}:
        assert "'ATIVO' AS status" in sql
    for row in [
        None,
        {"deleted_at": NOW, "status": "ATIVO"},
        {"deleted_at": None, "status": "BAIXADO"},
    ]:
        query.return_value = row
        result = obter_situacao_recurso_origem(session, kind, 7)
        assert result.existe is (row is not None)
        assert not result.permitido
    session.commit.assert_not_called()
    session.add.assert_not_called()
