"""
Main application module for the Model Registry service.
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app
import logging
import time

from app.api.router import api_router
from app.core.config import settings
from app.services.discovery import ModelDiscoveryService
from app.services.database import init_db, get_db

# Configure logging
logging.basicConfig(
    level=getattr(logging, settings.LOG_LEVEL),
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# Create metrics endpoint
metrics_app = make_asgi_app()

# Lifespan context manager for startup/shutdown events
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Initialize connections and services
    logger.info("Starting up Model Registry service")
    
    # Initialize database
    await init_db()
    
    # Initialize model discovery service
    app.state.discovery_service = ModelDiscoveryService()
    await app.state.discovery_service.initialize()
    await app.state.discovery_service.start_background_discovery()

    logger.info("Model Registry service started successfully")
    
    yield
    
    # Shutdown: Close connections and cleanup
    logger.info("Shutting down Model Registry service")
    await app.state.discovery_service.cleanup()
    logger.info("Model Registry service shutdown complete")

# Create FastAPI app
app = FastAPI(
    title="Alfred Model Registry",
    description="Service for managing AI model configurations and capabilities",
    version="1.0.0",
    lifespan=lifespan
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Mount metrics endpoint
app.mount("/metrics", metrics_app)

# Add request timing middleware
@app.middleware("http")
async def add_process_time_header(request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    response.headers["X-Process-Time"] = str(process_time)
    return response

# Include API router
app.include_router(api_router, prefix="/api/v1")

# Health check endpoint
@app.get("/health", tags=["health"])
async def health_check():
    return {"status": "healthy"}

# Root endpoint
@app.get("/", tags=["root"])
async def root():
    return {
        "service": "Alfred Model Registry",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "metrics": "/metrics",
            "api": "/api/v1",
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=settings.PORT, reload=settings.DEBUG)