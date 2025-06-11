"""Vector ingestion worker with CloudEvents support and ML functionality."""

import json
import os
import time
import uuid
import logging
from typing import Optional

import requests
import uvicorn
from cloudevents.http import CloudEvent
from fastapi import FastAPI, Response, HTTPException
from langchain.text_splitter import RecursiveCharacterTextSplitter
from sentence_transformers import SentenceTransformer

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(title="Vector Ingest Service")

# Initialize ML components (lazy loading)
MODEL: Optional[SentenceTransformer] = None
SPLITTER: Optional[RecursiveCharacterTextSplitter] = None

def get_model():
    """Lazy load the sentence transformer model."""
    global MODEL
    if MODEL is None:
        model_name = os.getenv("EMBED_MODEL", "sentence-transformers/all-MiniLM-L6-v2")
        logger.info(f"Loading model: {model_name}")
        MODEL = SentenceTransformer(model_name)
    return MODEL

def get_splitter():
    """Lazy load the text splitter."""
    global SPLITTER
    if SPLITTER is None:
        SPLITTER = RecursiveCharacterTextSplitter(chunk_size=512, chunk_overlap=64)
    return SPLITTER

@app.get("/health")
def health():
    """Health check endpoint."""
    return {
        "status": "ok",
        "service": "vector-ingest",
        "mode": "full",
        "model_loaded": MODEL is not None,
        "splitter_loaded": SPLITTER is not None
    }

@app.get("/healthz")
def healthz():
    """Simple health probe."""
    return {"status": "ok"}

@app.get("/")
def root():
    """Root endpoint."""
    return {
        "message": "Vector Ingest Service",
        "version": "1.0.0",
        "health": "/health",
        "mode": "full ML support"
    }

@app.post("/ingest")
async def ingest(event: dict):
    """Handle vector ingestion requests."""
    try:
        # For now, simplified auth handling
        # TODO: Implement proper auth verification
        # from alfred_sdk.auth.verify import verify
        # claims = verify(event.get("headers", {}).get("authorization", "").split()[-1])
        
        data = event.get("data", {})
        if isinstance(data, str):
            data = json.loads(data)
        
        tenant = data.get("tenant", "default")
        doc_id = data.get("id", str(uuid.uuid4()))
        text = data.get("text", "")
        
        if not text:
            raise HTTPException(status_code=400, detail="No text provided for ingestion")
        
        # Process text
        splitter = get_splitter()
        model = get_model()
        
        chunks = splitter.split_text(text)
        vectors = model.encode(chunks).tolist()
        
        payload = {
            "tenant": tenant,
            "doc_id": doc_id,
            "ttl_days": data.get("ttl_days", 90),
            "chunks": chunks,
            "vectors": vectors,
        }
        
        # Send to vector database
        vector_db_url = os.getenv("VECTOR_DB_URL", "http://vector-db:6333")
        response = requests.post(f"{vector_db_url}/ingest", json=payload, timeout=5)
        response.raise_for_status()
        
        logger.info(f"[{tenant}] ingested {len(chunks)} chunks for {doc_id}")
        
        return {
            "status": "success",
            "doc_id": doc_id,
            "chunks": len(chunks),
            "vectors": len(vectors)
        }
        
    except Exception as e:
        logger.error(f"Error processing ingestion: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

def handle_cloud_event(event: CloudEvent):
    """Legacy CloudEvent handler for compatibility."""
    # Convert CloudEvent to dict and call ingest
    event_dict = {
        "headers": dict(event.get("headers", {})),
        "data": event.data
    }
    return ingest(event_dict)

if __name__ == "__main__":
    port = int(os.getenv("PORT", "8000"))
    uvicorn.run(app, host="0.0.0.0", port=port)