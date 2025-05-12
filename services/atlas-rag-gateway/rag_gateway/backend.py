import os
import logging
import uuid
import time
from typing import List, Dict, Any, Optional
import httpx
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PointStruct
from qdrant_client.http.exceptions import UnexpectedResponse
from sentence_transformers import SentenceTransformer
import redis
import json
import threading
import hashlib

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("rag_gateway.backend")

# Environment variables
QDRANT_URL = os.getenv("QDRANT_URL", "http://qdrant:6333")
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379/0")
COLLECTION_NAME = os.getenv("COLLECTION_NAME", "atlas-docs")
EMBEDDING_MODEL = os.getenv("EMBEDDING_MODEL", "all-MiniLM-L6-v2")
EMBEDDING_DIM = int(os.getenv("EMBEDDING_DIM", "384"))  # Dimension for all-MiniLM-L6-v2
CACHE_TTL = int(os.getenv("CACHE_TTL", "3600"))  # 1 hour default TTL for cache

# Global clients
qdrant_client = None
model = None
redis_client = None
initialization_lock = threading.Lock()
is_initialized = False

def initialize_clients():
    """Initialize all clients (lazy initialization)"""
    global qdrant_client, model, redis_client, is_initialized
    
    with initialization_lock:
        if is_initialized:
            return
        
        # Initialize Qdrant client
        logger.info(f"Initializing Qdrant client: {QDRANT_URL}")
        qdrant_client = QdrantClient(url=QDRANT_URL)
        
        # Ensure collection exists
        try:
            collections = qdrant_client.get_collections().collections
            collection_names = [c.name for c in collections]
            
            if COLLECTION_NAME not in collection_names:
                logger.info(f"Creating collection: {COLLECTION_NAME}")
                qdrant_client.create_collection(
                    collection_name=COLLECTION_NAME,
                    vectors_config=VectorParams(size=EMBEDDING_DIM, distance=Distance.COSINE)
                )
        except Exception as e:
            logger.warning(f"Error checking/creating collection: {str(e)}")
        
        # Initialize sentence transformer
        logger.info(f"Loading embedding model: {EMBEDDING_MODEL}")
        model = SentenceTransformer(EMBEDDING_MODEL)
        
        # Initialize Redis client for caching
        try:
            logger.info(f"Connecting to Redis: {REDIS_URL}")
            redis_client = redis.from_url(REDIS_URL)
            redis_client.ping()  # Test connection
        except Exception as e:
            logger.warning(f"Redis connection failed, caching disabled: {str(e)}")
            redis_client = None
        
        is_initialized = True
        logger.info("Initialization complete")

def get_redis_key(prefix: str, data: str) -> str:
    """Create a Redis key with a prefix and hashed data"""
    return f"{prefix}:{hashlib.md5(data.encode()).hexdigest()}"

def query_chat(query: str, top_k: int = 15) -> List[Dict[str, Any]]:
    """
    Find relevant documents for a query
    
    Args:
        query: The query to search for
        top_k: Number of results to return
        
    Returns:
        List of documents with similarity scores
    """
    # Initialize if needed
    if not is_initialized:
        initialize_clients()
    
    # Check cache first
    cache_key = get_redis_key("query", f"{query}:{top_k}")
    if redis_client:
        cached = redis_client.get(cache_key)
        if cached:
            logger.info("Query cache hit")
            return json.loads(cached)
    
    # If this is a stub implementation (no model loaded), return dummy data
    if model is None:
        logger.warning("Using stub implementation for query_chat")
        return [{"text": f"Stub context for: {query}", "similarity": 1.0, "source": "stub"}]
    
    try:
        # Embed the query
        query_embedding = model.encode(query).tolist()
        
        # Search Qdrant
        search_result = qdrant_client.search(
            collection_name=COLLECTION_NAME,
            query_vector=query_embedding,
            limit=top_k
        )
        
        # Format results
        results = []
        for scored_point in search_result:
            result = {
                "text": scored_point.payload.get("text", ""),
                "similarity": scored_point.score,
                "source": scored_point.payload.get("source", "unknown")
            }
            results.append(result)
        
        # Cache results
        if redis_client:
            redis_client.setex(
                cache_key,
                CACHE_TTL,
                json.dumps(results)
            )
        
        return results
    
    except Exception as e:
        logger.error(f"Error querying Qdrant: {str(e)}")
        # Return empty result on error
        return []

def embed_batch(docs: List[str]) -> str:
    """
    Embed a batch of documents and store in Qdrant
    
    Args:
        docs: List of document texts to embed
        
    Returns:
        Job ID for the embedding job
    """
    # Initialize if needed
    if not is_initialized:
        initialize_clients()
    
    # Generate a job ID
    job_id = str(uuid.uuid4())
    
    # If this is a stub implementation (no model loaded), return dummy data
    if model is None:
        logger.warning("Using stub implementation for embed_batch")
        return job_id
    
    # Start embedding in a background thread
    def _embed_background():
        try:
            start_time = time.time()
            logger.info(f"Starting embedding job {job_id} with {len(docs)} documents")
            
            # Process in smaller batches to avoid memory issues
            batch_size = 32
            points = []
            
            for i in range(0, len(docs), batch_size):
                batch = docs[i:i+batch_size]
                
                # Create embeddings
                embeddings = model.encode(batch)
                
                # Create points
                for j, embedding in enumerate(embeddings):
                    idx = i + j
                    if idx < len(docs):
                        point_id = str(uuid.uuid4())
                        point = PointStruct(
                            id=point_id,
                            vector=embedding.tolist(),
                            payload={
                                "text": docs[idx],
                                "source": f"batch-{job_id}-{idx}",
                                "timestamp": time.time()
                            }
                        )
                        points.append(point)
            
            # Upsert points to Qdrant
            if points:
                qdrant_client.upsert(
                    collection_name=COLLECTION_NAME,
                    points=points
                )
            
            duration = time.time() - start_time
            logger.info(f"Completed embedding job {job_id} in {duration:.2f}s")
        
        except Exception as e:
            logger.error(f"Error in embedding job {job_id}: {str(e)}")
    
    # Start background task
    threading.Thread(target=_embed_background).start()
    
    return job_id

# Initialize on module load for faster first request
threading.Thread(target=initialize_clients).start()