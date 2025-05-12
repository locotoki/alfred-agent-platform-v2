"""Integration tests for API endpoints."""

import pytest
import uuid
import json
from unittest.mock import patch, MagicMock, AsyncMock
from fastapi.testclient import TestClient
from fastapi import FastAPI

# Import necessary modules
from app.main import app, legal_compliance_agent
from app.clients import rag_client, supabase_client
from app.clients.rag_client import RagClient
from app.clients.supabase_client import SupabaseClient

pytestmark = pytest.mark.asyncio

# Create test client
test_client = TestClient(app)

# Mock environment for tests
@pytest.fixture(autouse=True)
def mock_env_and_dependencies():
    """Mock environment and dependencies for tests."""
    with patch("app.clients.MIGRATION_MODE", "hybrid"):
        with patch.object(SupabaseClient, "check_connection") as mock_supabase:
            with patch.object(RagClient, "check_connection") as mock_rag:
                with patch.object(SupabaseClient, "store_task") as mock_store_task:
                    with patch.object(RagClient, "get_legal_context") as mock_get_legal_context:
                        with patch.object(SupabaseClient, "get_task_status") as mock_get_task_status:
                            with patch("app.main.supabase_transport.store_task") as mock_legacy_store:
                                with patch("app.main.pubsub_transport.publish_task") as mock_publish:
                                    with patch("app.main.legal_compliance_agent.add_context") as mock_add_context:
                                        # Set default return values
                                        mock_supabase.return_value = True
                                        mock_rag.return_value = True
                                        mock_store_task.return_value = str(uuid.uuid4())
                                        mock_get_legal_context.return_value = [{"text": "Test context"}]
                                        mock_legacy_store.return_value = str(uuid.uuid4())
                                        mock_publish.return_value = "message-id"
                                        mock_add_context.return_value = None
                                        
                                        # Setup task status mock
                                        async def get_task_status_mock(task_id):
                                            return {
                                                "task_id": task_id,
                                                "status": "processing",
                                                "intent": "TEST_INTENT",
                                                "timestamp": "2023-01-01T12:00:00Z"
                                            }
                                        mock_get_task_status.side_effect = get_task_status_mock
                                        
                                        yield

# Create test API token header
@pytest.fixture
def api_key_header():
    """Create API key header for authentication."""
    return {"X-API-Key": "test-api-key"}

