# Database Services Analysis - Supabase Overload! 🗄️

## Current Situation
We have **9 database-related containers** running:

### Core Database
1. **db-postgres** ✅ - Main PostgreSQL database (ESSENTIAL)

### Supabase Stack (5 services)
2. **db-auth** - Authentication service (GoTrue)
3. **db-api** - REST API generator (PostgREST)
4. **db-admin** - Web UI (Supabase Studio)
5. **db-realtime** - WebSocket subscriptions
6. **db-storage** ❌ - Broken (wrong image)

### Metrics Exporters (3 services)
7. **db-auth-metrics** - Monitors db-auth
8. **db-api-metrics** - Monitors db-api
9. **db-admin-metrics** - Monitors db-admin
10. **db-realtime-metrics** - Monitors db-realtime
11. **db-storage-metrics** - Monitors db-storage
12. **db-exporter** - PostgreSQL metrics
13. **monitoring-db** - PostgreSQL metrics (duplicate!)

## The Problems

### 1. Incomplete Supabase Setup
- Missing `postgres-meta` service
- Missing `supabase-kong` API gateway
- `db-admin` references these missing services
- `db-storage` using wrong image

### 2. Over-Monitoring
- Each Supabase service has its own metrics exporter
- Two PostgreSQL exporters (db-exporter AND monitoring-db)
- That's 7 monitoring containers for 5 database services!

### 3. Questionable Necessity
- Are we actually using Supabase features?
- Do we need real-time subscriptions?
- Do we need the admin UI?
- Do we need separate auth service?

## Recommendations

### Option A: Full Supabase (Complex)
Fix the setup by adding missing components:
- Add postgres-meta
- Add supabase-kong
- Fix db-storage image
- Keep all services

### Option B: Minimal Database (Recommended) ✅
Keep only what's essential:
1. **db-postgres** - Main database
2. **db-exporter** - PostgreSQL metrics
3. Remove all Supabase services
4. Remove redundant metrics exporters

### Option C: Partial Supabase
Keep core functionality:
1. **db-postgres** - Main database
2. **db-auth** - If authentication is needed
3. **db-api** - If REST API is used
4. **db-exporter** - Single metrics exporter
5. Remove everything else

## Impact Analysis

### Services Using Database
```bash
# Check which services actually connect to Supabase
grep -E "db-api|db-auth|SUPABASE" docker-compose.yml
```

### Result
- agent-atlas uses SUPABASE_URL (db-api)
- agent-social uses SUPABASE_URL (db-api)
- Several services use DATABASE_URL (direct PostgreSQL)

## Recommended Action Plan

1. **Immediate**: Disable broken/unused services
   - db-storage (broken)
   - db-admin (missing dependencies)
   - All metrics exporters except one

2. **Evaluate**: Check if agents actually use Supabase features
   - If not, remove db-api, db-auth, db-realtime
   - If yes, fix the setup properly

3. **Simplify**: One database, one metrics exporter
   - Keep db-postgres
   - Keep db-exporter OR monitoring-db (not both)