# Alfred Agent Platform v2

> **🎉 GA Ready - v3.0.0** | **Health: 100%** | **Cold-start: 14s**
> A production-ready, scalable AI agent platform built with Docker, Supabase, and Pub/Sub messaging.

[![Black Code Style](https://img.shields.io/badge/code%20style-black-000000.svg)](https://github.com/psf/black)
[![Black Format Check](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/black-check.yml/badge.svg?branch=main)](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/black-check.yml)
[![Dependency Inventory](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/deps-inventory-cron.yml/badge.svg)](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/deps-inventory-cron.yml)
[![Vulnerability Scan](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/vuln-scan-cron.yml/badge.svg)](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/vuln-scan-cron.yml)
[![License Compliance](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/license-scan-cron.yml/badge.svg)](https://github.com/locotoki/alfred-agent-platform-v2/actions/workflows/license-scan-cron.yml)
![Consolidation Progress](https://img.shields.io/badge/SC--250--complete-brightgreen?logo=github)
<sub>☝︎ Auto-updated by CI</sub>

## Features

- 🤖 Multiple AI agents with LangChain and LangGraph
- 📨 Event-driven architecture with Google Cloud Pub/Sub
- 🗄️ State management with Supabase (PostgreSQL + pgvector)
- 🔍 Vector search with Qdrant
- 🎯 Real-time updates via Supabase Realtime
- 📊 Comprehensive monitoring with Prometheus and Grafana
- 🔒 Built-in security with rate limiting and PII scrubbing
- 🚀 Local-first development with Docker Compose

## Available Agents

- **Alfred Bot**: Slack interface for platform interaction
- **Social Intelligence**: Social media trend analysis and monitoring
- **Legal Compliance**: Regulatory compliance checking and monitoring
- **Financial-Tax**: Tax calculations, financial analysis, and compliance checking

## Quick Start

### Prerequisites

- Docker Engine 25.0+
- Docker Compose v2
- Python 3.11+
- NVIDIA GPU with drivers (for local LLM)
- Git and Git LFS

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/alfred-agent-platform-v2.git
   cd alfred-agent-platform-v2
   ```

2. Initialize the environment:
   ```bash
   make init
   ```

3. Configure your environment:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

4. Start the platform:
   ```bash
   # One-command full local stack (all 34 services)
   make up

   # Production-like environment
   docker compose up -d

   # Development environment with hot-reloading and debugging
   docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile dev up -d

   # Include mock services for development
   docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile dev --profile mocks up -d

   # Stop the full stack
   make down
   ```

5. Access the services:
   - Supabase Studio: http://localhost:3001
   - Mission Control UI: http://localhost:3007
   - Grafana: http://localhost:3005
   - Prometheus: http://localhost:9090
   - Chat UI: http://localhost:8502
   - Financial-Tax API: http://localhost:9003/docs
   - Social Intelligence API: http://localhost:9000/docs

## Development

### Running Tests

```bash
# Run all tests
make test

# Run specific test types
make test-unit
make test-integration
make test-e2e
```

### Code Quality

```bash
# Format code (Black for Python, Prettier for JS/TS)
make format

# Run linters
make lint
```

We use industry-standard code formatters and linters:
- **Black (v24.1.1)**: Python formatter with line length=100
- **isort**: Import sorting (with Black compatibility)
- **flake8**: Python linter
- **mypy**: Static type checker

To manually apply Black formatting:
```bash
./scripts/apply-black-formatting.sh
```

See [Black Formatting Standards](docs/formatting/BLACK-FORMATTING-STANDARDS.md) for more details.

### Adding a New Agent

1. Create agent directory:
   ```bash
   mkdir -p agents/new_agent
   ```

2. Implement agent logic inheriting from `BaseAgent`
3. Create Docker service in `services/new-agent`
4. Add to `docker-compose.yml`
5. Update CI/CD matrix

## Production Deployment

### 🚀 GA Release v3.0.0 (July 11, 2025)

The platform is production-ready with:
- **100% service health coverage** (36/36 services)
- **Full TLS/HTTPS support** with automated certificates
- **Resource limits** configured for all services
- **Comprehensive monitoring** with Prometheus & Grafana
- **Multiple deployment options**: Docker Compose, Swarm, Kubernetes

### Deployment Options

#### Docker Compose (Single Node)
```bash
docker-compose -f docker-compose.yml \
               -f docker-compose.prod.yml \
               -f docker-compose.tls.yml \
               up -d
```

#### Kubernetes (Helm)
```bash
helm install alfred ./charts/alfred \
  --values ./charts/alfred/values-prod.yaml \
  --set image.tag=v3.0.0
```

See [Production Deployment Checklist](docs/production-deployment-checklist.md) for detailed instructions.

## Architecture

The platform follows an event-driven microservices architecture:

- **Entry Points**: Slack bot, API endpoints
- **Message Bus**: Google Cloud Pub/Sub
- **State Storage**: Supabase (PostgreSQL)
- **Vector Search**: Qdrant
- **Agent Framework**: LangChain + LangGraph
- **Monitoring**: Prometheus + Grafana

## Configuration

### Environment Variables

Key environment variables:

- `ENVIRONMENT`: Development/staging/production
- `DATABASE_URL`: PostgreSQL connection string
- `PUBSUB_EMULATOR_HOST`: Pub/Sub emulator address
- `OPENAI_API_KEY`: OpenAI API key
- `SLACK_BOT_TOKEN`: Slack bot token

See `.env.example` for full list.

### Database Migrations

```bash
# Run migrations
make db-migrate

# Reset database (CAUTION: deletes all data)
make db-reset
```

## Deployment

### Local Development

```bash
# Start all services in development mode (default)
./start-platform.sh

# Start in production mode
./start-platform.sh -e prod

# Start in detached mode (background)
./start-platform.sh -d

# Start just specific services
./start-platform.sh agent-core ui-chat

# View logs
./start-platform.sh -a logs

# Stop all services
./start-platform.sh -a down
```

#### Docker Compose Structure
The platform uses a simplified Docker Compose configuration:

- `docker-compose.yml` - Core configuration with all services and production defaults
- `docker-compose.dev.yml` - Development overrides with debugging and hot-reloading
- `docker-compose.prod.yml` - Production optimizations with performance settings
- `docker-compose.local.yml` - Personal developer customizations (create from template, not in version control)

Services are organized using profiles to enable conditional startup:
```bash
# Start with development profile (enables debug mode, hot-reloading)
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile dev up -d

# Add mock services for testing without real dependencies
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile dev --profile mocks up -d

# Start only specific services
docker compose -f docker-compose.yml -f docker-compose.dev.yml --profile dev up -d mission-control social-intel
```

To create your personal configuration file:
```bash
cp docker-compose.local.yml.template docker-compose.local.yml
# Edit as needed - this file is gitignored
```

See [DOCKER-COMPOSE-GUIDE.md](DOCKER-COMPOSE-GUIDE.md) for more details on the Docker Compose structure.

The platform includes these services:
- Slack Bot: http://localhost:8011
- Mission Control: http://localhost:8012
- RAG Gateway: http://localhost:8013
- WhatsApp Adapter: http://localhost:8014
- Streamlit Chat (dev-only): http://localhost:8501
- Redis
- Supabase (PostgreSQL)

### Staging Deployment

```bash
# Triggered automatically on push to develop branch
```

### Production Deployment

```bash
# Triggered automatically on push to main branch
```

## Monitoring

Access monitoring dashboards:

```bash
make monitor
```

- Grafana: http://localhost:3005 (admin/admin)
- Prometheus: http://localhost:9090

### Metrics and Health Checks

The platform includes comprehensive health monitoring with metrics export:

- **Update healthcheck binary**: `./scripts/update-healthcheck-binary.sh`
- **Validate metrics format**: `./scripts/lint-metrics-format.sh`
- **Setup DB metrics**: `make setup-metrics`
- **Service health dashboard**: http://localhost:3005/d/platform-health-dashboard/platform-health-dashboard
- **DB health dashboard**: http://localhost:3005/d/db-health-dashboard/database-health-dashboard

Each service exposes three standard health endpoints:
- `/health` - Detailed health information
- `/healthz` - Simple health probe
- `/metrics` - Prometheus metrics (port 909x)

For detailed documentation on the monitoring system, see:
- [Prometheus Health Implementation](docs/monitoring/PROMETHEUS_HEALTH_IMPLEMENTATION.md)
- [DB Metrics Implementation](docs/monitoring/DB_METRICS_IMPLEMENTATION.md)
- [Grafana Dashboard Preview](docs/monitoring/GRAFANA-DASHBOARD-PREVIEW.md)

#### Distributed Tracing

Health check probes support optional OpenTelemetry tracing to correlate health issues with service performance:

```bash
# Enable tracing for a health check probe
healthcheck --db-type postgres --db-dsn "user:pass@host:port/db" --trace-endpoint http://otel-collector:4318

# Environment variable configuration
export TRACE_ENDPOINT=http://otel-collector:4318
healthcheck --db-type postgres --db-dsn "user:pass@host:port/db"
```

See [TRACING.md](docs/TRACING.md) for full documentation.

## Dependency Management

The platform maintains an automated inventory of all Python dependencies to support vulnerability scanning, license compliance, and dependency management.

### Dependency Inventory

- **Automated Tracking**: All `requirements*.txt` and `pyproject.toml` files are scanned
- **Import Analysis**: Python imports are analyzed to discover undeclared dependencies
- **Weekly Refresh**: The dependency inventory is automatically updated every Monday at 08:00 UTC
- **CSV Output**: Complete inventory available at `metrics/dependency_inventory.csv`

### Vulnerability Scanning

- **Automated CVE Detection**: Weekly security vulnerability scanning using `pip-audit`
- **Comprehensive Coverage**: Scans all packages in the dependency inventory
- **Weekly Schedule**: Runs every Monday at 08:15 UTC (after inventory refresh)
- **Security Reports**: Vulnerability details saved to `metrics/vulnerability_report.csv`
- **CI Security Gate**: Pull requests are automatically blocked if critical or high severity vulnerabilities are detected
- **Age-Based Waivers**: HIGH/CRITICAL CVEs older than 30 days with available fixes are automatically waived in CI
- **Slack Alerts**: Real-time notifications for HIGH/CRITICAL CVEs that are young (≤30 days) or have no available fixes

### License Compliance

- **Automated License Detection**: Weekly license compliance scanning using `pip-licenses`
- **SPDX-Based Classification**: Uses SPDX license identifiers for precise categorization as permissive, copyleft, weak-copyleft, public-domain, or other
- **Enhanced Pattern Matching**: Intelligent fallback classification for non-SPDX license names
- **Compliance Monitoring**: Tracks license obligations and potential conflicts with <10% unknown/other ratio target
- **Weekly Schedule**: Runs every Monday at 08:20 UTC (after vulnerability scan)
- **Compliance Reports**: License details and classifications saved to `metrics/license_report.csv`

📊 **[Audit Dashboard](docs/audit/dashboard.md)** - Comprehensive overview of dependencies, vulnerabilities, and license compliance with automated weekly updates.

The dependency inventory, vulnerability scanning, and license compliance workflows run automatically and commit any changes to maintain comprehensive security and compliance awareness across all Python dependencies.

## Roadmap & GA Board

- [GA v3.0.0 Checklist](./docs/GA_SCOPE_CHECKLIST.md) - Core slice deliverables for General Availability
- [▶️ GA v3.0.0 Checklist](https://github.com/users/locotoki/projects/3) - Live tracking board

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
