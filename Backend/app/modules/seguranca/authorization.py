"""Dependencias HTTP de autenticacao e autorizacao RBAC."""

from datetime import UTC, datetime
from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.db.session import get_session
from app.modules.seguranca.rbac import ContextoRbac, RbacService
from app.modules.seguranca.repositories import RbacRepository, SessaoUsuarioRepository
from app.modules.seguranca.tokens import CodecTokenAcesso, TokenInvalidoError

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def obter_contexto_rbac(
    token: Annotated[str, Depends(oauth2_scheme)],
    session: Annotated[Session, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
) -> ContextoRbac:
    """Valida token e sessao antes de resolver as concessoes atuais no banco."""
    try:
        claims = CodecTokenAcesso(settings).validar(token)
    except TokenInvalidoError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    agora = datetime.now(UTC).replace(tzinfo=None)
    if (
        SessaoUsuarioRepository(session).buscar_ativa(claims.id_sessao, claims.id_usuario, agora)
        is None
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            headers={"WWW-Authenticate": "Bearer"},
        )
    return RbacService(RbacRepository(session)).resolver(claims.id_usuario)


def exigir_permissao(codigo: str):  # type: ignore[no-untyped-def]
    """Cria uma dependencia que nega acesso quando a concessao nao for explicita."""

    def verificar(contexto: Annotated[ContextoRbac, Depends(obter_contexto_rbac)]) -> ContextoRbac:
        if codigo not in contexto.permissoes:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
        return contexto

    return verificar


exigir_core_visualizar = exigir_permissao("CORE_VISUALIZAR")
exigir_core_cadastrar = exigir_permissao("CORE_CADASTRAR")
