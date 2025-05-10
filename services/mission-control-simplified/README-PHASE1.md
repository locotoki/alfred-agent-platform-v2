# Mission Control Simplified: Phase 1 Implementation

This document provides instructions for running the Phase 1 implementation, which includes the proxy service for the Niche-Scout ↔ Social-Intel Integration.

## Components

- **Mission Control**: The existing application
- **Proxy Service**: A new service that sits between Mission Control and the Social Intelligence API
- **Redis**: For caching and configuration persistence
- **Prometheus**: For metrics collection and monitoring

## Running the Implementation

### Prerequisites

- Node.js 14+
- Docker and Docker Compose (recommended)
- Redis (automatically included in Docker setup)

### Using Docker Compose (Recommended)

1. Start the entire stack:

```bash
cd /home/locotoki/projects/alfred-agent-platform-v2/services/mission-control-simplified
docker-compose up -d
```

This will start:
- Mission Control (port 3007)
- Proxy Service (port 3020)
- Redis (port 6379)
- Prometheus (port 9090)

### Manual Setup

1. Start Redis:

```bash
docker run -d -p 6379:6379 --name niche-scout-redis redis:alpine
```

2. Start the Proxy Service:

```bash
cd /home/locotoki/projects/alfred-agent-platform-v2/services/mission-control-simplified/proxy-service
cp .env.example .env  # Edit as needed
npm install
npm start
```

3. Start Mission Control:

```bash
cd /home/locotoki/projects/alfred-agent-platform-v2/services/mission-control-simplified
# Update server.js with the new server.js.new file
cp server.js.new server.js
# Update HTML to include proxy support
echo '<script src="/niche-scout-update.js"></script>' >> public/niche-scout.html
npm start
```

## Configuration

### Environment Variables

#### Mission Control

- `PORT`: Default 3007
- `SOCIAL_INTEL_HOST`: Social Intelligence API host
- `SOCIAL_INTEL_PORT`: Social Intelligence API port
- `PROXY_SERVICE_URL`: URL of the proxy service
- `ENABLE_PROXY`: Whether to enable proxy routing
- `PROXY_TRAFFIC_PERCENTAGE`: Percentage of traffic to route through the proxy

#### Proxy Service

- `PORT`: Default 3020
- `SOCIAL_INTEL_HOST`: Social Intelligence API host
- `SOCIAL_INTEL_PORT`: Social Intelligence API port
- `SIMILARITY_THRESHOLD`: Threshold for string similarity
- `DEFAULT_NICHE_COUNT`: Number of niches to return
- `WEIGHT_LEVENSHTEIN`: Weight for Levenshtein algorithm
- `WEIGHT_JACCARD`: Weight for Jaccard algorithm
- `WEIGHT_JARO_WINKLER`: Weight for Jaro-Winkler algorithm
- `CACHE_ENABLED`: Whether to enable caching
- `CACHE_TTL`: Cache time-to-live in seconds
- `REDIS_HOST`: Redis host
- `REDIS_PORT`: Redis port

## URLs

- Mission Control: http://localhost:3007
- Niche-Scout UI: http://localhost:3007/workflows/niche-scout
- Proxy Service: http://localhost:3020
- Prometheus: http://localhost:9090

## Testing

### Unit Tests

```bash
cd /home/locotoki/projects/alfred-agent-platform-v2/services/mission-control-simplified/proxy-service
npm test
```

### Manual Testing

1. Open http://localhost:3007/workflows/niche-scout
2. Click the "Debug" tab
3. Open the debug panel using the "Show Metrics Panel" button
4. Check the "Enable" checkbox in the "Proxy Routing" section
5. Run a Niche-Scout search
6. Observe that the request is routed through the proxy service

You can also use the "Proxy Config" tab to view and adjust the proxy service configuration.

## Monitoring

### Prometheus

Open http://localhost:9090 to view metrics from the proxy service.

Available metrics:
- `proxy_transform_duration_ms`
- `proxy_relevance_score`
- `proxy_relevant_niche_count`
- `proxy_match_types`
- `proxy_cache_hit_ratio`
- `proxy_api_response_time_ms`
- `proxy_total_requests`

## Deploying to Production

To deploy this implementation to production:

1. Review and adjust the Docker Compose file for production settings
2. Set appropriate environment variables
3. Configure a reverse proxy (e.g., Nginx) in front of the services
4. Set up proper monitoring and alerting
5. Configure a production-grade Redis instance with persistence

## Troubleshooting

- **Proxy Service Not Starting**: Check Redis connection and environment variables
- **Proxy Not Working**: Check proxy service logs and ensure `ENABLE_PROXY` is set to true
- **Slow Performance**: Check Redis connection and cache hit ratio
- **No Metrics**: Ensure Prometheus is running and the proxy service is configured correctly

## Documentation

For more information, see:
- [PHASE1_IMPLEMENTATION_PLAN.md](/docs/PHASE1_IMPLEMENTATION_PLAN.md)
- [PHASE1_IMPLEMENTATION_SUMMARY.md](/docs/PHASE1_IMPLEMENTATION_SUMMARY.md)
- [README-PIPELINE.md](/docs/README-PIPELINE.md)