# SPDX-License-Identifier: Apache-2.0
FROM ghcr.io/alfred/healthcheck:0.4.0 AS healthcheck

FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck

COPY app/ app/
COPY clients/ clients/

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

EXPOSE 8000
# Expose metrics port for Prometheus
EXPOSE 9091

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/healthz || exit 1

# Start the application with healthcheck metrics exporter
# DO NOT REMOVE --export-prom FLAG - Required for Prometheus metrics collection
CMD ["bash", "-c", "healthcheck serve --export-prom :9091 & exec uvicorn app.main:app --host 0.0.0.0 --port 8000"]
