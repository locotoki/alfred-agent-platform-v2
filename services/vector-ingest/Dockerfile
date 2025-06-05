FROM python:3.11-slim
WORKDIR /app
# Security: Update base packages
RUN apt-get update && apt-get upgrade -y && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir langchain sentence-transformers cloudevents requests
COPY worker.py .
# Security: Run as non-root user
RUN groupadd -r appgroup && useradd -r -g appgroup appuser
RUN chown -R appuser:appgroup /app
USER appuser
CMD ["python", "worker.py"]