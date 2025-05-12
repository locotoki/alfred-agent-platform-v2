"""
Tool for CrewAI agents to interact with the Alfred RAG Gateway.
"""

import os
import json
import httpx
from typing import Optional
from langchain.tools import BaseTool

import structlog

logger = structlog.get_logger(__name__)

class RagQueryTool(BaseTool):
    """Tool for retrieving information from the Alfred RAG Gateway."""
    
    name = "rag_query"
    description = """
    Retrieve information from the organization's knowledge base.
    Useful for finding specific information about products, processes, 
    or domain knowledge stored in the organizational documents.
    Input should be a specific query or question.
    """
    
    def __init__(
        self,
        rag_url: Optional[str] = None,
        rag_api_key: Optional[str] = None,
        tenant_id: Optional[str] = None,
        collection_name: str = "default",
        *args,
        **kwargs
    ):
        """Initialize the RAG query tool."""
        super().__init__(*args, **kwargs)
        self.rag_url = rag_url or os.environ.get("ALFRED_RAG_URL", "http://agent-rag:8501")
        self.rag_api_key = rag_api_key or os.environ.get("ALFRED_RAG_API_KEY", "crew-key")
        self.tenant_id = tenant_id
        self.collection_name = collection_name
    
    def _run(self, query: str) -> str:
        """Execute the RAG query."""
        if not query.strip():
            return "Query cannot be empty."
        
        headers = {
            "Content-Type": "application/json",
            "X-API-Key": self.rag_api_key
        }
        
        # Add tenant ID if provided
        params = {"collection": self.collection_name}
        if self.tenant_id:
            params["tenant_id"] = self.tenant_id
        
        try:
            # Construct the API endpoint for queries
            rag_endpoint = f"{self.rag_url}/api/v1/query"
            
            # Build the request payload
            payload = {
                "query": query,
                "max_results": 5
            }
            
            # Send the request to the RAG Gateway
            response = httpx.post(
                rag_endpoint,
                headers=headers,
                params=params,
                json=payload,
                timeout=30.0
            )
            
            if response.status_code != 200:
                logger.error(
                    "rag_query_error",
                    status_code=response.status_code,
                    response=response.text,
                    query=query
                )
                return f"Error querying RAG Gateway: {response.status_code}"
            
            # Process the response
            result = response.json()
            
            # Extract and format the results
            documents = result.get("documents", [])
            if not documents:
                return "No relevant information found for this query."
            
            # Format the response
            formatted_result = "Here's what I found in our knowledge base:\n\n"
            for i, doc in enumerate(documents, 1):
                content = doc.get("content", "").strip()
                metadata = doc.get("metadata", {})
                source = metadata.get("source", "Unknown source")
                
                formatted_result += f"Source {i}: {source}\n"
                formatted_result += f"{content}\n\n"
            
            return formatted_result
            
        except Exception as e:
            logger.error("rag_query_exception", error=str(e), query=query)
            return f"Error connecting to RAG Gateway: {str(e)}"
    
    async def _arun(self, query: str) -> str:
        """Execute the RAG query asynchronously."""
        if not query.strip():
            return "Query cannot be empty."
        
        headers = {
            "Content-Type": "application/json",
            "X-API-Key": self.rag_api_key
        }
        
        # Add tenant ID if provided
        params = {"collection": self.collection_name}
        if self.tenant_id:
            params["tenant_id"] = self.tenant_id
        
        try:
            # Construct the API endpoint for queries
            rag_endpoint = f"{self.rag_url}/api/v1/query"
            
            # Build the request payload
            payload = {
                "query": query,
                "max_results": 5
            }
            
            # Send the request to the RAG Gateway
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    rag_endpoint,
                    headers=headers,
                    params=params,
                    json=payload,
                    timeout=30.0
                )
            
            if response.status_code != 200:
                logger.error(
                    "rag_query_error",
                    status_code=response.status_code,
                    response=response.text,
                    query=query
                )
                return f"Error querying RAG Gateway: {response.status_code}"
            
            # Process the response
            result = response.json()
            
            # Extract and format the results
            documents = result.get("documents", [])
            if not documents:
                return "No relevant information found for this query."
            
            # Format the response
            formatted_result = "Here's what I found in our knowledge base:\n\n"
            for i, doc in enumerate(documents, 1):
                content = doc.get("content", "").strip()
                metadata = doc.get("metadata", {})
                source = metadata.get("source", "Unknown source")
                
                formatted_result += f"Source {i}: {source}\n"
                formatted_result += f"{content}\n\n"
            
            return formatted_result
            
        except Exception as e:
            logger.error("rag_query_exception", error=str(e), query=query)
            return f"Error connecting to RAG Gateway: {str(e)}"