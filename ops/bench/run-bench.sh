#!/usr/bin/env bash
set -euo pipefail
RUNS=${1:-3}
OUT=$(mktemp)
for i in $(seq 1 "$RUNS"); do
  START=$(date +%s%3N)
  alfred up --profile core >/dev/null 2>&1
  END=$(date +%s%3N)
  DUR=$((END-START))
  echo "{\"run\":$i,\"ms\":$DUR}" >> "$OUT"
  alfred down >/dev/null 2>&1
done
jq -s '{p95: (sort_by(.ms) | .[round(0.95*length)].ms), runs: .}' "$OUT" > "${2:-bench.json}"
