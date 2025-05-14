# Alfred-Home  –  Implementation Specification

Below is a **straight-through build plan** that plugs directly into the stack you already stood up for the Family MVP—Fly.io + Docker, Supabase Postgres, Upstash Redis, GitHub Actions, Prometheus / Grafana / Loki—and delivers two hard-isolated assistants:

```
bash
CopyEdit
Alfred-Home  (Fly app alfred-home-eu)   ← WhatsApp #1
Alfred-Biz   (Fly app alfred-biz-eu)    ← Slack bot   (add WA #2 later if ever needed)

```

---

## 0 · Pre-flight audit (½ day)

| Check | Why |
| --- | --- |
| **Fly org**: two Lite VMs available in the same region (EU-MAD) | matches existing `fly.toml` from MVP |
| **Supabase**: one free-tier project already exists → create a second (`alfred_biz`) | real physical isolation beats RLS gymnastics for a team of one |
| **Upstash Redis**: click “Duplicate” on the family-redis db to make `biz-redis` | identical cold-start latency |
| **Grafana / Loki stack** is running on Fly | we’ll just add a folder & labels later |

---

## 1 · Repo surgery (4 h)

1. **Move common code** into `src/core/` (agents, db, Redis helpers).
2. Add two thin adapters:
    - `src/adapters/whatsapp` (already in Family MVP)
    - `src/adapters/slack` – FastAPI route `POST /slack/events`, signature check, json → `InboundMessage`.
3. In `src/main.py` read `INSTANCE` env var → load skills from `skills_home/` if `home` else `skills_work/`.
4. Add pytest marker `@pytest.mark.home_only` so CI skips irrelevant tests per matrix build.

---

## 2 · Secrets & env templates (1 h)

Create **`.env.template`** with two sets of vars:

```
makefile
CopyEdit
# shared
OPENAI_API_KEY=
REDIS_URL=
DATABASE_URL=
INSTANCE=

# WhatsApp-only
META_TOKEN=
PHONE_ID=
VERIFY_TOKEN=

# Slack-only
SLACK_BOT_TOKEN=
SLACK_SIGNING_SECRET=

```

Push template; GitHub Actions will pick values from repo secrets for each job.

---

## 3 · GitHub Actions matrix deploy (2 h)

```yaml
yaml
CopyEdit
jobs:
  deploy:
    strategy:
      matrix:
        instance: [home, biz]
    steps:
      - uses: actions/checkout@v4
      - name: Set env
        run: echo "INSTANCE=${{ matrix.instance }}" >> $GITHUB_ENV
      - name: Build & push
        run: docker build -t registry/${{ matrix.instance }}:${{ github.sha }} .
      - name: Fly deploy
        run: fly deploy --app alf${{ matrix.instance }}-eu --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN_${{ matrix.instance | upper }} }}

```

The same workflow you already use in the Family MVP just loops twice.

---

## 4 · Database bootstrap (2 h)

Run the identical Alembic migrations that power Family MVP against each Supabase URL:

```bash
bash
CopyEdit
supabase db reset --project-ref alfred_home
supabase db reset --project-ref alfred_biz
alembic upgrade head

```

Both schemas stay in sync; no `tenant_id` columns, no RLS rules needed.

---

## 5 · Slack bot setup (3 h) *(skip if you’ll use WhatsApp #2 instead)*

1. `api.slack.com/apps` → **Create App** → **From scratch**.
2. Enable **Socket Mode** or Events API (URL = `https://alfred-biz.fly.dev/slack/events`).
3. Scopes: `chat:write`, `commands`, `app_mentions:read`.
4. Paste `SLACK_BOT_TOKEN`, `SLACK_SIGNING_SECRET` into Fly secrets for `alfred-biz`.
5. Slash command `/alfred` → Request URL same as above, method `POST`.
6. Smoke test: `/alfred ping` returns “pong”.

---

## 6 · WhatsApp #1 runs exactly as today (0 h)

Nothing changes for Alfred-Home; it keeps the Family MVP webhook and outbound worker flow Alfred WhatsApp Family …Alfred Multi‑Tenant Age….

---

## 7 · Skill separation (4 h)

| Folder | Contents |
| --- | --- |
| `skills_home/` | `GroceryService`, `ChoreService`, `MorningBriefingJob` from MVP Alfred WhatsApp Family …Alfred WhatsApp Family … |
| `skills_work/` | `WorkInboxService` (e-mail summariser), `CRMQueryService`, `/expense` command |
| `skills_shared/` *(optional)* | Date-time utils, language detection, LLM prompt helpers |

Loader logic:

```python
python
CopyEdit
import importlib, pkgutil, os
INSTANCE = os.getenv("INSTANCE", "home")
for mod in pkgutil.iter_modules([f"skills_{INSTANCE}"]):
    importlib.import_module(f"skills_{INSTANCE}.{mod.name}")

```

---

## 8 · Observability & alerts (2 h)

1. In Prometheus scrape configs, add label `instance` via `relabel_configs`:

```yaml
yaml
CopyEdit
- source_labels: [__meta_kubernetes_pod_label_fly_app_name]
  target_label: instance

```

1. Duplicate Grafana dashboard, set variable `instance =~ /alfred-.*/`.
2. Alert rule: **>1 % 5xx in 5 min** per instance → PagerDuty.

---

## 9 · Token rotation automation (1 h)

In 1Password **Home** vault set item *Meta-Token-Home*; in **Biz** vault set *Slack-Bot-Token*.

Create a GitHub Action scheduled weekly:

```yaml
yaml
CopyEdit
run: fly secrets set META_TOKEN=$(op read "op://Home/Meta-Token-Home/password")

```

Same for Slack secret. Keeps blast radius to one bot.

---

## 10 · End-to-end smoke tests (3 h)

*Home*:

```
bash
CopyEdit
POST /webhook  body="add bananas"
→ expect 200
→ GET /redis/grocery -> ["bananas"]

```

*Biz* (Slack):

```
bash
CopyEdit
/alfred expense 123.45
→ expect "Logged €123.45"
→ row in postgres.expn

```

---

## 11 · Roll-out sequence (1½ days)

| Day | Action |
| --- | --- |
| **1** morning | Cut `v0.2.0` tag → GitHub Actions deploy both apps |
| lunchtime | Join WhatsApp #1 group; smoke test chores & groceries |
| afternoon | Install Slack bot in workspace; ping `/alfred ping` |
| **2** morning | Dog-food for 24 h; watch Grafana latency graphs |
| afternoon | Enable Prom alert → PagerDuty; archive this checklist |

---

### Runtime cost (unchanged)

Both Lite VMs (€2 + €2) + WhatsApp convo fees (€2 – 4) ≈ **€6 / mo** total AI Agent Platform v2 Al…Alfred WhatsApp Family ….

---

## Why this plan is safe

- No shared tokens, DBs, or Redis keys → cross-leak risk is literally zero.*
- One repo, one CICD pipeline → no drift, tiny maintenance overhead.*
- When/if you need real-time personal↔business coordination, bolt the Coordination Broker + RLS back in—code already drafted* Alfred WhatsApp Family …Alfred Multi‑Tenant Age….