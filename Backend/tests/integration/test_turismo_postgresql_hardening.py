"""Hardening transacional contra PostgreSQL real, em banco local descartável."""

from collections.abc import Generator
from concurrent.futures import ThreadPoolExecutor
from datetime import UTC, date, datetime, timedelta
from pathlib import Path
from threading import Barrier, Event
from time import monotonic, sleep
from unittest.mock import patch

import pytest
from sqlalchemy import func, select, text
from sqlalchemy.engine import Engine
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.config import Settings
from app.db import models as _models  # noqa: F401
from app.db.base import Base
from app.db.session import create_db_engine
from app.modules.comercial.models import ItemVenda, Venda
from app.modules.corporativo.models import Cliente, Localidade, Pessoa
from app.modules.seguranca.models import Usuario
from app.modules.turismo.models import (
    AlocacaoVaga,
    PacoteViagem,
    ProdutoTuristico,
    Reserva,
    ReservaCorrelacao,
    ReservaOperacao,
    SaidaTuristica,
)
from app.modules.turismo.schemas import ReservaAcao, ReservaCreate, ReservaResponse
from app.modules.turismo.services import (
    RecursoTurismoNaoEncontradoError,
    RegraTurismoError,
    cancelar_reserva,
    confirmar_reserva,
    criar_reserva,
    expirar_bloqueios,
    obter_disponibilidade,
)

pytestmark = pytest.mark.postgresql


@pytest.fixture
def turismo_engine(postgresql_test_url: str) -> Generator[Engine]:
    engine = create_db_engine(Settings(database_url=postgresql_test_url, environment="test"))
    with engine.begin() as connection:
        connection.execute(text("CREATE SCHEMA IF NOT EXISTS financeiro"))
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    source = (
        Path(__file__).parents[3] / "Database/migrations/202609080100_turismo_hardening.sql"
    ).read_text(encoding="utf-8")
    with engine.begin() as connection:
        connection.execute(
            text("DROP FUNCTION IF EXISTS public.fn_validar_reserva_alocacao() CASCADE")
        )
        connection.execute(text(source[source.index("CREATE FUNCTION") :]))
    try:
        with Session(engine) as session:
            session.add(Localidade(cidade="Curitiba", uf="PR", pais="Brasil"))
            session.flush()
            session.add(
                Pessoa(
                    id_pessoa=1, tipo_pessoa="FISICA", nome_razao_social="Teste", id_localidade=1
                )
            )
            session.flush()
            session.add(Cliente(id_cliente=1, id_pessoa=1, codigo_cliente="TUR-TEST"))
            session.add(
                ProdutoTuristico(id_produto=1, codigo="P", nome="Produto", tipo_produto="PACOTE")
            )
            session.flush()
            session.add(PacoteViagem(id_pacote=1, id_produto=1, codigo_pacote="P"))
            session.flush()
            session.add(
                SaidaTuristica(
                    id_saida=1,
                    id_pacote=1,
                    codigo="S",
                    data_inicio=date(2026, 10, 1),
                    data_fim=date(2026, 10, 2),
                    capacidade=1,
                    status="ABERTA",
                )
            )
            session.add_all(
                [
                    Venda(
                        id_venda=i, numero_venda=f"V{i}", id_cliente=1, data_venda=date(2026, 9, 8)
                    )
                    for i in (1, 2)
                ]
            )
            session.flush()
            session.add(ItemVenda(id_item=1, id_venda=1, id_produto=1))
            session.commit()
        yield engine
    finally:
        Base.metadata.drop_all(engine)
        with engine.begin() as connection:
            connection.execute(text("DROP FUNCTION public.fn_validar_reserva_alocacao()"))
        engine.dispose()


def payload(chave: str = "reserva") -> ReservaCreate:
    return ReservaCreate(
        codigo_reserva=chave,
        id_cliente=1,
        id_saida=1,
        quantidade_passageiros=1,
        chave_idempotencia=chave,
    )


def test_duas_transacoes_disputam_ultima_vaga(turismo_engine: Engine) -> None:
    acquired, release, started = Event(), Event(), Event()
    pids: list[int] = []

    def primeira() -> int:
        with Session(turismo_engine) as session:
            session.scalar(
                select(SaidaTuristica).where(SaidaTuristica.id_saida == 1).with_for_update()
            )
            acquired.set()
            assert release.wait(10)
            return criar_reserva(session, payload("primeira")).id_reserva

    def segunda() -> str:
        with Session(turismo_engine) as session:
            pids.append(session.execute(text("SELECT pg_backend_pid()")).scalar_one())
            session.execute(text("SET LOCAL lock_timeout = '8s'"))
            started.set()
            with pytest.raises(RegraTurismoError, match="capacidade"):
                criar_reserva(session, payload("segunda"))
            assert not session.in_transaction()
            return "conflito"

    with ThreadPoolExecutor(max_workers=2) as executor:
        first = executor.submit(primeira)
        assert acquired.wait(5)
        second = executor.submit(segunda)
        try:
            assert started.wait(5)
            deadline = monotonic() + 5
            with turismo_engine.connect() as connection:
                while monotonic() < deadline:
                    blocked = connection.execute(
                        text("SELECT cardinality(pg_blocking_pids(:pid)) > 0"), {"pid": pids[0]}
                    ).scalar_one()
                    if blocked:
                        break
                    sleep(0.01)
                else:
                    pytest.fail("a segunda conexão não aguardou o lock da primeira")
            assert not second.done()
        finally:
            release.set()
        assert first.result(timeout=10) > 0
        assert second.result(timeout=10) == "conflito"
    with Session(turismo_engine) as session:
        assert session.scalar(select(func.count()).select_from(Reserva)) == 1
        assert session.scalar(select(func.count()).select_from(AlocacaoVaga)) == 1
        assert session.scalar(select(func.count()).select_from(ReservaCorrelacao)) == 0
        assert obter_disponibilidade(session, 1).disponibilidade == 0


