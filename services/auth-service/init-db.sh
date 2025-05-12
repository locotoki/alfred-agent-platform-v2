#!/bin/bash
set -e

# Wait for Postgres to start
echo "Waiting for PostgreSQL to start..."
until PGPASSWORD=${DB_PASSWORD} psql -h db-postgres -U ${DB_USER} -c '\q'; do
  echo "PostgreSQL is unavailable - sleeping"
  sleep 1
done

echo "PostgreSQL is up - executing schema creation"

# Create the auth schema
PGPASSWORD=${DB_PASSWORD} psql -h db-postgres -U ${DB_USER} -c "CREATE SCHEMA IF NOT EXISTS auth;"

# Set the search path for the database
PGPASSWORD=${DB_PASSWORD} psql -h db-postgres -U ${DB_USER} -c "ALTER DATABASE postgres SET search_path TO \"\$user\", public, auth;"

# Create the schema_migrations table in the auth schema
PGPASSWORD=${DB_PASSWORD} psql -h db-postgres -U ${DB_USER} -c "
CREATE TABLE IF NOT EXISTS auth.schema_migrations (
  version VARCHAR(14) NOT NULL,
  PRIMARY KEY(version)
);
CREATE UNIQUE INDEX IF NOT EXISTS schema_migrations_version_idx ON auth.schema_migrations (version);
"

echo "Auth schema initialization complete"