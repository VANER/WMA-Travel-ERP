"""Endpoints de autenticacao e ciclo de vida da sessao humana."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.db.session import get_session
from app.modules.seguranca.audit import AuditorSeguranca
from app.modules.seguranca.passwords import PoliticaHashArgon2id
from app.modules.seguranca.repositories import SessaoUsuarioRepository, UsuarioRepository
from app.modules.seguranca.schemas import LoginRequest, RefreshRequest, TokenResponse
from app.modules.seguranca.services import AutenticacaoNegadaError, AutenticacaoService
from app.modules.seguranca.tokens import CodecTokenAcesso, SessaoService, TokenInvalidoError

router = APIRouter(prefix="/auth", tags=["seguranca"])
SessionDep = Annotated[Session, Depends(get_session)]
SettingsDep = Annotated[Settings, Depends(get_settings)]


def _sessao_service(session: Session, settings: Settings) -> SessaoService:
    return SessaoService(SessaoUsuarioRepository(session), CodecTokenAcesso(settings), settings)


def _auditar(
    session: Session,
    request: Request,
    codigo: str,
    resultado: str,
    *,
    id_usuario: int | None = None,
) -> None:
    AuditorSeguranca(session).registrar(
        codigo,
        resultado,
        id_usuario=id_usuario,
        endereco_ip=request.client.host if request.client else None,
        agente_usuario=request.headers.get("user-agent", "")[:255] or None,
    )


@router.post("/login", response_model=TokenResponse)
def login(
    payload: LoginRequest, request: Request, session: SessionDep, settings: SettingsDep
) -> TokenResponse:
    try:
        identidade = AutenticacaoService(
            UsuarioRepository(session), PoliticaHashArgon2id()
        ).autenticar(str(payload.email), payload.credencial)
        tokens = _sessao_service(session, settings).iniciar(identidade)
        _auditar(session, request, "LOGIN", "SUCESSO", id_usuario=identidade.id_usuario)
        session.commit()
    except AutenticacaoNegadaError as exc:
        session.rollback()
        _auditar(session, request, "LOGIN", "NEGADO")
        session.commit()
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED) from exc
    except Exception:
        session.rollback()
        raise
    return TokenResponse(
        access_token=tokens.access_token,
        refresh_token=tokens.refresh_token,
        token_type=tokens.token_type,
        expires_in=tokens.expires_in,
    )


@router.post("/refresh", response_model=TokenResponse)
def refresh(
    payload: RefreshRequest, request: Request, session: SessionDep, settings: SettingsDep
) -> TokenResponse:
    try:
        tokens = _sessao_service(session, settings).renovar(payload.refresh_token)
        _auditar(session, request, "TOKEN_REFRESH", "SUCESSO")
        session.commit()
    except TokenInvalidoError as exc:
        session.rollback()
        _auditar(session, request, "TOKEN_REFRESH", "NEGADO")
        session.commit()
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED) from exc
    return TokenResponse(
        access_token=tokens.access_token,
        refresh_token=tokens.refresh_token,
        token_type=tokens.token_type,
        expires_in=tokens.expires_in,
    )


@router.post("/logout", status_code=status.HTTP_204_NO_CONTENT)
def logout(
    payload: RefreshRequest, request: Request, session: SessionDep, settings: SettingsDep
) -> Response:
    _sessao_service(session, settings).revogar(payload.refresh_token)
    _auditar(session, request, "LOGOUT", "SUCESSO")
    session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
