"""Limites, unicidade e rejeicao de dados pessoais nos comandos operacionais."""

import pytest
from pydantic import ValidationError

from app.modules.biketour import operational_schemas as s


@pytest.mark.parametrize(
    "tipo,origem", [("BICICLETA", {}), ("GUIA", {"id_guia": 1}), ("VEICULO", {"id_transporte": 1})]
)
def test_origens_validas(tipo: str, origem: dict[str, int]) -> None:
    assert s.RecursoCreate(codigo="R1", tipo=tipo, chave_idempotencia="k", **origem).tipo == tipo


@pytest.mark.parametrize(
    "tipo,origem", [("BICICLETA", {"id_guia": 1}), ("GUIA", {}), ("VEICULO", {})]
)
def test_origem_incompativel(tipo: str, origem: dict[str, int]) -> None:
    with pytest.raises(ValidationError):
        s.RecursoCreate(codigo="R1", tipo=tipo, chave_idempotencia="k", **origem)


def test_recursos_duplicados_e_dados_extras_rejeitados() -> None:
    with pytest.raises(ValidationError):
        s.RecursosInscricao(id_bicicleta=1, ids_equipamentos=[1])
    with pytest.raises(ValidationError):
        s.OcorrenciaCreate.model_validate(
            {
                "tipo": "OUTRA",
                "gravidade": "BAIXA",
                "motivo": "OPERACIONAL",
                "chave_idempotencia": "k",
                "nome": "PII",
            }
        )


def test_rota_rejeita_ordem_ou_distancia_repetida() -> None:
    with pytest.raises(ValidationError):
        s.PontosRequest(
            pontos=[s.PontoInput(ordem=1, id_localidade=1, distancia_km=0)] * 2,
            versao_esperada=1,
            chave_idempotencia="k",
        )


def test_equipe_e_apoio_nao_duplicam_recursos() -> None:
    with pytest.raises(ValidationError):
        s.EquipeRequest(
            equipe=[s.GuiaInput(id_recurso=1, papel="LIDER")] * 2,
            versao_esperada=1,
            chave_idempotencia="k",
        )
    with pytest.raises(ValidationError):
        s.LogisticaRequest(
            apoio=[s.ApoioInput(id_recurso=1, finalidade="APOIO")] * 2,
            versao_esperada=1,
            chave_idempotencia="k",
        )
