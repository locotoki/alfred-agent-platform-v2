# Alfred‑Biz Slack MVP – Detailed Design & Implementation Specification

# Alfred‑Biz Slack MVP – Detailed Design & Implementation Specification

*Last updated: 05 May 2025*

---

## 1 Purpose & Goals

This document explains how to build the first production‑ready version of **“Alfred‑Biz”**—the *Business* instance of Alfred that lives inside a single Slack workspace.  Alfred‑Biz re‑uses all Core APIs and services shared with Alfred‑Home but replaces the WhatsApp adapter with a Slack adapter and runs in its own isolated infrastructure.  The MVP must:

- Post a *daily morning briefing* (stand‑up summary, weather, reminders) to each team member via Slack DM.
- Maintain a shared **task list** (mirrors Alfred‑Home grocery list) and **recurring reminders** (e.g. invoice day).
- Automatically choose Portuguese **or** English based on the user’s first message.
- Respect user privacy (GDPR) and cost less than €10 / month for hosting (0 € Slack) at 10 active users.

---

## 1.1 Pre‑Implementation Checklist (“Phase 0”)

| # | Area | Action | Who |
| --- | --- | --- | --- |
| 1 | **Slack Setup** | Create Slack **App** in target workspace at [https://api.slack.com/apps](https://api.slack.com/apps). | Project Lead |
| 2 |  | Add OAuth scopes: `chat:write`, `channels:join`, `im:write`, `commands`, `channels:history`. | Project Lead |
| 3 |  | Enable **Socket Mode** *or* set **Events API** request URL (`/slack/events`). | Tech Lead |
| 4 |  | Install the app; copy **SLACK_BOT_TOKEN** and **SLACK_SIGNING_SECRET** to 1Password. | DevOps |
| 5 | **Repo Bootstrap** | Copy folder `services/alfred-home` → `services/alfred-biz`; rename adapter module. | Dev Team |
| 6 |  | Add **GitHub Actions** template (`.github/workflows/biz.yml`) that deploys only on changes inside `services/alfred-biz/**`. | DevOps |
| 7 | **Secrets / .env** | Draft `.env.template` with `SLACK_BOT_TOKEN`, `SLACK_SIGNING_SECRET`, `REDIS_URL`, `DATABASE_URL`, `OPENWEATHER_KEY`. | DevOps |
| 8 | **Cloud Accounts** | Provision new Upstash Redis + Supabase **(biz projects)**; paste URLs to `.env` *(leave home lines intact for reference)*. | DevOps |
| 9 | **Briefing Blocks** | Draft Block Kit JSON snippets for `morning_briefing` and `reminder`; no platform approval needed. | UX Writer |
| 10 | **Beta Workspaces** | Recruit 2 pilot companies (≤ 15 seats) and obtain admin consent. | Project Lead |
| 11 | **GDPR Docs** | Verify Privacy Notice already covers Slack; update Data Processing Addendum. | Legal |
| 12 | **Monitoring** | Duplicate Grafana dashboard row filtered by `instance=biz`. | DevOps |

When every checkbox is green, begin **Week 0** of the timeline below.

---

## 2 Tech‑Stack Overview

| Layer | Tech | Why |
| --- | --- | --- |
| Runtime | **Python 3.11** (`INSTANCE=biz`) | Shared Core, async support, rich Slack SDK |
| Web Framework | **FastAPI** | Async + built‑in OpenAPI docs |
| Messaging Channel | **Slack Web API + Events API 2024‑12** | Free tier, robust docs |
| Background Jobs | **APScheduler + Redis** | Same cron engine reused |
| Data Stores | **Redis** (context) + **PostgreSQL** (audit & state) | Matches Alfred‑Home for code reuse |
| Containerisation | **Docker + docker‑compose** (propagates `INSTANCE`) | Identical build chain |
| Observability | **Prometheus + Grafana + Loki** | Single dashboard, labelled `instance=biz` |
| CI/CD | **GitHub Actions** ➜ **Fly.io** | Spin‑up cost €2/mo |

---

## 3 High‑Level Architecture

```
┌────────────┐  Events API  ┌─────────────────┐   gRPC/REST   ┌────────────┐
│   Slack    │ ───────────▶ │  Adapter Svc    │ ───────────▶ │  Core API  │
│  Workspace │              │  (FastAPI)      │               │ (Shared)   │
└────────────┘              └─────────────────┘               └────────────┘
          ▲                            │                           │
          │                            ▼                           ▼
   Slash/DM Cmds                 Redis (context)           PostgreSQL (state)

```

> Deployment note: This service is deployed to Fly.io as alfred‑biz.  The codebase is identical to Alfred‑Home except for the adapter and the default INSTANCE=biz environment variable.
> 
- **SlackAdapter** – Verifies request signature (v0 scheme), converts event payloads to `InboundMessage`, calls Slack Web API for responses.
- **Core API** – Unchanged; contains `FamilyCoordinatorAgent`, services, scheduler endpoints.
- **Redis** – Keys identical to Home instance but live in separate Redis project for isolation.
- **PostgreSQL** – Same schema; future optional RLS can enable cross‑instance analytics.

---

## 4 Data Model

Exactly matches Alfred‑Home (see Home spec §4).  *No additional tables are required for Slack.*  The `tz_offset` column enables correct cron timing across client companies.

---

## 5 Message Formats (Slack Block Kit)

### 5.1 Morning Briefing `morning_briefing`

```json
{
  "blocks": [
    {"type": "header", "text": {"type": "plain_text", "text": "Bom dia, ${name} ☀️"}},
    {"type": "section", "text": {"type": "mrkdwn", "text": "*Hoje tens ${count} compromisso(s):*\n${events}"}},
    {"type": "context", "elements": [
      {"type": "mrkdwn", "text": ":thermometer: *${temp}°C*  ${weather_desc}"},
      {"type": "mrkdwn", "text": ":pushpin: ${reminder}"}
    ]},
    {"type": "divider"},
    {"type": "section", "text": {"type": "mrkdwn", "text": "*Tarefas pendentes:* ${tasks}"}}
  ]
}

```

### 5.2 Reminder `task_reminder`

```json
{
  "text": "Lembrete: ${task}",
  "blocks": [
    {"type": "section", "text": {"type": "plain_text", "text": "🔔 ${task}"}},
    {"type": "actions", "elements": [
      {"type": "button", "action_id": "mark_done", "text": {"type": "plain_text", "text": "✅ Feito"}},
      {"type": "button", "action_id": "snooze", "text": {"type": "plain_text", "text": "⏰ Lembrar mais tarde"}}
    ]}
  ]
}

```

Slack templates need **no pre‑approval**, speeding iteration.

---

## 6 Core Classes (Python)

Identical to Home except the adapter:

```python
class SlackAdapter(IAdapter):
    async def send(self, channel_id: str, payload: dict) -> None: ...
    async def receive(self, inbound: dict) -> InboundMessage: ...

```

---

## 7 Interaction Flows

### 7.1 App Installation & Onboarding

1. Admin installs Alfred‑Biz ➜ OAuth completes; bot joins `#general`.
2. User runs `/alfred start` ➜ Adapter verifies signing secret and Slack slash‑command format.
3. Core links user to a *business* family row; starts morning briefing.

### 7.2 Morning Briefing Job

Same as Alfred‑Home but message sent via `chat.postMessage` to each user’s `im` channel.

### 7.3 Add Task

```
User: /alfred add-task "Pay invoices"
Core: updates Redis list; replies with confirmation block.

```

### 7.4 Reminder Flow

1. APScheduler checks tasks hourly.
2. If due, posts `task_reminder` with interactive buttons.
3. Slack interaction payload hits `/slack/actions` ➜ `ChoreService.mark_done()` or snooze logic.

---

## 8 API Endpoints

| Method | Path | Purpose |
| --- | --- | --- |
| **POST** | `/slack/events` | Receives events & slash commands |
| **POST** | `/slack/actions` | Handles interactive buttons & modals |
| **GET** | `/healthz` | Load‑balancer probe |

Both endpoints require signature verification using `SLACK_SIGNING_SECRET`.

---

## 9 Deployment (Docker‑Compose Snippet)

```yaml
version: "3.9"
services:
  api:
    build: ./services/core
    env_file: .env
    environment:
      - INSTANCE=biz
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

Fly io `fly.toml` sets 256 MB Lite VM in EU‑MAD region (same as Home).

---

## 10 Security & Privacy

- **Request Signing** – Verify `X-Slack-Signature` + `X-Slack-Request-Timestamp` (v0) per Slack docs.
- **Role‑based access** – Only workspace admins can run `/alfred admin-*` commands.
- **GDPR** – `/admin/delete_user/{id}` applies to Slack IDs; data purged within 30 days.
- **Data Isolation** – Alfred‑Biz Redis/Supabase projects separate from Alfred‑Home. No shared secrets.

---

## 11 Monitoring & Alerts

Re‑use Prometheus/Loki stack; all metrics include label `instance=biz` for easy dashboard filtering.

---

## 12 Testing Strategy

| Layer | Tool | Target Coverage |
| --- | --- | --- |
| Unit | pytest | 80 % branches |
| Contract | `schemathesis` (+ FastAPI OpenAPI) | 100 % endpoints |
| Integration | Slack Sandbox (`@slack/bolt`) | Slash/DM round‑trip |
| Load | `locust` | 50 events/s, p95 < 300 ms |

Pilot rollout to 2 workspaces for 2 weeks.

---

## 13 Cost Estimate (Monthly, 10 users)

| Item | Unit Cost | Quantity | Sub‑total |
| --- | --- | --- | --- |
| Slack usage | €0 | – | €0 |
| Fly io Lite VM | €2 / mo | 1 | €2 |
| Redis (Upstash free tier) | €0 | – | €0 |
| Postgres (Supabase starter) | €0 | – | €0 |
| Prometheus stack | Self‑host | 256 MB VM | included |
| **Total** |  |  | **≈ €2.00** |

Combined **Home + Biz** platform cost remains **€4–6/month**.

---

## 14 6‑Week Implementation Plan (Delta‑Focused)

The majority of tasks mirror Alfred‑Home.  Only *net‑new* or *changed* tasks are listed below.

| Wk | Day | Task ID | Task Description | Owner | Est (hr) | Depends On |
| --- | --- | --- | --- | --- | --- | --- |
| **0** | Tue | B0‑2 | Clone `services/alfred-home` ➜ `services/alfred-biz`; rename package imports. | Dev | 3 | – |
|  | Wed | B0‑3 | Implement `SlackAdapter` with signature verification. | Dev | 6 | B0‑2 |
|  | Wed | B0‑4 | Update Docker env defaults to `INSTANCE=biz`. | Dev | 1 | B0‑3 |
| **1** | Mon | B1‑1 | Add `/slack/events` and `/slack/actions` routes. | Dev | 4 | B0‑4 |
|  | Tue | B1‑2 | Slash command `/alfred` parser and help. | Dev | 5 | B1‑1 |
| **2** | Mon | B2‑1 | Draft Block Kit morning briefing; unit tests. | UX | 4 | B1‑2 |
|  | Tue | B2‑2 | Interactive button handler (`mark_done`, `snooze`). | Dev | 4 | B2‑1 |
| **3** | Wed | B3‑1 | End‑to‑end tests with Slack sandbox. | QA | 6 | B2‑2 |
| **4** | Fri | B4‑1 | Load test 50 events/s (Locust + Bolt). | QA | 4 | B3‑1 |
| **5** | Thu | B5‑1 | Security audit (OAuth scopes, CSRF). | Sec | 3 | B4‑1 |
| **6** | Mon | B6‑1 | Deploy `v0.1.0` to production workspace. | DevOps | 2 | B5‑1 |

All other timeline tasks (metrics, GDPR delete, alerts) are inherited from Alfred‑Home and tracked in the shared roadmap.

---

## 15 Future Roadmap (post‑MVP)

1. **Multi‑workspace Support** – OAuth install flow for unlimited tenants.
2. **Jira Integration** – Sync tasks to Jira issues.
3. **Knowledge Search** – Connect to Confluence & Notion.
4. **Voice Chat (Zoom/Meet)** – Live summariser powered by Core API.

---

## 16 References & Links

- Slack API docs (Web API, Events API, Block Kit)
- Slack Signing Secrets verification guide
- APScheduler 3.x
- GDPR Art. 17 “Right to erasure”

*End of document*