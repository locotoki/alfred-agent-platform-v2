from fastapi import FastAPI, HTTPException, Depends
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import Column, Integer, String, Text, JSON, DateTime, select, func
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import text
import os
from datetime import datetime
from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field
import logging

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database configuration
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql+asyncpg://postgres:postgres@db-postgres:5432/postgres")
engine = create_async_engine(DATABASE_URL)
async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)

# Base class for SQLAlchemy models
Base = declarative_base()

# Model class for database table
class ModelRegistry(Base):
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
    parameters: Optional[Dict[str, Any]] = Field(default_factory=dict)
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

@app.get("/health")
async def health_check():
    """
    Health check endpoint
    """
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.get("/models", response_model=List[ModelSchema])
async def get_models(db: AsyncSession = Depends(get_db)):
    """
    Get all registered models
    """
    result = await db.execute(select(ModelRegistry))
    models = result.scalars().all()
    return models

@app.get("/models/{model_id}", response_model=ModelSchema)
async def get_model(model_id: int, db: AsyncSession = Depends(get_db)):
    """
    Get model by ID
    """
    result = await db.execute(select(ModelRegistry).where(ModelRegistry.id == model_id))
    model = result.scalar_one_or_none()
    if not model:
        raise HTTPException(status_code=404, detail=f"Model with ID {model_id} not found")
    return model

@app.post("/models", response_model=ModelSchema)
async def create_model(model: ModelSchema, db: AsyncSession = Depends(get_db)):
    """
    Create a new model
    """
    db_model = ModelRegistry(
        name=model.name,
        display_name=model.display_name,
        provider=model.provider,
        model_type=model.model_type,
        endpoint=model.endpoint,
        description=model.description,
        parameters=model.parameters
    )
    db.add(db_model)
    await db.commit()
    await db.refresh(db_model)
    return db_model

# Application lifespan event
@app.on_event("startup")
async def startup_event():
    logger.info("Model Registry service starting up")