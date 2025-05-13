FROM ghcr.io/alfred/healthcheck:0.3.1 AS healthcheck

FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
n# Copy healthcheck binary
COPY --from=healthcheck /healthcheck /usr/local/bin/healthcheck


COPY . .

EXPOSE 8011

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8011"]