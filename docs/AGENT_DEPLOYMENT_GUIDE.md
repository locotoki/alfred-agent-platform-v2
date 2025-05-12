# Agent Deployment Guide

This guide provides a standardized approach for deploying and updating agents in the Alfred Agent Platform v2 ecosystem, based on lessons learned from the Atlas deployment.

## 1. Pre-Deployment Checklist

- [ ] Agent code complete and tested locally
- [ ] Required environment variables documented
- [ ] Service dependencies identified and configured
- [ ] Database tables and schemas defined
- [ ] Docker image built and tested
- [ ] Health check endpoints implemented
- [ ] Metrics collection configured
- [ ] Error handling strategy defined

## 2. Containerization Standards

### Docker Image Requirements

- Base images should use specific version tags (not `latest`)
- Use multi-stage builds to minimize image size
- Include health checks
- Create non-root user for security
- Expose metrics on a consistent port (8000)
- Make logs available on STDOUT/STDERR

### Example `Dockerfile`

```dockerfile
FROM python:3.11-slim as builder

WORKDIR /app
COPY pyproject.toml poetry.lock ./
RUN pip install poetry && \
    poetry config virtualenvs.create false && \
    poetry install --no-dev --no-interaction

FROM python:3.11-slim
WORKDIR /app

# Create non-root user
RUN adduser --disabled-password --gecos "" appuser

# Copy only dependencies from builder
COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Copy application code
COPY . .

# Use non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:8000/healthz || exit 1

# Default environment variables
ENV LOG_LEVEL=INFO \
    PROMETHEUS_PORT=8000

EXPOSE 8000

CMD ["python", "-m", "agent.main"]
```

## 3. Database Integration

### Supabase Setup

1. Create tables before deployment
2. Use the `scripts/setup_agent_tables.sh` template to automate table creation
3. Always include Row Level Security (RLS) policies
4. Test read/write access with the service role key

### Table Creation Template

Create a setup script like `scripts/setup_AGENT_tables.sh`:

```bash
#!/usr/bin/env bash
set -e

# Load environment variables
source .env.dev

# Create table
curl -s -X POST \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "AGENT_table", "columns": [{"name": "id", "type": "uuid", "primary": true}, {"name": "data", "type": "jsonb"}]}' \
  "${SUPABASE_URL}/rest/v1/rpc/create_table_if_not_exists"

# Create RLS policies
curl -s -X POST \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d '{"table": "AGENT_table", "name": "service_role_all", "definition": "true", "action": "ALL", "role": "service_role"}' \
  "${SUPABASE_URL}/rest/v1/rpc/create_policy_if_not_exists"
```

## 4. Docker Compose Configuration

### Service Configuration Template

```yaml
agent-service:
  image: agent-service:latest
  env_file: .env.dev
  environment:
    # Connect to services via Docker network using service names
    SUPABASE_URL: http://supabase-rest:3000
    # Additional environment variables here
  ports: [8000:8000]  # Expose metrics port
  depends_on:
    - supabase-rest
    - pubsub-emulator
    - redis
    # Add other dependencies
  restart: unless-stopped
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/healthz"]
    interval: 30s
    timeout: 5s
    retries: 3
```

## 5. Message Bus Integration

### Pub/Sub Standards

1. Follow topic naming conventions: `{agent_name}_in` and `{agent_name}_out`
2. Use structured message format:
   ```json
   {
     "task_id": "uuid4",
     "role": "agent_name",
     "msg_type": "request_type",
     "content": "Message content",
     "metadata": {
       "parent_id": null,
       "schema_ver": 1
     }
   }
   ```
3. Implement acknowledgment only after successful processing
4. Include retry logic for transient failures

### Test Script Template

Create a script like `scripts/test_AGENT_pubsub.sh`:

