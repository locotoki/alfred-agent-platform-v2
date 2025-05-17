# Environment Setup Guide

This guide will help you properly configure your environment variables for the Alfred Agent Platform v2.

## Quick Start

1. Copy the example environment file:
   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file with your actual credentials:
   ```bash
   nano .env
   ```

3. Validate your environment configuration:
   ```bash
   ./scripts/validate-env.sh
   ```

4. Start the platform:
   ```bash
   ./start-platform.sh
   ```

## Critical Variables

The following variables are **critical** and must be set correctly:

- `DATABASE_URL`: Required by multiple services, especially social-intel
- `ALFRED_OPENAI_API_KEY`: Required for OpenAI models (if using them)
- `YOUTUBE_API_KEY`: Required for social-intel service
- `STREAMLIT_SERVER_HEADLESS`: Must be set to `true` for ui-chat service

## Environment Configuration By Service

### Core Services

For the base platform to function, configure:
- `ALFRED_ENVIRONMENT`
- `DATABASE_URL`
- `REDIS_URL`
- `ALFRED_MODEL_ROUTER_URL`

### Social Intelligence Agent

For the social-intel service to work properly:
- `DATABASE_URL` must point to a valid PostgreSQL instance
- `YOUTUBE_API_KEY` must be a valid YouTube Data API key
- `SOCIAL_INTEL_URL` must be accessible by other services

### Model Router

For AI/LLM functionality:
- `ALFRED_OPENAI_API_KEY` for OpenAI models
- `ALFRED_ANTHROPIC_API_KEY` for Claude models
- `MODEL_REGISTRY_URL` for model discovery

### UI and Frontend

For the user interfaces to work correctly:
- `NEXT_PUBLIC_SERVER_URL` for frontend access
- `NEXT_PUBLIC_API_BASE_URL` for API access from frontend
- `STREAMLIT_SERVER_HEADLESS=true` for Streamlit UI

## Using Docker Compose Overrides

For service-specific environment variables, use Docker Compose override files.

Create a file like `docker-compose.override.service-name.yml`:

```yaml
services:
  service-name:
    environment:
      - VARIABLE_NAME=value
      - ANOTHER_VARIABLE=another_value
```

These overrides will be automatically included when you use:
```bash
./start-platform.sh -f docker-compose.yml -f docker-compose.override.service-name.yml
```

## Testing External Services

To test if your external service credentials are working:

```bash
# Test OpenAI API Key
curl -s -H "Authorization: Bearer $ALFRED_OPENAI_API_KEY" https://api.openai.com/v1/models

# Test YouTube API Key
curl -s "https://www.googleapis.com/youtube/v3/search?part=snippet&q=test&key=$YOUTUBE_API_KEY&maxResults=1"
```

## Troubleshooting

If you encounter issues:

1. Check the environment validation output:
   ```bash
   ./scripts/validate-env.sh
   ```

2. Verify service-specific logs:
   ```bash
   docker-compose logs service-name
   ```

3. For database connection issues, ensure:
   - PostgreSQL is running
   - DATABASE_URL is correctly formatted
   - The database exists and is accessible

4. For service discovery issues, check:
   - Service URLs are using correct hostnames (docker service names)
   - All services are healthy (`docker-compose ps`)

See the full [Environment Variables Documentation](ENVIRONMENT_VARIABLES.md) for detailed information about all variables.