#\!/usr/bin/env bash
set -euo pipefail
RESULTS="bench/cold_start.json"

echo "⏱️  Measuring cold start…"
hyperfine --warmup 1 --export-json "$RESULTS" 'docker compose down -v >/dev/null 2>&1 || true && time alfred up'
jq '.results[0].mean' "$RESULTS"  < /dev/null |  awk '{printf "⏱️  mean cold-start: %.2f s\n",$1}'
