"""Politica de hash para credenciais humanas."""

from contextlib import suppress

from argon2 import PasswordHasher
from argon2.exceptions import InvalidHashError, VerificationError, VerifyMismatchError
from argon2.low_level import Type

ARGON2_TIME_COST = 3
ARGON2_MEMORY_COST_KIB = 65_536
ARGON2_PARALLELISM = 4
ARGON2_HASH_LENGTH = 32
ARGON2_SALT_LENGTH = 16
MAX_CREDENTIAL_BYTES = 1_024

_DUMMY_CREDENTIAL = "wma-authentication-dummy-credential"


class PoliticaHashArgon2id:
    """Gera e verifica hashes Argon2id com parametros versionados no proprio hash."""

    def __init__(self) -> None:
        self._hasher = PasswordHasher(
            time_cost=ARGON2_TIME_COST,
            memory_cost=ARGON2_MEMORY_COST_KIB,
            parallelism=ARGON2_PARALLELISM,
            hash_len=ARGON2_HASH_LENGTH,
            salt_len=ARGON2_SALT_LENGTH,
            type=Type.ID,
        )
        self._dummy_hash = self._hasher.hash(_DUMMY_CREDENTIAL)

    def gerar(self, credencial: str) -> str:
        """Gera um hash Argon2id para uma credencial valida."""
        if not credencial:
            raise ValueError("credencial nao pode ser vazia")
        if len(credencial.encode("utf-8")) > MAX_CREDENTIAL_BYTES:
            raise ValueError("credencial excede o limite de bytes")
        return self._hasher.hash(credencial)

    def verificar(self, credencial: str, credencial_armazenada: str | None) -> bool:
        """Compara a credencial e preserva trabalho de hash para identidades ausentes."""
        entrada_valida = len(credencial.encode("utf-8")) <= MAX_CREDENTIAL_BYTES
        credencial_limitada = credencial if entrada_valida else _DUMMY_CREDENTIAL
        hash_alvo = credencial_armazenada or self._dummy_hash

        try:
            corresponde = self._hasher.verify(hash_alvo, credencial_limitada)
        except VerifyMismatchError:
            return False
        except (InvalidHashError, VerificationError):
            if credencial_armazenada is not None:
                self._verificar_hash_ficticio(credencial_limitada)
            return False

        return bool(corresponde) and entrada_valida and credencial_armazenada is not None

    def precisa_rehash(self, credencial_armazenada: str) -> bool:
        """Indica hash invalido ou parametros diferentes da politica atual."""
        try:
            return self._hasher.check_needs_rehash(credencial_armazenada)
        except InvalidHashError:
            return True

    def _verificar_hash_ficticio(self, credencial: str) -> None:
        with suppress(VerifyMismatchError):
            self._hasher.verify(self._dummy_hash, credencial)
