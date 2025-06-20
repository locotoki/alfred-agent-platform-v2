# Containerization Recommendations

## Current Issue

There is an inconsistency in how the mission-control service is deployed compared to other services in the Alfred Agent Platform:

- Most services (architect-api, financial-tax, etc.) run as Docker containers
- The mission-control service runs directly on the host machine on port 3007
- This causes port configuration issues and dependency management complexity

## Implementation Status

We've implemented a Docker containerization solution:

1. **Updated `docker-compose.override.mission-control.yml`**:
   - Changed port mapping from 3003:3000 to 3007:3000
   - Added volume mounts for source code and node_modules
   - Added environment variables for all service URLs

2. **Updated `Dockerfile`**:
   - Added documentation for port mapping
   - Ensured proper configuration for production use

3. **Created `start-container.sh`**:
   - Added a convenience script for building and running the containerized service
   - Included error handling and service verification

4. **Created Documentation**:
   - `CONTAINERIZATION-PLAN.md`: Detailed plan for containerization
   - `DOCKER-INSTRUCTIONS.md`: Instructions for using the containerized service

## Next Steps

To complete the containerization:

1. **Stop the host-based mission-control service**:
   ```bash
   pkill -f "node.*next"
   ```

2. **Start the containerized mission-control service**:
   ```bash
   cd /home/locotoki/projects/alfred-agent-platform-v2
   ./services/mission-control/start-container.sh
   ```

3. **Verify the containerized service**:
   - Access http://localhost:3007/workflows
   - Verify that it can communicate with the architect-api service
   - Test both the Niche-Scout and Seed-to-Blueprint workflows

## Benefits

Running mission-control as a Docker container will:

1. **Improve Consistency**: All services follow the same deployment model
2. **Simplify Configuration**: Service-to-service communication uses Docker networking
3. **Enhance Portability**: The entire platform can be deployed with one command
4. **Improve Reliability**: Service dependencies are properly defined and managed
5. **Streamline Development**: Development and production environments match

## Long-term Recommendations

For ongoing maintenance:

1. **Update Documentation**: Ensure all documentation references the containerized approach
2. **Standardize CI/CD**: Update CI/CD pipelines to build and deploy Docker containers
3. **Add Integration Tests**: Add tests to verify service-to-service communication
4. **Monitor Container Logs**: Set up log aggregation for all containers
