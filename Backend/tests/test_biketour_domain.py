"""Invariantes operacionais congeladas, incluindo fronteiras de tempo e estados terminais."""

from datetime import UTC, datetime, timedelta, timezone
from itertools import product

import pytest

from app.modules.biketour.domain import (
    OcupacaoInscricao,
    calcular_expiracao,
    consome_capacidade,
    intervalos_sobrepostos,
    validar_capacidade,
    validar_rebloqueio,
    validar_transicao_evento,
    validar_transicao_inscricao,
    validar_transicao_ocorrencia,
    validar_versao,
)
from app.modules.biketour.errors import BikeTourError

NOW = datetime(2026, 9, 15, 12, tzinfo=UTC)
STATES = ("PENDENTE", "CONFIRMADA", "PRESENTE", "CONCLUIDA", "CANCELADA", "EXPIRADA", "NO_SHOW")


@pytest.mark.parametrize(("source", "target"), list(product(STATES, repeat=2)))
def test_matriz_inscricao_sem_reabertura_implicita(source: str, target: str) -> None:
    allowed = {
        ("PENDENTE", "CONFIRMADA"),
        ("PENDENTE", "EXPIRADA"),
        ("PENDENTE", "CANCELADA"),
        ("CONFIRMADA", "PRESENTE"),
        ("CONFIRMADA", "NO_SHOW"),
        ("CONFIRMADA", "CANCELADA"),
        ("PRESENTE", "CONCLUIDA"),
        ("PRESENTE", "CANCELADA"),
    }
    if (source, target) in allowed:
        validar_transicao_inscricao(source, target)
    else:
        with pytest.raises(BikeTourError, match="TRANSICAO_INSCRICAO"):
            validar_transicao_inscricao(source, target)


@pytest.mark.parametrize(
    ("source", "target"),
    [
        ("PLANEJADO", "ABERTO"),
        ("PLANEJADO", "CANCELADO"),
        ("ABERTO", "EM_EXECUCAO"),
        ("ABERTO", "CANCELADO"),
        ("EM_EXECUCAO", "CONCLUIDO"),
        ("EM_EXECUCAO", "CANCELADO"),
    ],
)
def test_evento_transicoes_validas(source: str, target: str) -> None:
    validar_transicao_evento(source, target)


@pytest.mark.parametrize("source", ["CONCLUIDO", "CANCELADO", "DESCONHECIDO"])
def test_evento_terminal_nao_reabre(source: str) -> None:
    with pytest.raises(BikeTourError, match="TRANSICAO_EVENTO"):
        validar_transicao_evento(source, "ABERTO")


def test_ocorrencia_exige_analise_e_preserva_terminal() -> None:
    validar_transicao_ocorrencia("ABERTA", "EM_ANALISE")
    validar_transicao_ocorrencia("EM_ANALISE", "RESOLVIDA")
    validar_transicao_ocorrencia("EM_ANALISE", "DESCARTADA")
    for source, target in [
        ("ABERTA", "RESOLVIDA"),
        ("RESOLVIDA", "ABERTA"),
        ("DESCARTADA", "ABERTA"),
    ]:
        with pytest.raises(BikeTourError, match="TRANSICAO_OCORRENCIA"):
            validar_transicao_ocorrencia(source, target)


@pytest.mark.parametrize("state", STATES)
def test_rebloqueio_explicito_somente_cancelada_ou_expirada(state: str) -> None:
    if state in {"CANCELADA", "EXPIRADA"}:
        validar_rebloqueio(state, "ABERTO")
    else:
        with pytest.raises(BikeTourError, match="REBLOQUEIO"):
            validar_rebloqueio(state, "ABERTO")
    with pytest.raises(BikeTourError, match="REBLOQUEIO"):
        validar_rebloqueio(state, "CONCLUIDO")


def test_versao_obrigatoria_e_otimista() -> None:
    validar_versao(2, 2)
    for expected, status in [(0, 422), (1, 409)]:
        with pytest.raises(BikeTourError) as error:
            validar_versao(2, expected)
        assert error.value.status_code == status


def test_bloqueio_limita_quinze_minutos_inicio_e_origem() -> None:
    assert calcular_expiracao(NOW, NOW + timedelta(hours=1), None) == NOW + timedelta(minutes=15)
    assert calcular_expiracao(NOW, NOW + timedelta(minutes=5), None) == NOW + timedelta(minutes=5)
    assert calcular_expiracao(
        NOW, NOW + timedelta(minutes=5), NOW + timedelta(minutes=2)
    ) == NOW + timedelta(minutes=2)
    for expired in [NOW, NOW - timedelta(seconds=1)]:
        with pytest.raises(BikeTourError, match="SEM_VALIDADE"):
            calcular_expiracao(NOW, expired, None)


def test_fuso_obrigatorio_e_normalizacao_utc() -> None:
    local = NOW.astimezone(timezone(timedelta(hours=-3)))
    assert calcular_expiracao(local, NOW + timedelta(hours=1), None).tzinfo is UTC
    with pytest.raises(BikeTourError, match="FUSO_OBRIGATORIO"):
        calcular_expiracao(NOW.replace(tzinfo=None), NOW, None)


@pytest.mark.parametrize("state", STATES)
def test_capacidade_distingue_comprometidas_de_terminais(state: str) -> None:
    assert consome_capacidade(OcupacaoInscricao(1, state, NOW + timedelta(seconds=1)), NOW) == (
        state in {"PENDENTE", "CONFIRMADA", "PRESENTE"}
    )
    assert consome_capacidade(OcupacaoInscricao(1, state, NOW), NOW) == (
        state in {"CONFIRMADA", "PRESENTE"}
    )
    assert consome_capacidade(OcupacaoInscricao(1, state, None), NOW) == (
        state in {"CONFIRMADA", "PRESENTE"}
    )


def test_capacidade_evento_saida_e_reserva() -> None:
    items = [OcupacaoInscricao(1, "CONFIRMADA", None), OcupacaoInscricao(1, "CONCLUIDA", None)]
    validar_capacidade(
        items,
        agora=NOW,
        capacidade_evento=2,
        capacidade_saida=3,
        id_reserva=1,
        quantidade_reserva=2,
    )
    for capacity, source_capacity, quantity, code in [
        (0, 3, 2, "CAPACIDADE_INVALIDA"),
        (1001, 2000, 2, "CAPACIDADE_INVALIDA"),
        (4, 3, 2, "CAPACIDADE_SAIDA"),
        (1, 3, 2, "EVENTO_LOTADO"),
        (2, 3, 1, "RESERVA_LOTADA"),
    ]:
        with pytest.raises(BikeTourError, match=code):
            validar_capacidade(
                items,
                agora=NOW,
                capacidade_evento=capacity,
                capacidade_saida=source_capacity,
                id_reserva=1,
                quantidade_reserva=quantity,
            )


def test_intervalos_adjacentes_permitidos_sobreposicao_rejeitada() -> None:
    end = NOW + timedelta(hours=1)
    assert not intervalos_sobrepostos(NOW, end, end, end + timedelta(hours=1))
    assert intervalos_sobrepostos(NOW, end, NOW + timedelta(minutes=59), end + timedelta(hours=1))
    with pytest.raises(BikeTourError, match="INTERVALO_INVALIDO"):
        intervalos_sobrepostos(NOW, NOW, NOW, end)
