# Development Guidelines

**Last Updated:** 2025-05-12  
**Owner:** Development Team  
**Status:** Active

## Overview

This document provides comprehensive development guidelines for the Alfred Agent Platform v2. These guidelines ensure consistency, quality, and maintainability across all platform components. By following these standards, developers will create code that integrates seamlessly with the platform, follows best practices, and maintains the architectural integrity of the system. These guidelines apply to all development work including agent implementation, service development, UI components, and infrastructure code.

## Project Metadata

| Attribute | Value |
|-----------|-------|
| Status | Active |
| Start Date | 2025-01-15 |
| Last Updated | 2025-05-12 |
| Current Phase | Phase 6: Financial-Tax Agent |
| Repository | [AI Agent Platform v2](https://github.com/alfred-agent-platform/v2) |

## Development Environment Setup

### Prerequisites

- Python 3.11+
- Node.js 18+
- Docker Desktop 4.15+
- Docker Compose v2
- Make
- Git

### Initial Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/alfred-agent-platform/v2.git
   cd alfred-agent-platform-v2
   ```

2. **Set up environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your configuration
   ```

3. **Install dependencies**
   ```bash
   make install
   ```

4. **Start the development environment**
   ```bash
   make dev
   ```

5. **Verify the installation**
   ```bash
   make test
   ```

### Development Workflows

#### Local Development

For local development, the recommended workflow is:

1. Start core services with Docker Compose:
   ```bash
   make up-core
   ```

2. For agent development, start additional required services:
   ```bash
   make up-atlas  # For RAG capabilities
   make up-monitoring  # For observability
   ```

3. Run local code with hot reloading:
   ```bash
   # For Python services
   cd services/your-service
   python -m uvicorn app.main:app --reload

   # For Node.js services
   cd services/your-service
   npm run dev
   ```

#### Working with LLM Services

When developing with LLM integration:

1. Configure API keys in `.env.llm`
2. Start LLM services:
   ```bash
   ./start-llm-with-keys.sh
   ```
3. Use the model registry and router for service development
4. Test with local models via Ollama for faster iteration

## Code Style Guidelines

### Python Code Style

- **Python Version**: 3.11+
- **Line Length**: 100 characters maximum
- **Formatting**: Black with default settings
- **Import Sorting**: isort with Black profile
- **Type Hints**: Required for all public functions and classes
- **Docstrings**: Google-style docstrings for all public functions and classes
- **Linters**: Flake8, mypy with strict type checking
- **Virtual Environment**: Use venv or Poetry for dependency management

```python
from typing import Dict, List, Optional
import structlog
from pydantic import BaseModel

logger = structlog.get_logger(__name__)

class UserProfile(BaseModel):
    """User profile data model.
    
    Contains basic user information and preferences.
    """
    user_id: str
    name: str
    email: str
    preferences: Dict[str, str]
    roles: List[str]
    profile_image_url: Optional[str] = None

def process_user_data(profile: UserProfile, update_preferences: bool = False) -> UserProfile:
    """Process user data and optionally update preferences.
    
    Args:
        profile: The user profile to process
        update_preferences: Whether to update preferences
        
    Returns:
        The processed user profile
        
    Raises:
        ValueError: If the profile is invalid
    """
    try:
        # Processing logic
        if update_preferences:
            profile.preferences.update({"theme": "dark"})
        return profile
    except Exception as e:
        logger.error("Failed to process user data", 
                    error=str(e), 
                    user_id=profile.user_id)
        raise ValueError(f"Invalid profile data: {str(e)}")
```

### JavaScript/TypeScript Code Style

- **Node.js Version**: 18+
- **TypeScript**: Required for all new code
- **Linting**: ESLint with TypeScript plugin
- **Formatting**: Prettier
- **Line Length**: 100 characters maximum
- **Package Manager**: npm or yarn
- **Module System**: ES Modules
- **Testing Framework**: Jest or Vitest

```typescript
import { Logger } from '../utils/logger';

interface TaskData {
  id: string;
  title: string;
  status: 'pending' | 'in_progress' | 'completed';
  priority: number;
  assignee?: string;
}

/**
 * Processes task data and updates the status
 * @param task - The task to process
 * @param newStatus - The new status to apply
 * @returns The updated task
 * @throws Error if the task is invalid
 */
export function processTask(task: TaskData, newStatus: TaskData['status']): TaskData {
  try {
    if (!task.id) {
      throw new Error('Task ID is required');
    }
    
    const updatedTask = {
      ...task,
      status: newStatus,
      updatedAt: new Date().toISOString()
    };
    
    return updatedTask;
  } catch (error) {
    Logger.error('Failed to process task', {
      taskId: task.id,
      error: error instanceof Error ? error.message : 'Unknown error'
    });
    throw error;
  }
}
```

### Docker Guidelines

- **Base Images**: Use official slim images where possible
- **Multi-stage Builds**: Use for optimized production images
- **Layer Caching**: Optimize for build performance
- **Environment Variables**: Use for configuration
- **User Permissions**: Don't run as root
- **Health Checks**: Include for all services
- **Resource Limits**: Configure memory and CPU limits

```dockerfile
FROM python:3.11-slim AS builder

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.11-slim

WORKDIR /app

COPY --from=builder /usr/local/lib/python3.11/site-packages /usr/local/lib/python3.11/site-packages
COPY . .

RUN useradd -m appuser
USER appuser

ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
```

## Testing Standards

### Testing Requirements

- **Coverage Targets**: 80% minimum code coverage
- **Test Types**:
  - Unit Tests: Required for all components
  - Integration Tests: Required for all services
  - End-to-End Tests: Required for critical workflows
- **Mocking**: Use pytest-mock or unittest.mock for external dependencies
- **Fixtures**: Use pytest fixtures for test setup

### Test Organization

- Tests should mirror the application structure
- Group tests by module/component
- Use descriptive test names that explain what is being tested

### Testing Practices

1. **Unit Tests**
   - Test functions and classes in isolation
   - Mock external dependencies
   - Focus on business logic and edge cases
   - Fast execution (milliseconds per test)

```python
def test_process_user_data_updates_preferences():
    # Arrange
    profile = UserProfile(
        user_id="user123",
        name="Test User",
        email="test@example.com",
        preferences={"notify": "true"},
        roles=["user"]
    )
    
    # Act
    result = process_user_data(profile, update_preferences=True)
    
    # Assert
    assert result.preferences["theme"] == "dark"
    assert result.preferences["notify"] == "true"
```

2. **Integration Tests**
   - Test component interactions
   - Use real dependencies where practical
   - Include database and API integration
   - Tag with `@pytest.mark.integration`

```python
@pytest.mark.integration
async def test_task_creation_persists_to_database():
    # Arrange
    task_service = TaskService(db_connection)
    task_data = {"title": "Test Task", "priority": 1}
    
    # Act
    created_task = await task_service.create_task(task_data)
    retrieved_task = await task_service.get_task(created_task.id)
    
    # Assert
    assert retrieved_task is not None
    assert retrieved_task.title == "Test Task"
    assert retrieved_task.id == created_task.id
```

3. **End-to-End Tests**
   - Test complete user journeys
   - Use real service interactions
   - Tag with `@pytest.mark.e2e`
   - Run in CI/CD pipeline

```python
@pytest.mark.e2e
async def test_content_analysis_workflow():
    # Arrange
    client = TestClient(app)
    input_data = {"url": "https://example.com/article"}
    
    # Act
    response = client.post("/api/analyze", json=input_data)
    result_id = response.json()["result_id"]
    
    # Poll for completion
    status = "processing"
    for _ in range(10):
        status_response = client.get(f"/api/results/{result_id}")
        status = status_response.json()["status"]
        if status == "completed":
            break
        time.sleep(1)
    
    # Get final result
    result_response = client.get(f"/api/results/{result_id}")
    
    # Assert
    assert status == "completed"
    assert result_response.status_code == 200
    assert "sentiment" in result_response.json()
    assert "keywords" in result_response.json()
```

## Agent Development Guidelines

### Agent Structure

New agents should follow this structure:

```
agents/
└── your_agent/
    ├── __init__.py
    ├── agent.py         # Main agent implementation
    ├── models.py        # Data models
    ├── chains.py        # LangChain/LangGraph chains
    └── tests/
        ├── __init__.py
        ├── test_agent.py
        ├── test_models.py
        └── test_chains.py
```

### Agent Implementation

1. **Base Class**: Extend the `BaseAgent` class
2. **Intent Handling**: Implement handlers for each supported intent
3. **Error Handling**: Implement proper error handling and task state updates
4. **Logging**: Use structured logging with context
5. **Metrics**: Export relevant metrics for monitoring

Example agent implementation:

```python
from libs.agent_core import BaseAgent
from libs.a2a_adapter import A2AEnvelope
from typing import Dict, Any
import structlog

logger = structlog.get_logger(__name__)

class MarketAnalyzerAgent(BaseAgent):
    def __init__(self):
        super().__init__(
            name="market-analyzer",
            version="1.0.0",
            supported_intents=["ANALYZE_MARKET", "MARKET_FORECAST"]
        )
        self.metrics = self._setup_metrics()
    
    async def process_task(self, envelope: A2AEnvelope) -> Dict[str, Any]:
        logger.info("Processing task", 
                   task_id=envelope.task_id, 
                   intent=envelope.intent)
                   
        self.metrics.task_received.inc()
        
        try:
            if envelope.intent == "ANALYZE_MARKET":
                return await self._analyze_market(envelope)
            elif envelope.intent == "MARKET_FORECAST":
                return await self._forecast_market(envelope)
            else:
                raise ValueError(f"Unsupported intent: {envelope.intent}")
        except Exception as e:
            logger.error("Task processing failed", 
                        task_id=envelope.task_id,
                        error=str(e),
                        stack_trace=traceback.format_exc())
            self.metrics.task_failed.inc()
            raise
    
    def _setup_metrics(self):
        from prometheus_client import Counter, Histogram
        
        class Metrics:
            def __init__(self):
                self.task_received = Counter(
                    'market_analyzer_tasks_received', 
                    'Number of tasks received',
                    ['intent']
                )
                self.task_completed = Counter(
                    'market_analyzer_tasks_completed', 
                    'Number of tasks completed',
                    ['intent']
                )
                self.task_failed = Counter(
                    'market_analyzer_tasks_failed', 
                    'Number of tasks failed',
                    ['intent']
                )
                self.processing_time = Histogram(
                    'market_analyzer_processing_time', 
                    'Time to process tasks',
                    ['intent']
                )
        
        return Metrics()
```

## Error Handling

### Error Handling Guidelines

1. **Structured Errors**: Use domain-specific exception classes
2. **Contextual Information**: Include relevant context in exception messages
3. **Error Propagation**: Catch and transform errors at API boundaries
4. **Retry Logic**: Implement appropriate retry logic for transient failures
5. **Structured Logging**: Log errors with structured context

### Error Handling Patterns

```python
# Domain-specific exceptions
class MarketAnalysisError(Exception):
    """Base exception for market analysis errors."""
    pass

class DataSourceError(MarketAnalysisError):
    """Error accessing market data sources."""
    pass

class AnalysisError(MarketAnalysisError):
    """Error performing market analysis."""
    pass

# Error handling with context
def analyze_market_data(market_id: str, time_period: str) -> Dict[str, Any]:
    try:
        data_source = get_data_source(market_id)
        
        if not data_source:
            raise DataSourceError(f"Data source not found for market: {market_id}")
            
        try:
            market_data = data_source.get_data(time_period)
        except Exception as e:
            raise DataSourceError(f"Failed to fetch data: {str(e)}")
            
        # Analysis logic
        result = perform_analysis(market_data)
        return result
    except MarketAnalysisError:
        # Re-raise domain exceptions
        raise
    except Exception as e:
        # Transform generic exceptions
        raise AnalysisError(f"Unexpected error: {str(e)}")
```

### API Error Responses

For REST API endpoints, use consistent error response structure:

```json
{
  "error": {
    "code": "MARKET_DATA_NOT_FOUND",
    "message": "Market data not found for ID: market123",
    "details": {
      "market_id": "market123",
      "time_period": "last_30_days"
    },
    "request_id": "req-abc-123"
  }
}
```

## Logging Standards

### Logging Guidelines

1. **Structured Logging**: Use structlog for Python and a structured logger for JS/TS
2. **Context Attributes**: Include relevant context in all log entries
3. **Log Levels**: Use appropriate log levels (DEBUG, INFO, WARNING, ERROR)
4. **Sensitive Data**: Never log sensitive data or credentials
5. **Correlation IDs**: Include trace and span IDs for distributed tracing

### Logging Examples

Python logging:

```python
import structlog
from uuid import uuid4

logger = structlog.get_logger(__name__)

def process_order(order_data, user_id):
    order_id = str(uuid4())
    # Bind context to logger
    log = logger.bind(
        order_id=order_id,
        user_id=user_id
    )
    
    log.info("Processing order started")
    
    try:
        # Process order
        result = execute_order(order_data)
        log.info("Order processed successfully", 
                items_count=len(order_data["items"]))
        return result
    except ValidationError as e:
        log.warning("Order validation failed", 
                   validation_errors=e.errors())
        raise
    except Exception as e:
        log.error("Order processing failed", 
                 error=str(e),
                 stack_trace=traceback.format_exc())
        raise
```

TypeScript logging:

```typescript
import { Logger } from '../utils/logger';

function processPayment(paymentData: PaymentData, userId: string): Promise<PaymentResult> {
  const paymentId = generateId();
  const log = Logger.child({
    paymentId,
    userId,
    paymentMethod: paymentData.method
  });

  log.info('Payment processing started');

  try {
    // Process payment
    const result = await executePayment(paymentData);
    log.info('Payment processed successfully', { amount: paymentData.amount });
    return result;
  } catch (error) {
    log.error('Payment processing failed', {
      error: error instanceof Error ? error.message : 'Unknown error'
    });
    throw error;
  }
}
```

## Documentation Standards

### Code Documentation

1. **Docstrings**: Required for all public functions, classes, and methods
2. **Example Usage**: Include example usage for complex functions
3. **Parameter Documentation**: Document all parameters, return values, and exceptions
4. **Architecture Documentation**: Maintain up-to-date architecture diagrams
5. **README Files**: Include comprehensive README.md files for all components

### Documentation Format

For Python, use Google-style docstrings:

```python
def perform_analysis(
    market_data: Dict[str, Any],
    indicators: List[str] = None,
    time_period: str = "1d"
) -> AnalysisResult:
    """Perform market analysis on the given market data.
    
    Analyzes market data using specified technical indicators
    and returns the analysis result.
    
    Args:
        market_data: Dictionary containing market OHLCV data
        indicators: List of technical indicators to use.
                    If None, uses default indicators.
        time_period: Time period for the analysis (e.g., "1d", "4h")
    
    Returns:
        An AnalysisResult object containing the analysis results
        
    Raises:
        AnalysisError: If analysis cannot be performed
        
    Example:
        ```python
        data = get_market_data("BTC/USD")
        result = perform_analysis(
            data,
            indicators=["RSI", "MACD"],
            time_period="4h"
        )
        print(result.recommendation)
        ```
    """
    # Implementation
```

## Performance Considerations

### Performance Guidelines

1. **Asynchronous Operations**: Use async/await for I/O-bound operations
2. **Caching**: Implement appropriate caching strategies
3. **Database Access**: Optimize database queries and use connection pooling
4. **Resource Cleanup**: Properly close connections and release resources
5. **Monitoring**: Implement performance metrics and monitoring

### Performance Patterns

```python
import asyncio
from functools import lru_cache
from contextlib import asynccontextmanager

# Caching example
@lru_cache(maxsize=1000)
def get_market_configuration(market_id: str) -> MarketConfig:
    """Get market configuration with caching."""
    return load_market_config(market_id)

# Resource management example
@asynccontextmanager
async def get_database_connection():
    """Get a database connection from the pool."""
    conn = await pool.acquire()
    try:
        yield conn
    finally:
        await pool.release(conn)

# Batch processing example
async def process_items(items: List[Item]) -> List[Result]:
    """Process items in parallel with concurrency control."""
    semaphore = asyncio.Semaphore(10)  # Limit concurrency
    
    async def process_with_semaphore(item):
        async with semaphore:
            return await process_item(item)
    
    return await asyncio.gather(*[process_with_semaphore(item) for item in items])
```

## Security Guidelines

### Security Best Practices

1. **Input Validation**: Validate all input data
2. **Authentication**: Use proper authentication for all endpoints
3. **Authorization**: Implement proper authorization checks
4. **Secret Management**: Never hardcode secrets; use environment variables or secret management systems
5. **Dependency Security**: Regularly update dependencies and scan for vulnerabilities
6. **Error Messages**: Avoid exposing sensitive information in error messages

### Security Patterns

```python
from pydantic import BaseModel, validator
from jose import jwt
from fastapi import Depends, HTTPException, Security
from fastapi.security import OAuth2PasswordBearer

# Input validation
class UserCreateRequest(BaseModel):
    username: str
    email: str
    password: str
    
    @validator('username')
    def username_must_be_valid(cls, v):
        if len(v) < 3 or len(v) > 50:
            raise ValueError('Username must be between 3 and 50 characters')
        if not v.isalnum():
            raise ValueError('Username must be alphanumeric')
        return v
    
    @validator('email')
    def email_must_be_valid(cls, v):
        if '@' not in v:
            raise ValueError('Invalid email format')
        return v
    
    @validator('password')
    def password_must_be_strong(cls, v):
        if len(v) < 8:
            raise ValueError('Password must be at least 8 characters')
        return v

# Authentication
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")

async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if user_id is None:
            raise HTTPException(status_code=401, detail="Invalid authentication credentials")
    except JWTError:
        raise HTTPException(status_code=401, detail="Invalid authentication credentials")
    
    user = await get_user(user_id)
    if user is None:
        raise HTTPException(status_code=401, detail="User not found")
    
    return user

# Authorization
def check_permission(required_permission):
    def permission_checker(user = Depends(get_current_user)):
        if required_permission not in user.permissions:
            raise HTTPException(
                status_code=403,
                detail=f"Permission denied: {required_permission} required"
            )
        return user
    return permission_checker
```

## Deployment Guidelines

### CI/CD Practices

1. **Automated Testing**: Run all tests in CI pipeline
2. **Static Analysis**: Run linters and static type checkers
3. **Security Scanning**: Scan dependencies for vulnerabilities
4. **Build Artifacts**: Create versioned build artifacts
5. **Deployment Automation**: Automate deployment process
6. **Environment Configuration**: Use environment-specific configuration

### Deployment Checklist

- [ ] All tests passing
- [ ] No linting issues
- [ ] No security vulnerabilities in dependencies
- [ ] Database migrations included
- [ ] Environment variables documented
- [ ] Metrics and monitoring configured
- [ ] Logging properly configured
- [ ] Health checks implemented
- [ ] Deployment rollback plan

## Conclusion

These development guidelines provide a comprehensive framework for maintaining code quality, consistency, and developer productivity on the Alfred Agent Platform v2. Adherence to these guidelines ensures the platform remains maintainable, scalable, and reliable as it evolves.

For additional project-specific documentation, refer to the [Project Integration Guide](./project-integration-guide.md) and [Technical Design Guide](./technical-design.md).

## References

- [Python Style Guide (PEP 8)](https://pep8.org/)
- [TypeScript Coding Guidelines](https://github.com/Microsoft/TypeScript/wiki/Coding-guidelines)
- [Twelve-Factor App Methodology](https://12factor.net/)
- [OWASP Security Best Practices](https://owasp.org/www-project-top-ten/)
- [Project Integration Guide](./project-integration-guide.md)
- [Technical Design Guide](./technical-design.md)