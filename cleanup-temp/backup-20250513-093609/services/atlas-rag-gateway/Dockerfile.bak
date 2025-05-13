FROM python:3.11-slim
WORKDIR /app

# Install dependencies directly
RUN pip install --no-cache-dir \
    fastapi==0.110.0 \
    uvicorn[standard]==0.29.0 \
    qdrant-client==1.7.0 \
    sentence-transformers==2.6.0 \
    redis==5.0.1 \
    httpx==0.24.1 \
    prometheus-client==0.20.0

# Copy application code
COPY rag_gateway /app/rag_gateway

# Expose port
EXPOSE 8501

# Run the application
CMD ["uvicorn", "rag_gateway.main:app", "--host", "0.0.0.0", "--port", "8501"]