from collections.abc import Generator

from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session, sessionmaker

from .config import settings

engine = create_engine(settings.database_url, future=True, pool_pre_ping=True)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def database_health() -> dict[str, str]:
    with engine.connect() as conn:
        conn.execute(text("SELECT 1"))
        postgis_version = conn.execute(text("SELECT PostGIS_Version()" )).scalar_one()
    return {"database": "ok", "postgis": str(postgis_version)}
