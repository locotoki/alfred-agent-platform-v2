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
| [ ]    | 047 | cypress/e2e/workbench_spec.js           | Write Cypress E2E covering PRD creation via Workbench                                               |# Test comment for guard workflow
