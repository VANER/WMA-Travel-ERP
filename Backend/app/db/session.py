"""Engine e fábrica de sessões com ciclo de vida explícito."""

import logging
from collections.abc import Generator, Iterator
from contextlib import contextmanager

from sqlalchemy import Engine, create_engine, text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import Settings, get_settings

logger = logging.getLogger(__name__)


def create_db_engine(settings: Settings) -> Engine:
    """Cria o engine síncrono com pool explícito e conexões validadas."""
    return create_engine(
        settings.database_url,
        pool_pre_ping=True,
        pool_size=settings.database_pool_size,
        max_overflow=settings.database_max_overflow,
        pool_timeout=settings.database_pool_timeout,
        pool_recycle=settings.database_pool_recycle,
        connect_args={"connect_timeout": settings.database_connect_timeout},
    )


engine = create_db_engine(get_settings())
SessionFactory = sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)


def get_session() -> Generator[Session]:
    """Fornece uma sessão por unidade de trabalho HTTP."""
    with SessionFactory() as session:
        try:
            yield session
        except Exception:
            session.rollback()
            raise


@contextmanager
def transactional_session() -> Iterator[Session]:
    """Fornece o limite transacional explícito para services orquestradores."""
    with SessionFactory() as session:
        try:
            yield session
            session.commit()
        except Exception:
            session.rollback()
            raise


def database_is_available(db_engine: Engine = engine) -> bool:
    """Executa uma consulta mínima sem alterar dados ou schema."""
    try:
        with db_engine.connect() as connection:
            connection.execute(text("SELECT 1"))
    except SQLAlchemyError as exc:
        logger.warning("PostgreSQL indisponível", extra={"exception_type": type(exc).__name__})
        return False
    return True
