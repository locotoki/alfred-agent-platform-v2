#!/bin/bash
set -e

# Initialize the database schema
/usr/local/bin/init-db.sh

# Execute the original command (auth service)
exec "$@"