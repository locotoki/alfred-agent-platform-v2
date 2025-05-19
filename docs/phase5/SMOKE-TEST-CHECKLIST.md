# Phase 5 Implementation Smoke Test

This document outlines the smoke testing process for the Phase 5 health check implementation workflows.

## Workflow Dry-Run Checklist

### 1. Database Health Checks Workflow

- [ ] Trigger workflow on branch with example files
- [ ] Verify Go build cache works correctly
- [ ] Verify Docker layer cache works correctly
- [ ] Check race detector runs properly on example driver code
- [ ] Verify health check waiting logic functions correctly
- [ ] Confirm status report artifact is generated

### 2. Monitoring Health Checks Workflow

- [ ] Trigger workflow on branch with example files
- [ ] Verify parallel matrix jobs continue even if one fails
- [ ] Verify alert rules are created and uploaded as artifacts
- [ ] Confirm health check waiting logic works on container tests
- [ ] Verify metrics endpoint validation succeeds

### 3. Phase 5 Summary Workflow

- [ ] Verify permissions are correctly set for issue comments
- [ ] Test workflow with manual dispatch
- [ ] Verify tracking issue template is ready (issue #123)
- [ ] Confirm GitHub Script can post to tracking issue
- [ ] Verify weekly status report is correctly formatted
- [ ] Confirm tagging and history file creation works

## Ready for Implementation Checklist

- [ ] Example files are in place:
  - [ ] internal/db/driver.go.example
  - [ ] internal/db/postgres.go.example
  - [ ] monitoring/prometheus/alerts/service_health.yml.example
  - [ ] README-PHASE5-WORKFLOWS.md

- [ ] Documentation is cross-referenced:
  - [ ] DB_PROBE_DESIGN.md references example files
  - [ ] IMPLEMENTATION-PLAN.md references example files
  - [ ] Tracking issue template is prepared

- [ ] CI/CD workflows are configured:
  - [ ] Workflow files have correct permissions
  - [ ] Tracking issue number is hardcoded or properly detected
  - [ ] Caching is correctly configured
  - [ ] Health check waiting logic is robust

## Implementation Start Checklist

- [ ] Create tracking issue from template
- [ ] Update hardcoded issue number in phase5-summary.yml
- [ ] Rename example files to their actual implementation names
- [ ] Create first implementation PR for PostgreSQL driver
- [ ] Monitor workflow runs to ensure they're working as expected

## Notes

- This checklist should be completed before beginning the actual Phase 5 implementation
- The dry-run should use the example files to validate the workflow logic
- Once smoke tests pass, the real implementation can begin
