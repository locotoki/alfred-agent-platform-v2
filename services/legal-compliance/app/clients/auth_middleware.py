"""
Authentication middleware for legal-compliance service.
Provides enhanced authentication and authorization capabilities.
"""

import os
import jwt
import time
import structlog
from fastapi import Request, HTTPException, Security
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from starlette.middleware.base import BaseHTTPMiddleware
from typing import Dict, Any, Optional, List, Callable, Awaitable

logger = structlog.get_logger(__name__)

# Environment variables
AUTH_ENABLED = os.getenv("USE_AUTH", "true").lower() in ("true", "1", "yes")
JWT_SECRET = os.getenv("JWT_SECRET", "development-secret-not-for-production")
API_KEY = os.getenv("API_KEY", "legal-compliance-key")
PLATFORM_API_KEYS = os.getenv("PLATFORM_API_KEYS", f"legal:{API_KEY}")

# Parse platform API keys
VALID_KEYS = {}
try:
    for key_pair in PLATFORM_API_KEYS.split(","):
        if ":" in key_pair:
            agent, key = key_pair.split(":")
            VALID_KEYS[key] = agent
except Exception as e:
    logger.error(f"Error parsing PLATFORM_API_KEYS: {str(e)}")
    VALID_KEYS = {API_KEY: "legal"}

# Security scheme for legacy endpoints
security = HTTPBearer()


def validate_api_key(api_key: str) -> bool:
    """
    Validate API key against configured keys.
    
    Args:
        api_key: The API key to validate
        
    Returns:
        True if valid, False otherwise
    """
    if not AUTH_ENABLED:
        return True
    
    return api_key in VALID_KEYS or api_key == API_KEY


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


def get_bearer_token(authorization: str) -> Optional[str]:
    """Extract bearer token from authorization header."""
    if authorization and authorization.startswith("Bearer "):
        return authorization.replace("Bearer ", "")
    return None


class AuthMiddleware(BaseHTTPMiddleware):
    """
    Authentication middleware for legal-compliance service.
    Provides API key and JWT token validation.
    """
    
    async def dispatch(self, request: Request, call_next: Callable[[Request], Awaitable[Any]]) -> Any:
        """Process the request through middleware."""
        if not AUTH_ENABLED:
            return await call_next(request)
        
        # Skip authentication for public endpoints
        path = request.url.path
        if path in ["/health", "/health/", "/metrics", "/docs", "/openapi.json", "/redoc"]:
            return await call_next(request)
        
        # Get authentication headers
        authorization = request.headers.get("Authorization")
        api_key = request.headers.get("X-API-Key")
        
        # Check API key first
        if api_key and validate_api_key(api_key):
            # Add agent info to request state
            request.state.agent = VALID_KEYS.get(api_key, "unknown")
            return await call_next(request)
        
        # Then check JWT
        if authorization:
            try:
                token = get_bearer_token(authorization)
                if token:
                    # If it looks like a JWT, validate it
                    if "." in token and len(token.split(".")) == 3:
                        payload = validate_jwt(token)
                        
                        # Add user info to request state
                        request.state.user = payload.get("sub")
                        request.state.role = payload.get("role", "user")
                        request.state.tenant_id = payload.get("tenant_id", payload.get("sub"))
                        
                        return await call_next(request)
                    
                    # If it's not a JWT, treat it as an API key
                    elif validate_api_key(token):
                        request.state.agent = VALID_KEYS.get(token, "unknown")
                        return await call_next(request)
            except HTTPException:
                # Fall through to 401 response below
                pass
        
        # If API key is in query parameters, check that
        query_api_key = request.query_params.get("api_key")
        if query_api_key and validate_api_key(query_api_key):
            request.state.agent = VALID_KEYS.get(query_api_key, "unknown")
            return await call_next(request)
        
        # If all auth methods fail, return 401
        return HTTPException(status_code=401, detail="Not authenticated")


async def get_current_user(credentials: HTTPAuthorizationCredentials = Security(security)) -> Dict[str, Any]:
    """
    Dependency for validating current user.
    Compatible with existing endpoints.
    
    Args:
        credentials: The security credentials
        
    Returns:
        User information
        
    Raises:
        HTTPException: If user is not authenticated
    """
    if not AUTH_ENABLED:
        return {"sub": "anonymous", "role": "user"}
    
    try:
        token = credentials.credentials
        
        # First try as JWT
        try:
            return validate_jwt(token)
        except HTTPException:
            # Then try as API key
            if validate_api_key(token):
                return {"sub": VALID_KEYS.get(token, "unknown"), "role": "agent"}
            else:
                raise HTTPException(status_code=401, detail="Invalid token or API key")
    except Exception as e:
        raise HTTPException(status_code=401, detail=f"Authentication error: {str(e)}")