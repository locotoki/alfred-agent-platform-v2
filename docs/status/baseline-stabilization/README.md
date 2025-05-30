# Baseline Stabilization Plan

## Problem Statement

The platform currently suffers from "fix → break → fix" cycles due to:
- No single contract defining what constitutes a "working core slice"
- Health probes evaluated inconsistently
- Unclear which hardening controls are mandatory vs optional
- Every local run is a discovery exercise
- Patches can accidentally shift the baseline

## Solution: 5-Phase Stabilization

### Phase 1: Inventory & Verify ✅
**Goal**: Know exactly what is already in place  
**Deliverable**: Automated audit script that prints:
- Enabled services & images
- Hash of every health-check command  
- PostgreSQL roles + privileges
- Enabled PostgreSQL settings (pgaudit, TLS, etc.)

**Status**: Complete
- Created `scripts/audit-core.sh`
- Captures baseline configuration

### Phase 2: Lock the Baseline 🚧
**Goal**: One command spins up the same core slice everywhere  
**Deliverable**: Docker Compose profile or override that contains exactly 10 services
- If audit script's hash doesn't match, build fails

**Status**: In Progress
- Created `scripts/bootstrap-dev.sh` for reproducible setup
- Created `scripts/check-core-health.sh` for health verification
- Need to fix db-api unhealthy status (missing anon role)

### Phase 3: Golden Image Build 📋
**Goal**: Remove "works only on my laptop" issues  
**Deliverable**: GitHub Action builds & pushes pre-hardened images
- Images tagged as `core-golden-<commitSha>`
- Local compose.yml pins to those tags

### Phase 4: Health-Gate in CI 📋
**Goal**: Catch drift before merge  
**Deliverable**: Smoke test workflow that:
1. `docker compose --profile core up -d`
2. Waits 2 minutes
3. Asserts all health probes = healthy
4. Runs audit script and fails if any diff

### Phase 5: Progressively Unfreeze Extras 📋
**Goal**: Add features without destabilizing core  
**Deliverable**: Each extra group lives in its own profile
- UI, Supabase, CRM, Slack in separate profiles
- Each has its own smoke test
- Failing "extras" don't block core

## Core Slice Definition

The following 10 services constitute the GA-critical core:

| Service | Purpose | Health Check |
|---------|---------|--------------|
| redis | Cache & pub/sub | redis-cli ping |
| redis-exporter | Metrics export | wget metrics endpoint |
| db-postgres | Primary database | pg_isready |
| db-api | PostgREST API | curl / endpoint |
| agent-core | Core agent logic | wget /health |
| telegram-adapter | Telegram integration | curl /health |
| pubsub-emulator | Google PubSub emulator | curl topics endpoint |
| pubsub-metrics | PubSub metrics | curl /health |
| monitoring-metrics | Prometheus | wget /-/ready |
| monitoring-dashboard | Grafana | wget /api/health |

## Current Issues

### db-api Unhealthy
- **Root Cause**: Missing PostgreSQL `anon` role
- **Fix**: Execute SQL to create role
- **Long-term**: Add to `docker/initdb/00-create-anon.sql`

### PostgreSQL Hardening
- Password authentication enforced (good)
- Need to verify pgaudit and SSL settings
- Capture in baseline audit

## Scripts

### `scripts/audit-core.sh`
Captures current state including:
- Service images and versions
- Health check configuration hash
- PostgreSQL roles and settings
- Container health summary

### `scripts/bootstrap-dev.sh`
One-command setup for new developers:
- Checks prerequisites
- Creates Docker network
- Starts only core services
- Attempts to fix db-api
- Runs health check
- Saves audit report

### `scripts/check-core-health.sh`
Quick health status check:
- Shows each container's health
- Counts healthy/unhealthy/starting
- Validates GA requirement (≤2 unhealthy)

## Next Steps

1. **Immediate**: Fix db-api by creating anon role
2. **Today**: Capture baseline audit hash
3. **This Week**: Create GitHub Action for CI health gate
4. **Next Week**: Build golden images

## Success Criteria

- Any developer can clone repo and run `./scripts/bootstrap-dev.sh`
- All 10 core services report healthy within 2 minutes
- CI prevents merging changes that break core health
- Audit hash ensures no configuration drift