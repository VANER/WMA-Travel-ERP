"""Base declarativa dos mapeamentos SQLAlchemy."""

from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    """Base para models mapeados gradualmente sobre a baseline."""
