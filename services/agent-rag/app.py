"""FastAPI stub for agent-rag service."""
from typing import Dict

from fastapi import FastAPI

app = FastAPI()


@app.get("/health")
def health() -> Dict[str, str]:
    """Health check endpoint."""
    return {"status": "ok"}
