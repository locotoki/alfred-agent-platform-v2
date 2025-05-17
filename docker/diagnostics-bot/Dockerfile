# Dockerfile for Slack diagnostics bot
FROM python:3.11-slim

# Environment configuration
ENV PYTHONUNBUFFERED=1 \
    POETRY_NO_INTERACTION=1

WORKDIR /app

# Install poetry and dependencies
COPY pyproject.toml poetry.lock /app/
RUN pip install poetry && \
    poetry config virtualenvs.create false && \
    poetry install --only main --no-interaction --no-ansi

# Copy application code
COPY alfred /app/alfred

# Run the diagnostics bot
CMD ["python", "-m", "alfred.slack.diagnostics"]