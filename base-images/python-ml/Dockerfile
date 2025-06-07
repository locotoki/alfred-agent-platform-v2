# ML-enabled Python base image for Alfred services
# Includes heavy ML dependencies pre-built for fast cold-start
FROM python:3.11-slim AS base

# Set environment variables
ENV PIP_ROOT_USER_ACTION=ignore
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Update base packages and install system dependencies for ML
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    curl \
    wget \
    gcc \
    g++ \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Upgrade pip and setuptools
RUN pip install --upgrade --no-cache-dir \
    setuptools>=75.0.0 \
    pip>=24.3.0

# Install common Python packages
RUN pip install --no-cache-dir \
    fastapi>=0.110.2 \
    uvicorn[standard]>=0.29.0 \
    structlog>=24.1.0 \
    prometheus-client>=0.20.0 \
    httpx>=0.24.1 \
    tenacity>=8.2.0 \
    requests \
    cloudevents

# Pre-install heavy ML dependencies
# Install torch first with CPU-only version
RUN pip install --no-cache-dir torch --index-url https://download.pytorch.org/whl/cpu

# Then install other ML dependencies
RUN pip install --no-cache-dir \
    numpy \
    transformers \
    sentence-transformers>=2.2.0

# Install langchain separately with more lenient approach
RUN pip install --no-cache-dir langchain || echo "langchain not found, trying alternatives"
RUN pip install --no-cache-dir langchain-text-splitters || echo "langchain-text-splitters not found"

# Create app directory and non-root user
WORKDIR /app
RUN groupadd -r alfred && useradd -r -g alfred alfred

# Security hardening
RUN chmod -R go-rwx /app && \
    chown -R alfred:alfred /app

# Pre-download the default model to speed up cold-start
RUN python -c "from sentence_transformers import SentenceTransformer; SentenceTransformer('sentence-transformers/all-MiniLM-L6-v2')"

# Switch to non-root user
USER alfred

# Set secure defaults
EXPOSE 8000
WORKDIR /app

# Default healthcheck template
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1