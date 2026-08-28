"""Endpoints de autenticacao e ciclo de vida da sessao humana."""

from typing import Annotated

from fastapi import APIRouter, Depends, HTTPException, Request, Response, status
from sqlalchemy.orm import Session

from app.core.config import Settings, get_settings
from app.db.session import get_session
from app.integrations.email_hostgator import NotificadorRecuperacaoHostGator
from app.modules.seguranca.audit import AuditorSeguranca
from app.modules.seguranca.passwords import PoliticaHashArgon2id
from app.modules.seguranca.recovery import (
    NotificadorRecuperacao,
    RecuperacaoInvalidaError,
    RecuperacaoService,
)
from app.modules.seguranca.repositories import (
    RecuperacaoRepository,
    SessaoUsuarioRepository,
    UsuarioRepository,
)
from app.modules.seguranca.schemas import (
    LoginRequest,
    RecuperacaoRequest,
    RedefinicaoRequest,
    RefreshRequest,
    TokenResponse,
)
from app.modules.seguranca.services import AutenticacaoNegadaError, AutenticacaoService
from app.modules.seguranca.tokens import CodecTokenAcesso, SessaoService, TokenInvalidoError

router = APIRouter(prefix="/auth", tags=["seguranca"])
SessionDep = Annotated[Session, Depends(get_session)]
SettingsDep = Annotated[Settings, Depends(get_settings)]


def obter_notificador_recuperacao(settings: SettingsDep) -> NotificadorRecuperacao:
    """Ativa o SMTP autorizado somente quando o segredo foi injetado no ambiente."""
    if settings.smtp_password is None:
        raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE)
    return NotificadorRecuperacaoHostGator(settings)


NotificadorDep = Annotated[NotificadorRecuperacao, Depends(obter_notificador_recuperacao)]


def _sessao_service(session: Session, settings: Settings) -> SessaoService:
    return SessaoService(SessaoUsuarioRepository(session), CodecTokenAcesso(settings), settings)


def _recuperacao_service(session: Session) -> RecuperacaoService:
    return RecuperacaoService(
        UsuarioRepository(session),
        RecuperacaoRepository(session),
        SessaoUsuarioRepository(session),
        PoliticaHashArgon2id(),
    )


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


@router.post("/recovery/request", status_code=status.HTTP_202_ACCEPTED)
def solicitar_recuperacao(
    payload: RecuperacaoRequest,
    request: Request,
    session: SessionDep,
    notificador: NotificadorDep,
) -> Response:
    try:
        entrega = _recuperacao_service(session).solicitar(payload.email)
        _auditar(session, request, "RECUPERACAO_SOLICITADA", "SUCESSO")
        session.commit()
    except Exception:
        session.rollback()
        raise
    if entrega is not None:
        try:
            notificador.enviar(entrega.email, entrega.token)
        except Exception as exc:
            session.rollback()
            _auditar(session, request, "RECUPERACAO_ENTREGUE", "ERRO")
            session.commit()
            raise HTTPException(status_code=status.HTTP_503_SERVICE_UNAVAILABLE) from exc
        _auditar(session, request, "RECUPERACAO_ENTREGUE", "SUCESSO")
        session.commit()
    return Response(status_code=status.HTTP_202_ACCEPTED)


@router.post("/recovery/reset", status_code=status.HTTP_204_NO_CONTENT)
def redefinir_credencial(
    payload: RedefinicaoRequest,
    request: Request,
    session: SessionDep,
) -> Response:
    try:
        _recuperacao_service(session).redefinir(payload.token, payload.nova_credencial)
        _auditar(session, request, "CREDENCIAL_REDEFINIDA", "SUCESSO")
        session.commit()
    except RecuperacaoInvalidaError as exc:
        session.rollback()
        _auditar(session, request, "CREDENCIAL_REDEFINIDA", "NEGADO")
        session.commit()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST) from exc
    except Exception:
        session.rollback()
        raise
    return Response(status_code=status.HTTP_204_NO_CONTENT)
