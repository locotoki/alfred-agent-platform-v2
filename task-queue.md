# Task Queue - Alfred Agent Platform v2

## Milestone Progress Checklist

- [x] **Phase 1**: CI Stabilization (Tasks 001-031)
- [x] **Phase 2**: PRD Infrastructure (Tasks 032-034)  
- [x] **Phase 3**: Planning & Enforcement Setup (Task 035)
- [ ] **Phase 3**: Planner PRD + scaffold implementation (Tasks 036-040)

## Phase History

### Phase 1: CI Stabilization (COMPLETED)
**Status**: ✅ Completed  
**Branch**: `feature/ci-stabilisation-20250619151652`  
**PR**: Merged to main  

**Tasks Completed**:
- [x] 001: Enable optional E2E & perf-stress jobs (PR #710)
- [x] 002: Make flake-detector a required gate (PR #710)
- [x] 003: Kick-off Dependabot + weekly Trivy automation (Issue #695)
- [x] 004: Migrate Slack adapter from ngrok to Cloudflare Tunnel
- [x] 005: Update Slack manifest for Cloudflare Tunnel migration
- [x] 006: Scaffold BizDev agent (create service skeleton, initial DB schema, and README stub)
- [x] 007: Fix task-ticker trigger by removing branches-ignore: [main]
- [x] 008: Deploy architect_review.yml auto-merge workflow to main
- [x] 009: Relax ci-summary for docs-only commits (auto-green docs-only PRs)
- [x] 010: Integrate Qdrant indexer sidecar into docker-compose and Helm charts
- [x] 011: Add nightly security CVE alert for trivy-image failures (Slack notification)
- [x] 012: Publish GA upgrade runbook & v1.0.9 CHANGELOG
- [x] 013: Add pipeline-health badge & Slack alert if any core job red > 1 hr
- [x] 014: Cache Go/Node build dependencies in CI using actions/cache
- [x] 015: Migrate classic branch protection to a single Ruleset (delete legacy rules)
- [x] 016: Add duplicate-bullet dedupe logic to architect-sync.py
- [x] 017: Retry + create GitHub Issue when task-ticker push fails
- [x] 018: Add Slack alert if task-queue has unchecked items but engineer_async idle > 60 min
- [x] 019: Add watchdog workflow to alert if architect_generate or engineer_async red > 30 min
- [x] 020: Create BizDev service skeleton (FastAPI project, poetry config, basic health endpoint)
- [x] 021: Add initial database schema for BizDev service (SQLAlchemy models + Alembic migration)
- [x] 022: Write Helm chart and Kubernetes manifests for BizDev service
- [x] 023: Add CI lint + unit-test job for BizDev service (pytest sample test, ruff lint)
- [x] 024: Broaden architect_generate trigger: run on push to main when planning/** changes
- [x] 025: Add weekly CI cache cleanup workflow to delete unused cache entries
- [x] 026: Add Architect-Board browser extension (Chrome/Firefox) for PRD editor integration
- [x] 027: Add task deduplication script to prevent duplicate task IDs in architect-plan.md
- [x] 028: Add CI stability monitor to track flake rates and auto-disable flaky tests
- [x] 029: Update CONTRIBUTING.md with new workflow procedures and task-ID requirements
- [x] 030: Add health check aggregator for all services with centralized dashboard
- [x] 031: Implement automated release workflow with changelog generation and version tagging

### Phase 2: PRD Infrastructure (COMPLETED)
**Status**: ✅ Completed  
**Branch**: `feature/prd-validator-20250619210107`  
**PR**: #818 - Ready for review  

**Tasks Completed**:
- [x] 032: Add PRD markdown template (`docs/templates/prd_template.md`)
- [x] 033: Implement PRD validator script (`.github/scripts/validate_prd.py`)
- [x] 034: Add PRD validation workflow (`.github/workflows/prd-validate.yml`)
- [x] PRD validation CI integration and testing

## Current Active Tasks

### Phase 3: Planning & Enforcement (IN PROGRESS)
**Status**: 🔄 In Progress  
**Priority**: High  
**Focus**: Planner PRD + scaffold implementation

**Tasks Completed**:
- [x] 035: Integrate PRD validation into branch protection rules (`.github/settings.yml`)

**Pending Tasks**:
- [ ] 036: Extend Architect-Board with PRD editor pane
- [ ] 037: Update Reviewer-agent rule-set to enforce PRD reference and task IDs
- [ ] 038: Document PRD workflow (`docs/automation_workflow.md`)
- [ ] 039: Implement reviewer middleware to enforce PRD-id & task-id in PR description  
- [ ] 040: Add KPI monitor script to fail if Architect or Task-ticker success < 95%

## Task Status Legend
- ✅ **Completed**: Task fully implemented and merged
- 🔄 **In Progress**: Currently being worked on
- ⏳ **Pending**: Queued for future work
- ❌ **Blocked**: Waiting on dependencies or decisions
- 🚫 **Cancelled**: No longer needed

## Notes
- Tasks 001-031 were previously lost due to architect sync bug but have been restored
- PRD infrastructure is complete and validated
- Next phase focuses on enforcement and automation workflows