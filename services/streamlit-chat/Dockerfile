FROM python:3.11-slim

WORKDIR /app

# Install system dependencies including wget for health checks
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY streamlit_chat.py .
COPY streamlit_chat_ui.py .
COPY health_server.py .
COPY health_proxy.py .
COPY healthcheck-wrapper.sh .

# Make scripts executable
RUN chmod +x healthcheck-wrapper.sh health_proxy.py

# Install aiohttp for health proxy
RUN pip install --no-cache-dir aiohttp

# Expose ports
EXPOSE 8501
EXPOSE 8080

# Set environment variables
ENV ALFRED_API_URL=http://agent-core:8011
ENV ALFRED_MODEL_ROUTER_URL=http://model-router:8080
ENV ENABLE_DIRECT_INFERENCE=true

# Health check on the proxy port
HEALTHCHECK --interval=30s --timeout=10s --start-period=45s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Run the wrapper script
CMD ["./healthcheck-wrapper.sh"]