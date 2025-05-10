FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    ffmpeg \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages
RUN pip install --no-cache-dir \
    yt-dlp==2024.3.10 \
    youtube-search-python==1.6.6 \
    pytrends==4.9.0 \
    duckdb==0.9.2 \
    umap-learn==0.5.4 \
    scikit-learn==1.4.0 \
    sentence-transformers==2.2.2 \
    prefect==2.14.5 \
    pandas \
    matplotlib \
    qdrant-client==1.7.0

# Create test directory
RUN mkdir -p /app/test

# Set working directory
WORKDIR /app/test

# Command to keep container running
CMD ["bash", "-c", "echo 'YouTube test environment ready' && tail -f /dev/null"]