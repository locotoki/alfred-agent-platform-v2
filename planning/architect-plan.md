<!-- ARCHITECT PROMPT: You are an AI architect.  
Generate a task breakdown from the planning bullets below.  
Return a markdown table with columns: | Status | ID | File | Description |.  
Use [ ] for unchecked tasks and [x] for completed ones. -->

| Status | ID  | File                                    | Description                                                                                         |
|--------|-----|-----------------------------------------|-----------------------------------------------------------------------------------------------------|
| [ ]    | 041 | ArchitectWorkbench.tsx                  | Implement `ArchitectWorkbench.tsx` with markdown editor + chat pane                                 |
| [ ]    | 042 | backend/sse-endpoint.ts                 | Add backend SSE endpoint `/architect/complete` that proxies to architect agent container            |
| [ ]    | 043 | validate_prd_worker.js                  | Integrate `validate_prd.py` via WebWorker for live status in UI                                     |
| [ ]    | 044 | MemorySidebar.jsx                       | Build `MemorySidebar` component calling `/memory/search` for similar docs                           |
| [ ]    | 045 | architect_ui_actions.js                 | Add "Finalize PRD" action that commits draft to `docs/prd/` and opens PR via GitHub API             |
| [ ]    | 046 | automation_workflow.md                  | Update `automation_workflow.md` diagram to include Workbench flow                                   |
| [ ]    | 047 | cypress/e2e/workbench_spec.js           | Write Cypress E2E covering PRD creation via Workbench                                               |

## pgvector Migration Completion

| Status | ID  | File                                    | Description                                                                                         |
|--------|-----|-----------------------------------------|-----------------------------------------------------------------------------------------------------|
| [ ]    | 048 | services/memory/search_adapter.py       | Replace search_qdrant() helper with search_pgvector() using <=> cosine operator                     |
| [ ]    | 049 | docker-compose.yml                      | Remove Qdrant service from core profile; keep compose.compat for rollback                           |
| [ ]    | 050 | scripts/migrate_qdrant_to_pgvector.py   | Delete migration script and Qdrant health probe steps from CI                                       |
| [ ]    | 051 | docs/memory-architecture.md             | Update docs: memory architecture, local-dev quick-start                                             |
| [ ]    | 052 | tests/load_test_vector_search.py        | Run load test (10k vector search) to confirm latency ≤ 20ms                                         |
| [ ]    | 053 | .env.example                            | Remove Qdrant secrets/env-vars from repo & runners                                                  |

# Test comment for guard workflow


#### Docs & Cost Visibility
- Refresh README with quick-start, architecture diagram, agent cheat-sheet
- Add onboarding guide (local runner, stream creation, env vars)
- Implement cost-collector GitHub Action for OpenAI + CI usage (daily cron)
- Create FastAPI /costs endpoint and Workbench sparkline panel
- Add KPI alert if 14-day rolling LLM cost exceeds threshold
