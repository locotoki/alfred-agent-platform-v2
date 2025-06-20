FROM python:3.12-slim
WORKDIR /app
COPY . .
RUN pip install --no-cache-dir fastapi uvicorn openai asyncpg redis nats-py pydantic slowapi
EXPOSE 8087
CMD ["uvicorn", "bizdev_app:app", "--host", "0.0.0.0", "--port", "8087"]
