"""Contratos de perfis, papeis e permissoes da etapa 2.2.5 a 2.2.7."""

from datetime import date
from pathlib import Path
from typing import cast
from unittest.mock import create_autospec

from sqlalchemy import Select, Table
from sqlalchemy.orm import Session

from app.modules.seguranca.models import (
    PerfilAcesso,
    PerfilPermissao,
    Permissao,
    UsuarioPerfil,
)
from app.modules.seguranca.rbac import ContextoRbac, LeitorRbac, RbacService
from app.modules.seguranca.repositories import RbacRepository

BACKEND_ROOT = Path(__file__).resolve().parents[1]


def test_models_preservam_autoridades_rbac_e_criam_apenas_associacao() -> None:
    perfil = cast(Table, PerfilAcesso.__table__)
    permissao = cast(Table, Permissao.__table__)
    usuario_perfil = cast(Table, UsuarioPerfil.__table__)
    perfil_permissao = cast(Table, PerfilPermissao.__table__)

    assert perfil.name == "perfil_acesso"
    assert permissao.name == "permissao"
    assert usuario_perfil.name == "usuario_perfil"
    assert perfil_permissao.name == "perfil_permissao"
    assert set(perfil_permissao.primary_key.columns.keys()) == {"id_perfil", "id_permissao"}
    assert {constraint.name for constraint in perfil_permissao.foreign_key_constraints} == {
        "fk_perfil_permissao_perfil_acesso",
        "fk_perfil_permissao_permissao",
    }
    assert any(
        index.name == "idx_perfil_permissao_id_permissao" for index in perfil_permissao.indexes
    )


def test_repository_aplica_vigencia_atividade_e_exclusao_logica() -> None:
    session = create_autospec(Session, instance=True)
    session.scalars.side_effect = [("administrador",), ("empresa.ler", "empresa.editar")]
    repository = RbacRepository(session)
    hoje = date(2026, 8, 25)

    assert repository.listar_perfis_ativos(7, hoje) == ("administrador",)
    assert repository.listar_permissoes_ativas(7, hoje) == frozenset(
        {"empresa.ler", "empresa.editar"}
    )

    statements = [call.args[0] for call in session.scalars.call_args_list]
    assert all(isinstance(statement, Select) for statement in statements)
    perfil_sql = str(statements[0].compile(compile_kwargs={"literal_binds": True}))
    permissao_sql = str(statements[1].compile(compile_kwargs={"literal_binds": True}))
    assert "perfil_acesso.ativo IS true" in perfil_sql
    assert "usuario_perfil.data_inicio" in perfil_sql
    assert "usuario_perfil.data_fim" in perfil_sql
    assert "perfil_permissao" in permissao_sql
    assert "permissao.deleted_at IS NULL" in permissao_sql
    assert "perfil_permissao.deleted_at IS NULL" in permissao_sql
    session.commit.assert_not_called()
    session.rollback.assert_not_called()


def test_service_resolve_contexto_vazio_sem_conceder_acesso_implicito() -> None:
    repository = create_autospec(LeitorRbac, instance=True)
    repository.listar_perfis_ativos.return_value = ()
    repository.listar_permissoes_ativas.return_value = frozenset()
    hoje = date(2026, 8, 25)

    contexto = RbacService(repository, clock=lambda: hoje).resolver(7)

    assert contexto == ContextoRbac(id_usuario=7, papeis=(), permissoes=frozenset())
    repository.listar_perfis_ativos.assert_called_once_with(7, hoje)
    repository.listar_permissoes_ativas.assert_called_once_with(7, hoje)


def test_migration_rbac_e_aditiva_reversivel_e_auditavel() -> None:
    migration = (BACKEND_ROOT / "migrations/versions/202608252300_perfil_permissao.py").read_text(
        encoding="utf-8"
    )

    assert 'down_revision: str | Sequence[str] | None = "202608252204"' in migration
    assert 'op.create_table(\n        "perfil_permissao"' in migration
    assert 'name="pk_perfil_permissao"' in migration
    assert "fn_atualiza_updated_at()" in migration
    assert "fn_log_auditoria()" in migration
    assert 'op.drop_table("perfil_permissao")' in migration
