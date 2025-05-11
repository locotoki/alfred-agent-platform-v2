# Alfred Agent Platform v2

A scalable, modular AI agent platform built with Docker, Supabase, and Pub/Sub messaging.

## Features

- 🤖 Multiple AI agents with LangChain and LangGraph
- 📨 Event-driven architecture with Google Cloud Pub/Sub
- 🗄️ State management with Supabase (PostgreSQL + pgvector)
- 🔍 Vector search with Qdrant
- 🎯 Real-time updates via Supabase Realtime
- 📊 Comprehensive monitoring with Prometheus and Grafana
- 🔒 Built-in security with rate limiting and PII scrubbing
- 🚀 Local-first development with Docker Compose

## Available Agents

- **Alfred Bot**: Slack interface for platform interaction
- **Social Intelligence**: Social media trend analysis and monitoring
- **Legal Compliance**: Regulatory compliance checking and monitoring
- **Financial-Tax**: Tax calculations, financial analysis, and compliance

## Quick Start

### Prerequisites

- Docker Engine 25.0+
- Docker Compose v2
- Python 3.11+
- NVIDIA GPU with drivers (for local LLM)
- Git and Git LFS

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/alfred-agent-platform-v2.git
   cd alfred-agent-platform-v2
   ```

2. Initialize the environment:
   ```bash
   make init
   ```

3. Configure your environment:
   ```bash
   cp .env.example .env
   # Edit .env with your settings
   ```

4. Start the platform:
   ```bash
   make setup
   ```

5. Access the services:
   - Supabase Studio: http://localhost:3001
   - Mission Control UI: http://localhost:3007
   - Grafana: http://localhost:3002
   - Prometheus: http://localhost:9090
   - Financial-Tax API: http://localhost:9003/docs
   - Social Intelligence API: http://localhost:9000/docs

## Development

### Running Tests

```bash
# Run all tests
make test

# Run specific test types
make test-unit
make test-integration
make test-e2e
```

### Code Quality

```bash
# Format code
make format

# Run linters
make lint
```

### Adding a New Agent

1. Create agent directory:
   ```bash
   mkdir -p agents/new_agent
   ```

2. Implement agent logic inheriting from `BaseAgent`
3. Create Docker service in `services/new-agent`
4. Add to `docker-compose.yml`
5. Update CI/CD matrix

## Architecture

The platform follows an event-driven microservices architecture:

- **Entry Points**: Slack bot, API endpoints
- **Message Bus**: Google Cloud Pub/Sub
- **State Storage**: Supabase (PostgreSQL)
- **Vector Search**: Qdrant
- **Agent Framework**: LangChain + LangGraph
- **Monitoring**: Prometheus + Grafana

## Configuration

### Environment Variables

Key environment variables:

- `ENVIRONMENT`: Development/staging/production
- `DATABASE_URL`: PostgreSQL connection string
- `PUBSUB_EMULATOR_HOST`: Pub/Sub emulator address
- `OPENAI_API_KEY`: OpenAI API key
- `SLACK_BOT_TOKEN`: Slack bot token

See `.env.example` for full list.

### Database Migrations

```bash
# Run migrations
make db-migrate

# Reset database (CAUTION: deletes all data)
make db-reset
```

## Deployment

### Local Development

```bash
# Start all services with Docker Compose
docker-compose -f docker-compose.dev.yml up

# Start in detached mode (background)
docker-compose -f docker-compose.dev.yml up -d

# Start just specific services
docker-compose -f docker-compose.dev.yml up slack-bot mission-control

# View logs
docker-compose -f docker-compose.dev.yml logs -f

# Stop all services
docker-compose -f docker-compose.dev.yml down
```

The docker-compose.dev.yml file includes:
- Slack Bot: http://localhost:8011
- Mission Control: http://localhost:8012
- RAG Gateway: http://localhost:8013
- WhatsApp Adapter: http://localhost:8014
- Streamlit Chat (dev-only): http://localhost:8501
- Redis
- Supabase (PostgreSQL)

### Staging Deployment

```bash
# Triggered automatically on push to develop branch
```

### Production Deployment

```bash
# Triggered automatically on push to main branch
```

## Monitoring

Access monitoring dashboards:

```bash
make monitor
```

- Grafana: http://localhost:3002 (admin/admin)
- Prometheus: http://localhost:9090

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
