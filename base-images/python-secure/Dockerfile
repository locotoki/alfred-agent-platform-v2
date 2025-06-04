# Security-hardened Python base image for Alfred services
# Addresses known CVEs and implements security best practices
FROM python:3.11-slim AS base

# Set environment variables
ENV PIP_ROOT_USER_ACTION=ignore
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Update base packages to patch known CVEs
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    wget \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Upgrade setuptools to patch CVE-2024-6345 and CVE-2025-47273
RUN pip install --upgrade --no-cache-dir \
    setuptools>=75.0.0 \
    pip>=24.3.0

# Install common Python packages with security considerations
RUN pip install --no-cache-dir \
    fastapi>=0.110.2 \
    uvicorn[standard]>=0.29.0 \
    structlog>=24.1.0 \
    prometheus-client>=0.20.0 \
    httpx>=0.24.1 \
    tenacity>=8.2.0

# Create app directory and non-root user
WORKDIR /app
RUN groupadd -r alfred && useradd -r -g alfred alfred

# Security hardening
RUN chmod -R go-rwx /app && \
    chown -R alfred:alfred /app

# Create health check directory
RUN mkdir -p /usr/local/bin && \
    chmod 755 /usr/local/bin

# Disable unnecessary services and reduce attack surface
USER alfred

# Set secure defaults
EXPOSE 8000
WORKDIR /app

# Default healthcheck template
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1