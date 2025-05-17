# Database Services Health Check Analysis

This document outlines the current state of each database service's health check configuration and the planned improvements.

## Overview

The Alfred Agent Platform v2 uses several database services from the Supabase stack:

1. **db-postgres**: PostgreSQL database (already properly configured)
2. **db-auth**: GoTrue authentication service 
3. **db-api**: PostgREST API
4. **db-admin**: Supabase Studio UI
5. **db-realtime**: Realtime updates service
6. **db-storage**: Storage API

## Current Status

| Service | Current Health Check | Status | Issues |
|---------|---------------------|--------|--------|
| db-postgres | `pg_isready -U postgres` | ✅ Working | None |
| db-auth | Not properly configured | ❌ Incomplete | Missing test command |
| db-api | Uses external healthcheck binary | ❌ Not Working | Not compatible |
| db-admin | Uses external healthcheck binary | ❌ Not Working | Not compatible |
| db-realtime | Uses external healthcheck binary | ❌ Not Working | Not compatible |
| db-storage | No test command defined | ❌ Incomplete | Missing test command |

## Required Changes

### 1. db-auth (GoTrue)

**Current Configuration:**
```yaml
healthcheck:
  <<: *basic-health-check
```

**Missing:** Test command

**Recommended Solution:**
```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:9999/health"]
  <<: *basic-health-check
```

**Metrics Port:** 9110

### 2. db-api (PostgREST)

**Current Configuration:**
```yaml
healthcheck:
  test: ["CMD", "healthcheck", "--http", "http://localhost:3000/"]
  <<: *basic-health-check
```

**Issue:** Using external healthcheck binary

**Recommended Solution:**
```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/"]
  <<: *basic-health-check
```

**Metrics Port:** 9111

### 3. db-admin (Supabase Studio)

**Current Configuration:**
```yaml
healthcheck:
  test: ["CMD", "healthcheck", "--http", "http://localhost:3001/api/health"]
  <<: *basic-health-check
```

**Issue:** Using external healthcheck binary

**Recommended Solution:**
```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:3000/api/health"]
  <<: *basic-health-check
```

**Metrics Port:** 9112

### 4. db-realtime (Realtime updates)

**Current Configuration:**
```yaml
healthcheck:
  test: ["CMD", "healthcheck", "--tcp", "localhost:4000"]
  <<: *basic-health-check
```

**Issue:** Using external healthcheck binary

**Recommended Solution:**
```yaml
healthcheck:
  test: ["CMD-SHELL", "nc -z localhost 4000 || exit 1"]
  <<: *basic-health-check
```

**Metrics Port:** 9113

### 5. db-storage (Storage API)

**Current Configuration:**
```yaml
healthcheck:
  <<: *basic-health-check
```

**Missing:** Test command

**Recommended Solution:**
```yaml
healthcheck:
  test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:5000/health"]
  <<: *basic-health-check
```

**Metrics Port:** 9114

## Metrics Implementation Plan

For each database service, we'll need to:

1. Create a simple metrics exporter for HTTP services (db-auth, db-api, db-admin, db-storage)
2. Create a TCP connection metrics exporter for db-realtime
3. Add metrics endpoints on the designated ports (9110-9114)
4. Update Prometheus configuration to scrape these endpoints
5. Update Grafana dashboard to display these metrics

## Implementation Priority

1. db-auth: High priority (authentication service)
2. db-api: High priority (API service)
3. db-storage: Medium priority (storage service)
4. db-admin: Low priority (admin UI)
5. db-realtime: Low priority (realtime updates)