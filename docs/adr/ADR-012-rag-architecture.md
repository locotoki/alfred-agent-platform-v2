# ADR-012 · Retrieval-Augmented Generation Architecture
*Status: Draft* — *5 Jun 2025 target for acceptance*

## Context
We need a minimal but extensible Retrieval-Augmented Generation (RAG) pipeline for **agent-core MVP** that satisfies:

* **p95 latency < 300 ms** (same as GA SLO)
* Citation-backed answers with ≥ 85 % groundedness on eval set
* Local developer workflow (Compose) and prod parity (Helm)

## Decision
* **Ingest path**: Nightly batch → chunker (Markdown + PDF) → OpenAI ada-002 embeddings → pgvector.
* **Query path**: User prompt → embed → top-k (k = 5) cosine search → prompt composer → GPT-4o answer.
* **Citation strategy**: Return top-k chunks ≥ score_threshold in answer appendix.
* **Language**: Python 3.11; orchestration via FastAPI service.

> Details TBD in follow-up ADR-013 (citation formatting).

## Consequences
* Locks us into pgvector; swapping to Qdrant post-GA becomes migration work.
* Streaming generation pushed to v0.10.x.
* Embedding cost ≈ \$0.06 per 1 K docs per day.

## Alternatives considered
1. **Milvus** — heavy footprint.
2. **Self-hosted OpenSearch** — slower vector search at small scale.

_Append further discussion here._
