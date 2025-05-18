# Alfred‑core – Comprehensive Overview (18 May 2025, **Local‑First Edition**)

## 1. Problem & Vision
You want **one AI assistant engine** that can juggle your personal life *and* your business without data bleed. Alfred‑core is a single code‑base deployed twice—**Alfred‑Home** (WhatsApp) and **Alfred‑Biz** (Slack)—yet runs comfortably on a single local machine.

---

## 2. User‑Facing Capabilities (first 6 weeks)
| Instance | Channel | MVP skills | Post‑MVP add‑ons |
|----------|---------|------------|------------------|
| **Home** | WhatsApp | grocery list, chore reminders, morning briefing, “remember” notes | home‑automation hooks, voice interface |
| **Biz**  | Slack | daily stand‑up, shared task list, invoice/expense reminders, inbox summary | CRM sync, travel planner, Jira/Notion search |

Both instances: Portuguese/English locale, proactive alerts, context memory, multimodal answers.

---

## 3. Core Architecture

### Runtime block diagram

```
┌──── Adapter ────┐   ┌──── Alfred‑core ───┐   ┌──────── Persist ────────┐
│ WA / Slack RTM  │⇒⇒│ Intent router +    │⇒⇒│ Redis (db0, key prefix) │
│ Sig‑verify      │  │ plugin skills      │  │ Postgres (two schemas)  │
│ JSON → Message  │  │ ↳ LLM adapter      │  └──────────────────────────┘
└─────────────────┘   └────────────────────┘
```

- **LLM** – GPT‑4o‑Turbo primary; Claude & Llama3 adapters idle
- **Skills** – hot‑reload plugins in `skills_home/` or `skills_work/`
- **State (local)** – *one* Redis container (key prefixes `home:` / `biz:`) and *one* Postgres container with **two schemas** (`home`, `biz`).
- **Isolation (local)** – two running app containers sharing DB engines but *never* crossing schema/prefix boundaries.
- **Isolation (prod)** – flip `DATABASE_URL` and `REDIS_URL` per instance to point at separate Supabase & Upstash DBs for hard isolation.
- **Observability** – Prometheus, Loki, Grafana (`instance=home|biz`).

Performance targets: p90 < 2 s, 99.9 % uptime, < 512 MB RAM per app.

### Minimal `docker-compose.yml`

```yaml
version: '3.9'
services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_PASSWORD: example
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports: ["5432:5432"]

  redis:
    image: redis:7
    ports: ["6379:6379"]

  alfred-home:
    build: .
    environment:
      APP_MODE: home
      DATABASE_URL: postgres://postgres:example@postgres:5432/postgres?schema=home
      REDIS_PREFIX: home
    depends_on: [postgres, redis]
    ports: ["8001:8000"]

  alfred-biz:
    build: .
    environment:
      APP_MODE: biz
      DATABASE_URL: postgres://postgres:example@postgres:5432/postgres?schema=biz
      REDIS_PREFIX: biz
    depends_on: [postgres, redis]
    ports: ["8002:8000"]

volumes:
  pgdata:
```

---

## 4. Phased Roadmap (0 → 6 weeks)
| Week | Deliverable | Notes |
|------|-------------|-------|
| -1 | ADR‑001‑005 (LLM, State, Skills, Personality, Observability) | Lock decisions |
| 0  | Webhook online + Prom counter | WhatsApp verify & `/alfred ping` |
| 1  | Core round‑trip via IntentRouter | Logs in Loki |
| 2  | Language detect, DB migrations (`home`, `biz` schemas) | Pact tests |
| 3  | Home skills + scheduler | Eval harness on last 100 utterances |
| 4  | Morning briefing live | Daily cost alert |
| 5  | Load & sec scan, cost guard‑rail | 5 % canary deploy (local → staging) |
| 6  | GA: 2 households + internal Slack pilot | Kick off Biz adapter fork |

---

## 5. Living Documentation
| Doc | Purpose |
|-----|---------|
| *Alfred‑Home WhatsApp MVP – Detailed Design* | Functional spec & infra guide |
| *Single Source of Truth – Ops Guide* | Day‑2 run‑book |
| *Path to Alfred‑Biz* / *Slack MVP spec* | Biz delta & timeline |
| *Interfaces Infra Assessment* | Quarterly audit |

---

## 6. Outstanding Gaps
1. **ADR‑006 – Security & threat model**
2. **Cost guard‑rail middleware**
3. **Automated model‑swap evaluation harness**
4. **Skill developer CLI**
5. **Quiet‑hours policy**

---

## 7. Why This Approach Works (Local Variant)
- **One Compose stack:** turn‑key dev experience; mirrors prod logic.
- **Logical isolation:** schemas & key prefixes guarantee no data bleed.
- **Upgrade path:** swap env vars to split into dedicated cloud DBs without code change.
- **Low cost:** stays free on local; moves to ≈ €4–6 / month in prod.
- **Same plugin system & LLM abstraction:** skills stay portable.
