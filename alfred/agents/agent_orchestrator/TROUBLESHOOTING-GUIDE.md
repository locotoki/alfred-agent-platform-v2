# Agent Orchestrator Troubleshooting Guide

## Common Issues and Solutions

### 1. Social Intelligence Service Shows as Offline

**Symptoms:**
- "Social Intelligence service is currently unavailable. Workflows will run in offline mode with simulated data."
- UI shows that the service is in offline mode even when the service is running.

**Solutions:**

1. **Verify Service is Running:**
   ```bash
   docker ps | grep social-intel
   curl -s http://localhost:9000/health/ | grep status
   ```

2. **Check Network Connectivity:**
   ```bash
   docker exec agent-orchestrator ping -c 3 social-intel
   ```

3. **Fix Service Health Check:**
   - Ensure the health check URL has trailing slash (`/health/` not `/health`)
   - Try multiple service URLs (`http://social-intel:9000/health/`, `http://localhost:9000/health/`)
   - Properly handle redirects (FastAPI redirects `/health` to `/health/`)

4. **Update Environment Variables:**
   ```yaml
   environment:
     - VITE_API_URL=http://social-intel:9000
     - VITE_SOCIAL_INTEL_URL=http://social-intel:9000
     - VITE_USE_MOCK_DATA=false
   ```

5. **Force Service Check:**
   - Add a `forceCheckAllServices()` function to trigger a fresh check
   - Clear cache if service status is stale

### 2. Blank White Screen / Syntax Errors

**Symptoms:**
- Blank white page when accessing UI
- Console errors about unicode escape or syntax errors

**Solutions:**

1. **Fix TypeScript Syntax Errors:**
   - Remove escaped characters (`\!` → `!`)
   - Ensure proper quotes and string literals

2. **Fix Type Imports and Exports:**
   - Ensure all imported types are properly exported
   - Use re-export pattern for moved functionality:
   ```typescript
   // Re-export functions when moved to new files
   export const checkServiceHealth = importedCheckServiceHealth;
   export const getServiceStatus = importedGetServiceStatus;
   export type { ServiceStatus };
   ```

3. **Complete Container Rebuild:**
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

### 3. Debugging Service Issues

**Tools Available:**

1. **Debug Web Interface:**
   - http://localhost:8080/debug-api.html
   - Tests API endpoints and connections

2. **Service Health Manual Check:**
   - http://localhost:8080/test-service-health.js
   - Diagnoses health check issues

3. **Test Connection Script:**
   - http://localhost:8080/test-connection.html
   - Tests browser-to-service connectivity

4. **Container Logs:**
   ```bash
   docker logs agent-orchestrator --tail 50
   docker logs social-intel --tail 50
   ```

### 4. Improving Service Reliability

**Implemented Solutions:**

1. **Enhanced Health Check:**
   - Multiple endpoint attempts (`/health/`, `/health`)
   - Proper redirect handling
   - Service name resolution (`social-intel:9000`, `localhost:9000`)
   - Detailed logging for troubleshooting

2. **Circuit Breaker Pattern:**
   - Service availability cache with TTL
   - Graceful degradation to mock data
   - Automatic retry mechanism

3. **Documentation:**
   - Detailed connectivity troubleshooting in SOCIAL-INTEL-CONNECTIVITY.md
   - Health check improvements in service-health.ts

## Docker Network Configuration

For proper inter-service communication, ensure:

1. All services are on the same Docker network:
   ```yaml
   networks:
     default:
       name: alfred-network
       external: true
   ```

2. Services use the container name for communication:
   ```
   http://social-intel:9000/health/
   ```

3. Health checks use proper container networking:
   ```javascript
   const endpoints = [
     `${API_BASE_URL}/health/`,
     `${API_BASE_URL}/health`,
     `http://social-intel:9000/health/`,
     `http://social-intel:9000/health`
   ];
   ```

## Verifying Fix is Working

To confirm that the Social Intelligence service is properly detected:

1. Access http://localhost:8080/agents/agent-1
2. The service should show as "Available"
3. The workflows should connect to the real API instead of using mock data
4. Check the logs for confirmation:
   ```bash
   docker logs agent-orchestrator | grep "\[Health\]"
   ```

You should see: `[Health] Service socialIntel available: true`
