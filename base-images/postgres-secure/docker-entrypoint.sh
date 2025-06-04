#!/bin/bash
set -Eeo pipefail

# Custom PostgreSQL entrypoint that uses su-exec instead of gosu
# Addresses security vulnerabilities in gosu binary

# usage: file_env VAR [DEFAULT]
#    ie: file_env 'XYZ_DB_PASSWORD' 'example'
# (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of
#  "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
	local var="$1"
	local fileVar="${var}_FILE"
	local def="${2:-}"
	if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
		echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
		exit 1
	fi
	local val="$def"
	if [ "${!var:-}" ]; then
		val="${!var}"
	elif [ "${!fileVar:-}" ]; then
		val="$(< "${!fileVar}")"
	fi
	export "$var"="$val"
	unset "$fileVar"
}

# Initialize environment variables
file_env 'POSTGRES_PASSWORD'
file_env 'POSTGRES_USER' 'postgres'
file_env 'POSTGRES_DB' "$POSTGRES_USER"
file_env 'POSTGRES_INITDB_ARGS'

# Setup data directory permissions
if [ ! -d /var/lib/postgresql/data ]; then
    mkdir -p /var/lib/postgresql/data
fi
chown -R postgres:postgres /var/lib/postgresql/data
chmod 700 /var/lib/postgresql/data

# Initialize database if needed
if [ ! -s /var/lib/postgresql/data/PG_VERSION ]; then
    su-exec postgres initdb \
        --pgdata=/var/lib/postgresql/data \
        --username="$POSTGRES_USER" \
        --pwfile=<(echo "$POSTGRES_PASSWORD") \
        $POSTGRES_INITDB_ARGS
    
    # Configure PostgreSQL
    echo "host all all all md5" >> /var/lib/postgresql/data/pg_hba.conf
    echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf
fi

# Start PostgreSQL with su-exec (more secure than gosu)
exec su-exec postgres postgres "$@"