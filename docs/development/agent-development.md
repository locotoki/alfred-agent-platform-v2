# Agent Development Guide

## Creating a New Agent

This guide walks through creating a new agent for the Alfred Agent Platform.

### 1. Define the Agent

Create a new directory under `agents/`:

```bash
mkdir -p agents/market_analyzer
```

### 2. Implement the Agent

Create `agents/market_analyzer/agent.py`:

```python
from libs.agent_core import BaseAgent
from libs.a2a_adapter import A2AEnvelope
from typing import Dict, Any

class MarketAnalyzerAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="market-analyzer",
            version="1.0.0",
            supported_intents=["ANALYZE_MARKET", "MARKET_FORECAST"]
        )

    async def process_task(self, envelope: A2AEnvelope) -> Dict[str, Any]:
        if envelope.intent == "ANALYZE_MARKET":
            return await self._analyze_market(envelope)
        elif envelope.intent == "MARKET_FORECAST":
            return await self._forecast_market(envelope)

    async def _analyze_market(self, envelope: A2AEnvelope) -> Dict[str, Any]:
        # Implement market analysis logic
        pass

    async def _forecast_market(self, envelope: A2AEnvelope) -> Dict[str, Any]:
        # Implement forecasting logic
        pass
```

### 3. Create the Service

Create the service directory:

```bash
mkdir -p services/market-analyzer
```

Create `services/market-analyzer/Dockerfile`:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
COPY --from=build-context libs /app/libs

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

EXPOSE 8012

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8012"]
```

### 4. Update Docker Compose

Add your service to `docker-compose.yml`:

```yaml
market-analyzer:
  build:
    context: ./services/market-analyzer
    dockerfile: Dockerfile
  container_name: market-analyzer
  ports:
    - "8012:8012"
  environment:
    - ENVIRONMENT=${ENVIRONMENT}
    - DATABASE_URL=${DATABASE_URL}
    - PUBSUB_EMULATOR_HOST=${PUBSUB_EMULATOR_HOST}
    - OPENAI_API_KEY=${OPENAI_API_KEY}
  depends_on:
    - supabase-db
    - pubsub-emulator
  networks:
    - alfred-network
```

### 5. Add Tests

Create test files under `tests/unit/agents/test_market_analyzer.py`.

### 6. Update CI/CD

Add your service to the build matrix in `.github/workflows/ci.yml`.

## Best Practices

1. **Error Handling**: Always handle errors gracefully and update task status
2. **Logging**: Use structured logging with context
3. **Testing**: Write comprehensive unit and integration tests
4. **Documentation**: Document all public methods and APIs
5. **Metrics**: Export relevant metrics for monitoring
