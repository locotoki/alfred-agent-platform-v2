# Alfred‑Home: Single Source of Truth – Implementation & Operations Guide (v2025‑05‑05)

# Alfred‑Home: Single Source of Truth – Implementation & Operations Guide (v2025‑05‑05)

## 1 · Executive Summary

This guide is the definitive reference for deploying, operating, and maintaining **Alfred‑Home**, the family instance of the Alfred AI assistant that runs on WhatsApp. It merges the *WhatsApp Family MVP Implementation Spec*, the *AI Agent Platform v2 – WhatsApp Cloud API Integration Guide*, and supersedes the outdated *Minimum Viable WhatsApp AI Assistant* document.

---

## 2 · High‑Level Architecture

```
WhatsApp  ▶  Webhook svc  ─▶  Redis Stream «alfred‑ingest» ─▶  Logic Orchestrator
                                                     │
Outbound Worker ◀──────── Redis Stream «alfred‑outbox»◀──────┘
```

- **Tenant isolation** – Hard‑coded `tenant_id = home` at the edge.
- **Persistence** – Supabase (Postgres + pgvector) and Upstash Redis.
- **Observability** – Prometheus → Grafana/Loki with per‑instance labels.

---

## 3 · Infrastructure Stack

| Layer | Service / Plan | Region |
| --- | --- | --- |
| Compute | Fly.io Lite VM × 1 (`alfred-home-eu`) | EU‑MAD |
| Database | Supabase project `alfred_home` (free tier) | EU‑W1 |
| Cache | Upstash Redis `home-redis` | Global |
| Metrics & Logs | Prometheus, Grafana, Loki on Fly | EU‑MAD |

> Cost: ≈ €6 / mo (1 Lite VM + WhatsApp message fees).
> 

---

## 4 · Codebase Layout

```
src/
 ├─ core/              # shared agents, data, helpers
 ├─ adapters/
 │    └─ whatsapp/     # FastAPI routes, signature check
 ├─ skills_home/       # GroceryService, ChoreService, MorningBriefingJob
 └─ main.py            # loads skills when INSTANCE=home
tests/                 # uses @pytest.mark.home_only
```

---

## 5 · WhatsApp Cloud API Integration

### 5.1 Prerequisites

- Business‑type Meta App **Alfred** with WhatsApp product attached.
- Verified WABA + production phone number in good standing.
- Long‑lived system‑user token (`whatsapp_business_messaging, whatsapp_business_management`).

### 5.2 Webhook Service

```
@app.get("/webhook")
async def verify(mode: str, challenge: str, token: str):
    if mode == "subscribe" and token == os.getenv("VERIFY_TOKEN"):
        return int(challenge)
    raise HTTPException(403)

@app.post("/webhook")
async def inbound(request: Request):
    raw = await request.body()
    sig = request.headers.get("X-Hub-Signature-256", "")[7:]
    expected = hmac.new(APP_SECRET.encode(), raw, hashlib.sha256).hexdigest()
    if not hmac.compare_digest(sig, expected):
        raise HTTPException(403)
    pubsub.publish("alfred-ingest", raw, tenant_id="home")
    return {"status": "ok"}
```

### 5.3 Outbound Worker

- Polls Redis stream `alfred‑outbox`.
- `POST /v18.0/{PHONE_ID}/messages` with exponential back‑off and re‑queue on 4xx/5xx.

### 5.4 Templates & Limits

- Use **Utility** templates only (e.g., `reminder_update`).
- Tier 1 limit: 1 000 user‑initiated conversations / day; auto‑scales with quality score.

---

## 6 · Secrets & Environment Variables

`.env.template` (tracked):

```
# shared\ nOPENAI_API_KEY=
REDIS_URL=
DATABASE_URL=
INSTANCE=home

# WhatsApp‑only
META_TOKEN=
PHONE_ID=
VERIFY_TOKEN=
```

Secrets injected via **Fly secrets** at deploy time (`fly secrets set META_TOKEN=...`).

---

## 7 · CI/CD Pipeline (GitHub Actions)

```
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build & push
        run: docker build -t registry/alfred-home:${{ github.sha }} .
      - name: Fly deploy
        run: fly deploy --app alfred-home-eu --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN_HOME }}
```

Tagging `vX.Y.Z` triggers deployment.

---

## 8 · Database & Migrations

```
supabase db reset --project-ref alfred_home
alembic upgrade head
```

No `tenant_id` columns or RLS rules are required for the single‑tenant Home instance.

---

## 9 · Observability & Alerts

- Prometheus scrape configs add label `instance=alfred-home`.
- Grafana dashboards duplicated per instance.
- PagerDuty alert: **> 1 % 5xx** in **5 min** window.

---

## 10 · Token Rotation Automation

```
run: fly secrets set META_TOKEN=$(op read "op://Home/Meta-Token-Home/password")
```

Scheduled weekly via GitHub Actions (`cron: "0 3 * * 1"`).

---

## 11 · Testing & Smoke Checks

| Test | Tool | Expected Result |
| --- | --- | --- |
| `POST /webhook` add "bananas" | curl | 200 OK + Redis list updated |
| Template send via Postman | WA | Message appears on device |
| HMAC tamper | curl | 403 Forbidden |

Full load and security test scripts live in `tests/e2e/`.

---

## 12 · Roll‑out Sequence

1. **Day 1 – morning** Cut tag `v1.0.0` → GitHub deploy.
2. **Lunch** Join family WhatsApp group; test chores & groceries.
3. **Day 2 – morning** Dog‑food for 24 h; monitor Grafana latency.
4. **Day 2 – afternoon** Enable PagerDuty alert; archive this checklist.

---

## 13 · Troubleshooting

| Symptom | Cause | Fix |
| --- | --- | --- |
| **HTTP 400** Invalid token | Token expired | Refresh LL token via Meta UI |
| **HTTP 429** | Rate‑limit or conversation cap | Wait 24 h or upgrade messaging tier |
| No webhook delivery | FW / URL mis‑config, bad signature | Check `verify` endpoint, use ngrok tunnel |

---

## 14 · Reference Links

- Meta Cloud API – developers.facebook.com/docs/whatsapp/cloud-api
- Webhook Security – …/webhooks/getting-started#security
- Messaging Limits – …/whatsapp/messaging-limits

---

## 15 · Change Log

| Date | Version | Notes |
| --- | --- | --- |
| 2025‑05‑05 | 1.0.0 | Consolidated MVP Implementation Spec + Cloud API Guide; archived outdated MVP doc. |

---

End of Document