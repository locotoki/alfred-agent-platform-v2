# RAG Project – Supplementary Design Docs

# RAG Project – Supplementary Design Docs

> Purpose : Capture every remaining topic discussed but not yet formalised into an artifact, so the solopreneur (you) and Claude Code have one last reference bundle.
> 
> 
> **Revision** : 0.1 – 2025‑05‑09
> 

---

## 1 Real‑Time Fetcher Pattern (Internet Data Access)

### 1.1 Problem & Scope

LLMs occasionally need live FX rates, tax tables, or commodity prices. Direct internet calls from GPT sessions violate privacy and auditability. We therefore introduce a **deterministic, allow‑listed fetcher tool**.

### 1.2 Design

| Component | Detail |
| --- | --- |
| **Service** | Tiny FastAPI container `realtime-fetcher` on `bond0:8100` |
| **Allow‑list** | Env `ALLOWED_DOMAINS=ecb.europa.eu,api.exchangerate.host,treasury.gov` |
| **Schema** | ```json |
| {"rate":float,"base":str,"timestamp":int} |  |

```
| **Cache** | Qdrant collection `live-cache` TTL 6 h (HNSW m=8, ef=64) |
| **Audit** | Conductor baggage `ext_url`, `sha256`, `fetched_at` |

#### 1.3 FastAPI stub
```python
from fastapi import FastAPI, HTTPException
import requests, hashlib, time, os
from pydantic import BaseModel

ALLOWED = set(os.getenv("ALLOWED_DOMAINS", "").split(","))
app = FastAPI()

class FXResp(BaseModel):
  rate: float
  base: str
  timestamp: int

@app.get("/fetch", response_model=FXResp)
async def fetch(url: str):
  host = url.split("/")[2]
  if host not in ALLOWED:
      raise HTTPException(400, "domain not allowed")
  r = requests.get(url, timeout=5)
  r.raise_for_status()
  j = r.json()
  if "rate" not in j:
      raise HTTPException(422, "invalid schema")
  # optional: write to live‑cache Qdrant here
  return FXResp(rate=j["rate"], base=j.get("base","EUR"), timestamp=int(time.time()))

```

---

## 2 Evaluation & Quality Harness

### 2.1 Golden‑set repo structure

```
 eval/
   golden.jsonl        # {"query":"...","answers":["…"]}
   run_eval.py         # ragas or RAG‑AS‑QA runner
   prom_push.py        # pushes recall@k metric

```

### 2.2 CI Job (GitHub Actions)

```yaml
- name: Nightly RAG eval
  schedule: [cron: '0 3 * * *']
  steps:
    - uses: actions/checkout@v4
    - run: pip install ragas prometheus_client
    - run: python eval/run_eval.py --gateway ${{ secrets.GW_URL }}

```

---

## 3 CI/CD Hardening Extras

| Add‑on | Snippet |
| --- | --- |
| **Pre‑commit** | `.pre‑commit‑config.yaml` with black, isort, ruff, markdown‑lint |
| **Smoke‑up job** | `docker compose -f docker-compose.rag.yml up -d && curl -f http://localhost:8080/healthz` |
| **Dependabot** | `dependabot.yml` tracking pip & docker manifests weekly |
| **SBOM scan** | `trivy sbom --format cyclonedx -o sbom.json .` + upload‑artifact |

---

## 4 Makefile (Developer Convenience)

```
up:            ## start full stack
	docker compose -f docker-compose.yml -f docker-compose.rag.yml up -d

eval:          ## run golden‑set eval
	python eval/run_eval.py --gateway $$RAG_GATEWAY_URL

backup:
	./scripts/backup_qdrant.sh

publish-py:
	python -m build ./packages/rag-client && twine upload dist/*

```

`make help` prints target descriptions via a Bash awk trick.

---

## 5 Personal Automation Playbook (Tier 1‑3)

| Tier | Example automations | Trigger | Agent(s) | Script / cron |
| --- | --- | --- | --- | --- |
| **1 Info-on-demand** | “Find my car VIN” | Chat | Alfred‑bot | none |
| **2 Proactive reminders** | Subscription renewals | Weekly cron | Fin‑Tax + Alfred | `cron/renewal_alert.py` |
| **3 Dashboards** | Monthly spend chart | Nightly job | Fin‑Tax | `grafana JSON datasource` |

---

## 6 Solo Founder “Company‑of‑One” Checklist

| Milestone | Agent mix | Human step |
| --- | --- | --- |
| MVP wireframes | Design‑Drafter | Approve Figma link |
| Alpha ship | Code‑Smith + Ops‑Pilot | Merge PRs |
| Stripe live | BizDev‑Bot + Finance‑Clerk | Verify payouts |
| Public launch | Growth‑Bot | Tweet thread |
| 10 k MRR | Add fractional CS human | Interview candidates |

---

## 7 Digital‑Content SaaS Cost Sheet (CSV‑ready)

```
Item,Unit Cost,Monthly Qty,Monthly Cost (USD)
GPT-4o prompt,$2.50/1M tkn,2M,5
GPT-4o output,$10/1M tkn,2M,20
GPU power,$0.12/kWh,216kWh,26
VPS,Hetzner CX42,1,35
Storage,Wasabi,$6/TB,0.5TB,3
Email,Postmark,10k emails,10
Total,,,99

```

---

## 8 Ingestion Event & Schema Reference

### 8.1 Redis Stream Names

```
doc.ingest.personal.file
...

```