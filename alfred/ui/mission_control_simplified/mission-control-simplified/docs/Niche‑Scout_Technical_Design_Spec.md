# Niche‑Scout Technical Design Specification

*Last updated: 2025‑05‑08*

---

## 1. Purpose

Provide a reliable, explainable and continuously‑learning engine that identifies under‑served, high‑monetisation content niches for creators.
The system must surface **opportunities** (high demand × high RPM ÷ low supply), present actionable insights and learn from outcome feedback.

---

## 2. High‑Level Architecture

```
┌────────────┐   SSE    ┌──────────────┐
│  React UI  │◀────────▶│  Node API     │
└────┬───────┘          │  (Express)   │
     │REST /events      └────┬─────────┘
     │POST /run               │enqueue
┌────▼──────────┐      ┌─────▼──────────┐
│ Redis (BullMQ)│─────▶│  Worker Pool   │
└────┬──────────┘      └─────┬──────────┘
     │progress/metrics        │reads/writes
┌────▼────────┐        ┌──────▼─────────┐
│ Supabase DB │◀──────▶│ Feature Store  │
└─────────────┘        └───────────────┘
```

* **React Wizard** — 3‑step flow + results panel.
* **Node API** — Express gateway, validates requests, streams progress (Server‑Sent Events).
* **BullMQ Queue** — orchestrates async analysis jobs.
* **Worker Pool** — micro‑services for each data source (YouTube, Reddit, Amazon, TikTok).
  Each emits canonical `Feature` rows into **Feature Store**.
* **Supabase** — Postgres schema + nightly materialised view `hot_niches_today`.

---

## 3. Data Model (Postgres / Supabase)

```sql
-- Core user query
CREATE TABLE niche_queries (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid REFERENCES auth.users,
  title         text,
  category      text,
  subcategory   text[],
  budget_cents  int,
  sources       text[],      -- e.g. ['youtube','reddit']
  created_at    timestamptz DEFAULT now()
);

-- Job instance
CREATE TABLE niche_jobs (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  query_id     uuid REFERENCES niche_queries,
  estimate_cents int,
  estimate_sec  int,
  actual_cents  int,
  actual_sec    int,
  status       text CHECK (status IN ('queued','running','done','error')),
  error_msg    text,
  created_at   timestamptz DEFAULT now(),
  finished_at  timestamptz
);

-- Canonical feature row (one per source item)
CREATE TABLE features (
  id            bigserial PRIMARY KEY,
  niche_id      uuid, -- derived hash of title + category
  source        text, -- 'youtube','reddit', etc.
  item_id       text,
  item_type     text,
  text          text,
  metrics       jsonb, -- raw numbers (views, likes, etc.)
  rpm_estimate  numeric,
  sentiment     numeric,
  fetched_at    timestamptz
);

-- Materialised view for landing pills
CREATE MATERIALIZED VIEW hot_niches_today AS
SELECT  niche_id,
        category,
        subcategory,
        percentile_cont(0.95) WITHIN GROUP (ORDER BY demand_score) AS demand_score,
        avg(monetise_score)  AS monetise_score,
        min(supply_score)    AS supply_score,
        (demand_score * monetise_score) / NULLIF(supply_score,0) AS opportunity_score
FROM     opportunity_scores   -- generated nightly
WHERE    date_trunc('day',calculated_at) = current_date
GROUP BY niche_id, category, subcategory
ORDER BY opportunity_score DESC
LIMIT 50;
```

### Opportunity Score Calculation

```
score = (demand * monetise) / supply
```

* **demand** — normalised 0‑1 from trending volume & engagement velocity.
* **monetise** — normalised RPM percentile.
* **supply** — creator count & content similarity density (lower is better).

The worker writes the three component scores per niche to table `opportunity_scores`; a nightly cron builds the view above.

---

## 4. API Surface

| Method | Path                   | Purpose                               |
| ------ | ---------------------- | ------------------------------------- |
| `GET`  | `/api/niches/today`    | Return top hot niches (view)          |
| `GET`  | `/api/score?query=…`   | Live “niche score” badge while typing |
| `POST` | `/api/run/niche-scout` | Enqueue a job, returns `{jobId}`      |
| `GET`  | `/events/niche/:jobId` | SSE stream: `{progress, stage, log}`  |
| `GET`  | `/api/results/:jobId`  | Final JSON insights                   |

All routes require JWT (Bearer) except the public landing pills.

---

## 5. Cost & Runtime Estimation

* Located in `shared/costRules.ts` so both UI & worker import the same function.
* Input: `{sources, budget_cents}`
* Output: `{maxItems, estCost, estDurationSec}`
* Each source has hard‑coded `costPerItem` and `processingMultiplier` coefficients.

---

## 6. Worker Lifecycle

1. **fetch‑items** per source using supplier SDKs (pagination until `maxItems`).
2. **extract‑features** — sentiment (`vader`), rpm‑estimate, etc.
3. **upsert features → Supabase**.
4. **calculate opportunity** — SQL `WITH demand AS …` query.
5. **emit progress** to Redis channel → SSE.
6. **assemble insights JSON** (clusters, keywords, creators, recommendations).
7. **store results** in `niche_results` table.

---

## 7. Front‑End Components

* **LandingOpportunityPills.tsx** — fetch `GET /api/niches/today` on `useEffect`.
* **NicheScoreBadge.tsx** — debounced call to `/api/score`.
* **BudgetSlider.tsx** — on change, calls `estimate()` from cost rules.
* **ReviewDiffTable.tsx** — lists each source line item + Totals.
* **RunButton.tsx** — POST job → starts EventSource for `/events/niche/:jobId`.
* **ProgressBar.tsx** — listens to SSE.
* **ResultsTabs.tsx** — Overview · Clusters · Keywords · Visualisation (BubbleMap).  Uses Recharts.

---

## 8. Observability

* **Metrics** exported at `/metrics` (Prometheus):

  * `queue_jobs_total` by status.
  * `external_api_cost_cents_total` by source.
  * `opportunity_score_estimation_error` (histogram).
* **Logging** — pino with pretty‑prints in dev, JSON in prod.

---

## 9. Security & Compliance

* **OAuth scopes** — read‑only analytics.
* **Rate limit** — 60 req/min/user on public routes.
* **Secrets** — .env excluded from git; GitHub Actions uses repo secrets.
* **GDPR** — user deletion triggers `DELETE FROM features WHERE user_id = …` cascade.

---

## 10. Testing Strategy

| Layer       | Tool             | Tests                                   |
| ----------- | ---------------- | --------------------------------------- |
| Unit        | Jest             | costRules, opportunityScore, UI helpers |
| Integration | Supertest + nock | `/api/run` happy/ error paths           |
| E2E         | Playwright       | wizard → progress → results rendered    |

Nightly GitHub Action runs unit + integration; E2E on push to main.

---

## 11. Roadmap Snapshot

| Sprint | Milestone                                              |
| ------ | ------------------------------------------------------ |
| 1      | Estimator + budget slider + top niches pills           |
| 2      | BullMQ queue + SSE progress                            |
| 3      | Feature store + real YouTube fetcher                   |
| 4      | Multi‑source & bubble visualisation                    |
| 5      | Feedback loop (estimate vs actual) + OAuth ROI tracker |

---

**End of Specification**
