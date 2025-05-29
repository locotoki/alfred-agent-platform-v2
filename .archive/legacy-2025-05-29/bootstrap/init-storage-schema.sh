#!/bin/bash
set -e

# Initialize storage schema if it doesn't exist
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Check if storage schema exists
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'storage') THEN
            -- Run the storage schema SQL file
            \i /bootstrap/storage-schema.sql
        END IF;
    END
    \$\$;
EOSQL
