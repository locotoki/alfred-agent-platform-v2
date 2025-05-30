# Service Explosion Issue

**Date**: May 30, 2025  
**Issue**: Container count jumped from 23 to 31 when using core slice

## Root Cause

The docker-compose.yml file contains **50 services** total, not the expected 39. Many were not running before because they weren't explicitly started.

## Services That Appeared

### Supabase Stack
- db-admin (Studio UI)
- db-storage (S3-compatible storage)
- db-realtime (Websocket server)
- auth-ui (Authentication UI)

### Metrics Services (9 total)
- db-admin-metrics
- db-api-metrics
- db-auth-metrics
- db-realtime-metrics
- db-storage-metrics

### Other Services
- ui-admin
- ui-chat
- hubspot-mock
- mail-server
- crm-sync
- contact-ingest

## Why This Happened

When we ran with `-f docker-compose.yml -f docker-compose.core.yml`, Docker Compose:
1. Loaded ALL 50 services from docker-compose.yml
2. Applied our overrides (scaling some to 0)
3. Started everything else that wasn't scaled down

## Solution Options

1. **Explicit service list**: Start only named services
   ```bash
   docker-compose up -d redis redis-exporter db-postgres db-api agent-core telegram-adapter pubsub-metrics monitoring-metrics monitoring-dashboard
   ```

2. **Better override file**: Set `replicas: 0` for ALL unwanted services

3. **Separate minimal compose file**: Create docker-compose.minimal.yml with only core services

## Impact

- More containers = more resource usage
- More complexity in health tracking
- Confusing metrics (31 containers when expecting ~10)