# Social Intelligence Service Connectivity Troubleshooting

## Issue
The agent-orchestrator UI is showing "Social Intelligence service is currently unavailable. Workflows will run in offline mode with simulated data."

## Diagnosis Steps
1. We verified that the Social Intelligence service is running and healthy:
   ```bash
   curl -s http://localhost:9000/health/
   {"status":"healthy","service":"social-intel","version":"1.0.0"}
   ```

2. We confirmed both containers are on the same Docker network:
   ```bash
   docker inspect agent-orchestrator -f "{{.NetworkSettings.Networks}}"
   map[alfred-network:0xc000186a80]
   
   docker inspect social-intel -f "{{.NetworkSettings.Networks}}"
   map[alfred-network:0xc00017eb60]
   ```

3. We verified connectivity through the Docker network:
   ```bash
   docker exec agent-orchestrator ping -c 3 social-intel
   ```
   The ping was successful, showing the network connection works.

4. We found several issues with the health check implementation:

   a. The health endpoint in the Social Intelligence service has a trailing slash, causing a redirect:
      ```
      GET /health -> 307 -> /health/
      ```

   b. The agent-orchestrator was not following redirects properly.

   c. There might be issues with Docker DNS resolution or network timeouts.

## Solution

We implemented several fixes:

1. Created a new service-health.ts module with improved health check functionality:
   - The checkServiceHealth function now tries multiple endpoint URLs
   - It properly handles redirects
   - It has better error handling and debugging
   - It exposes a forceCheckAllServices function to manually trigger health checks

2. Updated the docker-compose.override.yml to ensure proper service names are used:
   ```yml
   environment:
     - NODE_ENV=development
     - VITE_API_URL=http://social-intel:9000
     - VITE_SOCIAL_INTEL_URL=http://social-intel:9000
     - VITE_USE_MOCK_DATA=false
   ```

3. Modified the health check endpoint to include a trailing slash:
   ```javascript
   const endpoint = service === 'socialIntel' ? `${API_BASE_URL}/health/` : `${API_BASE_URL}/health/`;
   ```

4. Added debugging tools to help diagnose future issues:
   - Created debug-api.html to test API endpoints directly
   - Added detailed logging in the health check function

## Verification

To verify the fix:

1. Access the debug page at http://localhost:8080/debug-api.html and test the health endpoint.

2. Access the YouTube test page at http://localhost:8080/ and confirm the Social Intelligence service is shown as available.

3. Try running a workflow and verify it connects to the real API instead of using mock data.

## Next Steps

If the service still shows as offline:

1. Check the agent-orchestrator logs for health check errors:
   ```bash
   docker logs agent-orchestrator | grep -i health
   ```

2. Test if the service-health module is properly imported and initialized.

3. Verify that the forceCheckAllServices function is being called on application start.

4. Consider implementing a more robust circuit breaker pattern to handle temporary service outages.

## Long-term Improvements

1. **Circuit Breaker Pattern**: Implement a proper circuit breaker to handle temporary service outages with exponential backoff.

2. **Health Dashboard**: Add a dedicated dashboard showing the health and status of all services.

3. **Centralized Logging**: Implement centralized logging to make debugging easier.

4. **Auto-recovery**: Add auto-recovery mechanisms for services showing persistently offline.