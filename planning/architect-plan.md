<!-- ARCHITECT PROMPT: You are an AI architect.  
Generate a task breakdown from the planning bullets below.  
Return a markdown table with columns: | Status | ID | File | Description |.  
Use [ ] for unchecked tasks and [x] for completed ones. -->

| Status | ID  | File                              | Description                                                                                               |
|--------|-----|-----------------------------------|-----------------------------------------------------------------------------------------------------------|
| [ ]    | 032 | docs/templates/prd_template.md    | Add PRD markdown template                                                                                 |
| [ ]    | 033 | .github/scripts/validate_prd.py   | Implement PRD validator script                                                                            |
| [ ]    | 034 | ci-summary.yml                    | Add PRD validation to CI summary fast-pass                                                                |
| [ ]    | 035 | branch-protection.yml             | Integrate PRD validation into branch protection                                                           |
| [ ]    | 036 | architect-board                   | Extend Architect-Board with PRD editor pane to create/approve PRDs                                        |
| [ ]    | 037 | reviewer_agent.yml                | Update Reviewer-agent rule-set to enforce PRD reference and task IDs                                      |
| [ ]    | 038 | docs/automation_workflow.md       | Document PRD workflow                                                                                     |

#### Reviewer Agent
- Implement reviewer middleware to enforce prd-id & task-id in PR description

#### CI / Branch Protection
- Add kpi_monitor.yml to fail if Architect or Task-ticker success < 95 %
- Investigate missing services/agent-core path in CI build context
- Install docker compose CLI in CI runner images
- Validate docker-compose.yml with `docker compose config` step in CI
- Add integration test ensuring `docker compose up -d` succeeds
- Harden CI image caching and retry strategy to reduce flake
