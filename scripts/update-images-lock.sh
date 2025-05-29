#!/usr/bin/env bash
set -euo pipefail
TAG=${TAG:-edge}
docker compose -f docker-compose.yml config --images | sort > images.lock