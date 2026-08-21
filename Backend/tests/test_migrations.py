"""Gates da configuração Alembic e das convenções de migrations."""

from pathlib import Path

from alembic.config import Config
from alembic.script import ScriptDirectory

from app.db.base import NAMING_CONVENTION, Base, include_managed_object

BACKEND_ROOT = Path(__file__).parents[1]


def test_metadata_uses_database_naming_convention() -> None:
    assert Base.metadata.naming_convention == NAMING_CONVENTION
    assert NAMING_CONVENTION == {
        "ix": "idx_%(table_name)s_%(column_0_N_name)s",
        "uq": "uq_%(table_name)s_%(column_0_N_name)s",
        "ck": "ck_%(table_name)s_%(constraint_name)s",
        "fk": "fk_%(table_name)s_%(referred_table_name)s",
        "pk": "pk_%(table_name)s",
    }


def test_alembic_tree_is_linear_and_has_no_placeholder_revision() -> None:
    config = Config(BACKEND_ROOT / "alembic.ini")
    script = ScriptDirectory.from_config(config)

    assert script.get_bases() == []
    assert script.get_heads() == []


def test_autogenerate_preserves_unmapped_baseline_tables() -> None:
    assert not include_managed_object(object(), "pessoa", "table", True, None)
    assert include_managed_object(object(), "novo_model", "table", False, None)
    assert include_managed_object(object(), "cliente", "table", True, object())
    assert include_managed_object(object(), "idx_cliente_nome", "index", True, None)


def test_revision_template_requires_upgrade_and_downgrade() -> None:
    template = (BACKEND_ROOT / "migrations" / "script.py.mako").read_text(
        encoding="utf-8"
    )

    assert "def upgrade() -> None:" in template
    assert "def downgrade() -> None:" in template
    assert "down_revision: str | Sequence[str] | None" in template
