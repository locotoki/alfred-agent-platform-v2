# Alfred Platform - Environment Quick Setup Guide

This guide will help you quickly set up the environment for running the Alfred Agent Platform v2 using Docker Compose.

## Prerequisites

- Docker and Docker Compose v2 installed
- At least 8GB RAM available
- Ports available: 5432, 6379, 8011, 8080, 3005, 9090 (and others)

## Step 1: Create .env File

The platform requires several environment variables. Here's a minimal working configuration:

```bash
# Copy the example file
cp .env.example .env
```

## Step 2: Set Required Environment Variables

Edit your `.env` file with these minimal required values:

```bash
# Critical Database Password - MUST CHANGE THIS!
POSTGRES_PASSWORD=your-secure-password-here
DB_PASSWORD=your-secure-password-here

# Redis Password 
REDIS_PASSWORD=your-redis-password-here

# Slack Configuration (set these if using Slack integration)
SLACK_SIGNING_SECRET=your-slack-signing-secret
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token
SLACK_APP_TOKEN=xapp-your-slack-app-token

# Add these missing critical variables:
DATABASE_URL=postgresql://postgres:your-secure-password-here@db-postgres:5432/postgres
ALFRED_DATABASE_URL=postgresql://postgres:your-secure-password-here@db-postgres:5432/postgres
REDIS_URL=redis://:your-redis-password-here@redis:6379
ALFRED_REDIS_URL=redis://:your-redis-password-here@redis:6379

# Basic Alfred Settings
ALFRED_ENVIRONMENT=development
ALFRED_DEBUG=true
ALFRED_LOG_LEVEL=INFO
ALFRED_PROJECT_ID=alfred-agent-platform

# Model/AI Settings (use mock keys for local dev)
ALFRED_OPENAI_API_KEY=sk-mock-key-for-development-only
ALFRED_MODEL_ROUTER_URL=http://model-router:8080

# Service URLs
SOCIAL_INTEL_URL=http://agent-social:9000
ALFRED_RAG_URL=http://agent-rag:8501

# Supabase/Auth Settings
DB_JWT_SECRET=your-super-secret-jwt-token
JWT_SECRET=your-jwt-secret-key
ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImV4cCI6MTc0OTUzNjEzMH0.zcPCLGlqF3YHBP-gTlXOQ2zjV-h3VmxbThiYEg2I5io
SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiZXhwIjoxNzQ5NTM2MTMwfQ.EDf3DT0Zl6qQbrLIQLwAXRWAN5kaJ5mvlAh1jm0CY-o

# Monitoring
MONITORING_ADMIN_PASSWORD=admin
```

## Step 3: Create Docker Network

```bash
docker network create alfred-network
```

## Step 4: Start Core Services

### Option A: Use Bootstrap Script (Recommended)

```bash
# Start core services only
./scripts/bootstrap-dev.sh

# Or start all services including extras
./scripts/bootstrap-dev.sh --profile extras
```

### Option B: Manual Docker Compose

```bash
# Start all services
docker-compose up -d

# Or start specific services
docker-compose up -d redis db-postgres agent-core monitoring-metrics monitoring-dashboard
```

## Step 5: Initialize Database

After services start, create the required PostgreSQL role:

```bash
# Create anon role for db-api
docker exec -i db-postgres psql -U postgres << 'EOF'
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon NOLOGIN;
    END IF;
END $$;
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO anon;
EOF
```

## Step 6: Verify Services

Check service health:

```bash
# Check all services
docker-compose ps

# Check specific service logs
docker-compose logs -f agent-core

# Run health check script
./scripts/check-core-health.sh
```

## Service Access Points

Once running, you can access:

- **PostgreSQL**: `localhost:5432` (user: postgres, password: from POSTGRES_PASSWORD)
- **Redis**: `localhost:6379` (password: from REDIS_PASSWORD)
- **Agent Core API**: http://localhost:8011/health
- **Model Router**: http://localhost:8080/health
- **Grafana**: http://localhost:3005 (admin/admin)
- **Prometheus**: http://localhost:9090
- **UI Chat**: http://localhost:8502
- **UI Admin**: http://localhost:3007

## Troubleshooting

### Common Issues

1. **db-storage unhealthy**: This service has issues with the base postgres image. It's not critical for basic operation.

2. **Port conflicts**: If you get port binding errors, check what's using the ports:
   ```bash
   sudo lsof -i :5432  # Check PostgreSQL port
   sudo lsof -i :6379  # Check Redis port
   ```

3. **Service won't start**: Check logs:
   ```bash
   docker-compose logs service-name
   ```

4. **Database connection issues**: Ensure POSTGRES_PASSWORD matches in all DATABASE_URL variables.

### Minimal Service Set

For a minimal working setup, you only need:
- redis
- db-postgres
- db-api
- pubsub-emulator
- monitoring-metrics
- monitoring-dashboard

Start just these with:
```bash
docker-compose up -d redis db-postgres db-api pubsub-emulator monitoring-metrics monitoring-dashboard
```

## Next Steps

1. Once services are healthy, you can start adding agents:
   ```bash
   docker-compose up -d agent-core agent-rag agent-social
   ```

2. Enable UI services:
   ```bash
   docker-compose up -d ui-chat ui-admin
   ```

3. For production, update the passwords and tokens with secure values.

## Quick Commands Reference

```bash
# Start everything
docker-compose up -d

# Stop everything
docker-compose down

# View logs
docker-compose logs -f [service-name]

# Restart a service
docker-compose restart [service-name]

# Check service health
docker-compose ps

# Clean everything (including data)
docker-compose down -v
```