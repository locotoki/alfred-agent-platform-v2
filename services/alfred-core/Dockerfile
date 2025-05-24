FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
RUN pip install --no-cache-dir fastapi uvicorn structlog prometheus_client

# Copy service code
COPY ./app /app/app
COPY ./health.json /app/health.json
COPY ./healthcheck.sh /usr/local/bin/healthcheck.sh

# Make healthcheck script executable
RUN chmod +x /usr/local/bin/healthcheck.sh

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Expose application port and metrics port
EXPOSE 8011
EXPOSE 9091

# Run the application with metrics export
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8011"]