@pytest.mark.parametrize("falha_em", ["alocacao", "correlacao", "flush"])
def test_rollback_integral_e_sessao_reutilizavel(turismo_engine: Engine, falha_em: str) -> None:
    with Session(turismo_engine) as session:
        original = session.add

        def adicionar(instance: object, *, _warn: bool = True) -> None:
            if (falha_em == "alocacao" and isinstance(instance, AlocacaoVaga)) or (
                falha_em == "correlacao" and isinstance(instance, ReservaCorrelacao)
            ):
                raise RuntimeError("falha injetada")
            original(instance, _warn=_warn)

        if falha_em == "flush":
            original_flush = session.flush

            def flush(objects: object = None) -> None:
                original_flush()
                if any(isinstance(obj, Reserva) for obj in session.identity_map.values()):
                    raise RuntimeError("falha injetada")

            with (
                patch.object(session, "flush", side_effect=flush),
                pytest.raises(RuntimeError, match="injetada"),
            ):
                criar_reserva(session, payload().model_copy(update={"id_venda": 1}))
        else:
            with (
                patch.object(session, "add", side_effect=adicionar),
                pytest.raises(RuntimeError, match="injetada"),
            ):
                criar_reserva(session, payload().model_copy(update={"id_venda": 1}))
        assert not session.in_transaction()
        for model in (Reserva, AlocacaoVaga, ReservaCorrelacao):
            assert session.scalar(select(func.count()).select_from(model)) == 0
        assert criar_reserva(session, payload("retentativa")).id_reserva > 0


def test_repeticao_acoes_preserva_resposta_original(turismo_engine: Engine) -> None:
    with Session(turismo_engine) as session:
        identifier = criar_reserva(session, payload()).id_reserva
        action = ReservaAcao(chave_idempotencia="acao")
        confirmed = confirmar_reserva(session, identifier, action)
        assert confirmar_reserva(session, identifier, action) == confirmed
        cancelled = cancelar_reserva(session, identifier, action)
        assert cancelar_reserva(session, identifier, action) == cancelled
        assert confirmar_reserva(session, identifier, action) == confirmed
        session.expire_all()
        stored = session.get(Reserva, identifier)
        assert stored is not None and stored.status == "CANCELADA"
        assert session.scalar(select(func.count()).select_from(ReservaOperacao)) == 2
        assert obter_disponibilidade(session, 1).disponibilidade == 1
        with pytest.raises(RegraTurismoError, match="confirmada"):
            confirmar_reserva(session, identifier, ReservaAcao(chave_idempotencia="nova"))


@pytest.mark.parametrize(
    "changes, error",
    [
        ({"id_venda": 999}, RecursoTurismoNaoEncontradoError),
        ({"id_venda": 2, "id_item_venda": 1}, RegraTurismoError),
        ({"id_contrato": 999}, RecursoTurismoNaoEncontradoError),
        ({"id_venda": 1, "id_item_venda": 999}, RecursoTurismoNaoEncontradoError),
    ],
)
def test_correlacao_invalida_reverte(
    turismo_engine: Engine, changes: dict[str, int], error: type[RegraTurismoError]
) -> None:
    with Session(turismo_engine) as session:
        with pytest.raises(error):
            criar_reserva(session, payload().model_copy(update=changes))
        assert session.scalar(select(func.count()).select_from(Reserva)) == 0
        assert session.scalar(select(func.count()).select_from(AlocacaoVaga)) == 0


def test_sem_correlacao_e_unicidade(turismo_engine: Engine) -> None:
    with Session(turismo_engine) as session:
        identifier = criar_reserva(session, payload()).id_reserva
        assert session.scalar(select(func.count()).select_from(ReservaCorrelacao)) == 0
        session.add(ReservaCorrelacao(id_reserva=identifier, id_venda=1, chave_idempotencia="c1"))
        session.commit()
        session.add(ReservaCorrelacao(id_reserva=identifier, id_venda=2, chave_idempotencia="c2"))
        with pytest.raises(IntegrityError):
            session.commit()
        session.rollback()
        assert session.scalar(select(func.count()).select_from(ReservaCorrelacao)) == 1


