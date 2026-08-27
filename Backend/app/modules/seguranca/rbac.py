"""Contratos de perfis, papeis e permissoes efetivos."""

from collections.abc import Callable
from dataclasses import dataclass
from datetime import date
from typing import Protocol


class LeitorRbac(Protocol):
    def listar_perfis_ativos(self, id_usuario: int, hoje: date) -> tuple[str, ...]: ...

    def listar_permissoes_ativas(self, id_usuario: int, hoje: date) -> frozenset[str]: ...


@dataclass(frozen=True, slots=True)
class ContextoRbac:
    """Papeis e permissoes efetivos de uma identidade no instante consultado."""

    id_usuario: int
    papeis: tuple[str, ...]
    permissoes: frozenset[str]


class RbacService:
    """Resolve o contexto RBAC vigente, negando implicitamente o que nao estiver atribuido."""

    def __init__(self, repository: LeitorRbac, clock: Callable[[], date] = date.today) -> None:
        self.repository = repository
        self._clock = clock

    def resolver(self, id_usuario: int) -> ContextoRbac:
        hoje = self._clock()
        return ContextoRbac(
            id_usuario=id_usuario,
            papeis=self.repository.listar_perfis_ativos(id_usuario, hoje),
            permissoes=self.repository.listar_permissoes_ativas(id_usuario, hoje),
        )
