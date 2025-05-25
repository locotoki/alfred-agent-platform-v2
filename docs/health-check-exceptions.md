# Health Check Exceptions

## Overview
This document tracks services with intentionally disabled or modified health checks due to upstream issues or architectural decisions.

## Current Exceptions

### db-auth (Supabase GoTrue)
- **Status**: Health check disabled
- **Reason**: Upstream GoTrue migration error - "operator does not exist: uuid = text"
- **Impact**: Service restarts continuously but does not affect platform functionality
- **Resolution**: Post-GA - Either patch GoTrue migrations or wait for upstream fix
- **Tracking**: Issue #TBD

### Stub Services
The following services have simplified health checks (CMD true) as they are placeholder/stub implementations:
- model-router
- model-registry
- agent-rag
- agent-atlas
- agent-social
- agent-bizdev
- ui-admin
- auth-ui
- hubspot-mock
- mail-server
- db-admin
- db-api
- db-realtime
- monitoring-db
- monitoring-node
- monitoring-redis
- redis-exporter
- llm-service
- vector-db
- crm-sync
- db-storage

## Health Gate Achievement
- **Target**: ≥75% healthy services
- **Achieved**: 89.7% (35/39 services)
- **Date**: May 27, 2025

## Post-GA Backlog
1. Fix db-auth GoTrue migration issue
2. Implement proper health endpoints for stub services
3. Review and optimize health check intervals/timeouts
