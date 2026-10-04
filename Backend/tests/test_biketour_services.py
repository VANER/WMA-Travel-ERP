"""Testes comportamentais dos casos de uso Produto e Evento Bike Tour."""

from collections.abc import Callable
from datetime import UTC, date, datetime
from types import SimpleNamespace
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.modules.biketour.errors import BikeTourError
from app.modules.biketour.schemas import (
    EventoAcaoRequest,
    EventoCreate,
    EventoUpdate,
    ProdutoCreate,
    ProdutoUpdate,
)
from app.modules.biketour.services import (
    acionar_evento,
    alterar_evento,
    alterar_produto,
    criar_evento,
    criar_produto,
)
from app.modules.biketour.uow import ContextoComando, PermissaoComando, ResultadoComando
from app.modules.seguranca.rbac import ContextoRbac

NOW = datetime(2026, 9, 21, 12, tzinfo=UTC)
ATOR = ContextoRbac(7, (), frozenset({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}))


def _produto(**changes: object) -> SimpleNamespace:
    values: dict[str, object] = {
        "id_produto_bike_tour": 10,
        "id_produto": 20,
        "distancia_km": 12.5,
        "desnivel_m": 240,
        "nivel": "INTERMEDIARIO",
        "ativo": True,
        "versao": 1,
        "created_at": NOW,
        "updated_at": None,
        "deleted_at": None,
    }
    values.update(changes)
    return SimpleNamespace(**values)


def _evento(**changes: object) -> SimpleNamespace:
    values: dict[str, object] = {
        "id_evento_bike_tour": 30,
        "id_saida": 40,
        "inicio": NOW,
        "fim": NOW.replace(hour=16),
        "capacidade": 12,
        "status": "PLANEJADO",
        "versao": 1,
        "created_at": NOW,
        "updated_at": None,
        "deleted_at": None,
    }
    values.update(changes)
    return SimpleNamespace(**values)


def _inline_executor(session: MagicMock) -> Callable[..., object]:
    def execute(
        _session: Session,
        _context: ContextoRbac,
        _permission: PermissaoComando,
        _operation: str,
        _target: int,
        _key: str,
        _payload: dict[str, object],
        command: Callable[[ContextoComando], ResultadoComando],
    ) -> object:
        return command(ContextoComando(session, ATOR, uuid4(), NOW)).corpo

    return execute


def _persistido(item: object) -> None:
    for field, value in {
        "id_produto_bike_tour": 10,
        "id_evento_bike_tour": 30,
        "versao": 1,
        "created_at": NOW,
        "updated_at": None,
        "status": "PLANEJADO",
    }.items():
        setattr(item, field, value)


def _saida(**changes: object) -> SimpleNamespace:
    values: dict[str, object] = {
        "id_saida": 40,
        "id_pacote": 50,
        "data_inicio": date(2026, 9, 20),
        "data_fim": date(2026, 9, 25),
        "capacidade": 20,
        "status": "ABERTA",
        "deleted_at": None,
    }
    values.update(changes)
    return SimpleNamespace(**values)


def _produto_payload(**changes: object) -> ProdutoCreate:
    values: dict[str, object] = {
        "id_produto": 20,
        "distancia_km": "12.50",
        "desnivel_m": "240.00",
        "nivel": "INTERMEDIARIO",
        "chave_idempotencia": "produto-service-1",
    }
    values.update(changes)
    return ProdutoCreate(**values)


def _evento_payload(**changes: object) -> EventoCreate:
    values: dict[str, object] = {
        "id_saida": 40,
        "inicio": NOW,
        "fim": NOW.replace(hour=16),
        "capacidade": 12,
        "chave_idempotencia": "evento-service-1",
    }
    values.update(changes)
    return EventoCreate(**values)


def test_criar_produto_valida_origem_e_persiste() -> None:
    session = MagicMock()
    session.scalar.return_value = None
    session.add.side_effect = _persistido
    origem = SimpleNamespace(ativo=True, tipo="CICLOTURISMO")
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        patch("app.modules.biketour.services.obter_produto_origem", return_value=origem),
    ):
        result = criar_produto(session, ATOR, _produto_payload())
    assert result["id_produto"] == 20
    session.add.assert_called_once()


