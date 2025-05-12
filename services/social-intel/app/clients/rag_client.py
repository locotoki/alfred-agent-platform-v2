"""
RAG client for social-intel service with hybrid retrieval capability.
Supports both platform RAG Gateway and direct Qdrant access.
"""

import os
import json
import httpx
import structlog
from typing import List, Dict, Any, Optional

logger = structlog.get_logger(__name__)

# Environment variables for RAG Gateway
RAG_URL = os.getenv("RAG_URL", "http://rag-gateway:8501")
RAG_API_KEY = os.getenv("RAG_API_KEY", os.getenv("SOCIAL_RAG_API_KEY", "social-key"))
RAG_COLLECTION = os.getenv("RAG_COLLECTION", "social-intel-knowledge")
USE_RAG_GATEWAY = os.getenv("USE_RAG_GATEWAY", "true").lower() in ("true", "1", "yes")

# Environment variables for direct Qdrant access
QDRANT_URL = os.getenv("QDRANT_URL", "http://qdrant:6333")
USE_DIRECT_QDRANT = os.getenv("USE_DIRECT_QDRANT", "true").lower() in ("true", "1", "yes")

# Which source to try first (rag_gateway or direct_qdrant)
PRIMARY_SOURCE = os.getenv("PRIMARY_SOURCE", "rag_gateway")


