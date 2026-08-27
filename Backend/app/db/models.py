"""Registro central dos models gerenciados pelo Alembic."""

from app.modules.corporativo.models import (
    Cliente,
    ConfiguracaoEmpresa,
    Documento,
    Empresa,
    Fornecedor,
    Localidade,
    ParametroSistema,
    Pessoa,
    TipoDocumento,
)
from app.modules.seguranca.models import (
    EventoSeguranca,
    PerfilAcesso,
    PerfilPermissao,
    Permissao,
    RecuperacaoCredencial,
    SessaoUsuario,
    Usuario,
    UsuarioPerfil,
)

__all__ = [
    "Cliente",
    "ConfiguracaoEmpresa",
    "Documento",
    "Empresa",
    "EventoSeguranca",
    "Fornecedor",
    "Localidade",
    "ParametroSistema",
    "PerfilAcesso",
    "PerfilPermissao",
    "Permissao",
    "RecuperacaoCredencial",
    "Pessoa",
    "SessaoUsuario",
    "TipoDocumento",
    "Usuario",
    "UsuarioPerfil",
]
