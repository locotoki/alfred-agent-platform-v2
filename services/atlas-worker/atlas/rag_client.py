import os, logging, json
from typing import List, Dict, Any
import httpx
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type

# Configure logging
logger = logging.getLogger("atlas.rag")

# Environment configuration
RAG_URL = os.getenv("RAG_URL", "http://atlas-rag-gateway:8501")
RELEVANCY_THRESHOLD = float(os.getenv("RELEVANCY_THRESHOLD", "0.65"))
DEFAULT_TOP_K = int(os.getenv("RAG_TOP_K", "15"))

# In-memory cache for queries
# Simple LRU cache with a maximum of 100 items
class SimpleCache:
    def __init__(self, max_size=100):
        self.cache = {}
        self.max_size = max_size
        self.access_order = []
    
    def get(self, key):
        if key in self.cache:
            # Move to end of access order (most recently used)
            self.access_order.remove(key)
            self.access_order.append(key)
            return self.cache[key]
        return None
    
    def set(self, key, value):
        if key in self.cache:
            # Update existing item
            self.cache[key] = value
            self.access_order.remove(key)
            self.access_order.append(key)
        else:
            # Add new item, evict if necessary
            if len(self.cache) >= self.max_size:
                # Remove least recently used
                lru_key = self.access_order.pop(0)
                del self.cache[lru_key]
            
            # Add new item
            self.cache[key] = value
            self.access_order.append(key)

# Initialize cache
query_cache = SimpleCache(max_size=100)

@retry(
    retry=retry_if_exception_type((httpx.HTTPError, httpx.TimeoutException)),
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=2, max=10),
    reraise=True
)
def get_context(question: str, top_k: int = DEFAULT_TOP_K) -> List[Dict[str, Any]]:
    """
    Retrieve relevant context for a question from the RAG service
    
    Args:
        question: The question to retrieve context for
        top_k: Maximum number of context chunks to retrieve
        
    Returns:
        List of context chunks with text and similarity score
        
    Raises:
        httpx.HTTPError: If the RAG service returns an error
        httpx.TimeoutException: If the request times out
    """
    logger.info(f"Retrieving context for question: {question[:50]}...")
    
    # Check cache first
    cache_key = f"{question}:{top_k}"
    cached_result = query_cache.get(cache_key)
    if cached_result:
        logger.info("Retrieved context from cache")
        return cached_result
    
    try:
        # Make request to RAG service
        with httpx.Client(timeout=30.0) as client:
            response = client.post(
                f"{RAG_URL}/v1/query_chat",
                json={"query": question, "top_k": top_k}
            )
            
            # Raise for HTTP errors
            response.raise_for_status()
            
            # Parse response
            results = response.json()
            
            # Filter by relevancy threshold
            filtered_results = [
                r for r in results 
                if r.get("similarity", 0) >= RELEVANCY_THRESHOLD
            ]
            
            # Log results
            logger.info(f"Retrieved {len(filtered_results)} relevant context chunks " +
                       f"(filtered from {len(results)} total)")
            
            # Cache results
            query_cache.set(cache_key, filtered_results)
            
            return filtered_results
    except httpx.HTTPStatusError as e:
        logger.error(f"RAG service HTTP error: {e.response.status_code} - {e.response.text}")
        raise
    except httpx.TimeoutException:
        logger.error("RAG service request timed out")
        raise
    except Exception as e:
        logger.error(f"Error retrieving context: {str(e)}")
        # Return empty context as fallback
        return []