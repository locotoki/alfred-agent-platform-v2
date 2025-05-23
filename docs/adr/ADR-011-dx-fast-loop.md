# ADR-011: DX Fast-Loop Sprint

Date: 2025-05-26
Status: Draft
Authors: @alfred-architect-o3, Maintainers

## Context

The current developer experience (DX) suffers from significant friction points that impact productivity:

- **Slow cold-start times**: Initial environment setup takes 15-30 minutes
- **Repeated container rebuilds**: Each dependency change triggers full rebuild
- **Long feedback loops**: Test suite takes 8-12 minutes for full run
- **Resource-intensive dev containers**: 8GB+ RAM required for local development

Developer survey feedback (May 2025):
- 73% report "waiting for builds" as top productivity killer
- Average time to first commit for new contributors: 2.3 hours
- CI feedback loop averaging 12 minutes (should be <5 min for fast iteration)

### Current Pain Points

1. **Docker Build Times** (from GitHub Actions metrics):
   - Average build time: 4m 32s
   - P95 build time: 7m 18s
   - Cache miss rate: 42%

2. **Test Execution**:
   - Unit tests: 2m 15s
   - Integration tests: 5m 40s
   - E2E tests: 4m 20s
   - Total: ~12m 15s

3. **Local Development**:
   - Full stack startup: 3-5 minutes
   - Service restart after code change: 30-60s
   - Database migrations on every restart

## Decision

Implement a "DX Fast-Loop" sprint to optimize the developer feedback cycle through:

### 1. Pre-built Development Images
- Publish weekly base images with all dependencies pre-installed
- Layer application code on top (copy-on-write)
- Registry: ghcr.io/locotoki/alfred-dev-base:weekly-{date}

### 2. `alfred up` CLI Wrapper
- Smart service orchestration (only start what's needed)
- Automatic port allocation to avoid conflicts
- Health check aggregation and status dashboard
- Usage: `alfred up --services api,slack --watch`

### 3. Tiered Test Execution
- **Tier 0 (smoke)**: <30s - critical path only
- **Tier 1 (fast)**: <2m - unit + fast integration
- **Tier 2 (full)**: <10m - all tests including E2E
- Parallel execution by default
- Smart test selection based on changed files

### 4. Development Mode Optimizations
- Hot-reload for Python services (werkzeug/uvicorn)
- Incremental TypeScript compilation
- Shared volume mounts for faster file sync
- In-memory test databases

## Consequences

### Positive
- Reduced time-to-first-commit: target <30 minutes
- Faster iteration cycles: <2 minute feedback for most changes
- Lower resource requirements: 4GB RAM minimum
- Improved developer satisfaction and retention

### Negative
- Additional complexity in build pipeline
- Storage costs for pre-built images (~$50/month estimated)
- Need to maintain compatibility between dev and prod environments
- Security scanning cadence for base images

### Neutral
- Requires developer education on new tooling
- Migration period where both old and new approaches coexist

## Implementation Checklist

- [ ] Design pre-built image layering strategy
- [ ] Set up ghcr.io registry with retention policies
- [ ] Implement `alfred` CLI in Go for fast startup
- [ ] Create test tier annotations and runner
- [ ] Update developer documentation
- [ ] Run pilot with 5 developers for 2 weeks
- [ ] Gather metrics and iterate

## Open Questions

1. **Image Registry**: Use GitHub Packages (ghcr.io) or self-host?
2. **Security Scanning**: How often to rebuild base images? Daily vs weekly?
3. **Storage Costs**: Set hard limit at $100/month? Implement cleanup policies?
4. **Compatibility Testing**: How to ensure dev/prod parity?

## Review Process

1. Post PR for initial feedback (by May 30)
2. Present to #dx-council for approval
3. Run 2-week pilot program
4. Full rollout target: June 15, 2025

## References

- [Docker BuildKit Optimization Guide](https://docs.docker.com/build/buildkit/)
- [GitHub Actions Cache Best Practices](https://docs.github.com/en/actions/using-workflows/caching-dependencies)
- Internal Developer Survey Results (May 2025)
- Similar approach: [Spotify's Backstage](https://backstage.io/docs/local-dev/)