@pytest.mark.parametrize(
    ("origem", "code"),
    (
        (None, "BT_PRODUTO_ORIGEM_NAO_ENCONTRADO"),
        (SimpleNamespace(ativo=False, tipo="CICLOTURISMO"), "BT_PRODUTO_ORIGEM_INCOMPATIVEL"),
        (SimpleNamespace(ativo=True, tipo="HOTEL"), "BT_PRODUTO_ORIGEM_INCOMPATIVEL"),
    ),
)
def test_criar_produto_rejeita_origem_invalida(origem: object, code: str) -> None:
    session = MagicMock()
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        patch("app.modules.biketour.services.obter_produto_origem", return_value=origem),
        pytest.raises(BikeTourError, match=code),
    ):
        criar_produto(session, ATOR, _produto_payload())


def test_criar_produto_rejeita_duplicidade() -> None:
    session = MagicMock()
    session.scalar.return_value = _produto()
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        patch(
            "app.modules.biketour.services.obter_produto_origem",
            return_value=SimpleNamespace(ativo=True, tipo="CICLOTURISMO"),
        ),
        pytest.raises(BikeTourError, match="BT_PRODUTO_DUPLICADO"),
    ):
        criar_produto(session, ATOR, _produto_payload())


def test_alterar_produto_atualiza_atributos() -> None:
    session = MagicMock()
    item = _produto()
    session.get.return_value = item
    payload = ProdutoUpdate(
        distancia_km="15.00", ativo=False, versao_esperada=1, chave_idempotencia="produto-service-2"
    )
    with patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)):
        result = alterar_produto(session, ATOR, 10, payload)
    assert result["ativo"] is False
    assert item.distancia_km == payload.distancia_km


@pytest.mark.parametrize(
    ("item", "code"),
    ((None, "BT_PRODUTO_NAO_ENCONTRADO"), (_produto(versao=2), "BT_VERSAO_DIVERGENTE")),
)
def test_alterar_produto_rejeita_inexistente_ou_versao(item: object, code: str) -> None:
    session = MagicMock()
    session.get.return_value = item
    payload = ProdutoUpdate(ativo=False, versao_esperada=1, chave_idempotencia="produto-service-3")
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        pytest.raises(BikeTourError, match=code),
    ):
        alterar_produto(session, ATOR, 10, payload)


def test_criar_evento_valida_saida_periodo_e_capacidade() -> None:
    session = MagicMock()
    saida = _saida()
    session.add.side_effect = _persistido
    session.scalar.return_value = _produto()
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        patch("app.modules.biketour.services.obter_contexto_saida", return_value=saida),
        patch(
            "app.modules.biketour.services.obter_catalogo_saida",
            return_value=SimpleNamespace(
                elegivel=True, produto=SimpleNamespace(id_produto=20, tipo="CICLOTURISMO")
            ),
        ),
    ):
        result = criar_evento(session, ATOR, _evento_payload())
    assert result["id_saida"] == 40
    assert result["status"] == "PLANEJADO"


@pytest.mark.parametrize(
    ("saida", "catalogo", "payload", "code"),
    (
        (
            _saida(status="CANCELADA"),
            None,
            _evento_payload(),
            "BT_SAIDA_ORIGEM_INCOMPATIVEL",
        ),
        (_saida(), None, _evento_payload(), "BT_SAIDA_ORIGEM_INCOMPATIVEL"),
        (
            _saida(data_fim=date(2026, 9, 20)),
            SimpleNamespace(
                elegivel=True, produto=SimpleNamespace(id_produto=20, tipo="CICLOTURISMO")
            ),
            _evento_payload(fim=NOW.replace(hour=20)),
            "BT_PERIODO_FORA_DA_SAIDA",
        ),
        (
            _saida(capacidade=5),
            SimpleNamespace(
                elegivel=True, produto=SimpleNamespace(id_produto=20, tipo="CICLOTURISMO")
            ),
            _evento_payload(),
            "BT_CAPACIDADE_SAIDA",
        ),
    ),
)
def test_criar_evento_rejeita_regras_de_origem(
    saida: object, catalogo: object, payload: EventoCreate, code: str
) -> None:
    session = MagicMock()
    if catalogo is not None:
        session.scalar.return_value = _produto()
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        patch("app.modules.biketour.services.obter_contexto_saida", return_value=saida),
        patch("app.modules.biketour.services.obter_catalogo_saida", return_value=catalogo),
        pytest.raises(BikeTourError, match=code) as error,
    ):
        criar_evento(session, ATOR, payload)
    assert error.value.status_code == 409
    assert error.value.code == code
    session.add.assert_not_called()


