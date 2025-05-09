# Social Intelligence Service (v1.0.0)

The Social Intelligence service provides niche analysis, YouTube trend monitoring, and content strategy generation through a REST API. 

**Current Status**: ✅ Phase 2 Complete, Production Ready

## Features

- **Niche Scout**: Identifies high-potential YouTube niches with opportunity scoring
- **Seed to Blueprint**: Generates channel strategy blueprints from seed videos
- **Workflow Management**: Schedule and manage analysis workflows
- **Persistence**: PostgreSQL storage with materialized views for fast access
- **Metrics**: Prometheus metrics with optimized latency buckets for monitoring
- **Documentation**: OpenAPI specification with interactive Swagger UI
- **Testing**: Comprehensive unit, integration, and load testing with k6
- **Monitoring**: Prometheus alerts for latency, error rates, and data quality

## Getting Started

### Prerequisites

- Docker and Docker Compose
- Node.js 14+ (for running the scoring script locally)
- PostgreSQL client (for manual database operations)

### Configuration

Configure the service through environment variables:

```bash
# Create a .env file with your configuration
cp .env.example .env

# Edit the .env file with your settings
# Required variables:
# - DATABASE_URL
# - YOUTUBE_API_KEY (optional but recommended)
```

### Running with Docker

```bash
# Start the service and its dependencies
docker compose up -d

# Initialize the database schema
docker compose exec social-intel npm run migrate

# Seed the database with initial data
docker compose exec social-intel npm run db:seed

# Run the nightly scoring script to update opportunity scores
docker compose exec niche-scorer npm run score:nightly
```

### Development Setup

```bash
# Install dependencies
npm install

# Set up the database
npm run migrate

# Start the service in development mode
npm run dev

# Seed the database with initial niche data
npm run db:seed
```

## Database Schema

The service uses PostgreSQL with the following main tables:

- **features**: Stores niche data with opportunity scoring
  - `niche_id`: Unique identifier for each niche
  - `phrase`: The niche keyword or phrase
  - `demand_score`: Normalized demand score (0.0 to 1.0)
  - `monetise_score`: Normalized monetization potential (0.0 to 1.0)
  - `supply_score`: Normalized competition level (0.0 to 1.0)
  - `opportunity`: Calculated opportunity score
  - `updated_at`: Last update timestamp

- **hot_niches_today**: Materialized view of top 50 niches by opportunity

## Scoring Algorithm

The niche opportunity score is calculated nightly using:

```
opportunity = (demand_score * monetise_score) / MAX(supply_score, 0.01)
```

Where:
- Higher `demand_score` indicates higher search volume and interest
- Higher `monetise_score` indicates better monetization potential
- Higher `supply_score` indicates more competition (thus lowering opportunity)

## Data Seeding

The service comes with a sample dataset that can be loaded to quickly get started:

```bash
# Seed the database with sample niches
npm run db:seed
```

This command:
1. Reads niche data from `seed/initial_features.csv`
2. Inserts new records to the `features` table (skipping duplicates)
3. Refreshes the `hot_niches_today` materialized view

To add your own data, edit the CSV file before running the seed command.

## Testing

```bash
# Run all tests
npm test

# Run specific test suites
npm run test:unit
npm run test:integration

# Test metrics endpoint for latency buckets
npm run test:metrics

# Validate OpenAPI specification
npm run test:api

# Run k6 load tests locally (requires k6)
npm run test:load

# Run the nightly scoring script manually
npm run score:nightly
```

### Load Testing

The service includes a GitHub Actions workflow that automatically validates performance on every PR and blocks merges if performance thresholds are exceeded:

```bash
# Load test prerequisites
npm install -g k6        # Install k6 load testing tool
npm run migrate          # Set up database
npm run db:seed          # Load seed data

# Run load tests locally
npm run test:load        # Run the load tests
node scripts/assert_k6_si.js  # Analyze the results
```

The load tests verify that the service meets the following performance criteria:
- **Latency:** P95 response time < 800ms for niche-scout, < 400ms for hot-niches, < 1s for seed-to-blueprint
- **Error Rate:** < 5% error rate across all endpoints
- **Throughput:** Ability to handle increasing load from 1-15 VUs

Pull requests that violate these performance thresholds will be automatically blocked by CI.

## Monitoring

Prometheus metrics are exposed at `/health/metrics` and include:

- `si_requests_total`: Total API requests by endpoint and status
- `si_latency_seconds`: Request latency histograms (buckets: 0.05, 0.1, 0.2, 0.4, 0.8, 2 seconds)
- `si_worker_lag_seconds`: Lag time for worker tasks
- `si_db_query_seconds`: Database query time
- `si_niche_scout_results`: Number of niche results
- `si_niche_opportunity_score`: Distribution of opportunity scores

### Alert Rules

The service has the following alert rules defined in `prometheus/prom_alert_rules.yml`:

| Alert Name | Trigger Condition | Duration | Severity |
|------------|-------------------|----------|----------|
| HighLatencyP95 | P95 latency > 0.4s | 2m | Warning |
| HighErrorRate | Error rate > 5% | 1m | Critical |
| LowNicheResultsCount | Results < 5 | 5m | Warning |
| SocialIntelServiceDown | Service not responding | 30s | Critical |

The alert rules are designed to work with the tuned histogram buckets to:
1. Detect latency issues early at the 400ms mark (P95)
2. Balance alert sensitivity with minimizing noise
3. Provide meaningful alerts for SLO violations

## API Documentation

The service provides a Swagger UI interface for browsing and testing the API:

- **Swagger UI**: http://localhost:9000/docs

Key endpoints:
- `POST /niche-scout`: Run niche analysis
- `POST /seed-to-blueprint`: Generate channel strategy
- `GET /workflow-history`: View past workflow executions
- `POST /schedule-workflow`: Schedule a new workflow

The OpenAPI specification is available at:
- `/openapi.yaml`: Raw OpenAPI 3.0 specification

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│ FastAPI     │     │ PostgreSQL  │     │ Nightly      │
│ API Service ├────►│ Database    │◄────┤ Scorer       │
└─────────────┘     └─────────────┘     └──────────────┘
       │                   ▲                    │
       │                   │                    │
       ▼                   │                    ▼
┌─────────────┐     ┌─────────────┐     ┌──────────────┐
│ YouTube     │     │ Redis       │     │ Prometheus   │
│ API Client  │     │ Cache       │     │ Metrics      │
└─────────────┘     └─────────────┘     └──────────────┘
```

## Deployment

The service is deployed using a canary release process:

1. **Database Schema**: Deployed and validated first
2. **Service Container**: Built and deployed with health checks
3. **Canary Testing**: Initial deployment routes 10% of traffic
4. **Monitoring**: 24-hour monitoring period with alerting
5. **Full Deployment**: Promoted to 100% after successful monitoring

Deployment scripts are available in the `/scripts` directory:
- `social-intel-rollout.sh`: Initial canary deployment
- `monitor-social-intel.sh`: Monitoring during canary phase
- `promote-social-intel.sh`: Promotion to 100% traffic

## Version History

See [VERSION.md](./VERSION.md) for version history and [CHANGELOG.md](./CHANGELOG.md) for detailed change information.

## Implementation Status

See [IMPLEMENTATION-STATUS.md](./IMPLEMENTATION-STATUS.md) for detailed implementation status.

## Post-Rollout Actions

See [../docs/POST_ROLLOUT_ACTIONS.md](../docs/POST_ROLLOUT_ACTIONS.md) for post-deployment follow-up tasks.

## License

Proprietary - Alfred Agent Platform