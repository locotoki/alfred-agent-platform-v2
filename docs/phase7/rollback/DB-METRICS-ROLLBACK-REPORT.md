# DB Metrics v0.8.1-rc1 Rollback Report

## Decision: ROLLBACK ❌

### Timestamp: 2025-05-16 14:55 UTC

## Issues Detected

1. **Health check failures in 2 of 5 db-metrics services**:
   - db-api-metrics: HTTP 500 error on `/health` endpoint
   - db-admin-metrics: HTTP 500 error on `/health` endpoint
   - Other 3 services (db-storage-metrics, db-auth-metrics, db-realtime-metrics) appear healthy

2. **Missing monitoring reports**:
   - T+3h and T+6h logs were not found in `/monitoring/screenshots/`
   - Only T0 report (from 2025-05-15 22:00 UTC) was available

## Verification Performed

1. Checked all running db-metrics containers:
   - All 5 containers were running with Docker status "healthy"
   - This is because the `/healthz` endpoint (used by Docker) returns 200 OK
   - The main `/health` endpoint returns 500 for 2 services

2. Memory usage verification:
   - All services well below threshold (< 50MiB, threshold was 200MiB)
   - db-admin-metrics: 26.71MiB
   - db-api-metrics: 26.09MiB
   - db-auth-metrics: 27.36MiB 
   - db-realtime-metrics: 25.75MiB
   - db-storage-metrics: 28.62MiB

3. Service logs:
   - No explicit connection errors in the logs
   - The `/health` endpoint is failing with 500 error only when directly accessed

## Rollback Actions Taken

1. Deleted the v0.8.1-rc1 tag
2. Manual rollback since the automatic rollback workflow (rollback-staging.yml) was not found

## Next Steps

1. Investigate why the `/health` endpoint is failing for db-api-metrics and db-admin-metrics
2. Review why T+3h and T+6h monitoring logs were not generated
3. Fix issues before attempting another canary deployment
4. Implement the missing rollback workflow

## Prepared by

Claude (Automated Canary Monitor)
2025-05-16