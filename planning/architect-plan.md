<!-- ARCHITECT PROMPT: You are an AI architect.  
Generate a task breakdown from the planning bullets below.  
Return a markdown table with columns: | Status | ID | File | Description |.  
Use [ ] for unchecked tasks and [x] for completed ones. -->

```markdown
| Status | ID  | File                                | Description                                                                                     |
|--------|-----|-------------------------------------|-------------------------------------------------------------------------------------------------|
| [ ]    | 024 | architect-trigger.yml               | Broaden architect_generate trigger: run on push to main when planning/** changes                |
| [ ]    | 025 | architect-push.yml                  | Switch architect_generate push step to use ARCHITECT_PAT token                                  |
| [ ]    | 026 | architect_watchdog.yml              | Add architect_watchdog workflow: open GitHub Issue if planning has unchecked bullets but no successful architect_generate run in >30 min |
| [ ]    | 027 | engineer_async.yml                  | Add pre-flight ruff + pytest step in engineer_async; abort PR creation on failure               |
| [ ]    | 028 | reviewer_agent.yml                  | Add Reviewer agent workflow: helm lint and repo-wide conventions; auto-push fixes before CI     |
| [ ]    | 029 | planner_agent.yml                   | Create Planner agent workflow: generate PRD markdown for bullets labelled needs-spec; iterate Q&A; merge when label spec-approved is added |
| [ ]    | 030 | engineer_async_guard.yml            | Update engineer_async guard: skip task until matching spec-approved PRD file exists             |
| [ ]    | 031 | CONTRIBUTING.md                     | Update CONTRIBUTING.md to document needs-spec / spec-approved labels and new workflows          |
```