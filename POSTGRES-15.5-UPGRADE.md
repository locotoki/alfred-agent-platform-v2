# Postgres 15.5 Upgrade via Named Volume

## Changes Made
- Migrated from bind mount to Docker named volume: `alfred_db_data_v15_5`
- Upgraded Postgres from 15-alpine to 15.5-alpine
- Fixed permission issues with UID 999
- Enhanced security with proper volume management

## Location
The updated docker-compose.yml is at `/srv/alfred/db-stack/docker-compose.yml`

## Benefits
- Resolves libxml2 CVE vulnerabilities
- Fixes persistent permission issues
- Better Docker volume management
- Easier backup/restore operations
