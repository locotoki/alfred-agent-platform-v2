# Phase 2 Rollout Playbook

This document outlines the canary release process for Phase 2 (Advanced Analytics) of the Social Intelligence service.

## Pre-Rollout Checklist

| Item | Status | Owner | Notes |
|------|--------|-------|-------|
| All unit tests passing | 🔄 | QA Lead | Must be 100% |
| Integration tests passing | 🔄 | QA Lead | Must be 100% |
| Load test thresholds met | 🔄 | Platform Eng | See performance criteria |
| Database migrations tested | 🔄 | DBA | Verify in staging |
| Feature toggles configured | 🔄 | DevOps | See feature flag table |
| Rollback procedures tested | 🔄 | DevOps | Full rehearsal required |
| Monitoring dashboards ready | 🔄 | SRE | All alerts configured |
| Documentation updated | 🔄 | Tech Writer | API docs, release notes |
| Security sign-off | 🔄 | Security | Penetration test results reviewed |
| Privacy sign-off | 🔄 | Legal | PIA completed |

## Rollout Phases

### Phase 1: Infrastructure Preparation (T-7 days)

1. **Scale up database**:
   - Add read replicas for analytics queries
   - Verify replication lag < 5 seconds
   - Test query performance with production-like load

2. **Deploy monitoring infrastructure**:
   - New Grafana dashboards for analytics metrics
   - Configure Prometheus alerts for key thresholds
   - Set up PagerDuty integration for critical alerts

3. **Prepare feature flags**:
   - Configure LaunchDarkly or equivalent
   - Set up user segmentation for canary groups
   - Test flag behavior in staging environment

### Phase 2: Canary Deployment (Day 0)

| Stage | Traffic % | Duration | Success Criteria | Rollback Criteria |
|-------|-----------|----------|------------------|-------------------|
| **Alpha** | 1% | 1 day | No P1 errors | Any P1 error |
| **Beta** | 10% | 3 days | p95 latency < target | p95 latency > 1.5x target |
| **Gamma** | 25% | 2 days | Error rate < 0.1% | Error rate > 0.5% |
| **Delta** | 50% | 2 days | CPU/RAM < 70% capacity | CPU/RAM > 90% capacity |
| **Full** | 100% | N/A | All metrics within target | N/A |

#### Canary Deployment Commands

```bash
# Deploy with 1% traffic (Alpha)
FEATURE_ANALYTICS_ENABLED=0.01 docker compose up -d social-intel

# Verify deployment
./scripts/verify-deployment.sh social-intel v2.0.0

# Monitor for 24 hours
./scripts/canary-monitor.sh --threshold=alpha

# Increase to 10% traffic (Beta)
FEATURE_ANALYTICS_ENABLED=0.1 docker compose up -d social-intel

# Continue with remaining stages following the same pattern
```

### Phase 3: Post-Deployment Validation (Day 0 + X days)

1. **Smoke tests**:
   - Verify all API endpoints are accessible
   - Confirm dashboard components load correctly
   - Check all integrations are functioning

2. **Performance validation**:
   - Run full load test against production
   - Verify database query performance
   - Check cache hit rates against targets

3. **User acceptance**:
   - Internal stakeholder validation
   - Focused customer feedback sessions
   - Feature usage analytics review

## Monitoring During Rollout

### Key Metrics to Watch

| Metric | Description | Target | Alert Threshold | Dashboard |
|--------|-------------|--------|-----------------|-----------|
| **API Latency** | p95 response time for analytics endpoints | < 500ms | > 800ms | Service Health |
| **Error Rate** | Percentage of 5xx responses | < 0.1% | > 0.5% | Service Health |
| **Database Load** | CPU utilization of analytics DB | < 60% | > 80% | DB Performance |
| **Memory Usage** | RAM usage of analytics services | < 70% | > 85% | Resource Usage |
| **Cache Hit Rate** | Percentage of cached responses | > 80% | < 60% | Service Performance |
| **Vector Query Time** | p95 latency for vector searches | < 100ms | > 200ms | Vector Database |
| **ML Inference Time** | Average time for recommendations | < 300ms | > 500ms | ML Performance |

### Dashboards

