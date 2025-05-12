FROM python:3.11-slim

WORKDIR /app

# System dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    CREWAI_LOG_LEVEL=INFO

# Expose port
EXPOSE 9004
EXPOSE 9005

# Health check
HEALTHCHECK --interval=30s --timeout=10s --retries=3 --start-period=30s \
    CMD curl -f http://localhost:9004/health || exit 1

# Start application
CMD ["python", "-m", "crewai_service.main"]