# Model Registry Design

## Overview

The Model Registry is a central component that manages LLM models, their configurations, and their deployment status. It provides a unified interface for model discovery, selection, and monitoring.

## Core Components

### 1. Model Registry Database

A PostgreSQL schema with the following tables:

```sql
-- Model definitions
CREATE TABLE models (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    display_name VARCHAR(200) NOT NULL,
    provider VARCHAR(50) NOT NULL,  -- 'openai', 'anthropic', 'ollama', 'custom'
    model_type VARCHAR(50) NOT NULL, -- 'completion', 'chat', 'embedding', 'vision'
    version VARCHAR(50),
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Model endpoints
CREATE TABLE model_endpoints (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES models(id),
    endpoint_type VARCHAR(50) NOT NULL, -- 'rest', 'grpc', 'local'
    endpoint_url VARCHAR(255),
    auth_type VARCHAR(50), -- 'api_key', 'oauth', 'none'
    headers JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now()
);

-- Model capabilities
CREATE TABLE model_capabilities (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES models(id),
    capability VARCHAR(50) NOT NULL, -- 'text', 'image', 'code', 'reasoning', etc.
    capability_score FLOAT NOT NULL, -- 0-1 score representing capability strength
    UNIQUE(model_id, capability)
);

-- Model parameters
CREATE TABLE model_parameters (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES models(id),
    parameter_name VARCHAR(100) NOT NULL,
    default_value JSONB NOT NULL,
    min_value JSONB,
    max_value JSONB,
    description TEXT,
    UNIQUE(model_id, parameter_name)
);

-- Model performance tracking
CREATE TABLE model_performance (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES models(id),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT now(),
    metric_name VARCHAR(100) NOT NULL,
    metric_value FLOAT NOT NULL,
    task_category VARCHAR(100),
    sample_size INTEGER
);

-- Model usage statistics
CREATE TABLE model_usage (
    id SERIAL PRIMARY KEY,
    model_id INTEGER REFERENCES models(id),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT now(),
    token_count INTEGER,
    request_count INTEGER DEFAULT 1,
    average_latency FLOAT,
    error_count INTEGER DEFAULT 0,
    cost DECIMAL(10,6)
);
```

### 2. Registry API Service

A RESTful API that provides:

- **Model CRUD Operations**
  - `GET /models` - List all registered models
  - `GET /models/{id}` - Get specific model details
  - `POST /models` - Register a new model
  - `PUT /models/{id}` - Update model configuration
  - `DELETE /models/{id}` - Remove a model

- **Capability Management**
  - `GET /models/{id}/capabilities` - List model capabilities
  - `POST /models/{id}/capabilities` - Add capability to model
  - `DELETE /models/{id}/capabilities/{capability}` - Remove capability

- **Parameter Configuration**
  - `GET /models/{id}/parameters` - Get model parameters
  - `POST /models/{id}/parameters` - Add/update parameter

- **Performance Tracking**
  - `GET /models/{id}/performance` - Get performance metrics
  - `POST /models/{id}/performance` - Record performance data

- **Usage Statistics**
  - `GET /models/{id}/usage` - Get usage statistics
  - `POST /models/{id}/usage` - Record usage data

### 3. Model Discovery Service

An automatic model discovery service that:

1. Scans the Ollama service for available models
2. Queries cloud provider APIs for available models
3. Updates the model registry with discovered models
4. Fetches model capabilities and parameters

```python
class ModelDiscoveryService:
    def __init__(self, db_connection, config):
        self.db = db_connection
        self.config = config
        
    async def discover_ollama_models(self):
        # Connect to Ollama API
        # List available models
        # Register discovered models
        
    async def discover_openai_models(self):
        # Query OpenAI API for available models
        # Register discovered models
        
    async def discover_anthropic_models(self):
        # Query Anthropic API for available models
        # Register discovered models
        
    async def update_model_registry(self):
        # Sync discovered models with registry
        # Update capabilities and parameters
```

## Integration Points

### Database Integration

- Uses existing PostgreSQL database
- Creates new `model_registry` schema
- Integrates with existing auth system for access control

### API Integration

- Exposes RESTful API on port 8700
- Secured with same JWT authentication as other services
- Integrates with monitoring system for metrics

### Container Integration

- New `model-registry` container
- Connects to existing network
- Depends on PostgreSQL and Redis services

## Security Considerations

- All API endpoints secured with JWT authentication
- Role-based access control for model management
- Encrypted storage of API keys
- Audit logging for all registry operations
- Validation of model parameters to prevent injection

## Implementation Details

### Container Configuration

```yaml
model-registry:
  build:
    context: ./services/model-registry
    dockerfile: Dockerfile
  image: alfred-model-registry:latest
  container_name: model-registry
  ports:
    - "8700:8700"
  environment:
    - DATABASE_URL=${ALFRED_DATABASE_URL:-postgresql://${DB_USER:-postgres}:${DB_PASSWORD:-your-super-secret-password}@db-postgres:5432/${DB_NAME:-postgres}}
    - REDIS_URL=redis://redis:6379/0
    - JWT_SECRET=${DB_JWT_SECRET:-your-super-secret-jwt-token}
    - LOG_LEVEL=info
    - OLLAMA_URL=http://llm-service:11434
    - OPENAI_API_KEY=${ALFRED_OPENAI_API_KEY}
    - ANTHROPIC_API_KEY=${ALFRED_ANTHROPIC_API_KEY}
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8700/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 10s
  depends_on:
    db-postgres:
      condition: service_healthy
    redis:
      condition: service_started
  restart: unless-stopped
  networks:
    - alfred-network
  labels:
    com.docker.compose.project: "alfred"
    com.docker.compose.group: "core-infrastructure"
    com.docker.compose.service: "model-registry"
```

### Technology Stack

- Python FastAPI for the registry API
- SQLAlchemy for database ORM
- Redis for caching model information
- Pydantic for data validation
- AsyncIO for non-blocking operations
- Prometheus for metrics collection

## Expected Behavior

1. During startup:
   - Initialize database schema if not exists
   - Discover available models from configured providers
   - Register models in the database
   - Start serving API requests

2. During runtime:
   - Serve model information requests
   - Track model usage statistics
   - Periodically update model information
   - Alert on model issues or performance degradation

3. Integration with other services:
   - Model Router queries for available models
   - Agent services request model capabilities
   - Monitoring system collects performance metrics