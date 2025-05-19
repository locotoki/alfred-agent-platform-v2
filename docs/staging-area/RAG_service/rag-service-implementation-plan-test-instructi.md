# RAG Service – Implementation Plan & Test Instructions

# RAG Service – Implementation Plan & Test Instructions

> Audience: Solo developer working inside Claude Code. All commands assume Ubuntu 22.04 host with Docker ≥ 24, NVIDIA runtime, and existing alfred-agent-platform-v2 compose project.
>
>
> **Convention**: Replace `$❯` with your shell prompt. All code blocks are copy‑pasta‑ready for Claude Code’s terminal.
>

---

## Phase 0 – Environment Prep *(½ day)*

| Step | Action | Test Instruction |
| --- | --- | --- |
| 0.1 | Pull latest infra images | `$❯ docker pull qdrant/qdrant:latest && docker pull supabase/postgres:15`Expect no errors. |
| 0.2 | Verify GPU driver & runtime | `$❯ nvidia-smi` → 3080 Ti listed.`$❯ docker run --rm --gpus all nvidia/cuda:12.3.0-base nvidia-smi` |
| 0.3 | Clone RAG repo scaffold | `$❯ git clone https://github.com/yourorg/rag-stack && cd rag-stack` |

---

## Phase 1 – Compose Stack Bootstrap *(1 day)*

| Step | Action | Test Instruction |
| --- | --- | --- |
| 1.1 | Copy `docker-compose.rag.yml` from RFC §4.2 | `$❯ cp ../docs/docker-compose.rag.yml .` |
| 1.2 | Start stack | `$❯ docker compose -f docker-compose.rag.yml up -d` |
| 1.3 | Health check containers | `$❯ docker compose ps` → STATUS `running` for `rag-gateway`, `rag-embed-gpu`, `minio`… |
| 1.4 | Gateway smoke test | `$❯ curl -s http://localhost:8080/healthz` → `{ "status": "ok" }` |

---

## Phase 2 – Qdrant Collections & Seed Data *(½ day)*

