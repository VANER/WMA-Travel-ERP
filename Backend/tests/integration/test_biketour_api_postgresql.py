"""Smoke tests HTTP Bike Tour contra o PostgreSQL autorizado."""

from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import Settings
from app.db.session import create_db_engine, get_session
from app.main import create_app
from app.modules.seguranca.authorization import (
    exigir_bike_tour_gerenciar,
    exigir_bike_tour_visualizar,
    obter_contexto_rbac,
)
from app.modules.seguranca.rbac import ContextoRbac

pytestmark = pytest.mark.postgresql


@pytest.fixture
def bike_api_client(postgresql_test_url: str) -> Generator[TestClient]:
    engine = create_db_engine(Settings(database_url=postgresql_test_url, environment="test"))
    factory = sessionmaker(bind=engine, expire_on_commit=False)
    app = create_app()

    def session_dependency() -> Generator[Session]:
        with factory() as session:
            yield session

    contexto = ContextoRbac(
        id_usuario=1,
        papeis=("TESTE",),
        permissoes=frozenset({"BIKE_TOUR_VISUALIZAR", "BIKE_TOUR_GERENCIAR"}),
    )
    app.dependency_overrides[get_session] = session_dependency
    app.dependency_overrides[obter_contexto_rbac] = lambda: contexto
    app.dependency_overrides[exigir_bike_tour_visualizar] = lambda: contexto
    app.dependency_overrides[exigir_bike_tour_gerenciar] = lambda: contexto
    try:
        with TestClient(app) as client:
            yield client
    finally:
        app.dependency_overrides.clear()
        engine.dispose()


def test_api_biketour_postgresql_e_banco_autorizado(
    bike_api_client: TestClient, postgresql_test_url: str
) -> None:
    response = bike_api_client.get("/api/v1/biketour/produtos")
    assert response.status_code == 200

    engine = create_db_engine(Settings(database_url=postgresql_test_url, environment="test"))
    try:
        with engine.connect() as connection:
            database = connection.execute(text("select current_database()")).scalar_one()
            configured_url = make_url(postgresql_test_url)
            assert database == configured_url.database
            assert str(database).endswith("_test")
            assert (
                connection.execute(text("select current_user")).scalar_one()
                == configured_url.username
            )
    finally:
        engine.dispose()


def test_api_biketour_postgresql_origem_inexistente_faz_rollback(
    bike_api_client: TestClient,
) -> None:
    response = bike_api_client.post(
        "/api/v1/biketour/produtos",
        json={
            "id_produto": 999999,
            "distancia_km": "10.00",
            "desnivel_m": "100.00",
            "nivel": "INICIANTE",
            "chave_idempotencia": "pg-api-produto-404",
        },
    )
    assert response.status_code == 404


def test_api_biketour_postgresql_saida_inexistente_faz_rollback(
    bike_api_client: TestClient,
) -> None:
    response = bike_api_client.post(
        "/api/v1/biketour/eventos",
        json={
            "id_saida": 999999,
            "inicio": "2026-09-21T12:00:00Z",
            "fim": "2026-09-21T16:00:00Z",
            "capacidade": 10,
            "chave_idempotencia": "pg-api-evento-404",
        },
    )
    assert response.status_code == 404
