FROM python:3.11-slim

WORKDIR /app

# Install health check dependencies
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Expose port
EXPOSE 8095

# Run the mock server
CMD ["python", "-m", "uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8095"]
