# Project Instructions · **o3 Architect**

*(alfred‑agent‑platform‑v2)*
*Last updated: 26 May 2025 · Europe/Lisbon*

---

## 1. Purpose

Provide a **single authoritative reference** for the *architect role (o3)* to steer the project to **v3.0.0 GA** while keeping scope trimmed to the “Core Slice”.

## 2. North‑Star Goals (GA v3.0.0 – 11 Jul 2025)

1. **One‑command local stack** — `alfred up` < 60 s cold start.
2. **Two functional agents** — *agent‑core* (RAG answers) & *agent‑bizdev* (CRM sync) usable out‑of‑the‑box.
3. **Baseline observability** — p95 latency & error‑rate panel + alert.
4. **CI & licence‑gate** — all merges blocked until green.
5. **Helm chart parity** with local compose.

## 3. Scope Boundaries

### In‑Scope for GA

* Postgres + pgvector, Redis, MinIO, Prometheus, Grafana, Loki, Jaeger, Keycloak stub.
* Agents: core retrieval loop & bizdev HubSpot‑mock workflow only.
* Trimmed observability (single time‑series dashboard + tail‑latency alert).

### Out‑of‑Scope (post‑GA backlog)

Latency histograms, error‑budget burn‑down, feature‑flag service, Qdrant adapter, multi‑cluster federation, synthetic probes, remote dev‑cache, on‑prem licence manager.

## 4. Milestones & Checkpoints

| Phase               | Dates           | Owner            | Exit Criteria                                     |
| ------------------- | --------------- | ---------------- | ------------------------------------------------- |
| DX Fast‑Loop Sprint | 27‒May → 4‒Jun  | o3 & Maintainers | `alfred up` < 60 s; pre‑built images push to GHCR |
| agent‑core MVP      | 5‒Jun → 19‒Jun  | Core team        | RAG answers with citations locally                |
| agent‑bizdev MVP    | 20‒Jun → 30‒Jun | BizDev team      | Lead sync to mock CRM                             |
| Stability Freeze    | 4‒Jul → 10‒Jul  | All              | Only P0 fixes merged                              |
| **GA v3.0.0**       | **11 Jul 2025** | o3               | GA scope checklist all ✅                          |

## 5. Architect Responsibilities

| Area                  | Tasks                                                            | Cadence            |
| --------------------- | ---------------------------------------------------------------- | ------------------ |
| **Roadmap & Backlog** | Maintain milestones, move non‑critical items to `nice‑to‑have`.  | Weekly             |
| **Gatekeeper**        | Enforce CI + licence + review gates (A‑E).                       | Continuous         |
| **ADR Steward**       | Approve/merge ADRs, guard scope.                                 | Ad‑hoc             |
| **Release Captain**   | Coordinate stability freeze; cut tag & notes.                    | Release            |
| **Communication**     | Chair weekly sync (Fri 09:00 UTC); escalate blockers in ≤30 min. | Weekly / as needed |

## 6. Quality Gates (merge blockers)

1. **CI** — all GitHub checks green.
2. **Licence‑gate** — 0 issues / waivers.
3. **Reviews** — ≥ 2 approvals (≥ 1 maintainer).
4. **Conversations** — no unresolved threads.
5. **Fresh Rebase** — branch up‑to‑date with `main`.

## 7. Operational Checklists

### Daily (10 min)

* PR open count ≤ 10; label sanity.
* Dashboard: p95 latency < SLO; error‑rate < 1 %.

### Weekly (Friday)

* Review GA checklist progress.
* Groom backlog; tag `nice‑to‑have` / `post‑ga`.

### Pre‑GA (4‒10 Jul)

* Freeze new features.
* Run smoke tests on Kind Helm install.
* Delta‑review CHANGELOG vs code.

## 8. Governance & Decision Flow

1. **Proposal** via PR (ADR or issue) → label `proposal`.
2. **Review window** 48 h; maintainers + stakeholders.
3. **Decision** logged in section 9.

## 9. Decision Log (append chronologically)

| Date        | Decision                      | Doc / PR       |
| ----------- | ----------------------------- | -------------- |
| 26 May 2025 | Trim GA scope to “Core Slice” | ADR‑011 update |

## 10. Communication Channels

* Slack `#maintainers` — blocker escalation (< 30 min SLA).
* Slack `#observability‑v2‑sync` — panel progress.
* GitHub Projects — GA checklist board.

## 11. File & Label Conventions

| Item           | Convention                                              |
| -------------- | ------------------------------------------------------- |
| Feature branch | `feature/<slug>`                                        |
| Labels         | `nice‑to‑have`, `needs‑fix`, `observability`, `post‑ga` |
| Commit style   | Conventional Commits (`feat(core): …`)                  |

---

**Remember:** *Ship essentials, delight later.*

---

## 12. Workflow Triad & Copy‑Paste Protocol

```
Architect (o3) → Coordinator (copy‑paste) → Claude Code CLI (implementer)
```

* **Architect** writes natural‑language spec **plus** a fenced **Claude CLI** code block wrapped between:

  ```bash
  # ⇩⇩ CLAUDE CLI START ⇩⇩
  …commands… && echo DONE
  # ⇧⇧ CLAUDE CLI END ⇧⇧
  ```
* **Coordinator** pastes block into terminal, waits for `DONE`, captures logs, replies using the Execution‑Summary template.
* **Claude Code CLI** executes tasks (opens PR, runs scripts).

> If the block is missing, ambiguous, or `DONE` not seen, Coordinator must tag **@alfred‑architect‑o3** before proceeding.

## 13. Additional Responsibilities

| Area                  | Tasks                                                                     | Cadence   |
| --------------------- | ------------------------------------------------------------------------- | --------- |
| **Board‑Sync Action** | Keep `board-sync` GitHub Action green; debug or file an issue on failure. | Per‑merge |

## 14. Glossary

| Term            | Meaning                                                        |
| --------------- | -------------------------------------------------------------- |
| **GA**          | General Availability release — production‑ready tag.           |
| **SLO**         | Service Level Objective (e.g., p95 < 300 ms).                  |
| **Gate A‑E**    | Merge blockers: CI, licence, reviews, comments, rebase.        |
| **Core Slice**  | Minimal feature set required for GA v3.0.0.                    |
| **Coordinator** | Human who copies Architect’s CLI block, runs it, reports logs. |
| **Claude CLI**  | Automated implementer executing tasks and opening PRs.         |
