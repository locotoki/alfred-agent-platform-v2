# CrewAI & n8n Integration Plan for Alfred Agent Platform

## 1. Executive Summary

This integration plan outlines how to incorporate CrewAI (multi-agent orchestration) and n8n (workflow automation) into the current Alfred Agent Platform architecture. It includes technical specifications, implementation steps, and compatibility considerations to ensure seamless integration with existing services.

## 2. Integration Architecture

![Integration Architecture](https://mermaid.ink/img/pako:eNqVVMtuwjAQ_JWVj0UCFYgEJw75gkrtpYeeLA9sYsFjR95NA1X57914oXnQHsrJ3p2dmZ1d-0IylSNJSUl5cCCaDFjEZ4xzoHnVRrRQLSP1vjJotV4QQWqcVahgdphhzlRx5rlPfTKuQSG8NxJ5XsB9Bnao8aSF1EQrXGjYA-uoxGbYqhPJNXCNrUWH4qDMi7b7I2eCKVGkWYgNWwEXMlf5N7Uw42LlZDLw-jbhEMlJLhgczXDGsN55qJKWrYGdjUYTmxXeVkl0C6gO3HEUt-jRRlfBpvbBN4u6ZKA7hJaQQzmZi7xkgZZwvsBP3hvxpXFc-yZQK9XeU6hzthdcMDLzojxr1gjpR7tJfBZcDzNT6gPk4kQmEDiXYBYULajSqRyX11QTTQGvHQY-N5lkl9NlOMGSPJ0n37CL4JGC6P3QnjPxEXxyNl7wA1b2OuDdN3cGG_fqDxBsb4M3yGm4N-3JK_YdLj-UXkkZ-ZQ-ky3p-r_SCylV5CPIuVZqJWmqJbzSqBTtMXHQdjzaQlDRH6VsZ7xJPpONH_NfgwPdIw?type=png)

### 2.1 Key Components

1. **CrewAI Service**
   - Custom Dockerized service running CrewAI framework
   - Manages agent teams ("crews") that can collaborate on complex tasks
   - Connects to existing agents via PubSub and API calls

2. **n8n Service**
   - Self-hosted workflow automation platform
   - Handles integration with external systems and orchestration
   - Provides visual workflow builder for no-code/low-code automation

3. **Integration Layer**
   - New PubSub topics for cross-service communication
   - Shared authentication mechanisms
   - Standardized data formats for interoperability

## 3. Implementation Phases

### 3.1 Containerization

#### CrewAI Service Dockerfile
```dockerfile
FROM python:3.11-slim

WORKDIR /app

# System dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Set environment variables
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    CREWAI_LOG_LEVEL=INFO

# Expose port
EXPOSE 9004

# Start application
CMD ["python", "-m", "crewai_service.main"]
```

#### n8n Docker Compose Stanza
```yaml
  workflow-n8n:
    image: n8nio/n8n:latest
    container_name: workflow-n8n
    restart: unless-stopped
    ports:
      - "5500:5678"
    environment:
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=${N8N_USER:-admin}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_PASSWORD:-alfred123}
      - N8N_HOST=${N8N_HOST:-localhost}
      - N8N_PORT=5678
      - N8N_PROTOCOL=${N8N_PROTOCOL:-http}
      - N8N_LOG_LEVEL=${N8N_LOG_LEVEL:-info}
      - GENERIC_TIMEZONE=${TIMEZONE:-UTC}
      - DB_TYPE=postgresdb
      - DB_POSTGRESDB_HOST=db-postgres
      - DB_POSTGRESDB_PORT=5432
      - DB_POSTGRESDB_DATABASE=${DB_NAME:-postgres}
      - DB_POSTGRESDB_USER=${DB_USER:-postgres}
      - DB_POSTGRESDB_PASSWORD=${DB_PASSWORD:-your-super-secret-password}
      - N8N_METRICS=true
    volumes:
      - n8n-data:/home/node/.n8n
      - ./workflows/n8n:/home/node/workflows
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:5678/healthz"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 30s
    depends_on:
      db-postgres:
        condition: service_healthy
    networks:
      - alfred-network
```

### 3.2 PubSub Bindings

**New PubSub Topics to Create:**

| Topic | Purpose | Publishers | Subscribers |
|-------|---------|------------|-------------|
| `crew.tasks` | Tasks for CrewAI service | agent-core, ui-admin, n8n | CrewAI service |
| `crew.results` | Results from CrewAI tasks | CrewAI service | agent-core, ui-admin |
| `n8n.events` | Events for n8n workflows | agent-core, CrewAI | n8n service |
| `n8n.results` | Results from n8n workflows | n8n service | agent-core, CrewAI |

**Message Format Example (A2A Envelope Extension):**
```json
{
  "task_id": "a8f2e7c1-0d3b-4e82-9a7f-6c8a5b4f3e2d",
  "intent": "CREW_RESEARCH_TASK",
  "timestamp": "2025-05-11T14:30:00Z",
  "tenant_id": "tenant-123",
  "source": "agent-core",
  "target": "crew-service",
  "content": {
    "objective": "Research the latest developments in quantum computing",
    "crew_template": "research_team",
    "max_iterations": 3,
    "data_sources": ["web", "research_papers", "news"],
    "context": "This is for a technical blog post aimed at developers"
  }
}
```

### 3.3 Crew Templates

**BaseCrew Implementation:**
```python
from typing import Dict, Any, List, Optional
import uuid
import time
import asyncio
import json
from google.cloud import pubsub_v1
from crewai import Crew, Agent, Task
import structlog

logger = structlog.get_logger(__name__)

class BaseCrew:
    """Base class for CrewAI crews that integrates with Alfred Agent Platform."""
    
    def __init__(
        self,
        crew_id: Optional[str] = None,
        tenant_id: Optional[str] = None,
        project_id: str = "alfred-agent-platform",
        pubsub_emulator_host: Optional[str] = None,
    ):
        self.crew_id = crew_id or str(uuid.uuid4())
        self.tenant_id = tenant_id
        self.project_id = project_id
        self.pubsub_emulator_host = pubsub_emulator_host
        
        # Initialize PubSub clients
        self.publisher = pubsub_v1.PublisherClient()
        self.results_topic_path = self.publisher.topic_path(
            self.project_id, "crew.results"
        )
        
        # Initialize base crew components
        self.agents: List[Agent] = []
        self.tasks: List[Task] = []
        self.crew: Optional[Crew] = None
    
    def add_agent(self, agent: Agent) -> None:
        """Add an agent to the crew."""
        self.agents.append(agent)
    
    def add_task(self, task: Task) -> None:
        """Add a task to the crew."""
        self.tasks.append(task)
    
    def create_crew(self, **kwargs) -> Crew:
        """Create and configure the CrewAI crew."""
        self.crew = Crew(
            agents=self.agents,
            tasks=self.tasks,
            verbose=True,
            **kwargs
        )
        return self.crew
    
    async def run(self, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """Run the crew and publish results to PubSub."""
        if not self.crew:
            self.create_crew()
        
        start_time = time.time()
        
        try:
            # Execute crew tasks
            result = self.crew.kickoff(inputs=context or {})
            
            # Process and format result
            execution_time = time.time() - start_time
            processed_result = self._process_result(result, execution_time)
            
            # Publish result to PubSub
            await self._publish_result(processed_result)
            
            return processed_result
            
        except Exception as e:
            error_result = {
                "crew_id": self.crew_id,
                "status": "error",
                "error": str(e),
                "execution_time": time.time() - start_time
            }
            await self._publish_result(error_result)
            logger.error("crew_execution_error", error=str(e), crew_id=self.crew_id)
            raise
    
    def _process_result(self, result: Any, execution_time: float) -> Dict[str, Any]:
        """Process and structure the crew execution result."""
        return {
            "crew_id": self.crew_id,
            "tenant_id": self.tenant_id,
            "status": "completed",
            "result": result if isinstance(result, dict) else {"output": str(result)},
            "execution_time": execution_time,
            "timestamp": time.time(),
            "agents": [agent.name for agent in self.agents],
            "tasks": [task.description for task in self.tasks]
        }
    
    async def _publish_result(self, result: Dict[str, Any]) -> None:
        """Publish result to the appropriate PubSub topic."""
        message = json.dumps(result).encode("utf-8")
        try:
            future = self.publisher.publish(self.results_topic_path, message)
            message_id = future.result()
            logger.info(
                "result_published",
                message_id=message_id,
                crew_id=self.crew_id,
                topic="crew.results"
            )
        except Exception as e:
            logger.error(
                "result_publish_error",
                error=str(e),
                crew_id=self.crew_id
            )
```

### 3.4 n8n Starter Workflows

**PR Triage Workflow:**
- Triggers from: GitHub webhook or `crew.results` PubSub topic
- Actions:
  1. Fetch PR details from GitHub
  2. Analyze PR content using the AI agents
  3. Tag PR with appropriate labels
  4. Assign reviewer based on expertise
  5. Notify team on Slack
  6. Update status in Supabase

**Daily Metrics Workflow:**
- Triggers: Scheduled (daily at 9 AM)
- Actions:
  1. Query Prometheus metrics for past 24 hours
  2. Pull agent usage stats from Supabase
  3. Generate performance report
  4. Send summary to Slack
  5. Update dashboards

### 3.5 Secrets & Environment Variables

**New Environment Variables:**

```bash
# CrewAI Service Configuration
CREWAI_PORT=9004
CREWAI_LOG_LEVEL=INFO
CREWAI_OPENAI_API_KEY=${ALFRED_OPENAI_API_KEY}
CREWAI_ANTHROPIC_API_KEY=${ALFRED_ANTHROPIC_API_KEY}
CREWAI_RAG_URL=http://agent-rag:8501
CREWAI_RAG_API_KEY=crew-key
CREWAI_METRICS_PORT=9005
CREWAI_TASK_MAX_RUNTIME=600  # seconds

# n8n Configuration
N8N_USER=admin
N8N_PASSWORD=alfred123
N8N_HOST=localhost
N8N_PROTOCOL=http
N8N_LOG_LEVEL=info
N8N_METRICS_PORT=5679
```

### 3.6 Monitoring Integration

**Prometheus Scrape Configuration (addition to prometheus.yml):**

```yaml
scrape_configs:
  # Existing scrape configs...
  
  # CrewAI service metrics
  - job_name: 'crewai-service'
    scrape_interval: 15s
    static_configs:
      - targets: ['crewai-service:9005']
    
  # n8n metrics
  - job_name: 'n8n'
    scrape_interval: 15s
    static_configs:
      - targets: ['workflow-n8n:5679']
```

**Grafana Dashboard:** A JSON dashboard definition will be provided in `/monitoring/grafana/dashboards/crewai_n8n_dashboard.json`

### 3.7 CI/CD Integration

**GitHub Actions Workflow (add to existing CI):**

```yaml
name: Build and Push CrewAI Service

on:
  push:
    branches: [ main ]
    paths:
      - 'services/crewai-service/**'
      - '.github/workflows/crewai-service.yml'
  pull_request:
    branches: [ main ]
    paths:
      - 'services/crewai-service/**'

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to Container Registry
        uses: docker/login-action@v2
        with:
          registry: ${{ secrets.CONTAINER_REGISTRY }}
          username: ${{ secrets.REGISTRY_USERNAME }}
          password: ${{ secrets.REGISTRY_PASSWORD }}
      
      - name: Build and push CrewAI service
        uses: docker/build-push-action@v4
        with:
          context: ./services/crewai-service
          push: ${{ github.event_name != 'pull_request' }}
          tags: ${{ secrets.CONTAINER_REGISTRY }}/crewai-service:latest,${{ secrets.CONTAINER_REGISTRY }}/crewai-service:${{ github.sha }}
```

## 4. Integration with Existing Agents

### 4.1 Service Interactions

The CrewAI and n8n services will interact with existing agents through:

1. **PubSub Message Bus** - For asynchronous task delegation and results collection
2. **Direct API Calls** - For synchronous operations that need immediate responses
3. **Shared Database** - For persistent state and cross-agent task coordination

### 4.2 Backward Compatibility

To ensure existing LangChain/LangGraph flows aren't disrupted:

1. **Parallel Operations** - CrewAI flows run alongside existing flows, not replacing them
2. **Feature Flagging** - New capabilities can be toggled via environment variables
3. **Graceful Fallbacks** - If CrewAI/n8n services are unavailable, system falls back to existing flows

### 4.3 Migration Path

For teams wanting to migrate from LangChain/LangGraph to CrewAI:

1. **Wrapper Classes** - Provide adapter classes that map LangChain patterns to CrewAI concepts
2. **Migration Scripts** - Tools to help convert existing agent definitions
3. **Hybrid Mode** - Support for running both frameworks simultaneously during transition

## 5. Local Development Setup

### 5.1 Setup Instructions

1. **Add New Services to docker-compose**:
   Add CrewAI and n8n service stanzas to your `docker-compose.dev.yml`

2. **Install Dependencies**:
   ```bash
   pip install -r services/crewai-service/requirements.txt
   ```

3. **Start Services**:
   ```bash
   make up-crewai-n8n
   ```

4. **Access n8n Interface**:
   Open http://localhost:5500 in your browser to access n8n workflow editor

5. **Test CrewAI Service**:
   ```bash
   curl http://localhost:9004/health
   ```

### 5.2 Development Workflow

1. **Create Crew Templates**:
   Add new crew templates to `services/crewai-service/crewai_service/crews/`

2. **Create n8n Workflows**:
   Build workflows in the n8n UI and export to `workflows/n8n/`

3. **Test Integration**:
   Use the integration test suite in `tests/integration/test_crewai_n8n.py`

## 6. Production Deployment Considerations

1. **Resource Requirements**:
   - CrewAI Service: 1-2 CPU cores, 2-4GB RAM minimum
   - n8n Service: 1 CPU core, 2GB RAM minimum
   - Scale based on expected workflow volume

2. **Security Considerations**:
   - API keys stored in secure environment variables or secrets manager
   - Proper authentication between services
   - Rate limiting and request validation

3. **High Availability**:
   - Multiple replicas of CrewAI service with load balancing
   - n8n clustering for high-volume environments
   - Redundant PubSub subscriptions

## 7. Documentation

Comprehensive documentation will be added to:
- `/docs/services/crewai-service/README.md`
- `/docs/services/n8n/README.md`
- `/docs/integrations/crewai-n8n-integration.md`

## 8. Next Steps

1. Create directory structure for the new services
2. Set up scaffolding code and configuration files
3. Implement basic CrewAI service with health checks
4. Deploy n8n container and configure connection to Postgres
5. Develop first crew template and n8n workflow
6. Build integration tests and monitoring
7. Document usage patterns and best practices