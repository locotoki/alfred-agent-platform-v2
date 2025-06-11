# Vector-ingest service with full ML functionality
FROM alfred-python-ml:latest

WORKDIR /app

# Copy files as root first
COPY worker.py.backup worker.py
COPY requirements.txt* ./

# Install any additional service-specific dependencies as root
USER root
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt || true; fi

# Fix permissions and switch to non-root user
RUN chown -R alfred:alfred /app
USER alfred

ENV PYTHONUNBUFFERED=1
EXPOSE 8000
CMD ["python", "worker.py"]