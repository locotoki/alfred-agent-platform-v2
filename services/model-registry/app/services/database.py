"""
Database connection and session management for the Model Registry service.
"""
import logging
from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.orm import declarative_base

from app.core.config import settings

# Configure logging
logger = logging.getLogger(__name__)

# Create SQLAlchemy engine and session factory
engine = create_async_engine(settings.DATABASE_URL, echo=settings.DEBUG)
async_session_factory = async_sessionmaker(engine, expire_on_commit=False)

# Create base class for declarative models
Base = declarative_base()

async def init_db():
    """Initialize database by creating all tables."""
    try:
        async with engine.begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Error initializing database: {e}")
        raise

async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """Get database session as a dependency."""
    async with async_session_factory() as session:
        try:
            yield session
        finally:
            await session.close()