# Alfred‑Home & Alfred‑Biz — Comprehensive Guide

# Alfred‑Home & Alfred‑Biz — Comprehensive Guide

*version 0.3 – May 2025*

---

## 1 · Objective

Run **one code‑base** as **two isolated assistants**:

| Instance | Channel | Scope |
| --- | --- | --- |
| **Alfred‑Home** | WhatsApp #1 | family chores, reminders, shopping |
| **Alfred‑Biz** | Slack bot (optionally WhatsApp #2) | email summaries, CRM, expenses |

No personal⇄business data leakage, minimal infra overhead (< €6 / month).

---

## 2 · High‑Level Architecture

```
┌──────────────┐  Webhook   ┌────────────────────────┐
│ WhatsApp #1  │──────────▶│ Alfred‑Home (FastAPI)   │
└──────────────┘            │ skills_home + core     │──┐
                            └────────────────────────┘  │  Redis‑H
                                                       │  Postgres‑H
           GitHub Actions  ⇢  Fly app  ⇢  EU‑MAD  ──────┤
                                                       ▼
┌───────────┐ Events  ┌────────────────────────┐   ┌──────────────┐
│  Slack    │────────▶│ Alfred‑Biz  (FastAPI)  │──▶│WhatsApp #2* │
└───────────┘         │ skills_work + core     │   └──────────────┘
                      └────────────────────────┘
                           Redis‑B │ Postgres‑B

```

*WA #2 optional — start with Slack only.*

---

## 3 · Repository Layout

```
repo/
├─ src/
│   ├─ core/                # orchestrator, db, utils
│   ├─ skills_home/         # grocery, chores, memory
│   ├─ skills_work/         # inbox, CRM, expenses
│   └─ adapters/
│       ├─ whatsapp/
│       │    └─ handler.py  # webhook → InboundMessage
│       └─ slack/
│            └─ handler.py  # /events or RTM
├─ alembic/                 # migrations shared by both DBs
├─ Dockerfile               # single image
├─ fly.toml                 # reused by GH Actions matrix
└─ docs/                    # this file + quickstarts

```

---

## 4 · Data Stores

| Layer | Home (free tier) | Biz (free tier) |
| --- | --- | --- |
| **DB** | Supabase `alfred_home` | Supabase `alfred_biz` |
| **Cache** | Upstash Redis `home‑redis` | Upstash Redis `biz‑redis` |
| **Back‑ups** | S3 `alfred‑home‑backup‑eu` | S3 `alfred‑biz‑backup‑eu` |

No shared resources ⇒ zero cross‑contamination. Row‑level security stays **ON** as defence‑in‑depth.

---

## 5 · Secrets & CI/CD

- `.env.template` enumerates all variables.
- GitHub Actions **matrix** deploys:

```yaml
strategy:
  matrix: {instance: [home, biz]}

```

- Each Fly app stores its own secret set: `META_TOKEN_HOME`, `SLACK_BOT_TOKEN`, etc.
- Weekly token‑rotation cron pulls fresh values from 1Password → `fly secrets set`.

---

## 6 · Deployment Checklist (7 days)

| Day | Action |
| --- | --- |
| **0** | Audit Fly quota; clone repo; run docker‑compose locally. |
| **1** | WA #1 onboarding (Meta Business acct, phone, token, webhook). |
| **2** | Slack bot creation (or WA #2 repeat Day 1). |
| **3** | Refactor draft `main.py` into `adapters/whatsapp/handler.py`; wire Redis/Postgres. |
| **4** | Port **skills_home**; stub **skills_work**. Unit tests pass. |
| **5** | Deploy Fly apps `alfred-home-eu`, `alfred-biz-eu`. |
| **6** | Grafana dashboards per `instance`; Loki labels. |
| **7** | End‑to‑end smoke tests; enable PagerDuty alert. |

---

## 7 · Local Sandbox (Quick‑Start)

```
docker compose up  # spins WhatsApp adapter + ngrok tunnel
export NGROK_URL=https://abcd.ngrok.io
# Set webhook URL in Meta to $NGROK_URL/webhook

```

Fast iteration without touching Supabase/Fly.

---

## 8 · Security Hardening

1. Strict CORS & HMAC verification on webhooks.
2. Outbound domains allow‑list: Home → `graph.facebook.com`; Biz → `slack.com`.
3. Loki keeps 30 d logs, then ships gzip to S3 (180 d retention).
4. GitHub branch‑protections: Biz build fails if diff touches `skills_home/*` and vice‑versa.

---

## 9 · Cost Snapshot (monthly)

| Item | Home | Biz | Total |
| --- | --- | --- | --- |
| Fly Lite VM | €2 | €2 | €4 |
| Supabase starter | €0 | €0 | €0 |
| Upstash Redis | €0 | €0 | €0 |
| WhatsApp conv. | €2‑4 | €0 (Slack) | €4‑6 |

---

## 10 · Roadmap

- **T+30 d** – Add read‑only JSON bridge Biz → Home (family can see travel schedule).
- **T+90 d** – Decide if live Coordination Broker (multi‑tenant) is worth adding.
- **T+120 d** – Voice interface (Alexa/Google) to whichever instance user chooses.

---

## Appendix A · WhatsApp Business Quick‑Start

```
1. Meta Business Suite → Create Account
2. Add WhatsApp Business API product
3. Register phone (can be test number) & verify
4. Generate long‑lived access token (60 d)
5. Webhook → https://alfred-home.fly.dev/webhook
   - Subscribe to messages, message_deliveries, message_status
6. Paste META_TOKEN_HOME + PHONE_ID_HOME into Fly secrets
7. Send "hello" from phone → Alfred replies "Howdy, I’m Alfred‑Home"

```

---

## Appendix B · Slack Bot Quick‑Start (Biz)

```
1. https://api.slack.com/apps → Create App «Alfred‑Biz»
2. Enable Socket Mode OR Events API
   - Request URL: https://alfred-biz.fly.dev/slack/events
3. Scopes: chat:write, commands, app_mentions:read
4. Install to workspace; copy Bot Token + Signing Secret
5. Fly secrets set SLACK_BOT_TOKEN … SLACK_SIGNING_SECRET …
6. Slash command /alfred ping → Alfred‑Biz: pong

```

---

## Appendix C · Skill Template

```python
# skills_home/grocery.py
from core import orchestrator, db

@orchestrator.skill(trigger=[r"(?i)add (.+) to (?:the )?shopping list"])
async def add_item(ctx, match):
    item = match.group(1)
    await db.add_grocery(ctx.user_id, item)
    return f"✓ Added {item} to the shopping list."

```

---

*End of document.*