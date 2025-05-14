# RAG Service – Day‑Two Operations Guide

# RAG Service – Day‑Two Operations Guide

> Audience: SRE / on‑call engineer operating the RAG stack in production (single‑node on‑prem).
> 
> 
> **Revision**: 0.1 ‑‑ 2025‑05‑09
> 
> **Prerequisite**: MVP rolled out per *Implementation Plan & Test Instructions*.
> 

---

## 1 Operations Philosophy

- **High trust, low ceremony** – single‑maintainer environment; scripts over tickets.
- **Automate then document** – every manual step here has a matching script in `scripts/`.
- **Error budget rules** – adhere to SLO charter (§5).

---

## 2 On‑Call & Escalation

| Rotation | Primary | Backup | Hours |
| --- | --- | --- | --- |
| Weekdays | `@locotoki` | — | 09:00‑18:00 CET |
| Nights / weekends | PagerDuty “Solo Ops” schedule | — | 18:00‑09:00 |

**Escalation levels**

1. Slack `#rag‑alerts` mention `@here`
2. Phone/SMS (PagerDuty)
3. Data‑loss → call datacenter NOC + pull DR runbook

---

## 3 Monitoring & Alerting

### 3.1 Key Dashboards

| Grafana UID | Title | Owner |
| --- | --- | --- |
| `rag‑ov` | *RAG Overview* | SRE |
| `gpu‑util` | *GPU Utilisation* | SRE |
| `qdr‑stor` | *Qdrant Storage & Shards* | DBRE |

### 3.2 Prometheus Rules (excerpt)

```yaml
groups:
- name: rag‑latency
  rules:
  - alert: RAG_P95_Latency_High
    expr: histogram_quantile(0.95, sum(rate(rag_gateway_query_latency_seconds_bucket[5m])) by (le)) > 0.25
    for: 10m
    labels:
      severity: page
    annotations:
      summary: "RAG p95 latency > 250 ms"
      runbook: https://git.local/runbooks/rag#latency

```

### 3.3 Log Routing

- **Gateway & Reranker** → Loki label `{app="rag"}`
- **Supabase & Qdrant** → separate Loki tenants for PII scrubbing.

---

## 4 Routine Maintenance Schedule

| Frequency | Task | Script | Expected Duration |
| --- | --- | --- | --- |
| Daily 08:00 | Check overnight alerts | `make alert-summary` | 5 min |
| Daily 23:00 | Incremental Qdrant snapshot | `scripts/backup_qdrant.sh` | 2 min |
| Weekly Mon | Retention prune (hot‑tier >90 d) | `python scripts/retention_worker.py --dry-run` | 10 min |
| Weekly Fri | GPU driver + container base image CVE scan | `trivy fs /var/lib/docker` | 15 min |
| Monthly 1st | Full load test (k6) + Ragas eval | `make load-test eval` | 30 min |
| Quarterly | Disaster‑recovery drill (restore to staging) | `scripts/restore_dr.sh` | 1 h |

---

## 5 Backup & Disaster Recovery

- **Snapshots** – nightly `.snapshot` per collection stored in MinIO `rag-backups/yyyy-mm-dd/`.
- **Metadata** – Supabase Postgres WAL archiving to same bucket.
- **Verification** – weekly SHA‑256 checksum & restore dry‑run.

### 5.1 Restore Procedure (cheat sheet)

```bash
$❯ docker compose stop rag-gateway rag-embed-gpu rag-rerank-gpu
$❯ mc cp minio/rag-backups/2025-05-09/*.snapshot /tmp/restore/
$❯ docker run --rm -v qdrant_data:/qdrant_data -v /tmp/restore:/restore \
      qdrant/qdrant:latest qdrant-restore -s /restore/personal.snapshot
$❯ docker compose up -d

```

---

## 6 Upgrade & Rollback

### 6.1 Gateway / Worker Containers

1. `docker pull ghcr.io/yourorg/rag-gateway:<tag>`
2. `docker compose up -d rag-gateway` (blue‑green port 8081)
3. Health‑check `curl :8081/healthz`
4. Switch Nginx upstream
5. Remove old container.

**Rollback** → revert Nginx to old port, `docker tag` back.

### 6.2 Qdrant Version Bump

- Use `-snapshot` flag then in‑place upgrade (supports semver minor).
- Major version → restore snapshot to fresh volume, verify `collections.stats`.

### 6.3 Embedding Model Refresh

| Step | Command |
| --- | --- |
| Download | `ollama pull e5-large-v2:q5` |
| Canary | `GATEWAY_EMBED_MODEL=e5-large-v2:q5 CANARY=1` env var → 10 % traffic header `X-Embed-Canary: 1` |
| Promote | Edit `.env` + redeploy gateway |

---

## 7 Capacity Management

- **GPU** – Alert at 80 % util for >15 m. Add second card or move reranker to CPU.
- **Vectors** – Qdrant `estimated_point_count` alert at 15 M; plan shard split.
- **Storage** – MinIO bucket reaches 70 % disk → expand NAS.

---

## 8 Security Operations

### 8.1 Token & Key Rotation

| Secret | Rotation | Script |
| --- | --- | --- |
| Supabase JWT signing key | 90 d | `scripts/rotate_jwt.sh` |
| OpenAI key | 60 d | `doppler rotate openai` |

### 8.2 Vulnerability Scanning

- **CI** runs Trivy on every PR; fails build on HIGH CVEs.
- Monthly full‑node scan: `trivy rootfs /`.

---

## 9 Incident Response Playbooks

### 9.1 High Latency (>250 ms p95)

1. Check Grafana `gpu-util` – if >90 % → scale ingest worker down.
2. Verify Qdrant CPU – if >80 % → `docker restart qdrant`.
3. Still red? Switch Gateway to OpenAI embeddings fallback.

### 9.2 5xx Spike (Gateway)

| Check | Command | Fix |
| --- | --- | --- |
| Error logs | `docker logs rag-gateway | tail` |
| Supabase | `curl supabase:8000/health` | restart container |

### 9.3 Namespace Leakage Alert

1. Review Athena report URL in Slack alert.
2. Run `scripts/leakage_audit.sql` against Postgres.
3. Purge offending vectors: `qdrant-delete --filter 'tenant_id="foo" AND persona="personal"'`.

---

## 10 Post‑Incident Review Template

```
### Summary
<two‑sentence overview>

### Timeline (UTC)
* 12:05 – Alert fired …
* 12:15 – Mitigation applied …

### Impact
<users affected, duration>

### Root Cause
<diagram + explanation>

### Lessons Learned
- What worked
- What didn’t

### Action Items
| Owner | Task | Date |
|-------|------|------|

### Tags: reliability, security, latency

```

---

## 11 Performance Tuning Cheatsheet

| Scenario | Knob | Command |
| --- | --- | --- |
| ANN recall low | Increase `ef` | `scripts/qdrant_tune.py --ef 512` |
| Rerank slow | Batch size | `GATEWAY_RERANK_BATCH=4` env var |
| High RAM usage | Enable on‑disk payload | `curl .../collections/<c>/update -d '{"on_disk_payload":true}'` |

---

## 12 Change Management & Versioning

- All infra repos use **GitFlow**; merge to `main` auto‑deploys to staging.
- SemVer for API (`/v1/…`), JSON Schemas under `components.schemas.v*`.
- Deprecations announced in `#rag‑announce` 30 d in advance.

---

*End of Day‑Two Operations Guide.  Keep this doc version‑controlled next to the compose stack.*