```bash
#!/usr/bin/env bash
set -e

# Create the message JSON
MSG="{\"role\":\"AGENT\",\"msg_type\":\"request\",\"content\":\"$1\",\"metadata\":{}}"
BASE64_MSG=$(echo -n "$MSG" | base64 | tr -d '\n')

# Send to Pub/Sub emulator
curl -X POST "http://localhost:8681/v1/projects/alfred-agent-platform/topics/AGENT_in:publish" \
  -H "Content-Type: application/json" \
  -d "{\"messages\":[{\"data\":\"$BASE64_MSG\"}]}"

echo "Message sent to AGENT_in topic"
```

## 6. Monitoring and Observability

### Metrics Standards

1. Every agent should expose the following metrics:
   - `{agent}_request_count`: Counter of requests processed
   - `{agent}_processing_seconds`: Histogram of processing time
   - `{agent}_error_count`: Counter of errors encountered
   - `{agent}_health`: Gauge indicating health status (0/1)

2. Create a Prometheus endpoint at `/metrics`

3. Implement the following health checks:
   - Database connectivity
   - Required API services
   - Pub/Sub connectivity

### Logging Standards

1. Use structured JSON logging
2. Include consistent fields:
   - `timestamp`
   - `level`
   - `service`
   - `request_id`
   - `message`
   - `context` (with relevant data)

## 7. Deployment Process

### New Agent Deployment

1. Update `.env.dev` with required variables
2. Run database setup script: `./scripts/setup_AGENT_tables.sh`
3. Build Docker image: `docker build -t AGENT-service ./services/AGENT`
4. Update `docker-compose.dev.yml` with the new service
5. Start services: `docker-compose -f docker-compose.dev.yml up -d`
6. Verify health: `curl http://localhost:8000/healthz`
7. Send test message: `./scripts/test_AGENT_pubsub.sh "Test message"`

### Agent Updates

1. Update code in `services/AGENT/`
2. Rebuild image: `docker build -t AGENT-service ./services/AGENT`
3. Restart service: `docker-compose -f docker-compose.dev.yml up -d --no-deps AGENT-service`
4. Verify metrics to confirm service is operational

## 8. Common Issues and Solutions

### Database Connectivity

**Issue**: 404 Not Found when connecting to Supabase
**Solution**: 
- Verify tables exist - run `./scripts/setup_AGENT_tables.sh`
- Check service role key has appropriate permissions

### Message Bus Connectivity

**Issue**: Messages not being processed
**Solution**:
- Ensure Pub/Sub emulator is running
- Verify topic exists
- Check PUBSUB_EMULATOR_HOST environment variable

### Docker Networking

**Issue**: Services can't connect to each other
**Solution**:
- Use service names as hostnames (e.g., `http://supabase-rest:3000`)
- Ensure all services are on the same Docker network
- Check the `depends_on` configuration is correct

### Authentication Issues

**Issue**: 401/403 errors when accessing Supabase
**Solution**:
- Verify service role key is valid and not expired
- Check RLS policies are correctly configured
- Ensure headers are properly formatted

## 9. Testing Framework

Create standardized test scripts for every agent:

1. `test_AGENT_health.sh` - Verify health endpoints
2. `test_AGENT_metrics.sh` - Verify metrics exposed
3. `test_AGENT_pubsub.sh` - Test Pub/Sub integration
4. `test_AGENT_db.sh` - Test database connectivity and operations

## 10. Documentation Requirements

Each agent should have:

1. `README.md` with:
   - Overview
   - Features
   - Configuration
   - API descriptions
   - Dependencies
   - Quick start

2. `TROUBLESHOOTING.md` with:
   - Common issues
   - Logs to check
   - Resolution steps

3. `architecture.md` with:
   - Component diagram
   - Data flow
   - Integration points

## Conclusion

Following these standards will ensure consistent, reliable deployment of agents within the Alfred Agent Platform ecosystem. This approach addresses the common issues encountered during the Atlas deployment and provides a streamlined path for future agent integrations.