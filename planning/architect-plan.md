<!-- ARCHITECT PROMPT: You are an AI architect.  
Generate a task breakdown from the planning bullets below.  
Return a markdown table with columns: | Status | ID | File | Description |.  
Use [ ] for unchecked tasks and [x] for completed ones. -->

```markdown
| Status | ID  | File                                | Description                                                                                     |
|--------|-----|-------------------------------------|-------------------------------------------------------------------------------------------------|
| [x]    | 009 | ci-summary.yml                      | Relax ci-summary for docs-only commits (auto-green docs-only PRs)                               |
| [x]    | 004 | infra/scripts/slack_adapter.sh      | Migrate Slack adapter from ngrok to Cloudflare Tunnel                                           |
| [x]    | 004 | Helm chart                          | Update Helm chart for Slack adapter migration                                                   |
| [x]    | 004 | Migration_Docs.md                   | Update docs for Slack adapter migration                                                         |
| [x]    | 005 | Slack_Manifest_Update.md            | Update Slack manifest for Cloudflare Tunnel migration                                           |
| [x]    | 006 | services/bizdev_service             | Scaffold BizDev agent (create service skeleton, initial DB schema, and README stub)             |
| [x]    | 010 | docker-compose.yml                  | Integrate Qdrant indexer sidecar into docker-compose and Helm charts (health probe, metrics)    |
| [x]    | 011 | trivy-alert.yml                     | Add nightly security CVE alert for trivy-image failures (Slack notification)                    |
| [x]    | 012 | docs/runbook_1.0.9.md               | Publish GA upgrade runbook & v1.0.9 CHANGELOG                                                   |
| [x]    | 002 | PR #74                              | Enable flake-detector gate enforcement (merge PR #74, set as required status)                   |
| [x]    | 013 | pipeline-health.yml                 | Add pipeline-health badge & Slack alert if any core job red > 1 hr                              |
| [x]    | 014 | ci-cache.yml                        | Cache Go/Node build dependencies in CI using actions/cache                                      |
| [x]    | 015 | branch-protection.yml               | Migrate classic branch protection to a single Ruleset (delete legacy rules)                     |
| [x]    | 016 | architect-sync.py                   | Add duplicate-bullet dedupe logic to architect-sync.py (skip second identical bullet)           |
| [x]    | 017 | task-ticker.yml                     | Retry + create GitHub Issue when task-ticker push fails (skip silent drop)                      |
| [x]    | 018 | task-queue_monitor.yml              | Add Slack alert if task-queue has unchecked items but engineer_async idle > 60 min              |
| [x]    | 019 | watchdog_workflow.yml               | Add watchdog workflow to alert if architect_generate or engineer_async red > 30 min             |
| [x]    | 020 | fastapi_project_setup.md            | Create BizDev service skeleton (FastAPI project `services/bizdev_service`, poetry config, basic health endpoint) |
| [x]    | 021 | bizdev_db_schema.sql                | Add initial database schema for BizDev service (SQLAlchemy models + Alembic migration for `leads` table) |
| [x]    | 022 | bizdev_helm_chart                   | Write Helm chart and Kubernetes manifests for BizDev service (values.yaml, deployment, service) |
| [x]    | 023 | bizdev_ci.yml                       | Add CI lint + unit-test job for BizDev service (pytest sample test, ruff lint)                  |
```
# Architect reliability
- Broaden architect_generate trigger: run on push to main when planning/** changes
- Switch architect_generate push step to use ARCHITECT_PAT token

- Add architect_watchdog workflow: open GitHub Issue if planning has unchecked bullets but no successful architect_generate run in >30 min

# Engineer reliability
- Add pre-flight ruff + pytest step in engineer_async; abort PR creation on failure

# Reviewer & linting
- Add Reviewer agent workflow: helm lint and repo-wide conventions; auto-push fixes before CI

# Planner / PRD flow
- Create Planner agent workflow: generate PRD markdown for bullets labelled needs-spec; iterate Q&A; merge when label spec-approved is added
- Update engineer_async guard: skip task until matching spec-approved PRD file exists

# Docs
- Update CONTRIBUTING.md to document needs-spec / spec-approved labels and new workflows

