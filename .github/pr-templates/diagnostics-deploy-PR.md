## Summary
Adds deployment infrastructure for the Slack diagnostics bot to support containerized deployment and Helm chart installation.

## Key Changes

### 1. Docker Containerization
- Created `docker/diagnostics-bot/Dockerfile` for Python 3.11 slim image
- Uses Poetry for dependency management
- Configurable via environment variables

### 2. Helm Sub-chart
- Added `charts/alfred/charts/diagnostics-bot/` with:
  - Deployment manifest with secret mounting
  - Kubernetes secrets for Slack tokens
  - Configurable resources and socket mode support
- Integrated with parent Alfred chart as conditional dependency

### 3. CI/CD Pipeline
- GitHub Actions workflow for automatic Docker image builds
- Triggers on version tags and feature branches
- Pushes to GitHub Container Registry

### 4. Bot Module Structure
- Restructured `alfred.slack.diagnostics` as a package
- Added `__main__.py` for direct module execution
- Integrated with slack-bolt for socket mode support

### 5. Local Development
- Docker Compose configuration for local testing
- Environment variable support for tokens
- Mounted volumes for development

## Testing
- Docker build tested locally
- Module imports verified
- Helm chart syntax validated

## Deployment Instructions
```bash
# Local development
docker-compose -f deploy/docker-compose.diagnostics.yml up

# Kubernetes deployment
helm install alfred ./charts/alfred -n dev \
  --set diagnostics.enabled=true \
  --set diagnostics.env.SLACK_BOT_TOKEN=$SLACK_BOT_TOKEN \
  --set diagnostics.env.SLACK_APP_TOKEN=$SLACK_APP_TOKEN
```

## Checklist
- [x] Dockerfile created and builds successfully
- [x] Helm chart validated
- [x] GitHub Actions workflow configured
- [x] Module restructured for execution
- [x] Documentation updated
- [x] Pre-commit checks pass

Complements #74 with deployment capabilities for Phase 8.1.
