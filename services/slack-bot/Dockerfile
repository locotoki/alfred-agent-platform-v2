FROM python:3.12-slim
RUN apt-get update && apt-get install -y redis-server curl && rm -rf /var/lib/apt/lists/*
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ /app
WORKDIR /app
ENTRYPOINT ["bash", "-c", "redis-server --daemonize yes && uvicorn bot:app --host 0.0.0.0 --port 8000"]
HEALTHCHECK CMD curl -sf http://localhost:8000/health || exit 1
