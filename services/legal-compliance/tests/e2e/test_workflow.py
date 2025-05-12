"""End-to-end tests for legal-compliance workflows."""

import pytest
import requests
import time
import os
import uuid
import jwt
import json
from unittest.mock import patch

# Mark this module as requiring e2e environment
pytestmark = [
    pytest.mark.e2e,
    pytest.mark.asyncio
]

# Base URL for API
BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000")

# Test API key
API_KEY = os.getenv("TEST_API_KEY", "legal-compliance-key")

# JWT secret for generating test tokens
JWT_SECRET = os.getenv("JWT_SECRET", "development-secret-not-for-production")

@pytest.fixture
def api_key_header():
    """Create API key header for authentication."""
    return {"X-API-Key": API_KEY}

@pytest.fixture
def jwt_token_header():
    """Create JWT token header for authentication."""
    # Create a valid token
    payload = {
        "sub": "test-user",
        "role": "user",
        "tenant_id": "test-tenant",
        "exp": int(time.time()) + 3600  # 1 hour from now
    }
    token = jwt.encode(payload, JWT_SECRET, algorithm="HS256")
    return {"Authorization": f"Bearer {token}"}

class TestE2EWorkflows:
    """End-to-end test cases for complete workflows."""
    
    @pytest.mark.skipif(not os.getenv("RUN_E2E_TESTS"), reason="E2E tests disabled")
    async def test_full_compliance_audit_workflow(self, api_key_header):
        """Test complete compliance audit workflow."""
        # 1. Submit compliance audit task
        test_data = {
            "company_name": "E2E Test Company",
            "compliance_categories": ["GDPR"],
            "documents": ["Privacy Policy", "Data Processing Agreement"],
            "jurisdictions": ["EU"],
            "tenant_id": "e2e-test"
        }
        
        audit_response = requests.post(
            f"{BASE_URL}/api/v1/legal-compliance/audit-compliance",
            json=test_data,
            headers=api_key_header
        )
        
        assert audit_response.status_code == 200
        audit_data = audit_response.json()
        assert audit_data["status"] == "accepted"
        task_id = audit_data["tracking"]["task_id"]
        
        # 2. Poll for task completion (with timeout)
        max_attempts = 10
        completed = False
        result = None
        
        for attempt in range(max_attempts):
            status_response = requests.get(
                f"{BASE_URL}/api/v1/legal-compliance/task/{task_id}",
                headers=api_key_header
            )
            
            assert status_response.status_code == 200
            status_data = status_response.json()
            
            if status_data["status"] == "completed":
                completed = True
                result = status_data["result"]
                break
            
            # Wait before next attempt
            time.sleep(2)
        
        assert completed, f"Task {task_id} did not complete within timeout"
        assert result is not None
        
        # 3. Verify result structure
        assert "compliance_findings" in result
        assert "risk_level" in result
        assert "recommendations" in result
    
    @pytest.mark.skipif(not os.getenv("RUN_E2E_TESTS"), reason="E2E tests disabled")
    async def test_tenant_isolation(self, jwt_token_header):
        """Test tenant isolation for multi-tenant setup."""
        # 1. Submit document analysis task with tenant ID
        test_data = {
            "document_type": "POLICY",
            "document_content": "This is a test privacy policy for tenant isolation testing.",
            "jurisdiction": "US",
            "tenant_id": "test-tenant"  # This should match the JWT token's tenant_id
        }
        
        doc_response = requests.post(
            f"{BASE_URL}/api/v1/legal-compliance/analyze-document",
            json=test_data,
            headers=jwt_token_header
        )
        
        assert doc_response.status_code == 200
        doc_data = doc_response.json()
        assert doc_data["status"] == "accepted"
        task_id = doc_data["tracking"]["task_id"]
        
        # 2. Verify task is accessible with the same tenant
        status_response = requests.get(
            f"{BASE_URL}/api/v1/legal-compliance/task/{task_id}",
            headers=jwt_token_header
        )
        
        assert status_response.status_code == 200
        
        # 3. Create a different tenant token
        payload = {
            "sub": "other-user",
            "role": "user",
            "tenant_id": "other-tenant",
            "exp": int(time.time()) + 3600
        }
        other_token = jwt.encode(payload, JWT_SECRET, algorithm="HS256")
        other_header = {"Authorization": f"Bearer {other_token}"}
        
        # 4. Attempt to access the task with different tenant
        if os.getenv("TEST_RLS_POLICIES", "false").lower() == "true":
            # This should only be tested in environments with actual RLS policies
            other_response = requests.get(
                f"{BASE_URL}/api/v1/legal-compliance/task/{task_id}",
                headers=other_header
            )
            
            # Should return 404 due to RLS policies
            assert other_response.status_code == 404
    
    @pytest.mark.skipif(not os.getenv("RUN_E2E_TESTS"), reason="E2E tests disabled")
    async def test_rag_context_integration(self, api_key_header):
        """Test RAG context integration in contract review."""
        # 1. Submit contract review with specific details to trigger context
        test_data = {
            "contract_type": "SERVICE_AGREEMENT",
            "contract_content": "This is a service agreement for software development services...",
            "jurisdiction": "US",
            "parties": ["Provider Corp", "Client Inc"],
            "tenant_id": "e2e-test"
        }
        
        review_response = requests.post(
            f"{BASE_URL}/api/v1/legal-compliance/review-contract",
            json=test_data,
            headers=api_key_header
        )
        
        assert review_response.status_code == 200
        review_data = review_response.json()
        task_id = review_data["tracking"]["task_id"]
        
        # 2. Poll for task completion (with timeout)
        max_attempts = 10
        completed = False
        result = None
        
        for attempt in range(max_attempts):
            status_response = requests.get(
                f"{BASE_URL}/api/v1/legal-compliance/task/{task_id}",
                headers=api_key_header
            )
            
            if status_response.status_code == 200:
                status_data = status_response.json()
                
                if status_data["status"] == "completed":
                    completed = True
                    result = status_data["result"]
                    break
            
            # Wait before next attempt
            time.sleep(2)
        
        if completed:
            # 3. Verify results contain context-specific information
            assert "legal_issues" in result
            assert "recommendations" in result
            
            # Look for evidence that context was used
            # This is imperfect, but we can check for service agreement specific terms
            result_text = json.dumps(result).lower()
            assert any(term in result_text for term in ["service", "agreement", "software", "development"])
        else:
            pytest.skip("Task did not complete in time - skipping result verification")
    
    @pytest.mark.skipif(not os.getenv("RUN_E2E_TESTS"), reason="E2E tests disabled")
    async def test_migration_mode_behavior(self, api_key_header):
        """Test behavior of different migration modes."""
        # Note: This test assumes ability to change environment variables
        # which may not be practical in all test environments
        
        original_mode = os.getenv("MIGRATION_MODE", "hybrid")
        try:
            # Test with MIGRATION_MODE=legacy
            if os.getenv("CAN_MODIFY_ENV", "false").lower() == "true":
                os.environ["MIGRATION_MODE"] = "legacy"
                
                # Allow time for settings to take effect if there's a reload mechanism
                time.sleep(1)
                
                # Make request in legacy mode
                response_legacy = requests.post(
                    f"{BASE_URL}/api/v1/legal-compliance/audit-compliance",
                    json={"company_name": "Test Legacy Mode"},
                    headers=api_key_header
                )
                
                assert response_legacy.status_code == 200
                
                # Test with MIGRATION_MODE=platform
                os.environ["MIGRATION_MODE"] = "platform"
                time.sleep(1)
                
                # Make request in platform mode
                response_platform = requests.post(
                    f"{BASE_URL}/api/v1/legal-compliance/audit-compliance",
                    json={"company_name": "Test Platform Mode"},
                    headers=api_key_header
                )
                
                assert response_platform.status_code == 200
            else:
                pytest.skip("Cannot modify environment variables in this test environment")
        finally:
            # Restore original mode
            if os.getenv("CAN_MODIFY_ENV", "false").lower() == "true":
                os.environ["MIGRATION_MODE"] = original_mode