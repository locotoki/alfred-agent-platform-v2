"""
Authentication middleware for social-intel service.
Supports both platform authentication and legacy API key authentication.
"""

import os
import time
import jwt
import structlog
from fastapi import Request, HTTPException, Security
from fastapi.security import APIKeyHeader
from starlette.middleware.base import BaseHTTPMiddleware
from typing import Dict, Any, List, Optional, Callable, Awaitable

logger = structlog.get_logger(__name__)

# Environment variables
AUTH_ENABLED = os.getenv("USE_AUTH", "true").lower() in ("true", "1", "yes")
JWT_SECRET = os.getenv("JWT_SECRET", "development-secret-not-for-production")
API_KEY = os.getenv("API_KEY", "default-social-intel-key")
PLATFORM_API_KEYS = os.getenv("PLATFORM_API_KEYS", f"social:{API_KEY}")

# Parse platform API keys into a dictionary
VALID_KEYS = {}
try:
    for key_pair in PLATFORM_API_KEYS.split(","):
        if ":" in key_pair:
            agent, key = key_pair.split(":")
            VALID_KEYS[key] = agent
except Exception as e:
    logger.error(f"Error parsing PLATFORM_API_KEYS: {str(e)}")
    VALID_KEYS = {API_KEY: "social"}

# API key header
api_key_header = APIKeyHeader(name="X-API-Key", auto_error=False)


def validate_api_key(api_key: str) -> bool:
    """Validate API key against configured keys"""
    if not AUTH_ENABLED:
        return True
    
    # Check if key is in valid keys
    return api_key in VALID_KEYS


def validate_jwt(token: str) -> Dict[str, Any]:
    """
    Validate JWT token and return its payload.
    
    Args:
        token: JWT token string
        
    Returns:
        Token payload as dictionary
        
    Raises:
        HTTPException: If token is invalid
    """
    if not AUTH_ENABLED:
        return {"sub": "anonymous", "role": "user"}
    
    try:
        # Handle "Bearer" prefix if present
        if token.startswith("Bearer "):
            token = token.split(" ")[1]
        
        # Decode and verify the token
        payload = jwt.decode(token, JWT_SECRET, algorithms=["HS256"])
        return payload
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired")
    except jwt.InvalidTokenError as e:
        raise HTTPException(status_code=401, detail=f"Invalid token: {str(e)}")


class AuthMiddleware(BaseHTTPMiddleware):
    """
    Middleware for authenticating requests with hybrid authentication strategy.
    Supports both API key and JWT authentication.
    """
    
    async def dispatch(self, request: Request, call_next: Callable[[Request], Awaitable[Any]]) -> Any:
        """Process the request through the middleware"""
        if not AUTH_ENABLED:
            # Skip authentication if disabled
            return await call_next(request)
        
        # Check for public paths that don't need authentication
        path = request.url.path
        if path in ["/health", "/metrics", "/docs", "/openapi.json", "/redoc"]:
            return await call_next(request)
        
        # Extract authorization header
        auth_header = request.headers.get("Authorization")
        api_key = request.headers.get("X-API-Key")
        
        # Try API key first
        if api_key and validate_api_key(api_key):
            # Add agent info to request state
            request.state.agent = VALID_KEYS.get(api_key, "unknown")
            return await call_next(request)
        
        # Then try JWT
        if auth_header:
            try:
                token = auth_header.replace("Bearer ", "")
                payload = validate_jwt(token)
                
                # Add user info to request state
                request.state.user = payload.get("sub")
                request.state.role = payload.get("role", "user")
                
                return await call_next(request)
            except HTTPException:
                # Fall through to legacy API key check
                pass
        
        # Legacy API key check (in query parameters)
        query_api_key = request.query_params.get("api_key")
        if query_api_key and (query_api_key == API_KEY or validate_api_key(query_api_key)):
            # Add agent info to request state
            request.state.agent = VALID_KEYS.get(query_api_key, "unknown")
            return await call_next(request)
        
        # If all auth methods fail, return 401
        return HTTPException(status_code=401, detail="Not authenticated")


async def get_api_key(
    api_key_header: str = Security(api_key_header)
) -> str:
    """
    FastAPI dependency for extracting and validating API key.
    
    Args:
        api_key_header: API key from the X-API-Key header
        
    Returns:
        Validated API key
        
    Raises:
        HTTPException: If API key is invalid
    """
    if not AUTH_ENABLED:
        return "disabled"
    
    if api_key_header is None:
        raise HTTPException(
            status_code=401,
            detail="Missing API key"
        )
    
    if not validate_api_key(api_key_header):
        raise HTTPException(
            status_code=401,
            detail="Invalid API key"
        )
    
    return api_key_header