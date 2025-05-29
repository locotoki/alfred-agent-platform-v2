# Alfred Agent Platform v2 - Clean Project Structure

## Directory Organization (as of 2025-05-29)

### 🎯 Core Application Code
- **`alfred/`** - Main platform namespace containing all core services
  - Core infrastructure modules
  - Service implementations
  - Shared protocols and interfaces
  
- **`agents/`** - Agent implementations
  - `financial_tax/` - Financial and tax agent
  - `legal_compliance/` - Legal compliance agent
  - `social_intel/` - Social intelligence agent

- **`services/`** - Service-specific implementations
  - `slack_mcp_gateway/` - Slack MCP gateway service
  - Other microservices

### 🐳 Infrastructure & Deployment
- **`docker-compose/`** - Docker Compose configurations
  - Environment-specific compose files
  - Service orchestration

- **`config/`** - Configuration files
  - `redis.conf` - Redis configuration
  - `redis-entrypoint.sh` - Redis startup script

- **`k8s/`** - Kubernetes manifests
  - Deployment configurations
  - Service definitions

- **`charts/`** - Helm charts
  - `alfred-3.0.1.tgz` - Latest Helm package

- **`terraform/`** - Infrastructure as Code
  - Cloud resource definitions

### 📊 Monitoring & Observability
- **`monitoring/`** - Monitoring stack configuration
- **`prometheus/`** - Prometheus configuration and rules
- **`grafana/`** - Grafana dashboards
- **`observability/`** - Observability setup
- **`metrics/`** - Metrics collection and reporting

### 🔧 Development & Operations
- **`scripts/`** - Operational and automation scripts
- **`migrations/`** - Database migrations (Alembic)
- **`tests/`** - Test suites
- **`templates/`** - Service templates
- **`requirements/`** - Python dependency specifications

### 📚 Documentation & Analysis
- **`docs/`** - Project documentation
- **`runbooks/`** - Operational runbooks
- **`rca/`** - Root cause analysis documents

### 🔌 Integration Adapters
- **`adapters/`** - External integration adapters
  - `slack/` - Slack integration
  - `telegram/` - Telegram integration

- **`slack-bot/`** - Consolidated Slack bot service

### 🚀 CI/CD
- **`.github/`** - GitHub Actions workflows
- **`ci/`** - Additional CI configurations

### 🗄️ Archived Content
- **`.archive/legacy-2025-05-29/`** - Legacy folders moved for cleanup
  - Contains 40+ folders that were obsolete or redundant
  - Includes old implementations, unused features, and development artifacts

### 📁 Special Directories
- **`bin/`** - Binary files (couldn't move due to permissions)

## Clean Structure Benefits

1. **Reduced Clutter**: From 75+ directories to 25 essential ones
2. **Clear Organization**: Each directory has a specific purpose
3. **Easy Navigation**: Related functionality grouped together
4. **Maintained History**: Legacy code archived, not deleted

## Quick Reference

| Need to work on... | Look in... |
|-------------------|------------|
| Core platform code | `alfred/` |
| Agent logic | `agents/` |
| Service implementations | `services/` |
| Docker setup | `docker-compose/`, `config/` |
| Kubernetes deployment | `k8s/`, `charts/` |
| Monitoring | `monitoring/`, `prometheus/`, `grafana/` |
| Scripts & automation | `scripts/` |
| Documentation | `docs/`, `runbooks/` |
| Tests | `tests/` |
| Database changes | `migrations/` |

## Notes

- The `.backup/` directory was kept as it may contain important backups
- The `bin/` directory couldn't be moved due to permissions but appears to only contain the `act` binary
- All moved folders are preserved in `.archive/legacy-2025-05-29/` if needed for reference