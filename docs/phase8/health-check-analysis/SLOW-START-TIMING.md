# Slow-Start Services Timing Profile

## Current vs Recommended Timing

| Service | Current Settings | Issue | Recommended |
|---------|-----------------|-------|-------------|
| **llm-service** (Ollama) | interval=30s, timeout=10s, start_period=120s, retries=3 | Missing curl, needs 3-5 min to download models | start_period=300s, add curl to healthcheck |
| **vector-db** (Milvus) | interval=30s, timeout=10s, start_period=60s, retries=3 | Missing curl, needs 2-3 min to initialize | start_period=180s, add curl to healthcheck |
| **db-storage** | interval=30s, timeout=10s, start_period=60s, retries=3 | Migration scripts take time | start_period=120s |
| **db-admin** | interval=30s, timeout=10s, start_period=45s, retries=3 | Supabase Studio slow init | start_period=90s |
| **db-api** | interval=30s, timeout=10s, start_period=45s, retries=3 | PostgREST connection setup | start_period=60s |
| **db-realtime** | interval=30s, timeout=10s, start_period=45s, retries=3 | Realtime service init | start_period=90s |

## Alternative Health Check Strategies

### For Services Without curl

Instead of installing curl in every container, we can:

1. **Use wget** (often pre-installed):
   ```yaml
   healthcheck:
     test: ["CMD", "wget", "-qO-", "http://localhost:PORT/endpoint"]
   ```

2. **Use service-specific tools**:
   - Ollama: Use ollama CLI if available
   - Milvus: Use milvus_cli if available
   - PostgreSQL-based: Use pg_isready

3. **TCP port check** (simplest):
   ```yaml
   healthcheck:
     test: ["CMD", "sh", "-c", "echo > /dev/tcp/localhost/PORT"]
   ```

## Timing Recommendations Summary

1. **Fast services** (< 30s startup): Keep current timing
2. **Medium services** (30s-90s): start_period=90s
3. **Slow services** (90s-180s): start_period=180s
4. **Very slow services** (> 180s): start_period=300s

## Services That Just Need More Time

These services are probably fine, just need longer start_period:
- llm-service: Downloading models on first start
- vector-db: Initializing vector indices
- db-storage: Running migrations
- Supabase services: Complex initialization
