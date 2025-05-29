FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY services/agent_bizops/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY workflows/ ./workflows/
COPY services/agent_bizops/app/ ./app/
COPY services/agent_bizops/middleware/ ./middleware/

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

# Run the application
CMD ["python", "-m", "app.main"]
