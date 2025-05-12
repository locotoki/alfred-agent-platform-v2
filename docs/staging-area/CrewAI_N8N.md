# Integration Blueprint: CrewAI & n8n for Alfred Agent Platform

*Version 0.1 – 2025‑05‑11*

---

## 1 · Objective

Bring **CrewAI** (multi‑agent orchestration) and **n8n** (workflow/integration layer) into the existing Alfred Agent Platform repo (`locotoki/alfred-agent-platform-v2`) without breaking current LangChain/LangGraph flows.

---

## 2 · Phase Roadmap (excerpt)

| Phase                       | What we will deliver                                            |
| --------------------------- | --------------------------------------------------------------- |
| **3.1 · Containerise**      | Dockerfile for CrewAI service; docker‑compose stanza for n8n    |
| **3.2 · Pub/Sub bindings**  | Topics: `crew.tasks`, `crew.results`, `n8n.events`              |
| **3.3 · Crew templates**    | `BaseCrew` wrapper emitting Pub/Sub envelopes                   |
| **3.4 · n8n starter flows** | PR‑triage & Daily‑metrics workflows stored in `/workflows/n8n/` |
| **3.5 · Secrets & env**     | Extend `.env.example` + docs                                    |
| **3.6 · Monitoring**        | Prometheus scrape + Grafana dashboard patches                   |
| **3.7 · CI/CD**             | New matrix jobs & container publish                             |
| **3.8 · Docs & onboarding** | Service docs in `/docs/services/`                               |

---

## 3 · Data We Still Need

1. Full list of **environment variables** already in use across services.
2. Existing **Pub/Sub topics** and which components subscribe/publish.
3. **Ports** currently occupied by docker‑compose services.
4. Inventory of **CI jobs** that build/push images.
5. Any **Prometheus metrics** endpoints already exposed.

Collecting this baseline will let us fine‑tune names, avoid port clashes, and write minimal migration docs.

---

## 4 · Prompt for Claude (Code Assistant) – *Generate Baseline Report*

```text
You are a code assistant with filesystem access to the checked‑out Alfred Agent Platform monorepo.

**Goal**: produce a concise report (`integration_baseline.md`) that enumerates:
1. **Docker‑compose services** – service name, image, exposed ports (parse all `docker-compose*.yml`).
2. **Pub/Sub topics** referenced in code, Terraform or scripts.
3. **Environment variables** found in `.env*` files, compose files, Helm charts, or K8s manifests.
4. **CI jobs** that build & publish containers (scan `.github/workflows`).
5. **Prometheus metrics endpoints** – search for `prometheus_client` usage or `metrics:` exposure.

**Steps** (you may use shell & Python):
- Prefer parsing over regex where possible (`yq`, `jq`, `python -m pyyaml`).
- Output one **markdown table** for each numbered section.
- For every item include **file path** in parentheses for traceability.
- Write the final report to the repo root as `integration_baseline.md`.

Return success message with the path of the generated file.
```

---

## 5 · Immediate Action Items

*

*End of v0.1*
