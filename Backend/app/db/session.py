"""Engine e fábrica de sessões com ciclo de vida explícito."""

from collections.abc import Generator

from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import get_settings

engine = create_engine(get_settings().database_url, pool_pre_ping=True)
SessionFactory = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def get_session() -> Generator[Session]:
    """Fornece uma sessão por unidade de trabalho HTTP."""
    with SessionFactory() as session:
        try:
            yield session
        except Exception:
            session.rollback()
            raise
