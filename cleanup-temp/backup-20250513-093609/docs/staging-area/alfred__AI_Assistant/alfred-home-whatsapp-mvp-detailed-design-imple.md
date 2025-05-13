# Alfred‑Home WhatsApp MVP – Detailed Design & Implementation Specification

# Alfred‑Home WhatsApp MVP – Detailed Design & Implementation Specification

*Last updated: 05 May 2025*

---

## 1 Purpose & Goals

The goal of this document is to describe, **in plain language**, how to build the first production‑ready version of **“Alfred‑Home”** that serves one household over **WhatsApp Business (Cloud API)**.  Alfred‑Home represents the *Home* instance of Alfred; a later sibling **Alfred‑Biz** will reuse the same Core API but surface in Slack.  The MVP must:

- Send a *daily morning briefing* to each family member.
- Maintain a shared **grocery list** and **recurring chore reminders**.
- Respond in Portuguese **and** English, choosing automatically from the user’s first inbound message.
- Respect user privacy (GDPR) and cost less than €30 / month for hosting + messaging at 5 active users.

---

## 1.1 Pre‑Implementation Checklist (“Phase 0”)

Before writing any code, make sure the items below are ticked. Most are one‑off tasks that remove friction later.

| # | Area | Action | Who |
| --- | --- | --- | --- |
| 1 | **Meta Setup** | Create Meta **Business Manager** account ➜ add **WhatsApp Cloud API** product. | Project Lead |
| 2 |  | Verify business + upload VAT/ID docs (takes 1‑3 days). | Project Lead |
| 3 |  | Reserve a dedicated phone number; enable **EU data‑residency** flag. | Tech Lead |
| 4 |  | Generate a long‑lived (90‑day) access token; store in 1Password. | DevOps |
| 5 | **Repo Bootstrap** | Create monorepo folder `services/alfred-home` with Dockerfile + `main.py`. | Dev Team |
| 6 |  | Add **GitHub Actions** template (lint, test, push to Fly) | DevOps |
| 7 | **Secrets / .env** | Draft `.env.template` with `META_TOKEN`, `PHONE_ID`, `REDIS_URL`, `DATABASE_URL`, `OPENWEATHER_KEY`. | DevOps |
| 8 | **Cloud Accounts** | Confirm Redis (Upstash) + Supabase projects exist; copy URLs to `.env` *(Home instance)*.  Add a second, commented‑out pair of lines labelled **Biz instance – leave blank for now** so the split is visible early. | DevOps |
| 9 | **Template Draft** | Write Portuguese + English versions of `daily_briefing` and `chore_reminder`; submit for Meta approval (≈15 min). | UX Writer |
| 10 | **Beta Households** | Recruit 2 families (Lisbon & Porto) and collect consent + WhatsApp numbers. | Project Lead |
| 11 | **GDPR Docs** | Add Privacy Notice & Data Processing Addendum to repo `/legal`. | Legal |
| 12 | **Monitoring** | Create Grafana API key & first dashboard folder. | DevOps |

Once every line above is marked **done**, jump to **Week 0** of the 6‑week timeline.

---

## 2 Tech‑Stack Overview

| Layer | Tech | Why |
| --- | --- | --- |
| Runtime | **Python 3.11** *(set env var `INSTANCE=home` or `biz` at container start‑up)* | Mature async support, rich WhatsApp SDKs |
| Web Framework | **FastAPI** | Async + built‑in OpenAPI docs |
| Messaging Channel | **Meta WhatsApp Cloud API v20.0** | No on‑premises Bap, EU data‑residency flag |
| Background Jobs | **APScheduler + Redis** | Simple cron replacement, serverless‑friendly |
| Data Stores | **Redis** (key‑value) + **PostgreSQL** (relational) | Redis for fast context; Postgres for audit & reporting |
| Containerisation | **Docker + docker‑compose** *(passes `INSTANCE` env down to the app; Alfred‑Home defaults to `home`)* | Repeatable dev & prod |
| Observability | **Prometheus + Grafana + Loki** | Single‑node stack |
| CI/CD | **GitHub Actions** ➜ **Fly.io** or **Render.com** | Free tier, deploy on git push |

---

## 3 High‑Level Architecture

```
┌──────────────┐   Webhook    ┌─────────────────┐   gRPC/REST   ┌────────────┐
│  WhatsApp    │ ───────────▶ │  Adapter Svc    │ ───────────▶ │  Core API  │
│  Cloud API   │              │  (FastAPI)      │               │ (Master)   │
└──────────────┘              └─────────────────┘               └────────────┘
          ▲                            │                           │
          │                            ▼                           ▼
   Inbound JSON                  Redis (context)           PostgreSQL (state)

```

