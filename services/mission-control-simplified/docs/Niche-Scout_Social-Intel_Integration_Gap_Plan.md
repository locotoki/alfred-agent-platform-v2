# Niche‑Scout ↔ Social‑Intel Integration Gap Plan

*Version 2025‑05‑08*

This document captures the **design‑reality disconnect**, provides a **mitigation architecture** (proxy transformation layer + joint API evolution), and breaks the work into **actionable, testable tasks**.

---

## 1 · Gap Summary

| Layer                | Original Design (Spec)                                                   | Current Reality                                              | Impact                          |
| -------------------- | ------------------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------- |
| **API contract**     | `/api/run/niche-scout` with `NicheQuery` object; returns `NicheResult[]` | `/api/youtube/niche-scout` ignores body, returns canned JSON | Irrelevant results; UI mismatch |
| **Query → Store**    | Shared TS types; single data model                                       | No guaranteed types; unknown scoring                         | Front‑end casts `any` → brittle |
| **Scoring logic**    | Transparent `(demand × RPM) / supply`                                    | Black‑box scoring                                            | Impossible to debug / tune      |
| **Progress updates** | SSE events with stages                                                   | None                                                         | Users see freezes               |

**Root cause:** Social‑Intel Agent is an **independent service**, never updated to the Niche‑Scout schema.

---

## 2 · Integration Strategy

> Deliver immediate relevance, then converge the two services.

### 2.1 Phase‑0 “Stop‑Gap” (≤ 1 week)

* Add **client‑side transform v2** (see `transformApiResponse.ts`).
* Inject **relevance filters**: string similarity ≥ 0.55 (RapidFuzz), category keyword match.
* Log transformation stats → `localStorage` + console (for QA).

### 2.2 Phase‑1 Proxy Micro‑Service (2 weeks)

```
React ──┐        POST /workflows/niche‑scout  ┌── Social‑Intel
        │                                      │
        ▼                                      ▼
  Proxy API  ── axios → /youtube/niche‑scout → API
   (Node/TS)     ↳ transform ↳ cache ↳ metrics
```

* **Responsibilities**

  1. **Validate** request → `NicheQuery` schema (Zod).
  2. **Forward** to Social‑Intel.
  3. **Transform** into `NicheResult[]`.
  4. **Cache** by SHA‑256(request) TTL = 1 h (Redis).
  5. **Emit metrics** (`/metrics` Prometheus).
* **Benefits**: keeps Mission Control thin; transformation is centrally testable.

### 2.3 Phase‑2 Joint API Upgrade (4–6 weeks, parallel)

* Draft **v2 contract** shared between teams (`openapi/niche‑scout.yaml`).
* Social‑Intel implements real parameter filtering + returns `opportunity_score` & breakdown.
* Remove 80 % of proxy transform when API passes conformance tests.

### 2.4 Phase‑3 Feedback & Learning (8+ weeks)

* Capture user engagement (views, saves) in Supabase table `niche_feedback`.
* Train **relevance booster** (XGBoost on embeddings + meta‑features).
* Proxy adds `?userId` to personalize ordering.

---

## 3 · Proxy Detailed Design

### 3.1 Endpoints

| Method   | Path                     | Purpose                |
| -------- | ------------------------ | ---------------------- |
| `POST`   | `/workflows/niche-scout` | Main proxy + transform |
| `DELETE` | `/cache/:key`            | Admin cache purge      |
| `GET`    | `/metrics`               | Prometheus exposition  |

### 3.2 Env Vars (`.env`)

```
SOCIAL_INTEL_URL=http://social‑intel:9000
REDIS_URL=redis://cache:6379
PROXY_PORT=3001
CACHE_TTL=3600          # seconds
SIMILARITY_THRESHOLD=0.55
```

### 3.3 Transform Algorithm (pseudo‑code)

```ts
export async function transform(src: SocialIntelResp, q: NicheQuery): Promise<NicheResult[]> {
  const rel = (name: string) => similarity(name, q.query) >= +process.env.SIMILARITY_THRESHOLD;
  const keep = src.niches.filter(n => rel(n.name) && inCategory(n, q.category));
  return keep.map(mapFields);
}
```

### 3.4 Metrics

| Name                          | Type      | Description       |
| ----------------------------- | --------- | ----------------- |
| `proxy_api_calls_total`       | Counter   | Upstream requests |
| `proxy_cache_hit_total`       | Counter   | Redis hits        |
| `proxy_transform_duration_ms` | Histogram | Transform latency |
| `proxy_errors_total`          | Counter   | 5xx responses     |

---

## 4 · Test Plan

1. **Contract tests** (`jest` + `supertest`) – ensure 200 ↔ valid `NicheResult[]`.
2. **Transformation relevance** – embed titles with `@langchain/openai` → cosine ≥ 0.4 to query.
3. **Cache behaviour** – two identical POSTs hit Redis (mock) once.
4. **Load test** – `k6` ramp 100 → 1 000 VUs, p99 < 300 ms.

---

## 5 · Timeline & Ownership

| Week       | Deliverable                            | Owner       |
| ---------- | -------------------------------------- | ----------- |
| **W19**    | Client‑side transform v2, logging      | @frontend   |
| **W20–21** | Proxy service deployed to staging      | @backend    |
| **W22–23** | Contract v2 signed, SI team dev        | @SI‑liaison |
| **W24**    | Roll proxy to prod; remove client hack | @devops     |

