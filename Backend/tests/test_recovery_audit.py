"""Recuperacao de acesso e auditoria de seguranca."""

from datetime import UTC, datetime, timedelta
from typing import cast
from unittest.mock import MagicMock, create_autospec
from uuid import uuid4

import pytest
from sqlalchemy.orm import Session

from app.modules.seguranca.audit import AuditorSeguranca
from app.modules.seguranca.models import RecuperacaoCredencial, Usuario
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

NOW = datetime(2026, 8, 25, 20, tzinfo=UTC)


def _service() -> tuple[RecuperacaoService, MagicMock, MagicMock, MagicMock, MagicMock]:
    usuarios = MagicMock(spec=UsuarioRepository)
    recuperacoes = MagicMock(spec=RecuperacaoRepository)
    sessoes = MagicMock(spec=SessaoUsuarioRepository)
    notificador = create_autospec(NotificadorRecuperacao, instance=True)
    politica = MagicMock(spec=PoliticaHashArgon2id)
    service = RecuperacaoService(
        usuarios, recuperacoes, sessoes, notificador, politica, clock=lambda: NOW
    )
    return service, usuarios, recuperacoes, sessoes, notificador


def test_solicitacao_persiste_apenas_hash_e_notifica_token_opaco() -> None:
    service, usuarios, recuperacoes, _sessoes, notificador = _service()
    usuarios.buscar_por_email.return_value = Usuario(
        id_usuario=7, nome="Ana", email="ana@example.com", ativo=True
    )

    service.solicitar("ana@example.com")

    registro = recuperacoes.adicionar.call_args.args[0]
    token = notificador.enviar.call_args.args[1]
    assert len(registro.token_hash) == 64
    assert token not in registro.token_hash
    assert registro.data_expiracao == NOW.replace(tzinfo=None) + timedelta(minutes=30)


def test_solicitacao_inexistente_tem_resultado_uniforme() -> None:
    service, usuarios, recuperacoes, _sessoes, notificador = _service()
    usuarios.buscar_por_email.return_value = None

    service.solicitar("ausente@example.com")
    recuperacoes.adicionar.assert_not_called()
    notificador.enviar.assert_not_called()


def test_redefinicao_e_de_uso_unico_e_revoga_sessoes() -> None:
    service, usuarios, recuperacoes, sessoes, _notificador = _service()
    registro = RecuperacaoCredencial(
        id_recuperacao=uuid4(),
        id_usuario=7,
        token_hash="a" * 64,
        data_expiracao=NOW.replace(tzinfo=None) + timedelta(minutes=5),
    )
    usuario = Usuario(id_usuario=7, nome="Ana", email="ana@example.com", ativo=True)
    recuperacoes.buscar_por_hash_para_atualizacao.return_value = registro
    usuarios.buscar_por_id.return_value = usuario
    cast(MagicMock, service.politica_hash.gerar).return_value = "novo-hash"

    service.redefinir("token-opaco", "nova-credencial")

    assert usuario.senha_hash == "novo-hash"
    assert registro.utilizado_em == NOW.replace(tzinfo=None)
    sessoes.revogar_usuario.assert_called_once_with(7, NOW.replace(tzinfo=None))


@pytest.mark.parametrize("registro", [None, "utilizado", "expirado"])
def test_redefinicao_nega_token_invalido(registro: str | None) -> None:
    service, _usuarios, recuperacoes, _sessoes, _notificador = _service()
    if registro is None:
        recuperacoes.buscar_por_hash_para_atualizacao.return_value = None
    else:
        recuperacoes.buscar_por_hash_para_atualizacao.return_value = RecuperacaoCredencial(
            id_recuperacao=uuid4(),
            id_usuario=7,
            token_hash="a" * 64,
            data_expiracao=(NOW - timedelta(minutes=1)).replace(tzinfo=None)
            if registro == "expirado"
            else (NOW + timedelta(minutes=1)).replace(tzinfo=None),
            utilizado_em=NOW.replace(tzinfo=None) if registro == "utilizado" else None,
        )
    with pytest.raises(RecuperacaoInvalidaError):
        service.redefinir("invalido", "nova")


def test_auditoria_rejeita_segredos_e_persiste_evento_estruturado() -> None:
    session = create_autospec(Session, instance=True)
    auditor = AuditorSeguranca(session)

    evento = auditor.registrar("LOGIN", "SUCESSO", id_usuario=7, detalhes={"metodo": "senha"})

    assert evento.codigo == "LOGIN"
    session.add.assert_called_once_with(evento)
    with pytest.raises(ValueError):
        auditor.registrar("LOGIN", "NEGADO", detalhes={"token": "segredo"})
