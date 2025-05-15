FROM alfred/healthcheck:0.4.0 AS healthcheck

FROM python:3.11-slim
ENV PIP_ROOT_USER_ACTION=ignore
WORKDIR /app

# Copy healthcheck binary from the first stage
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

# Install necessary packages for building and healthcheck
RUN apt-get update && apt-get install -y gcc git curl netcat-traditional && rm -rf /var/lib/apt/lists/*

# Install dependencies directly - using compatible versions
# httpx version set to 0.24.1 to be compatible with both OpenAI and Supabase
RUN pip install --no-cache-dir \
    openai==1.20.0 \
    fastapi==0.110.0 \
    google-cloud-pubsub==2.20.0 \
    httpx==0.24.1 \
    prometheus-client==0.20.0 \
    tenacity==8.2.0 \
    asyncio==3.4.3 \
    uvicorn[standard]==0.29.0 \
    supabase==2.0.1 \
    structlog==24.1.0

# Copy application code
COPY atlas /app/atlas

# Create libs directory if it doesn't exist yet
RUN mkdir -p /app/libs

# Create fallback healthcheck script
RUN echo '#!/bin/bash\nset -e\n\ncurl -f -s http://localhost:8000/health > /dev/null || exit 1\nexit 0' > /usr/local/bin/healthcheck.sh && \
    chmod +x /usr/local/bin/healthcheck.sh

# Expose application port and metrics port
EXPOSE 8000
EXPOSE 9091

# Run the application with healthcheck wrapper
CMD ["healthcheck", "--export-prom", ":9091", "--", "python", "-m", "atlas.main"]