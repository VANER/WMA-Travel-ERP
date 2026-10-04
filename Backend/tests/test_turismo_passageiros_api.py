from collections.abc import Iterator
from contextlib import contextmanager
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from app.db.session import get_session
from app.main import create_app
from app.modules.seguranca.authorization import obter_contexto_rbac
from app.modules.seguranca.rbac import ContextoRbac
from app.modules.turismo.services import (
    RecursoTurismoNaoEncontradoError,
    RegraTurismoError,
)

PATH = "/api/v1/turismo/reservas/10/passageiros"


def passageiro() -> SimpleNamespace:
    return SimpleNamespace(
        id_passageiro=101,
        id_reserva=10,
        ordem=1,
        status="ATIVO",
        versao=1,
    )


@contextmanager
def cliente_com_permissoes(
    permissoes: set[str],
) -> Iterator[TestClient]:
    app = create_app()
    session = MagicMock()

    app.dependency_overrides[get_session] = lambda: session
    app.dependency_overrides[obter_contexto_rbac] = lambda: ContextoRbac(
        id_usuario=1,
        papeis=(),
        permissoes=frozenset(permissoes),
    )

    try:
        with TestClient(app) as client:
            yield client
    finally:
        app.dependency_overrides.clear()


def test_get_lista_passageiros_com_visualizar() -> None:
    with (
        cliente_com_permissoes(
            {"TURISMO_VISUALIZAR"},
        ) as client,
        patch(
            "app.modules.turismo.router.listar_passageiros_reserva",
            return_value=[passageiro()],
        ) as service,
    ):
        response = client.get(PATH)

    assert response.status_code == 200
    assert response.json() == [
        {
            "id_passageiro": 101,
            "id_reserva": 10,
            "ordem": 1,
            "status": "ATIVO",
            "versao": 1,
        }
    ]
    service.assert_called_once()


def test_post_cadastra_passageiro_com_operar_e_visualizar() -> None:
    with (
        cliente_com_permissoes(
            {
                "TURISMO_VISUALIZAR",
                "TURISMO_OPERAR",
            },
        ) as client,
        patch(
            "app.modules.turismo.router.cadastrar_passageiro_reserva",
            return_value=passageiro(),
        ) as service,
    ):
        response = client.post(
            PATH,
            json={"ordem": 1},
        )

    assert response.status_code == 201
    assert response.json() == {
        "id_passageiro": 101,
        "id_reserva": 10,
        "ordem": 1,
        "status": "ATIVO",
        "versao": 1,
    }
    service.assert_called_once()


def test_get_sem_autenticacao_retorna_401() -> None:
    with TestClient(create_app()) as client:
        response = client.get(PATH)

    assert response.status_code == 401


def test_post_sem_autenticacao_retorna_401() -> None:
    with TestClient(create_app()) as client:
        response = client.post(
            PATH,
            json={"ordem": 1},
        )

    assert response.status_code == 401


def test_get_sem_visualizar_retorna_403() -> None:
    with (
        cliente_com_permissoes(
            {"TURISMO_OPERAR"},
        ) as client,
        patch(
            "app.modules.turismo.router.listar_passageiros_reserva",
        ) as service,
    ):
        response = client.get(PATH)

    assert response.status_code == 403
    service.assert_not_called()


def test_post_apenas_visualizar_retorna_403() -> None:
    with (
        cliente_com_permissoes(
            {"TURISMO_VISUALIZAR"},
        ) as client,
        patch(
            "app.modules.turismo.router.cadastrar_passageiro_reserva",
        ) as service,
    ):
        response = client.post(
            PATH,
            json={"ordem": 1},
        )

    assert response.status_code == 403
    service.assert_not_called()


def test_get_reserva_inexistente_retorna_404() -> None:
    with (
        cliente_com_permissoes(
            {"TURISMO_VISUALIZAR"},
        ) as client,
        patch(
            "app.modules.turismo.router.listar_passageiros_reserva",
            side_effect=RecursoTurismoNaoEncontradoError("reserva nao encontrada"),
        ),
    ):
        response = client.get(PATH)

    assert response.status_code == 404


def test_post_reserva_inexistente_retorna_404() -> None:
    with (
        cliente_com_permissoes(
            {
                "TURISMO_VISUALIZAR",
                "TURISMO_OPERAR",
            },
        ) as client,
        patch(
            "app.modules.turismo.router.cadastrar_passageiro_reserva",
            side_effect=RecursoTurismoNaoEncontradoError("reserva nao encontrada"),
        ),
    ):
        response = client.post(
            PATH,
            json={"ordem": 1},
        )

    assert response.status_code == 404


def test_post_conflito_retorna_409() -> None:
    with (
        cliente_com_permissoes(
            {
                "TURISMO_VISUALIZAR",
                "TURISMO_OPERAR",
            },
        ) as client,
        patch(
            "app.modules.turismo.router.cadastrar_passageiro_reserva",
            side_effect=RegraTurismoError("ordem de passageiro ja cadastrada"),
        ),
    ):
        response = client.post(
            PATH,
            json={"ordem": 1},
        )

    assert response.status_code == 409


def test_post_ordem_invalida_retorna_422_sem_chamar_servico() -> None:
    with (
        cliente_com_permissoes(
            {
                "TURISMO_VISUALIZAR",
                "TURISMO_OPERAR",
            },
        ) as client,
        patch(
            "app.modules.turismo.router.cadastrar_passageiro_reserva",
        ) as service,
    ):
        response = client.post(
            PATH,
            json={"ordem": 0},
        )

    assert response.status_code == 422
    assert response.json()["code"] == "VALIDATION_ERROR"
    service.assert_not_called()


def test_post_campo_extra_retorna_422_sem_chamar_servico() -> None:
    with (
        cliente_com_permissoes(
            {
                "TURISMO_VISUALIZAR",
                "TURISMO_OPERAR",
            },
        ) as client,
        patch(
            "app.modules.turismo.router.cadastrar_passageiro_reserva",
        ) as service,
    ):
        response = client.post(
            PATH,
            json={
                "ordem": 1,
                "nome": "nao deve existir aqui",
            },
        )

    assert response.status_code == 422
    assert response.json()["code"] == "VALIDATION_ERROR"
    service.assert_not_called()


def test_identifier_invalido_retorna_422() -> None:
    with cliente_com_permissoes(
        {"TURISMO_VISUALIZAR"},
    ) as client:
        response = client.get("/api/v1/turismo/reservas/0/passageiros")

    assert response.status_code == 422
    assert response.json()["code"] == "VALIDATION_ERROR"


def test_openapi_publica_contrato_de_passageiros() -> None:
    app = create_app()
    schema = app.openapi()

    path = "/api/v1/turismo/reservas/{identifier}/passageiros"

    operations = schema["paths"][path]

    assert {"get", "post"} <= set(operations)

    assert operations["get"]["operationId"] == "listar_passageiros_reserva_turistica"
    assert operations["post"]["operationId"] == "cadastrar_passageiro_reserva_turistica"

    assert {
        "200",
        "401",
        "403",
        "404",
        "405",
        "409",
        "422",
        "500",
    } <= set(operations["get"]["responses"])

    assert {
        "201",
        "401",
        "403",
        "404",
        "405",
        "409",
        "422",
        "500",
    } <= set(operations["post"]["responses"])
