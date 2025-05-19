#!/usr/bin/env bash
# Lists Dockerfiles that still use the legacy health-check layer (< v0.4.0)

set -euo pipefail
grep -R --exclude-dir='.git' --exclude='*.md' \
     -E 'ghcr\.io/alfred/healthcheck:(0\.3|0\.2|0\.1)' services \
     | cut -d: -f1 \
     | sort -u
