#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
set -euo pipefail
RESULTS="bench/cold_start.json"

echo "⏱️  Measuring cold start…"
hyperfine --warmup 1 --export-json "$RESULTS" 'docker compose down -v >/dev/null 2>&1 || true && time docker compose up -d'
jq '.results[0].mean' "$RESULTS" | awk '{printf "⏱️  mean cold-start: %.2f s\n",$1}'
