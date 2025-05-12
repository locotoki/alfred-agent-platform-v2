"""
RAG client for legal-compliance service.
Integrates with the platform RAG Gateway for legal and regulatory knowledge retrieval.
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
RAG_API_KEY = os.getenv("RAG_API_KEY", os.getenv("LEGAL_RAG_API_KEY", "legal-key"))
RAG_COLLECTION = os.getenv("RAG_COLLECTION", "legal-knowledge")
USE_RAG_GATEWAY = os.getenv("USE_RAG_GATEWAY", "true").lower() in ("true", "1", "yes")


class RagClient:
    """
    RAG client for legal-compliance service.
    Provides retrieval-augmented generation capabilities for legal and regulatory topics.
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
                            "description": "Legal and regulatory knowledge for the legal-compliance agent"
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
    async def get_legal_context(
        query: str, 
        jurisdictions: Optional[List[str]] = None,
        document_types: Optional[List[str]] = None,
        compliance_categories: Optional[List[str]] = None,
        top_k: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Retrieve legal knowledge from the RAG Gateway.
        
        Args:
            query: Query text
            jurisdictions: Optional list of jurisdictions (e.g., "US", "EU", "UK")
            document_types: Optional list of document types (e.g., "contract", "policy", "regulation")
            compliance_categories: Optional list of compliance categories (e.g., "GDPR", "HIPAA", "CCPA")
            top_k: Maximum number of results
            
        Returns:
            List of relevant legal knowledge
        """
        if not USE_RAG_GATEWAY:
            return []
        
        try:
            # Build filter
            filter_dict = {}
            if jurisdictions:
                filter_dict["jurisdictions"] = jurisdictions[0] if len(jurisdictions) == 1 else {"$in": jurisdictions}
            if document_types:
                filter_dict["document_type"] = document_types[0] if len(document_types) == 1 else {"$in": document_types}
            if compliance_categories:
                filter_dict["compliance_category"] = compliance_categories[0] if len(compliance_categories) == 1 else {"$in": compliance_categories}
            
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
                
                logger.info(f"Retrieved {len(results)} legal context items from RAG Gateway")
                return results
                
        except Exception as e:
            logger.error(f"Error retrieving legal context from RAG Gateway: {str(e)}")
            return []
    
    @staticmethod
    async def get_regulation_context(
        query: str,
        regulation_name: Optional[str] = None,
        jurisdiction: Optional[str] = None,
        industry: Optional[str] = None,
        top_k: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Retrieve regulation-specific knowledge from the RAG Gateway.
        
        Args:
            query: Query text
            regulation_name: Optional regulation name (e.g., "GDPR", "HIPAA")
            jurisdiction: Optional jurisdiction (e.g., "US", "EU")
            industry: Optional industry (e.g., "healthcare", "finance", "technology")
            top_k: Maximum number of results
            
        Returns:
            List of relevant regulation knowledge
        """
        if not USE_RAG_GATEWAY:
            return []
        
        try:
            # Build filter
            filter_dict = {}
            if regulation_name:
                filter_dict["regulation_name"] = regulation_name
            if jurisdiction:
                filter_dict["jurisdiction"] = jurisdiction
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
                
                logger.info(f"Retrieved {len(results)} regulation context items from RAG Gateway")
                return results
                
        except Exception as e:
            logger.error(f"Error retrieving regulation context from RAG Gateway: {str(e)}")
            return []
    
    @staticmethod
    async def get_contract_context(
        query: str,
        contract_type: Optional[str] = None,
        jurisdiction: Optional[str] = None,
        top_k: int = 10
    ) -> List[Dict[str, Any]]:
        """
        Retrieve contract-specific knowledge from the RAG Gateway.
        
        Args:
            query: Query text
            contract_type: Optional contract type (e.g., "employment", "service", "lease")
            jurisdiction: Optional jurisdiction (e.g., "US", "EU", "UK")
            top_k: Maximum number of results
            
        Returns:
            List of relevant contract knowledge
        """
        if not USE_RAG_GATEWAY:
            return []
        
        try:
            # Build filter
            filter_dict = {}
            if contract_type:
                filter_dict["contract_type"] = contract_type
            if jurisdiction:
                filter_dict["jurisdiction"] = jurisdiction
            
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
                
                logger.info(f"Retrieved {len(results)} contract context items from RAG Gateway")
                return results
                
        except Exception as e:
            logger.error(f"Error retrieving contract context from RAG Gateway: {str(e)}")
            return []
    
    @staticmethod
    async def store_documents(documents: List[Dict[str, Any]]) -> bool:
        """
        Store legal and regulatory documents in the RAG Gateway.
        
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