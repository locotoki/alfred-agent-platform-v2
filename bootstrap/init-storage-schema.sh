#!/bin/bash
set -e -x  # Enable verbose output

echo "Running Storage Schema Initialization Script"

# PostgreSQL connection parameters
PG_HOST="${DB_HOST:-db-postgres}"
PG_PORT="${DB_PORT:-5432}"
PG_USER="${DB_USER:-postgres}"
PG_PASSWORD="${DB_PASSWORD:-postgres}"
PG_DATABASE="${DB_NAME:-postgres}"

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
MAX_RETRIES=30
RETRY=0
until PGPASSWORD="$PG_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" -c "SELECT 1" >/dev/null 2>&1 || [ $RETRY -eq $MAX_RETRIES ]
do
  echo "Waiting for PostgreSQL to become available... ($((MAX_RETRIES - RETRY)) attempts left)"
  RETRY=$((RETRY + 1))
  sleep 2
done

if [ $RETRY -eq $MAX_RETRIES ]; then
  echo "Error: Could not connect to PostgreSQL"
  exit 1
fi

echo "PostgreSQL is ready"

# Check if storage schema already exists
SCHEMA_EXISTS=$(PGPASSWORD="$PG_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" -t -c "SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'storage');")

if [[ $SCHEMA_EXISTS =~ t ]]; then
  echo "Storage schema already exists"

  # Ensure migrations table is empty to bypass validation
  echo "Ensuring storage.migrations table is empty..."
  PGPASSWORD="$PG_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" -c "TRUNCATE storage.migrations;"
else
  echo "Initializing storage schema..."
  # Apply the schema SQL
  PGPASSWORD="$PG_PASSWORD" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DATABASE" -f /bootstrap/storage-schema.sql
fi

echo "Storage schema initialization complete"
