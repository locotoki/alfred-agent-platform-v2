#!/usr/bin/env python3
"""
Integration tests for the CrewAI production client.
"""

import os
import json
import pytest
import requests
from unittest.mock import patch, MagicMock

# Import the client to test
from alfred_agent.crewai.client import send_task, validate_token

# Sample test data
TEST_PAYLOAD = {
    "task_type": "remediation",
    "service_name": "model-router",
    "error_details": {
        "error_message": "Connection refused",
        "probe_status_code": 500,
        "retry_count": 3
    },
    "priority": "high"
}

@pytest.fixture
def mock_token_file(tmp_path):
    """Create a mock JWT token file for testing."""
    token_file = tmp_path / "mock_token"
    token_file.write_text("mock.jwt.token")
    return str(token_file)

@pytest.fixture
def mock_environment(mock_token_file, monkeypatch):
    """Set up a mock environment for testing."""
    monkeypatch.setenv("CREWAI_ENDPOINT", "https://crewai.test.internal")
    monkeypatch.setenv("CREWAI_A2A_JWT", mock_token_file)
    return mock_token_file

def test_validate_token(mock_token_file):
    """Test that the token validation function works correctly."""
    # Valid token
    assert validate_token(mock_token_file) is True
    
    # Invalid token path
    assert validate_token("/nonexistent/path") is False
    
    # Empty token
    empty_token_file = mock_token_file + ".empty"
    with open(empty_token_file, "w") as f:
        f.write("")
    assert validate_token(empty_token_file) is False

@patch("alfred_agent.crewai.client.requests.post")
def test_send_task(mock_post, mock_environment):
    """Test that send_task correctly sends requests to the CrewAI service."""
    # Set up the mock
    mock_response = MagicMock()
    mock_response.json.return_value = {
        "status": "accepted",
        "task_id": "test-123",
        "message": "Task accepted"
    }
    mock_post.return_value = mock_response
    
    # Call the function
    result = send_task(TEST_PAYLOAD)
    
    # Verify the function made the correct API call
    mock_post.assert_called_once_with(
        "https://crewai.test.internal",
        json=TEST_PAYLOAD,
        headers={
            "Authorization": "Bearer mock.jwt.token",
            "Content-Type": "application/json",
            "Accept": "application/json",
        },
        timeout=10
    )
    
    # Verify the result
    assert result["status"] == "accepted"
    assert result["task_id"] == "test-123"
    assert result["message"] == "Task accepted"

@patch("alfred_agent.crewai.client.requests.post")
def test_send_task_error_handling(mock_post, mock_environment):
    """Test that send_task correctly handles errors."""
    # Set up the mock to raise an exception
    mock_post.side_effect = requests.RequestException("Connection error")
    
    # Verify the function raises the exception
    with pytest.raises(requests.RequestException):
        send_task(TEST_PAYLOAD)

@pytest.mark.skip(reason="This test requires actual CrewAI service. For CI, use the mocked version above.")
def test_crewai_roundtrip():
    """
    End-to-end test that actually communicates with the CrewAI service.
    This test is skipped by default and only used in controlled environments.
    """
    # Check if we have a token and endpoint
    token_path = os.getenv("CREWAI_A2A_JWT")
    endpoint = os.getenv("CREWAI_ENDPOINT")
    
    if not token_path or not endpoint or not os.path.exists(token_path):
        pytest.skip("CrewAI configuration not available")
    
    # Send a simple test task
    result = send_task({
        "task_type": "test",
        "service_name": "integration-test",
        "priority": "low"
    })
    
    # Just verify we got a response
    assert "status" in result
    assert "task_id" in result