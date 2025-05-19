# Niche-Scout Proxy Service

This service sits between the Mission Control frontend and the Social Intelligence API, providing transformation, caching, and metrics collection for the Niche-Scout workflow.

## Features

- **API Proxy**: Forwards requests to the Social Intelligence API
- **Smart Transformation**: Ensures search relevance by transforming API responses
- **Redis Caching**: Improves performance with configurable caching
- **Prometheus Metrics**: Comprehensive metrics for monitoring
- **Dynamic Configuration**: Update configuration without restarting the service

## Getting Started

### Prerequisites

- Node.js 14+
- Redis
- Docker and Docker Compose (optional)

### Installation

1. Clone the repository
2. Install dependencies:
   ```
   npm install
   ```
3. Copy the environment file and configure it:
   ```
   cp .env.example .env
   ```
4. Start the service:
   ```
   npm start
   ```

### Docker Setup

To run the service with Docker Compose:

```
docker-compose up -d
```

This will start:
- The proxy service
- Redis for caching
- Prometheus for metrics
- Grafana for dashboards

## API Endpoints

- `GET /status` - Health check endpoint
- `POST /api/youtube/niche-scout` - Main transformation endpoint
- `GET /metrics` - Prometheus metrics endpoint
- `GET /config` - Get current configuration
- `POST /config` - Update configuration

## Configuration

The service can be configured through environment variables or the `/config` endpoint:

- `SIMILARITY_THRESHOLD`: Threshold for string similarity (default: 0.55)
- `DEFAULT_NICHE_COUNT`: Number of niches to return (default: 5)
- `ALGORITHM_WEIGHTS`: Weights for similarity algorithms
- `CACHE_ENABLED`: Enable/disable caching (default: true)
- `CACHE_TTL`: Cache time-to-live in seconds (default: 3600)
- `FEATURE_FLAG_PROXY_ENABLED`: Enable/disable proxy transformation (default: true)

## Metrics

The service exposes the following Prometheus metrics:

- `proxy_transform_duration_ms`: Histogram of transformation duration
- `proxy_relevance_score`: Gauge of relevance score for transformations
- `proxy_relevant_niche_count`: Gauge of relevant niches count
- `proxy_match_types`: Counter for match types (exact, partial, category, none)
- `proxy_cache_hit_ratio`: Gauge of cache hit ratio
- `proxy_api_response_time_ms`: Histogram of Social Intelligence API response time
- `proxy_total_requests`: Counter of total requests by endpoint and status

## Development

### Running in Development Mode

```
npm run dev
```

### Running Tests

```
npm test
npm run test:unit
npm run test:integration
```

### Running Load Tests

```
npm run test:load
```
