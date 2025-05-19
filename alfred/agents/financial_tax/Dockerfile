FROM alfred/healthcheck:0.4.0 AS healthcheck

FROM python:3.11-slim
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
COPY requirements-dev.txt .
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install --no-cache-dir -r requirements-dev.txt

# Copy application code
COPY app app/

# Copy shared libraries and agents - Using volume mount approach
# These will be mounted at runtime using docker-compose volumes

# Healthcheck is handled by the healthcheck binary

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Expose port
EXPOSE 9003
EXPOSE 9091

# Run the application with healthcheck wrapper
CMD ["healthcheck", "--export-prom", ":9091", "--", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "9003"]
