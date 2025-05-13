FROM ghcr.io/alfred/healthcheck:0.3.1 AS healthcheck

FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
n# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck


# Copy application code
COPY streamlit_chat_ui.py .
COPY .streamlit/ .streamlit/

# Expose the Streamlit default port
EXPOSE 8501

# Command to run the application
CMD ["streamlit", "run", "streamlit_chat_ui.py", "--server.port=8501", "--server.address=0.0.0.0"]