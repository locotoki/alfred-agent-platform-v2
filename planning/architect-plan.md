<!-- ARCHITECT PROMPT: You are an AI architect.  
Generate a task breakdown from the planning bullets below.  
Return a markdown table with columns: | Status | ID | File | Description |.  
Use [ ] for unchecked tasks and [x] for completed ones. -->

| Status | ID  | File                                  | Description                                                                                      |
|--------|-----|-------------------------------------|--------------------------------------------------------------------------------------------------|
| [x]    | 001 | PR #710                             | Enable optional E2E & perf-stress jobs                                                           |
| [x]    | 002 | PR #710                             | Make flake-detector a required gate                                                              |
| [x]    | 003 | Issue #695                          | Kick-off Dependabot + weekly Trivy automation                                                    |
| [x]    | 004 | infra/scripts/slack_adapter.sh      | Migrate Slack adapter from ngrok to Cloudflare Tunnel                                            |
| [x]    | 005 | Slack_Manifest_Update.md            | Update Slack manifest for Cloudflare Tunnel migration                                            |
| [x]    | 006 | services/bizdev_service             | Scaffold BizDev agent (create service skeleton, initial DB schema, and README stub)              |
| [x]    | 007 | task-ticker.yml                     | Fix task-ticker trigger by removing branches-ignore: [main]                                      |
| [x]    | 008 | architect_review.yml                | Deploy architect_review.yml auto-merge workflow to main                                          |
| [x]    | 009 | ci-summary.yml                      | Relax ci-summary for docs-only commits (auto-green docs-only PRs)                                |
| [x]    | 010 | docker-compose.yml                  | Integrate Qdrant indexer sidecar into docker-compose and Helm charts (health probe, metrics)     |
| [x]    | 011 | trivy-alert.yml                     | Add nightly security CVE alert for trivy-image failures (Slack notification)                     |
| [x]    | 012 | docs/runbook_1.0.9.md               | Publish GA upgrade runbook & v1.0.9 CHANGELOG                                                    |
| [x]    | 013 | pipeline-health.yml                 | Add pipeline-health badge & Slack alert if any core job red > 1 hr                               |
| [x]    | 014 | ci-cache.yml                        | Cache Go/Node build dependencies in CI using actions/cache                                       |
| [x]    | 015 | branch-protection.yml               | Migrate classic branch protection to a single Ruleset (delete legacy rules)                      |
| [x]    | 016 | architect-sync.py                   | Add duplicate-bullet dedupe logic to architect-sync.py (skip second identical bullet)            |
| [x]    | 017 | task-ticker.yml                     | Retry + create GitHub Issue when task-ticker push fails (skip silent drop)                       |
| [x]    | 018 | task-queue_monitor.yml              | Add Slack alert if task-queue has unchecked items but engineer_async idle > 60 min               |
| [x]    | 019 | watchdog_workflow.yml               | Add watchdog workflow to alert if architect_generate or engineer_async red > 30 min              |
| [x]    | 020 | fastapi_project_setup.md            | Create BizDev service skeleton (FastAPI project `services/bizdev_service`, poetry config, basic health endpoint) |
| [x]    | 021 | bizdev_db_schema.sql                | Add initial database schema for BizDev service (SQLAlchemy models + Alembic migration for `leads` table) |
| [x]    | 022 | bizdev_helm_chart                   | Write Helm chart and Kubernetes manifests for BizDev service (values.yaml, deployment, service)  |
| [x]    | 023 | bizdev_ci.yml                       | Add CI lint + unit-test job for BizDev service (pytest sample test, ruff lint)                   |
| [x]    | 024 | architect-trigger.yml               | Broaden architect_generate trigger: run on push to main when planning/** changes                 |
| [x]    | 025 | cache-cleanup.yml                   | Add weekly CI cache cleanup workflow to delete unused cache entries                              |
| [x]    | 026 | architect-board-extension.js        | Add Architect-Board browser extension (Chrome/Firefox) for PRD editor integration                |
| [x]    | 027 | task-deduper.py                     | Add task deduplication script to prevent duplicate task IDs in architect-plan.md                 |
| [x]    | 028 | ci-stability-monitor.yml            | Add CI stability monitor to track flake rates and auto-disable flaky tests                       |
| [x]    | 029 | docs/contributing.md                | Update CONTRIBUTING.md with new workflow procedures and task-ID requirements                     |
| [x]    | 030 | health-check-aggregator.yml         | Add health check aggregator for all services with centralized dashboard                          |
| [x]    | 031 | release-automation.yml              | Implement automated release workflow with changelog generation and version tagging               |
| [x]    | 032 | docs/templates/prd_template.md      | Add PRD markdown template                                                                        |
| [x]    | 033 | .github/scripts/validate_prd.py     | Implement PRD validator script                                                                   |
| [x]    | 034 | .github/workflows/prd-validate.yml  | Add PRD validation workflow                                                                      |
| [ ]    | 035 | branch-protection.yml               | Integrate PRD validation into branch protection                                                  |
| [ ]    | 036 | architect-board                     | Extend Architect-Board with PRD editor pane to create/approve PRDs                               |
| [ ]    | 037 | reviewer_agent.yml                  | Update Reviewer-agent rule-set to enforce PRD reference and task IDs                             |
| [ ]    | 038 | docs/automation_workflow.md         | Document PRD workflow                                                                            |
| [ ]    | 039 | reviewer_middleware.md              | Implement reviewer middleware to enforce PRD-id & task-id in PR description                      |
| [ ]    | 040 | kpi_monitor.yml                     | Add KPI monitor script to fail if Architect or Task-ticker success < 95%                         |