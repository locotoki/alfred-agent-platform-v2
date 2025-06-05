FROM python:3.11-slim
WORKDIR /app
RUN pip install --no-cache-dir langchain sentence-transformers cloudevents requests
COPY worker.py .
CMD ["python", "worker.py"]