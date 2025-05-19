# Week 1 Implementation Guide - Master Alfred Foundation

## 🚀 Immediate Action Items (May 6-10, 2025)

### Day 1: Monday - Project Setup

#### Morning (9:00 AM - 12:00 PM)
```bash
# 1. Create project structure
cd /home/locotoki/projects/alfred-agent-platform-v2/services
mkdir -p master-alfred/{app/{core,personality,family,security,context,proactive,interfaces,api},tests,docs}
cd master-alfred

# 2. Create base files
cat > Dockerfile << 'EOF'
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Create non-root user for security
RUN adduser --disabled-password --gecos '' appuser
USER appuser

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8012"]
EOF

# 3. Create requirements.txt
cat > requirements.txt << 'EOF'
fastapi==0.104.1
uvicorn==0.24.0
pydantic==2.5.2
structlog==23.2.0
langchain==0.0.350
openai==1.3.7
redis==5.0.1
twilio==8.10.3
speech-recognition==3.10.0
gTTS==2.4.0
asyncpg==0.29.0
python-jose[cryptography]==3.3.0
python-multipart==0.0.6
websockets==12.0
aiohttp==3.9.1
asyncio==3.4.3
EOF
```

#### Afternoon (1:00 PM - 5:00 PM)
```python
# 4. Create main.py
cat > app/main.py << 'EOF'
from fastapi import FastAPI, Request
from contextlib import asynccontextmanager
import structlog
import os

from app.core.master_alfred import MasterAlfredAgent
from libs.agent_core.health import create_health_app
from libs.a2a_adapter import PubSubTransport, SupabaseTransport

logger = structlog.get_logger(__name__)

# Initialize transports
pubsub_transport = PubSubTransport(
    project_id=os.getenv("GCP_PROJECT_ID", "alfred-agent-platform")
)

supabase_transport = SupabaseTransport(
    database_url=os.getenv("DATABASE_URL")
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle."""
    # Startup
    global master_alfred
    master_alfred = MasterAlfredAgent()
    await master_alfred.start()
    await supabase_transport.connect()
    logger.info("master_alfred_started")

    yield

    # Shutdown
    await master_alfred.stop()
    await supabase_transport.disconnect()
    logger.info("master_alfred_stopped")

app = FastAPI(
    title="Master Alfred",
    version="2.0.0",
    lifespan=lifespan
)

# Health checks
health_app = create_health_app("master-alfred", "2.0.0")
app.mount("/health", health_app)

# API routes will be added here
from app.api.router import api_router
app.include_router(api_router, prefix="/api/v1")
EOF
```

### Day 2: Tuesday - Core Implementation

