"""
Example resilient HTTP client implementation using the resilience utilities.
"""
import logging
import aiohttp
import asyncio
from typing import Dict, Any, Optional, List, Union
import json

from .resilience import with_retry, CircuitBreaker

logger = logging.getLogger(__name__)

class ResilientClient:
    """A HTTP client with built-in resilience patterns."""
    
    def __init__(
        self,
        base_url: str,
        timeout: float = 10.0,
        max_retries: int = 3,
        circuit_failure_threshold: int = 5,
    ):
        """Initialize the resilient client.
        
        Args:
            base_url: Base URL for the service
            timeout: Request timeout in seconds
            max_retries: Maximum number of retries for failed requests
            circuit_failure_threshold: Number of failures before circuit opens
        """
        self.base_url = base_url.rstrip('/')
        self.timeout = timeout
        self.max_retries = max_retries
        self.circuit_breaker = CircuitBreaker(failure_threshold=circuit_failure_threshold)
        self._session = None
    
    async def ensure_session(self) -> None:
        """Ensure that an HTTP session exists."""
        if self._session is None or self._session.closed:
            self._session = aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=self.timeout),
                headers={"Content-Type": "application/json"}
            )
    
    async def close(self) -> None:
        """Close the HTTP session."""
        if self._session and not self._session.closed:
            await self._session.close()
            self._session = None
    
    @with_retry(retryable_exceptions=(aiohttp.ClientError, asyncio.TimeoutError))
    async def get(
        self, 
        path: str, 
        params: Optional[Dict[str, Any]] = None,
        headers: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """Make a GET request to the service.
        
        Args:
            path: URL path
            params: Query parameters
            headers: Additional headers
            
        Returns:
            Response as a dictionary
        """
        await self.ensure_session()
        url = f"{self.base_url}/{path.lstrip('/')}"
        
        async with self._session.get(url, params=params, headers=headers) as response:
            response.raise_for_status()
            return await response.json()
    
    @with_retry(retryable_exceptions=(aiohttp.ClientError, asyncio.TimeoutError))
    async def post(
        self, 
        path: str, 
        json_data: Dict[str, Any],
        headers: Optional[Dict[str, str]] = None
    ) -> Dict[str, Any]:
        """Make a POST request to the service.
        
        Args:
            path: URL path
            json_data: JSON data to send
            headers: Additional headers
            
        Returns:
            Response as a dictionary
        """
        await self.ensure_session()
        url = f"{self.base_url}/{path.lstrip('/')}"
        
        async with self._session.post(url, json=json_data, headers=headers) as response:
            response.raise_for_status()
            return await response.json()

# Example implementations for specific services

class ModelRouterClient(ResilientClient):
    """Client for interacting with the Model Router service."""
    
    async def get_completion(
        self, 
        prompt: str,
        model: str = "default",
        temperature: float = 0.7,
        max_tokens: int = 1000
    ) -> Dict[str, Any]:
        """Get a completion from the model router.
        
        Args:
            prompt: The prompt to send
            model: The model to use
            temperature: Temperature parameter
            max_tokens: Maximum tokens to generate
            
        Returns:
            Completion response
        """
        json_data = {
            "prompt": prompt,
            "model": model,
            "temperature": temperature,
            "max_tokens": max_tokens
        }
        return await self.post("completions", json_data=json_data)
    
    async def get_models(self) -> List[Dict[str, Any]]:
        """Get list of available models.
        
        Returns:
            List of model information
        """
        response = await self.get("models")
        return response.get("models", [])

class RagClient(ResilientClient):
    """Client for interacting with the RAG service."""
    
    def __init__(
        self,
        base_url: str,
        api_key: str,
        collection: str = "general-knowledge",
        **kwargs
    ):
        """Initialize the RAG client.
        
        Args:
            base_url: Base URL for the RAG service
            api_key: API key for authentication
            collection: Default collection to use
            **kwargs: Additional arguments for ResilientClient
        """
        super().__init__(base_url, **kwargs)
        self.api_key = api_key
        self.collection = collection
    
    async def query(
        self,
        query: str,
        collection: Optional[str] = None,
        limit: int = 5
    ) -> List[Dict[str, Any]]:
        """Query the RAG service.
        
        Args:
            query: The query text
            collection: Collection to query (defaults to instance default)
            limit: Maximum number of results
            
        Returns:
            List of documents
        """
        headers = {"X-API-Key": self.api_key}
        json_data = {
            "query": query,
            "collection": collection or self.collection,
            "limit": limit
        }
        response = await self.post("query", json_data=json_data, headers=headers)
        return response.get("documents", [])
    
    async def index_document(
        self,
        document: str,
        metadata: Dict[str, Any],
        collection: Optional[str] = None
    ) -> Dict[str, Any]:
        """Index a document in the RAG service.
        
        Args:
            document: The document text
            metadata: Document metadata
            collection: Collection to index in (defaults to instance default)
            
        Returns:
            Indexing response
        """
        headers = {"X-API-Key": self.api_key}
        json_data = {
            "document": document,
            "metadata": metadata,
            "collection": collection or self.collection
        }
        return await self.post("index", json_data=json_data, headers=headers)