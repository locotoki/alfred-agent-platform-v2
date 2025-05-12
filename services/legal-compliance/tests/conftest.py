"""Test configuration and fixtures for legal-compliance service."""

import os
import pytest
import asyncio
import httpx
import jwt
from unittest.mock import patch, MagicMock
import importlib
import sys

# Patch environment variables before importing modules
os.environ["RAG_URL"] = "http://test-rag:8501"
os.environ["RAG_API_KEY"] = "test-key"
os.environ["RAG_COLLECTION"] = "test-collection"
os.environ["USE_RAG_GATEWAY"] = "true"

os.environ["SUPABASE_URL"] = "http://test-supabase:3000"
os.environ["SUPABASE_SERVICE_ROLE_KEY"] = "test-service-key"
os.environ["USE_SUPABASE"] = "true"

os.environ["MIGRATION_MODE"] = "hybrid"
os.environ["USE_AUTH"] = "true"
os.environ["JWT_SECRET"] = "test-secret"
os.environ["API_KEY"] = "test-api-key"
os.environ["PLATFORM_API_KEYS"] = "legal:test-api-key,atlas:atlas-key"

# Force reload the client modules to pick up environment variables
if 'app.clients.rag_client' in sys.modules:
    importlib.reload(sys.modules['app.clients.rag_client'])
if 'app.clients.supabase_client' in sys.modules:
    importlib.reload(sys.modules['app.clients.supabase_client'])
if 'app.clients.auth_middleware' in sys.modules:
    importlib.reload(sys.modules['app.clients.auth_middleware'])
if 'app.clients' in sys.modules:
    importlib.reload(sys.modules['app.clients'])

# Now import the modules
from app.clients.auth_middleware import (
    AUTH_ENABLED,
    validate_api_key,
    validate_jwt,
    get_bearer_token,
    AuthMiddleware,
    get_current_user
)
from app.clients.rag_client import RagClient, USE_RAG_GATEWAY
from app.clients.supabase_client import SupabaseClient, USE_SUPABASE

@pytest.fixture(scope="session")
def event_loop():
    """Create and provide an event loop for tests."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture
def mock_httpx_client():
    """Mock for httpx.AsyncClient."""
    mock_client = MagicMock()
    mock_client.__aenter__ = MagicMock()
    mock_client.__aexit__ = MagicMock()
    mock_client.__aenter__.return_value = mock_client
    mock_response = MagicMock()
    mock_client.get = MagicMock(return_value=mock_response)
    mock_client.post = MagicMock(return_value=mock_response)
    mock_client.delete = MagicMock(return_value=mock_response)
    mock_response.status_code = 200
    mock_response.json = MagicMock(return_value={})
    return mock_client

@pytest.fixture(autouse=True)
def mock_env_vars():
    """Set up mock environment variables for tests."""
    # Set test environment variables (already done above)
    # Patch the imported variables directly to ensure they're picked up in tests
    with patch('app.clients.auth_middleware.AUTH_ENABLED', True):
        with patch('app.clients.auth_middleware.API_KEY', 'test-api-key'):
            with patch('app.clients.auth_middleware.JWT_SECRET', 'test-secret'):
                with patch('app.clients.auth_middleware.VALID_KEYS', {'test-api-key': 'legal'}):
                    with patch('app.clients.rag_client.USE_RAG_GATEWAY', True):
                        with patch('app.clients.supabase_client.USE_SUPABASE', True):
                            yield

@pytest.fixture
def mock_fastapi_request():
    """Mock for FastAPI Request object."""
    mock_request = MagicMock()
    mock_request.headers = {"Authorization": "Bearer test-token", "X-API-Key": "test-api-key"}
    mock_request.url = MagicMock()
    mock_request.url.path = "/api/v1/test"
    mock_request.state = MagicMock()
    mock_request.query_params = {}
    return mock_request