#### Morning (9:00 AM - 12:00 PM)
```python
# 5. Create Master Alfred core
mkdir -p app/core
cat > app/core/master_alfred.py << 'EOF'
from typing import Dict, Any, Optional
import structlog
from datetime import datetime

from libs.agent_core import BaseAgent
from libs.a2a_adapter import A2AEnvelope, A2AResponse
from app.personality.engine import AlfredPersonality
from app.context.manager import ContextManager
from app.family.profiles import FamilyProfileManager
from app.proactive.monitor import ProactiveMonitor

logger = structlog.get_logger(__name__)

class MasterAlfredAgent(BaseAgent):
    """
    Master Alfred Orchestrator - The central controller for all Alfred operations.
    """

    def __init__(self):
        super().__init__(
            name="master-alfred",
            version="2.0.0",
            supported_intents=[
                "GENERAL_ASSISTANCE",
                "FAMILY_COORDINATION",
                "BUSINESS_SUPPORT",
                "EMERGENCY_RESPONSE",
                "PROACTIVE_SUGGESTION",
                "VOICE_COMMAND",
                "MOBILE_REQUEST",
                "WHATSAPP_MESSAGE",
                "WEB_INTERACTION",
                "DELEGATE_TO_AGENT",
                "AGGREGATE_RESPONSES",
                "PRIORITY_OVERRIDE"
            ]
        )

        self.personality_engine = AlfredPersonality()
        self.context_manager = ContextManager()
        self.family_profiles = FamilyProfileManager()
        self.proactive_monitor = ProactiveMonitor()

    async def process_task(self, envelope: A2AEnvelope) -> Dict[str, Any]:
        """Process incoming requests with Alfred's personality."""
        try:
            # Extract user context
            user_id = envelope.content.get("user_id")
            interface = envelope.content.get("interface", "unknown")

            # Get family profile
            family_member = await self.family_profiles.get_member(user_id)

            # Get context
            context = await self.context_manager.get_context(
                user_id=user_id,
                family_member=family_member,
                interface=interface,
                intent=envelope.intent
            )

            # Route to appropriate handler
            response = await self._route_request(envelope, context)

            # Apply personality to response
            final_response = await self.personality_engine.format_response(
                response=response,
                context=context,
                family_member=family_member
            )

            return final_response

        except Exception as e:
            logger.error("master_alfred_error", error=str(e))
            return self._create_error_response(e, envelope)

    async def _route_request(self, envelope: A2AEnvelope, context: Dict[str, Any]) -> Dict[str, Any]:
        """Route requests to appropriate handlers."""
        if envelope.intent == "GENERAL_ASSISTANCE":
            return await self._handle_general_assistance(envelope, context)
        else:
            # Default response for now
            return {
                "status": "success",
                "response": f"Master Alfred acknowledges: {envelope.intent}",
                "task_id": envelope.task_id
            }

    async def _handle_general_assistance(self, envelope: A2AEnvelope, context: Dict[str, Any]) -> Dict[str, Any]:
        """Handle general assistance requests."""
        query = envelope.content.get("query", "")

        return {
            "status": "success",
            "response": f"Certainly! I understand you need assistance with: {query}",
            "task_id": envelope.task_id
        }
EOF
```

#### Afternoon (1:00 PM - 5:00 PM)
```python
# 6. Create personality engine stub
mkdir -p app/personality
cat > app/personality/engine.py << 'EOF'
from typing import Dict, Any
import structlog

logger = structlog.get_logger(__name__)

class AlfredPersonality:
    """Alfred's personality engine."""

    def __init__(self):
        self.traits = {
            "discretion": 0.95,
            "anticipatory": 0.85,
            "warmth": 0.75,
            "formality": 0.80,
            "wit": 0.70,
            "crisis_competence": 0.95,
            "loyalty": 1.0
        }

    async def format_response(self, response: Dict[str, Any], context: Dict[str, Any], family_member: Dict[str, Any]) -> Dict[str, Any]:
        """Format response with Alfred's personality."""
        # Add personality touches
        if "response" in response:
            response["response"] = self._apply_alfred_style(response["response"])
        return response

    def _apply_alfred_style(self, text: str) -> str:
        """Apply Alfred's speaking style."""
        # TODO: Implement sophisticated style application
        return f"Indeed, {text}"
EOF

# 7. Create context manager stub
mkdir -p app/context
cat > app/context/manager.py << 'EOF'
from typing import Dict, Any, Optional
import structlog

logger = structlog.get_logger(__name__)

class ContextManager:
    """Manages conversation and situational context."""

    def __init__(self):
        self.contexts = {}

    async def get_context(self, user_id: str, family_member: Dict[str, Any], interface: str, intent: str) -> Dict[str, Any]:
        """Get current context for user."""
        return {
            "user_id": user_id,
            "interface": interface,
            "intent": intent,
            "timestamp": "2025-05-06T10:00:00Z"
        }
EOF

# 8. Create family profile manager stub
mkdir -p app/family
cat > app/family/profiles.py << 'EOF'
from typing import Dict, Any, Optional
import structlog

logger = structlog.get_logger(__name__)

class FamilyProfileManager:
    """Manages family member profiles."""

    def __init__(self):
        self.profiles = {}

    async def get_member(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Get family member profile."""
        # TODO: Implement database lookup
        return {
            "member_id": user_id,
            "name": "Guest",
            "role": "guest"
        }
EOF

# 9. Create proactive monitor stub
mkdir -p app/proactive
cat > app/proactive/monitor.py << 'EOF'
import structlog

logger = structlog.get_logger(__name__)

class ProactiveMonitor:
    """Monitors for proactive assistance opportunities."""

    def __init__(self):
        self.is_running = False

    async def start(self):
        """Start monitoring."""
        self.is_running = True
        logger.info("proactive_monitor_started")

    async def stop(self):
        """Stop monitoring."""
        self.is_running = False
        logger.info("proactive_monitor_stopped")
EOF
```

