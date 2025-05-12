# Atlas MVP Scaffold (patch‑set 001)

>  Drop these files into the repo root then run `docker compose -f docker-compose.dev.yml up -d` to see “hello‑world” traffic end‑to‑end.

---

## 0 File‑tree

```text
.
├─ docker-compose.dev.yml
├─ scripts/
│  ├─ publish_task.sh
│  └─ index_repo.sh
└─ services/
   ├─ rag-gateway/
   │  ├─ Dockerfile
   │  └─ rag_gateway/
   │     ├─ __init__.py
   │     ├─ main.py
   │     └─ backend.py
   └─ atlas-worker/
      ├─ Dockerfile           # already exists in manual
      └─ atlas/
         ├─ __init__.py
         ├─ main.py
         ├─ bus_client.py
         ├─ rag_client.py
         └─ openai_client.py
```

---

## 1 `docker-compose.dev.yml`

```yaml
version: "3.9"

services:
  qdrant:
    image: qdrant/qdrant:v1.7.3
    volumes:
      - qdrant-data:/qdrant/storage
    ports: [6333:6333]

  redis:
    image: redis:7-alpine
    ports: [6379:6379]

  pubsub:
    image: gcr.io/google.com/cloudsdktool/cloud-sdk:alpine
    command: ["gcloud", "beta", "emulators", "pubsub", "start", "--host-port=0.0.0.0:8681"]
    ports: [8681:8681]

  rag-gateway:
    build: ./services/rag-gateway
    environment:
      QDRANT_URL: http://qdrant:6333
      REDIS_URL: redis://redis:6379/0
    depends_on: [qdrant, redis]
    ports: [8501:8501]

  atlas-worker:
    build: ./services/atlas-worker
    environment:
      OPENAI_API_KEY: "${OPENAI_API_KEY:?err}"
      # --- Supabase ---
      SUPABASE_URL: "${SUPABASE_URL:-http://localhost:54321}"
      SUPABASE_SERVICE_ROLE_KEY: "${SUPABASE_SERVICE_ROLE_KEY:-stub}"
      # --- Pub/Sub ---
      PUBSUB_PROJECT_ID: "${PUBSUB_PROJECT_ID:-atlas-dev}"
      PUBSUB_TOPIC_IN: "architect_in"
      PUBSUB_TOPIC_OUT: "architect_out"
      PUBSUB_EMULATOR_HOST: pubsub:8681
      # --- RAG ---
      RAG_URL: http://rag-gateway:8501
    depends_on: [rag-gateway, pubsub]

volumes:
  qdrant-data:
```

---

## 2 `services/rag-gateway/Dockerfile`

```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY pyproject.toml poetry.lock /app/
RUN pip install poetry==1.8.2 && poetry install --no-root --only main
COPY rag_gateway /app/rag_gateway
CMD ["uvicorn", "rag_gateway.main:app", "--host", "0.0.0.0", "--port", "8501"]
```

### 2.1 `rag_gateway/main.py`

```python
from fastapi import FastAPI
from rag_gateway.backend import embed_batch, query_chat

app = FastAPI()

@app.get("/healthz")
async def health():
    return {"status": "ok"}

@app.post("/v1/query_chat")
async def _query(payload: dict):
    return query_chat(payload["query"], payload.get("top_k", 15))

@app.post("/v1/embed_batch")
async def _embed(payload: list[str]):
    job_id = embed_batch(payload)
    return {"job_id": job_id}
```

### 2.2 `rag_gateway/backend.py` *(minimal stub)*

```python
from typing import List

# TODO: wire real vector DB + encoder

def query_chat(query: str, top_k: int = 15):
    return [{"text": "stub context for: " + query, "similarity": 1.0}]


def embed_batch(docs: List[str]):
    # pretend we off‑loaded a batch‑embed job
    return "job-0001"
```

---

## 3 `services/atlas-worker/atlas/main.py`

