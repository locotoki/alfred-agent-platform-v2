# Open Pull Requests Summary
*Generated: 25 May 2025*

## Total Open PRs: 20

### Recent PRs (Last 2 Days)

#### Infrastructure & CI
1. **PR #466**: Add healthcheck prefix validation to CI
   - Branch: `ci/release-root-context`
   - Created: 2025-05-25
   - Purpose: Adds CI validation for healthcheck base image prefixes

2. **PR #465**: Align healthcheck base-image prefix
   - Branch: `chore/align-healthcheck-prefix`
   - Created: 2025-05-25
   - Purpose: Standardizes healthcheck base image naming

3. **PR #445**: ci: add --no-cache to release image builds
   - Branch: `ci/cache-busting-release-workflow`
   - Created: 2025-05-25
   - Purpose: Ensures fresh builds in release pipeline

4. **PR #432**: Fix: pubsub-metrics Dockerfile & health-check
   - Branch: `fix/pubsub-metrics-dockerfile`
   - Created: 2025-05-24
   - Purpose: Fixes pubsub-metrics service health checks

### Architecture & Documentation
5. **PR #420**: ADR-013: BizDev service architecture
   - Branch: `feat/adr-013-bizdev-arch`
   - Created: 2025-05-24
   - Purpose: Architecture Decision Record for BizDev service

6. **PR #344**: docs: update integration surface with retrieval metrics and PR status
   - Branch: `docs/update-integration-surface`
   - Created: 2025-05-23
   - Labels: needs-rebase
   - Purpose: Documentation updates for integration surface

### Observability & Monitoring
7. **PR #354**: feat(observability): add error-rate alert for agent-core
   - Branch: `feature/observability-error-alert`
   - Created: 2025-05-23
   - Labels: observability
   - Purpose: Adds error rate alerting for agent-core service

8. **PR #305**: Observability v2 – Advanced Panels (post-GA)
   - Branch: `feature/observability-v2-extras`
   - Created: 2025-05-23
   - Purpose: Advanced monitoring panels for post-GA release

### Testing & Performance
9. **PR #349**: test: add performance test infrastructure and mock harness
   - Branch: `test/perf-harness-infrastructure`
   - Created: 2025-05-23
   - Labels: ci-fail
   - Purpose: Performance testing framework

10. **PR #333**: perf: scaffold tier1 harness with p95 latency gate
    - Branch: `perf/tier1-harness`
    - Created: 2025-05-23
    - Purpose: Performance testing with p95 latency requirements

### UI & Frontend
11. **PR #338**: ui: scaffold chat bubble with collapsible mock citations
    - Branch: `ui/chat-citation-shell`
    - Created: 2025-05-23
    - Labels: phase8, needs-rebase
    - Purpose: UI component for chat with citations

### Developer Experience
12. **PR #321**: feat(dx): add cold-start bench + CI stub
    - Branch: `feature/fast-loop-baseline`
    - Created: 2025-05-23
    - Purpose: Cold start benchmarking for DX improvements

13. **PR #310**: ADR-011: DX Fast-Loop Sprint
    - Branch: `adr/dx-fast-loop`
    - Created: 2025-05-23
    - Purpose: Architecture decision for developer experience improvements

### Maintenance & Cleanup
14. **PR #334**: ci: polish nightly pipeline with size report and retention logic stub
    - Branch: `ci/nightly-polish`
    - Created: 2025-05-23
    - Labels: phase8, needs-rebase
    - Purpose: Nightly CI pipeline improvements

15. **PR #300**: chore: fix isort and line-ending drift (#272)
    - Branch: `chore/isort-line-ending-fix`
    - Created: 2025-05-23
    - Purpose: Code formatting fixes

16. **PR #296**: fix: board-sync PAT scope handling
    - Branch: `infra/board-sync-pat`
    - Created: 2025-05-22
    - Purpose: Fix GitHub PAT scope for board synchronization

17. **PR #286**: chore: clean up licence waivers file format
    - Branch: `chore/remove-psycopg2-binary`
    - Created: 2025-05-22
    - Purpose: License waiver cleanup

18. **PR #258**: SC-250 Slice 6 (part 2): final ORPHAN sweep and 100% completion
    - Branch: `ops/SC-250-finish-part2`
    - Created: 2025-05-22
    - Purpose: Spring cleaning completion

19. **PR #225**: Fix #223 – enum validation cleanup
    - Branch: `fix/223-enum-validation`
    - Created: 2025-05-21
    - Purpose: Enum validation fixes

20. **PR #178**: fix: local-stack boot smoke-test (SC-LS-001)
    - Branch: `ops/sc-ls-001-local-stack-smoke`
    - Created: 2025-05-20
    - Purpose: Local stack smoke testing

## PR Categories & Priority

### High Priority (Health/CI)
- PR #466, #465 - Healthcheck standardization
- PR #445 - Build cache fixes
- PR #432 - pubsub-metrics fixes

### Medium Priority (Features/Observability)
- PR #354 - Error rate alerting
- PR #349 - Performance test infrastructure
- PR #420 - BizDev architecture

### Low Priority (Cleanup/Docs)
- PR #344, #338, #334 - Need rebase
- PR #300, #286, #258 - Cleanup tasks

## Labels Summary
- **needs-rebase**: 3 PRs (#344, #338, #334)
- **phase8**: 2 PRs (#338, #334)
- **observability**: 1 PR (#354)
- **ci-fail**: 1 PR (#349)

## High-Priority Issues Status
- **#441**: GA polish: bench job, validate cleanup, ingest alert - **CLOSED**
- **#372**: Synthetic workload generator for BizDev dashboards - **OPEN**
- **#442**: chore(release): v0.9.11-beta configuration - **MERGED**

## Recommendations
1. **Merge health-related PRs first** (#466, #465, #432) to improve service stability
2. **Rebase stale PRs** that have the needs-rebase label
3. **Address CI failures** in PR #349 (performance test infrastructure)
4. **Focus on issue #372** as it's the only open high-priority issue
