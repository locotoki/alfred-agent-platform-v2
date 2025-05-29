# Local Stack Boot Errors (SC-LS-001)

## Summary of Issues
The local stack cannot start properly due to several critical issues:

1. **PostgreSQL version incompatibility**:
   - Error: `database files are incompatible with server`
   - Details: The data directory was initialized by PostgreSQL version 15, but the current container uses version 14.18
   - Impact: Database cannot start

2. **Grafana datasource configuration error**:
   - Error: `Datasource provisioning error: datasource.yaml config is invalid. Only one datasource per organization can be marked as default`
   - Details: Multiple datasources are marked as default in the provisioning configuration
   - Impact: Grafana container keeps restarting

3. **Docker compose file generation issue**:
   - Error: `Additional property .env-common is not allowed`
   - Details: The `generate_compose.py` script adds an invalid `.env-common` property to the docker-compose.generated.yml file
   - Impact: Cannot start the stack with docker compose

4. **Health check script dependency**:
   - Error: `jq: command not found`
   - Details: The compose-health-check.sh script requires jq for JSON parsing
   - Impact: Cannot accurately report on service health

## Service Status
- Redis: Can run independently but fails as part of the stack
- PostgreSQL: Cannot start due to version incompatibility
- Grafana/Prometheus: Cannot start due to configuration errors

## Recommended Actions

1. **Fix PostgreSQL version incompatibility**:
   - Update Dockerfile to use postgres:15-alpine
   - OR clean the volume: `docker volume rm alfred-db-postgres-data`

2. **Fix Grafana datasource configuration**:
   - Review and fix provisioning files to ensure only one datasource is marked as default
   - Location: monitoring/grafana/provisioning/datasources/datasource.yaml

3. **Fix docker-compose generation script**:
   - Modify scripts/generate_compose.py to avoid adding the `.env-common` property
   - A fixed version has been created at scripts/generate_compose_fixed.py

4. **Install jq dependency**:
   - Run: `apt-get update && apt-get install -y jq`
