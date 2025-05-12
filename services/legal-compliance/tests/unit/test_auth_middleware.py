"""Unit tests for Auth Middleware."""

import pytest
import jwt
import time
from fastapi import HTTPException
from unittest.mock import patch, MagicMock, AsyncMock

from app.clients.auth_middleware import (
    AUTH_ENABLED,
    validate_api_key,
    validate_jwt,
    get_bearer_token,
    AuthMiddleware,
    get_current_user
)

pytestmark = pytest.mark.asyncio

class TestAuthMiddleware:
    """Test cases for Auth Middleware."""
    
    def test_validate_api_key_valid(self, mock_env_vars):
        """Test API key validation with valid key."""
        assert validate_api_key("test-api-key") is True
    
    def test_validate_api_key_invalid(self, mock_env_vars):
        """Test API key validation with invalid key."""
        assert validate_api_key("invalid-key") is False
    
    def test_validate_api_key_auth_disabled(self, mock_env_vars):
        """Test API key validation when auth is disabled."""
        global AUTH_ENABLED
        old_value = AUTH_ENABLED
        AUTH_ENABLED = False
        try:
            assert validate_api_key("any-key") is True
        finally:
            AUTH_ENABLED = old_value
    
    def test_validate_jwt_valid(self, mock_env_vars):
        """Test JWT validation with valid token."""
        # Create a valid token
        payload = {
            "sub": "test-user",
            "role": "user",
            "exp": int(time.time()) + 3600  # 1 hour from now
        }
        token = jwt.encode(payload, "test-secret", algorithm="HS256")
        
        result = validate_jwt(token)
        assert result["sub"] == "test-user"
        assert result["role"] == "user"
    
    def test_validate_jwt_with_bearer(self, mock_env_vars):
        """Test JWT validation with Bearer prefix."""
        payload = {
            "sub": "test-user",
            "role": "user",
            "exp": int(time.time()) + 3600
        }
        token = jwt.encode(payload, "test-secret", algorithm="HS256")
        bearer_token = f"Bearer {token}"
        
        result = validate_jwt(bearer_token)
        assert result["sub"] == "test-user"
    
    def test_validate_jwt_expired(self, mock_env_vars):
        """Test JWT validation with expired token."""
        payload = {
            "sub": "test-user",
            "exp": int(time.time()) - 3600  # 1 hour ago
        }
        token = jwt.encode(payload, "test-secret", algorithm="HS256")
        
        with pytest.raises(HTTPException) as exc_info:
            validate_jwt(token)
        
        assert exc_info.value.status_code == 401
        assert "expired" in exc_info.value.detail
    
    def test_validate_jwt_invalid(self, mock_env_vars):
        """Test JWT validation with invalid token."""
        with pytest.raises(HTTPException) as exc_info:
            validate_jwt("invalid-token")
        
        assert exc_info.value.status_code == 401
    
    def test_validate_jwt_auth_disabled(self, mock_env_vars):
        """Test JWT validation when auth is disabled."""
        global AUTH_ENABLED
        old_value = AUTH_ENABLED
        AUTH_ENABLED = False
        try:
            result = validate_jwt("any-token")
            assert result["sub"] == "anonymous"
            assert result["role"] == "user"
        finally:
            AUTH_ENABLED = old_value
    
    def test_get_bearer_token(self):
        """Test extracting bearer token."""
        assert get_bearer_token("Bearer token123") == "token123"
        assert get_bearer_token("token123") is None
        assert get_bearer_token(None) is None
    
    async def test_auth_middleware_skip_auth_endpoints(self, mock_fastapi_request, mock_env_vars):
        """Test auth middleware skips auth for certain endpoints."""
        mock_fastapi_request.url.path = "/health"
        
        middleware = AuthMiddleware(app=None)
        mock_call_next = AsyncMock()
        mock_call_next.return_value = "response"
        
        result = await middleware.dispatch(mock_fastapi_request, mock_call_next)
        
        assert result == "response"
        mock_call_next.assert_called_once_with(mock_fastapi_request)
    
    async def test_auth_middleware_api_key_header(self, mock_fastapi_request, mock_env_vars):
        """Test auth middleware with API key in header."""
        mock_fastapi_request.url.path = "/api/test"
        mock_fastapi_request.headers = {"X-API-Key": "test-api-key"}
        
        middleware = AuthMiddleware(app=None)
        mock_call_next = AsyncMock()
        mock_call_next.return_value = "response"
        
        result = await middleware.dispatch(mock_fastapi_request, mock_call_next)
        
        assert result == "response"
        assert mock_fastapi_request.state.agent == "legal"
    
    async def test_auth_middleware_jwt_token(self, mock_fastapi_request, mock_env_vars):
        """Test auth middleware with JWT token."""
        # Create a valid token
        payload = {
            "sub": "test-user",
            "role": "user",
            "exp": int(time.time()) + 3600
        }
        token = jwt.encode(payload, "test-secret", algorithm="HS256")
        
        mock_fastapi_request.url.path = "/api/test"
        mock_fastapi_request.headers = {"Authorization": f"Bearer {token}"}
        
        middleware = AuthMiddleware(app=None)
        mock_call_next = AsyncMock()
        mock_call_next.return_value = "response"
        
        result = await middleware.dispatch(mock_fastapi_request, mock_call_next)
        
        assert result == "response"
        assert mock_fastapi_request.state.user == "test-user"
        assert mock_fastapi_request.state.role == "user"
    
    async def test_auth_middleware_api_key_as_bearer(self, mock_fastapi_request, mock_env_vars):
        """Test auth middleware with API key in Bearer token."""
        mock_fastapi_request.url.path = "/api/test"
        mock_fastapi_request.headers = {"Authorization": "Bearer test-api-key"}
        
        middleware = AuthMiddleware(app=None)
        mock_call_next = AsyncMock()
        mock_call_next.return_value = "response"
        
        result = await middleware.dispatch(mock_fastapi_request, mock_call_next)
        
        assert result == "response"
        assert mock_fastapi_request.state.agent == "legal"
    
    async def test_auth_middleware_query_param(self, mock_fastapi_request, mock_env_vars):
        """Test auth middleware with API key in query param."""
        mock_fastapi_request.url.path = "/api/test"
        mock_fastapi_request.headers = {}
        mock_fastapi_request.query_params = {"api_key": "test-api-key"}
        
        middleware = AuthMiddleware(app=None)
        mock_call_next = AsyncMock()
        mock_call_next.return_value = "response"
        
        result = await middleware.dispatch(mock_fastapi_request, mock_call_next)
        
        assert result == "response"
        assert mock_fastapi_request.state.agent == "legal"
    
    async def test_auth_middleware_unauthorized(self, mock_fastapi_request, mock_env_vars):
        """Test auth middleware with no valid auth."""
        mock_fastapi_request.url.path = "/api/test"
        mock_fastapi_request.headers = {}
        mock_fastapi_request.query_params = {}
        
        middleware = AuthMiddleware(app=None)
        mock_call_next = AsyncMock()
        
        result = await middleware.dispatch(mock_fastapi_request, mock_call_next)
        
        assert isinstance(result, HTTPException)
        assert result.status_code == 401
        mock_call_next.assert_not_called()
    
    async def test_get_current_user_jwt(self, mock_env_vars):
        """Test get_current_user with JWT token."""
        # Create a valid token
        payload = {
            "sub": "test-user",
            "role": "admin",
            "exp": int(time.time()) + 3600
        }
        token = jwt.encode(payload, "test-secret", algorithm="HS256")
        
        # Mock credentials
        mock_credentials = MagicMock()
        mock_credentials.credentials = token
        
        result = await get_current_user(mock_credentials)
        
        assert result["sub"] == "test-user"
        assert result["role"] == "admin"
    
    async def test_get_current_user_api_key(self, mock_env_vars):
        """Test get_current_user with API key."""
        # Mock credentials
        mock_credentials = MagicMock()
        mock_credentials.credentials = "test-api-key"
        
        result = await get_current_user(mock_credentials)
        
        assert result["sub"] == "legal"
        assert result["role"] == "agent"
    
    async def test_get_current_user_invalid(self, mock_env_vars):
        """Test get_current_user with invalid credentials."""
        # Mock credentials
        mock_credentials = MagicMock()
        mock_credentials.credentials = "invalid-key"
        
        with pytest.raises(HTTPException) as exc_info:
            await get_current_user(mock_credentials)
        
        assert exc_info.value.status_code == 401