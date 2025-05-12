# Alfred Agent Platform v2 - Startup Configurations

## Main Startup Methods

| Method | Command | Configuration | Purpose |
|--------|---------|---------------|---------|
| Main Docker Compose | `docker-compose up -d` | docker-compose.yml | Standard development setup |
| Start Alfred Script | `./start-alfred.sh` | docker-compose.combined-fixed.yml | Feature-based startup (UI, agents, etc.) |
| Start Clean Script | `./start-clean.sh` | docker-compose.combined-fixed.yml | Clean start with network recreation |
| Production Start | `./start-production.sh` | docker-compose.combined-fixed.yml + others | Production deployment |
| Makefile targets | `make start-all`, `make up-core`, etc. | docker-compose.combined-fixed.yml | Component-based startup |

## Specific Use Case Configurations

| Configuration | File | Purpose | Notes |
|---------------|------|---------|-------|
| Main config | docker-compose.yml | Base configuration | Most complete definition |
| Combined fixed | docker-compose.combined-fixed.yml | Improved version of default | Used by scripts |
| Atlas config | docker-compose.atlas.yml, docker-compose.atlas-fix.yml | Atlas development | Focus on the atlas service |
| Monitoring config | docker-compose.monitoring.yml, docker-compose.monitoring-fixed.yml | Monitoring setup | Focus on Prometheus, Grafana |
| Dev override | docker-compose.override.yml | Development settings | Override for development |
| Streamlit chat | services/streamlit-chat/docker-compose.yml | Chat UI development | For UI development |
| Agent orchestrator | services/agent-orchestrator/docker-compose.yml | Orchestrator development | For orchestrator development |
| Mission control | services/mission-control-simplified/docker-compose.yml | Mission control development | For UI dashboard development |

## Startup Scripts

| Script | Purpose | Services Started |
|--------|---------|------------------|
| start-alfred.sh | Main entry point with options | Configurable (--all, --core, --atlas, etc.) |
| start-clean.sh | Clean start with new network | All or selected components |
| start-production.sh | Production deployment | All services with production settings |
| scripts/start-all-dev.sh | Start development stack | Mission control and agent orchestrator |
| services/streamlit-chat/start-dev-stack.sh | Streamlit development | Streamlit and alfred-bot |
| services/alfred-core/start.sh | Alfred core development | Alfred core service |

## Dependencies Between Startup Configurations

- Many scripts ultimately use docker-compose.combined-fixed.yml
- Some services have dedicated development stacks
- Production settings build on combined configuration with specific overrides

## Environment Handling

Most configurations rely on:
- `.env` file for configuration
- Fallback default values in docker-compose files
- Service-specific environment variables

## Network Configuration

- Most services use the `alfred-network`
- Some configurations recreate the network, others reuse it
- Some service-specific configurations create isolated networks

## Volume Management

- Most configurations share the same named volumes
- Some development configurations use additional bind mounts

## Observations and Issues

1. **Redundancy**: Multiple ways to start the same services
2. **Inconsistency**: Different naming conventions across files
3. **Complexity**: Many startup scripts with overlapping functionality
4. **Maintenance overhead**: Changes need to be propagated across files
5. **Developer confusion**: Unclear which configuration to use for what
6. **Version conflicts**: Different configurations might use different versions

## Ideal Refactoring Target

A single, modular docker-compose structure with:
1. Base configuration (docker-compose.yml)
2. Environment-specific overrides (docker-compose.dev.yml, docker-compose.prod.yml)
3. Component-specific overrides (docker-compose.ui.yml, docker-compose.agents.yml)
4. A single, comprehensive startup script with clear options