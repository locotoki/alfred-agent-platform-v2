# Changelog

## Version 0.2.0 (2025-05-11)

### Major Changes

#### Infrastructure and Docker Setup
- **Docker Configuration**: Created a streamlined Docker Compose configuration in `docker-compose.combined-fixed.yml`
- **Startup Script**: Developed a comprehensive `start-production.sh` script that correctly sets up the environment
- **Network Handling**: Fixed Docker network configuration with proper creation/removal of `alfred-network`
- **Verification System**: Created `verify-platform.sh` for automated environment verification

#### Supabase Integration
- **Authentication Fix**: Disabled authentication requirements for development environment
- **Database Schema**: Created proper schema with tables for all services
- **JWT Configuration**: Fixed JWT token configuration for secure communication
- **RLS Policies**: Configured Row Level Security (RLS) policies for table access

#### Health Monitoring
- **Atlas Health Fix**: Patched Atlas health endpoint to correctly return 200 OK status
- **Health Endpoints**: Added standardized `/health` and `/healthz` endpoints to services
- **Health Reporting**: Improved health status reporting for external service connections

#### Documentation
- **CURRENT_STATE.md**: Updated with complete environment state
- **QUICKSTART.md**: Enhanced with clear setup instructions
- **SUPABASE_STATUS.md**: Added documentation on Supabase authentication configuration
- **Patches README**: Documented health endpoint fixes and implementation

### Bug Fixes
- Fixed Grafana startup issue with YAML syntax error in atlas.yml
- Fixed Atlas reporting unhealthy in Docker health checks
- Fixed 401 errors when connecting to Supabase
- Fixed service-to-service communication problems

### Improvements
- **Service Naming**: Standardized service names (e.g., rag-gateway, atlas)
- **Environment Variables**: Ensured consistent environment variables across containers
- **Script Organization**: Created specialized scripts for specific tasks
- **Error Handling**: Improved error reporting in scripts

## Version 0.1.0 (2025-05-04)

Initial version of the Alfred Agent Platform v2 with:
- Basic Docker Compose setup
- Atlas service
- RAG Gateway
- Supabase integration
- Monitoring with Prometheus and Grafana
