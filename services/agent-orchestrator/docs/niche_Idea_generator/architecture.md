# Architecture

```mermaid
graph TD
  UI["Next.js UI (Lovable preview)"]
  API[/API Routes/]
  Cron{{Hot‑Niches Cron}}
  DB[(Supabase)]
  UI --> API
  API --> DB
  Cron --> DB
```

## Components
* **Next.js** – App Router, shadcn/ui
* **Supabase** – Postgres + RLS + Edge Functions
* **Cron** – Node job scoring opportunity data
* **CI** – GitHub Actions: lint → test → preview

## Data flow
1. Cron scores categories → `taxonomy_dynamic`
2. Wizard fetches **GET /api/taxonomy/hot**
3. User runs workflow → payload stored in `runs`
