# RAG Service – Add‑On Artifacts

# RAG Service – Add‑On Artifacts

> Purpose : Capture the supporting dev‑experience and ops files that were discussed but not yet codified.
> 
> 
> These snippets can be copied verbatim into the repo.  Paths are relative to repo root.
> 

---

## 1 Git Pre‑Commit Hooks

**File**: `.pre-commit-config.yaml`

```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 24.3.0
    hooks:
      - id: black
  - repo: https://github.com/pycqa/isort
    rev: 5.13.2
    hooks:
      - id: isort
  - repo: https://github.com/markdownlint/markdownlint
    rev: v0.11.0
    hooks:
      - id: markdownlint
  - repo: https://github.com/pre-commit/mirrors-eslint
    rev: v8.57.0
    hooks:
      - id: eslint
        additional_dependencies: ["eslint-config-prettier"]

```

Install once:

```bash
pip install pre-commit && pre-commit install

```

---

## 2 CI Smoke‑Up Workflow

**File**: `.github/workflows/ci-smoke.yml`

```yaml
name: CI Smoke‑Up
on:
  pull_request:
    branches: [ main ]
jobs:
  smoke:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Start RAG stack
        run: |
          docker compose -f docker-compose.yml -f docker-compose.override.rag.yml up -d --build
      - name: Wait for healthz
        run: |
          for i in {1..30}; do curl -sf http://localhost:8080/healthz && exit 0; sleep 5; done; exit 1
      - name: Curl query
        run: |
          curl -s -o /dev/null -w "%{http_code}\n" -X POST http://localhost:8080/v1/query -d '{"query":"ping","top_k":1}' | grep 200
      - name: Tear down
        if: always()
        run: docker compose down -v

```

---

## 3 Dependabot + Renovate

**File**: `.github/dependabot.yml`

```yaml
version: 2
updates:
  - package-ecosystem: "pip"
    directory: "/"
    schedule:
      interval: "weekly"
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"

```

**File**: `renovate.json`

```json
{
  "extends": ["config:base"],
  "pip-compile": {
    "enabled": true
  },
  "prHourlyLimit": 2,
  "prConcurrentLimit": 5
}

```

---

## 4 SBOM & Vulnerability Scan Workflow

**File**: `.github/workflows/trivy-sbom.yml`

```yaml
name: Trivy SBOM + Scan
on:
  push:
    tags: [ "v*" ]
jobs:
  sbom:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build image
        run: docker build -t rag-gateway:${{github.sha}} -f services/gateway/Dockerfile .
      - name: Trivy SBOM
        uses: aquasecurity/trivy-action@0.16.0
        with:
          image-ref: rag-gateway:${{github.sha}}
          format: cyclonedx
          output: sbom.json
      - name: Upload
        uses: actions/upload-artifact@v4
        with:
          name: sbom
          path: sbom.json
      - name: Release asset
        if: startsWith(github.ref, 'refs/tags/')
        uses: softprops/action-gh-release@v2
        with:
          files: sbom.json

```

---

## 5 Ops “First 90 Days” Checklist

**File**: `docs/ops_first_90_days.md`

```markdown
# First 90 Days – RAG Platform Ops

## Week 1–2
- [ ] Verify backups succeed nightly & restore once.
- [ ] Grafana dashboard imported, alerts firing to Slack.
- [ ] Document incident channel & on‑call phone.

## Week 3–4
- [ ] Load‑test: k6 100 RPS, p95 < 300 ms.
- [ ] Rotate Supabase JWT secret.

## Month 2
- [ ] Run Trivy scan on prod images.
- [ ] Evaluate embedding model upgrade.

## Month 3
- [ ] Disaster‑recovery dry‑run on spare VPS.
- [ ] Board sign‑off on SLO report.

```

---

## 6 Grafana Dashboard JSON (overview)

**File**: `monitoring/rag_overview.json` (excerpt)

```json
{
  "title": "RAG Overview",
  "panels": [
    { "type": "time-series", "title": "Gateway p95 latency", "targets": [{
        "expr": "histogram_quantile(0.95, sum(rate(gateway_request_latency_bucket[5m])) by (le))"
    }]},
    { "type": "stat", "title": "Vectors total", "targets": [{
        "expr": "qdrant_vectors_total"
    }]}
  ]
}

```

Import via **Dashboards › Import › Upload JSON**.

---

## 7 Sample Golden‑Set for Eval Harness

**File**: `eval/golden.jsonl`

```
{"query":"total expenses March 2025","answer_regex":".*€?\s*3[,\d\.]*"}
{"query":"AWS invoice number for April","answer_regex":"#?5\d{3}"}
{"query":"When does my passport expire","answer_regex":"202[6-9]-\d{2}-\d{2}"}
{"query":"VAT rate on AWS","answer_regex":"(23|24)%"}
{"query":"Renewal date Youtube Premium","answer_regex":"June"}

```

Used by `make test-rag` to compute recall@5.

---

## 8 Makefile Wrappers

**File**: `Makefile`

```makefile
.PHONY: up down test lint publish backup

up:
	docker compose -f docker-compose.yml -f docker-compose.override.rag.yml up -d --build

down:
	docker compose down -v

lint:
	pre-commit run --all-files

test:
	pytest tests && make eval

eval:
	python scripts/eval_rag.py --golden eval/golden.jsonl

publish:
	pnpm -F @acme/rag-client build && pnpm -r publish --access public

backup:
	bash scripts/backup_qdrant.sh

```

---

### ☑️ These artifacts close the remaining “quick add‑on” gaps mentioned earlier. Copy them into your repo and wire them into CI; the Trivy SBOM workflow will attach a CycloneDX file to every tag release, and Dependabot/Renovate keep dependencies fresh.