> Note: This service is deployed to Fly.io as alfred‑home.  A sibling deployment alfred‑biz reuses the same Core API but connects to Slack rather than WhatsApp.
> 
- **Adapter Service** – Terminates Meta webhooks, verifies signature, converts payload into internal `InboundMessage` model.
- **Core API** – Houses `FamilyCoordinatorAgent`, grocery & chore services, and scheduler endpoints.
- **Redis** – Stores hot keys: `family:{id}:grocery`, `chore:{id}:trash:status`, `user:{wa_id}:lang`.
- **PostgreSQL** – Durable tables: `users`, `families`, `audit_log`, `message_template`, `event_history`.

---

## 4 Data Model (simplified)

### 4.1 PostgreSQL Tables

```
CREATE TABLE users (
    id               UUID PRIMARY KEY,
    wa_id            VARCHAR(20) UNIQUE NOT NULL,
    display_name     TEXT,
    language         VARCHAR(5) DEFAULT 'pt',
    created_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE families (
    id               UUID PRIMARY KEY,
    name             TEXT,
    tz_offset        INT DEFAULT 0,  -- minutes offset from UTC for cron
    created_at       TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE family_members (
    family_id UUID REFERENCES families(id),
    user_id   UUID REFERENCES users(id),
    role      TEXT DEFAULT 'member',
    PRIMARY KEY (family_id, user_id)
);

CREATE TABLE audit_log (
    id         BIGSERIAL PRIMARY KEY,
    user_id    UUID,
    event      TEXT,
    payload    JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

```

### 4.2 Redis Keys

- `grocery:{family_id}` – **List**: `["leite", "ovos"]`
- `chore:{family_id}:{chore_id}` – **Hash**: `{due:"20:00", status:"pending"}`
- `last_interaction:{user_wa}` – **String** unix‑timestamp (24 h window helper)

---

## 5 Message Templates (Meta approval)

### 5.1 Morning Briefing – `daily_briefing_pt`

```
Bom dia, {{1}} ☀️
• Hoje tens {{2}} compromisso(s):
{{3}}
• Meteo: {{4}}°C, {{5}}
• Lembrete: {{6}}
• Compras pendentes: {{7}}

```

*Variables*: name, count, event list, temp, weather desc, reminder, first 3 groceries.

### 5.2 Chore Reminder – `chore_reminder_pt`

```
🔔 Lembrete: {{1}}

```

*Buttons*: ✅ Feito | ⏰ Lembrar mais tarde

---

## 6 Core Classes (Python)

```
class IAdapter(ABC):
    async def send(self, to_wa_id: str, payload: dict) -> None: ...
    async def receive(self, inbound: dict) -> "InboundMessage": ...

class WhatsappAdapter(IAdapter):
    # implements signature check, template calls, etc.

class GroceryService:
    def add_item(self, family_id: UUID, item: str) -> list[str]: ...
    def list_items(self, family_id: UUID) -> list[str]: ...

class ChoreService:
    def schedule(self, family_id: UUID, name: str, due_time: time): ...
    def mark_done(self, family_id: UUID, name: str): ...

class FamilyCoordinatorAgent:
    async def handle(self, msg: InboundMessage) -> OutboundMessage: ...

```

---

## 7 Interaction Flows

### 7.1 Registration

1. User sends **any** message ➜ Adapter validates ➜ Core checks `users` table.
2. If unknown, Core replies with onboarding & language detection.
3. On *START*, user linked to default family and morning job enabled.

### 7.2 Morning Briefing Job

1. APScheduler triggers at 07:30 local‑time per family timezone.
2. Core queries Google Calendar API (optional) + Redis chores + OpenWeather.
3. Core composes variables ➜ `WhatsappAdapter.send(template_id, vars)`.

### 7.3 Add Grocery

```
User: add bananas
Core: update Redis list ➜ send text confirm.

```

### 7.4 Chore Reminder

1. APScheduler checks due chores hourly.
2. If pending & within 1 h window, send button template.
3. Webhook receives button payload ➜ `ChoreService.mark_done()`.

---

## 8 API Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| **GET** | `/webhook` | Meta verification (hub.mode & token) |
| **POST** | `/webhook` | Receives messages and status callbacks |
| **POST** | `/admin/groceries/{family}/{item}` | Manual add (internal) |
| **GET** | `/healthz` | Used by load balancer |

All internal endpoints secured with JWT signed by GitHub Actions secret.

---

## 9 Deployment (Docker‑Compose Snippet)

```
version: "3.9"
services:
  api:
    build: ./services/core
    env_file: .env
    environment:
      - INSTANCE=home
    depends_on: [redis, postgres]
    ports: ["8000:8000"]
  redis:
    image: redis:7-alpine
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: alfred
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
  grafana:
    image: grafana/grafana

```