| Step | Action | Test Instruction |
| --- | --- | --- |
| 2.1 | Exec bootstrap script | `$❯ docker compose exec rag-gateway /scripts/init_qdrant.sh` |
| 2.2 | Verify collections | `$❯ curl -s [http://localhost:6333/collections](http://localhost:6333/collections) |
| 2.3 | Index sample doc | `$❯ ./scripts/index_sample.sh docs/hello_world.md` |
| 2.4 | Query sample | `$❯ ./scripts/query.sh "hello"` → returns hit with score ≈ 0.9 |

---

## Phase 3 – Embedding Worker Validation *(½ day)*

| Step | Action | Test Instruction |
| --- | --- | --- |
| 3.1 | Real‑time embed API | `$❯ curl -s -X POST [http://localhost:8080/v1/embed](http://localhost:8080/v1/embed) -d '{"texts":["Claude is helpful" ]}' |
| 3.2 | GPU utilisation | `$❯ nvidia-smi --query-compute-apps=name,utilization.gpu --format=csv` while step 3.1 runs – see util > 20 % |

---

## Phase 4 – Hybrid Search & Re‑Rank *(1 day)*

| Step | Action | Test Instruction |
| --- | --- | --- |
| 4.1 | Enable BM25 index | `$❯ psql supabase -c "CREATE INDEX idx_bm25 ON documents USING gin(to_tsvector('english', content));"` |
| 4.2 | Start reranker | `$❯ docker compose up -d rag-rerank-gpu` |
| 4.3 | Query with hybrid | `$❯ ./scripts/query.sh "vector and lexical" --hybrid` → payload `hybrid=true` in Gateway logs |
| 4.4 | Check rerank latency | `$❯ docker logs --tail 20 rag-rerank-gpu` shows `<110ms>` per batch |

---

## Phase 5 – JWT & ACL Verification *(½ day)*

| Step | Action | Test Instruction |
| --- | --- | --- |
| 5.1 | Generate test tokens | `$❯ ./scripts/mint_jwt.sh personal user123` & `business acme-org` |
| 5.2 | Personal namespace read | `$❯ ./scripts/query.sh "private data" --jwt personal.jwt` returns doc id `tenant:user123:personal` |
| 5.3 | Cross‑persona block | `$❯ ./scripts/query.sh "private data" --jwt business.jwt` → HTTP 403 |

---

## Phase 6 – Client SDK Smoke Tests *(½ day)*

| Step | Action | Test Instruction |
| --- | --- | --- |
| 6.1 | Python SDK | ```python |
| from rag_client_retriever import RAGClientRetriever |  |  |
| retriever = RAGClientRetriever(tenant_id="acme", persona="business", top_k=3) |  |  |
| print(retriever.get_relevant_documents("hello")) |  |  |

```
| 6.2 | TypeScript SDK | `$❯ node examples/ts-sdk-demo.mjs` → prints JSON hits |

---
## Phase 7 – Observability & Alerting  *(1 day)*
| Step | Action | Test Instruction |
|------|--------|------------------|
| 7.1 | Prometheus targets up | Grafana → **Prometheus > Status > Targets** shows `UP` for `rag-gateway` and `rag-rerank` |
| 7.2 | Graph latency SLI | Grafana dash “RAG Overview” panel `query_latency_p95` < 200 ms |
| 7.3 | Alert rule test | `curl -X POST grafana:3000/api/alertmanager/test` – alert fires in Slack test channel |

---
## Phase 8 – Cold‑Tier Archive Flow  *(1 day)*
| Step | Action | Test Instruction |
|------|--------|------------------|
| 8.1 | Force archive day 91 | `$❯ python scripts/fast_forward_archival.py 91` (sets `updated_at` back‑date) |
| 8.2 | Run archival job | `$❯ docker compose exec rag-ingest-worker python archival_worker.py --once` |
| 8.3 | Check MinIO bucket | `$❯ mc ls minio/rag-personal-archive/user123/` shows archived object |
| 8.4 | Rehydrate | `$❯ ./scripts/query.sh "archived fact" --jwt personal.jwt` → triggers on‑demand embed, Gateway log `rehydrate=true` |

---
## Phase 9 – Evaluation Harness  *(1 day)*
| Step | Action | Test Instruction |
|------|--------|------------------|
| 9.1 | Install Ragas | `$❯ pip install ragas` |
| 9.2 | Run golden set | `$❯ make test-rag` – outputs precision ≥ 0.70 |
| 9.3 | Export metric | Prometheus metric `rag_eval_precision` appears in scrape |

---
## Phase 10 – Docs & Hand‑off  *(½ day)*
| Step | Action | Test Instruction |
|------|--------|------------------|
| 10.1 | Generate README badges | `$❯ ./scripts/gen_badges.sh` – CI, Docker size, coverage badges updated |
| 10.2 | Publish npm package | `$❯ pnpm publish -r --access public` – tag v0.1 appears on npm |
| 10.3 | Merge PR & tag release | GitHub Actions pipeline green → Docker images pushed to GHCR |

---
### Time‑box summary
| Phase | Effort |
|-------|--------|
| 0 – Environment Prep | 0.5 d |
| 1 – Compose Bootstrap | 1.0 d |
| 2 – Collections Seed | 0.5 d |
| 3 – Embed Validation | 0.5 d |
| 4 – Hybrid + Re‑rank | 1.0 d |
| 5 – Auth & ACL | 0.5 d |
| 6 – SDK Tests | 0.5 d |
| 7 – Observability | 1.0 d |
| 8 – Cold‑Tier | 1.0 d |
| 9 – Evaluation | 1.0 d |
|10 – Docs & Release | 0.5 d |
| **Total** | **8 dev‑days** |

---
### Appendix – Claude Code Tips
* Use **Ctrl ⇧ Enter** to run multi‑line commands in the terminal panel.
* Drag‑drop JSON or YAML output into the editor → auto‑formats for inspection.
* Split terminal ⇆ editor panes (`⌘ \`) when comparing logs vs code.

---
_End of plan – revisit after Phase 3 for status review._

```
