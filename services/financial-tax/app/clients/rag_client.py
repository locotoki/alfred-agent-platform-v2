"""
RAG client for financial-tax service.
Integrates with the platform RAG Gateway for financial and tax knowledge retrieval.
"""

import os
import json
import httpx
import structlog
from typing import List, Dict, Any, Optional
from datetime import datetime

logger = structlog.get_logger(__name__)

# Environment variables for RAG Gateway
RAG_URL = os.getenv("RAG_URL", "http://rag-gateway:8501")
RAG_API_KEY = os.getenv("RAG_API_KEY", os.getenv("FINANCIAL_RAG_API_KEY", "financial-key"))
RAG_COLLECTION = os.getenv("RAG_COLLECTION", "financial-knowledge")
USE_RAG_GATEWAY = os.getenv("USE_RAG_GATEWAY", "true").lower() in ("true", "1", "yes")


class RagClient:
    """
    RAG client for financial-tax service.
    Provides retrieval-augmented generation capabilities for financial and tax topics.
    """
    
    @staticmethod
    async def check_connection() -> bool:
        """
        Check if the RAG Gateway is reachable.
        
        Returns:
            True if the RAG Gateway is reachable, False otherwise
        """
        global USE_RAG_GATEWAY
        
        if not RAG_URL or not RAG_API_KEY:
            logger.warning("RAG Gateway not configured")
            USE_RAG_GATEWAY = False
            return False
        
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                # Check basic health
                response = await client.get(
                    f"{RAG_URL}/healthz",
                    headers={
                        "X-API-Key": RAG_API_KEY
                    }
                )
                
                if response.status_code >= 300:
                    logger.warning(f"RAG Gateway health check failed: {response.status_code}")
                    USE_RAG_GATEWAY = False
                    return False
                
                # Verify collection exists
                collection_check = await client.get(
                    f"{RAG_URL}/collections/{RAG_COLLECTION}",
                    headers={
                        "X-API-Key": RAG_API_KEY
                    }
                )
                
                if collection_check.status_code == 404:
                    logger.warning(f"Collection '{RAG_COLLECTION}' not found")
                    # Try to create the collection
                    creation_response = await client.post(
                        f"{RAG_URL}/collections/create",
                        headers={
                            "Content-Type": "application/json",
                            "X-API-Key": RAG_API_KEY
                        },
                        json={
                            "name": RAG_COLLECTION,
                            "description": "Financial and tax knowledge for the financial-tax agent"
                        }
                    )
                    
                    if creation_response.status_code >= 300:
                        logger.error(f"Failed to create collection: {creation_response.status_code}")
                        USE_RAG_GATEWAY = False
                        return False
                    else:
                        logger.info(f"Created collection '{RAG_COLLECTION}'")
                
                logger.info("Successfully connected to RAG Gateway")
                return True
                
        except Exception as e:
            logger.error(f"Error connecting to RAG Gateway: {str(e)}")
            USE_RAG_GATEWAY = False
            return False
    
    @staticmethod
    async def get_tax_context(
        query: str, 
        jurisdiction: Optional[str] = None,
        tax_year: Optional[int] = None,
        entity_type: Optional[str] = None,
        top_k: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Retrieve tax-specific knowledge from the RAG Gateway.
        
        Args:
            query: Query text
            jurisdiction: Optional jurisdiction filter
            tax_year: Optional tax year filter
            entity_type: Optional entity type filter
            top_k: Maximum number of results
            
        Returns:
            List of relevant tax knowledge
        """
        if not USE_RAG_GATEWAY:
            return []
        
        try:
            # Build filter
            filter_dict = {}
            if jurisdiction:
                filter_dict["jurisdiction"] = jurisdiction
            if tax_year:
                filter_dict["tax_year"] = tax_year
            if entity_type:
                filter_dict["entity_type"] = entity_type
            
            async with httpx.AsyncClient(timeout=10.0) as client:
                # Query RAG Gateway
                response = await client.post(
                    f"{RAG_URL}/query",
                    headers={
                        "Content-Type": "application/json",
                        "X-API-Key": RAG_API_KEY
                    },
                    json={
                        "query": query,
                        "collection": RAG_COLLECTION,
                        "top_k": top_k,
                        "filter": filter_dict if filter_dict else None
                    }
                )
                
                if response.status_code >= 300:
                    logger.warning(f"RAG Gateway query failed: {response.status_code}")
                    return []
                
                data = response.json()
                results = data.get("results", [])
                
                logger.info(f"Retrieved {len(results)} tax context items from RAG Gateway")
                return results
                
        except Exception as e:
            logger.error(f"Error retrieving tax context from RAG Gateway: {str(e)}")
            return []
    
    @staticmethod
    async def get_financial_context(
        query: str,
        statement_type: Optional[str] = None,
        industry: Optional[str] = None,
        top_k: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Retrieve financial knowledge from the RAG Gateway.
        
        Args:
            query: Query text
            statement_type: Optional statement type filter (income, balance, cash_flow)
            industry: Optional industry filter
            top_k: Maximum number of results
            
        Returns:
            List of relevant financial knowledge
        """
        if not USE_RAG_GATEWAY:
            return []
        
        try:
            # Build filter
            filter_dict = {}
            if statement_type:
                filter_dict["statement_type"] = statement_type
            if industry:
                filter_dict["industry"] = industry
            
            async with httpx.AsyncClient(timeout=10.0) as client:
                # Query RAG Gateway
                response = await client.post(
                    f"{RAG_URL}/query",
                    headers={
                        "Content-Type": "application/json",
                        "X-API-Key": RAG_API_KEY
                    },
                    json={
                        "query": query,
                        "collection": RAG_COLLECTION,
                        "top_k": top_k,
                        "filter": filter_dict if filter_dict else None
                    }
                )
                
                if response.status_code >= 300:
                    logger.warning(f"RAG Gateway query failed: {response.status_code}")
                    return []
                
                data = response.json()
                results = data.get("results", [])
                
                logger.info(f"Retrieved {len(results)} financial context items from RAG Gateway")
                return results
                
        except Exception as e:
            logger.error(f"Error retrieving financial context from RAG Gateway: {str(e)}")
            return []
    
    @staticmethod
    async def get_regulatory_context(
        query: str,
        regulation_type: Optional[str] = None,
        country: Optional[str] = None,
        top_k: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Retrieve regulatory compliance knowledge from the RAG Gateway.
        
        Args:
            query: Query text
            regulation_type: Optional regulation type filter
            country: Optional country filter
            top_k: Maximum number of results
            
        Returns:
            List of relevant regulatory knowledge
        """
        if not USE_RAG_GATEWAY:
            return []
        
        try:
            # Build filter
            filter_dict = {}
            if regulation_type:
                filter_dict["regulation_type"] = regulation_type
            if country:
                filter_dict["country"] = country
            
            async with httpx.AsyncClient(timeout=10.0) as client:
                # Query RAG Gateway
                response = await client.post(
                    f"{RAG_URL}/query",
                    headers={
                        "Content-Type": "application/json",
                        "X-API-Key": RAG_API_KEY
                    },
                    json={
                        "query": query,
                        "collection": RAG_COLLECTION,
                        "top_k": top_k,
                        "filter": filter_dict if filter_dict else None
                    }
                )
                
                if response.status_code >= 300:
                    logger.warning(f"RAG Gateway query failed: {response.status_code}")
                    return []
                
                data = response.json()
                results = data.get("results", [])
                
                logger.info(f"Retrieved {len(results)} regulatory context items from RAG Gateway")
                return results
                
        except Exception as e:
            logger.error(f"Error retrieving regulatory context from RAG Gateway: {str(e)}")
            return []
    
    @staticmethod
    async def store_documents(documents: List[Dict[str, Any]]) -> bool:
        """
        Store financial and tax documents in the RAG Gateway.
        
        Args:
            documents: List of documents to store
            
        Returns:
            True if successful, False otherwise
        """
        if not USE_RAG_GATEWAY:
            return False
        
        try:
            async with httpx.AsyncClient(timeout=20.0) as client:
                # Store documents
                response = await client.post(
                    f"{RAG_URL}/ingest",
                    headers={
                        "Content-Type": "application/json",
                        "X-API-Key": RAG_API_KEY
                    },
                    json={
                        "documents": documents,
                        "collection": RAG_COLLECTION
                    }
                )
                
                if response.status_code >= 300:
                    logger.warning(f"Failed to store documents in RAG Gateway: {response.status_code}")
                    return False
                
                logger.info(f"Stored {len(documents)} documents in RAG Gateway")
                return True
                
        except Exception as e:
            logger.error(f"Error storing documents in RAG Gateway: {str(e)}")
            return False

# Initialize client
rag_client = RagClient()