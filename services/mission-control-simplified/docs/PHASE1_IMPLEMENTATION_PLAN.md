# Phase 1 Implementation Plan: Proxy Service

## Overview

This document outlines the implementation plan for Phase 1 of the Niche-Scout ↔ Social-Intel Integration project. Phase 1 focuses on moving the client-side transformation logic to a dedicated proxy service that sits between the Mission Control frontend and the Social Intelligence API.

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐
│             │     │              │     │                 │
│  Frontend   │────▶│  Proxy       │────▶│  Social Intel   │
│  (Mission   │     │  Service     │     │  API            │
│  Control)   │◀────│              │◀────│                 │
│             │     │              │     │                 │
└─────────────┘     └──────────────┘     └─────────────────┘
```

## Implementation Steps

### 1. Create Proxy Service

#### 1.1 Setup Proxy Service Project

- Create a new directory `proxy-service` in the main repository
- Initialize a Node.js project with Express and required dependencies
- Set up Docker configuration for the service
- Configure environment variables for connections to Social Intel API

#### 1.2 Extract Transformation Logic

Extract and refactor the following core functions from `integrate-with-social-intel.js`:

- `stringSimilarity` and related algorithms (Levenshtein, Jaccard, Jaro-Winkler)
- `getMockNichesForCategory`
- `getTopicsForNiche`
- `logTransformationMetrics` (modify to use Prometheus instead of localStorage)
- `calculateRelevanceMetrics`

#### 1.3 Implement API Endpoints

Create the following endpoints in the proxy service:

- `GET /status` - Health check endpoint
- `POST /api/youtube/niche-scout` - Main transformation endpoint that handles requests to Social Intel
- `GET /metrics` - Prometheus metrics endpoint
- `POST /config` - Dynamic configuration endpoint

### 2. Implement Data Storage

#### 2.1 Redis Integration

- Set up Redis connection for caching and storing configuration
- Store category lists in Redis with version tracking
- Implement cache invalidation strategy

#### 2.2 Prometheus Metrics

Replace `localStorage` metrics with the following Prometheus metrics:

- `proxy_transform_duration_ms` (Histogram)
- `proxy_relevance_score` (Gauge)
- `proxy_relevant_niche_count` (Gauge)
- `proxy_match_types` (Counter with labels)

### 3. Update Mission Control

#### 3.1 Frontend Changes

- Update API endpoint URLs to point to proxy service
- Add configuration for feature flag to control traffic between client-side and proxy
- Update debug panel to show proxy metrics and configuration

#### 3.2 Backend Changes

- Modify server.js to optionally forward requests to proxy service
- Implement feature flag mechanism

### 4. Docker Integration

- Update docker-compose.yml to include the proxy service
- Configure networking between services
- Set up volume mounting for configuration files

## Configuration Options

The proxy service should expose the following configuration options:

- `SIMILARITY_THRESHOLD` - Default: 0.55
- `DEFAULT_NICHE_COUNT` - Default: 5
- `ALGORITHM_WEIGHTS` - Default: Levenshtein (0.5), Jaccard (0.3), Jaro-Winkler (0.2)
- `CACHE_TTL` - Default: 3600 seconds (1 hour)
- `FEATURE_FLAG_PROXY_ENABLED` - Default: true

## Testing Plan

### Unit Tests

- Port existing transformation tests to the proxy service
- Add new tests for Redis integration and Prometheus metrics

### Integration Tests

- Test end-to-end flow from frontend through proxy to Social Intel API
- Test caching behavior and performance
- Test feature flag behavior

### Load Tests

- Benchmark proxy service under various load conditions
- Test cache hit ratios and performance improvements

## Rollout Strategy

1. **Development Phase**
   - Implement proxy service with full functionality
   - Run alongside client-side transformation with 0% traffic

2. **Testing Phase**
   - Gradually increase traffic to proxy service (10% → 25% → 50%)
   - Monitor metrics and performance
   - Address any issues or discrepancies

3. **Full Rollout**
   - Switch to 100% proxy service traffic
   - Deprecate client-side transformation
   - Document changes for team

## Appendix: Proxy Service Directory Structure

```
proxy-service/
├── Dockerfile
├── docker-compose.yml
├── .env.example
├── package.json
├── README.md
├── src/
│   ├── index.js                 # Main application entry point
│   ├── config.js                # Configuration management
│   ├── routes/
│   │   ├── index.js             # Route definitions
│   │   ├── api.js               # API endpoints
│   │   └── metrics.js           # Prometheus metrics endpoint
│   ├── services/
│   │   ├── socialIntel.js       # Social Intel API client
│   │   ├── redis.js             # Redis client and operations
│   │   └── metrics.js           # Prometheus metrics collection
│   ├── transformers/
│   │   ├── nicheScout.js        # Main transformation logic
│   │   ├── similarity.js        # String similarity algorithms
│   │   ├── topics.js            # Topic generation
│   │   └── metrics.js           # Metrics calculation
│   └── utils/
│       ├── cache.js             # Caching utilities
│       ├── validation.js        # Input validation
│       └── logger.js            # Logging configuration
└── tests/
    ├── unit/                    # Unit tests
    ├── integration/             # Integration tests
    └── load/                    # Load tests
```

## Timeline

- **Week 1**: Setup proxy service and extract transformation logic
- **Week 2**: Implement data storage and metrics collection
- **Week 3**: Testing and integration with Mission Control
- **Week 4**: Rollout and monitoring

## Success Metrics

- Reduced frontend load (transformation time moved to backend)
- Improved caching and response times (target: 50% reduction in average response time)
- Consistent relevance scores between Phase 0 and Phase 1 implementations
- Zero regression in user experience
- Prometheus metrics available for monitoring
- Ability to dynamically update configuration without redeployment