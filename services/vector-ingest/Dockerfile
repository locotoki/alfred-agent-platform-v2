FROM python:3.11-slim
WORKDIR /app
# Security: Update base packages
RUN apt-get update && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir --upgrade pip
# Only add FastAPI for now - remove heavy ML deps to test service first
RUN pip install --no-cache-dir fastapi uvicorn[standard] requests
COPY worker.py .
# Security: Run as non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
RUN chown -R appuser:appgroup /app
USER appuser
CMD ["python", "worker.py"]