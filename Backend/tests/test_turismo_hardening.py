"""Contratos HTTP, RBAC e caminhos de falha do hardening de Turismo."""

from collections.abc import Callable
from datetime import UTC, date, datetime, timedelta
from typing import Any
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient
from pydantic import ValidationError
from sqlalchemy.orm import Session

from app.db.session import get_session
from app.main import create_app
from app.modules.comercial.models import Contrato, ItemVenda
from app.modules.seguranca.authorization import obter_contexto_rbac
from app.modules.seguranca.rbac import ContextoRbac
from app.modules.turismo import services
from app.modules.turismo.models import AlocacaoVaga, Reserva, ReservaOperacao, SaidaTuristica
from app.modules.turismo.repositories import ReservaRepository, SaidaRepository
from app.modules.turismo.schemas import ReservaAcao, ReservaCreate, ReservaResponse

ROUTES = [
    ("GET", "/saidas", None, "SaidaRepository.listar", "VISUALIZAR"),
    ("GET", "/saidas/1/disponibilidade", None, "obter_disponibilidade", "VISUALIZAR"),
    (
        "POST",
        "/saidas",
        {
            "id_pacote": 1,
            "codigo": "S",
            "data_inicio": "2026-10-01",
            "data_fim": "2026-10-02",
            "capacidade": 1,
        },
        "criar_saida",
        "GERENCIAR",
    ),
    (
        "POST",
        "/reservas",
        {
            "codigo_reserva": "R",
            "id_cliente": 1,
            "id_saida": 1,
            "quantidade_passageiros": 1,
            "chave_idempotencia": "r",
        },
        "criar_reserva",
        "OPERAR",
    ),
    ("POST", "/reservas/1/confirmacao", {"chave_idempotencia": "a"}, "confirmar_reserva", "OPERAR"),
    ("POST", "/reservas/1/cancelamento", {"chave_idempotencia": "a"}, "cancelar_reserva", "OPERAR"),
]


def reserva(status: str = "PENDENTE") -> Reserva:
    return Reserva(
        id_reserva=1,
        codigo_reserva="R",
        id_cliente=1,
        id_pacote=1,
        id_saida=1,
        data_reserva=date(2026, 9, 8),
        quantidade_passageiros=1,
        valor_total=None,
        status=status,
        versao=1,
    )


@pytest.mark.parametrize("route", ROUTES)
@pytest.mark.parametrize(
    "permissions",
    [(), ("VISUALIZAR",), ("VISUALIZAR", "OPERAR"), ("VISUALIZAR", "OPERAR", "GERENCIAR")],
)
def test_rbac_por_endpoint(
    route: tuple[str, str, dict[str, Any] | None, str, str], permissions: tuple[str, ...]
) -> None:
    method, path, body, target, required = route
    app = create_app()
    session = MagicMock()
    app.dependency_overrides[get_session] = lambda: session
    app.dependency_overrides[obter_contexto_rbac] = lambda: ContextoRbac(
        id_usuario=1,
        papeis=("ADMIN",) if len(permissions) == 3 else (),
        permissoes=frozenset("TURISMO_" + p for p in permissions),
    )
    result: object = reserva()
    if target == "SaidaRepository.listar":
        result = []
    elif target == "obter_disponibilidade":
        result = {
            "id_saida": 1,
            "capacidade": 1,
            "vagas_bloqueadas": 0,
            "vagas_confirmadas": 0,
            "disponibilidade": 1,
        }
    elif target == "criar_saida":
        result = SaidaTuristica(
            id_saida=1,
            id_pacote=1,
            codigo="S",
            data_inicio=date(2026, 10, 1),
            data_fim=date(2026, 10, 2),
            capacidade=1,
            status="ABERTA",
            versao=1,
        )
    with (
        patch("app.modules.turismo.router." + target, return_value=result) as service,
        TestClient(app) as client,
    ):
        response = client.request(method, "/api/v1/turismo" + path, json=body)
    if "VISUALIZAR" in permissions and required in permissions:
        assert response.status_code == (
            201 if path in {"/reservas", "/saidas"} and method == "POST" else 200
        )
        service.assert_called_once()
    else:
        assert response.status_code == 403
        service.assert_not_called()


@pytest.mark.parametrize("route", ROUTES)
def test_autenticacao_obrigatoria(route: tuple[str, str, dict[str, Any] | None, str, str]) -> None:
    method, path, body, _, _ = route
    with TestClient(create_app()) as client:
        assert client.request(method, "/api/v1/turismo" + path, json=body).status_code == 401


