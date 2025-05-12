"""
Client module initialization for social-intel service.
Provides centralized access to platform integration clients.
"""

import os
import asyncio
import structlog
from typing import Dict, Any

logger = structlog.get_logger(__name__)

# Import clients
from .supabase_client import supabase_client, SupabaseClient
from .rag_client import rag_client, RagClient
from .auth_middleware import AuthMiddleware, get_api_key, validate_jwt, validate_api_key

# Configuration flags
USE_PLATFORM_SERVICES = os.getenv("USE_PLATFORM_SERVICES", "true").lower() in ("true", "1", "yes")
MIGRATION_MODE = os.getenv("MIGRATION_MODE", "hybrid")  # Options: legacy, hybrid, platform

# Service version
SERVICE_VERSION = os.getenv("SERVICE_VERSION", "1.1.0")


async def initialize_clients():
    """Initialize all clients and verify connections"""
    logger.info(f"Initializing social-intel clients (version {SERVICE_VERSION}, mode: {MIGRATION_MODE})")
    
    # Check Supabase connection
    supabase_status = await supabase_client.check_connection()
    logger.info(f"Supabase connection: {'✅ Connected' if supabase_status else '⚠️ Using file fallback'}")
    
    # Check RAG Gateway connection
    rag_gateway_status = await rag_client.check_gateway_connection()
    logger.info(f"RAG Gateway connection: {'✅ Connected' if rag_gateway_status else '⚠️ Not available'}")
    
    # Check direct Qdrant connection
    qdrant_status = await rag_client.check_qdrant_connection()
    logger.info(f"Direct Qdrant connection: {'✅ Connected' if qdrant_status else '⚠️ Not available'}")
    
    # Log overall status
    if MIGRATION_MODE == "legacy":
        logger.info("Running in legacy mode (using original implementations)")
    elif MIGRATION_MODE == "hybrid":
        logger.info("Running in hybrid mode (trying platform services with fallback)")
    elif MIGRATION_MODE == "platform":
        logger.info("Running in platform mode (using platform services only)")
        
        # Verify required platform services
        if not supabase_status:
            logger.error("Platform mode requires Supabase connection")
        if not rag_gateway_status:
            logger.error("Platform mode requires RAG Gateway connection")
    
    logger.info("Client initialization complete")


# Make clients available at the module level
__all__ = [
    "supabase_client", 
    "rag_client", 
    "AuthMiddleware", 
    "get_api_key", 
    "validate_jwt", 
    "validate_api_key",
    "initialize_clients",
    "MIGRATION_MODE",
    "SERVICE_VERSION"
]