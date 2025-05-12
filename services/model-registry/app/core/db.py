"""
Database configuration and models for the Model Registry service.
"""
from sqlalchemy import create_engine, MetaData
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import structlog

from app.core.config import settings

# Configure logging
logger = structlog.get_logger(__name__)

# Create metadata schema
metadata = MetaData(schema="model_registry")

# Create declarative base
Base = declarative_base(metadata=metadata)

# Convert PostgreSQL URL from sync to async format
# Example: postgresql://user:pass@host/db -> postgresql+asyncpg://user:pass@host/db
def get_async_db_url(db_url: str) -> str:
    """Convert a PostgreSQL URL to AsyncPG format."""
    if db_url.startswith("postgresql://"):
        return db_url.replace("postgresql://", "postgresql+asyncpg://")
    return db_url

# Create async engine
async_engine = create_async_engine(
    get_async_db_url(settings.DATABASE_URL),
    echo=settings.DEBUG,
    future=True
)

# Create async session maker
AsyncSessionLocal = sessionmaker(
    async_engine,
    class_=AsyncSession,
    expire_on_commit=False
)

# Dependency for getting database session
async def get_db():
    """
    Dependency that provides a database session.
    Usage: 
        @app.get("/items")
        async def get_items(db: AsyncSession = Depends(get_db)):
            ...
    """
    async with AsyncSessionLocal() as session:
        try:
            yield session
        finally:
            await session.close()

async def init_db():
    """
    Initialize the database by creating tables and initial data.
    """
    try:
        logger.info("Initializing database for model registry")
        
        # Create schema if it doesn't exist
        # This needs to be done with a raw SQL query
        # as SQLAlchemy doesn't support CREATE SCHEMA
        sync_engine = create_engine(settings.DATABASE_URL)
        with sync_engine.connect() as conn:
            conn.execute("CREATE SCHEMA IF NOT EXISTS model_registry")
            conn.commit()
        
        # Create tables
        async with async_engine.begin() as conn:
            # Create all tables
            await conn.run_sync(Base.metadata.create_all)
        
        logger.info("Database initialization complete")
    except Exception as e:
        logger.error("Database initialization failed", error=str(e))
        raise