# Agent-core Integration Surface
*Single source of truth for all cross-track interfaces* (generated 23 May 2025).

## 1 · Vector-store schema (`documents`)
 < /dev/null |  column    | type            | notes                                             |
|-----------|-----------------|---------------------------------------------------|
| `id`      | `uuid` **PK**   | v4 from indexer                                   |
| `content` | `text`          | raw markdown / txt                                |
| `embedding` | `vector(1536)` | cosine distance – OpenAI `text-embedding-3-small` |
| `metadata` | `jsonb`        | arbitrary key-value pairs                         |

**Indexes**
* `IVFFLAT` on **embedding** (`lists=200`)
* `GIN` on full-text column `ts`

---

## 2 · `EmbeddingRepo` interface (Go)
```go
type EmbeddingRepo interface {
    UpsertEmbeddings(ctx context.Context, docs []DocWithEmbedding) error
    Search(ctx context.Context, query Embedding, topK int) ([]SearchHit, error)
}
```

---

## 3 · RAG Retrieval API
**POST /v1/query**

Request
```json
{
  "query": "When is GA v3.0.0?",
  "top_k": 4
}
```

Response
```json
{
  "answer": "GA is targeted for 11 July 2025 [^1]",
  "citations": [
    { "id": "1433d0…", "excerpt": "GA v3.0.0 — 11 Jul 2025" }
  ]
}
```

Footnote numbers in `answer` map to the `citations` array.

---

## 4 · Observability hooks
| Metric | Type | Labels |
|--------|------|--------|
| `embedding_repo_latency_seconds` | Histogram | `op` = `search` \\| `upsert` |
| `http_server_request_duration_seconds` | Histogram | `route`, `status` |
| `retrieval_requests_total` | Counter | - |
| `retrieval_errors_total` | Counter | `kind` = `embedding` \\| `search` |
| `retrieval_latency_ms` | Histogram | - |
| `openai_tokens_total` | Counter | - |

---

## 5 · Integration-asset tracker
| Component | Status | PR / Branch |
|-----------|--------|-------------|
| Vector schema migration | **Merged** | #336 |
| Ingest CLI & indexer | **Merged** | #339 |
| Retrieval API & RAG loop | **Merged** | #343 |
| Test & Perf harness | **Merged** | #345 |
| Observability dashboard | Pending |  |
| UI chat panel | Pending |  |

**Update this table whenever a PR merges or an interface changes.**

---

## 6 · Live Examples

### Retrieval Endpoint Test
```bash
# Basic query
curl -X POST http://localhost:8080/v1/query \
  -H "Content-Type: application/json" \
  -d '{
    "query": "What is the EmbeddingRepo interface?",
    "top_k": 5
  }'

# Response format
{
  "answer": "The EmbeddingRepo interface is a Go interface that provides methods for upserting document embeddings and searching for similar documents using vector similarity [^1]",
  "citations": [
    {
      "id": "1433d0ef-89ab-4567-bcde-f0123456789a",
      "excerpt": "type EmbeddingRepo interface { UpsertEmbeddings(ctx context.Context, docs []DocWithEmbedding) error..."
    }
  ]
}
```

### Metrics Endpoint
```bash
curl -s http://localhost:8080/metrics | grep retrieval_
# retrieval_requests_total 42
# retrieval_errors_total{kind="embedding"} 0
# retrieval_errors_total{kind="search"} 1
# retrieval_latency_ms_bucket{le="10"} 5
# retrieval_latency_ms_bucket{le="20"} 12
```

### Performance Testing
```bash
# Run performance harness (10 RPS for 60s)
python3 perf/harness_scaffold.py

# Expected output:
# p95: 245.32ms ✅
# Error rate: 0.15% ✅
```
