# Model Router Service

The Model Router service is a key component of the Alfred Agent Platform that intelligently routes requests to the most appropriate AI model based on content characteristics, task requirements, and user context.

## Features

- **Intelligent Model Selection**: Routes requests to the optimal model based on request content, task type, and user context
- **Dynamic Rules Engine**: Configurable rules for model selection based on various criteria
- **Content Analysis**: Analyzes request content to determine characteristics like token count, content types, etc.
- **Fallback Mechanisms**: Automatically tries fallback models if primary model is unavailable
- **Metrics Tracking**: Captures usage metrics for performance monitoring and optimization
- **Model Discovery Integration**: Works with the Model Registry service to discover available models
- **Direct Model Access**: Allows direct access to specific models when needed

## API Endpoints

### Routing

- `POST /api/v1/route`: Routes a request to the most appropriate model
- `POST /api/v1/process`: End-to-end processing of a request (routing + dispatching)
- `POST /api/v1/generate/{model_id}`: Generate a response using a specific model

### Model Information

- `GET /api/v1/models`: List all available models
- `GET /api/v1/models/{model_id}`: Get detailed information about a specific model
- `GET /api/v1/models/task/{task_type}`: Get models that support a specific task
- `GET /api/v1/models/content/{content_type}`: Get models that support a specific content type

### Metrics

- `POST /api/v1/metrics`: Log model usage metrics

## Configuration

Key configuration options in `config.py`:

- **Default Model**: Fallback model when no routing rules match
- **Request Timeout**: Maximum request processing time
- **Content Type Thresholds**: Configurable thresholds for content characteristics
- **Selection Rules**: Rules for model selection based on request attributes
- **Fallback Models**: Configuration for model fallback chains

## Architecture

The service consists of several key components:

1. **Router Engine**: Core logic for model selection based on rules
2. **Request Analyzer**: Analyzes incoming requests to determine characteristics
3. **Model Dispatcher**: Handles sending requests to the selected model
4. **Registry Client**: Communicates with the Model Registry service
5. **API Router**: REST API endpoints for external interaction

## Development

### Installation

```bash
# Install dependencies
pip install -r requirements.txt

# Run development server
uvicorn app.main:app --reload
```

### Environment Variables

- `PORT`: Service port (default: 8080)
- `DEBUG`: Enable debug mode (default: False)
- `MODEL_REGISTRY_URL`: URL of the Model Registry service
- `DATABASE_URL`: PostgreSQL connection string
- `JWT_SECRET`: Secret for JWT authentication

## Docker

```bash
# Build Docker image
docker build -t alfred-model-router .

# Run Docker container
docker run -p 8080:8080 alfred-model-router
```

## Testing

```bash
# Run tests
pytest
```