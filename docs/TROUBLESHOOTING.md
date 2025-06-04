# Alfred Agent Platform v2 - Troubleshooting Guide

This guide provides solutions for common issues you might encounter when working with the Alfred Agent Platform v2.

## Table of Contents

1. [Docker Container Issues](#docker-container-issues)
2. [Port Configuration Problems](#port-configuration-problems)
3. [Inter-Service Communication Failures](#inter-service-communication-failures)
4. [Library Dependency Issues](#library-dependency-issues)
5. [API Integration Errors](#api-integration-errors)
6. [UI Rendering Problems](#ui-rendering-problems)
7. [Database Connectivity Issues](#database-connectivity-issues)

## 11-Service Core Baseline

**New in v0.9.14**: The platform now uses a hardened 11-service core baseline for optimal stability and performance.

### Core Services
The following services are included in the core baseline:
- `db-postgres` (PostgreSQL 16 with security hardening)
- `redis` (Redis 7 Alpine)
- `db-api` (PostgREST API layer)
- `db-storage` (Storage service)
- `pubsub-emulator` (Google Cloud Pub/Sub emulator)
- `llm-service` (Ollama LLM service)
- `model-router` (Model routing service)
- `model-registry` (Model registry service)
- `agent-core` (Core agent service)
- `mail-server` (MailHog mail server)
- `redis-exporter` (Redis metrics exporter)
- `pubsub-metrics` (Pub/Sub metrics collector)

### Starting Core Services
```bash
# Start 11-service core baseline
docker compose --profile core up -d

# Or use the alfred command
alfred up --profile core

# Check service health
docker compose ps
```

### Minimal Development Mode (CORE_NO_LLM)
For development environments with limited resources, you can disable LLM services:

```bash
# Set environment variable to disable LLM services
export CORE_NO_LLM=true
docker compose --profile core up -d

# Or pass directly
CORE_NO_LLM=true alfred up --profile core
```

When `CORE_NO_LLM=true`:
- `llm-service`, `model-router`, `model-registry` are disabled
- Reduces to 8-service baseline for faster startup
- LLM-dependent features will be mocked/disabled

## Docker Container Issues

### Container Fails to Start

**Symptoms**:
- Container exits immediately after starting
- Docker logs show errors during startup

**Possible Causes**:
- Missing environment variables
- Port conflicts
- Volume mount issues
- Dependency service not available
- Registry authentication issues (for custom images)

**Solutions**:

1. **Check Docker logs**:
   ```bash
   docker logs <container-name>
   ```

2. **Verify environment variables**:
   ```bash
   docker inspect <container-name> | grep -A 20 "Env"
   ```

3. **Check port availability**:
   ```bash
   netstat -tulpn | grep <port>
   ```

4. **Verify volume mounts**:
   ```bash
   docker inspect <container-name> | grep -A 10 "Mounts"
   ```

5. **Ensure dependency services are running**:
   ```bash
   docker-compose ps
   ```

### "Invalid containerPort" Error

**Symptoms**:
- Error message: `failed to solve: invalid containerPort: #`
- Container fails to build or start

**Causes**:
- Invalid syntax in Docker Compose file
- Missing or incorrect volume configuration
- Malformed EXPOSE directive in Dockerfile

**Solutions**:

1. **Fix Docker Compose volume configuration**:
   ```yaml
   volumes:
     my-volume:
       driver: local  # Add this line
   ```

2. **Simplify Dockerfile**:
   ```dockerfile
   # Use simple EXPOSE directive
   EXPOSE 3000
   ```

3. **Validate Docker Compose file**:
   ```bash
   docker-compose config
   ```

## Port Configuration Problems

### Mission Control Port Conflicts

**Symptoms**:
- Mission Control UI not accessible
- Port already in use errors
- Inconsistent access URLs

**Causes**:
- Inconsistent port configuration between:
  - package.json scripts
  - next.config.js
  - docker-compose.yml files
  - .env.local files

**Solutions**:

1. **Standardize port configuration**:
   - Update package.json scripts to use port 3007:
     ```json
     "dev": "next dev -p 3007",
     "start": "next start -p 3007"
     ```

   - Update next.config.js to use port 3007:
     ```js
     serverRuntimeConfig: {
       port: parseInt(process.env.PORT, 10) || 3007,
     }
     ```

   - Update Docker Compose port mapping:
     ```yaml
     ports:
       - "3007:3000"  # Maps host port 3007 to container port 3000
     ```

   - Update .env.local URLs:
     ```
     NEXT_PUBLIC_SERVER_URL=http://localhost:3007
     ```

2. **Check for running processes on the same port**:
   ```bash
   lsof -i :3007
   ```

3. **Restart all services after port changes**:
   ```bash
   docker-compose down && docker-compose up -d
   ```

## Inter-Service Communication Failures

### "Cannot import name 'A2AEnvelope'" Error

**Symptoms**:
- Service containers exit with import errors
- Error message: `ImportError: cannot import name 'A2AEnvelope' from 'libs.a2a_adapter'`

**Causes**:
- Missing export in `libs/a2a_adapter/__init__.py`
- Stub implementation doesn't match what services expect

**Solutions**:

1. **Update `__init__.py` to export required classes**:
   ```python
   from .envelope import A2AEnvelope
   from .transport import PubSubTransport, SupabaseTransport
   from .middleware import PolicyMiddleware

   __all__ = ["A2AEnvelope", "PubSubTransport", "SupabaseTransport", "PolicyMiddleware"]
   ```

2. **Ensure envelope.py exists and contains the A2AEnvelope class**:
   ```python
   class A2AEnvelope(BaseModel):
       schema_version: str = "0.4"
       task_id: str = Field(default_factory=lambda: str(uuid4()))
       intent: str
       role: str = "assistant"
       content: Dict[str, Any] = Field(default_factory=dict)
       # ...
   ```

### "Cannot import name 'BaseAgent'" Error

**Symptoms**:
- Agent services fail to start
- Error message: `ImportError: cannot import name 'BaseAgent' from 'libs.agent_core'`

**Causes**:
- Missing export in `libs/agent_core/__init__.py`
- Stub implementation doesn't match what services expect

**Solutions**:

1. **Update `__init__.py` to export required classes**:
   ```python
   from .health import create_health_app
   from .base_agent import BaseAgent

   __all__ = ["create_health_app", "BaseAgent"]
   ```

2. **Verify base_agent.py contains the BaseAgent class**:
   ```python
   class BaseAgent(ABC):
       def __init__(
           self,
           name: str,
           version: str,
           supported_intents: List[str],
           pubsub_transport: PubSubTransport,
           supabase_transport: SupabaseTransport,
           policy_middleware: PolicyMiddleware
       ):
           # ...
   ```

### "'SupabaseTransport' object has no attribute '_pool'" Error

**Symptoms**:
- Agent services fail to start
- Error message: `AttributeError: 'SupabaseTransport' object has no attribute '_pool'`

**Causes**:
- Stub implementation doesn't match what services expect
- BaseAgent trying to access database connection pool that doesn't exist in stub

**Solutions**:

1. **Simplify BaseAgent methods that access `_pool`**:
   ```python
   async def _register_agent(self):
       """Register agent in database."""
       # Simplified stub implementation
       logger.info(
           "agent_registered",
           name=self.name,
           type=self.__class__.__name__,
           version=self.version,
           status="active",
           capabilities=self.supported_intents
       )
   ```

2. **Add missing methods to stub implementation**:
   ```python
   async def store_task(self, envelope: Any) -> str:
       """Stub method to store a task envelope."""
       logger.info("STUB: Storing task envelope", intent=getattr(envelope, "intent", "unknown"))
       return getattr(envelope, "task_id", "task-id-stub")
   ```

## API Integration Errors

### Social Intelligence API Connection Failures

**Symptoms**:
- Mission Control UI shows "Failed to fetch" errors
- Workflow results don't display
- Cannot schedule new workflows

**Causes**:
- Incorrect API URLs in environment configuration
- Missing API endpoints in Social Intelligence agent
- Network connectivity issues between containers

**Solutions**:

1. **Check API URL configuration**:
   - Verify `.env.local` contains correct URLs:
     ```
     SOCIAL_INTEL_URL=http://localhost:9000
     SOCIAL_INTEL_SERVICE_URL=http://social-intel:9000
     ```

2. **Implement fallback mechanisms**:
   ```javascript
   // In youtube-workflows.ts
   const baseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || '/api/social-intel';
   const fallbackBaseUrl = '/api/youtube'; // Fallback to local endpoints

   async function fetchWithFallback(url, options) {
     try {
       const response = await fetch(url, options);
       // ...
     } catch (error) {
       // Try fallback URL
       // ...
     }
   }
   ```

3. **Use container networking**:
   - In Docker environment, use service names for direct communication:
     ```
     SOCIAL_INTEL_SERVICE_URL=http://social-intel:9000
     ```

## UI Rendering Problems

### Workflow Results Not Displaying

**Symptoms**:
- Blank result pages
- Missing visualizations or data
- Console errors in browser

**Causes**:
- API response format mismatch
- Missing data properties
- React component errors

**Solutions**:

1. **Add data validation and defaults**:
   ```javascript
   // Ensure data has expected structure or provide defaults
   const results = data?.results || [];
   const metrics = data?.metrics || { totalVideos: 0, avgViews: 0 };
   ```

2. **Add error boundaries in React components**:
   ```javascript
   try {
     // Component rendering logic
   } catch (error) {
     console.error("Failed to render component:", error);
     return <ErrorFallback error={error} />;
   }
   ```

3. **Implement loading states**:
   ```javascript
   const [isLoading, setIsLoading] = useState(true);
   const [error, setError] = useState(null);

   // Show loading indicator while fetching
   if (isLoading) return <LoadingSpinner />;
   if (error) return <ErrorDisplay message={error.message} />;
   ```

## Database Connectivity Issues

### Supabase Connection Failures

**Symptoms**:
- Database connection errors in logs
- "Could not connect to database" messages
- Authentication failures

**Causes**:
- Incorrect database URL
- Missing environment variables
- Database service not running or ready

**Solutions**:

1. **Verify database URL configuration**:
   ```
   DATABASE_URL=postgresql://postgres:your-super-secret-password@supabase-db:5432/postgres
   ```

2. **Check database service is healthy**:
   ```bash
   docker-compose ps supabase-db
   ```

3. **Wait for database readiness**:
   ```bash
   # In startup scripts
   ./check-db-ready.sh
   ```

4. **Add retry logic for database connections**:
   ```python
   async def connect_with_retry(max_retries=5, retry_delay=2):
       retries = 0
       while retries < max_retries:
           try:
               # Connection logic
               return connection
           except Exception as e:
               retries += 1
               logger.warning(f"Database connection attempt {retries} failed: {e}")
               await asyncio.sleep(retry_delay)
       raise Exception("Failed to connect to database after maximum retries")
   ```

## Common Solutions

### Restart Services

Many issues can be resolved by restarting services:

```bash
# Restart specific service
docker-compose restart <service-name>

# Restart all services
docker-compose down && docker-compose up -d
```

### Update Environment Files

Ensure all environment files are correctly set:

```bash
# Check for missing variables
cp .env.example .env.local
# Edit .env.local with correct values
```

### Check Service Health

Use health check endpoints to verify service status:

```bash
# Check Mission Control
curl http://localhost:3007/api/health

# Check Social Intelligence
curl http://localhost:9000/health/

# Check Financial-Tax
curl http://localhost:9003/health/

# Check Legal Compliance
curl http://localhost:9002/health/
```

### View Container Logs

Always check container logs for detailed error information:

```bash
# View logs for specific service
docker logs <container-name>

# Follow logs in real-time
docker logs -f <container-name>

# View logs for all services
docker-compose logs
```

### Check Volume Configuration

Ensure Docker volumes are properly configured:

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect <volume-name>

# Remove and recreate volumes if needed
docker-compose down -v
docker-compose up -d
```

## Additional Resources

- [Docker Troubleshooting Guide](https://docs.docker.com/engine/troubleshooting/)
- [Next.js Troubleshooting](https://nextjs.org/docs/messages/runtime-configs)
- [FastAPI Documentation](https://fastapi.tiangolo.com/tutorial/debugging/)
- [Python Import System](https://docs.python.org/3/reference/import.html)

---

*This document is maintained as part of the Alfred Agent Platform v2 project and was last updated on May 6, 2025.*
