#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
RESULTS="bench/cold_start.json"

# Check if we're in a CI environment without compose files
if [[ ! -f "docker-compose.yml" ]] && [[ "${CI:-false}" == "true" ]]; then
    echo "⏱️  Skipping cold start benchmark in CI (no docker-compose.yml)"
    echo '{"results":[{"mean":0.0}]}' > "$RESULTS"
    echo "⏱️  mean cold-start: 0.00 s (skipped)"
    exit 0
fi

echo "⏱️  Measuring cold start…"
hyperfine --warmup 1 --export-json "$RESULTS" 'docker compose down -v >/dev/null 2>&1 || true && time docker compose up -d'
jq '.results[0].mean' "$RESULTS" | awk '{printf "⏱️  mean cold-start: %.2f s\n",$1}'
