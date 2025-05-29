# Environment Variables Documentation

This document provides a comprehensive guide to all environment variables used in the Alfred Agent Platform v2. Understanding these variables is crucial for proper configuration and troubleshooting of the platform.

## Core Settings

| Variable | Required | Default | Used By | Description |
|----------|----------|---------|---------|-------------|
| `ALFRED_ENVIRONMENT` | Yes | `development` | All services | Determines the runtime environment. Valid values: `development`, `production`, `test`. Controls logging verbosity, feature availability, and security settings. |
| `ALFRED_DEBUG` | No | `false` | All services | When set to `true`, enables additional debug logging and development features. Should be `false` in production. |
| `ALFRED_PROJECT_ID` | Yes | `alfred-agent-platform` | Core services, PubSub | Unique identifier for the project, used for PubSub topic/subscription naming and service discovery. |

## Database Settings

| Variable | Required | Default | Used By | Description |
|----------|----------|---------|---------|-------------|
| `POSTGRES_PASSWORD` | Yes | `postgres` | PostgreSQL container | Password for the PostgreSQL database. **CRITICAL**: Change in production! |
| `POSTGRES_USER` | Yes | `postgres` | PostgreSQL container | Username for the PostgreSQL database. |
| `POSTGRES_DB` | Yes | `postgres` | PostgreSQL container | Default database name to create on startup. |
| `DATABASE_URL` | Yes | `postgresql://postgres:postgres@db-postgres:5432/postgres` | social-intel, rag-service | Primary connection string for PostgreSQL. **CRITICAL**: Required by multiple services including social-intel agent. Connection failures will cause service outages. |
| `ALFRED_DATABASE_URL` | Yes | Same as `DATABASE_URL` | agent-core, alfred-bot | Alternative connection string with the ALFRED_ prefix for some services. Must match `DATABASE_URL`. |
| `DB_JWT_SECRET` | Yes | `jwt-secret-for-development-only` | db-api, storage | Secret used to sign JWT tokens for database access. **CRITICAL**: Change in production! |
| `ANON_KEY` | Yes | *example JWT token* | client applications | JWT token for anonymous database access. Used by frontend applications. |
| `SERVICE_ROLE_KEY` | Yes | *example JWT token* | backend services | JWT token with elevated privileges for backend services. |
| `ALFRED_SUPABASE_URL` | Yes | `http://db-api:3000` | agent-core, storage-api | URL of the Supabase instance. |
| `ALFRED_SUPABASE_KEY` | Yes | `${SERVICE_ROLE_KEY}` | agent-core, storage-api | Authentication key for Supabase access. Uses the SERVICE_ROLE_KEY by default. |

## Authentication Settings

| Variable | Required | Default | Used By | Description |
|----------|----------|---------|---------|-------------|
| `SITE_URL` | Yes | `http://localhost:3000` | Authentication service | Base URL of the application for authentication callbacks. |
| `ADDITIONAL_REDIRECT_URLS` | No | `http://localhost:3000/auth/callback,http://localhost:3003/auth/callback` | Authentication service | Comma-separated list of additional URLs allowed for authentication callbacks. |
| `DISABLE_SIGNUP` | No | `false` | Authentication service | When true, disables new user registration. |
| `JWT_EXPIRY` | No | `3600` | Authentication service | Token expiration time in seconds (default: 1 hour). |

## Cache & Messaging Settings

| Variable | Required | Default | Used By | Description |
|----------|----------|---------|---------|-------------|
| `REDIS_URL` | Yes | `redis://redis:6379` | agent-core, alfred-bot, social-intel | Connection string for Redis cache server. Used for caching, session storage, and rate limiting. |
| `ALFRED_REDIS_URL` | Yes | Same as `REDIS_URL` | All ALFRED_ prefixed services | Alternative connection string with ALFRED_ prefix. Must match `REDIS_URL`. |
| `PUBSUB_EMULATOR_HOST` | Yes | `pubsub-emulator:8085` | agent-orchestrator, social-intel | Hostname for the PubSub emulator in dev environments. |
| `ALFRED_PUBSUB_EMULATOR_HOST` | Yes | Same as `PUBSUB_EMULATOR_HOST` | All ALFRED_ prefixed services | Alternative PubSub host with ALFRED_ prefix. |
| `GOOGLE_CLOUD_PROJECT` | Yes | `alfred-agent-platform` | PubSub clients | Google Cloud project ID for PubSub topic/subscription naming. |
| `GOOGLE_APPLICATION_CREDENTIALS` | Yes | `/tmp/empty-credentials.json` | PubSub clients | Path to GCP credentials file. Uses empty credentials with emulator in dev. |

