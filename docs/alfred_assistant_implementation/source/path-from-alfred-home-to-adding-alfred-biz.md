# Path from Alfred-home to adding Alfred-biz

**Alfred-Biz slots in as a *parallel* instance that re-uses the same Core code but swaps only the “edges.”
Think: two thin adapters pointing at one shared brain.**

| Concern | Alfred-Home (today) | Alfred-Biz (new) |
| --- | --- | --- |
| **Adapter service** | `WhatsappAdapter` (Webhook + Graph API) | `SlackAdapter` (Events API + Web API) |
| **Repo path** | `services/alfred-home/` | `services/alfred-biz/` |
| **Container flag** | `INSTANCE=home` | `INSTANCE=biz` |
| **Deploy target** | Fly app **alfred-home** | Fly app **alfred-biz** |
| **User channel** | WhatsApp Business Cloud | Slack workspace / channel |
| **Secrets template** | `.env → META_TOKEN …` | `.env → SLACK_BOT_TOKEN, SLACK_SIGNING_SECRET` |
| **Data stores** | Upstash Redis + Supabase **(home projects)** | *Separate* Upstash/Supabase projects (empty for now) → ensures hard isolation; we can relax later with RLS if we want shared reporting tables. |
| **Cron timing** | Uses `families.tz_offset` to schedule morning briefings | Same job runner; briefing goes to Slack DM instead of WhatsApp template. |
| **CI workflow** | `gh-actions/home.yml` | `gh-actions/biz.yml` (identical steps, different APP_NAME) |
| **Observability** | Prom-/Grafana labels: `instance=home` | Prom-/Grafana labels: `instance=biz` |
| **Cost deltas** | 1 Fly Lite VM (€2) + WhatsApp marketing msgs (€1-2) | 1 Fly Lite VM (€2) + Slack free plan (0€) → total extra ≈ €2 / month |

### How to spin it up (delta from Home)

1. **Clone the service folder**

```bash
bash
CopyEdit
cp -r services/alfred-home services/alfred-biz

```

1. **Swap the adapter**

```python
python
CopyEdit
# services/alfred-biz/adapter.py
class SlackAdapter(IAdapter):
    ...

```

1. **Add Slack creds to `.env.template`** (already hinted in Phase 0 line 8).
2. **Fly setup**

```bash
bash
CopyEdit
fly launch --name alfred-biz --region mad
fly secrets set INSTANCE=biz SLACK_BOT_TOKEN=... SLACK_SIGNING_SECRET=...

```

1. **CI**

```yaml
yaml
CopyEdit
# .github/workflows/biz.yml
on:
  push:
    paths:
      - 'services/alfred-biz/**'
jobs:
  deploy:
    steps:
      - flyctl deploy --app alfred-biz

```

1. **Monitoring & alerts** – add a second Prometheus scrape job and a Grafana dashboard row filtered by `instance=biz`.

---

**TL;DR** – Alfred-Biz is **literally the same Core container started with `INSTANCE=biz` and wired to Slack**.

Everything else (infra, costs, monitoring) is a second, isolated copy so neither household data nor outages can cross-contaminate.

Let me know if you’d like this distilled into a new appendix in the spec.
