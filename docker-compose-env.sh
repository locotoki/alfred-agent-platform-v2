#!/bin/bash
# docker-compose-env.sh - Wrapper script for docker-compose with .env.local support

# Rather than exporting all variables which can cause issues with comments,
# let's use explicit env-file flags for docker compose
docker compose --env-file .env --env-file .env.local "$@"
