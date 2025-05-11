FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY . .

# Create empty src directory if it doesn't exist
RUN mkdir -p src

# Create a minimal app.py if it doesn't exist
RUN if [ ! -f src/app.py ]; then \
    echo 'import os\nimport logging\n\nlogging.basicConfig(level=logging.INFO)\nlogger = logging.getLogger(__name__)\n\nport = int(os.environ.get("PORT", 8011))\n\nif __name__ == "__main__":\n    logger.info(f"Starting Slack Bot on port {port}")\n    logger.info(f"Using Slack token: {os.environ.get("SLACK_BOT_TOKEN", "Not set")[0:5]}...")' > src/app.py; \
    fi

# Create an empty requirements.txt if it doesn't exist
RUN if [ ! -f requirements.txt ]; then \
    echo 'flask==2.2.3\nslack-sdk==3.21.3\nredis==4.5.4\n' > requirements.txt; \
    pip install --no-cache-dir -r requirements.txt; \
    fi

EXPOSE 8011

CMD ["python", "-m", "src.app"]