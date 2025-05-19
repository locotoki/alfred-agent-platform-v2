# AI Agent Platform v2 · Alfred × WhatsApp Cloud API Integration Guide (v2025‑05‑05a)

# AI Agent Platform v2 · Alfred × WhatsApp Cloud API Integration Guide (v2025‑05‑05a)

*Supersedes the 2025‑05‑05 draft; aligns with the **Alfred‑Home** Fly/Redis architecture and recent infra decisions.*

---

## 1 · Executive Summary

|  | Details |
| --- | --- |
| **Goal** | Enable Alfred to send & receive WhatsApp messages via Meta’s **Cloud API** under Digital Native Ventures’ WABA. |
| **Outcome** | ✔ Two‑way messaging (user‑ & business‑initiated).✔ Webhook events flow into Alfred’s Redis event bus.✔ Per‑tenant isolation (*home*, *biz*) enforced at the edge. |
| **Assumes** | • DNV Business Manager & WABA already exist.• Business‑type Meta App **Alfred** with WhatsApp product attached.• Deployment on **Fly.io** (Single Lite VM) with **Redis Streams** & **Supabase**. |

---

## 2 · Meta Platform Primer (unchanged)

| Concept | Description |
| --- | --- |
| **Business Manager** | Container for pages, apps, WABAs, etc. |
| **Meta App (Business)** | Holds WhatsApp product; issues access tokens. |
| **WABA** | Owns phone numbers & templates. |
| **Phone Number ID** | Unique ID; used in REST paths. |
| **Access Tokens** | • *Sandbox* 23‑h token • *System‑user* long‑lived token |
| **Conversation Types** | • User‑initiated (24 h) • Business‑initiated (template) |
| **Rate Limits** | Tier 1 = 1 000 conv/day; scales with quality. |

---

## 3 · High‑Level Architecture

```
WhatsApp  ▶  Webhook svc  ─▶  Redis Stream «alfred‑ingest» ─▶  Logic Orchestrator
                                                     │
Outbound Worker ◀──────── Redis Stream «alfred‑outbox»◀──────┘

```

- **Webhook svc** – FastAPI route verifies X‑Hub‑Signature‑256 (HMAC‑SHA‑256). Emits a standard `InboundMessage` JSON with `tenant_id` = *home*.
- **Outbound Worker** – Consumes «alfred‑outbox»; `POST /v18.0/{PHONE_ID}/messages` with exponential back‑off; requeues on transient 4xx/5xx.
- **Observability** – Prometheus scrape via Fly exporter; dashboards in Grafana with label `instance=alfred-home`.

---

## 4 · Implementation Plan

| Phase | Deliverables | Effort |
| --- | --- | --- |
| **0 · Prep** | • Complete Business verification.• Add WABA payment method (if absent). | 0.5 d |
| **1 · Sandbox Smoke** | • Confirm WhatsApp product → test number & token.• Whitelist family numbers.• `curl` **hello_world** template. | 0.5 d |
| **2 · Webhook MVP** | • Deploy `/webhook` on Fly.• Implement GET verify + HMAC check.• `xadd` into `alfred‑ingest` stream. | 1 d |
| **3 · Production Phone** | • Add real phone number; SMS verify.• Display‑name review → *Household Assistant*.• Generate system‑user LL token. | 1 d |
| **4 · Outbound Worker & Templates** | • Create *Utility* templates (e.g., `reminder_update`).• Implement worker with fail‑requeue.• Unit + load tests (Locust 50 msg/s). | 1 d |
| **5 · Observability & Alerts** | • Prometheus + Grafana on Fly.• PagerDuty alert ≥ 10 % send‑fail or quality drop. | 0.5 d |

*Total ≈ 4 – 5 engineer‑days.*

---

## 5 · Step‑by‑Step Setup

### 5.1 Create / Confirm Business‑type App

1. `developers.facebook.com` ▸ **My Apps** ▸ **Create App** ▸ **Business**.
2. Pick **Digital Native Ventures** Business Manager.

### 5.2 Add WhatsApp Product & Smoke Test

Copy test token & phone‑ID →

```bash
curl -X POST "https://graph.facebook.com/v18.0/$PHONE_ID/messages" \
  -H "Authorization: Bearer $SANDBOX_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
        "messaging_product":"whatsapp",
        "to":"<DEV_NUMBER>",
        "type":"template",
        "template":{"name":"hello_world","language":{"code":"en_US"}}
      }'

```

