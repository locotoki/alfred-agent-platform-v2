# Database Migrations

## Migration Order

1. `000_init.sql` - Initialize database with roles and pgvector extension
2. `001_extensions.sql` - Additional extensions (excluding pgvector)
3. `002_core_tables.sql` - Core application tables

## To Run Migrations

```bash
make db-migrate
-- Enable pgvector
CREATE EXTENSION IF NOT EXISTS "vector" SCHEMA extensions;
