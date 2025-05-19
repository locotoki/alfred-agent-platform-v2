# Niche‑Scout Incremental Implementation Guide

*This guide translates the Technical Spec into step‑by‑step engineering tasks. Each milestone is self‑contained and can be executed by Claude Code or a human developer. The order is strict—do not parallelise milestones unless explicitly noted.*

---

## Legend

| Mark  | Meaning                       |
| ----- | ----------------------------- |
| `🛠️` | CLI command to paste directly |
| `📦`  | Code file to create or edit   |
| `✅`   | Acceptance criterion          |

---

## Milestone 0 – Repository Hygiene (1 day)

1. **Clone and bootstrap repo**

   `🛠️ git clone git@github.com:org/niche‑scout.git && cd niche‑scout && yarn`

2. **Tooling**

   `🛠️ yarn add -D prettier eslint eslint-config-prettier`

   Add `.editorconfig` and run `🛠️ yarn lint --fix`.

3. **Shared TSConfig**

   Create `tsconfig.base.json`. Extend in `packages/server/tsconfig.json` and `packages/client/tsconfig.json`.

4. **Green tests**

   `🛠️ yarn test`

   `✅ Jest shows 0 failing tests`.

---

## Milestone 1 – Shared Types & Cost Rules (0.5 day)

### 1.1 Shared interfaces

`📦 /shared/types.ts`

```ts
export interface NicheQuery {
  query: string;
  category: string;
  subCategories: string[];
  timeRangeDays: number;
  demographics: string[];
  sources: SourceTag[];
  budgetCents: number;
}

export interface CostEstimate {
  maxItems: number;
  estCostCents: number;
  estDurationSec: number;
}

export interface JobProgressEvent {
  jobId: string;
  percent: number;
  stage: string;
  message?: string;
}

export type SourceTag = 'YOUTUBE' | 'REDDIT' | 'AMAZON';
```

### 1.2 Cost rules

`📦 /shared/costRules.ts`

```ts
import { SourceTag, NicheQuery, CostEstimate } from './types';

const SOURCE_UNIT_COST: Record<SourceTag, number> = {
  YOUTUBE: 0.0012, // $ per video analysed
  REDDIT: 0.0002,
  AMAZON: 0.003,
};

export function estimateCost(q: NicheQuery): CostEstimate {
  const items = Math.min(
    Math.floor(q.budgetCents / Math.max(...Object.values(SOURCE_UNIT_COST)) / 100),
    2000
  );

  const estCost =
    items *
    (q.sources
      .map((s) => SOURCE_UNIT_COST[s])
      .reduce((a, b) => a + b, 0) /
      q.sources.length);

  return {
    maxItems: items,
    estCostCents: Math.ceil(estCost * 100),
    estDurationSec: Math.round((items * q.sources.length) / 40),
  };
}
```

### 1.3 Unit tests

`📦 /packages/server/__tests__/costRules.test.ts`

```ts
import { estimateCost } from '../../../shared/costRules';
import { mockQuery } from '../fixtures/mockQuery';

describe('estimateCost', () => {
  it('never exceeds budget', () => {
    expect(estimateCost(mockQuery).estCostCents).toBeLessThanOrEqual(mockQuery.budgetCents);
  });
});
```

`✅ Tests pass`.

Commit `🛠️ git commit -am "Milestone 1 – shared types & cost rules"`.

---

## Milestone 2 – Job Queue & SSE Progress (2 days)

1. **Add BullMQ & Redis**

   `🛠️ yarn add bullmq ioredis`

   Start local Redis: `🛠️ docker run -d --name redis -p 6379:6379 redis:7-alpine`

2. **Queue setup**

`📦 /packages/server/queue.ts`

```ts
import { Queue } from 'bullmq';
export const nicheQueue = new Queue('nicheScout', { connection: { host: 'localhost', port: 6379 } });
```

3. **API**

`📦 /packages/server/routes/run.ts`

```ts
import express from 'express';
import { nicheQueue } from '../queue';

const router = express.Router();

router.post('/run/niche-scout', async (req, res) => {
  const job = await nicheQueue.add('nicheScout', req.body as NicheQuery);
  res.json({ jobId: job.id });
});

export default router;
```

4. **Worker**

`📦 /packages/worker/index.ts`

```ts
import { Worker } from 'bullmq';
import { computeNicheInsights } from './pipeline';

new Worker('nicheScout', async (job) => computeNicheInsights(job.data));
```

5. **Server‑Sent Events**

   Add `/events/niche/:jobId` endpoint that subscribes to Redis pub/sub `niche:events:<jobId>` and streams `JobProgressEvent` JSON.

6. **Client progress hook**

   In React, add `useEventSource(jobId)` and update progress bar component.

`✅  Progress bar moves within 800 ms for 95 % of jobs.`

---

## Milestone 3 – Feature Store & Opportunity Score (3 days)

1. **Supabase schema**

```sql
CREATE TABLE features (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  niche_key text,
  source text,
  metrics jsonb,
  fetched_at timestamptz DEFAULT now()
);
```

2. **Daily job**

   Cloud scheduler invokes `pnpm ts-node scripts/calcOpportunity.ts` which computes `demand`, `rpm`, `supply`, writes to `opportunity_today` materialised view.

3. **Score function**

`📦 /packages/worker/scoring.ts`

```ts
export function opportunityScore(demand: number, rpm: number, supply: number) {
  return Math.round((demand * rpm) / Math.max(supply, 1));
}
```

4. **Landing pills API**

`GET /api/niches/today` returns top rows from `opportunity_today`.

`✅ Landing page shows 6 hot niches; tooltip shows demand/rpm/supply figures.`

---

## Milestone 4 – Wizard Estimate & Diff Table (1 day)

1. Wire `estimateCost()` into React step 2 parameter tuning.
2. Review tab renders diff‑style table:

```
200 videos   ·  $0.24
800 posts    ·  $0.16
Sentiment    ·  $0.50
Total        ·  $0.90   ETA 2 m15 s
```

`✅ Moving the budget slider updates the table within 200 ms.`

---

## Milestone 5 – Visualisation & Keyword/Cluster Tabs (2 days)

1. **Bubble chart** – Use Recharts in `ResultsVisual.tsx`; props `{ data: ClusterInsights[] }`.
2. **Tabs** –

   * **Clusters** table
   * **Keywords** table
   * **Creators** ranked list
   * **Content gaps** list

`✅ Interactive bubbles respond to filter chips.`

---

## Milestone 6 – Accuracy Feedback Loop & Draft Runs (1.5 days)

1. **Estimates table** – Supabase table `run_estimates` with `budget, estCost, actualCost, estDuration, actualDuration`.
2. **Delta badge** – In results header: `"Estimate was $0.90 → actual $0.86 (+4 %)"`.
3. **Save draft** – Button writes JSON payload to `drafts` table with TTL 7 days.
4. **Cron purge** – Supabase function deletes expired drafts nightly.

`✅ Δ% ≤ 10 % for 90 % of jobs.`

---

## Milestone 7 – Post‑launch Hardening (ongoing)

* Add JWT auth & Stripe billing hooks.
* Integrate Prometheus `/metrics`.
* Run Lighthouse accessibility audit to ≥ 90.

---

**Done!**

Merge `main` → deploy via CI/CD pipeline (GitHub Actions + Render.com). 🎉
