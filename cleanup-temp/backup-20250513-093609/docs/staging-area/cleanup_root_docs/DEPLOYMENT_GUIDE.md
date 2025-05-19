# Alfred Agent Platform v2 - Deployment Guide

This document provides comprehensive guidance for deploying and maintaining the Alfred Agent Platform v2 environment.

## Prerequisites

- Docker Engine 25.0+
- Docker Compose v2
- Bash shell environment
- 4GB+ RAM available
- 10GB+ disk space

## Quick Deployment

### Development Environment

For local development with authentication disabled (recommended for development only):

```bash
# Start all services with our production-ready script
./start-production.sh

# Or start specific components
./start-production.sh --core-only      # Core infrastructure only
./start-production.sh --with-atlas     # Core + Atlas services
```

### Production Environment

For production deployment with proper authentication (TODO):

```bash
# In the future, use:
# ./start-prod-secure.sh
```

## Manual Deployment Steps

If you prefer to understand and control each step, follow this process:

1. **Create Docker Network**:
   ```bash
   docker network create alfred-network
   ```

2. **Launch Core Services**:
   ```bash
   docker-compose -f docker-compose.combined-fixed.yml up -d supabase-db redis qdrant pubsub-emulator
   ```

3. **Configure Supabase**:
   ```bash
   ./setup-supabase-fixed.sh
   ./disable-auth.sh  # For development only
   ```

4. **Launch Platform Services**:
   ```bash
   docker-compose -f docker-compose.combined-fixed.yml -f docker-compose.atlas-fix.yml up -d rag-gateway atlas
   ```

5. **Launch Agent Services**:
   ```bash
   docker-compose -f docker-compose.combined-fixed.yml up -d alfred-bot social-intel financial-tax legal-compliance
   ```

6. **Launch Monitoring**:
   ```bash
   docker-compose -f docker-compose.combined-fixed.yml up -d prometheus grafana node-exporter postgres-exporter
   ```

## Verifying Deployment

Run the verification script to check if all services are working correctly:

```bash
./verify-platform.sh
```

This will check:
- All container health status
- Health endpoints
- Network connectivity between services
- Database persistence

## Component Architecture

The platform consists of several service groups:

1. **Core Infrastructure**:
   - **Supabase**: PostgreSQL database, REST API, Authentication
   - **Redis**: In-memory cache
   - **Qdrant**: Vector database for embeddings
   - **PubSub Emulator**: Message queue for service communication

2. **Atlas Services**:
   - **RAG Gateway**: Vector search and retrieval API
   - **Atlas**: Main worker service for AI processing

3. **Agent Services**:
   - **Alfred Bot**: Main assistant agent
   - **Social Intel**: Social media intelligence agent
   - **Financial Tax**: Financial and tax intelligence agent
   - **Legal Compliance**: Legal and compliance intelligence agent

4. **Monitoring**:
   - **Prometheus**: Metrics collection
   - **Grafana**: Visualization and dashboards

## Configuration

### Docker Compose Files

The platform uses several Docker Compose files, combined for different purposes:

- `docker-compose.combined-fixed.yml`: Main configuration with all services
- `docker-compose.supabase-config.yml`: Supabase-specific configuration
- `docker-compose.atlas-fix.yml`: Atlas health endpoint fix

### Environment Variables

Key environment variables are defined in `.env`:

- `JWT_SECRET`: Secret for JWT token generation
- `SERVICE_ROLE_KEY`: Key for service role authentication
- `SUPABASE_URL`: Internal URL for Supabase REST API
- `RAG_URL`: URL for RAG Gateway
- `RAG_API_KEY`: API key for RAG Gateway access

### Database Schema

The platform uses several database tables in Supabase:

1. **Atlas Tables**:
   - `architect_in`: Input queue for Atlas
   - `architect_out`: Output from Atlas processing

2. **Agent Tables**:
   - `alfred_bot_tasks`: Tasks for Alfred Bot
   - `social_intel_analysis`: Analysis data for Social Intelligence
   - `financial_tax_records`: Records for Financial Tax agent
   - `legal_compliance_checks`: Compliance data for Legal agent

## Health Monitoring

All services implement standard health endpoints:

- `/healthz`: Simple health check (returns 200 OK)
- `/health`: Detailed health status with service checks

These can be used for:
- Kubernetes probes
- Load balancer checks
- Monitoring alerts

## Troubleshooting

### Common Issues

1. **Supabase Authentication Issues**:
   - Run `./disable-auth.sh` to disable authentication (development)
   - Check JWT token configuration in `.env`

2. **Atlas Showing Unhealthy**:
   - Run `./apply-health-fix.sh` to fix the health endpoint
   - Restart the Atlas container

3. **Network Connectivity Issues**:
   - Ensure `alfred-network` exists: `docker network inspect alfred-network`
   - Check container logs: `docker logs alfred-agent-platform-v2-[service-name]`

4. **Container Not Starting**:
   - Check for port conflicts: `netstat -tuln`
   - Check container logs: `docker logs alfred-agent-platform-v2-[service-name]`

### Advanced Troubleshooting

For more complex issues:

1. **Database Issues**:
   - Check Supabase DB logs: `docker logs alfred-agent-platform-v2-supabase-db-1`
   - Verify table schemas: `docker exec -it alfred-agent-platform-v2-supabase-db-1 psql -U postgres -d postgres -c "\dt"`

2. **Service Communication**:
   - Test direct communication: `docker exec alfred-agent-platform-v2-atlas-1 curl -s http://rag-gateway:8501/healthz`
   - Verify environment variables: `docker exec alfred-agent-platform-v2-atlas-1 env | grep SUPABASE`

## Security Considerations

For production deployments:

1. **Authentication**:
   - Enable Row Level Security (RLS) in Supabase
   - Configure proper JWT authentication
   - Use secure API keys for service-to-service communication

2. **Network Security**:
   - Consider using Docker network isolation
   - Implement proper firewall rules
   - Use TLS for external communication

3. **Secrets Management**:
   - Use Docker secrets or environment variables
   - Rotate JWT keys regularly
   - Implement access control for sensitive operations

## Additional Resources

- **QUICKSTART.md**: Quick reference guide
- **CURRENT_STATE.md**: Current platform state
- **SUPABASE_STATUS.md**: Supabase authentication details
- **CHANGELOG.md**: History of changes and updates
