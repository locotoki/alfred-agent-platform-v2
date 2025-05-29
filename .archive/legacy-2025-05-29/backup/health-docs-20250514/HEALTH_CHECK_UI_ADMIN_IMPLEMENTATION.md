# UI Admin Service Health Check Implementation Guide

This document provides detailed implementation instructions for adding standardized health checks to the UI Admin service (mission-control-simplified) in the Alfred Agent Platform v2.

## Current Status

The UI Admin service currently lacks standardized health check endpoints and metrics export. We need to implement:

1. Standard health endpoints (`/health`, `/healthz`, `/metrics`)
2. Docker healthcheck configuration
3. Metrics export on port 9091
4. Prometheus configuration for metrics scraping

## Implementation Steps

### Step 1: Add Health Endpoints to UI Admin

Since UI Admin is a Node.js service, we'll add Express endpoints for health checks.

1. **Create health routes file**:

```javascript
// File: services/mission-control-simplified/src/routes/health.js

const express = require('express');
const router = express.Router();
const promClient = require('prom-client');

// Create a Registry to register metrics
const register = new promClient.Registry();

// Add a simple counter
const requestsCounter = new promClient.Counter({
  name: 'ui_admin_requests_total',
  help: 'Total number of requests',
  registers: [register]
});

// Add a service health gauge
const serviceHealth = new promClient.Gauge({
  name: 'service_health',
  help: 'Service health status (1 = up, 0 = down)',
  registers: [register]
});

// Set initial values
serviceHealth.set(1);

// Health check endpoint
router.get('/health', (req, res) => {
  requestsCounter.inc();

  // Check dependencies
  const agentCoreStatus = checkAgentCoreConnection() ? 'ok' : 'error';
  const ragStatus = checkRagConnection() ? 'ok' : 'error';
  const socialIntelStatus = checkSocialIntelConnection() ? 'ok' : 'error';

  const services = {
    'agent_core': agentCoreStatus,
    'rag_service': ragStatus,
    'social_intel': socialIntelStatus
  };

  // Determine overall status
  const hasError = Object.values(services).includes('error');
  const status = hasError ? 'error' : 'ok';

  // If status is error, set health gauge to 0
  if (status === 'error') {
    serviceHealth.set(0);
  } else {
    serviceHealth.set(1);
  }

  res.json({
    status: status,
    version: '1.0.0',
    services: services
  });
});

// Simple health probe
router.get('/healthz', (req, res) => {
  requestsCounter.inc();
  res.json({ status: 'ok' });
});

// Prometheus metrics endpoint
router.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Helper functions for dependency checks
function checkAgentCoreConnection() {
  // In a real implementation, check the actual connection
  // For now, return true to indicate working dependency
  return true;
}

function checkRagConnection() {
  return true;
}

function checkSocialIntelConnection() {
  return true;
}

module.exports = router;
```

2. **Update server.js to use health routes**:

```javascript
// Add to existing services/mission-control-simplified/server.js

const healthRoutes = require('./src/routes/health');

// Add this line to your Express app setup
app.use('/', healthRoutes);

// If you use a separate metrics server on 9091
const metricsApp = express();
metricsApp.use('/', healthRoutes);
metricsApp.listen(9091, () => {
  console.log('Metrics server listening on port 9091');
});
```

### Step 2: Update package.json to add dependencies

```json
// Add to dependencies in services/mission-control-simplified/package.json
{
  "dependencies": {
    // ... existing dependencies
    "prom-client": "^14.2.0"
  }
}
```

### Step 3: Update Dockerfile

```dockerfile
# Update services/mission-control-simplified/Dockerfile

FROM ghcr.io/alfred/healthcheck:0.4.0 AS healthcheck
FROM node:18-alpine

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy application code
COPY . .

# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck

# Expose application and metrics ports
EXPOSE 3000
EXPOSE 9091

# Healthcheck configuration
HEALTHCHECK --interval=30s --timeout=20s --start-period=45s --retries=5 \
  CMD healthcheck --http http://localhost:3000/health || exit 1

# Start the application with metrics server
CMD ["node", "server.js"]
```

### Step 4: Update docker-compose.yml

```yaml
# Update ui-admin section in docker-compose.yml

# Admin Dashboard
ui-admin:
  build:
    context: ./services/mission-control-simplified
    dockerfile: Dockerfile
  image: mission-control-simplified:latest
  container_name: ui-admin
  ports:
    - "3007:3000"  # Map container's 3000 to host's 3007
    - "9100:9091"  # Map metrics port to host
  environment:
    - ALFRED_API_URL=http://agent-core:8011
    - ALFRED_RAG_URL=http://agent-rag:8501
    - NEXT_PUBLIC_SOCIAL_INTEL_URL=http://agent-social:9000
    - NODE_ENV=production
    - PORT=3000
  volumes:
    - ./services/mission-control-simplified/standalone.js:/app/standalone.js
  command: ["node", "standalone.js"]
  healthcheck:
    test: ["CMD", "healthcheck", "--http", "http://localhost:3000/health"]
    <<: *basic-health-check
  depends_on:
    agent-core:
      condition: service_started
    agent-social:
      condition: service_started
  restart: unless-stopped
  deploy:
  networks:
    - alfred-network
  labels:
    <<: *ui-service-labels
    com.docker.compose.service: "ui-admin"
    prometheus.metrics.port: "9091"
```

### Step 5: Update Prometheus Configuration

The Prometheus configuration has already been updated to include this service in the `alfred_health_dashboard` job, so no additional changes are needed.

## Implementation Verification

After implementing the changes, verify:

1. **Health Endpoint**:
   ```
   curl -s http://localhost:3007/health | jq
   ```
   Expected: JSON with status and services

2. **Metrics Endpoint**:
   ```
   curl -s http://localhost:9100/metrics | head
   ```
   Expected: Prometheus text format metrics

3. **Docker Healthcheck**:
   ```
   docker inspect --format='{{.State.Health.Status}}' ui-admin
   ```
   Expected: "healthy"

4. **Prometheus Scraping**:
   - Open Prometheus UI (http://localhost:9090)
   - Query: `service_health{job="alfred_health_dashboard"}`
   - Expected: UI Admin service is listed with value 1

## Implementation Checklist

- [ ] Add health routes to UI Admin
- [ ] Update server.js to use health routes
- [ ] Add prom-client dependency
- [ ] Update Dockerfile
- [ ] Update docker-compose.yml
- [ ] Test implementation
- [ ] Document any issues or edge cases

## Troubleshooting

If health checks are not working:

1. **Check Node.js dependencies**: Ensure prom-client is properly installed
2. **Verify port mappings**: Make sure 9091 is exposed in Dockerfile and mapped in docker-compose.yml
3. **Check Express routes**: Confirm the routes are properly registered
4. **Inspect container logs**: Look for any errors during container startup
