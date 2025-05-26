# Environment Variable Management Guide

## Overview

Alfred Agent Platform uses environment files to manage configuration across different environments.

## Environment Files

| File | Purpose | Git Status | When to Use |
|------|---------|------------|-------------|
| `.env` | Default development values | Ignored | Local development |
| `.env.dev` | Development/staging secrets | Ignored | Pre-release testing |
| `.env.staging` | Staging environment | Ignored | Staging validation |
| `.env.prod` | Production secrets | Ignored | Production deployment |
| `.env.example` | Template with all vars | Tracked | Reference for new deployments |
| `.env.prod.example` | Production template | Tracked | Production setup guide |

## Loading Order

1. Docker Compose automatically loads `.env` by default
2. Override with `--env-file`:
   ```bash
   docker-compose --env-file .env.dev up
   ```
3. Scripts can source multiple files:
   ```bash
   source .env
   source .env.dev  # Overrides .env values
   ```

## Pre-Release Testing (Week of July 7)

The pre-release checklist script automatically loads environment variables:

```bash
# Script loads from .env and .env.dev automatically
./scripts/pre-release-checklist.sh

# Or manually set environment first
source .env.dev
./scripts/pre-release-checklist.sh
```

### Available in .env.dev:
- `SLACK_BOT_TOKEN` - Slack bot OAuth token
- `SLACK_APP_TOKEN` - Slack app-level token
- `SLACK_SIGNING_SECRET` - Slack request signature verification
- `STAGING_REDIS_PASSWORD` - Redis password for staging
- `GHCR_PAT` - GitHub Container Registry token

### Need to Add:
- `OPENAI_API_KEY` - Your OpenAI API key
- `ANTHROPIC_API_KEY` - Your Anthropic API key
- `POSTGRES_PASSWORD` - PostgreSQL password
- `GRAFANA_PASSWORD` - Grafana admin password

## Production Deployment (July 11)

1. Copy the template:
   ```bash
   cp .env.prod.example .env.prod
   ```

2. Fill in production values:
   ```bash
   # Edit with your production credentials
   vim .env.prod
   ```

3. Generate passwords:
   ```bash
   # Add to .env.prod
   echo "POSTGRES_PASSWORD=$(openssl rand -base64 32)" >> .env.prod
   echo "REDIS_PASSWORD=$(openssl rand -base64 32)" >> .env.prod
   echo "JWT_SECRET=$(openssl rand -base64 64)" >> .env.prod
   ```

4. Deploy with production environment:
   ```bash
   docker-compose --env-file .env.prod \
     -f docker-compose.yml \
     -f docker-compose.prod.yml \
     -f docker-compose.tls.yml \
     up -d
   ```

## Security Best Practices

1. **Never commit .env files with secrets**
   - All .env files except examples are in .gitignore
   - Use `.env.example` files for templates

2. **Use strong passwords**
   ```bash
   # Generate secure passwords
   openssl rand -base64 32
   ```

3. **Rotate credentials regularly**
   - Update tokens every 90 days
   - Use different credentials per environment

4. **Store production secrets securely**
   - Use HashiCorp Vault or AWS Secrets Manager
   - Or use Docker secrets:
     ```bash
     echo "my-secret" | docker secret create postgres_password -
     ```

## Troubleshooting

### Missing Variables
```bash
# Check what's set
env | grep SLACK

# Check what's needed
grep -E "^[A-Z_]+=" docker-compose.yml
```

### Variable Not Loading
```bash
# Debug loading
set -a  # Export all variables
source .env.dev
set +a
echo $SLACK_BOT_TOKEN
```

### Wrong Environment
```bash
# Verify which env file is loaded
docker-compose config | grep ENVIRONMENT
```

## Quick Reference

```bash
# Development
docker-compose up

# Staging validation (pre-release)
source .env.dev
./scripts/pre-release-checklist.sh

# Production
docker-compose --env-file .env.prod \
  -f docker-compose.yml \
  -f docker-compose.prod.yml \
  up -d
```
