FROM alfred/healthcheck:0.4.0 AS healthcheck

FROM python:3.11-slim
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app app/

# Copy shared libraries and agents - Using volume mount approach
# These will be mounted at runtime using docker-compose volumes

# Create fallback healthcheck script
RUN echo '#!/bin/bash\nset -e\n\ncurl -f -s http://localhost:9002/health > /dev/null || exit 1\nexit 0' > /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Expose port
EXPOSE 9002
EXPOSE 9091

# Run the application with healthcheck wrapper
CMD ["healthcheck", "--export-prom", ":9091", "--", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "9002"]