def test_criar_evento_rejeita_produto_bike_tour_inativo() -> None:
    session = MagicMock()
    session.scalar.return_value = _produto(ativo=False)

    catalogo = SimpleNamespace(
        elegivel=True,
        produto=SimpleNamespace(
            id_produto=20,
            tipo="CICLOTURISMO",
        ),
    )

    with (
        patch(
            "app.modules.biketour.services._executar",
            side_effect=_inline_executor(session),
        ),
        patch(
            "app.modules.biketour.services.obter_contexto_saida",
            return_value=_saida(),
        ),
        patch(
            "app.modules.biketour.services.obter_catalogo_saida",
            return_value=catalogo,
        ),
        pytest.raises(
            BikeTourError,
            match="BT_PRODUTO_INCOMPATIVEL",
        ) as error,
    ):
        criar_evento(
            session,
            ATOR,
            _evento_payload(),
        )
    assert error.value.status_code == 409
    assert error.value.code == "BT_PRODUTO_INCOMPATIVEL"
    session.add.assert_not_called()


def test_criar_evento_mapeia_integridade_para_conflito() -> None:
    session = MagicMock()
    session.in_transaction.return_value = False
    session.scalar.side_effect = [None, _produto()]
    session.flush.side_effect = IntegrityError("duplicate", {}, Exception())
    with (
        patch("app.modules.biketour.services.obter_contexto_saida", return_value=_saida()),
        patch(
            "app.modules.biketour.services.obter_catalogo_saida",
            return_value=SimpleNamespace(
                elegivel=True, produto=SimpleNamespace(id_produto=20, tipo="CICLOTURISMO")
            ),
        ),
        pytest.raises(BikeTourError, match="BT_CONFLITO_INTEGRIDADE"),
    ):
        criar_evento(session, ATOR, _evento_payload())


def test_alterar_evento_atualiza_periodo_e_capacidade() -> None:
    session = MagicMock()
    session.scalar.return_value = None
    item = _evento()
    session.get.return_value = item
    payload = EventoUpdate(
        inicio=NOW.replace(hour=13),
        fim=NOW.replace(hour=17),
        capacidade=10,
        versao_esperada=1,
        chave_idempotencia="evento-service-2",
    )
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        patch("app.modules.biketour.services.obter_contexto_saida", return_value=_saida()),
    ):
        result = alterar_evento(session, ATOR, 30, payload)
    assert result["capacidade"] == 10
    assert item.status == "PLANEJADO"


@pytest.mark.parametrize(
    ("item", "code"),
    (
        (None, "BT_EVENTO_NAO_ENCONTRADO"),
        (_evento(status="ABERTO"), "BT_EVENTO_ESTADO_INCOMPATIVEL"),
    ),
)
def test_alterar_evento_rejeita_estado_ou_inexistencia(item: object, code: str) -> None:
    session = MagicMock()
    session.get.return_value = item
    payload = EventoUpdate(capacidade=10, versao_esperada=1, chave_idempotencia="evento-service-3")
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        pytest.raises(BikeTourError, match=code),
    ):
        alterar_evento(session, ATOR, 30, payload)