Expected: “Hello World” on phone.

### 5.3 Webhook Endpoint on Fly

```python
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
    redis.xadd("alfred-ingest", {"payload": raw}, id="*")
    return {"status": "ok"}

```

### 5.4 Long‑Lived Token Storage

```bash
fly secrets set META_TOKEN="<LL_TOKEN>"

```

Weekly rotation via GitHub Actions cron (`0 3 * * 1`).

### 5.5 Production Send Example

```bash
curl -X POST "https://graph.facebook.com/v18.0/$PHONE_ID/messages" \
  -H "Authorization: Bearer $META_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
        "messaging_product":"whatsapp",
        "to":"+14155551234",
        "type":"text",
        "text":{"body":"Your meeting starts in 10 min."}
      }'

```

---

## 6 · Security & Compliance

- **Token handling** – Stored in Fly secrets; rotated weekly.
- **HMAC verification** – Mandatory; reject if missing or timestamp skew > 10 s.
- **RBAC** – Separate service users per tenant in Meta; `tenant_id` in every Redis envelope.
- **Audit trail** – Log outbound payload + HTTP status, tag with `tenant_id`.
- **PII retention** – 30‑day hot in Supabase; 90‑day cold (S3‑compatible). Auto‑anonymize after.

---

## 7 · Testing Checklist

| Test | Tool | Pass criteria |
| --- | --- | --- |
| Sandbox send/receive | Postman | 200 OK + phone receives msg |
| HMAC tamper | curl | 403 Forbidden |
| Template approval flow | Meta UI | “Approved” within 1 h SLA |
| Load (50 msg/s × 5 min) | Locust | ≤ 1 % error, p95 < 2 s |
| OOM resilience | Fly VM restart | Worker re‑queues, no msg loss |

---

## 8 · Troubleshooting Guide

| Symptom | Probable cause | Remedy |
| --- | --- | --- |
| **HTTP 400** “Invalid token” | Token expired | Regenerate LL token, `fly secrets set` |
| **HTTP 429** | Tier cap or rate‑limit | Wait 24 h or raise messaging tier |
| No webhook delivery | Invalid verify token or HMAC failure | Check Fly logs, re‑verify token |
| Fly VM OOM | Message burst > RAM | Scale to `shared-cpu-1x`, add Redis back‑pressure |

---

## 9 · Reference Links

- Meta Cloud API Docs – [https://developers.facebook.com/docs/whatsapp/cloud-api](https://developers.facebook.com/docs/whatsapp/cloud-api)
- Webhook Security – …/webhooks/getting-started#security
- Messaging Limits – …/whatsapp/messaging-limits

---

### Change Log

| Date | Version | Notes |
| --- | --- | --- |
| 2025‑05‑05 | 1.0.0a | Updated for Fly & Redis; aligned with Alfred‑Home SSoT. |

---

End of Document


**Note:** This document is a consolidation of multiple source documents from the staging area.
Last consolidated: 2025-05-14


## Source Documents

- alfred__AI_Assistant/ai-agent-platform-v2-alfred-whatsapp-cloud-api.md
- AI_Agent_Platform_v2/ai-agent-platform-v2-technical-design-guide.md
- AI_Agent_Platform_v2/ai-agent-platform-v2-re-architecture-plan-supab.md
- AI_Agent_Platform_v2/ai-agent-platform-v2--technical-architecture-docum.md
- AI_Agent_Platform_v2/ai-agent-platform-v2--test-plan-test-cases.md
- AI_Agent_Platform_v2/ai-agent-platform-v2--operations-maintenance-gui.md
- AI_Agent_Platform_v2/ai-agent-platform-v2--ci-cd-pipeline-documentation.md
- AI_Agent_Platform_v2/ai-agent-platform-v2--security-plan.md
- AI_Agent_Platform_v2/ai-agent-platform-v2--api-documentation.md
- AI_Agent_Platform_v2/ai-agent-platform-v2-complete-implementation-guide.md
- AI_Agent_Platform_v2/ai-agent-platform-v2---master-project-plan-v1-1-05.md
- AI_Agent_Platform_v2/ai-agent-platform-v2---master-project-plan.md
- AI_Agent_Platform_v2/ai-agent-platform-v2-ai-agent-core-integration-pla.md
- AI_Agent_Platform_v2/ai-agent-platform-v2.md
- AI_Agent_Platform_v2/ai-agent-platform-v2-1-rearchitecture-plan-supa.md
