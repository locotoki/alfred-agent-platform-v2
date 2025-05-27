# Alfred Platform Run-Book

## Overview

This run-book provides operational procedures for the Alfred Agent Platform v2.

## System Components

- **Alfred Core**: Main orchestration service
- **Model Router**: LLM routing and load balancing
- **Agent Services**: Domain-specific agent implementations
- **Storage Layer**: PostgreSQL and Redis
- **Monitoring Stack**: Prometheus, Grafana, and custom metrics

## Common Operations

### Starting the Platform

```bash
docker-compose up -d
```

### Checking Service Health

```bash
# Check all services
docker-compose ps

# Check specific service logs
docker-compose logs -f alfred-core
```

### Troubleshooting

#### Service Won't Start
1. Check logs: `docker-compose logs <service-name>`
2. Verify environment variables are set
3. Ensure ports are not already in use
4. Check Docker resource limits

#### Database Connection Issues
1. Verify PostgreSQL is running: `docker-compose ps db-postgres`
2. Check connection string in environment
3. Ensure migrations have run

#### Memory Issues
1. Monitor with: `docker stats`
2. Check memory limits in docker-compose.yml
3. Review memory leak workflow results

## Emergency Procedures

### Service Restart
```bash
docker-compose restart <service-name>
```

### Full Platform Restart
```bash
docker-compose down
docker-compose up -d
```

### Data Backup
See backup procedures in `docs/deployment/deployment-guide.md`

## Monitoring and Alerts

- Grafana dashboards: http://localhost:3000
- Prometheus metrics: http://localhost:9090
- Alert rules defined in `monitoring/prometheus/alerts.yml`

## Contact Information

- On-call rotation: See internal wiki
- Escalation: Platform team lead
- Security incidents: security@example.com

> **Note**: This is a living document. Update as procedures change.
