"""Base declarativa e convenções dos mapeamentos SQLAlchemy."""

from sqlalchemy import MetaData
from sqlalchemy.orm import DeclarativeBase

NAMING_CONVENTION = {
    "ix": "idx_%(table_name)s_%(column_0_N_name)s",
    "uq": "uq_%(table_name)s_%(column_0_N_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s",
}


def include_managed_object(
    _object: object,
    _name: str | None,
    object_type: str,
    reflected: bool,
    compare_to: object | None,
) -> bool:
    """Impede autogenerate de remover tabelas históricas ainda não mapeadas."""
    return not (object_type == "table" and reflected and compare_to is None)


class Base(DeclarativeBase):
    """Base para models mapeados gradualmente sobre a baseline."""

    metadata = MetaData(naming_convention=NAMING_CONVENTION)
