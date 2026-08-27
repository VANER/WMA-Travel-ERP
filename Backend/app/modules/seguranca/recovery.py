"""Recuperacao de credenciais com token opaco de uso unico."""

from collections.abc import Callable
from datetime import UTC, datetime, timedelta
from hashlib import sha256
from secrets import token_urlsafe
from typing import Protocol
from uuid import uuid4

from app.modules.seguranca.models import RecuperacaoCredencial
from app.modules.seguranca.passwords import PoliticaHashArgon2id
from app.modules.seguranca.repositories import (
    RecuperacaoRepository,
    SessaoUsuarioRepository,
    UsuarioRepository,
)

RECOVERY_TOKEN_BYTES = 32
RECOVERY_TTL = timedelta(minutes=30)


class RecuperacaoInvalidaError(Exception):
    """Falha uniforme para token ausente, expirado ou reutilizado."""


class NotificadorRecuperacao(Protocol):
    def enviar(self, email: str, token: str) -> None: ...


class RecuperacaoService:
    """Emite e consome recuperacoes sem expor a existencia da identidade."""

    def __init__(
        self,
        usuarios: UsuarioRepository,
        recuperacoes: RecuperacaoRepository,
        sessoes: SessaoUsuarioRepository,
        notificador: NotificadorRecuperacao,
        politica_hash: PoliticaHashArgon2id,
        clock: Callable[[], datetime] = lambda: datetime.now(UTC),
    ) -> None:
        self.usuarios = usuarios
        self.recuperacoes = recuperacoes
        self.sessoes = sessoes
        self.notificador = notificador
        self.politica_hash = politica_hash
        self._clock = clock

    def solicitar(self, email: str) -> None:
        usuario = self.usuarios.buscar_por_email(email)
        if usuario is None or usuario.ativo is not True or usuario.deleted_at is not None:
            return
        agora = _utc_sem_fuso(self._clock())
        token = token_urlsafe(RECOVERY_TOKEN_BYTES)
        self.recuperacoes.adicionar(
            RecuperacaoCredencial(
                id_recuperacao=uuid4(),
                id_usuario=usuario.id_usuario,
                token_hash=_hash_token(token),
                data_expiracao=agora + RECOVERY_TTL,
            )
        )
        self.notificador.enviar(usuario.email, token)

    def redefinir(self, token: str, nova_credencial: str) -> None:
        agora = _utc_sem_fuso(self._clock())
        recuperacao = self.recuperacoes.buscar_por_hash_para_atualizacao(_hash_token(token))
        if (
            recuperacao is None
            or recuperacao.utilizado_em is not None
            or recuperacao.data_expiracao <= agora
        ):
            raise RecuperacaoInvalidaError
        usuario = self.usuarios.buscar_por_id(recuperacao.id_usuario)
        if usuario is None or usuario.ativo is not True or usuario.deleted_at is not None:
            raise RecuperacaoInvalidaError
        usuario.senha_hash = self.politica_hash.gerar(nova_credencial)
        usuario.updated_at = agora
        recuperacao.utilizado_em = agora
        self.sessoes.revogar_usuario(usuario.id_usuario, agora)


def _hash_token(token: str) -> str:
    return sha256(token.encode("utf-8")).hexdigest()


def _utc_sem_fuso(instante: datetime) -> datetime:
    if instante.tzinfo is None:
        return instante
    return instante.astimezone(UTC).replace(tzinfo=None)
