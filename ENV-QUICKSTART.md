# Environment Variables Quick Start

## For New Developers / Fresh Pull

```bash
# 1. One-time setup (creates .env from template)
./setup-local-env.sh

# 2. Edit .env with actual secrets
vi .env

# 3. Validate your setup
./scripts/validate-env.sh

# 4. Start services with env vars
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.override.env.yml up -d

# Or use the alias (add to ~/.bashrc):
alias alfred-up='docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.override.env.yml up -d'
```

## Quick Fixes

### Slack not working?
```bash
# Check if env vars are loaded
docker exec slack-adapter env | grep SLACK

# If missing, restart with env override:
docker compose -f docker-compose.yml -f docker-compose.override.yml -f docker-compose.override.env.yml up -d slack-adapter
```

### Missing env vars after git pull?
```bash
# Always run validation after pull
./scripts/validate-env.sh

# If new vars added to template:
diff .env.template .env
# Add missing vars to your .env
```

### Build failing due to env vars?
```bash
# Export env vars before build
export $(grep -v '^#' .env | xargs)
docker compose build
```

## Environment Variable Sources

1. **Local Development**: `.env` file (never committed)
2. **CI/CD**: GitHub Secrets
3. **Staging/Prod**: Kubernetes Secrets

## Service-Specific Requirements

| Service | Required Env Vars |
|---------|------------------|
| slack-adapter | SLACK_SIGNING_SECRET, SLACK_BOT_TOKEN, SLACK_APP_TOKEN |
| slack-mcp-gateway | SLACK_APP_TOKEN, SLACK_BOT_TOKEN |
| agent-core | REDIS_PASSWORD, JWT_SIGNING_KEY |
| all services | GHCR_PAT (for pulling images) |

## Troubleshooting

1. **"Permission denied" when pulling images**
   - Check GHCR_PAT is valid
   - Login: `echo $GHCR_PAT | docker login ghcr.io -u USERNAME --password-stdin`

2. **"Slack commands not responding"**
   - Verify SLACK_APP_TOKEN starts with `xapp-`
   - Verify SLACK_BOT_TOKEN starts with `xoxb-`
   - Check docker logs: `docker logs slack-adapter`

3. **"Redis connection failed"**
   - Ensure REDIS_PASSWORD matches redis service config
   - Check redis is running: `docker ps | grep redis`

## Security Notes

- NEVER commit .env files
- Use different secrets for dev/staging/prod
- Rotate tokens regularly
- Use read-only GHCR tokens when possible