# Alfred WhatsApp Family MVP – Detailed Design & Implementation Specification

# Alfred WhatsApp Family MVP – Detailed Design & Implementation Specification

*Last updated: 05 May 2025*

---

## 1 Purpose & Goals

The goal of this document is to describe, **in plain language**, how to build the first production‐ready version of “Alfred” that serves one household over **WhatsApp Business (Cloud API)**.  The MVP must:

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
| 5 | **Repo Bootstrap** | Create monorepo folder `services/whatsapp-family` with Dockerfile + `main.py`. | Dev Team |
| 6 |  | Add **GitHub Actions** template (lint, test, push to Fly) | DevOps |
| 7 | **Secrets / .env** | Draft `.env.template` with `META_TOKEN`, `PHONE_ID`, `REDIS_URL`, `DATABASE_URL`, `OPENWEATHER_KEY`. | DevOps |
| 8 | **Cloud Accounts** | Confirm Redis (Upstash) + Supabase projects exist; copy URLs to `.env`. | DevOps |
| 9 | **Template Draft** | Write Portuguese + English versions of `daily_briefing` and `chore_reminder`; submit for Meta approval (≈15 min). | UX Writer |
| 10 | **Beta Households** | Recruit 2 families (Lisbon & Porto) and collect consent + WhatsApp numbers. | Project Lead |
| 11 | **GDPR Docs** | Add Privacy Notice & Data Processing Addendum to repo `/legal`. | Legal |
| 12 | **Monitoring** | Create Grafana API key & first dashboard folder. | DevOps |

Once every line above is marked **done**, jump to **Week 0** of the 6‑week timeline.

---

## 2 Tech‑Stack Overview

| Layer | Tech | Why |
| --- | --- | --- |
| Runtime | **Python 3.11** | Mature async support, rich WhatsApp SDKs |
| Web Framework | **FastAPI** | Async + built‑in OpenAPI docs |
| Messaging Channel | **Meta WhatsApp Cloud API v20.0** | No on‑premises Bap, EU data‑residency flag |
| Background Jobs | **APScheduler + Redis** | Simple cron replacement, serverless‑friendly |
| Data Stores | **Redis** (key‑value) + **PostgreSQL** (relational) | Redis for fast context; Postgres for audit & reporting |
| Containerisation | **Docker + docker‑compose** | Repeatable dev & prod |
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

- **Adapter Service** – Terminates Meta webhooks, verifies signature, converts payload into internal `InboundMessage` model.
- **Core API** – Houses `FamilyCoordinatorAgent`, grocery & chore services, and scheduler endpoints.
- **Redis** – Stores hot keys: `family:{id}:grocery`, `chore:{id}:trash:status`, `user:{wa_id}:lang`.
- **PostgreSQL** – Durable tables: `users`, `families`, `audit_log`, `message_template`, `event_history`.

---

## 4 Data Model (simplified)

### 4.1 PostgreSQL Tables

```sql
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

```python
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

```yaml
version: "3.9"
services:
  api:
    build: ./services/core
    env_file: .env
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

---

## 14 6‑Week Timeline

| Week | Focus | Deliverables |
| --- | --- | --- |
| 0 | Kick‑off | Repo, Docker skeleton, WhatsApp sandbox live |
| 1 | Adapter | Webhook + signature‑check; simple echo bot |
| 2 | Core API | Redis interface, FamilyCoordinator w/ `echo` |
| 3 | Features | Grocery add/list, Chore CRUD, APScheduler |
| 4 | i18n + Briefing | Template variables, weather, calendar stub |
| 5 | Hardening | Error retries, metrics, alerts, >80 % tests |
| 6 | Pilot | Beta households onboarded, feedback collection |

---

## 15 Future Roadmap (post‑MVP)

1. **Voice Interface** – Alexa skill reusing Core API.
2. **Shared Polls** – “Pizza vs Sushi?” quick votes.
3. **Geo‑fence Reminders** – Notify when near supermarket.
4. **Business Tenant** – Separate Slack adapter with context silo.

---

## 16 References & Links

- Meta WhatsApp Business Cloud API docs (v20.0)
- OpenWeather Map OneCall API
- APScheduler 3.x
- GDPR Art. 17 “Right to erasure”

*End of document*

[Interfaces initial infra assessment](Interfaces%20initial%20infra%20assessment%201e9b4fd21ff08080a6ebccdf693562f3.md)