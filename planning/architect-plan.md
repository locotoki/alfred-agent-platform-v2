<!-- ARCHITECT PROMPT: You are an AI architect.  
Generate a task breakdown from the planning bullets below.  
Return a markdown table with columns: | Status | ID | File | Description |.  
Use [ ] for unchecked tasks and [x] for completed ones. -->

#### Milestone Progress
- [ ] Stabilise CI runner (Phase 1) – all jobs pass without allow-failure
- [ ] PRD foundation merged & branch protection enforced (Phase 2)
- [ ] Planner agent MVP live and generating tasks (Phase 3)
- [ ] Reviewer agent MVP gating PRs (Phase 4)
- [ ] KPI monitor & Watchdog deployed (Phase 5)
- [ ] Architect-Board UI polished and E2E green (Phase 6)
- [ ] Guard-rail hooks 024-029 active (Phase 7)
- [ ] Docs & diagram refresh complete (Phase 8)

| Status | ID  | File                              | Description                                                                                               |
|--------|-----|-----------------------------------|-----------------------------------------------------------------------------------------------------------|
| [ ]    | 032 | docs/templates/prd_template.md    | Add PRD markdown template                                                                                 |
| [ ]    | 033 | .github/scripts/validate_prd.py   | Implement PRD validator script                                                                            |
| [ ]    | 034 | ci-summary.yml                    | Add PRD validation to CI summary fast-pass                                                                |
| [ ]    | 035 | branch-protection.yml             | Integrate PRD validation into branch protection                                                           |
| [ ]    | 036 | architect-board                   | Extend Architect-Board with PRD editor pane to create/approve PRDs                                        |
| [ ]    | 037 | reviewer_agent.yml                | Update Reviewer-agent rule-set to enforce PRD reference and task IDs                                      |
| [ ]    | 038 | docs/automation_workflow.md       | Document PRD workflow                                                                                     |
| [ ]    | 039 | reviewer_middleware.md            | Implement reviewer middleware to enforce PRD-id & task-id in PR description                               |
| [ ]    | 040 | kpi_monitor.yml                   | Add KPI monitor script to fail if Architect or Task-ticker success < 95%                                  |

#### CI / Branch Protection
- Remove temporary allow-failure workflow once CI passes consistently