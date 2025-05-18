FROM alfred/healthcheck:0.4.0 AS healthcheck
FROM python:3.9-slim
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck

WORKDIR /app

# Install wget for health check
RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Add health check
HEALTHCHECK --interval=30s --timeout=20s --start-period=45s --retries=5 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:9103/healthz || exit 1

# Expose metrics port
EXPOSE 9103
EXPOSE 9091
#  Metrics port

# Start the server
CMD ["healthcheck", "--export-prom", ":9091", "--", "python", "app.py"]
