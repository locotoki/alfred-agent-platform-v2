# Atlas (Infra‑Architect Agent) – Deployment Manual

> Version 0.1 ‑ May 2025
> 
> 
> This guide shows how to bring up Atlas as a production‑ready architect agent inside the Alfred Agent Platform v2 stack. It assumes you already run Supabase, Pub/Sub (or the local emulator), Qdrant, and have a GitHub repo for source control.
> 

---

## 1 Overview

Atlas is a stateless Python worker that:

1. Listens for `architect` role messages on the event‑bus.
2. Retrieves relevant knowledge via the RAG Service.
3. Calls the configured OpenAI model (GPT‑4.1 ↔ o3 ↔ o1‑pro).
4. Publishes architecture specs back to the bus for Claude‑Code and UI clients.

```
Supabase ▶ architect_in  ─┐
                          │ (router)  ➜  Pub/Sub topic  ➜  atlas‑worker
atlas‑worker ▶ architect_out ─┘

```

---

### 1.1 Crew Composition

| Role | Included in MVP? | Merge candidate | Add when … |
| --- | --- | --- | --- |
| **Atlas** (Architect) | **Yes** | — | Day‑1 requirement. |
| **Claude‑Code** (Implementer) | **Yes** | Can moonlight as **Forge** for basic builds/tests. | Day‑1 requirement. |
| **Forge** (Builder/Runner) | Optional | Often merged into Claude‑Code. | Hands‑free cloud provisioning or multi‑env roll‑outs needed. |
| **Sentinel** (Validator) | Optional | Could be a validation node inside Atlas DAG. | Automated gatekeeping / SLO enforcement required. |
| **Conductor** (Glue/orchestrator) | Already covered by LangGraph DAG + router | — | Only if static DAGs aren’t enough and you need dynamic scheduling. |

Start with the two bold roles.  Promote Forge or Sentinel only after their absence is felt.

---

## 2 Minimum Prerequisites

| Component | Requirement |
| --- | --- |
| **Docker Engine** | ≥ 24.x & Docker Compose ≥ 2.24 |
| **Python (alt)** | 3.11.x (only if running bare‑metal) |
| **CPU / RAM** | 2 vCPU, 4 GiB |
| **Disk** | 1 GiB free |
| **Outbound 443** | OpenAI API, Supabase, Pub/Sub |

### Required environment variables

```
OPENAI_API_KEY=
OPENAI_MODEL=gpt-4.1     # default
SUPABASE_URL=
SUPABASE_SERVICE_ROLE_KEY=
PUBSUB_PROJECT_ID=
PUBSUB_TOPIC_OUT=architect_out
TOKEN_BUDGET_PER_RUN=12000   # optional
DAILY_TOKEN_BUDGET=250000    # optional

```

Store secrets in `.env`, Docker secrets, or your vault of choice.

---

## 3 Single‑Node Quick‑Start

```bash
# 1 Clone repo and copy env
$ git clone https://github.com/locotoki/alfred-agent-platform-v2.git
$ cd alfred-agent-platform-v2
$ cp .env.example .env   # edit the variables listed above

# 2 Start the trimmed stack (Supabase, Qdrant, Pub/Sub‑emu, RAG, Atlas)
$ docker compose -f docker-compose.min.yml up -d

# 3 Index initial docs so RAG has content
$ ./scripts/index_repo.sh docs/

# 4 Send a test task (architect chat message)
$ ./scripts/publish_task.sh "Design a minimal CI pipeline"

# 5 Tail the reply
$ docker logs -f atlas-worker | grep architect_out

```

If you see a streamed spec in the logs, Atlas is alive.

---

## 4 Building the Docker Image

`services/atlas-worker/Dockerfile`:

```
FROM python:3.11-slim
ENV PIP_ROOT_USER_ACTION=ignore
RUN apt-get update && apt-get install -y gcc git && rm -rf /var/lib/apt/lists/*
COPY pyproject.toml poetry.lock /app/
WORKDIR /app
RUN pip install poetry==1.8.2 && poetry install --no-root --only main
COPY atlas /app/atlas
CMD ["python", "-m", "atlas.main"]

```

Key deps in `pyproject.toml`:

```toml
openai = "^1.20"
google-cloud-pubsub = "^2.20"
supabase = "^2.1"
prometheus-client = "^0.20"
tenacity = "^8.2"

```

---

## 5 Event‑Bus Contracts