@pytest.mark.parametrize("route", ROUTES[1:])
@pytest.mark.parametrize(
    "error,code",
    [(services.RecursoTurismoNaoEncontradoError, 404), (services.RegraTurismoError, 409)],
)
def test_erros_http_tipados(
    route: tuple[str, str, dict[str, Any] | None, str, str], error: type[ValueError], code: int
) -> None:
    method, path, body, target, _ = route
    app = create_app()
    app.dependency_overrides[get_session] = lambda: MagicMock()
    app.dependency_overrides[obter_contexto_rbac] = lambda: ContextoRbac(
        id_usuario=1,
        papeis=("ADMIN",),
        permissoes=frozenset({"TURISMO_VISUALIZAR", "TURISMO_OPERAR", "TURISMO_GERENCIAR"}),
    )
    with (
        patch("app.modules.turismo.router." + target, side_effect=error("recurso")),
        TestClient(app) as client,
    ):
        assert client.request(method, "/api/v1/turismo" + path, json=body).status_code == code


def test_payload_invalido_e_openapi() -> None:
    app = create_app()
    app.dependency_overrides[get_session] = lambda: MagicMock()
    app.dependency_overrides[obter_contexto_rbac] = lambda: ContextoRbac(
        id_usuario=1,
        papeis=("ADMIN",),
        permissoes=frozenset({"TURISMO_VISUALIZAR", "TURISMO_OPERAR", "TURISMO_GERENCIAR"}),
    )
    with TestClient(app) as client:
        assert client.post("/api/v1/turismo/reservas", json={}).status_code == 422
    for path, methods in app.openapi()["paths"].items():
        if not path.startswith("/api/v1/turismo"):
            continue
        for operation in methods.values():
            expected = {"401", "403", "422"}
            if path != "/api/v1/turismo/saidas" or "requestBody" in operation:
                expected.add("404")
            if "/reservas" in path:
                expected.add("409")
            assert expected <= operation["responses"].keys()


@pytest.mark.parametrize(
    "operation",
    [services.confirmar_reserva, services.cancelar_reserva],
)
def test_acoes_com_reserva_inexistente_revertem(
    operation: Callable[[Session, int, ReservaAcao], ReservaResponse],
) -> None:
    session = MagicMock()

    with (
        patch.object(ReservaRepository, "obter", return_value=None),
        pytest.raises(
            services.RecursoTurismoNaoEncontradoError,
            match="reserva não encontrada",
        ),
    ):
        operation(session, 999, ReservaAcao(chave_idempotencia="inexistente"))

    session.rollback.assert_called_once()
    session.commit.assert_not_called()


@pytest.mark.parametrize("operation", [services.confirmar_reserva, services.cancelar_reserva])
def test_acoes_ausentes_revertem(
    operation: Callable[[Session, int, ReservaAcao], ReservaResponse],
) -> None:
    session = MagicMock()
    with (
        patch.object(ReservaRepository, "obter", side_effect=[reserva(), None]),
        pytest.raises(services.RecursoTurismoNaoEncontradoError),
    ):
        operation(session, 1, ReservaAcao(chave_idempotencia="a"))
    session.rollback.assert_called_once()


@pytest.mark.parametrize(
    "action,initial,allocation,expected",
    [
        ("confirmar_reserva", "PENDENTE", None, "alocação"),
        ("confirmar_reserva", "PENDENTE", AlocacaoVaga(status="LIBERADA"), "alocação"),
        (
            "confirmar_reserva",
            "PENDENTE",
            AlocacaoVaga(status="BLOQUEADA", expira_em=None),
            "expirado",
        ),
        ("confirmar_reserva", "CANCELADA", None, "confirmada"),
        ("cancelar_reserva", "CONCLUIDA", None, "cancelada"),
        ("cancelar_reserva", "NO_SHOW", None, "cancelada"),
    ],
)
def test_estados_invalidos(
    action: str, initial: str, allocation: AlocacaoVaga | None, expected: str
) -> None:
    session = MagicMock()
    session.scalar.side_effect = [None, allocation]
    with (
        patch.object(ReservaRepository, "obter", return_value=reserva(initial)),
        patch.object(SaidaRepository, "obter", return_value=SaidaTuristica()),
        pytest.raises(services.RegraTurismoError, match=expected),
    ):
        getattr(services, action)(session, 1, ReservaAcao(chave_idempotencia="a"))
    session.rollback.assert_called_once()