@pytest.mark.parametrize(
    ("status", "acao", "motivo", "destino"),
    (
        ("PLANEJADO", "ABRIR", None, "ABERTO"),
        ("ABERTO", "INICIAR", None, "EM_EXECUCAO"),
        ("EM_EXECUCAO", "CONCLUIR", "OPERACIONAL", "CONCLUIDO"),
        ("PLANEJADO", "CANCELAR", "CLIMA", "CANCELADO"),
    ),
)
def test_acionar_evento_aplica_transicoes(
    status: str, acao: str, motivo: str | None, destino: str
) -> None:
    session = MagicMock()
    session.scalar.return_value = None
    item = _evento(status=status)
    session.get.return_value = item
    payload = EventoAcaoRequest(
        acao=acao, motivo=motivo, versao_esperada=1, chave_idempotencia=f"acao-{acao}"
    )
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        patch("app.modules.biketour.services._validar_preparacao"),
        patch("app.modules.biketour.services.obter_contexto_saida", return_value=_saida()),
        patch(
            "app.modules.biketour.services.obter_catalogo_saida",
            return_value=SimpleNamespace(
                elegivel=True, produto=SimpleNamespace(id_produto=20, tipo="CICLOTURISMO")
            ),
        ),
    ):
        result = acionar_evento(session, ATOR, 30, payload)
    assert result["status"] == destino


def test_acionar_evento_rejeita_motivo_ausente_e_transicao_invalida() -> None:
    session = MagicMock()
    session.get.return_value = _evento(status="PLANEJADO")
    sem_motivo = EventoAcaoRequest(acao="CANCELAR", versao_esperada=1, chave_idempotencia="acao-1")
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        pytest.raises(BikeTourError, match="BT_MOTIVO_OBRIGATORIO"),
    ):
        acionar_evento(session, ATOR, 30, sem_motivo)
    invalida = EventoAcaoRequest(
        acao="CONCLUIR", motivo="OPERACIONAL", versao_esperada=1, chave_idempotencia="acao-2"
    )
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        pytest.raises(BikeTourError, match="BT_TRANSICAO_EVENTO_INVALIDA"),
    ):
        acionar_evento(session, ATOR, 30, invalida)


def _acao(acao: str) -> EventoAcaoRequest:
    return EventoAcaoRequest(
        acao=acao, motivo="OPERACIONAL", versao_esperada=1, chave_idempotencia="revisao-acao"
    )


@pytest.mark.parametrize("excluido", [False, True])
def test_acao_rejeita_evento_ausente_ou_excluido(excluido: bool) -> None:
    session = MagicMock()
    session.get.return_value = _evento(deleted_at=NOW) if excluido else None
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        pytest.raises(BikeTourError, match="BT_EVENTO_NAO_ENCONTRADO"),
    ):
        acionar_evento(session, ATOR, 30, _acao("ABRIR"))
    session.flush.assert_not_called()


@pytest.mark.parametrize("acao", ["CONCLUIR"])
def test_terminal_rejeita_inscricoes_ativas_sem_mudar_estado(acao: str) -> None:
    session = MagicMock()
    item = _evento(status="EM_EXECUCAO")
    session.get.return_value = item
    session.scalar.return_value = 1
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        pytest.raises(BikeTourError, match="BT_INSCRICOES_ATIVAS"),
    ):
        acionar_evento(session, ATOR, 30, _acao(acao))
    assert item.status == "EM_EXECUCAO"
    session.flush.assert_not_called()


def test_conclusao_rejeita_ocorrencia_grave_aberta() -> None:
    session = MagicMock()
    session.get.return_value = _evento(status="EM_EXECUCAO")
    session.scalar.side_effect = [None, 123]
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        pytest.raises(BikeTourError, match="BT_OCORRENCIAS_PENDENTES"),
    ):
        acionar_evento(session, ATOR, 30, _acao("CONCLUIR"))
    session.flush.assert_not_called()


def test_cancelamento_em_execucao_libera_apoio_e_registra_ocorrencia() -> None:
    session = MagicMock()
    session.get.return_value = _evento(status="EM_EXECUCAO")
    session.scalar.return_value = None
    alocacao = SimpleNamespace(status="BLOQUEADA", expira_em=NOW)
    session.scalars.return_value.all.side_effect = [[], [alocacao], [alocacao]]
    with patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)):
        result = acionar_evento(session, ATOR, 30, _acao("CANCELAR"))
    assert result["status"] == "CANCELADO"
    assert alocacao.status == "LIBERADA"
    assert alocacao.expira_em is None
    adicionados = [call.args[0] for call in session.add.call_args_list]
    assert any(
        getattr(item_adicionado, "tipo", None) == "INTERRUPCAO" for item_adicionado in adicionados
    )