- **Canary Health**: https://grafana.example.com/d/analytics-canary
- **API Performance**: https://grafana.example.com/d/analytics-api
- **User Experience**: https://grafana.example.com/d/analytics-ux
- **Resource Usage**: https://grafana.example.com/d/analytics-resources
- **Error Tracking**: https://grafana.example.com/d/analytics-errors

## Feature Flags

| Flag Name | Description | Default | Fallback Behavior |
|-----------|-------------|---------|-------------------|
| `FEATURE_ANALYTICS_ENABLED` | Master toggle for analytics features | `0` (off) | Return basic metrics only |
| `FEATURE_TREND_FORECASTING` | Enable ML-based trend forecasting | `0` (off) | Return historical data only |
| `FEATURE_CROSS_PLATFORM` | Enable cross-platform analytics | `0` (off) | Return YouTube data only |
| `FEATURE_RECOMMENDATIONS` | Enable personalized recommendations | `0` (off) | Return generic recommendations |
| `FEATURE_COMPETITOR_HEATMAP` | Enable competitor heatmap visualization | `0` (off) | Return text-based competitor list |

## Rollback Procedures

### Immediate Rollback Triggers

- p95 API latency exceeds 1.5x target (> 750ms)
- Error rate exceeds 1% for any 15-minute period
- Database CPU sustained above 85% for 10 minutes
- Critical security vulnerability discovered
- Data integrity issue detected

### Rollback Commands

```bash
# Disable new features via feature flag (fastest)
FEATURE_ANALYTICS_ENABLED=0 docker compose up -d social-intel

# If feature flags are not sufficient, roll back to previous version
docker compose stop social-intel
docker tag social-intel:v1.0.0 social-intel:latest
docker compose up -d social-intel

# Verify rollback
./scripts/verify-deployment.sh social-intel v1.0.0

# Rollback database schema if necessary (last resort)
cd /home/locotoki/projects/alfred-agent-platform-v2/db/migrations
./rollback_to_v1.sh
```

### Communications During Incident

1. **Internal notification**:
   - Post to #incidents Slack channel
   - Page on-call engineer if after hours
   - Start incident call if severity > 2

2. **External communication**:
   - Update status page
   - Send email for extended incidents
   - Prepare customer support brief

## Success Criteria

The rollout will be considered successful when:

1. **Performance meets targets**:
   - p95 latency < 500ms for all analytics endpoints
   - Error rate < 0.1% sustained over 7 days
   - Forecast accuracy > 80% for 7-day predictions

2. **User adoption metrics**:
   - Dashboard engagement > 3 charts viewed per session
   - Recommendation click-through rate > 15%
   - Repeat usage rate > 60% week-over-week

3. **Business metrics**:
   - Time-to-insight reduced by 70%+ (verified via user surveys)
   - Analytics feature usage in 40%+ of sessions
   - NPS score increase of 15+ points for analytics users

## Post-Rollout Tasks

1. **Feature validation**:
   - Verify all features are functioning as designed
   - Collect initial user feedback
   - Identify any quick-win improvements

2. **Performance optimization**:
   - Review performance metrics for optimization opportunities
   - Analyze query patterns for indexing improvements
   - Tune caching strategies based on hit/miss patterns

3. **Knowledge sharing**:
   - Document lessons learned
   - Update runbooks with new procedures
   - Train support team on new features

## Timeline

| Day | Activity | Owner | Status |
|-----|----------|-------|--------|
| T-7 | Infrastructure preparation | DevOps | 🔄 |
| T-5 | Final staging validation | QA | 🔄 |
| T-3 | Go/No-go decision meeting | Leadership | 🔄 |
| T-1 | Pre-deployment verification | Engineering | 🔄 |
| **T** | **1% canary deployment** | DevOps | 🔄 |
| T+1 | Expand to 10% traffic | DevOps | 🔄 |
| T+4 | Expand to 25% traffic | DevOps | 🔄 |
| T+6 | Expand to 50% traffic | DevOps | 🔄 |
| T+8 | Expand to 100% traffic | DevOps | 🔄 |
| T+9 | Post-deployment validation | QA | 🔄 |
| T+10 | Launch announcement | Marketing | 🔄 |

## Rollout Team

- **Rollout Lead**:
- **Engineering Lead**:
- **QA Lead**:
- **DevOps Engineer**:
- **DBA**:
- **Customer Support Lead**:
