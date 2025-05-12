from fastapi import FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse
from rag_gateway.backend import embed_batch, query_chat
import logging
import time
from prometheus_client import Counter, Histogram, generate_latest
from prometheus_client.exposition import CONTENT_TYPE_LATEST
from fastapi.responses import Response

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[logging.StreamHandler()]
)
logger = logging.getLogger("rag-gateway")

# Metrics
query_requests = Counter("rag_query_requests_total", "Total query requests")
embed_requests = Counter("rag_embed_requests_total", "Total embedding requests")
query_latency = Histogram("rag_query_seconds", "Query latency",
                        buckets=[0.05, 0.1, 0.5, 1.0, 2.0, 5.0, 10.0])
embed_latency = Histogram("rag_embed_seconds", "Embedding latency",
                        buckets=[0.1, 0.5, 1.0, 5.0, 10.0, 30.0, 60.0])
error_count = Counter("rag_errors_total", "Total errors", ["type"])

app = FastAPI(title="Atlas RAG Gateway")

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Log all requests and their processing time"""
    start_time = time.time()

    try:
        response = await call_next(request)
        process_time = time.time() - start_time
        logger.info(f"Request: {request.method} {request.url.path} - Status: {response.status_code} - Time: {process_time:.3f}s")
        return response
    except Exception as e:
        process_time = time.time() - start_time
        logger.error(f"Request: {request.method} {request.url.path} - Error: {str(e)} - Time: {process_time:.3f}s")
        error_count.labels(type="middleware").inc()
        return JSONResponse(
            status_code=500,
            content={"detail": "Internal server error"}
        )

@app.get("/healthz")
async def health():
    """Health check endpoint"""
    return {"status": "ok"}

@app.get("/metrics")
async def metrics():
    """Prometheus metrics endpoint"""
    return Response(content=generate_latest(), media_type=CONTENT_TYPE_LATEST)

@app.post("/v1/query_chat")
async def _query(payload: dict):
    """Query endpoint to retrieve relevant context for a question"""
    query_requests.inc()

    # Validate payload
    if "query" not in payload:
        error_count.labels(type="missing_query").inc()
        raise HTTPException(status_code=400, detail="Missing 'query' field")

    # Process query with metrics
    try:
        with query_latency.time():
            result = query_chat(payload["query"], payload.get("top_k", 15))
        return result
    except Exception as e:
        logger.error(f"Query error: {str(e)}")
        error_count.labels(type="query_processing").inc()
        raise HTTPException(status_code=500, detail=f"Error processing query: {str(e)}")

@app.post("/v1/embed_batch")
async def _embed(payload: list[str]):
    """Embed a batch of documents into the vector database"""
    embed_requests.inc()

    # Validate payload
    if not payload or not isinstance(payload, list):
        error_count.labels(type="invalid_batch").inc()
        raise HTTPException(status_code=400, detail="Payload must be a non-empty list of strings")

    # Process embedding with metrics
    try:
        with embed_latency.time():
            job_id = embed_batch(payload)
        return {"job_id": job_id}
    except Exception as e:
        logger.error(f"Embedding error: {str(e)}")
        error_count.labels(type="embed_processing").inc()
        raise HTTPException(status_code=500, detail=f"Error processing embeddings: {str(e)}")