def test_expiracao_logica_e_materializacao_repetivel(turismo_engine: Engine) -> None:
    with Session(turismo_engine) as session:
        identifier = criar_reserva(
            session,
            payload().model_copy(
                update={"expira_em": datetime.now(UTC).replace(tzinfo=None) + timedelta(hours=1)}
            ),
        ).id_reserva
        allocation = session.scalar(select(AlocacaoVaga))
        assert allocation is not None
        allocation.expira_em = datetime(2000, 1, 1)
        session.commit()
        assert obter_disponibilidade(session, 1).disponibilidade == 1
        with pytest.raises(RegraTurismoError, match="expirado"):
            confirmar_reserva(session, identifier, ReservaAcao(chave_idempotencia="expirada"))
        assert expirar_bloqueios(session, 1) == 1
        assert expirar_bloqueios(session, 1) == 0
        session.refresh(allocation)
        assert allocation.status == "EXPIRADA"
        assert allocation.expira_em == datetime(2000, 1, 1)
        assert obter_disponibilidade(session, 1).disponibilidade == 1


@pytest.mark.parametrize(
    "column,value", [("quantidade_passageiros", 0), ("valor_total", -1), ("status", "CONFIRMADA")]
)
def test_constraints_rejeitam_estado_invalido(
    turismo_engine: Engine, column: str, value: int | str
) -> None:
    with Session(turismo_engine) as session:
        identifier = criar_reserva(
            session,
            payload().model_copy(
                update={"expira_em": datetime.now(UTC).replace(tzinfo=None) + timedelta(hours=1)}
            ),
        ).id_reserva
        with pytest.raises(IntegrityError):
            session.execute(
                text(f"UPDATE reserva SET {column} = :value WHERE id_reserva = :id"),
                {"value": value, "id": identifier},
            )
            session.commit()
        session.rollback()
        assert obter_disponibilidade(session, 1).disponibilidade == 0


@pytest.mark.parametrize("operacao", ["confirmar", "cancelar"])
def test_acoes_concorrentes_mesma_chave(turismo_engine: Engine, operacao: str) -> None:
    with Session(turismo_engine) as session:
        identifier = criar_reserva(session, payload()).id_reserva
    barrier = Barrier(2)
    action = confirmar_reserva if operacao == "confirmar" else cancelar_reserva

    def executar() -> ReservaResponse:
        with Session(turismo_engine) as session:
            session.execute(text("SET LOCAL lock_timeout = '10s'"))
            barrier.wait(timeout=10)
            return action(session, identifier, ReservaAcao(chave_idempotencia="simultanea"))

    with ThreadPoolExecutor(max_workers=2) as executor:
        first = executor.submit(executar)
        second = executor.submit(executar)
        assert first.result(timeout=20) == second.result(timeout=20)
    with Session(turismo_engine) as session:
        assert session.scalar(select(func.count()).select_from(ReservaOperacao)) == 1
        assert session.scalar(select(func.count()).select_from(AlocacaoVaga)) == 1
        assert obter_disponibilidade(session, 1).disponibilidade == (operacao == "cancelar")


def test_idempotencia_isola_ator(turismo_engine: Engine) -> None:
    with Session(turismo_engine) as session:
        session.add_all(
            [Usuario(id_usuario=i, nome=f"Ator {i}", email=f"ator{i}@example.com") for i in (1, 2)]
        )
        session.commit()
        identifier = criar_reserva(session, payload()).id_reserva
        action = ReservaAcao(chave_idempotencia="compartilhada")
        confirmed = confirmar_reserva(session, identifier, action, id_usuario=1)
        assert confirmar_reserva(session, identifier, action, id_usuario=2) == confirmed
        assert session.scalar(select(func.count()).select_from(ReservaOperacao)) == 2
        cancelar_reserva(session, identifier, action, id_usuario=1)
        assert confirmar_reserva(session, identifier, action, id_usuario=2) == confirmed


@pytest.mark.parametrize("operacao", ["confirmar", "cancelar"])
def test_falha_ao_registrar_resultado_reverte_acao(turismo_engine: Engine, operacao: str) -> None:
    with Session(turismo_engine) as session:
        identifier = criar_reserva(session, payload()).id_reserva
        action = confirmar_reserva if operacao == "confirmar" else cancelar_reserva
        with (
            patch.object(session, "add", side_effect=RuntimeError("snapshot")),
            pytest.raises(RuntimeError, match="snapshot"),
        ):
            action(session, identifier, ReservaAcao(chave_idempotencia="falha"))
        session.expire_all()
        stored = session.get(Reserva, identifier)
        assert stored is not None and stored.status == "PENDENTE"
        allocation = session.scalar(select(AlocacaoVaga))
        assert allocation is not None and allocation.status == "RESERVADA"
        assert session.scalar(select(func.count()).select_from(ReservaOperacao)) == 0
        assert obter_disponibilidade(session, 1).disponibilidade == 0