```python
import asyncio, json, os
from atlas.bus_client import subscribe, publish
from atlas.rag_client import get_context
from atlas.openai_client import chat

async def handle(msg):
    ctx = get_context(msg["content"])
    reply = await chat(msg["content"], ctx)
    out = {
        **msg,
        "msg_type": "spec",
        "content": reply,
        "metadata": {**msg.get("metadata", {}), "status": "done"}
    }
    await publish(out)

async def main():
    async for raw in subscribe(role="architect"):
        asyncio.create_task(handle(json.loads(raw.data)))

if __name__ == "__main__":
    asyncio.run(main())
```

### 3.1 `atlas/bus_client.py` *(Pub/Sub emulator version)*

```python
import os, asyncio, json
from google.cloud import pubsub_v1

PROJECT = os.getenv("PUBSUB_PROJECT", "atlas-dev")
TOPIC = os.getenv("PUBSUB_TOPIC_OUT", "architect_out")
SUBSCRIPTION = f"{TOPIC}-sub"

publisher = pubsub_v1.PublisherClient()
subscriber = pubsub_v1.SubscriberClient()

async def publish(msg: dict):
    data = json.dumps(msg).encode()
    publisher.publish(publisher.topic_path(PROJECT, TOPIC), data)

async def subscribe(role: str):
    sub_path = subscriber.subscription_path(PROJECT, SUBSCRIPTION)
    flow = asyncio.Queue()

    def _callback(message):
        flow.put_nowait(message)

    subscriber.subscribe(sub_path, callback=_callback)
    while True:
        yield await flow.get()
```

### 3.2 `atlas/rag_client.py`

```python
import os, httpx

RAG_URL = os.getenv("RAG_URL", "http://rag-gateway:8501")

def get_context(question: str):
    r = httpx.post(f"{RAG_URL}/v1/query_chat", json={"query": question, "top_k": 5})
    r.raise_for_status()
    return r.json()
```

### 3.3 `atlas/openai_client.py` *(stub – echoes prompt)*

```python
async def chat(prompt: str, context):
    # TODO: replace with real OpenAI call
    joined_ctx = "\n".join(c["text"] for c in context)
    return f"[ctx]\n{joined_ctx}\n\n[response]\nSpec for: {prompt}"
```

---

## 4 `scripts/publish_task.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

MSG=$(jq -n --arg c "$1" '{role:"architect",msg_type:"chat",content:$c,metadata:{}}')
# Using Pub/Sub emulator REST endpoint
curl -s -X POST "http://localhost:8681/v1/projects/atlas-dev/topics/architect_in:publish" \
  -H "Content-Type: application/json" \
  -d '{"messages":[{"data":"'$(echo -n "$MSG" | base64)'"}]}' | jq .
```

## 5 `scripts/index_repo.sh`

```bash
#!/usr/bin/env bash
set -e
python - <<'PY'
import sys, requests, os, json
RAG_URL = os.getenv("RAG_URL", "http://rag-gateway:8501")
with open(sys.argv[1], 'r') as f:
    docs = f.readlines()
print(requests.post(f"{RAG_URL}/v1/embed_batch", json=docs).json())
PY
```

---

### 6 Quick‑start

```bash
# 1. create a .env file and export essential secrets
cat <<EOF > .env
OPENAI_API_KEY=sk-fake-key
SUPABASE_URL=http://localhost:54321
SUPABASE_SERVICE_ROLE_KEY=super-secret-jwt
PUBSUB_PROJECT_ID=atlas-dev
EOF
export $(grep -v '^#' .env | xargs)

# 2. spin up the dev stack
docker compose -f docker-compose.dev.yml up -d --build

# 3. send a task
./scripts/publish_task.sh "Design a logging ADR"

