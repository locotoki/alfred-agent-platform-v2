<!-- ARCHITECT PROMPT: You are an AI architect.  
Generate a task breakdown from the planning bullets below.  
Return a markdown table with columns: | Status | ID | File | Description |.  
Use [ ] for unchecked tasks and [x] for completed ones. -->

| Status | ID  | File                       | Description                                               |
|--------|-----|----------------------------|-----------------------------------------------------------|
| [ ]    | 007 | task-ticker.yml            | Fix task-ticker trigger by removing branches-ignore: [main] |
| [ ]    | 008 | architect_review.yml       | Deploy architect_review.yml auto-merge workflow to main   |
| [x]    | 001 | PR #710                    | Enable optional E2E & perf-stress jobs                    |
| [x]    | 002 | PR #710                    | Make flake-detector a required gate                       |
| [x]    | 003 | Issue #695                 | Kick-off Dependabot + weekly Trivy automation             |
| [ ]    | 004 | Migrate_Slack_Adapter.md   | Migrate Slack adapter from ngrok to Cloudflare Tunnel     |
| [x]    | 005 | Slack_Manifest_Update.md   | Update Slack manifest for Cloudflare Tunnel migration     |
| [x]    | 006 | Issue #697                 | Begin BizDev agent scaffold                               |

## Planning bullets
- Relax ci-summary for docs-only commits (auto-green docs-only PRs)
- Migrate Slack adapter from ngrok to Cloudflare Tunnel (update infra/scripts/slack_adapter.sh, Helm chart, and docs)
- Update Slack manifest for Cloudflare Tunnel migration (regenerate slash-command URL and OAuth scopes)
- Scaffold BizDev agent (create service skeleton, initial DB schema, and README stub)
- Integrate Qdrant indexer sidecar into docker-compose and Helm charts (health probe, metrics)
- Add nightly security CVE alert for trivy-image failures (Slack notification)
- Publish GA upgrade runbook & v1.0.9 CHANGELOG (docs/runbook_1.0.9.md)
- Enable flake-detector gate enforcement (merge PR #74, set as required status)
- Add pipeline-health badge & Slack alert if any core job red > 1 hr
- Cache Go/Node build dependencies in CI using actions/cache
- Migrate classic branch protection to a single Ruleset (delete legacy rules)
- Add duplicate-bullet dedupe logic to architect-sync.py (skip second identical bullet)
- Retry + create GitHub Issue when task-ticker push fails (skip silent drop)
- Add Slack alert if task-queue has unchecked items but engineer_async idle > 60 min
- Re-assert automerge label in engineer_async before workflow ends
- Add watchdog workflow to alert if architect_generate or engineer_async red > 30 min

- Create BizDev service skeleton (FastAPI project `services/bizdev_service`, poetry config, basic health endpoint)
- Add initial database schema for BizDev service (SQLAlchemy models + Alembic migration for `leads` table)
- Write Helm chart and Kubernetes manifests for BizDev service (values.yaml, deployment, service)
- Add CI lint + unit-test job for BizDev service (pytest sample test, ruff lint)
