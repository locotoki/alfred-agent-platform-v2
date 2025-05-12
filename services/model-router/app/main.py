from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from prometheus_client import make_asgi_app
import logging
import time

from app.api.router import router as api_router
from app.core.config import settings
from app.services.registry_client import RegistryClient
from app.services.router_engine import RouterEngine
from app.utils.responses import register_exception_handlers

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

# Create metrics endpoint
metrics_app = make_asgi_app()

# Lifespan context manager for startup/shutdown events
@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Initialize connections and services
    logger.info("Starting up Model Router service")
    
    # Initialize registry client
    app.state.registry_client = RegistryClient(settings.MODEL_REGISTRY_URL)
    await app.state.registry_client.initialize()
    
    # Initialize router engine
    app.state.router_engine = RouterEngine(app.state.registry_client)
    await app.state.router_engine.initialize()
    
    logger.info("Model Router service started successfully")
    
    yield
    
    # Shutdown: Close connections and cleanup
    logger.info("Shutting down Model Router service")
    await app.state.registry_client.close()
    logger.info("Model Router service shutdown complete")

# Create FastAPI app
app = FastAPI(
    title="Alfred Model Router",
    description="Service for intelligently routing requests to the most appropriate AI model",
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

# Register exception handlers
register_exception_handlers(app)

# Health check endpoint
@app.get("/health", tags=["health"])
async def health_check():
    return {"status": "healthy"}

# Root endpoint
@app.get("/", tags=["root"])
async def root():
    return {
        "service": "Alfred Model Router",
        "version": "1.0.0",
        "endpoints": {
            "health": "/health",
            "metrics": "/metrics",
            "api": "/api/v1",
        }
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=settings.PORT, reload=settings.DEBUG)