## External Service Credentials

| Variable | Required | Default | Used By | Description |
|----------|----------|---------|---------|-------------|
| `OPENAI_API_KEY` | Yes for OpenAI models | `sk-mock-key-for-development-only` | model-router, agent-core | API key for OpenAI services. Required for GPT models. Mock key used in dev with simulated responses. |
| `ALFRED_OPENAI_API_KEY` | Yes for OpenAI models | Same as `OPENAI_API_KEY` | All ALFRED_ prefixed services | Alternative API key with ALFRED_ prefix. Must match `OPENAI_API_KEY`. |
| `ALFRED_ANTHROPIC_API_KEY` | No | Empty | model-router | API key for Anthropic services. Required for Claude models. |
| `SLACK_BOT_TOKEN` | Yes for Slack integration | `placeholder-token` | alfred-bot | Bot token for Slack integration. Format: `xoxb-*` |
| `SLACK_SIGNING_SECRET` | Yes for Slack integration | `placeholder-secret` | alfred-bot | Signing secret for Slack API validation. |
| `ALFRED_SLACK_BOT_TOKEN` | Yes for Slack integration | Same as `SLACK_BOT_TOKEN` | alfred-bot | Alternative token with ALFRED_ prefix. Must match `SLACK_BOT_TOKEN`. |
| `ALFRED_SLACK_SIGNING_SECRET` | Yes for Slack integration | Same as `SLACK_SIGNING_SECRET` | alfred-bot | Alternative secret with ALFRED_ prefix. Must match `SLACK_SIGNING_SECRET`. |
| `YOUTUBE_API_KEY` | Yes for social-intel | `youtube-mock-key-for-development-only` | social-intel | YouTube Data API key. **CRITICAL** for social intelligence workflows. |
| `ALFRED_YOUTUBE_API_KEY` | Yes for social-intel | Same as `YOUTUBE_API_KEY` | social-intel | Alternative key with ALFRED_ prefix. Must match `YOUTUBE_API_KEY`. |

## SMTP Configuration (Optional)

| Variable | Required | Default | Used By | Description |
|----------|----------|---------|---------|-------------|
| `SMTP_HOST` | No | `mail-server` | Notification services | SMTP server hostname for sending emails. |
| `SMTP_PORT` | No | `1025` | Notification services | SMTP server port. Default is for development mail server. |
| `SMTP_USER` | No | Empty | Notification services | SMTP authentication username. |
| `SMTP_PASS` | No | Empty | Notification services | SMTP authentication password. |
| `SMTP_ADMIN_EMAIL` | No | `admin@example.com` | Notification services | Admin email for notifications and alerts. |
| `SMTP_SENDER_NAME` | No | `Alfred Platform` | Notification services | Display name for outgoing emails. |

## Service URLs

| Variable | Required | Default | Used By | Description |
|----------|----------|---------|---------|-------------|
| `MODEL_REGISTRY_URL` | Yes | `http://model-registry:8079` | model-router, agent-core | URL for the model registry service. |
| `ALFRED_MODEL_ROUTER_URL` | Yes | `http://model-router:8080` | All services using LLMs | URL for the model router service that handles LLM requests. |
| `ALFRED_API_URL` | Yes | `http://agent-core:8011` | Frontend, agent-orchestrator | URL for the agent core API. |
| `ALFRED_RAG_URL` | Yes | `http://agent-rag:8501` | agent-core, social-intel | URL for the RAG (Retrieval Augmented Generation) service. |
| `ALFRED_RAG_API_KEY` | Yes | `social-key` | agent-core, social-intel | API key for RAG service authentication. |
| `ALFRED_RAG_COLLECTION` | Yes | `social-knowledge` | agent-core, social-intel | Default collection for RAG service. |
| `NEXT_PUBLIC_SOCIAL_INTEL_URL` | Yes | `http://agent-social:9000` | Frontend | URL for the Social Intelligence service. Frontend-accessible. |
| `SOCIAL_INTEL_URL` | Yes | `http://agent-social:9000` | agent-orchestrator | URL for the Social Intelligence service. Backend-accessible. |
| `SOCIAL_INTEL_SERVICE_URL` | Yes | Same as `SOCIAL_INTEL_URL` | agent-orchestrator | Alternative URL for the Social Intelligence service. |
| `NEXT_PUBLIC_SERVER_URL` | Yes | `http://localhost:3000` | Frontend | Base URL for frontend access to the server. |
| `NEXT_PUBLIC_API_BASE_URL` | Yes | `http://localhost:8011` | Frontend | Base URL for frontend access to the API. |

