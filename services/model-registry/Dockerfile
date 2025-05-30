FROM python:3.11-slim

WORKDIR /app

# Install PostgreSQL client for database init
RUN apt-get update && \
    apt-get install -y postgresql-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY ./app /app/app
COPY ./init-db.sql /app/init-db.sql

# Initialize the database when container starts
RUN echo '#!/bin/bash \n\
if [ "$DATABASE_URL" ]; then \n\
  echo "Initializing database..." \n\
  # Simplify connection to just use regular PostgreSQL client \n\
  psql "postgresql://postgres:postgres@db-postgres:5432/postgres" -f /app/init-db.sql \n\
fi \n\
exec "$@"' > /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

# Set environment variables
ENV PYTHONPATH=/app
ENV PORT=8079

# Expose the application port
EXPOSE 8079

# Use the entrypoint script to run the application
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8079"]