Fly io `fly.toml` sets 256 MB Lite VM in EU‑MAD region.

---

## 10 Security & Privacy

- **E2EE transport** – All calls to Meta Graph API use HTTPS; webhook protected by HMAC‑SHA256 header.
- **Role‑based access** – Only users with `role='owner'` may modify templates or chores.
- **GDPR** – `/admin/delete_user/{id}` hard‑deletes Redis + Postgres entries; log kept 30 days then pruned.
- **Data residency** – Enable *EU Region* toggle when creating phone number in Meta console.
- **Secrets and data stores shared with Alfred‑Biz: none.**

---

## 11 Monitoring & Alerts

- **Prometheus metrics**: request_latency_ms, outbound_errors_total, cron_job_duration.
- **Alert rules**: >1 % outbound errors in 5 min ➜ PagerDuty.
- **Log aggregation**: Loki, with structured JSON logs for each inbound/outbound message.

---

## 12 Testing Strategy

| Layer | Tool | Target Coverage |
| --- | --- | --- |
| Unit | pytest | 80 % branches |
| Contract | `schemathesis` (+ FastAPI OpenAPI) | 100 % endpoints |
| Integration | WhatsApp Sandbox | Send/receive flow |
| Load | `locust` | 50 msg/s, p95 < 300 ms |

Beta rollout to 2 households (Lisbon, Porto) for 2 weeks.

---

## 13 Cost Estimate (Monthly, 5 users)

| Item | Unit Cost | Quantity | Sub‑total |
| --- | --- | --- | --- |
| WhatsApp Service Conversations | €0 | 150 conv | €0 |
| WhatsApp Marketing (template re‑open) | €0.049 | 30 conv | €1.47 |
| Fly io Lite VM | €2 / mo | 1 | €2 |
| Redis (Upstash free tier) | €0 | – | €0 |
| Postgres (Supabase starter) | €0 | – | €0 |
| Prometheus stack | Self‑host | 256 MB VM | included |
| **Total** |  |  | **≈ €3.50** |

*Total platform cost for **Home + Biz** currently estimated at **€4–6/month** (see dual‑instance doc §6).*

---

## 14 Detailed 6‑Week Implementation Plan (Expanded)

Below is an expanded view of the six‑week plan.  Each task now has an **owner**, an **estimate** (ideal hours), key **inputs/outputs**, and explicit **dependencies**.

