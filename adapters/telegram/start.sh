#!/bin/sh
set -e

# Export environment variables for Prometheus multiprocess mode
export PROMETHEUS_MULTIPROC_DIR=/tmp/prometheus

# Start the application
exec python -m uvicorn app:app --host 0.0.0.0 --port ${PORT:-8080}
