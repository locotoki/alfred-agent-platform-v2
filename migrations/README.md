# Database Migrations

This directory contains database migrations for the Alfred Agent Platform v2.

## Migration Order

Migrations must be executed in the following order:

1. `000_init.sql` - Create roles and enable pgvector
2. `001_extensions.sql` - Enable additional PostgreSQL extensions
3. `002_core_tables.sql` - Create core application tables

## Running Migrations

### Automatic (via Docker)

Migrations are automatically applied when starting the database container:

```bash
docker compose up supabase-db
```

### Manual

To run migrations manually:

```bash
# Connect to database
psql postgresql://postgres:password@localhost:5432/postgres

# Run migrations in order
\i migrations/supabase/000_init.sql
\i migrations/supabase/001_extensions.sql
\i migrations/supabase/002_core_tables.sql
```

## Creating New Migrations

1. Create a new SQL file with incrementing number prefix
2. Add descriptive name after the number
3. Include rollback statements commented out at the bottom
4. Update this README with the new migration in the order list

Example migration file structure:

```sql
-- 003_new_feature.sql
-- Description: Add new feature tables

-- Migration
CREATE TABLE new_feature (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rollback (commented out)
-- DROP TABLE new_feature;
```

## Best Practices

1. Keep migrations small and focused
2. Always include rollback statements
3. Test migrations in development first
4. Use descriptive table and column names
5. Include appropriate indexes
6. Add comments for complex logic