## LLM/AI Configuration

| Variable | Required | Default | Used By | Description |
|----------|----------|---------|---------|-------------|
| `LANGSMITH_API_KEY` | No | `ls-your-langsmith-api-key` | agent-core, model-router | API key for LangSmith service. Used for LLM observability. |
| `LANGCHAIN_TRACING_V2` | No | `true` | LangChain components | Enables v2 tracing in LangChain. |
| `LANGCHAIN_ENDPOINT` | No | `http://langsmith:1984` | LangChain components | Endpoint for LangChain tracing server. |
| `LANGCHAIN_PROJECT` | No | `alfred-platform` | LangChain components | Project name for LangChain traces. |

## UI Configuration

| Variable | Required | Default | Used By | Description |
|----------|----------|---------|---------|-------------|
| `STREAMLIT_SERVER_HEADLESS` | Yes | `true` | ui-chat | **CRITICAL**: Must be true for containerized Streamlit services. Prevents browser auto-launch. |
| `STREAMLIT_BROWSER_GATHER_USAGE_STATS` | No | `false` | ui-chat | Disables usage statistics gathering in Streamlit. |
| `ENABLE_DIRECT_INFERENCE` | No | `true` | ui-chat | Enables direct model inference from the UI. |
| `NODE_ENV` | Yes | `production` | Frontend services | Node.js environment. Valid values: `development`, `production`, `test`. |

## Monitoring & Security

| Variable | Required | Default | Used By | Description |
|----------|----------|---------|---------|-------------|
| `GRAFANA_ADMIN_PASSWORD` | Yes | `admin` | Grafana | Admin password for Grafana monitoring dashboard. **CRITICAL**: Change in production! |
| `PROMETHEUS_RETENTION_TIME` | No | `15d` | Prometheus | Data retention period for Prometheus metrics. |
| `MONITORING_ADMIN_PASSWORD` | Yes | `admin` | Monitoring dashboard | Password for monitoring admin access. **CRITICAL**: Change in production! |
| `API_KEY_SALT` | Yes | `salt-for-development-only` | Authentication | Salt for hashing API keys. **CRITICAL**: Change in production! |
| `ENCRYPTION_KEY` | Yes | `32-byte-encryption-key-for-dev-only` | Encryption services | Key for encrypting sensitive data. **CRITICAL**: Change in production! |

## Feature Flags

| Variable | Required | Default | Used By | Description |
|----------|----------|---------|---------|-------------|
| `ENABLE_EMAIL_SIGNUP` | No | `true` | Authentication | Enables user registration via email. |
| `ENABLE_EMAIL_AUTOCONFIRM` | No | `true` | Authentication | Automatically confirms email registrations without verification. Set to `false` in production. |
| `ENABLE_ANONYMOUS_SIGN_INS` | No | `false` | Authentication | Allows anonymous authentication. |
| `RATE_LIMIT_PER_MINUTE` | No | `60` | API services | Rate limiting for API requests per minute per client. |
| `RATE_LIMIT_PER_HOUR` | No | `1000` | API services | Rate limiting for API requests per hour per client. |

## Troubleshooting Common Issues

### Missing DATABASE_URL
If services like social-intel fail with database connection errors, ensure DATABASE_URL is properly set in your environment or in docker-compose.override.yml for that service.

### UI-Chat Restart Loop
If ui-chat continuously restarts, ensure STREAMLIT_SERVER_HEADLESS=true is set. This prevents Streamlit from trying to open a browser in containerized environments.

### Service Discovery Failures
If services can't communicate, check the service URLs configuration. Docker service names must match the hostnames in URL variables (e.g., `http://agent-social:9000`).

### Authentication Errors
For JWT authentication errors, ensure DB_JWT_SECRET, ANON_KEY, and SERVICE_ROLE_KEY are consistent across all services.

## Environment Variable Best Practices

1. **Never use production secrets in development or test environments**
2. **Use docker-compose.override.yml for service-specific environment variables**
3. **Keep a backup of your production .env file in a secure location**
4. **Regularly rotate sensitive credentials like API keys**
5. **Use the validation script before deployment to catch configuration issues**
   ```bash
   ./scripts/validate-env.sh
   ```
