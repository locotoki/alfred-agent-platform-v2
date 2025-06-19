# Complete Task History (001-031)

This file contains the complete task history for tasks 001-031 that were lost due to a sync bug and restored in commit d564a523.

| Status | ID  | File                                | Description                                                                                     |
|--------|-----|-------------------------------------|-------------------------------------------------------------------------------------------------|
| [x]    | 001 | PR #710                             | Enable optional E2E & perf-stress jobs                                                          |
| [x]    | 002 | PR #710                             | Make flake-detector a required gate                                                             |
| [x]    | 003 | Issue #695                          | Kick-off Dependabot + weekly Trivy automation                                                   |
| [x]    | 004 | infra/scripts/slack_adapter.sh      | Migrate Slack adapter from ngrok to Cloudflare Tunnel                                           |
| [x]    | 005 | Slack_Manifest_Update.md            | Update Slack manifest for Cloudflare Tunnel migration                                           |
| [x]    | 006 | services/bizdev_service             | Scaffold BizDev agent (create service skeleton, initial DB schema, and README stub)             |
| [x]    | 007 | task-ticker.yml                     | Fix task-ticker trigger by removing branches-ignore: [main]                                     |
| [x]    | 008 | architect_review.yml                | Deploy architect_review.yml auto-merge workflow to main                                         |
| [x]    | 009 | ci-summary.yml                      | Relax ci-summary for docs-only commits (auto-green docs-only PRs)                               |
| [x]    | 010 | docker-compose.yml                  | Integrate Qdrant indexer sidecar into docker-compose and Helm charts (health probe, metrics)    |
| [x]    | 011 | trivy-alert.yml                     | Add nightly security CVE alert for trivy-image failures (Slack notification)                    |
| [x]    | 012 | docs/runbook_1.0.9.md               | Publish GA upgrade runbook & v1.0.9 CHANGELOG                                                   |
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
| [x]    | 024 | architect-trigger.yml               | Broaden architect_generate trigger: run on push to main when planning/** changes                |
| [x]    | 025 | architect-push.yml                  | Switch architect_generate push step to use ARCHITECT_PAT token                                  |
| [x]    | 026 | architect_watchdog.yml              | Add architect_watchdog workflow: open GitHub Issue if planning has unchecked bullets but no successful architect_generate run in >30 min |
| [x]    | 027 | engineer_async.yml                  | Add pre-flight ruff + pytest step in engineer_async; abort PR creation on failure               |
| [x]    | 028 | reviewer_agent.yml                  | Add Reviewer agent workflow: helm lint and repo-wide conventions; auto-push fixes before CI     |
| [x]    | 029 | planner_agent.yml                   | Create Planner agent workflow: generate PRD markdown for bullets labelled needs-spec; iterate Q&A; merge when label spec-approved is added |
| [x]    | 030 | engineer_async_guard.yml            | Update engineer_async guard: skip task until matching spec-approved PRD file exists             |
| [x]    | 031 | CONTRIBUTING.md                     | Update CONTRIBUTING.md to document needs-spec / spec-approved labels and new workflows          |