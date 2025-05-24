#\!/usr/bin/env bash
# Measures cold-start time of docker compose up -d until all services healthy
set -e
docker compose down -v --remove-orphans || true

start=$(date +%s)
docker compose up -d
scripts/wait_healthy.sh 120
end=$(date +%s)
total=$((end-start))

echo "Cold-start: ${total}s"
echo "cold_start_seconds=${total}" >> "$GITHUB_OUTPUT"

docker compose down -v --remove-orphans

# fail if over threshold when run locally (CI check happens in workflow)
if [[ -z "$CI" && $total -gt 60 ]]; then
  echo "Cold-start exceeds 60 s" >&2
  exit 1
fi
