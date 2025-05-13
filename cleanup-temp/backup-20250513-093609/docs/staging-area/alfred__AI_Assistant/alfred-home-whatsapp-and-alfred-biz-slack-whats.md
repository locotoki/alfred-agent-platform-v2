# Alfred-Home (WhatsApp) and Alfred-Biz (Slack/WhatsApp) — one-engine / two-instance blueprint

**lfred-Home (WhatsApp) and Alfred-Biz (Slack/WhatsApp) — one-engine / two-instance blueprint**

---

### 1 · Core objective

Run a single codebase in two completely isolated deployments so your private life and your business never touch, yet you only maintain one set of skills, tests and CI.

---

### 2 · Logical architecture (thin & symmetrical)

```
bash
CopyEdit
┌─────────────┐    Webhook    ┌────────────────┐
│ WhatsApp #1 │ ────────────▶ │ Alfred-Home    │───┐
└─────────────┘               │ FastAPI svc    │   │ Redis-H
                              └────────────────┘   │ Postgres-H
                                                   ▼
                       GitHub Actions  ⇢  Fly app  ▲
                                                   │
┌──────────┐   Events     ┌────────────────┐   ┌─────────────┐
│ Slack RTM│─────────────▶│ Alfred-Biz     │──▶│WhatsApp #2* │
└──────────┘ (or Webhook) │ FastAPI svc    │   └─────────────┘
                          └────────────────┘
                               Redis-B │ Postgres-B

```

*Second phone number only if you need WhatsApp for business; otherwise Slack is enough.*

- Hard isolation: separate `.env`, databases, Redis, Secrets Manager keys. No network path between H & B.
- Shared repo: `services/core` (skills, LLM orchestration) + `services/adapter_whatsapp` + `services/adapter_slack`.
- Each service loads only the skills tagged for its `INSTANCE=home|biz` env var.

---

### 3 · Design decisions (why they’re safe & simple)

| Topic | Decision | Rationale & reference |
| --- | --- | --- |
| **Data stores** | Two separate Supabase/Postgres projects + two Upstash Redis | Physical isolation beats RLS gymnastics for a team of one; mirrors Family-MVP tables verbatim |
| **Messaging channels** | WhatsApp Cloud API for Home; Slack RTM (or second WhatsApp) for Biz | Keeps contexts visually distinct; Cloud API steps already scripted |
| **Auth & secrets** | Long-lived Meta token in 1Password vault “Home”; Slack bot token / second Meta token in vault “Biz” | Never reuse credentials across vault items; rotate every 60 d per integration guide §6 |
| **Code organisation** | Monorepo; `core/` imports skills from `skills_home/` or `skills_work/` on start-up | One pipeline, no duplication |
| **CI/CD** | Single GitHub Actions workflow → two Fly apps (`alfred-home`, `alfred-biz`) with matrix deploy | Saves config drift; Family-MVP already contains Fly manifest template |
| **Observability** | One Grafana instance; dashboards filtered by Fly app name | You still see both bots at a glance, logs never mix |

---

### 4 · Implementation guide (task-by-task)

| Day | Instance | Task | Key inputs / outputs |
| --- | --- | --- | --- |
| **0-A** | — | Clone repo, create branches `home`, `biz` off `main` | Local Docker compose runs `core` tests green |
| **0-B** | — | Create `.env.template`; add `INSTANCE`, `SLACK_BOT_TOKEN`, `META_TOKEN`, `PHONE_ID` variables | Template committed |
| **1** | Home | Follow Phase-0 checklist lines 1-8 from Family-MVP spec (Meta account, phone, Redis, Postgres) Alfred WhatsApp Family … | Sandbox “hello_world” template reaches your phone |
| **2** | Biz | Slack path: create bot, enable RTM, note signing secret.  WA path: repeat Day 1 with second WABA. | Event appears in dev log |
| **3** | Both | Refactor `main.py` to read `INSTANCE`; mount `skills_home/` or `skills_work/` | `pytest -k skills` passes |
| **4** | Home | Port grocery & chore services from MVP (`GroceryService`, `ChoreService`) AI Agent Platform v2 Al…AI Agent Platform v2 Al… | Integration test adds “bananas” |
| **4** | Biz | Stub `WorkInboxService` (email summariser) & `CRMQueryService` | Unit tests green |
| **5** | Home | Deploy Fly app `alfred-home-eu` (256 MB) | `/healthz` 200 in EU-MAD |
| **5** | Biz | Deploy Fly app `alfred-biz-eu` (256 MB) | Slack slash-command `/alfred ping` returns “pong” |
| **6** | — | Grafana: import Home dashboard JSON from Family-MVP §11, duplicate & relabel for Biz Alfred WhatsApp Family …Alfred WhatsApp Family … | Latency graphs per bot |
| **7** | — | Secrets: schedule token rotation cron in 1Password; add PagerDuty alert rules (>1 % errors) | Alert fires on Locust test |

Total: ≤ 7 days solo effort (you already wrote 80 % of the code in the Family MVP).

---

### 5 · Security checklist (zero cross-contamination)

1. **Env isolation** — each Fly app has its own secret set; no shared variables.
2. **Database rules** — Supabase row-level security ON even though DBs are separate, as defence-in-depth.
3. **Outbound webhooks** — Home only whitelists `graph.facebook.com`; Biz only `slack.com` (or second FB Graph).
4. **Audit logs** — keep Loki stack per instance with label `instance=home|biz`; log retention 30 d → S3 180 d Alfred WhatsApp Family …Alfred WhatsApp Family ….
5. **CI guard-rails** — matrix deploy job aborts if branch contains files outside its instance scope (`skills_home/*` in biz build, etc.).

---

### 6 · Cost snapshot (monthly, EU region)

| Item | Home | Biz | Total |
| --- | --- | --- | --- |
| Fly Lite VM (256 MB) | €2 | €2 | €4 |
| Supabase starter | €0 | €0 | €0 |
| Upstash Redis free | €0 | €0 | €0 |
| WhatsApp conversations | €2 (≈ 35 template reopen) | €0–2* | €4 |
| Slack bot | — | €0 | €0 |
| **Approx.** | **€4–6** |  |  |

*If Biz uses Slack only, WhatsApp cost for Biz is zero.*

---

### 7 · Future-proof hooks

- One-way bridge: nightly cron in Biz exports minimal JSON calendar to S3; Home pulls via signed URL. No live RPC needed.
- If real-time sharing ever matters, resurrect the Coordination Broker & RLS scheme in Multi-Tenant draft (start with read-only rules) Alfred WhatsApp Family …Alfred Multi‑Tenant Age….
- Voice interface and Alexa skill can point to whichever instance you prefer.

---

**You now have a clear, low-risk path: two bots, one brain, confined by infra—not by hope.**