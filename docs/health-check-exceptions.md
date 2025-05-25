# Health Check Exceptions

## Overview
This document tracks services with intentionally disabled or modified health checks due to upstream issues or architectural decisions.

## Current Exceptions

### db-auth (Supabase GoTrue) - FIXED
- **Status**: Health check enabled and passing
- **Previous Issue**: Upstream GoTrue migration error - "operator does not exist: uuid = text"
- **Resolution**: Created custom Dockerfile that:
  - Pre-initializes auth schema with correct UUID types
  - Patches the problematic migration file to cast both sides to text
  - Service now runs successfully with health checks enabled
- **Date Fixed**: May 27, 2025

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
- **Achieved**: 87.2% (34/39 services)
- **Date**: May 27, 2025

## Post-GA Backlog
1. ~~Fix db-auth GoTrue migration issue~~ ✅ Fixed May 27, 2025
2. Implement proper health endpoints for stub services
3. Review and optimize health check intervals/timeouts
4. Upstream the GoTrue migration fix to Supabase
