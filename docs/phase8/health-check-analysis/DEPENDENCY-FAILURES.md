# Missing Dependencies Analysis

## Services Missing curl in Container

Many services have health checks that use `curl` but don't have it installed:

1. **llm-service** - Ollama image doesn't include curl
2. **vector-db** - Milvus image doesn't include curl
3. **db-storage** - Supabase storage image missing curl

## Empty Log Services (Not Starting)

These services have completely empty logs, suggesting they're not starting at all:

1. **agent-atlas** (atlas-worker:latest)
   - Build issue or missing entrypoint

2. **agent-social** (alfred-agent-platform-v2-social-intel:latest)
   - Build issue or missing entrypoint

3. **model-router**
   - Missing app/ directory in build context
   - Wrong healthcheck image reference

4. **model-registry**
   - Missing app/ directory in build context
   - Wrong healthcheck image reference

## Database Services Issues

1. **db-admin** (supabase/studio)
   - External image, may need specific environment variables

2. **db-api** (postgrest/postgrest)
   - External image, may need database connection config

3. **db-realtime** (supabase/realtime)
   - External image, may need specific configuration

4. **db-storage** (custom build)
   - Complex service with migration scripts

## Metrics Services (Port Mismatch)

All db-*-metrics services:
- Health check on port 9091 but service runs on 9103
- Health check uses /metrics but service provides /health

## Summary of Required Fixes

1. **Install curl** in services that need it for health checks
2. **Fix port mismatches** in all metrics services
3. **Create missing app directories** for model services
4. **Fix healthcheck image references**
5. **Extend start periods** for slow services
6. **Debug empty-log services** for startup issues
