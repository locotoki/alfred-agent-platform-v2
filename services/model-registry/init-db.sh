#!/bin/bash
set -e

# Wait for postgres to be ready
echo "Waiting for postgres to be ready..."
until PGPASSWORD=postgres psql -h db-postgres -U postgres -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

>&2 echo "Postgres is up - executing command"

# Create schema and tables
echo "Creating schema and tables..."
PGPASSWORD=postgres psql -h db-postgres -U postgres -d postgres -f /app/init-db.sql

echo "Database initialization completed."