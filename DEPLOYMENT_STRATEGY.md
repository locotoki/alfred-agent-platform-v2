# Alfred Agent Platform v2 - Deployment Strategy & Service Tiers

## Why Chat-UI Was Missing (Answer to Your Question)

The chat-UI and other UI services weren't running in the initial macOS deployment because:

1. **Profile-based Architecture**: Services are organized into profiles, not all started by default
2. **Dependency Chain**: UI services depend on agent services that weren't running
3. **Platform Inconsistency**: Windows deployment likely uses different startup scripts

## Service Organization & Profiles

### 🎯 **Core Tier** (Always Required)
```bash
# Infrastructure essentials
- db-postgres      # PostgreSQL database
- redis           # Redis cache/queues  
- vector-db       # Qdrant vector database
- db-api          # PostgREST API
- mail-server     # MailHog for development
```

### 🤖 **LLM Tier** (Profile: `--profile llm`)
```bash
- llm-service     # Ollama LLM runtime
- model-registry  # Model management
- model-router    # LLM request routing
```

### 🧠 **Agent Tier** (Profile: `--profile agents`)
```bash
- agent-core      # Main agent orchestrator  
- agent-rag       # RAG/vector search
- agent-social    # Social intelligence
- agent-atlas     # Atlas worker
- pubsub-emulator # Message queuing
```

### 🖥️ **UI Tier** (Profile: `--profile ui`)
```bash
- ui-chat         # Streamlit chat interface (port 8502)
- ui-admin        # Mission control dashboard (port 3007)
```

### 🔐 **Auth Tier** (Profile: `--profile auth`)
```bash
- db-auth         # GoTrue authentication
- auth-ui         # Authentication interface (port 3006)
```

### 📊 **Monitoring Tier** (Profile: `--profile monitoring`)
```bash
- monitoring-metrics    # Prometheus
- monitoring-dashboard  # Grafana  
- monitoring-db        # Database metrics
- monitoring-redis     # Redis metrics
```

## Consistent Cross-Platform Deployment Commands

### 🚀 **Minimal Development Stack**
```bash
# Core + LLM + Agent-Core only
docker compose --profile dev --profile llm up -d
```

### 🎮 **Full Development Stack** (Matches Windows)
```bash
# Everything including UI services
docker compose \
  --profile dev \
  --profile llm \
  --profile agents \
  --profile ui \
  --profile monitoring \
  up -d --build
```

### ⚡ **Production Stack**
```bash
# Optimized for production
docker compose \
  --profile llm \
  --profile agents \
  --profile ui \
  --profile auth \
  up -d
```

## Service Endpoints by Tier

### Core Services
- PostgreSQL: `localhost:5432`
- Redis: `localhost:6379` 
- Qdrant: `http://localhost:6333`
- PostgREST: `http://localhost:3000`

### UI Services (The Missing Piece!)
- **Chat UI**: `http://localhost:8502` ← This was missing!
- **Admin UI**: `http://localhost:3007`
- **Auth UI**: `http://localhost:3006`

### LLM Services  
- Ollama API: `http://localhost:11434`
- Model Router: `http://localhost:8080`
- Model Registry: `http://localhost:8079`

### Agent Services
- Agent Core: `http://localhost:8011`
- Agent RAG: `http://localhost:8501`
- Agent Social: `http://localhost:9000`

### Monitoring
- Grafana: `http://localhost:3005`
- Prometheus: `http://localhost:9090`

## Platform Consistency Solutions

### 1. **Environment Standardization**
```bash
# Create .envrc for direnv users
echo 'export $(grep -vE "^\s*#" .env | xargs)' > .envrc

# Ensure same environment variables across platforms
cp .env.example .env  # Then customize
```

### 2. **Profile-Based Startup Scripts**

**For Development (matches Windows):**
```bash
#!/bin/bash
# start-dev-full.sh
docker compose \
  --profile dev \
  --profile llm \
  --profile agents \
  --profile ui \
  up -d --build
```

**For Core Services Only:**
```bash
#!/bin/bash  
# start-core.sh
docker compose \
  --profile dev \
  --profile llm \
  up -d
```

### 3. **Health Check Standardization**
```bash
# Wait for core services
until docker compose ps --filter "status=healthy" | grep -q "agent-core"; do
  echo "Waiting for agent-core..."
  sleep 2
done

echo "✅ Platform ready with all tiers!"
```

## Recommended Deployment Pattern

### Step 1: Choose Your Tier
```bash
# Minimal (no UI)
PROFILES="--profile dev --profile llm"

# Full Development (with UI) 
PROFILES="--profile dev --profile llm --profile agents --profile ui"

# Production
PROFILES="--profile llm --profile agents --profile ui --profile auth"
```

### Step 2: Deploy Consistently
```bash
docker compose down --remove-orphans
docker compose $PROFILES up -d --build
```

### Step 3: Verify All Tiers
```bash
# Core tier
curl -s http://localhost:6333/collections | jq '.result'

# LLM tier  
curl -s http://localhost:11434/api/tags | jq '.models'

# Agent tier
curl -s http://localhost:8011/health | jq '.status'

# UI tier (the key missing piece!)
curl -s http://localhost:8502/ | grep -q "Streamlit"
```

## Why This Approach Ensures Consistency

1. **Profile-Based**: Same service groupings across all platforms
2. **Environment-Driven**: Same .env configuration everywhere  
3. **Health-Check Driven**: Same readiness verification
4. **Endpoint Standardized**: Same URLs regardless of platform
5. **Build-Once Deploy-Anywhere**: Docker ensures platform parity

The missing chat-UI issue was simply that the UI profile wasn't being activated in the initial deployment. With this tiered approach, you get exactly the same services running on macOS, Windows, and Linux.