### Day 3: Wednesday - Docker & API Setup

#### Morning (9:00 AM - 12:00 PM)
```python
# 10. Create API router
mkdir -p app/api
cat > app/api/router.py << 'EOF'
from fastapi import APIRouter
from app.api.endpoints import family, commands, status

api_router = APIRouter()

api_router.include_router(family.router, prefix="/family", tags=["family"])
api_router.include_router(commands.router, prefix="/commands", tags=["commands"])
api_router.include_router(status.router, prefix="/status", tags=["status"])
EOF

# 11. Create command endpoint
mkdir -p app/api/endpoints
cat > app/api/endpoints/commands.py << 'EOF'
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import Dict, Any
import structlog

from libs.a2a_adapter import A2AEnvelope

router = APIRouter()
logger = structlog.get_logger(__name__)

class CommandRequest(BaseModel):
    command: str
    user_id: str
    interface: str = "api"
    context: Dict[str, Any] = {}

@router.post("/execute")
async def execute_command(request: CommandRequest):
    """Execute a command through Master Alfred."""
    try:
        envelope = A2AEnvelope(
            intent="GENERAL_ASSISTANCE",
            content={
                "query": request.command,
                "user_id": request.user_id,
                "interface": request.interface,
                "context": request.context
            }
        )

        # Process through Master Alfred
        from app.main import master_alfred
        response = await master_alfred.process_task(envelope)

        return response
    except Exception as e:
        logger.error("command_execution_failed", error=str(e))
        raise HTTPException(status_code=500, detail=str(e))
EOF
```

#### Afternoon (1:00 PM - 5:00 PM)
```yaml
# 12. Update docker-compose
cd /home/locotoki/projects/alfred-agent-platform-v2
cp docker-compose.yml docker-compose-alfred.yml

# Add master-alfred service
cat >> docker-compose-alfred.yml << 'EOF'

  master-alfred:
    build:
      context: ./services/master-alfred
      dockerfile: Dockerfile
    ports:
      - "8012:8012"
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - REDIS_URL=redis://redis:6379
      - DATABASE_URL=${DATABASE_URL}
      - GCP_PROJECT_ID=${GCP_PROJECT_ID}
      - PUBSUB_EMULATOR_HOST=pubsub-emulator:8085
    depends_on:
      - redis
      - supabase-db
      - pubsub-emulator
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8012/health/"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - app-network
EOF
```

### Day 4: Thursday - Testing & Development Scripts

#### Morning (9:00 AM - 12:00 PM)
```python
# 13. Create test structure
cd services/master-alfred
mkdir -p tests/{unit,integration}

# 14. Create first unit test
cat > tests/unit/test_master_alfred.py << 'EOF'
import pytest
from app.core.master_alfred import MasterAlfredAgent
from libs.a2a_adapter import A2AEnvelope

@pytest.mark.asyncio
async def test_general_assistance():
    """Test general assistance intent."""
    alfred = MasterAlfredAgent()

    envelope = A2AEnvelope(
        intent="GENERAL_ASSISTANCE",
        content={
            "query": "What's the weather today?",
            "user_id": "test_user"
        }
    )

    response = await alfred.process_task(envelope)

    assert response["status"] == "success"
    assert "weather" in response["response"].lower()
EOF

# 15. Create pytest configuration
cat > pytest.ini << 'EOF'
[pytest]
testpaths = tests
python_files = test_*.py
python_functions = test_*
asyncio_mode = auto
EOF
```

