# RAG Retrieval Endpoint

This package implements the retrieval-augmented generation (RAG) endpoint for the agent-core MVP.

## API Specification

### POST /v1/query

Request:
```json
{
  "query": "When is GA v3.0.0?",
  "top_k": 4
}
```

Response:
```json
{
  "answer": "GA is targeted for 11 July 2025 [^1]",
  "citations": [
    {
      "id": "1433d0…",
      "excerpt": "GA v3.0.0 — 11 Jul 2025"
    }
  ]
}
```

## Implementation Details

1. The handler accepts a query and optional `top_k` parameter (default: 4)
2. Generates an embedding for the query using OpenAI's text-embedding-3-small model
3. Searches the vector store for the most similar documents
4. Uses GPT-3.5-turbo to generate an answer with citations
5. Returns the answer with footnote-style citations mapping to the citations array

## Performance Target

- p95 latency ≤ 300ms at 10 QPS

## Testing

Run unit tests:
```bash
go test ./internal/handler -v
```

Run integration test:
```bash
# Start the server
PORT=8080 POSTGRES_DSN=... OPENAI_API_KEY=... go run cmd/server/main.go

# Test the endpoint
curl -X POST http://localhost:8080/v1/query \
  -H "Content-Type: application/json" \
  -d '{"query": "What is the platform architecture?", "top_k": 4}'
```
