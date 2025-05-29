# Healthcheck Standardisation Runbook

## Purpose
Ensure 100% of services expose a `/health` endpoint and Docker `healthcheck` blocks.

## Checklist
- [ ] Service code returns 200 OK for `/health`
- [ ] `HEALTH_PORT` env set if non-default
- [ ] Docker compose `healthcheck` green locally (`docker compose ps`)

## Standard Healthcheck Configuration

```yaml
healthcheck:
  test: ["CMD-SHELL", "curl -fs http://localhost:${HEALTH_PORT:-8080}/health || exit 1"]
  interval: 30s
  timeout: 5s
  retries: 3
```

## Service-Specific Ports

| Service | Health Port | Endpoint |
|---------|-------------|----------|
| agent-core | 8011 | /health |
| agent-rag | 8012 | /health |
| agent-social | 8013 | /health |
| slack_mcp_gateway | 3000 | /health |
| db-api | 3000 | / |
| db-auth | 9999 | /health |
| db-realtime | 4000 | / |

## Verification Steps

1. **Start services with healthchecks**: `docker compose -f docker-compose.yml -f docker-compose.healthchecks.yml up -d`
2. **Wait for startup**: `sleep 30`
3. **Check health status**: `docker compose ps`
4. **Verify all show "(healthy)"**: All services should show health status

## Usage

Apply the healthcheck overlay by including both compose files:
```bash
docker compose -f docker-compose.yml -f docker-compose.healthchecks.yml up -d
```

## Troubleshooting

### Service shows "unhealthy"
1. Check logs: `docker logs <service-name>`
2. Test endpoint manually: `docker exec <service-name> curl -v localhost:<port>/health`
3. Verify port mapping in docker-compose.yml

### Missing /health endpoint
1. Check service implementation for health endpoint
2. Add health endpoint if missing (see templates in services/_template/)
3. Rebuild image after adding endpoint

## Implementation Template

### Python (FastAPI)
```python
@app.get("/health")
async def health():
    return {"status": "healthy"}
```

### Node.js (Express)
```javascript
app.get('/health', (req, res) => {
  res.json({ status: 'healthy' });
});
```

### Go
```go
http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
    w.WriteHeader(http.StatusOK)
    json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
})
```
