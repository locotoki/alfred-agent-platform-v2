# Phase 1 Hardening Plan

This document outlines the steps needed to verify Phase 1 completion and harden the implementation before wider rollout.

## Completion Verification Checklist

| Status | Capability | Evidence (where to look) | Gap/Action Item |
| --- | --- | --- | --- |
| ❌ | **Proxy micro-service live** | `proxy/src/index.ts` running via Docker container `niche-proxy:latest` | Need to rename `.js` to `.ts` and verify container name |
| ✅ | **Similarity & transform functions extracted** | Functions extracted to proxy service (`/proxy-service/src/transformers/`) | Need to move to shared package structure (`packages/shared/`) |
| ❌ | **Redis cache (TTL ≥ 3600 s)** | Redis cache implemented with 3600s TTL | Need to add logs and metrics tracking |
| ✅ | **Prometheus metrics exposed** | Metrics exported in proxy-service | Need to verify path at `/metrics` |
| ❌ | **Mission Control routes via proxy (feature flag)** | Feature flag implemented in `server.js` | Need to add UI "Powered by proxy" badge |
| ❌ | **Unit + integration tests green** | Tests created but need execution and CI setup | Set up CI pipeline or run tests locally to verify |
| ✅ | **Container orchestration ready** | Docker compose configured for all services | Need to validate compose works end-to-end |

## Hardening Tasks

### 🔒 High Priority

#### Add Auth Header to Proxy → SI API
- **Current Status**: Missing Authentication
- **Location**: `/proxy-service/src/services/socialIntel.js`
- **Action Items**:
  - Add `SI_API_KEY` to `.env.example` and Docker Compose
  - Modify `createApiClient` function to include auth header
  - Add tests for API key handling

#### Graceful Cache Fallback
- **Current Status**: Basic implementation exists but needs improvement
- **Location**: `/proxy-service/src/services/redis.js`
- **Action Items**:
  - Enhance Redis error handling
  - Implement in-memory Map fallback with expiration
  - Add tests for failover behavior

#### Alerting Rules
- **Current Status**: Not implemented
- **Action Items**:
  - Add Alertmanager to Docker Compose
  - Create alerting rules for:
    - `proxy_error_rate > 0.05`
    - `proxy_p95_latency > 0.8`
  - Configure email/notification routing

### 📏 Medium Priority

#### End-to-End Load Test
- **Current Status**: Not implemented
- **Action Items**:
  - Create k6 load test script
  - Set up performance testing workflow
  - Configure assertions for p99 latency
  - Document performance benchmarks

#### Canary Rollout Ramp
- **Current Status**: Feature flag exists but no graduated rollout
- **Action Items**:
  - Document rollout stages (10% → 30% → 100%)
  - Automate rollout or create manual process
  - Establish monitoring checkpoints

### 🗑️ Low Priority

#### Cache-Bust Endpoint
- **Current Status**: Not implemented
- **Action Items**:
  - Add DELETE endpoint with token auth
  - Add documentation for endpoint usage
  - Implement cache invalidation logic

## Personal Ops Workflow

### Daily Monitoring Checklist
- Check Grafana dashboard
- Look for error rate spikes
- Verify cache hit ratio

### Weekly Health Check
- Run unit tests
- Execute load tests
- Archive performance history

### Deployment Procedure
1. Run tests
2. Build and push Docker images
3. Tag release
4. Verify deployment

### Incident Response Plan
1. Check container health
2. Review logs
3. Restart services if needed
4. Roll back if necessary

## Go/No-Go Decision Criteria

### Success Criteria
- p95 latency ≤ 400 ms during 15-minute canary at 30% share
- Error rate ≤ 2% (all causes) in the same window
- Alertmanager quiet for ≥ 30 min

### Rollback Procedure
- Set `PROXY_ROLLOUT_PERCENT=0`
- Stop proxy service
- Document incident for post-mortem

## Questions and Gaps

1. **TypeScript Migration**: Current implementation is in JavaScript. Do we need to migrate to TypeScript before proceeding?

2. **Shared Package Structure**: The current implementation has code in the proxy service. Should we move to a shared package structure?

3. **CI/CD Pipeline**: How will automated testing and deployment be handled?

4. **Auth Mechanism**: What type of authentication does the Social Intelligence API expect?

5. **Metrics Collection Granularity**: Are the current metrics sufficient for alerting and monitoring?

6. **Grafana Dashboard**: Need to create a Grafana dashboard for monitoring the proxy service.

7. **Rate Limiting**: Should we implement rate limiting in the proxy service?

8. **Backup Strategy**: How should Redis data be backed up?

9. **SLAs/SLOs**: What are the specific service level objectives for the proxy service?

10. **Documentation**: Need to create operational documentation for the DevOps team.

## Implementation Timeline

| Week | Focus | Tasks |
|------|-------|-------|
| 1 | Verification | Complete checklist items, fix immediate gaps |
| 1 | High Priority | Implement auth, cache fallback, alerting |
| 2 | Medium Priority | Set up load testing, canary deployment |
| 2 | Low Priority | Implement cache-bust endpoint |
| 3 | Testing | End-to-end testing, load testing |
| 3 | Rollout | Begin gradual rollout if go criteria met |