@pytest.mark.parametrize("distancias", [[], [0], [10, 5], [5, 5]])
def test_abertura_rejeita_rota_incompleta(distancias: list[int]) -> None:
    session = MagicMock()
    session.get.return_value = _evento()
    session.scalars.return_value.all.return_value = [
        SimpleNamespace(distancia_km=value) for value in distancias
    ]
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        patch("app.modules.biketour.services.obter_contexto_saida", return_value=_saida()),
        patch(
            "app.modules.biketour.services.obter_catalogo_saida",
            return_value=SimpleNamespace(
                elegivel=True, produto=SimpleNamespace(id_produto=20, tipo="CICLOTURISMO")
            ),
        ),
        pytest.raises(BikeTourError, match="BT_ROTA_INCOMPLETA"),
    ):
        acionar_evento(session, ATOR, 30, _acao("ABRIR"))


@pytest.mark.parametrize("apoio", [(None, 2), (1, None), (1, 2)])
def test_abertura_exige_lider_e_veiculo_alocados(apoio: tuple[int | None, int | None]) -> None:
    session = MagicMock()
    session.get.return_value = _evento()
    session.scalars.return_value.all.return_value = [
        SimpleNamespace(distancia_km=value) for value in [0, 10]
    ]
    session.scalar.side_effect = apoio
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        patch("app.modules.biketour.services.obter_contexto_saida", return_value=_saida()),
        patch(
            "app.modules.biketour.services.obter_catalogo_saida",
            return_value=SimpleNamespace(
                elegivel=True, produto=SimpleNamespace(id_produto=20, tipo="CICLOTURISMO")
            ),
        ),
    ):
        if None in apoio:
            with pytest.raises(BikeTourError, match="BT_APOIO_INCOMPLETO"):
                acionar_evento(session, ATOR, 30, _acao("ABRIR"))
        else:
            assert acionar_evento(session, ATOR, 30, _acao("ABRIR"))["status"] == "ABERTO"


@pytest.mark.parametrize(
    "saida,catalogo",
    [
        (None, None),
        (_saida(status="CANCELADA"), None),
        (_saida(deleted_at=NOW), None),
        (_saida(), None),
        (_saida(), SimpleNamespace(elegivel=False)),
    ],
)
def test_abertura_revalida_origem(saida: object, catalogo: object) -> None:
    session = MagicMock()
    session.get.return_value = _evento()
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        patch("app.modules.biketour.services.obter_contexto_saida", return_value=saida),
        patch("app.modules.biketour.services.obter_catalogo_saida", return_value=catalogo),
        pytest.raises(BikeTourError, match="BT_SAIDA_ORIGEM_INCOMPATIVEL"),
    ):
        acionar_evento(session, ATOR, 30, _acao("ABRIR"))


@pytest.mark.parametrize("inicio,fim", [(13, 16), (10, 12)])
def test_inicio_fora_do_horario_e_rejeitado(inicio: int, fim: int) -> None:
    session = MagicMock()
    session.get.return_value = _evento(
        status="ABERTO", inicio=NOW.replace(hour=inicio), fim=NOW.replace(hour=fim)
    )
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        patch("app.modules.biketour.services._validar_preparacao"),
        patch("app.modules.biketour.services.obter_contexto_saida", return_value=_saida()),
        patch(
            "app.modules.biketour.services.obter_catalogo_saida",
            return_value=SimpleNamespace(
                elegivel=True, produto=SimpleNamespace(id_produto=20, tipo="CICLOTURISMO")
            ),
        ),
        pytest.raises(BikeTourError, match="BT_HORARIO_INCOMPATIVEL"),
    ):
        acionar_evento(session, ATOR, 30, _acao("INICIAR"))


