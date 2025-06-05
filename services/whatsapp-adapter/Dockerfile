FROM python:3.11-slim
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends curl && \
    pip install --no-cache-dir fastapi uvicorn 'uvicorn[standard]'
COPY src/ ./src/
CMD ["uvicorn", "src.app:app", "--host", "0.0.0.0", "--port", "8080"]