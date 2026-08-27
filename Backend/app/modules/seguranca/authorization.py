"""Dependencias HTTP de autenticacao e autorizacao RBAC."""

from collections.abc import Callable
from datetime import UTC, datetime
from typing import Annotated

from fastapi import Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.db.session import get_session
from app.modules.seguranca.audit import AuditorSeguranca
from app.modules.seguranca.rbac import ContextoRbac, RbacService
from app.modules.seguranca.repositories import (
    RbacRepository,
    SessaoUsuarioRepository,
    UsuarioRepository,
)
from app.modules.seguranca.tokens import CodecTokenAcesso, TokenInvalidoError

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def _auditar_decisao(
    session: Session,
    request: Request,
    resultado: str,
    *,
    id_usuario: int | None = None,
    permissao: str | None = None,
) -> None:
    detalhes: dict[str, object] = {"metodo": request.method, "caminho": request.url.path}
    if permissao is not None:
        detalhes["permissao"] = permissao
    AuditorSeguranca(session).registrar(
        "AUTORIZACAO",
        resultado,
        id_usuario=id_usuario,
        endereco_ip=request.client.host if request.client else None,
        agente_usuario=request.headers.get("user-agent", "")[:255] or None,
        detalhes=detalhes,
    )
    session.commit()


def obter_contexto_rbac(
    token: Annotated[str, Depends(oauth2_scheme)],
    session: Annotated[Session, Depends(get_session)],
    settings: Annotated[Settings, Depends(get_settings)],
    request: Request,
) -> ContextoRbac:
    """Valida token e sessao antes de resolver as concessoes atuais no banco."""
    try:
        claims = CodecTokenAcesso(settings).validar(token)
    except TokenInvalidoError as exc:
        _auditar_decisao(session, request, "NEGADO")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc

    agora = datetime.now(UTC).replace(tzinfo=None)
    sessoes = SessaoUsuarioRepository(session)
    if sessoes.buscar_ativa(claims.id_sessao, claims.id_usuario, agora) is None:
        _auditar_decisao(session, request, "NEGADO", id_usuario=claims.id_usuario)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            headers={"WWW-Authenticate": "Bearer"},
        )
    if UsuarioRepository(session).buscar_ativo_por_id(claims.id_usuario) is None:
        sessoes.revogar_usuario(claims.id_usuario, agora)
        _auditar_decisao(session, request, "NEGADO", id_usuario=claims.id_usuario)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            headers={"WWW-Authenticate": "Bearer"},
        )
    return RbacService(RbacRepository(session)).resolver(claims.id_usuario)


def exigir_permissao(codigo: str) -> Callable[..., ContextoRbac]:
    """Cria uma dependencia que nega acesso quando a concessao nao for explicita."""

    def verificar(
        contexto: Annotated[ContextoRbac, Depends(obter_contexto_rbac)],
        request: Request,
        session: Annotated[Session, Depends(get_session)],
    ) -> ContextoRbac:
        if codigo not in contexto.permissoes:
            _auditar_decisao(
                session,
                request,
                "NEGADO",
                id_usuario=contexto.id_usuario,
                permissao=codigo,
            )
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN)
        _auditar_decisao(
            session,
            request,
            "SUCESSO",
            id_usuario=contexto.id_usuario,
            permissao=codigo,
        )
        return contexto

    return verificar


exigir_core_visualizar = exigir_permissao("CORE_VISUALIZAR")
exigir_core_cadastrar = exigir_permissao("CORE_CADASTRAR")