| Wk | Day | Task ID | Task Description | Owner | Est (hr) | Input(s) | Output / Done Criteria | Depends On |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **0** | Mon | 0‑1 | Close Phase 0 checklist | PM | 4 | Checklist items | All items green in Jira | – |
|  | Tue | 0‑2 | Scaffold service repo (`./services/alfred-home`) | Dev | 6 | Template repo | `main.py` runs `uvicorn` | 0‑1 |
|  | Wed | 0‑3 | Write Dockerfile & local `docker‑compose.yml` | Dev | 4 | Base image choice | `docker compose up` shows healthy containers | 0‑2 |
|  | Thu | 0‑4 | Create Fly staging app & CI deploy | DevOps | 3 | GitHub token | `fly apps list` shows app; staging URL returns 200 | 0‑3 |
|  | Fri | 0‑5 | Point Meta sandbox → `/webhook` echo | QA | 2 | Webhook URL, token | Echo latency < 2 s | 0‑4 |
| **1** | Mon | 1‑1 | Add HMAC signature middleware | Dev | 4 | Meta docs | Unit tests pass for valid/invalid sig | 0‑5 |
|  | Tue | 1‑2 | Build `InboundMessage` & adapter mapping | Dev | 6 | Sample JSON | `pytest tests/test_adapter.py` green | 1‑1 |
|  | Wed | 1‑3 | Implement outbound helpers (`send_text`, `send_template`) | Dev | 5 | Token, phone ID | Text & template reach sandbox | 1‑2 |
|  | Thu | 1‑4 | Add retry/back‑off (429/5xx) | Dev | 3 | HTTP client | Integration test sim 429 passes | 1‑3 |
|  | Fri | 1‑5 | Static analysis + 80 % unit coverage | QA | 2 | `pytest‑cov` | CI green badge | 1‑4 |
|  | Fri | 1‑6 | Introduce `INSTANCE` env & skill loader (flag = home) | Dev | 4 | Env spec | Sandbox passes `INSTANCE=home` smoke | 1‑5 |
| **2** | Mon | 2‑1 | Alembic migrations (`users`, `families`, `audit_log`) | Dev | 4 | DB URL | `alembic upgrade head` succeeds | 1‑6 |
|  | Tue | 2‑2 | Language detection & greeting logic | Dev | 5 | `langdetect` lib | PT vs EN greeting validated | 2‑1 |
|  | Wed | 2‑3 | Implement `/start` flow + family link | Dev | 4 | Redis client | Row in `family_members` created | 2‑2 |
|  | Thu | 2‑4 | Integration tests with sandbox mocks | QA | 4 | pytest fixtures | 90 % branch coverage | 2‑3 |
|  | Fri | 2‑5 | Prometheus metric `request_latency_ms` | DevOps | 2 | `prom-client` | Metric visible in Grafana | 2‑4 |
| **3** | Mon | 3‑1 | `GroceryService.add/list` using Redis list | Dev | 5 | Redis URL | “add milk” confirmed | 2‑5 |
|  | Tue | 3‑2 | `ChoreService` CRUD + APScheduler | Dev | 6 | Cron spec | Redis hash updates; job emits log | 3‑1 |
|  | Wed | 3‑3 | WhatsApp quick‑reply button handler | Dev | 4 | Payload sample | Mark‑done stops reminders | 3‑2 |
|  | Thu | 3‑4 | End‑to‑end tests (add + remind) | QA | 4 | Sandbox creds | All green | 3‑3 |
|  | Fri | 3‑5 | Update API docs & `/admin` stubs | Docs | 3 | OpenAPI JSON | `docs/api.md` merged | 3‑4 |
| **4** | Mon | 4‑1 | Integrate OpenWeather API | Dev | 4 | API key | Cached weather JSON in Redis | 3‑5 |
|  | Tue | 4‑2 | Calendar events stub (static ICS) | Dev | 4 | .ics file | Events list renders in vars | 4‑1 |
|  | Wed | 4‑3 | Assemble briefing variables & template send | Dev | 5 | Redis, weather, events | Message in sandbox at 07:30 | 4‑2 |
|  | Thu | 4‑4 | Implement `STOP` & `PAUSE n` flags | Dev | 3 | Redis set | Flags honoured in message loop | 4‑3 |
|  | Fri | 4‑5 | Meta template approval check (PT + EN) | UX | 1 | Meta console | Status = `approved` | 4‑4 |
| **5** | Mon | 5‑1 | Add Loki structured logging | DevOps | 3 | Grafana URL | Trace IDs link to Grafana | 4‑5 |
|  | Tue | 5‑2 | Load test (Locust 50 msg/s) | QA | 4 | Locust scripts | p95 latency < 300 ms | 5‑1 |
|  | Wed | 5‑3 | Security scan (OWASP ZAP + trivy) | Sec | 3 | Container image | No high/crit CVEs | 5‑2 |
|  | Thu | 5‑4 | GDPR delete endpoint + RLS | Dev | 5 | Supabase SQL | Delete verified via curl | 5‑3 |
|  | Fri | 5‑5 | Tag `v0.1.0‑rc1`, deploy to staging | PM | 2 | Release notes | Smoke tests pass | 5‑4 |
| **6** | Mon | 6‑1 | Prod DB migration + `v0.1.0` deploy | DevOps | 2 | `fly deploy` | Prod `/healthz` 200 | 5‑5 |
|  | Tue | 6‑2 | Onboard Lisbon family | PM | 2 | Invite link | Briefing delivered | 6‑1 |
|  | Wed | 6‑3 | Onboard Porto family | PM | 2 | Invite link | Grocery item added | 6‑2 |
|  | Thu | 6‑4 | Collect NPS + bug reports, hotfixes | QA | 4 | Google Form | Sev‑1 bugs = 0 | 6‑3 |
|  | Fri | 6‑5 | Go/No‑Go review | Stakeholders | 1 | Metrics dashboard | Sign‑off | 6‑4 |

### Critical Path

`0‑1 → 0‑2 → 0‑3 → 0‑4 → 0‑5 → 1‑1 → 1‑2 → 1‑3 → … → 6‑5`

If **any** task on the critical path slips > 1 day, re‑evaluate scope or extend timeline.

### Buffer Days

*Each Friday afternoon (after demos) is a ½‑day buffer* reserved for hotfixes and carry‑over work.  Do **not** schedule new scope there.

---

## 15 Future Roadmap (post‑MVP)

1. **Voice Interface** – Alexa skill reusing Core API.
2. **Shared Polls** – “Pizza vs Sushi?” quick votes.
3. **Geo‑fence Reminders** – Notify when near supermarket.
4. **Deploy Alfred‑Biz** – Separate Fly app with Slack adapter.

---

## 16 References & Links

- Meta WhatsApp Business Cloud API docs (v20.0)
- OpenWeather Map OneCall API
- APScheduler 3.x
- GDPR Art. 17 “Right to erasure”

*End of document*