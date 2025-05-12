"""Unit tests for RAG Client."""

import pytest
import json
import asyncio
from unittest.mock import patch, MagicMock

from app.clients.rag_client import RagClient, USE_RAG_GATEWAY

pytestmark = pytest.mark.asyncio

class TestRagClient:
    """Test cases for the RAG client."""
    
    async def test_check_connection_success(self, mock_httpx_client, mock_env_vars):
        """Test successful connection check."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_httpx_client.get.return_value = mock_response
        mock_httpx_client.post.return_value = mock_response
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await RagClient.check_connection()
            
            assert result is True
            assert USE_RAG_GATEWAY is True
            
            # Verify HTTP requests
            assert mock_httpx_client.get.call_count == 2
            mock_httpx_client.get.assert_any_call(
                "http://test-rag:8501/healthz",
                headers={"X-API-Key": "test-key"}
            )
            mock_httpx_client.get.assert_any_call(
                "http://test-rag:8501/collections/test-collection",
                headers={"X-API-Key": "test-key"}
            )
    
    async def test_check_connection_failure(self, mock_httpx_client, mock_env_vars):
        """Test connection check failure."""
        mock_response = MagicMock()
        mock_response.status_code = 500
        mock_httpx_client.get.return_value = mock_response
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await RagClient.check_connection()
            
            assert result is False
            assert USE_RAG_GATEWAY is False
    
    async def test_check_connection_collection_creation(self, mock_httpx_client, mock_env_vars):
        """Test collection creation if not exists."""
        # First request succeeds (healthz)
        health_response = MagicMock()
        health_response.status_code = 200
        
        # Second request fails (collection check)
        collection_response = MagicMock()
        collection_response.status_code = 404
        
        # Third request succeeds (collection creation)
        creation_response = MagicMock()
        creation_response.status_code = 200
        
        mock_httpx_client.get.side_effect = [health_response, collection_response]
        mock_httpx_client.post.return_value = creation_response
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await RagClient.check_connection()
            
            assert result is True
            assert USE_RAG_GATEWAY is True
            
            # Verify collection creation request
            mock_httpx_client.post.assert_called_once_with(
                "http://test-rag:8501/collections/create",
                headers={
                    "Content-Type": "application/json",
                    "X-API-Key": "test-key"
                },
                json={
                    "name": "test-collection",
                    "description": "Legal and regulatory knowledge for the legal-compliance agent"
                }
            )
    
    async def test_get_legal_context_success(self, mock_httpx_client, mock_env_vars):
        """Test successful legal context retrieval."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "results": [
                {"text": "Legal document 1", "metadata": {"jurisdiction": "US"}},
                {"text": "Legal document 2", "metadata": {"jurisdiction": "EU"}}
            ]
        }
        mock_httpx_client.post.return_value = mock_response
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            # Call with all parameters
            result = await RagClient.get_legal_context(
                query="legal compliance",
                jurisdictions=["US", "EU"],
                document_types=["contract"],
                compliance_categories=["GDPR"]
            )
            
            assert len(result) == 2
            assert result[0]["text"] == "Legal document 1"
            
            # Verify request parameters
            mock_httpx_client.post.assert_called_with(
                "http://test-rag:8501/query",
                headers={
                    "Content-Type": "application/json",
                    "X-API-Key": "test-key"
                },
                json={
                    "query": "legal compliance",
                    "collection": "test-collection",
                    "top_k": 10,
                    "filter": {
                        "jurisdictions": {"$in": ["US", "EU"]},
                        "document_type": {"$in": ["contract"]},
                        "compliance_category": {"$in": ["GDPR"]}
                    }
                }
            )
    
    async def test_get_legal_context_single_values(self, mock_httpx_client, mock_env_vars):
        """Test legal context retrieval with single values."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"results": [{"text": "Legal document"}]}
        mock_httpx_client.post.return_value = mock_response
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            # Call with single values (not lists)
            result = await RagClient.get_legal_context(
                query="legal compliance",
                jurisdictions=["US"],
                document_types=["contract"],
                compliance_categories=["GDPR"]
            )
            
            assert len(result) == 1
            
            # Verify correct filter format for single values
            mock_httpx_client.post.assert_called_with(
                "http://test-rag:8501/query",
                headers={
                    "Content-Type": "application/json",
                    "X-API-Key": "test-key"
                },
                json={
                    "query": "legal compliance",
                    "collection": "test-collection",
                    "top_k": 10,
                    "filter": {
                        "jurisdictions": "US",
                        "document_type": "contract",
                        "compliance_category": "GDPR"
                    }
                }
            )
    
    async def test_get_legal_context_gateway_disabled(self, mock_httpx_client, mock_env_vars):
        """Test behavior when gateway is disabled."""
        # Set gateway to disabled
        global USE_RAG_GATEWAY
        USE_RAG_GATEWAY = False
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await RagClient.get_legal_context(query="test")
            
            # Should return empty list and not make HTTP request
            assert result == []
            mock_httpx_client.post.assert_not_called()
    
    async def test_get_regulation_context(self, mock_httpx_client, mock_env_vars):
        """Test regulation context retrieval."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "results": [{"text": "GDPR regulation", "metadata": {"regulation_name": "GDPR"}}]
        }
        mock_httpx_client.post.return_value = mock_response
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await RagClient.get_regulation_context(
                query="GDPR requirements",
                regulation_name="GDPR",
                jurisdiction="EU",
                industry="technology"
            )
            
            assert len(result) == 1
            assert result[0]["text"] == "GDPR regulation"
            
            # Verify filter parameters
            mock_httpx_client.post.assert_called_with(
                "http://test-rag:8501/query",
                headers={
                    "Content-Type": "application/json",
                    "X-API-Key": "test-key"
                },
                json={
                    "query": "GDPR requirements",
                    "collection": "test-collection",
                    "top_k": 10,
                    "filter": {
                        "regulation_name": "GDPR",
                        "jurisdiction": "EU",
                        "industry": "technology"
                    }
                }
            )
    
    async def test_get_contract_context(self, mock_httpx_client, mock_env_vars):
        """Test contract context retrieval."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {
            "results": [{"text": "Employment contract template", "metadata": {"contract_type": "employment"}}]
        }
        mock_httpx_client.post.return_value = mock_response
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await RagClient.get_contract_context(
                query="employment contract template",
                contract_type="employment",
                jurisdiction="US"
            )
            
            assert len(result) == 1
            assert result[0]["text"] == "Employment contract template"
            
            # Verify filter parameters
            mock_httpx_client.post.assert_called_with(
                "http://test-rag:8501/query",
                headers={
                    "Content-Type": "application/json",
                    "X-API-Key": "test-key"
                },
                json={
                    "query": "employment contract template",
                    "collection": "test-collection",
                    "top_k": 10,
                    "filter": {
                        "contract_type": "employment",
                        "jurisdiction": "US"
                    }
                }
            )
    
    async def test_store_documents(self, mock_httpx_client, mock_env_vars):
        """Test document storage functionality."""
        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_httpx_client.post.return_value = mock_response
        
        documents = [
            {"text": "Legal document 1", "metadata": {"jurisdiction": "US"}},
            {"text": "Legal document 2", "metadata": {"jurisdiction": "EU"}}
        ]
        
        with patch('httpx.AsyncClient', return_value=mock_httpx_client):
            result = await RagClient.store_documents(documents)
            
            assert result is True
            
            # Verify document storage request
            mock_httpx_client.post.assert_called_with(
                "http://test-rag:8501/ingest",
                headers={
                    "Content-Type": "application/json",
                    "X-API-Key": "test-key"
                },
                json={
                    "documents": documents,
                    "collection": "test-collection"
                }
            )