# RAG Service – Supplementary Toolkit

# RAG Service – Supplementary Toolkit

> Purpose All the smaller, ops‑oriented artefacts we discussed but had not yet codified. Copy each file into your repo exactly as shown (paths in the headings).
> 

---

## 1 Dev‑Quality Automation

### 1.1 `.pre‑commit‑config.yaml`

```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.12.1
    hooks:
      - id: black
  - repo: https://github.com/pycqa/isort
    rev: 5.13.2
    hooks:
      - id: isort
  - repo: https://github.com/PyCQA/flake8
    rev: 6.1.0
    hooks:
      - id: flake8
  - repo: https://github.com/markdownlint/markdownlint
    rev: v0.12.0
    hooks:
      - id: markdownlint

```

Activate with:

```bash
pipx install pre‑commit && pre‑commit install

```

### 1.2 `Makefile`

```makefile
.PHONY: up down restart logs test lint publish sbom
COMPOSE=docker compose -f docker-compose.yml -f docker-compose.override.rag.yml
up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart rag-gateway rag-embed-gpu

logs:
	$(COMPOSE) logs -f --tail=100

test:
	pytest -q tests

lint:
	pre-commit run --all-files

publish:
	pnpm --filter @acme/rag-client run build && pnpm publish --access public

sbom:
	trivy fs --format cyclonedx --output sbom.json .

```

---

## 2 Continuous Integration

### 2.1 `.github/workflows/ci-smoke.yml`

```yaml
name: CI Smoke‑up
on:
  pull_request:
    branches: [ main ]
jobs:
  smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build & boot stack
        run: docker compose -f docker-compose.yml -f docker-compose.override.rag.yml up -d
      - name: Health probes
        run: |
          curl --fail http://localhost:8080/healthz
          curl --fail http://localhost:6333/collections
      - name: Shut down
        run: docker compose down

```

### 2.2 `.github/workflows/security.yml`

```yaml
name: Security Scan & SBOM
on:
  push:
    branches: [ main ]
jobs:
  trivy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: aquasecurity/trivy-action@v0.16.0
        with:
          image-ref: qdrant/qdrant:latest
          format: table
          exit-code: 1
      - name: Generate SBOM
        run: trivy fs --format cyclonedx --output sbom.json .
      - name: Upload artefact
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: sbom.json

```

### 2.3 `.github/renovate.json`

```
{
  "extends": ["config:base"],
  "schedule": ["at 06:00 on monday"],
  "packageRules": [
    { "matchDepTypes": ["devDependencies"], "groupName": "dev‑deps" }
  ]
}

```

---

## 3 Ops / SRE Artefacts

### 3.1 `ops/first_90_days.md`

```markdown
# First 90 Days – Ops Checklist
Week 1: ✔ Verify nightly Qdrant snapshot
Week 2: ✔ Grafana alert channels (PagerDuty)
Week 3: ✔ Trivy baseline scan – no HIGH vulns
Week 4: Automate JWT rotation script
Month 2: Load‑test 500 rps with k6
Month 3: Failover drill – restore snapshot to staging box

```

### 3.2 `monitoring/grafana_dashboards/rag_overview.json`

*(trimmed to essentials)*

```json
{
  "title": "RAG Overview",
  "panels": [
    { "type": "graph", "title": "Gateway Latency P95", "targets": [
        { "expr": "histogram_quantile(0.95, sum(rate(rag_gateway_request_latency_bucket[5m])) by (le))" }
      ]
    },
    { "type": "stat", "title": "Vector Count", "targets": [
        { "expr": "sum(qdrant_points{collection=~\"tenant:.*:personal\"})" }
      ]
    }
  ]
}

```

---

## 4 Quality & Eval Harness

### 4.1 `eval/golden.jsonl`

```
{"query":"annual subscription cost","answers":["$264"],"context":"Invoice #123 Spotify $22 12‑month"}
{"query":"next passport expiry","answers":["12‑Aug‑2027"],"context":"Passport expiry 12‑Aug‑2027"}
{"query":"March gross salary","answers":["€8200"],"context":"March 2025 salary €8200 gross"}
{"query":"Lufthansa airfare VAT","answers":["23%"],"context":"Invoice Lufthansa VAT 23%"}
{"query":"Portugal‑US treaty royalty rate","answers":["10%"],"context":"PT‑US treaty Art 12 10% withholding"}

```