#### Afternoon (1:00 PM - 5:00 PM)
```bash
# 16. Create development scripts
mkdir -p scripts
cat > scripts/dev-setup.sh << 'EOF'
#!/bin/bash
set -e

echo "Setting up Master Alfred development environment..."

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
pip install pytest pytest-asyncio pytest-cov

echo "Development environment ready!"
EOF

chmod +x scripts/dev-setup.sh

# 17. Create test script
cat > scripts/test-master-alfred.sh << 'EOF'
#!/bin/bash
set -e

echo "Running Master Alfred tests..."

# Run unit tests
pytest tests/unit -v

# Run integration tests if available
if [ -d "tests/integration" ]; then
    pytest tests/integration -v
fi

# Generate coverage report
pytest --cov=app tests/

echo "Tests completed!"
EOF

chmod +x scripts/test-master-alfred.sh
```

### Day 5: Friday - Integration & Documentation

#### Morning (9:00 AM - 12:00 PM)
```bash
# 18. Create documentation
mkdir -p docs
cat > docs/README.md << 'EOF'
# Master Alfred Service

The central orchestrator for the Alfred AI Assistant platform.

## Features
- Personality-driven responses
- Multi-interface support
- Family profile management
- Proactive monitoring
- Context-aware processing

## Quick Start
```bash
# Development setup
./scripts/dev-setup.sh

# Run tests
./scripts/test-master-alfred.sh

# Start service
docker-compose -f docker-compose-alfred.yml up master-alfred
```

## API Endpoints
- POST `/api/v1/commands/execute` - Execute a command
- GET `/api/v1/status` - Get service status
- GET `/health/` - Health check

## Architecture
See [technical-architecture.md](../docs/alfred_assistant_implementation/technical-architecture.md)
EOF
```

#### Afternoon (1:00 PM - 5:00 PM)
```bash
# 19. Create Makefile additions
cd /home/locotoki/projects/alfred-agent-platform-v2
cat >> Makefile << 'EOF'

# Master Alfred commands
.PHONY: dev-alfred test-alfred build-alfred

dev-alfred:
	docker-compose -f docker-compose-alfred.yml up master-alfred

test-alfred:
	cd services/master-alfred && ./scripts/test-master-alfred.sh

build-alfred:
	docker-compose -f docker-compose-alfred.yml build master-alfred

logs-alfred:
	docker-compose -f docker-compose-alfred.yml logs -f master-alfred

shell-alfred:
	docker-compose -f docker-compose-alfred.yml exec master-alfred /bin/bash
EOF

# 20. Test the complete setup
make build-alfred
make test-alfred
make dev-alfred
```

## 📋 End of Week 1 Checklist

### Completed Tasks
- [x] Master Alfred service structure created
- [x] Core implementation with basic personality
- [x] Docker configuration complete
- [x] API endpoints scaffolded
- [x] Test framework established
- [x] Development scripts ready
- [x] Documentation started

### Next Week Preview
- Implement full personality engine
- Create context management system
- Set up family profile database
- Enhance API functionality
- Add integration tests

## 🎯 Week 1 Success Metrics

1. **Service Startup**: Master Alfred starts successfully
2. **Health Check**: `/health/` endpoint responds with 200
3. **API Response**: `/api/v1/commands/execute` returns valid response
4. **Test Coverage**: Basic unit tests passing
5. **Docker Integration**: Service runs in Docker environment

## 🚦 Status Check Commands

```bash
# Verify service health
curl http://localhost:8012/health/

# Test API endpoint
curl -X POST http://localhost:8012/api/v1/commands/execute \
  -H "Content-Type: application/json" \
  -d '{"command": "Hello Alfred", "user_id": "test_user"}'

# Check logs
docker-compose -f docker-compose-alfred.yml logs master-alfred

# Run tests
cd services/master-alfred && pytest tests/
```

---

*End of Week 1 - Master Alfred foundation successfully established!*