```
{
  "task_id": "uuid4",
  "role": "architect",
  "msg_type": "chat|spec|control",
  "content": "…prompt or reply…",
  "metadata": {
    "tokens": 0,
    "model": "gpt-4.1",
    "parent_id": null,
    "status": "in_progress"
  }
}

```

*Architect publishes* to **`architect_out`**.  Claude‑Code and UI clients subscribe.

---

## 6 GitHub App Integration *(Optional but Recommended)*

GitHub Issues and Pull‑Requests give you an auditable trail and CI hooks, but **Atlas and Claude‑Code can still collaborate autonomously via Supabase ↔ Pub/Sub alone.**  Skip this section if you don’t need PR workflows yet.

1. **Settings → Developer settings → GitHub Apps → *New GitHub App***. Name: `alfred-atlas-bot`.
2. **Webhook URL**: `https://<your-router-domain>/github`
    
    • **Local testing** – run `ngrok http 8000` (or Cloudflare Tunnel) and paste the generated HTTPS URL, e.g. `https://fluffy-otter.ngrok.io/github`.
    
    • **Production** – use the DNS name or load‑balancer where your router micro‑service is exposed, e.g. `https://router.dnv.ai/github`.
    
3. **Repo permissions**: Metadata RO, Issues RW, PR RW, Contents RW.
4. Enable Webhook events: Issues, Issue‑comment, PR, PR‑review.
5. Generate a **private key (.pem)**; note the **App ID**.
6. Install the app on repo `alfred-agent-platform-v2` (select repos → Install). Copy the **Installation ID**.
7. Mount the `.pem` and set:

```bash
GITHUB_APP_ID=123456
GITHUB_INSTALLATION_ID=987654
GITHUB_WEBHOOK_SECRET=********

```

The router service exchanges the App JWT for an installation token and lets Atlas/Claude‑Code create Issues & PRs.

---

## 7 RAG Service Wiring Service Wiring

- Gateway already running at `http://rag-gateway:8501`.
- Atlas calls `/v1/query_chat` with `top_k=15` unless `question + context ≤ TOKEN_BUDGET_PER_RUN`.
- Retrieval wrapper (`atlas/rag_client.py`) caches results in Redis (TTL 1 h).
- Nightly cron re‑indexes `docs/` via `/v1/embed_batch`.

---

## 8 Observability & Guard‑Rails

| Metric | Default alert |
| --- | --- |
| `atlas_tokens_total` | Warn at 80 % of `DAILY_TOKEN_BUDGET`, page at 100 %. |
| `atlas_run_seconds` (histogram) | Page if p95 > 10 s. |
| Pub/Sub dead‑letters | Warn if ≥ 1 msg / 5 min. |

Prometheus scrapes `http://atlas-worker:8000/metrics`; Grafana dashboard `dashboards/atlas.json` shows live token spend.

---

## 9 Operational Tasks

| Frequency | Task | Command |
| --- | --- | --- |
| daily | Rotate RAG index cronjob logs | `docker logs --since 24h rag-embed-worker` |
| weekly | Review token budget chart | Grafana dashboard → Atlas panel |
| quarterly | Rotate `OPENAI_API_KEY`, GitHub App key, Supabase JWT secret | Update secrets + restart stack |

---

## 10 Troubleshooting

| Symptom | Checklist |
| --- | --- |
| **Atlas container restarts** | `docker logs atlas-worker` → common: invalid OpenAI key, token limit. |
| **No reply in Slack** | Verify `architect_out` channel with Supabase Studio; check router logs. |
| **High token spend** | Lower `top_k`, switch `OPENAI_MODEL` to `gpt-4o-mini` for drafts. |

---

## 11 Next Steps (Phase 2)

- Add hybrid re‑ranke­r side‑car to RAG.
- Turn `index_repo.sh` into a long‑running embed‑worker subscribed to `docs.added` events.
- Extend event schema with streaming chunk fields for large replies.
- Create CI test (`pytest`) to fail PR if Atlas tokens > per‑run budget.

---

### Appendix A – Supabase Channel DDL

```sql
create publication architect_bus;
create table public.architect_in  (data jsonb);
create table public.architect_out (data jsonb);
alter publication architect_bus add table public.architect_in, public.architect_out;

```

### Appendix B – Example Implementation Task Issue (GitHub)

```
## Context
Need Terraform module for Supabase S3.

## Technical Spec
…

```

Atlas will convert the markdown into a `chat` message and reply back with a *spec*.

---

© 2025 locotoki / Digital Native Ventures – MIT License