Run nightly with:

```bash
ragas evaluate eval/golden.jsonl --gateway http://gateway:8080 > eval/report.html

```

---

## 5 Policy Guard‑rails

### 5.1 `policy/approval_guard.rego`

```
package rag.approval

# Require human confirm for outbound payments > $300
require_approval[action] {
  action.type == "stripe_refund"
  action.amount > 300
}

```

Use `opa eval` in agent chain before executing external mutation.

---

## 6 Real‑time Fetch Micro‑service

### 6.1 `services/realtime_fetch.py`

```python
from fastapi import FastAPI, HTTPException
import httpx, hashlib, time, os
from pydantic import BaseModel, AnyUrl

ALLOWED = set(os.getenv("ALLOWED_DOMAINS", "ecb.europa.eu,api.exchangerate.host").split(','))
app = FastAPI()

class FetchResp(BaseModel):
    url: AnyUrl
    sha256: str
    fetched_at: int
    payload: dict

@app.get("/fetch", response_model=FetchResp)
async def fetch(url: AnyUrl):
    if url.host not in ALLOWED:
        raise HTTPException(400, "domain not allowed")
    async with httpx.AsyncClient(timeout=5) as client:
        r = await client.get(str(url))
    data = r.json()
    return FetchResp(url=url, sha256=hashlib.sha256(r.content).hexdigest(), fetched_at=int(time.time()), payload=data)

```

Add to compose:

```yaml
realtime-fetch:
  build: ./services
  environment:
    - ALLOWED_DOMAINS=ecb.europa.eu,api.exchangerate.host
  ports: ["8085:8000"]

```

---

## 7 Feedback UI Stub

### 7.1 `ui/FeedbackThumbs.tsx`

```tsx
import { ThumbsUp, ThumbsDown } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";

export default function FeedbackThumbs({ traceId }: { traceId: string }) {
  const [sent, setSent] = useState(false);
  if (sent) return <span className="text-sm">Thanks!</span>;
  return (
    <div className="flex gap-2">
      <Button size="icon" onClick={() => send(true)}><ThumbsUp /></Button>
      <Button size="icon" onClick={() => send(false)}><ThumbsDown /></Button>
    </div>
  );
  async function send(positive: boolean) {
    await fetch("/api/feedback", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ traceId, positive })
    });
    setSent(true);
  }
}

```

Server route stores feedback in `rag.feedback` topic.

---

## 8 Temporal Workflow Example

### 8.1 `workflows/subscription_reminder.py`

```python
from temporalio import workflow, activity
from datetime import timedelta
from rag_client_retriever import RAGClientRetriever

@activity.defn
async def query_subs(user_id: str):
    retriever = RAGClientRetriever(user_id, "personal", filters={"type":"invoice"}, top_k=10)
    docs = retriever.get_relevant_documents("renew next 30 days")
    return [d.metadata for d in docs]

@workflow.defn
class ReminderWF:
    @workflow.run
    async def run(self, user_id: str):
        while True:
            invoices = await workflow.execute_activity(query_subs, user_id, schedule_to_close_timeout=60)
            if invoices:
                await workflow.execute_activity(send_slack_dm, invoices, schedule_to_close_timeout=30)
            await workflow.sleep(timedelta(days=1))

```

---

## 9 Grafana Alert Rule YAML

### 9.1 `monitoring/alerts/rag_alerts.yaml`

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: rag-alerts
spec:
  groups:
    - name: rag-gateway
      rules:
        - alert: RAGHighLatency
          expr: histogram_quantile(0.95, sum(rate(rag_gateway_request_latency_bucket[5m])) by (le)) > 0.25
          for: 10m
          labels:
            severity: page
          annotations:
            summary: "RAG Gateway high latency P95 > 250ms"
            description: "Investigate embed worker or Qdrant load."

```

---

## 10 Quick reference index

| Folder | Purpose |
| --- | --- |
| `.github/workflows/` | CI, security scan, Renovate bot |
| `policy/` | OPA rego guard‑rails |
| `monitoring/` | Dashboards + alert rules |
| `ops/` | Runbooks, 90‑day checklist |
| `services/` | Real‑time fetch micro‑service |
| `ui/` | React components (feedback) |
| `eval/` | Golden QA set & nightly script |

*Copy these into your repository to complete the end‑to‑end operational scaffolding.*