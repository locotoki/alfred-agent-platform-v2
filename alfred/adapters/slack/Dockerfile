FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Poetry
ENV POETRY_VERSION=1.7.1
ENV POETRY_HOME=/opt/poetry
ENV PATH="$POETRY_HOME/bin:$PATH"
RUN curl -sSL https://install.python-poetry.org | python3 -

# Copy dependency files
COPY pyproject.toml poetry.lock ./

# Configure Poetry for production
ENV POETRY_NO_INTERACTION=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1 \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache

# Install production dependencies only
RUN poetry install --only main --no-root && rm -rf $POETRY_CACHE_DIR

# Copy application code
COPY alfred/adapters/slack alfred/adapters/slack/
COPY alfred/adapters/__init__.py alfred/adapters/
COPY alfred/__init__.py alfred/

# Set Python path
ENV PYTHONPATH=/app

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/healthz || exit 1

# Run the application
EXPOSE 8000
CMD ["poetry", "run", "uvicorn", "alfred.adapters.slack.webhook:app", "--host", "0.0.0.0", "--port", "8000"]