class RagClient:
    """
    Hybrid RAG client that supports both platform RAG Gateway and direct Qdrant access.
    This allows for a gradual migration to platform services without losing specialized functionality.
    """
    
    @staticmethod
    async def check_gateway_connection() -> bool:
        """
        Check if the RAG Gateway is reachable.
        
        Returns:
            True if the RAG Gateway is reachable, False otherwise
        """
        global USE_RAG_GATEWAY
        
        if not RAG_URL or not RAG_API_KEY:
            logger.warning("RAG Gateway not configured - using direct Qdrant only")
            USE_RAG_GATEWAY = False
            return False
        
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
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
                    USE_RAG_GATEWAY = False
                    return False
                
                logger.info("Successfully connected to RAG Gateway")
                return True
                
        except Exception as e:
            logger.error(f"Error connecting to RAG Gateway: {str(e)}")
            USE_RAG_GATEWAY = False
            return False
    
    @staticmethod
    async def check_qdrant_connection() -> bool:
        """
        Check if direct Qdrant access is available.
        
        Returns:
            True if Qdrant is reachable, False otherwise
        """
        global USE_DIRECT_QDRANT
        
        if not QDRANT_URL:
            logger.warning("Qdrant URL not configured")
            USE_DIRECT_QDRANT = False
            return False
        
        try:
            async with httpx.AsyncClient(timeout=5.0) as client:
                response = await client.get(f"{QDRANT_URL}/collections")
                
                if response.status_code >= 300:
                    logger.warning(f"Qdrant connection failed: {response.status_code}")
                    USE_DIRECT_QDRANT = False
                    return False
                
                # Check if our collections exist
                collections_data = response.json()
                collections = [c["name"] for c in collections_data.get("result", {}).get("collections", [])]
                
                if not any(c in collections for c in ["youtube_channels", "youtube_videos", "youtube_niches"]):
                    logger.warning("No YouTube collections found in Qdrant")
                
                logger.info("Successfully connected to Qdrant directly")
                return True
                
        except Exception as e:
            logger.error(f"Error connecting to Qdrant: {str(e)}")
            USE_DIRECT_QDRANT = False
            return False
    
    @staticmethod
    async def get_context_from_gateway(query: str, top_k: int = 10, filter_dict: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """
        Retrieve context from the platform RAG Gateway.
        
        Args:
            query: The query to retrieve context for
            top_k: Maximum number of results to return
            filter_dict: Optional filter dictionary
            
        Returns:
            List of context documents or empty list if failed
        """
        if not USE_RAG_GATEWAY:
            return []
        
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                # Prepare request body
                request_data = {
                    "query": query,
                    "collection": RAG_COLLECTION,
                    "top_k": top_k
                }
                
                if filter_dict:
                    request_data["filter"] = filter_dict
                
                # Make the request
                response = await client.post(
                    f"{RAG_URL}/query",
                    headers={
                        "Content-Type": "application/json",
                        "X-API-Key": RAG_API_KEY
                    },
                    json=request_data
                )
                
                if response.status_code >= 300:
                    logger.warning(f"RAG Gateway query failed: {response.status_code}")
                    return []
                
                # Process response
                data = response.json()
                results = data.get("results", [])
                
                logger.info(f"Retrieved {len(results)} context items from RAG Gateway")
                return results
                
        except Exception as e:
            logger.error(f"Error retrieving context from RAG Gateway: {str(e)}")
            return []
    
    @staticmethod
    async def get_context_from_qdrant(query: str, collection: str = "youtube_niches", top_k: int = 10, filter_dict: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """
        Retrieve context directly from Qdrant.
        
        Args:
            query: The query to retrieve context for
            collection: The Qdrant collection to query
            top_k: Maximum number of results to return
            filter_dict: Optional filter conditions
            
        Returns:
            List of context documents or empty list if failed
        """
        if not USE_DIRECT_QDRANT:
            return []
        
        try:
            # Convert query to vector (would normally use a model here)
            # For demo purposes, we're just doing a keyword search
            # In a real implementation, this would use sentence-transformers
            async with httpx.AsyncClient(timeout=10.0) as client:
                # The actual implementation should use proper vector embedding
                # This is a simplified version for demonstration purposes
                search_payload = {
                    "filter": filter_dict if filter_dict else {},
                    "limit": top_k,
                    "with_payload": True
                }
                
                # In real implementation, we would use:
                # vector = get_embedding(query)
                # search_payload["vector"] = vector
                
                # For now, use a simplified keyword search
                search_payload["with_payload"] = {"keywords": query.split()}
                
                # Make the request
                response = await client.post(
                    f"{QDRANT_URL}/collections/{collection}/points/search",
                    json=search_payload
                )
                
                if response.status_code >= 300:
                    logger.warning(f"Qdrant query failed: {response.status_code}")
                    return []
                
                # Process response
                data = response.json()
                results = data.get("result", [])
                
                # Format results to match RAG Gateway format
                formatted_results = []
                for result in results:
                    payload = result.get("payload", {})
                    formatted_results.append({
                        "text": payload.get("text", ""),
                        "metadata": {
                            "source": payload.get("source", ""),
                            "score": result.get("score", 0)
                        }
                    })
                
                logger.info(f"Retrieved {len(formatted_results)} context items from Qdrant")
                return formatted_results
                
        except Exception as e:
            logger.error(f"Error retrieving context from Qdrant: {str(e)}")
            return []
    
    @staticmethod
    async def get_context(query: str, top_k: int = 10, context_type: str = "youtube", filter_dict: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """
        Get context with hybrid retrieval strategy.
        Tries the primary source first, then falls back to the secondary source.
        
        Args:
            query: The query to retrieve context for
            top_k: Maximum number of results to return
            context_type: Type of context (youtube, trends, etc.)
            filter_dict: Optional filter conditions
            
        Returns:
            List of context documents
        """
        results = []
        
        # Determine which source to try first
        if PRIMARY_SOURCE == "rag_gateway":
            # Try RAG Gateway first
            if USE_RAG_GATEWAY:
                results = await RagClient.get_context_from_gateway(query, top_k, filter_dict)
            
            # Fall back to direct Qdrant if needed
            if not results and USE_DIRECT_QDRANT:
                # Map context_type to collection
                collection = "youtube_niches"
                if context_type == "channels":
                    collection = "youtube_channels"
                elif context_type == "videos":
                    collection = "youtube_videos"
                
                results = await RagClient.get_context_from_qdrant(query, collection, top_k, filter_dict)
        else:
            # Try direct Qdrant first
            if USE_DIRECT_QDRANT:
                # Map context_type to collection
                collection = "youtube_niches"
                if context_type == "channels":
                    collection = "youtube_channels"
                elif context_type == "videos":
                    collection = "youtube_videos"
                
                results = await RagClient.get_context_from_qdrant(query, collection, top_k, filter_dict)
            
            # Fall back to RAG Gateway if needed
            if not results and USE_RAG_GATEWAY:
                results = await RagClient.get_context_from_gateway(query, top_k, filter_dict)
        
        return results
    
    @staticmethod
    async def store_documents(documents: List[Dict[str, Any]], collection: Optional[str] = None) -> bool:
        """
        Store documents in the RAG system with hybrid storage strategy.
        
        Args:
            documents: List of documents to store
            collection: Optional collection override
            
        Returns:
            True if successful, False otherwise
        """
        success = False
        
        # Try RAG Gateway first if enabled
        if USE_RAG_GATEWAY:
            try:
                collection_name = collection or RAG_COLLECTION
                
                async with httpx.AsyncClient(timeout=20.0) as client:
                    response = await client.post(
                        f"{RAG_URL}/ingest",
                        headers={
                            "Content-Type": "application/json",
                            "X-API-Key": RAG_API_KEY
                        },
                        json={
                            "documents": documents,
                            "collection": collection_name
                        }
                    )
                    
                    if response.status_code < 300:
                        logger.info(f"Stored {len(documents)} documents in RAG Gateway")
                        success = True
                    else:
                        logger.warning(f"Failed to store documents in RAG Gateway: {response.status_code}")
            except Exception as e:
                logger.error(f"Error storing documents in RAG Gateway: {str(e)}")
        
        # Try direct Qdrant storage if enabled
        if USE_DIRECT_QDRANT and (not success or PRIMARY_SOURCE == "direct_qdrant"):
            try:
                # Map to appropriate Qdrant collection
                qdrant_collection = "youtube_niches"
                if collection == "channels":
                    qdrant_collection = "youtube_channels"
                elif collection == "videos":
                    qdrant_collection = "youtube_videos"
                
                # Format documents for Qdrant
                points = []
                for i, doc in enumerate(documents):
                    # In a real implementation, we would convert text to a vector here
                    # For demo purposes, we're storing without vectors
                    points.append({
                        "id": i,
                        "payload": {
                            "text": doc.get("text", ""),
                            "source": doc.get("metadata", {}).get("source", ""),
                            "keywords": doc.get("text", "").split()  # Simple tokenization
                        }
                    })
                
                # Store in batches of 100
                batch_size = 100
                for i in range(0, len(points), batch_size):
                    batch = points[i:i+batch_size]
                    
                    async with httpx.AsyncClient(timeout=20.0) as client:
                        response = await client.put(
                            f"{QDRANT_URL}/collections/{qdrant_collection}/points",
                            json={"points": batch}
                        )
                        
                        if response.status_code >= 300:
                            logger.warning(f"Failed to store batch in Qdrant: {response.status_code}")
                            success = False
                            break
                
                if success:
                    logger.info(f"Stored {len(documents)} documents in Qdrant")
            except Exception as e:
                logger.error(f"Error storing documents in Qdrant: {str(e)}")
                success = False
        
        return success

# Initialize client
rag_client = RagClient()