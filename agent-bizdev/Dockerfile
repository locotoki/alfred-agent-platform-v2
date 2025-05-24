FROM python:3.11-slim
WORKDIR /app
COPY health.sh /health.sh
RUN chmod +x /health.sh
HEALTHCHECK CMD /health.sh
# tiny HTTP server so the container does something
CMD ["python", "-m", "http.server", "8080"]
