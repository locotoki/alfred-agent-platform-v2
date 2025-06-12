FROM ghcr.io/locotoki/alfred-agent-platform-v2/healthcheck:0.4.0 AS healthcheck

FROM python:3.11-slim
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

WORKDIR /app

# Install curl for health checks
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && rm -rf /var/lib/apt/lists/*

# Create minimal requirements.txt
RUN echo "fastapi==0.104.1" > requirements.txt && \
    echo "uvicorn==0.24.0" >> requirements.txt

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Create minimal RAG gateway stub
RUN echo 'from fastapi import FastAPI' > main.py && \
    echo 'app = FastAPI(title="RAG Gateway Stub")' >> main.py && \
    echo '@app.get("/health")' >> main.py && \
    echo 'def health(): return {"status": "healthy", "service": "rag-gateway-stub"}' >> main.py && \
    echo '@app.get("/")' >> main.py && \
    echo 'def root(): return {"message": "RAG Gateway Stub - Service under development"}' >> main.py

# Expose application port
EXPOSE 8080
# Expose metrics port for Prometheus
EXPOSE 9091

# Start the application with healthcheck metrics exporter
CMD ["bash", "-c", "healthcheck serve --export-prom :9091 & exec uvicorn main:app --host 0.0.0.0 --port 8080"]