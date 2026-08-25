"""Gates da politica Argon2id para credenciais humanas."""

import pytest
from argon2 import PasswordHasher, extract_parameters
from argon2.low_level import ARGON2_VERSION, Type

from app.modules.seguranca.passwords import (
    ARGON2_HASH_LENGTH,
    ARGON2_MEMORY_COST_KIB,
    ARGON2_PARALLELISM,
    ARGON2_SALT_LENGTH,
    ARGON2_TIME_COST,
    MAX_CREDENTIAL_BYTES,
    PoliticaHashArgon2id,
)
from app.modules.seguranca.services import VerificadorCredencial


@pytest.fixture(scope="module")
def politica() -> PoliticaHashArgon2id:
    return PoliticaHashArgon2id()


def test_gerar_usa_argon2id_com_parametros_explicitos(
    politica: PoliticaHashArgon2id,
) -> None:
    encoded_hash = politica.gerar("credencial correta")
    parameters = extract_parameters(encoded_hash)

    assert encoded_hash.startswith("$argon2id$v=19$")
    assert parameters.type is Type.ID
    assert parameters.version == ARGON2_VERSION
    assert parameters.memory_cost == ARGON2_MEMORY_COST_KIB
    assert parameters.time_cost == ARGON2_TIME_COST
    assert parameters.parallelism == ARGON2_PARALLELISM
    assert parameters.hash_len == ARGON2_HASH_LENGTH
    assert parameters.salt_len == ARGON2_SALT_LENGTH


def test_gerar_usa_salt_aleatorio(politica: PoliticaHashArgon2id) -> None:
    assert politica.gerar("mesma credencial") != politica.gerar("mesma credencial")


def test_verificar_aceita_credencial_correta(politica: PoliticaHashArgon2id) -> None:
    encoded_hash = politica.gerar("credencial correta")

    assert politica.verificar("credencial correta", encoded_hash)


@pytest.mark.parametrize("stored_hash", (None, "hash-invalido"))
def test_verificar_recusa_ausencia_ou_hash_invalido(
    politica: PoliticaHashArgon2id, stored_hash: str | None
) -> None:
    assert not politica.verificar("credencial", stored_hash)


def test_verificar_recusa_credencial_incorreta(politica: PoliticaHashArgon2id) -> None:
    encoded_hash = politica.gerar("credencial correta")

    assert not politica.verificar("credencial incorreta", encoded_hash)


def test_limites_de_entrada_protegem_a_operacao(politica: PoliticaHashArgon2id) -> None:
    with pytest.raises(ValueError, match="vazia"):
        politica.gerar("")
    with pytest.raises(ValueError, match="limite"):
        politica.gerar("a" * (MAX_CREDENTIAL_BYTES + 1))

    assert not politica.verificar("a" * (MAX_CREDENTIAL_BYTES + 1), None)


def test_precisa_rehash_detecta_parametros_antigos_e_hash_invalido(
    politica: PoliticaHashArgon2id,
) -> None:
    previous_policy = PasswordHasher(
        time_cost=2,
        memory_cost=ARGON2_MEMORY_COST_KIB,
        parallelism=ARGON2_PARALLELISM,
        hash_len=ARGON2_HASH_LENGTH,
        salt_len=ARGON2_SALT_LENGTH,
        type=Type.ID,
    )

    assert not politica.precisa_rehash(politica.gerar("credencial"))
    assert politica.precisa_rehash(previous_policy.hash("credencial"))
    assert politica.precisa_rehash("hash-invalido")


def test_politica_satisfaz_o_contrato_da_autenticacao(
    politica: PoliticaHashArgon2id,
) -> None:
    verificador: VerificadorCredencial = politica

    assert verificador is politica
