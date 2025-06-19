<!-- ARCHITECT PROMPT: You are an AI architect.  
Generate a task breakdown from the planning bullets below.  
Return a markdown table with columns: | Status | ID | File | Description |.  
Use [ ] for unchecked tasks and [x] for completed ones. -->

```markdown
| Status | ID  | File                                | Description                                                                                     |
|--------|-----|-------------------------------------|-------------------------------------------------------------------------------------------------|
| [ ]    | 009 | ci-summary.yml                      | Relax ci-summary for docs-only commits (auto-green docs-only PRs)                               |
| [x]    | 004 | infra/scripts/slack_adapter.sh      | Migrate Slack adapter from ngrok to Cloudflare Tunnel                                           |
| [x]    | 004 | Helm chart                          | Update Helm chart for Slack adapter migration                                                   |
| [x]    | 004 | Migration_Docs.md                   | Update docs for Slack adapter migration                                                         |
| [x]    | 005 | Slack_Manifest_Update.md            | Update Slack manifest for Cloudflare Tunnel migration                                           |
| [x]    | 006 | services/bizdev_service             | Scaffold BizDev agent (create service skeleton, initial DB schema, and README stub)             |
| [ ]    | 010 | docker-compose.yml                  | Integrate Qdrant indexer sidecar into docker-compose and Helm charts (health probe, metrics)    |
| [ ]    | 011 | trivy-alert.yml                     | Add nightly security CVE alert for trivy-image failures (Slack notification)                    |
| [ ]    | 012 | docs/runbook_1.0.9.md               | Publish GA upgrade runbook & v1.0.9 CHANGELOG                                                   |
| [x]    | 002 | PR #74                              | Enable flake-detector gate enforcement (merge PR #74, set as required status)                   |
| [ ]    | 013 | pipeline-health.yml                 | Add pipeline-health badge & Slack alert if any core job red > 1 hr                              |
| [ ]    | 014 | ci-cache.yml                        | Cache Go/Node build dependencies in CI using actions/cache                                      |
| [ ]    | 015 | branch-protection.yml               | Migrate classic branch protection to a single Ruleset (delete legacy rules)                     |
| [ ]    | 016 | architect-sync.py                   | Add duplicate-bullet dedupe logic to architect-sync.py (skip second identical bullet)           |
| [ ]    | 017 | task-ticker.yml                     | Retry + create GitHub Issue when task-ticker push fails (skip silent drop)                      |
| [ ]    | 018 | task-queue_monitor.yml              | Add Slack alert if task-queue has unchecked items but engineer_async idle > 60 min              |
| [ ]    | 019 | watchdog_workflow.yml               | Add watchdog workflow to alert if architect_generate or engineer_async red > 30 min             |
| [ ]    | 020 | fastapi_project_setup.md            | Create BizDev service skeleton (FastAPI project `services/bizdev_service`, poetry config, basic health endpoint) |
| [ ]    | 021 | bizdev_db_schema.sql                | Add initial database schema for BizDev service (SQLAlchemy models + Alembic migration for `leads` table) |
| [ ]    | 022 | bizdev_helm_chart                   | Write Helm chart and Kubernetes manifests for BizDev service (values.yaml, deployment, service) |
| [ ]    | 023 | bizdev_ci.yml                       | Add CI lint + unit-test job for BizDev service (pytest sample test, ruff lint)                  |
```