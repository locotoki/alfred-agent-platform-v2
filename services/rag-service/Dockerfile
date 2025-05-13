FROM ghcr.io/alfred/healthcheck:0.4.0 AS healthcheck

FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck

# Copy source code
COPY . .

# Expose application port
EXPOSE 8501
# Expose metrics port for Prometheus
EXPOSE 9091

# Start the application with healthcheck metrics exporter
# DO NOT REMOVE --export-prom FLAG - Required for Prometheus metrics collection
CMD ["bash", "-c", "healthcheck serve --export-prom :9091 & exec uvicorn app.main:app --host 0.0.0.0 --port 8501"]