# 4. watch atlas‑worker logs
docker logs -f $(docker compose ps -q atlas-worker)
```

If everything is wired, the stub spec will appear in the logs, proving end ‑ to ‑ end flow.

---

## 7 Environment Variable Checklist

| Variable                               | Purpose                           | Default (dev)                    |
| -------------------------------------- | --------------------------------- | -------------------------------- |
| `OPENAI_API_KEY`                       | Auth to OpenAI completions        | `sk-*`                           |
| `SUPABASE_URL`                         | Supabase REST endpoint            | `http://localhost:54321`         |
| `SUPABASE_SERVICE_ROLE_KEY`            | Service-role JWT (channel tables) | `stub`                           |
| `PUBSUB_PROJECT_ID`                    | GCP project / emulator namespace  | `atlas-dev`                      |
| `PUBSUB_TOPIC_IN` / `PUBSUB_TOPIC_OUT` | Bus topics                        | `architect_in` / `architect_out` |
| `PUBSUB_EMULATOR_HOST`                 | Host\:port for local Pub/Sub      | `pubsub:8681`                    |
| `RAG_URL`                              | Base URL for RAG gateway          | `http://rag-gateway:8501`        |

Keep production secrets in Docker/K8s Secrets or your vault of choice—never commit real keys into Git.

---

## 8 Dependency Files (Poetry)

### 8.1 `services/rag-gateway/pyproject.toml`

```toml
[tool.poetry]
name = "rag-gateway"
version = "0.1.0"

[tool.poetry.dependencies]
python = "^3.11"
fastapi = "^0.110"
uvicorn = {extras = ["standard"], version = "^0.29"}
qdrant-client = "^1.7"
sentence-transformers = "^2.6"
redis = "^5.0"
httpx = "^0.27"
prometheus-client = "^0.20"

[build-system]
requires = ["poetry-core>=1.8"]
build-backend = "poetry.core.masonry.api"
```

### 8.2 `services/atlas-worker/pyproject.toml`

```toml
[tool.poetry]
name = "atlas-worker"
version = "0.1.0"

[tool.poetry.dependencies]
python = "^3.11"
openai = "^1.20"
fastapi = "^0.110"
google-cloud-pubsub = "^2.20"
httpx = "^0.27"
prometheus-client = "^0.20"
tenacity = "^8.2"
asyncio = "^3.4"

[build-system]
requires = ["poetry-core>=1.8"]
build-backend = "poetry.core.masonry.api"
```

Run `poetry install --no-root --only main` inside each service directory to generate the corresponding `poetry.lock` file.

---

## 9 Supabase Migration Script

Add `migrations/0001_supabase_channels.sql`:

```sql
create publication if not exists architect_bus;

create table if not exists public.architect_in (
  id uuid primary key default gen_random_uuid(),
  data jsonb
);

create table if not exists public.architect_out (
  id uuid primary key default gen_random_uuid(),
  data jsonb
);

alter publication architect_bus add table public.architect_in, public.architect_out;
```

Apply via:

```bash
psql $SUPABASE_URL < migrations/0001_supabase_channels.sql
```

---

## 10 Prometheus Metrics Wiring

Create `services/atlas-worker/atlas/metrics.py`:

```python
from prometheus_client import Counter, Histogram, start_http_server

atlas_tokens_total = Counter("atlas_tokens_total", "Total tokens used by Atlas")
run_seconds = Histogram("atlas_run_seconds", "Latency of Atlas run")

start_http_server(8000)  # exporter
```

Hook it in `atlas/main.py`:

```python
from atlas.metrics import run_seconds
...
async def handle(msg):
    with run_seconds.time():
        ...  # existing logic
```

Expose port 8000 in `docker-compose.dev.yml` so Prometheus can scrape `atlas-worker`.

---

## 11 Next Steps

1. **Secrets** – store `OPENAI_API_KEY` and `SUPABASE_SERVICE_ROLE_KEY` using Docker/K8s secrets; mount as files or env.
2. **Replace stubs** – integrate Qdrant + Sentence‑Transformers in `rag_gateway/backend.py` and swap the OpenAI call in `openai_client.py` (the fallback loop is already scaffolded).
3. **CI smoke test** – add GitHub Action to launch the dev stack, run `./scripts/publish_task.sh`, and assert response via Pub/Sub REST.
4. **Docs** – update project README and internal wiki with the new commands and environment variables.
