"""Gates da autenticacao humana sem antecipar hash, tokens ou sessao."""

from datetime import datetime
from typing import cast
from unittest.mock import MagicMock, create_autospec

import pytest
from sqlalchemy import Select, Table
from sqlalchemy.orm import Session

from app.modules.seguranca.models import Usuario
from app.modules.seguranca.repositories import UsuarioRepository
from app.modules.seguranca.services import (
    AutenticacaoNegadaError,
    AutenticacaoService,
    IdentidadeAutenticada,
    VerificadorCredencial,
)


def test_usuario_reflete_a_autoridade_humana_da_baseline() -> None:
    table = cast(Table, Usuario.__table__)

    assert table.name == "usuario"
    assert table.schema is None
    assert table.comment == "Usuários autorizados do sistema"
    assert set(table.columns.keys()) == {
        "id_usuario",
        "nome",
        "email",
        "senha_hash",
        "perfil",
        "ativo",
        "created_at",
        "updated_at",
        "deleted_at",
        "created_by",
        "updated_by",
        "deleted_by",
        "versao",
    }
    assert table.c.senha_hash.nullable is True
    assert any(constraint.name == "uk_usuario_email" for constraint in table.constraints)


def test_repository_remove_espacos_do_email_e_nao_altera_transacao() -> None:
    session = create_autospec(Session, instance=True)
    expected = Usuario(id_usuario=7, nome="Ana", email="ana@example.com")
    session.scalar.return_value = expected

    result = UsuarioRepository(session).buscar_por_email("  ana@example.com ")

    assert result is expected
    statement = session.scalar.call_args.args[0]
    assert isinstance(statement, Select)
    compiled = str(statement.compile(compile_kwargs={"literal_binds": True}))
    assert "usuario.email = 'ana@example.com'" in compiled
    session.commit.assert_not_called()
    session.rollback.assert_not_called()


def test_service_retorna_apenas_identidade_autenticada() -> None:
    usuario = Usuario(
        id_usuario=7,
        nome="Ana",
        email="ana@example.com",
        senha_hash="formato-a-decidir",
        ativo=True,
    )
    repository = MagicMock(spec=UsuarioRepository)
    repository.buscar_por_email.return_value = usuario
    verificador = create_autospec(VerificadorCredencial, instance=True)
    verificador.verificar.return_value = True

    result = AutenticacaoService(repository, verificador).autenticar(
        "ana@example.com", "credencial"
    )

    assert result == IdentidadeAutenticada(7, "Ana", "ana@example.com")
    verificador.verificar.assert_called_once_with("credencial", "formato-a-decidir")


@pytest.mark.parametrize(
    ("email", "credencial", "usuario", "credencial_valida"),
    (
        ("ana@example.com", "credencial", None, False),
        (
            "ana@example.com",
            "credencial",
            Usuario(nome="Ana", email="ana@example.com", senha_hash=None, ativo=True),
            False,
        ),
        (
            "ana@example.com",
            "credencial",
            Usuario(nome="Ana", email="ana@example.com", senha_hash="hash", ativo=False),
            True,
        ),
        (
            "ana@example.com",
            "credencial",
            Usuario(
                nome="Ana",
                email="ana@example.com",
                senha_hash="hash",
                ativo=True,
                deleted_at=datetime(2026, 8, 25),
            ),
            True,
        ),
        (
            "ana@example.com",
            "credencial",
            Usuario(nome="Ana", email="ana@example.com", senha_hash="hash", ativo=True),
            False,
        ),
        (
            " ",
            "credencial",
            Usuario(nome="Ana", email="", senha_hash="hash", ativo=True),
            True,
        ),
        (
            "ana@example.com",
            "",
            Usuario(nome="Ana", email="ana@example.com", senha_hash="hash", ativo=True),
            True,
        ),
    ),
)
def test_service_nega_todas_as_falhas_com_o_mesmo_erro(
    email: str,
    credencial: str,
    usuario: Usuario | None,
    credencial_valida: bool,
) -> None:
    repository = MagicMock(spec=UsuarioRepository)
    repository.buscar_por_email.return_value = usuario
    verificador = create_autospec(VerificadorCredencial, instance=True)
    verificador.verificar.return_value = credencial_valida

    with pytest.raises(AutenticacaoNegadaError):
        AutenticacaoService(repository, verificador).autenticar(email, credencial)

    stored = usuario.senha_hash if usuario is not None else None
    verificador.verificar.assert_called_once_with(credencial, stored)