class TestApiEndpoints:
    """Test cases for API endpoints."""
    
    def test_audit_compliance_endpoint(self, api_key_header, mock_env_and_dependencies):
        """Test compliance audit endpoint."""
        # Test request data
        test_data = {
            "company_name": "Test Company",
            "compliance_categories": ["GDPR", "HIPAA"],
            "documents": ["document1", "document2"],
            "jurisdictions": ["EU", "US"]
        }
        
        # Make API request
        response = test_client.post(
            "/api/v1/legal-compliance/audit-compliance",
            json=test_data,
            headers=api_key_header
        )
        
        # Check response
        assert response.status_code == 200
        response_data = response.json()
        assert response_data["status"] == "accepted"
        assert "task_id" in response_data
        assert "message_id" in response_data["tracking"]
        
        # Verify platform services were used
        supabase_client.store_task.assert_called_once()
        rag_client.get_legal_context.assert_called_once()
    
    def test_analyze_document_endpoint(self, api_key_header, mock_env_and_dependencies):
        """Test document analysis endpoint."""
        # Test request data
        test_data = {
            "document_type": "CONTRACT",
            "document_content": "This is a test contract...",
            "jurisdiction": "US"
        }
        
        # Make API request
        response = test_client.post(
            "/api/v1/legal-compliance/analyze-document",
            json=test_data,
            headers=api_key_header
        )
        
        # Check response
        assert response.status_code == 200
        response_data = response.json()
        assert response_data["status"] == "accepted"
        
        # Verify platform services were used
        supabase_client.store_task.assert_called_once()
        rag_client.get_legal_context.assert_called_once()
    
    def test_check_regulations_endpoint(self, api_key_header, mock_env_and_dependencies):
        """Test regulation check endpoint."""
        # Test request data
        test_data = {
            "business_activity": "Processing customer data",
            "regulations": ["GDPR", "CCPA"],
            "jurisdiction": "EU",
            "industry": "technology"
        }
        
        # Configure mock to return results for multiple regulations
        rag_client.get_regulation_context.return_value = [{"text": "GDPR regulation"}]
        
        # Make API request
        response = test_client.post(
            "/api/v1/legal-compliance/check-regulations",
            json=test_data,
            headers=api_key_header
        )
        
        # Check response
        assert response.status_code == 200
        response_data = response.json()
        assert response_data["status"] == "accepted"
    
    def test_review_contract_endpoint(self, api_key_header, mock_env_and_dependencies):
        """Test contract review endpoint."""
        # Test request data
        test_data = {
            "contract_type": "EMPLOYMENT",
            "contract_content": "This is an employment contract...",
            "jurisdiction": "US",
            "parties": ["Company A", "Employee B"]
        }
        
        # Configure mock
        rag_client.get_contract_context.return_value = [{"text": "Employment contract template"}]
        
        # Make API request
        response = test_client.post(
            "/api/v1/legal-compliance/review-contract",
            json=test_data,
            headers=api_key_header
        )
        
        # Check response
        assert response.status_code == 200
        response_data = response.json()
        assert response_data["status"] == "accepted"
        
        # Verify contract context was retrieved
        rag_client.get_contract_context.assert_called_once()
    
    def test_get_task_status_endpoint(self, api_key_header, mock_env_and_dependencies):
        """Test task status endpoint."""
        # Make API request
        response = test_client.get(
            "/api/v1/legal-compliance/task/test-task-id",
            headers=api_key_header
        )
        
        # Check response
        assert response.status_code == 200
        response_data = response.json()
        assert response_data["task_id"] == "test-task-id"
        assert response_data["status"] == "processing"
        
        # Verify platform service was used
        supabase_client.get_task_status.assert_called_once_with("test-task-id")
    
    def test_task_not_found(self, api_key_header, mock_env_and_dependencies):
        """Test task status endpoint with task not found."""
        # Configure mock to return None (task not found)
        supabase_client.get_task_status.return_value = None
        
        # Make API request
        response = test_client.get(
            "/api/v1/legal-compliance/task/nonexistent-task",
            headers=api_key_header
        )
        
        # Check response
        assert response.status_code == 404
        assert "not found" in response.json()["error"]
    
    def test_unauthorized_access(self):
        """Test endpoint with no authentication."""
        # Make API request without auth header
        response = test_client.post(
            "/api/v1/legal-compliance/audit-compliance",
            json={"company_name": "Test"}
        )
        
        # Check response
        assert response.status_code == 401
    
    def test_platform_only_mode(self, api_key_header, mock_env_and_dependencies):
        """Test behavior in platform-only mode."""
        # Set mode to platform-only
        with patch("app.clients.MIGRATION_MODE", "platform"):
            # Make API request
            response = test_client.post(
                "/api/v1/legal-compliance/audit-compliance",
                json={"company_name": "Test Company"},
                headers=api_key_header
            )
            
            # Check response
            assert response.status_code == 200
            
            # Verify only platform services were used, not legacy
            supabase_client.store_task.assert_called_once()
            rag_client.get_legal_context.assert_called_once()
            
            # Legacy service should not be called
            from app.main import supabase_transport
            supabase_transport.store_task.assert_not_called()
    
    def test_legacy_mode(self, api_key_header, mock_env_and_dependencies):
        """Test behavior in legacy-only mode."""
        # Set mode to legacy-only
        with patch("app.clients.MIGRATION_MODE", "legacy"):
            # Make API request
            response = test_client.post(
                "/api/v1/legal-compliance/audit-compliance",
                json={"company_name": "Test Company"},
                headers=api_key_header
            )
            
            # Check response
            assert response.status_code == 200
            
            # Verify only legacy services were used, not platform
            from app.main import supabase_transport
            supabase_transport.store_task.assert_called_once()
            
            # Platform services should not be called
            supabase_client.store_task.assert_not_called()
            rag_client.get_legal_context.assert_not_called()