FROM ghcr.io/alfred/healthcheck:0.3.1 AS healthcheck

FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    wget \
    gcc \
    python3-dev \
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code and initialization scripts
COPY ./app /app/app
COPY init-db.sql /app/
COPY init-db.sh /app/
RUN chmod +x /app/init-db.sh
n# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck


# Expose the service port
EXPOSE 8079

# Command to run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8079"]