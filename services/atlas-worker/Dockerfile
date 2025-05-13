FROM ghcr.io/alfred/healthcheck:0.3.1 AS healthcheck

FROM python:3.11-slim
ENV PIP_ROOT_USER_ACTION=ignore
WORKDIR /app

# Install necessary packages for building
RUN apt-get update && apt-get install -y gcc git curl && rm -rf /var/lib/apt/lists/*

# Install dependencies directly - using compatible versions
# httpx version set to 0.24.1 to be compatible with both OpenAI and Supabase
RUN pip install --no-cache-dir \
n# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck

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

# Health check
HEALTHCHECK --interval=30s --timeout=3s CMD curl -f http://localhost:8000/healthz || exit 1

# Run the application
CMD ["python", "-m", "atlas.main"]