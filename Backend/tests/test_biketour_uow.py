"""Contrato da unidade de trabalho: autorizacao, replay e falhas atomicas."""

from unittest.mock import MagicMock
from uuid import uuid4

import pytest
from sqlalchemy.exc import IntegrityError, OperationalError, TimeoutError

from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.models import OperacaoBikeTour, PendenciaBikeTour
from app.modules.biketour.uow import BikeTourUnitOfWork, ContextoComando, ResultadoComando
from app.modules.seguranca.rbac import ContextoRbac


def _actor(*permissions: str) -> ContextoRbac:
    return ContextoRbac(1, ("ADMIN",), frozenset(permissions))


@pytest.fixture
def session() -> MagicMock:
    session = MagicMock()
    session.in_transaction.return_value = False
    session.scalar.return_value = None
    return session


def _execute(session: MagicMock, **overrides: object) -> ResultadoComando:
    args = {
        "ator": _actor("BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_OPERAR"),
        "permissao": "BIKE_TOUR_OPERAR",
        "correlation_id": uuid4(),
        "operacao": "criar_recurso",
        "alvo": 0,
        "chave": "chave-opaca",
        "payload": {"codigo": "BT-1"},
        "comando": lambda ctx: ResultadoComando(201, {"id": 1}),
        **overrides,
    }
    return BikeTourUnitOfWork(session).executar(**args)  # type: ignore[arg-type]


def test_sucesso_persiste_hashes_e_resultado_com_um_commit(session: MagicMock) -> None:
    result = _execute(session)
    assert result == ResultadoComando(201, {"id": 1})
    session.begin.assert_called_once()
    session.connection.assert_called_once_with(
        execution_options={"isolation_level": "READ COMMITTED"}
    )
    assert [str(call.args[0]) for call in session.execute.call_args_list] == [
        "SET LOCAL lock_timeout = '5s'",
        "SELECT pg_advisory_xact_lock(2700, 1)",
    ]
    operation = session.add.call_args.args[0]
    assert operation.created_by == "1"
    assert len(operation.chave_hash) == len(operation.payload_hash) == 64
    assert operation.resultado == {"id": 1}
    assert operation.resultado is not result.corpo
    session.flush.assert_called_once()
    session.commit.assert_not_called()
    session.begin.return_value.__exit__.assert_called_once_with(None, None, None)


@pytest.mark.parametrize("permissions", [(), ("BIKE_TOUR_OPERAR",), ("BIKE_TOUR_VISUALIZAR",)])
def test_admin_sem_permissao_explicita_nao_consulta_replay(
    session: MagicMock, permissions: tuple[str, ...]
) -> None:
    with pytest.raises(BikeTourError) as error:
        _execute(session, ator=_actor(*permissions))
    assert error.value.status_code == 403
    session.begin.assert_not_called()
    session.scalar.assert_not_called()


@pytest.mark.parametrize(
    "overrides", [{"chave": ""}, {"chave": "x" * 101}, {"operacao": "!"}, {"alvo": -1}]
)
def test_comando_invalido_nao_inicia_transacao(
    session: MagicMock, overrides: dict[str, object]
) -> None:
    with pytest.raises(BikeTourError) as error:
        _execute(session, **overrides)
    assert error.value.status_code == 422
    session.begin.assert_not_called()


def test_rejeita_transacao_preexistente_sem_confirma_la(session: MagicMock) -> None:
    session.in_transaction.return_value = True
    with pytest.raises(RuntimeError, match="preexistente"):
        _execute(session)
    session.begin.assert_not_called()
    session.commit.assert_not_called()


def test_replay_preserva_corpo_sem_reexecutar_ou_alterar_historico(session: MagicMock) -> None:
    _execute(session)
    operation = session.add.call_args.args[0]
    session.reset_mock()
    session.scalar.return_value = operation
    handler = MagicMock()
    result = _execute(session, comando=handler)
    assert result.corpo == operation.resultado
    assert result.corpo is not operation.resultado
    handler.assert_not_called()
    session.add.assert_not_called()


def test_replay_com_payload_divergente_reverte_transacao(session: MagicMock) -> None:
    session.scalar.return_value = OperacaoBikeTour(payload_hash="outro")
    with pytest.raises(BikeTourError) as error:
        _execute(session)
    assert error.value.code == "BT_CHAVE_REUTILIZADA"
    assert session.begin.return_value.__exit__.call_args.args[0] is BikeTourError
    session.add.assert_not_called()


def test_resultado_de_erro_nao_e_persistido(session: MagicMock) -> None:
    with pytest.raises(RuntimeError, match="bem-sucedidos"):
        _execute(session, comando=lambda ctx: ResultadoComando(409, {}))
    session.add.assert_not_called()


@pytest.mark.parametrize("sqlstate", ["55P03", "40P01", "08006"])
def test_falha_postgresql_reverte_e_mapeia_sem_expor_sql(session: MagicMock, sqlstate: str) -> None:
    original = MagicMock()
    original.sqlstate = sqlstate
    session.execute.side_effect = OperationalError("SQL privado", {}, original)
    with pytest.raises(BikeTourError) as error:
        _execute(session)
    assert error.value.status_code == (503 if sqlstate == "08006" else 409)
    assert "SQL" not in str(error.value)
    session.add.assert_not_called()


@pytest.mark.parametrize(
    ("exception", "status"),
    [(IntegrityError("SQL privado", {}, Exception()), 409), (TimeoutError(), 503)],
)
def test_falha_de_commit_ou_pool_reverte(
    session: MagicMock, exception: Exception, status: int
) -> None:
    session.begin.return_value.__exit__.side_effect = exception
    with pytest.raises(BikeTourError) as error:
        _execute(session)
    assert error.value.status_code == status


def test_pendencia_e_resultado_compartilham_transacao(session: MagicMock) -> None:
    def handler(ctx: ContextoComando) -> ResultadoComando:
        ctx.pendencias.append(
            PendenciaBikeTour(id_evento_bike_tour=1, tipo="CANCELAMENTO", motivo="CLIMA")
        )
        return ResultadoComando(200, {"id_evento_bike_tour": 1})

    def add(item: object) -> None:
        if isinstance(item, OperacaoBikeTour):
            item.id_operacao_bike_tour = 42

    session.add.side_effect = add
    _execute(session, comando=handler)
    pendencia = session.add.call_args.args[0]
    assert pendencia.id_operacao_bike_tour == 42
    assert session.flush.call_count == 2


def test_aliases_historicos_biketour_continuam_compativeis(
    session: MagicMock,
) -> None:
    result = _execute(
        session,
        ator=_actor(
            "BIKETOUR_VISUALIZAR",
            "BIKETOUR_OPERAR",
        ),
        permissao="BIKETOUR_OPERAR",
    )

    assert result == ResultadoComando(
        201,
        {"id": 1},
    )


def test_alias_historico_nao_cria_heranca_implicita(
    session: MagicMock,
) -> None:
    with pytest.raises(BikeTourError) as error:
        _execute(
            session,
            ator=_actor(
                "BIKETOUR_VISUALIZAR",
                "BIKETOUR_GERENCIAR",
            ),
            permissao="BIKETOUR_OPERAR",
        )

    assert error.value.status_code == 403
    session.begin.assert_not_called()
