"""Orquestracao da autenticacao humana sem definir hash ou sessao."""

from dataclasses import dataclass
from typing import Protocol

from app.modules.seguranca.repositories import UsuarioRepository


class VerificadorCredencial(Protocol):
    """Porta consumida pela autenticacao para verificar credenciais."""

    def verificar(self, credencial: str, credencial_armazenada: str | None) -> bool:
        """Compara a credencial apresentada sem expor detalhes do armazenamento."""
        ...


class AutenticacaoNegadaError(Exception):
    """Falha unica para impedir enumeracao de contas e estados."""


@dataclass(frozen=True, slots=True)
class IdentidadeAutenticada:
    """Identidade confirmada, sem perfil, permissao, token ou sessao."""

    id_usuario: int
    nome: str
    email: str


class AutenticacaoService:
    """Valida uma credencial e o estado minimo da identidade humana."""

    def __init__(
        self,
        repository: UsuarioRepository,
        verificador: VerificadorCredencial,
    ) -> None:
        self.repository = repository
        self.verificador = verificador

    def autenticar(self, email: str, credencial: str) -> IdentidadeAutenticada:
        """Retorna somente a identidade quando todos os gates forem satisfeitos."""
        usuario = self.repository.buscar_por_email(email)
        credencial_armazenada = usuario.senha_hash if usuario is not None else None
        credencial_valida = self.verificador.verificar(credencial, credencial_armazenada)

        if (
            not email.strip()
            or not credencial
            or usuario is None
            or usuario.ativo is not True
            or usuario.deleted_at is not None
            or usuario.senha_hash is None
            or not credencial_valida
        ):
            raise AutenticacaoNegadaError

        return IdentidadeAutenticada(
            id_usuario=usuario.id_usuario,
            nome=usuario.nome,
            email=usuario.email,
        )
