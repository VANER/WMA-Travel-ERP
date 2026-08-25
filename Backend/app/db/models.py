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
from app.modules.seguranca.models import Usuario

__all__ = [
    "Cliente",
    "ConfiguracaoEmpresa",
    "Documento",
    "Empresa",
    "Fornecedor",
    "Localidade",
    "ParametroSistema",
    "Pessoa",
    "TipoDocumento",
    "Usuario",
]
