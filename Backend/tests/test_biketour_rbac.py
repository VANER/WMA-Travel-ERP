"""Gates estaticos do RBAC Bike Tour."""

from pathlib import Path

from app.modules.seguranca.authorization import (
    exigir_bike_tour_gerenciar,
    exigir_bike_tour_operar,
    exigir_bike_tour_visualizar,
)
from app.modules.seguranca.rbac import ContextoRbac

MIGRATION = Path(__file__).parents[1] / "migrations" / "versions" / "202609170100_bike_tour_rbac.py"


def test_biketour_rbac_migration_is_linear_and_reversible() -> None:
    source = MIGRATION.read_text(encoding="utf-8")

    assert 'revision: str = "202609170100"' in source
    assert 'down_revision: str | None = "202609130700"' in source
    assert "def upgrade() -> None:" in source
    assert "def downgrade() -> None:" in source

    for permission in (
        "BIKE_TOUR_VISUALIZAR",
        "BIKE_TOUR_OPERAR",
        "BIKE_TOUR_GERENCIAR",
    ):
        assert permission in source

    assert "perfil.codigo = 'ADMIN'" in source
    assert "ON CONFLICT (codigo) DO NOTHING" in source
    assert "ON CONFLICT (id_perfil, id_permissao) DO NOTHING" in source


def test_biketour_visualizar_exige_permissao_explicita() -> None:
    contexto = ContextoRbac(
        id_usuario=7,
        papeis=("OPERADOR",),
        permissoes=frozenset({"BIKE_TOUR_VISUALIZAR"}),
    )

    assert callable(exigir_bike_tour_visualizar)
    assert "BIKE_TOUR_VISUALIZAR" in contexto.permissoes


def test_biketour_operar_nao_e_implicado_por_gerenciar() -> None:
    contexto = ContextoRbac(
        id_usuario=7,
        papeis=("GESTOR",),
        permissoes=frozenset({"BIKE_TOUR_GERENCIAR"}),
    )

    assert "BIKE_TOUR_GERENCIAR" in contexto.permissoes
    assert "BIKE_TOUR_OPERAR" not in contexto.permissoes
    assert callable(exigir_bike_tour_operar)
    assert callable(exigir_bike_tour_gerenciar)


def test_biketour_admin_recebe_tres_permissoes_explicitamente_na_migration() -> None:
    source = MIGRATION.read_text(encoding="utf-8")

    assert source.count("'BIKE_TOUR_VISUALIZAR'") >= 2
    assert source.count("'BIKE_TOUR_OPERAR'") >= 2
    assert source.count("'BIKE_TOUR_GERENCIAR'") >= 2
    assert "perfil.codigo = 'ADMIN'" in source
