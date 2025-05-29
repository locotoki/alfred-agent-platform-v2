# Port Allocation Guide

## Overview

This document lists all network ports used by Alfred Agent Platform services in different environments.

## Development Ports

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| alfred-core | 8080 | HTTP | Main API endpoint |
| model-registry | 8081 | HTTP | Model registry API |
| model-router | 8082 | HTTP | Model routing service |
| slack-adapter | 8083 | HTTP | Slack webhook receiver |
| slack-mcp-gateway | 8084 | WebSocket | Slack MCP gateway |
| agent-orchestrator | 8085 | HTTP | Agent orchestration API |
| social-intel | 8086 | HTTP | Social intelligence API |
| ui-chat | 8501 | HTTP | Streamlit chat UI |
| mission-control | 3000 | HTTP | Next.js mission control |
| mission-control-simplified | 3001 | HTTP | Simplified mission control |
| db-postgres | 5432 | PostgreSQL | Main database |
| db-storage | 5433 | HTTP | Supabase storage API |
| db-auth | 5434 | HTTP | Supabase auth API (GoTrue) |
| redis | 6379 | Redis | Cache and pub/sub |
| prometheus | 9090 | HTTP | Metrics collection |
| grafana | 3000 | HTTP | Metrics visualization |
| db-exporter | 9187 | HTTP | PostgreSQL metrics |
| redis-exporter | 9121 | HTTP | Redis metrics |

## Production Ports (External)

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| HTTP | 80 | HTTP | Redirects to HTTPS |
| HTTPS | 443 | HTTPS | All external traffic |

## Production URLs (via Ingress)

| Service | URL | Description |
|---------|-----|-------------|
| API | https://api.alfred.example.com | Main API endpoint |
| Chat UI | https://chat.alfred.example.com | User chat interface |
| Mission Control | https://mission.alfred.example.com | Admin dashboard |
| Grafana | https://grafana.alfred.example.com | Metrics dashboard |
| Prometheus | https://prometheus.alfred.example.com | Metrics API (auth required) |
| Traefik | https://traefik.alfred.example.com | Ingress dashboard (auth required) |

## Internal Service Discovery

In production, services communicate using internal DNS names:

| Service | Internal URL | Port |
|---------|--------------|------|
| alfred-core | http://alfred-core:8080 | 8080 |
| model-registry | http://model-registry:8081 | 8081 |
| model-router | http://model-router:8082 | 8082 |
| db-postgres | postgresql://db-postgres:5432 | 5432 |
| redis | redis://redis:6379 | 6379 |

## Load Balancer Configuration

Production uses Traefik/Nginx as reverse proxy:

```yaml
# Traefik entrypoints
- web: :80 (HTTP)
- websecure: :443 (HTTPS)

# Rate limiting
- API: 100 req/s
- UI: 50 req/s
```

## Firewall Rules

### Ingress (Allow)
- 80/tcp from 0.0.0.0/0 (HTTP)
- 443/tcp from 0.0.0.0/0 (HTTPS)
- 22/tcp from bastion only (SSH)

### Egress (Allow)
- 443/tcp to 0.0.0.0/0 (HTTPS APIs)
- 53/udp to DNS servers
- 123/udp to NTP servers

### Internal (Allow)
- All traffic between services in same namespace
- Prometheus scraping on /metrics endpoints

## Health Check Endpoints

All services expose health checks on their primary port:

| Pattern | Example |
|---------|---------|
| /health | http://alfred-core:8080/health |
| /healthz | http://model-registry:8081/healthz |
| /api/health | http://grafana:3000/api/health |

## Debugging Port Issues

```bash
# Check port usage
netstat -tlnp | grep <port>
lsof -i :<port>

# Test connectivity
nc -zv <host> <port>
curl -v http://<host>:<port>/health

# Docker compose
docker-compose ps --services --filter "status=running"
docker-compose port <service> <port>

# Kubernetes
kubectl get svc -n alfred-prod
kubectl port-forward svc/<service> <local>:<remote>
```

## Port Conflicts

Known conflicts and resolutions:

1. **Grafana vs Mission Control (3000)**
   - Development: Grafana uses 3000, Mission Control uses 3001
   - Production: Both behind reverse proxy on different domains

2. **Database Services**
   - Separated by incrementing ports: 5432, 5433, 5434
   - Use connection pooling in production

## Future Considerations

- Service mesh (Istio/Linkerd) may change internal routing
- Consider using Unix sockets for same-host communication
- Implement port management via service discovery
