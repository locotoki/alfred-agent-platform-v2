# RAG Servcie - Rag Client Retriever

from **future** import annotations

"""
LangChain retriever wrapper that swaps seamlessly into any existing agent chain.
Requires: `pip install langchain pydantic requests tenacity`.
"""

from typing import List, Any, Dict
import os
import requests
from pydantic import BaseModel, Field, HttpUrl
from tenacity import retry, wait_exponential, stop_after_attempt
from langchain.schema import Document
from langchain.retrievers.base import BaseRetriever

RAG_GATEWAY = os.getenv("RAG_GATEWAY", "[http://localhost:8080](http://localhost:8080/)")
JWT_TOKEN = os.getenv("SUPABASE_JWT")

class RetrievalHit(BaseModel):
id: str
score: float
content: str
metadata: Dict[str, Any]

class _RetrievalResponse(BaseModel):
trace_id: str
latency_ms: int
hits: List[RetrievalHit]

class RAGClientRetriever(BaseRetriever):
"""LangChain retriever that calls the /v1/query endpoint."""

```
top_k: int = Field(default=4, description="Number of results to return")
hybrid_lambda: float = Field(default=0.95, description="ANN weight vs BM25 (0‑1)")
rerank: bool = Field(default=True, description="Apply cross‑encoder re‑ranking")

def _headers(self) -> Dict[str, str]:
    return {
        "Authorization": f"Bearer {JWT_TOKEN}",
        "Content-Type": "application/json",
    }

@retry(wait=wait_exponential(multiplier=0.25, min=0.5, max=4), stop=stop_after_attempt(3))
def _query_gateway(self, query: str) -> _RetrievalResponse:
    resp = requests.post(
        f"{RAG_GATEWAY}/v1/query",
        json={
            "query": query,
            "top_k": self.top_k,
            "hybrid_lambda": self.hybrid_lambda,
            "rerank": self.rerank,
        },
        headers=self._headers(),
        timeout=10,
    )
    resp.raise_for_status()
    return _RetrievalResponse.model_validate(resp.json())

def _get_relevant_documents(self, query: str) -> List[Document]:
    resp = self._query_gateway(query)
    return [
        Document(
            page_content=hit.content,
            metadata={
                **hit.metadata,
                "score": hit.score,
                "trace_id": resp.trace_id,
            },
        )
        for hit in resp.hits
    ]

```

# -- quick smoke test ---------------------------------------------------------

if **name** == "**main**":
retriever = RAGClientRetriever(top_k=3)
docs = retriever.get_relevant_documents("What does the infra look like?")
for d in docs:
print(d.metadata["score"], d.page_content[:120])