"""Recorte ORM ate Turismo; Bike Tour exige a baseline migrada em outro banco."""

from sqlalchemy import Table

from app.db.base import Base


def orm_test_tables() -> list[Table]:
    """Exclui o delta Bike Tour, cujas FKs apontam para autoridades legadas."""
    return [table for table in Base.metadata.sorted_tables if not table.name.endswith("_bike_tour")]