@pytest.mark.parametrize("valida", [False, True])
def test_inicio_revalida_reserva_e_passageiro(valida: bool) -> None:
    session = MagicMock()
    session.get.return_value = _evento(status="ABERTO")
    session.scalars.return_value.all.return_value = [SimpleNamespace(id_reserva=1, id_passageiro=2)]
    origem = SimpleNamespace(
        reserva=SimpleNamespace(deleted_at=None, status="CONFIRMADA" if valida else "CANCELADA"),
        passageiro=SimpleNamespace(deleted_at=None, status="ATIVO"),
    )
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        patch("app.modules.biketour.services._validar_preparacao"),
        patch("app.modules.biketour.services.obter_contexto_saida", return_value=_saida()),
        patch(
            "app.modules.biketour.services.obter_catalogo_saida",
            return_value=SimpleNamespace(
                elegivel=True, produto=SimpleNamespace(id_produto=20, tipo="CICLOTURISMO")
            ),
        ),
        patch("app.modules.biketour.services.obter_contexto_inscricao", return_value=origem),
    ):
        if valida:
            assert acionar_evento(session, ATOR, 30, _acao("INICIAR"))["status"] == "EM_EXECUCAO"
        else:
            with pytest.raises(BikeTourError, match="BT_INSCRICAO_ORIGEM_INCOMPATIVEL"):
                acionar_evento(session, ATOR, 30, _acao("INICIAR"))


@pytest.mark.parametrize("vinculo", ["inscricao", "alocacao"])
def test_alteracao_rejeita_vinculos_ativos(vinculo: str) -> None:
    session = MagicMock()
    session.get.return_value = _evento()
    session.scalar.return_value = 1 if vinculo == "inscricao" else None
    session.scalars.return_value.all.return_value = [SimpleNamespace()]
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        pytest.raises(BikeTourError, match="BT_EVENTO_COM_VINCULOS_ATIVOS"),
    ):
        alterar_evento(
            session,
            ATOR,
            30,
            EventoUpdate(capacidade=5, versao_esperada=1, chave_idempotencia="vinculo"),
        )


@pytest.mark.parametrize("capacidade", [None, 21])
def test_alteracao_rejeita_limites_da_saida(capacidade: int | None) -> None:
    session = MagicMock()
    session.get.return_value = _evento()
    session.scalar.return_value = None

    if capacidade is None:
        payload = EventoUpdate(
            inicio=NOW.replace(day=19),
            fim=NOW,
            versao_esperada=1,
            chave_idempotencia="limites",
        )
    else:
        payload = EventoUpdate(
            capacidade=capacidade,
            versao_esperada=1,
            chave_idempotencia="limites",
        )

    with (
        patch(
            "app.modules.biketour.services._executar",
            side_effect=_inline_executor(session),
        ),
        patch(
            "app.modules.biketour.services.obter_contexto_saida",
            return_value=_saida(),
        ),
        pytest.raises(
            BikeTourError,
            match="BT_PERIODO_FORA_DA_SAIDA|BT_CAPACIDADE_SAIDA",
        ),
    ):
        alterar_evento(session, ATOR, 30, payload)


def test_criacao_rejeita_saida_inexistente() -> None:
    session = MagicMock()
    with (
        patch("app.modules.biketour.services._executar", side_effect=_inline_executor(session)),
        patch("app.modules.biketour.services.obter_contexto_saida", return_value=None),
        pytest.raises(BikeTourError, match="BT_SAIDA_NAO_ENCONTRADA"),
    ):
        criar_evento(session, ATOR, _evento_payload())


@pytest.mark.parametrize("produto", [False, True])
def test_resposta_persiste_versao_atualizada_pelo_trigger(produto: bool) -> None:
    session = MagicMock()
    session.scalar.return_value = None
    session.in_transaction.return_value = False
    item = _produto() if produto else _evento()
    session.get.return_value = item

    def refresh(target: SimpleNamespace) -> None:
        target.versao = 2
        target.updated_at = NOW

    session.refresh.side_effect = refresh
    with patch("app.modules.biketour.services.obter_contexto_saida", return_value=_saida()):
        if produto:
            result = alterar_produto(
                session,
                ATOR,
                10,
                ProdutoUpdate(ativo=False, versao_esperada=1, chave_idempotencia="versao"),
            )
        else:
            result = alterar_evento(
                session,
                ATOR,
                30,
                EventoUpdate(capacidade=5, versao_esperada=1, chave_idempotencia="versao"),
            )
    assert result["versao"] == 2
    assert result["updated_at"] == NOW.isoformat()
    assert session.add.call_args.args[0].resultado == result