---

## 6 · Open Risks & Mitigations

| Risk                                              | Likelihood | Impact | Mitigation                               |
| ------------------------------------------------- | ---------- | ------ | ---------------------------------------- |
| Social‑Intel backlog delays filter implementation | M          | H      | Keep proxy long‑term; raise threshold    |
| Redis outage causes latency spike                 | M          | M      | Fallback to in‑memory LRU 1 h            |
| Transform relevance false negatives               | L          | M      | Lower similarity threshold + manual tune |

---

## 7 · Acceptance Criteria (Phase‑1)

* **AC‑1**: POST `/workflows/niche‑scout` with `{query:"mobile",category:"Gaming"}` returns ≥ 5 niches containing “mobile” or synonyms.
* **AC‑2**: First progress metric `proxy_transform_duration_ms` observed in Prometheus.
* **AC‑3**: Cache hit ratio ≥ 70 % for identical queries in load test.
* **AC‑4**: End‑to‑end Cypress test green (UI shows relevant cards).

---

> *Once this plan is executed, Mission Control users will consistently receive topic‑appropriate results while the Social‑Intel team retrofits native parameter support. The proxy can then be slimmed or removed.*

---

## 8 · Pre‑Implementation Readiness & Concerns

This section captures the outstanding questions and control gates surfaced by the Claude Desktop assessment. All items **MUST** be signed‑off before Phase‑1 (proxy) goes live.

### 8.1 Technical Concerns & Mitigations

| Area                           | Question(s)                                                | Decision / Action                                                                                                                                                                                           |
| ------------------------------ | ---------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **API stability & versioning** | Is SI API still evolving? Does it expose a `/v{n}` prefix? | • Adopt `/v1/` in proxy paths.<br>• Add response‑header check (`x-si-version`).<br>• Alert on version drift via Prometheus rule `si_version_mismatch_total`.                                                |
| **Auth & security**            | Are API keys or JWTs required?                             | • Proxy will read `SI_API_KEY` env var and add `Authorization: Bearer`.<br>• Rotate keys monthly via Vault.<br>• Add mTLS option flag for prod.                                                             |
| **Error handling**             | How to isolate upstream failures?                          | • Implement `axios-retry` (3 ×, exp back‑off).<br>• Use `opossum` circuit‑breaker: open after 5 failures / 30 s.                                                                                            |
| **Cache invalidation**         | How to refresh stale niches?                               | • Respect `Cache-Control` or last‑modified header if SI adds it.<br>• Provide `/cache/flush?queryId=` endpoint for manual bust.<br>• Set default TTL = 1 h, but overrideable per request via `x-cache-ttl`. |
| **Data volume**                | Payload size? Pagination?                                  | • Proxy enforces `MAX_ITEMS_PER_RESPONSE` (env, default = 50).<br>• Stream large payloads with `Transfer-Encoding: chunked`.                                                                                |

### 8.2 Operational Concerns

| Topic                     | Resolution                                                                                                                                        |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Monitoring & alerting** | • Alerts: p95 latency > 500 ms (critical), error\_rate > 2 % (warning), cache\_hit < 40 % (info).<br>• PagerDuty escalation to `#mc‑on‑call`.     |
| **Deployment**            | • Helm chart `proxy‑svc` in MC‑k8s cluster.<br>• Feature flag `proxy.enabled` default false in production; gradual 10 → 100 % rollout.            |
| **Load testing**          | • Use `k6` with recorded real queries.<br>• Peak target: 1 000 RPM, 25 RPS steady.<br>• Upstream SI API hit capped with `--vus 100` to avoid DoS. |

### 8.3 Organizational Concerns

| Area               | Action                                                                          |
| ------------------ | ------------------------------------------------------------------------------- |
| Team coordination  | Weekly 30‑min stand‑up SI & MC (Tuesdays 15:00 UTC).                            |
| Knowledge transfer | Confluence page + Loom walkthrough; code comments mandatory.                    |
| Success metrics    | • User CTR on niches +15 %.<br>• Support tickets on “irrelevant results” −80 %. |
| Budget/resource    | Project allocated 0.5 FTE BE, 0.3 FTE FE, 0.2 FTE DevOps for 8 weeks.           |

### 8.4 Implementation Readiness Checklist

* [ ] Access confirmed to SI staging API & docs
* [ ] `.env.example` includes all auth & tuning flags
* [ ] CI pipeline (GitHub Actions) builds Docker + runs jest / lints
* [ ] Grafana dashboard `proxy‑overview` created
* [ ] Rollback guide in `RUNBOOK.md`

---

## 9 · Timeline Adjustments & Risk Matrix

Add one week buffer (W21‑22) for auth & circuit‑breaker QA.

| Risk                            | Current Mitigation                    | Residual Risk |
| ------------------------------- | ------------------------------------- | ------------- |
| Auth tokens expire unexpectedly | Key rotation cron + healthcheck ping  | L → M         |
| SI API schema change            | Version header alert + contract tests | M             |
| Cache stampede on purge         | Redis `SETNX lock` around refresh     | L             |

---

## 10 · Sign‑off

This plan revision requires sign‑off from:

* **Tech Lead (Mission Control)** – *@tech‑lead*
* **SI API Owner** – *@si‑owner*
* **DevOps** – *@devops‑lead*

Once all checkboxes in §8.4 are ticked and sign‑off recorded in Confluence, Phase‑1 implementation may proceed.
