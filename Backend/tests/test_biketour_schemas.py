"""Branches de validação dos contratos HTTP Bike Tour."""

from datetime import UTC, datetime

import pytest
from pydantic import ValidationError

from app.modules.biketour.schemas import (
    EventoAcaoRequest,
    EventoCreate,
    EventoUpdate,
    ProdutoUpdate,
)

NOW = datetime(2026, 9, 21, 12, tzinfo=UTC)


def test_evento_create_rejeita_fuso_ausente() -> None:
    with pytest.raises(ValidationError):
        EventoCreate(
            id_saida=1,
            inicio=datetime(2026, 9, 21, 12),
            fim=datetime(2026, 9, 21, 16),
            capacidade=10,
            chave_idempotencia="schema-1",
        )


def test_evento_create_rejeita_intervalo_invertido() -> None:
    with pytest.raises(ValidationError):
        EventoCreate(
            id_saida=1,
            inicio=NOW,
            fim=NOW.replace(hour=11),
            capacidade=10,
            chave_idempotencia="schema-2",
        )


def test_evento_update_exige_inicio_e_fim_juntos() -> None:
    with pytest.raises(ValidationError):
        EventoUpdate(inicio=NOW, versao_esperada=1, chave_idempotencia="schema-3")


def test_evento_update_exige_atributo() -> None:
    with pytest.raises(ValidationError):
        EventoUpdate(versao_esperada=1, chave_idempotencia="schema-4")


def test_produto_update_exige_atributo() -> None:
    with pytest.raises(ValidationError):
        ProdutoUpdate(versao_esperada=1, chave_idempotencia="schema-5")


def test_produto_update_rejeita_null_explicito() -> None:
    with pytest.raises(
        ValidationError,
        match="atributos de atualizacao nao aceitam null",
    ):
        ProdutoUpdate(
            ativo=None,
            versao_esperada=1,
            chave_idempotencia="schema-null-produto",
        )


def test_evento_update_rejeita_null_explicito() -> None:
    with pytest.raises(
        ValidationError,
        match="atributos de atualizacao nao aceitam null",
    ):
        EventoUpdate(
            capacidade=None,
            versao_esperada=1,
            chave_idempotencia="schema-null-evento",
        )


def test_evento_acao_rejeita_acao_desconhecida() -> None:
    with pytest.raises(ValidationError):
        EventoAcaoRequest(acao="PAUSAR", versao_esperada=1, chave_idempotencia="schema-6")


def test_evento_update_rejeita_periodo_invertido() -> None:
    with pytest.raises(ValidationError, match="periodo invalido"):
        EventoUpdate(inicio=NOW, fim=NOW, versao_esperada=1, chave_idempotencia="schema-7")
