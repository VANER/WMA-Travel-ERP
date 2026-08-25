"""Emissao e rotacao de tokens para sessoes humanas."""

from collections.abc import Callable
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from hashlib import sha256
from secrets import token_urlsafe
from typing import Protocol
from uuid import UUID, uuid4

import jwt
from jwt import InvalidTokenError

from app.core.config import Settings
from app.modules.seguranca.models import SessaoUsuario
from app.modules.seguranca.services import IdentidadeAutenticada

JWT_ALGORITHM = "HS256"
REFRESH_TOKEN_BYTES = 32
REQUIRED_CLAIMS = ["iss", "aud", "sub", "sid", "jti", "iat", "nbf", "exp", "typ"]


class TokenInvalidoError(Exception):
    """Falha uniforme para tokens ausentes, invalidos, expirados ou reutilizados."""


@dataclass(frozen=True, slots=True)
class ClaimsAcesso:
    id_usuario: int
    id_sessao: UUID
    id_token: UUID


@dataclass(frozen=True, slots=True)
class ParTokens:
    access_token: str
    refresh_token: str
    token_type: str
    expires_in: int


class RepositorioSessao(Protocol):
    def adicionar(self, sessao: SessaoUsuario) -> None: ...

    def buscar_por_hash_para_atualizacao(self, token_hash: str) -> SessaoUsuario | None: ...

    def revogar_familia(self, id_familia: UUID, instante: datetime) -> None: ...


class CodecTokenAcesso:
    """Assina e valida JWTs de acesso com algoritmo e claims fixos."""

    def __init__(self, settings: Settings) -> None:
        self._key = settings.token_signing_key.get_secret_value()
        self._issuer = settings.token_issuer
        self._audience = settings.token_audience
        self._ttl = timedelta(minutes=settings.access_token_ttl_minutes)

    @property
    def expires_in(self) -> int:
        return int(self._ttl.total_seconds())

    def emitir(self, id_usuario: int, id_sessao: UUID, agora: datetime) -> str:
        agora_utc = _como_utc(agora)
        payload = {
            "iss": self._issuer,
            "aud": self._audience,
            "sub": str(id_usuario),
            "sid": str(id_sessao),
            "jti": str(uuid4()),
            "iat": agora_utc,
            "nbf": agora_utc,
            "exp": agora_utc + self._ttl,
            "typ": "access",
        }
        return jwt.encode(payload, self._key, algorithm=JWT_ALGORITHM)

    def validar(self, token: str) -> ClaimsAcesso:
        try:
            payload = jwt.decode(
                token,
                self._key,
                algorithms=[JWT_ALGORITHM],
                audience=self._audience,
                issuer=self._issuer,
                options={"require": REQUIRED_CLAIMS, "strict_aud": True},
            )
            if payload["typ"] != "access":
                raise TokenInvalidoError
            return ClaimsAcesso(
                id_usuario=int(payload["sub"]),
                id_sessao=UUID(payload["sid"]),
                id_token=UUID(payload["jti"]),
            )
        except (InvalidTokenError, KeyError, TypeError, ValueError) as exc:
            raise TokenInvalidoError from exc


class SessaoService:
    """Cria, renova e revoga familias de sessoes humanas."""

    def __init__(
        self,
        repository: RepositorioSessao,
        codec: CodecTokenAcesso,
        settings: Settings,
        clock: Callable[[], datetime] = lambda: datetime.now(UTC),
    ) -> None:
        self.repository = repository
        self.codec = codec
        self._refresh_ttl = timedelta(days=settings.refresh_token_ttl_days)
        self._clock = clock

    def iniciar(self, identidade: IdentidadeAutenticada) -> ParTokens:
        agora = _utc_sem_fuso(self._clock())
        id_sessao = uuid4()
        refresh_token = token_urlsafe(REFRESH_TOKEN_BYTES)
        self.repository.adicionar(
            SessaoUsuario(
                id_sessao=id_sessao,
                id_usuario=identidade.id_usuario,
                id_familia=id_sessao,
                token_refresh_hash=_hash_refresh(refresh_token),
                data_expiracao=agora + self._refresh_ttl,
            )
        )
        return self._par(identidade.id_usuario, id_sessao, refresh_token, agora)

    def renovar(self, refresh_token: str) -> ParTokens:
        agora = _utc_sem_fuso(self._clock())
        sessao = self.repository.buscar_por_hash_para_atualizacao(_hash_refresh(refresh_token))
        if sessao is None:
            raise TokenInvalidoError
        if sessao.revogado_em is not None:
            self.repository.revogar_familia(sessao.id_familia, agora)
            raise TokenInvalidoError
        if sessao.deleted_at is not None or sessao.data_expiracao <= agora:
            self.repository.revogar_familia(sessao.id_familia, agora)
            raise TokenInvalidoError

        novo_id = uuid4()
        novo_refresh = token_urlsafe(REFRESH_TOKEN_BYTES)
        sessao.revogado_em = agora
        sessao.updated_at = agora
        sessao.id_sessao_substituta = novo_id
        self.repository.adicionar(
            SessaoUsuario(
                id_sessao=novo_id,
                id_usuario=sessao.id_usuario,
                id_familia=sessao.id_familia,
                token_refresh_hash=_hash_refresh(novo_refresh),
                data_expiracao=agora + self._refresh_ttl,
            )
        )
        return self._par(sessao.id_usuario, novo_id, novo_refresh, agora)

    def revogar(self, refresh_token: str) -> None:
        agora = _utc_sem_fuso(self._clock())
        sessao = self.repository.buscar_por_hash_para_atualizacao(_hash_refresh(refresh_token))
        if sessao is not None:
            self.repository.revogar_familia(sessao.id_familia, agora)

    def _par(
        self, id_usuario: int, id_sessao: UUID, refresh_token: str, agora: datetime
    ) -> ParTokens:
        return ParTokens(
            access_token=self.codec.emitir(id_usuario, id_sessao, agora.replace(tzinfo=UTC)),
            refresh_token=refresh_token,
            token_type="Bearer",
            expires_in=self.codec.expires_in,
        )


def _hash_refresh(token: str) -> str:
    return sha256(token.encode("utf-8")).hexdigest()


def _como_utc(instante: datetime) -> datetime:
    if instante.tzinfo is None:
        return instante.replace(tzinfo=UTC)
    return instante.astimezone(UTC)


def _utc_sem_fuso(instante: datetime) -> datetime:
    return _como_utc(instante).replace(tzinfo=None)