@pytest.mark.parametrize(
    "action,initial,allocation,status",
    [
        ("confirmar_reserva", "PENDENTE", AlocacaoVaga(status="RESERVADA"), "CONFIRMADA"),
        (
            "confirmar_reserva",
            "PENDENTE",
            AlocacaoVaga(status="BLOQUEADA", expira_em=datetime(2099, 1, 1)),
            "CONFIRMADA",
        ),
        ("confirmar_reserva", "CONFIRMADA", None, "CONFIRMADA"),
        ("cancelar_reserva", "PENDENTE", AlocacaoVaga(status="BLOQUEADA"), "CANCELADA"),
        ("cancelar_reserva", "PENDENTE", AlocacaoVaga(status="EXPIRADA"), "CANCELADA"),
        ("cancelar_reserva", "PENDENTE", None, "CANCELADA"),
        ("cancelar_reserva", "CANCELADA", None, "CANCELADA"),
    ],
)
def test_acoes_persistem_resposta(
    action: str, initial: str, allocation: AlocacaoVaga | None, status: str
) -> None:
    session = MagicMock()
    session.scalar.side_effect = [None, allocation]
    value = reserva(initial)
    value.id_saida = None
    with patch.object(ReservaRepository, "obter", return_value=value):
        result = getattr(services, action)(session, 1, ReservaAcao(chave_idempotencia="a"))
    assert result.status == status
    stored = session.add.call_args.args[0]
    assert isinstance(stored, ReservaOperacao)
    assert stored.resultado == result.model_dump(mode="json")
    session.commit.assert_called_once()


@pytest.mark.parametrize("action", [services.confirmar_reserva, services.cancelar_reserva])
def test_replay_nao_grava(action: Callable[[Session, int, ReservaAcao], ReservaResponse]) -> None:
    session = MagicMock()
    original = ReservaResponse.model_validate(reserva("CONFIRMADA"))
    session.scalar.return_value = ReservaOperacao(resultado=original.model_dump(mode="json"))
    with patch.object(ReservaRepository, "obter", return_value=reserva("CANCELADA")):
        assert action(session, 1, ReservaAcao(chave_idempotencia="a")) == original
    session.add.assert_not_called()
    session.commit.assert_not_called()


@pytest.mark.parametrize(
    "changes,returned,error",
    [
        ({"id_venda": 1}, None, "venda"),
        ({"id_venda": 1, "id_item_venda": 1}, ItemVenda(id_venda=2), "incompatível"),
        ({"id_item_venda": 1, "id_venda": 1}, None, "venda"),
        ({"id_contrato": 1}, None, "contrato"),
        ({"id_contrato": 1, "id_venda": 1}, Contrato(id_venda=2), "incompatível"),
    ],
)
def test_validacao_comercial(changes: dict[str, int], returned: object, error: str) -> None:
    session = MagicMock()
    session.get.return_value = returned
    data = ReservaCreate(
        codigo_reserva="R",
        id_cliente=1,
        id_saida=1,
        quantidade_passageiros=1,
        chave_idempotencia="r",
        **changes,
    )
    with pytest.raises(services.RegraTurismoError, match=error):
        services._validar_correlacao(session, data)


def test_correlacao_item_ausente_e_valida() -> None:
    data = ReservaCreate(
        codigo_reserva="R",
        id_cliente=1,
        id_saida=1,
        quantidade_passageiros=1,
        chave_idempotencia="r",
        id_venda=1,
        id_item_venda=1,
        id_contrato=1,
    )
    session = MagicMock()
    session.get.side_effect = [object(), None]
    with pytest.raises(services.RecursoTurismoNaoEncontradoError, match="item"):
        services._validar_correlacao(session, data)
    session.get.side_effect = [object(), ItemVenda(id_venda=1), Contrato(id_venda=1)]
    services._validar_correlacao(session, data)


def test_expiracao_e_fuso() -> None:
    data = dict(
        codigo_reserva="R",
        id_cliente=1,
        id_saida=1,
        quantidade_passageiros=1,
        chave_idempotencia="r",
    )
    aware = datetime.now(UTC) + timedelta(hours=1)
    result = ReservaCreate.model_validate({**data, "expira_em": aware})
    assert result.expira_em == aware.replace(tzinfo=None)
    with pytest.raises(ValidationError, match="requer"):
        ReservaCreate.model_validate({**data, "id_item_venda": 1})
    session = MagicMock()
    with (
        patch.object(SaidaRepository, "obter", return_value=None),
        pytest.raises(services.RecursoTurismoNaoEncontradoError),
    ):
        services.expirar_bloqueios(session, 1)
    with patch.object(SaidaRepository, "obter", return_value=object()):
        session.scalars.return_value.all.return_value = [1, 2]
        assert services.expirar_bloqueios(session, 1) == 2


def test_criacao_reconsulta_chave_apos_lock() -> None:
    session = MagicMock()
    value = reserva()
    data = ReservaCreate(
        codigo_reserva="R",
        id_cliente=1,
        id_saida=1,
        quantidade_passageiros=1,
        chave_idempotencia="r",
    )
    with (
        patch.object(ReservaRepository, "por_chave", side_effect=[None, value]),
        patch.object(SaidaRepository, "obter", return_value=SaidaTuristica(status="ABERTA")),
    ):
        assert services.criar_reserva(session, data) is value
    session.add.assert_not_called()
