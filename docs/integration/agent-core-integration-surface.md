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

---

## 5 · Integration-asset tracker
| Component | Status | PR / Branch |
|-----------|--------|-------------|
| Vector schema migration | Merged | #336 |
| Ingest CLI & indexer | CI-red (fixing) | #339 |
| Retrieval API & RAG loop | PR to open | `feat/retrieval-endpoint` |
| Perf harness (Locust) | Scaffolding | `perf/harness-t1` |
| Observability dashboard | Pending |  |
| UI chat panel | Pending |  |

**Update this table whenever a PR merges or an interface changes.**

