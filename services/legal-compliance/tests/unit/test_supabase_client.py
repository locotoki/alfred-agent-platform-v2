"""Unit tests for Supabase Client."""

import pytest
import json
import uuid
from unittest.mock import patch, MagicMock

from app.clients.supabase_client import SupabaseClient, USE_SUPABASE, LEGAL_IN_TABLE, LEGAL_OUT_TABLE

pytestmark = pytest.mark.asyncio

class TestSupabaseClient:
    """Test cases for the Supabase client."""
    
    async def test_check_connection_success(self, mock_httpx_client, mock_env_vars):
        """Test successful connection check."""
        # Mock first response (check tables)
        check_response = MagicMock()
        check_response.status_code = 200
        
        # Mock second response (test write)
        write_response = MagicMock()
        write_response.status_code = 201
        
        # Mock third response (delete test)
        delete_response = MagicMock()
        delete_response.status_code = 200
        
        mock_httpx_client.get.return_value = check_response
        mock_httpx_client.post.return_value = write_response
        mock_httpx_client.delete.return_value = delete_response
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await SupabaseClient.check_connection()
            
            assert result is True
            assert USE_SUPABASE is True
            
            # Verify HTTP requests
            assert mock_httpx_client.get.call_count == 1
            assert mock_httpx_client.post.call_count == 1
            assert mock_httpx_client.delete.call_count == 1
            
            # Check table request
            mock_httpx_client.get.assert_called_with(
                f"http://test-supabase:3000/rest/v1/{LEGAL_OUT_TABLE}",
                headers={
                    "apikey": "test-service-key",
                    "Authorization": "Bearer test-service-key",
                    "Content-Type": "application/json"
                },
                params={
                    "select": "id",
                    "limit": "1"
                }
            )
    
    async def test_check_connection_table_not_found(self, mock_httpx_client, mock_env_vars):
        """Test connection check when table doesn't exist."""
        mock_response = MagicMock()
        mock_response.status_code = 404
        mock_httpx_client.get.return_value = mock_response
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await SupabaseClient.check_connection()
            
            assert result is False
            assert USE_SUPABASE is False
    
    async def test_store_task_success(self, mock_httpx_client, mock_env_vars):
        """Test successful task storage."""
        mock_response = MagicMock()
        mock_response.status_code = 201
        mock_httpx_client.post.return_value = mock_response
        
        test_id = str(uuid.uuid4())
        envelope = {
            "task_id": test_id,
            "intent": "TEST_INTENT",
            "content": {"test": "data"}
        }
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await SupabaseClient.store_task(envelope)
            
            assert result == test_id
            
            # Verify post request
            mock_httpx_client.post.assert_called_with(
                f"http://test-supabase:3000/rest/v1/{LEGAL_IN_TABLE}",
                headers={
                    "apikey": "test-service-key",
                    "Authorization": "Bearer test-service-key",
                    "Content-Type": "application/json",
                    "Prefer": "return=minimal"
                },
                json={
                    "id": test_id,
                    "data": envelope,
                    "tenant_id": "default"  # Default tenant
                }
            )
    
    async def test_store_task_with_tenant(self, mock_httpx_client, mock_env_vars):
        """Test task storage with tenant ID."""
        mock_response = MagicMock()
        mock_response.status_code = 201
        mock_httpx_client.post.return_value = mock_response
        
        test_id = str(uuid.uuid4())
        envelope = {
            "task_id": test_id,
            "intent": "TEST_INTENT",
            "content": {"test": "data"},
            "tenant_id": "test-tenant"
        }
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await SupabaseClient.store_task(envelope)
            
            assert result == test_id
            
            # Verify tenant was included
            called_args = mock_httpx_client.post.call_args[1]
            assert called_args["json"]["tenant_id"] == "test-tenant"
    
    async def test_store_task_auto_id(self, mock_httpx_client, mock_env_vars):
        """Test task storage with automatic ID generation."""
        mock_response = MagicMock()
        mock_response.status_code = 201
        mock_httpx_client.post.return_value = mock_response
        
        envelope = {
            "intent": "TEST_INTENT",
            "content": {"test": "data"}
        }
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            with patch('uuid.uuid4', return_value=uuid.UUID('12345678-1234-5678-1234-567812345678')):
                result = await SupabaseClient.store_task(envelope)
                
                assert result == "12345678-1234-5678-1234-567812345678"
                assert "task_id" in envelope
                assert envelope["task_id"] == "12345678-1234-5678-1234-567812345678"
    
    async def test_store_task_supabase_disabled(self, mock_httpx_client, mock_env_vars):
        """Test behavior when Supabase is disabled."""
        # Set Supabase to disabled
        global USE_SUPABASE
        USE_SUPABASE = False
        
        envelope = {
            "task_id": "test-id",
            "intent": "TEST_INTENT",
            "content": {"test": "data"}
        }
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await SupabaseClient.store_task(envelope)
            
            # Should return task_id without making HTTP request
            assert result == "test-id"
            mock_httpx_client.post.assert_not_called()
    
    async def test_store_result_success(self, mock_httpx_client, mock_env_vars):
        """Test successful result storage."""
        mock_response = MagicMock()
        mock_response.status_code = 201
        mock_httpx_client.post.return_value = mock_response
        
        test_id = str(uuid.uuid4())
        result_data = {"status": "success", "output": "test output"}
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await SupabaseClient.store_result(test_id, result_data)
            
            assert result is True
            
            # Verify post request
            mock_httpx_client.post.assert_called_with(
                f"http://test-supabase:3000/rest/v1/{LEGAL_OUT_TABLE}",
                headers={
                    "apikey": "test-service-key",
                    "Authorization": "Bearer test-service-key",
                    "Content-Type": "application/json",
                    "Prefer": "return=minimal"
                },
                json={
                    "id": test_id,
                    "data": {
                        "task_id": test_id,
                        "result": result_data,
                        "status": "completed",
                        "timestamp": mock_httpx_client.post.call_args[1]["json"]["data"]["timestamp"]
                    },
                    "tenant_id": "default"
                }
            )
    
    async def test_get_task_status_completed(self, mock_httpx_client, mock_env_vars):
        """Test retrieving completed task status."""
        # Mock response for completed task
        completed_response = MagicMock()
        completed_response.status_code = 200
        completed_response.json.return_value = [{
            "id": "test-id",
            "data": {
                "result": {"output": "test output"},
                "timestamp": "2023-01-01T12:00:00Z"
            }
        }]
        
        mock_httpx_client.get.return_value = completed_response
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await SupabaseClient.get_task_status("test-id")
            
            assert result is not None
            assert result["status"] == "completed"
            assert result["task_id"] == "test-id"
            assert result["result"] == {"output": "test output"}
            assert result["timestamp"] == "2023-01-01T12:00:00Z"
            
            # Verify get request to legal_out table
            mock_httpx_client.get.assert_called_with(
                f"http://test-supabase:3000/rest/v1/{LEGAL_OUT_TABLE}",
                headers={
                    "apikey": "test-service-key",
                    "Authorization": "Bearer test-service-key",
                    "Content-Type": "application/json"
                },
                params={
                    "id": "eq.test-id",
                    "select": "*"
                }
            )
    
    async def test_get_task_status_processing(self, mock_httpx_client, mock_env_vars):
        """Test retrieving processing task status."""
        # Mock responses
        completed_response = MagicMock()
        completed_response.status_code = 200
        completed_response.json.return_value = []  # No completed task
        
        processing_response = MagicMock()
        processing_response.status_code = 200
        processing_response.json.return_value = [{
            "id": "test-id",
            "data": {
                "intent": "TEST_INTENT",
                "timestamp": "2023-01-01T12:00:00Z"
            }
        }]
        
        mock_httpx_client.get.side_effect = [completed_response, processing_response]
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await SupabaseClient.get_task_status("test-id")
            
            assert result is not None
            assert result["status"] == "processing"
            assert result["task_id"] == "test-id"
            assert result["intent"] == "TEST_INTENT"
            
            # Verify both tables were checked
            assert mock_httpx_client.get.call_count == 2
            mock_httpx_client.get.assert_any_call(
                f"http://test-supabase:3000/rest/v1/{LEGAL_OUT_TABLE}",
                headers={
                    "apikey": "test-service-key",
                    "Authorization": "Bearer test-service-key",
                    "Content-Type": "application/json"
                },
                params={
                    "id": "eq.test-id",
                    "select": "*"
                }
            )
            mock_httpx_client.get.assert_any_call(
                f"http://test-supabase:3000/rest/v1/{LEGAL_IN_TABLE}",
                headers={
                    "apikey": "test-service-key",
                    "Authorization": "Bearer test-service-key",
                    "Content-Type": "application/json"
                },
                params={
                    "id": "eq.test-id",
                    "select": "*"
                }
            )
    
    async def test_get_task_status_not_found(self, mock_httpx_client, mock_env_vars):
        """Test task status not found."""
        # Mock empty responses from both tables
        empty_response = MagicMock()
        empty_response.status_code = 200
        empty_response.json.return_value = []
        
        mock_httpx_client.get.return_value = empty_response
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await SupabaseClient.get_task_status("test-id")
            
            assert result is None
    
    async def test_list_tasks(self, mock_httpx_client, mock_env_vars):
        """Test listing tasks."""
        # Mock responses for completed and processing tasks
        completed_response = MagicMock()
        completed_response.status_code = 200
        completed_response.json.return_value = [{
            "id": "task1",
            "data": {
                "result": {"output": "result1"},
                "timestamp": "2023-01-02T12:00:00Z"
            },
            "tenant_id": "tenant1"
        }]
        
        processing_response = MagicMock()
        processing_response.status_code = 200
        processing_response.json.return_value = [{
            "id": "task2",
            "data": {
                "intent": "TEST_INTENT",
                "timestamp": "2023-01-01T12:00:00Z"
            },
            "tenant_id": "tenant1"
        }]
        
        mock_httpx_client.get.side_effect = [completed_response, processing_response]
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await SupabaseClient.list_tasks(limit=10, offset=0, tenant_id="tenant1")
            
            assert len(result) == 2
            # First task (newest by timestamp)
            assert result[0]["task_id"] == "task1"
            assert result[0]["status"] == "completed"
            assert result[0]["result"] == {"output": "result1"}
            assert result[0]["tenant_id"] == "tenant1"
            
            # Second task
            assert result[1]["task_id"] == "task2"
            assert result[1]["status"] == "processing"
            assert result[1]["intent"] == "TEST_INTENT"
            assert result[1]["tenant_id"] == "tenant1"
            
            # Verify tenant filter was used
            assert "tenant_id" in mock_httpx_client.get.call_args_list[0][1]["params"]
            assert mock_httpx_client.get.call_args_list[0][1]["params"]["tenant_id"] == "eq.tenant1"