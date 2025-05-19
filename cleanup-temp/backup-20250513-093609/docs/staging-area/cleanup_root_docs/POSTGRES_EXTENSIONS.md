# PostgreSQL Extensions in Alfred Agent Platform

This document describes the PostgreSQL extensions required by the Alfred Agent Platform and how they are installed.

## Required Extensions

The Alfred Agent Platform requires the following PostgreSQL extensions:

- **uuid-ossp**: For generating UUIDs in PostgreSQL
- **pgcrypto**: For cryptographic functions
- **pgjwt**: For JWT token handling
- **pg_stat_statements**: For SQL statement statistics
- **pg_trgm**: For text similarity search
- **pg_cron**: For scheduling jobs within PostgreSQL
- **pgvector**: For vector operations (embeddings storage and retrieval)

## Custom PostgreSQL Image

We use a custom PostgreSQL image based on `pgvector/pgvector:pg14` that includes all required extensions. The Dockerfile for this image is located at `/services/db-postgres/Dockerfile` and is built using:

```bash
docker-compose build db-postgres
```

## Custom Initialization Scripts

We provide a fallback mechanism in case the pgjwt extension is not properly installed. This is handled by `/services/db-postgres/init-patch.sql`, which is mounted at `/docker-entrypoint-initdb.d/002_init_patch.sql` in the container.

## Model Registry Schema

The Model Registry service uses a PostgreSQL schema named `model_registry` with tables for tracking LLM models, capabilities, and usage statistics. This schema is initialized by the script at `/services/model-registry/init-db.sql`, which is mounted at `/docker-entrypoint-initdb.d/900_model_registry_init.sql` in the container.

## Order of Initialization

The PostgreSQL initialization scripts are executed in alphabetical order, which is why we prefix them with numbers to control execution order:

1. `0001_supabase_channels.sql`, `0002_atlas_auth.sql`, etc.: Base schema initialization
2. `002_init_patch.sql`: Extensions fallback patch
3. `900_model_registry_init.sql`: Model Registry schema initialization

## Troubleshooting

If you encounter issues with missing extensions, consider these steps:

1. Check that the custom PostgreSQL image was built correctly
2. Verify that all initialization scripts are mounted correctly
3. Examine PostgreSQL logs for any errors during startup
4. Run `docker exec db-postgres psql -U postgres -c "SELECT extname FROM pg_extension;"` to list installed extensions
5. Manually create missing extensions or schemas using `docker exec db-postgres psql -U postgres -f /path/to/script.sql`

## Rebuilding the Database

If you need to completely rebuild the database, follow these steps:

1. Stop all containers: `docker-compose -f docker-compose-clean.yml down`
2. Remove the PostgreSQL volume: `docker volume rm alfred-db-postgres-data`
3. Rebuild the PostgreSQL image: `docker-compose -f docker-compose-clean.yml build db-postgres`
4. Start the containers: `docker-compose -f docker-compose-clean.yml up -d`
