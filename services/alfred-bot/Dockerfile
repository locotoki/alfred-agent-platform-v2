FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY ./services/alfred-bot/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY ./services/alfred-bot .

# Copy shared libraries
COPY ./libs /app/libs

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1
# Default to demo mode for easier testing without Slack credentials
ENV ALFRED_APP_MODULE="app.demo_mode:app"

# Expose port
EXPOSE 8011

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8011/health/ || exit 1

# Run the application with configurable module
CMD uvicorn ${ALFRED_APP_MODULE} --host 0.0.0.0 --port 8011
