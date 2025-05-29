# Platform Stability Guide

## Critical Configuration Requirements

### 1. Environment Variables (.env)
```bash
# REQUIRED - Security Critical
REDIS_PASSWORD=NTWtO6kBAsuoaKQJMXEqXEE8qxcHNmrc
POSTGRES_PASSWORD=postgres
JWT_SIGNING_KEY=<secure-key>

# REQUIRED - Slack Integration
SLACK_APP_TOKEN=xapp-...
SLACK_BOT_TOKEN=xoxb-...
SLACK_SIGNING_SECRET=<secret>

# REQUIRED - GitHub Registry
GHCR_PAT=ghp_...
```

### 2. Docker Compose Configuration

Create a single override file `docker-compose.override.yml`:
```yaml
services:
  redis:
    command: redis-server /usr/local/etc/redis/redis.conf
    volumes:
      - ./config/redis.conf:/usr/local/etc/redis/redis.conf:ro

  db-storage:
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}

  db-auth:
    environment:
      GOTRUE_DB_DATABASE_URL: postgres://postgres:${POSTGRES_PASSWORD}@db-postgres:5432/postgres?search_path=auth

  db-api:
    environment:
      PGRST_DB_URI: postgres://postgres:${POSTGRES_PASSWORD}@db-postgres:5432/postgres
```

### 3. Service Startup Order

Always start services in this order:
```bash
# 1. Core Infrastructure
docker compose up -d redis db-postgres

# 2. Wait for health
docker compose exec redis redis-cli -a $REDIS_PASSWORD ping
docker compose exec db-postgres pg_isready

# 3. Start dependent services
docker compose up -d
```

### 4. Common Issues and Fixes

#### Redis Authentication Lost
```bash
# Verify Redis is using config
docker compose exec redis ps aux | grep redis-server
# Should show: redis-server /usr/local/etc/redis/redis.conf

# If not, restart with config
docker compose up -d --force-recreate redis
```

#### Stuck Messages in Redis Streams
```bash
# Check consumer groups
docker compose exec -T redis redis-cli -a $REDIS_PASSWORD XINFO CONSUMERS mcp.responses slack-gateway

# Clear stuck messages
docker compose exec -T redis redis-cli -a $REDIS_PASSWORD XGROUP DESTROY mcp.responses slack-gateway
docker compose restart slack_mcp_gateway echo-agent
```

#### Slack Not Responding
1. Check logs: `docker compose logs slack_mcp_gateway --tail 50`
2. Look for "No metadata found" errors
3. Clear Redis consumer groups (see above)
4. Rebuild and restart: `docker compose build slack_mcp_gateway && docker compose up -d slack_mcp_gateway`

### 5. Health Monitoring

Monitor these endpoints:
- Redis: `docker compose exec redis redis-cli -a $REDIS_PASSWORD ping`
- Slack Gateway: `curl http://localhost:3010/health`
- Agent Core: `curl http://localhost:8011/health`

### 6. Backup Critical Configs

Before any changes:
```bash
# Backup configs
cp .env .env.backup
cp docker-compose.override.yml docker-compose.override.yml.backup
cp config/redis.conf config/redis.conf.backup
```

### 7. Security Checklist

- [ ] Redis password set in .env
- [ ] Redis config mounted as volume
- [ ] Dangerous Redis commands disabled
- [ ] All services use environment variables for credentials
- [ ] No hardcoded passwords in docker-compose files
- [ ] Regular credential rotation schedule

### 8. Recovery Script

Use `/scripts/recover-services-simple.sh` for quick recovery:
```bash
./scripts/recover-services-simple.sh
```

## Prevention

1. **Single Configuration Source**: Use `.env` for all credentials
2. **Persistent Volumes**: Mount config files as read-only volumes
3. **Health Checks**: Ensure dependencies are healthy before starting services
4. **Monitoring**: Set up alerts for service failures
5. **Documentation**: Keep this guide updated with new issues

## Emergency Contacts

- Security incidents: Follow docs/security/incident-response.md
- Platform issues: Check this guide first
- Credential rotation: See docs/security/credential-rotation.md
