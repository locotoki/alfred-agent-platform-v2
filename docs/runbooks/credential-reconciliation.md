# Credential Reconciliation Runbook

## Overview

This runbook ensures all services in the Alfred platform use consistent credentials for PostgreSQL and Redis, meeting the GA-Hardening exit criteria of "All containers healthy, 0 auth failures".

## Prerequisites

- Docker and Docker Compose installed
- Access to modify `.env` file
- Basic understanding of PostgreSQL and Redis authentication

## Quick Start

```bash
# 1. Run the reconciliation script
./scripts/reconcile-credentials.sh

# 2. Start all services with reconciled credentials
docker-compose -f docker-compose.yml -f docker-compose.override.credentials.yml up -d

# 3. Verify no authentication failures
./scripts/verify-no-auth-failures.sh
```

## Detailed Steps

### 1. Environment Setup

Ensure your `.env` file contains:

```bash
# Database credentials
POSTGRES_PASSWORD=<secure-password>
DB_PASSWORD=<same-as-postgres-password>
DB_USER=postgres
DATABASE_URL=postgresql://postgres:<password>@db-postgres:5432/postgres

# Redis credentials
REDIS_PASSWORD=<secure-redis-password>

# Service URLs (using same passwords)
ALFRED_DATABASE_URL=postgresql://postgres:<password>@db-postgres:5432/postgres
ALFRED_REDIS_URL=redis://:<redis-password>@redis:6379
```

### 2. Run Reconciliation

The reconciliation script will:
- Validate environment variables
- Create Redis configuration with authentication
- Generate credential override file
- Test basic connectivity

```bash
./scripts/reconcile-credentials.sh
```

Expected output:
```
✓ Environment variables loaded
✓ Redis configuration created
✓ Credential override file created
✓ All credential checks passed!
```

### 3. Start Services

Use the credential override file to ensure consistency:

```bash
docker-compose -f docker-compose.yml -f docker-compose.override.credentials.yml up -d
```

### 4. Verify Authentication

Run the verification script to ensure 0 auth failures:

```bash
./scripts/verify-no-auth-failures.sh
```

## Service-Specific Configuration

### Redis Services

Services that connect to Redis must use:
```
REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379
```

Affected services:
- slack_mcp_gateway
- echo-agent
- agent-core
- alfred-bot
- agent_bizops

### PostgreSQL Services

Services that connect to PostgreSQL must use:
```
DATABASE_URL=postgresql://${DB_USER}:${POSTGRES_PASSWORD}@db-postgres:5432/postgres
```

Affected services:
- agent-core
- model-registry
- db-auth (Supabase)
- db-api (PostgREST)
- db-storage

## Troubleshooting

### Common Issues

1. **"NOAUTH Authentication required"**
   - Redis password not set or incorrect
   - Check `REDIS_PASSWORD` in .env
   - Ensure redis.conf is mounted correctly

2. **"password authentication failed for user"**
   - PostgreSQL password mismatch
   - Check `POSTGRES_PASSWORD` matches `DB_PASSWORD`
   - Verify no hardcoded passwords in compose files

3. **Services can't connect**
   - Environment variables not propagated
   - Use the credential override file
   - Check for typos in connection strings

### Debug Commands

```bash
# Test Redis auth
docker exec redis redis-cli -a $REDIS_PASSWORD ping

# Test PostgreSQL auth
docker exec db-postgres psql -U postgres -c "SELECT 1"

# Check service logs
docker-compose logs -f <service-name> | grep -i auth

# List all environment variables in a container
docker exec <container> env | grep -E "(PASSWORD|DATABASE_URL|REDIS)"
```

## Security Best Practices

1. **Never commit credentials**
   - Keep `.env` in `.gitignore`
   - Use secure password generation
   - Rotate credentials regularly

2. **Production considerations**
   - Use secrets management (Vault, K8s secrets)
   - Enable SSL/TLS for connections
   - Implement connection pooling
   - Use read-only credentials where possible

3. **Monitoring**
   - Set up alerts for authentication failures
   - Monitor connection pool exhaustion
   - Track credential rotation schedule

## Exit Criteria Validation

The GA-Hardening exit criteria are met when:

✅ All containers report healthy status
✅ Zero authentication failures in logs
✅ Redis accepts authenticated connections
✅ PostgreSQL accepts authenticated connections
✅ All services can read/write data

Run the full validation:
```bash
./scripts/verify-no-auth-failures.sh && echo "✅ Exit criteria MET"
```
