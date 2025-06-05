import logging
import os
import threading
from datetime import datetime
from typing import Any, Dict, List, Optional

import prometheus_client
import uvicorn
from fastapi import Depends, FastAPI, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import JSON, Column, DateTime, Integer, String, Text, select
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.ext.declarative import declarative_base

# from sqlalchemy.orm import declarative_base as typed_declarative_base
from sqlalchemy.orm import sessionmaker

# Import Type annotations for SQLAlchemy
from sqlalchemy.orm.decl_api import DeclarativeMeta
from sqlalchemy.sql import text

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database configuration
DATABASE_URL = os.getenv(
    "DATABASE_URL", "postgresql+asyncpg://postgres:postgres@db-postgres:5432/postgres"
)
engine = create_async_engine(DATABASE_URL)
# Use type: ignore to bypass the type checking for sessionmaker parameters
# TODO: Issue #SC-300 - Fix sessionmaker type compatibility with AsyncEngine
async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)  # type: ignore

# Base class for SQLAlchemy models
Base: DeclarativeMeta = declarative_base()


# Model class for database table
class ModelRegistry(Base):  # type: ignore
    __tablename__ = "models"
    __table_args__ = {"schema": "model_registry"}

    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)
    display_name = Column(String(255))
    provider = Column(String(50), nullable=False)
    model_type = Column(String(50), nullable=False)
    endpoint = Column(String(255))
    description = Column(Text)
    parameters = Column(JSON, default={})
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


# Pydantic model for API request/response
class ModelSchema(BaseModel):
    id: Optional[int] = None
    name: str
    display_name: Optional[str] = None
    provider: str
    model_type: str
    endpoint: Optional[str] = None
    description: Optional[str] = None
    # Use a lambda to create a new dict for each instance
    # TODO: Issue #SC-300 - Update with proper callable type for default_factory
    parameters: Optional[Dict[str, Any]] = Field(default_factory=lambda: {})
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# Dependency to get database session
async def get_db():
    async with async_session() as session:
        try:
            yield session
        finally:
            await session.close()


# Create FastAPI application
app = FastAPI(title="Model Registry API")

# Create metrics app
metrics_app = FastAPI(title="Model Registry Metrics")


@app.get("/health")
async def health_check():
    """Detailed health check endpoint"""
    # Check database connectivity
    db_status = "ok"
    try:
        async with async_session() as session:
            await session.execute(text("SELECT 1"))
    except Exception as e:
        logger.error(f"Database health check failed: {e}")
        db_status = "error"

    return {
        "status": "ok" if db_status == "ok" else "error",
        "version": "1.0.0",
        "services": {"database": db_status},
    }


@app.get("/healthz")
async def simple_health():
    """Simple health check for container probes"""
    return {"status": "ok"}


@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint on the main service port"""
    from fastapi.responses import Response

    return Response(
        content=prometheus_client.generate_latest(), media_type="text/plain"
    )


@metrics_app.get("/metrics")
async def metrics_dedicated():
    """Prometheus metrics endpoint for the dedicated metrics port"""
    from fastapi.responses import Response

    return Response(
        content=prometheus_client.generate_latest(), media_type="text/plain"
    )


@app.get("/models", response_model=List[ModelSchema])
async def get_models(db: AsyncSession = Depends(get_db)):
    """Get all registered models"""
    result = await db.execute(select(ModelRegistry))
    models = result.scalars().all()
    return models


@app.get("/models/{model_id}", response_model=ModelSchema)
async def get_model(model_id: int, db: AsyncSession = Depends(get_db)):
    """Get model by ID"""
    result = await db.execute(select(ModelRegistry).where(ModelRegistry.id == model_id))
    model = result.scalar_one_or_none()
    if not model:
        raise HTTPException(
            status_code=404, detail=f"Model with ID {model_id} not found"
        )
    return model


@app.post("/models", response_model=ModelSchema)
async def create_model(model: ModelSchema, db: AsyncSession = Depends(get_db)):
    """Create a new model"""
    db_model = ModelRegistry(
        name=model.name,
        display_name=model.display_name,
        provider=model.provider,
        model_type=model.model_type,
        endpoint=model.endpoint,
        description=model.description,
        parameters=model.parameters,
    )
    db.add(db_model)
    await db.commit()
    await db.refresh(db_model)
    return db_model


# Start metrics server on separate port
@app.on_event("startup")
async def start_metrics_server():
    """Start metrics server on metrics port"""
    # Use environment variable or default to 9092 to avoid conflict with healthcheck port 9091
    metrics_port = int(os.getenv("METRICS_PORT", 9092))
    thread = threading.Thread(
        target=uvicorn.run,
        args=(metrics_app,),
        kwargs={"host": "0.0.0.0", "port": metrics_port, "log_level": "error"},
        daemon=True,
    )
    thread.start()
    logger.info(f"Metrics server started on port {metrics_port}")


# Application lifespan event
@app.on_event("startup")
async def startup_event():
    logger.info("Model Registry service starting up")


def create_registry_app() -> FastAPI:
    """Create and configure the model registry app.

    Returns:
        Configured FastAPI application.
    """
    return app
