# Model Router Design

## Overview

The Model Router is a critical service that determines which AI model to use for a given request based on various factors including task type, content, complexity, and resource constraints. It serves as the intelligent gateway between agent services and the actual model implementations.

## Core Components

### 1. Request Analyzer

The Request Analyzer examines incoming requests to determine their characteristics:

```python
class RequestAnalyzer:
    def __init__(self, config):
        self.config = config
        self.content_analyzers = {
            'text': TextAnalyzer(),
            'image': ImageAnalyzer(),
            'document': DocumentAnalyzer(),
            'code': CodeAnalyzer()
        }
        
    async def analyze_request(self, request):
        # Extract request details
        content = request.get('content', '')
        content_type = request.get('content_type', 'text')
        
        # Determine task type
        task_type = self._determine_task_type(request)
        
        # Analyze content complexity
        complexity = await self._analyze_complexity(content, content_type)
        
        # Identify special requirements
        special_requirements = self._identify_special_requirements(request)
        
        return {
            'task_type': task_type,
            'content_type': content_type,
            'complexity': complexity,
            'special_requirements': special_requirements,
            'content_length': len(content) if isinstance(content, str) else 0,
            'estimated_tokens': self._estimate_tokens(content, content_type)
        }
    
    def _determine_task_type(self, request):
        # Use heuristics or ML to determine task type
        # Examples: summarization, qa, generation, analysis, code, etc.
        
    async def _analyze_complexity(self, content, content_type):
        # Route to appropriate analyzer based on content type
        analyzer = self.content_analyzers.get(content_type, self.content_analyzers['text'])
        return await analyzer.analyze_complexity(content)
    
    def _identify_special_requirements(self, request):
        # Check for special flags or requirements
        # Examples: high accuracy, fast response, code execution, etc.
    
    def _estimate_tokens(self, content, content_type):
        # Estimate token count based on content type and length
```

### 2. Model Selection Engine

The Model Selection Engine uses the analysis and available models to select the optimal model:

```python
class ModelSelectionEngine:
    def __init__(self, registry_client, config):
        self.registry_client = registry_client
        self.config = config
        self.rule_engine = RuleEngine(config)
        self.fallback_model = config.get('fallback_model', 'llama3')
        
    async def select_model(self, request_analysis, user_preferences=None):
        # Get available models
        available_models = await self.registry_client.get_available_models()
        
        # Apply user preferences if provided
        if user_preferences and user_preferences.get('preferred_model'):
            preferred_model = user_preferences.get('preferred_model')
            if preferred_model in available_models:
                return preferred_model
        
        # Apply selection rules
        selected_model = self.rule_engine.apply_rules(
            request_analysis,
            available_models,
            user_preferences
        )
        
        # If no model selected, use fallback
        if not selected_model:
            selected_model = self.fallback_model
            
        # Get model parameters
        parameters = await self._get_model_parameters(
            selected_model, 
            request_analysis
        )
        
        return {
            'model_id': selected_model,
            'parameters': parameters
        }
    
    async def _get_model_parameters(self, model_id, request_analysis):
        # Fetch base parameters for the model
        base_params = await self.registry_client.get_model_parameters(model_id)
        
        # Adjust parameters based on request characteristics
        adjusted_params = self._adjust_parameters(base_params, request_analysis)
        
        return adjusted_params
    
    def _adjust_parameters(self, base_params, request_analysis):
        # Adjust temperature, top_p, etc. based on task type and complexity
        adjusted = base_params.copy()
        
        # Examples of adjustments:
        if request_analysis['task_type'] == 'creative':
            adjusted['temperature'] = min(base_params.get('temperature', 0.7) * 1.2, 1.0)
        elif request_analysis['task_type'] == 'factual':
            adjusted['temperature'] = max(base_params.get('temperature', 0.7) * 0.5, 0.1)
            
        return adjusted
```

### 3. Rule Engine

The Rule Engine applies configurable rules to select the appropriate model:

```python
class RuleEngine:
    def __init__(self, config):
        self.config = config
        self.rules = self._load_rules()
        
    def _load_rules(self):
        # Load rules from configuration
        return self.config.get('model_selection_rules', [])
    
    def apply_rules(self, request_analysis, available_models, user_preferences=None):
        # Apply each rule in sequence
        for rule in self.rules:
            match = self._evaluate_rule_conditions(rule, request_analysis)
            if match:
                model = rule['model']
                if model in available_models:
                    return model
                    
        # If no rules match, apply default selection logic
        return self._apply_default_selection(request_analysis, available_models)
    
    def _evaluate_rule_conditions(self, rule, request_analysis):
        # Check if all conditions in the rule match
        for condition_key, condition_value in rule.get('conditions', {}).items():
            if condition_key not in request_analysis:
                return False
                
            if isinstance(condition_value, dict):
                # Handle range conditions
                if 'min' in condition_value and request_analysis[condition_key] < condition_value['min']:
                    return False
                if 'max' in condition_value and request_analysis[condition_key] > condition_value['max']:
                    return False
            elif request_analysis[condition_key] != condition_value:
                return False
                
        return True
    
    def _apply_default_selection(self, request_analysis, available_models):
        # Default selection logic based on content type and complexity
        complexity = request_analysis.get('complexity', 0.5)
        
        if 'image' in request_analysis.get('content_type', ''):
            # Select image-capable model
            for model_name in ['gpt4o', 'llava', 'bakllava']:
                if model_name in available_models:
                    return model_name
                    
        if complexity > 0.8:
            # High complexity task
            for model_name in ['gpt41', 'gpt4o', 'claude-3-opus']:
                if model_name in available_models:
                    return model_name
        elif complexity > 0.5:
            # Medium complexity task
            for model_name in ['gpt41mini', 'llama3:70b', 'claude-3-sonnet']:
                if model_name in available_models:
                    return model_name
        else:
            # Low complexity task
            for model_name in ['llama3', 'mistral', 'gpt35turbo']:
                if model_name in available_models:
                    return model_name
                    
        # If nothing matched, return the first available model
        return next(iter(available_models), None)
```

### 4. Request Dispatcher

The Request Dispatcher sends the request to the selected model:

```python
class RequestDispatcher:
    def __init__(self, registry_client, config):
        self.registry_client = registry_client
        self.config = config
        self.dispatchers = {
            'openai': OpenAIDispatcher(),
            'anthropic': AnthropicDispatcher(),
            'ollama': OllamaDispatcher(),
            'custom': CustomModelDispatcher()
        }
        
    async def dispatch_request(self, request, selection):
        # Get model details
        model_id = selection['model_id']
        model_details = await self.registry_client.get_model_details(model_id)
        
        # Get appropriate dispatcher
        provider = model_details.get('provider', 'openai')
        dispatcher = self.dispatchers.get(provider)
        if not dispatcher:
            raise ValueError(f"No dispatcher available for provider: {provider}")
        
        # Prepare request with selected parameters
        prepared_request = self._prepare_request(request, selection['parameters'])
        
        # Dispatch request
        start_time = time.time()
        try:
            response = await dispatcher.dispatch(
                prepared_request, 
                model_details
            )
            
            # Record metrics
            duration = time.time() - start_time
            await self._record_usage(model_id, prepared_request, response, duration)
            
            return response
        except Exception as e:
            # Handle error and try fallback if needed
            error_info = {
                'error': str(e),
                'model_id': model_id,
                'timestamp': time.time()
            }
            await self._record_error(model_id, error_info)
            
            # Try fallback if configured
            if self.config.get('use_fallback', True):
                return await self._try_fallback(request, selection, error_info)
            
            # Otherwise re-raise
            raise
            
    def _prepare_request(self, request, parameters):
        # Merge original request with selected parameters
        prepared = request.copy()
        prepared['parameters'] = parameters
        return prepared
        
    async def _record_usage(self, model_id, request, response, duration):
        # Calculate tokens
        input_tokens = self._count_tokens(request.get('content', ''))
        output_tokens = self._count_tokens(response.get('content', ''))
        
        # Record in registry
        await self.registry_client.record_usage(
            model_id=model_id,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
            duration=duration
        )
        
    async def _record_error(self, model_id, error_info):
        # Record error in registry
        await self.registry_client.record_error(
            model_id=model_id,
            error_info=error_info
        )
        
    async def _try_fallback(self, request, selection, error_info):
        # Get fallback model
        fallback_model = self.config.get('fallback_model', 'llama3')
        
        # Create new selection with fallback
        fallback_selection = {
            'model_id': fallback_model,
            'parameters': selection['parameters']
        }
        
        # Log fallback attempt
        logger.warning(
            f"Falling back to {fallback_model} after error with {selection['model_id']}: {error_info['error']}"
        )
        
        # Retry with fallback
        return await self.dispatch_request(request, fallback_selection)
    
    def _count_tokens(self, content):
        # Estimate token count from content
        if not content:
            return 0
        # Simple approximation: ~4 chars per token for English text
        return len(content) // 4
```

## Integration Points

### Model Registry Integration

- Queries registry for available models
- Retrieves model capabilities and parameters
- Records usage statistics and performance metrics

### Agent Service Integration

- Exposes a RESTful API at `/api/v1/model`
- Accepts requests with content and constraints
- Returns model-generated responses

### Monitoring Integration

- Exports Prometheus metrics for model usage
- Records latency and token usage
- Tracks error rates and fallback usage

## Security Considerations

- JWT authentication for API access
- Rate limiting to prevent abuse
- Validation of input to prevent prompt injection
- Content filtering for safety
- API key rotation for external services

## Implementation Details

### Container Configuration

```yaml
model-router:
  build:
    context: ./services/model-router
    dockerfile: Dockerfile
  image: alfred-model-router:latest
  container_name: model-router
  ports:
    - "8701:8701"
  environment:
    - DATABASE_URL=${ALFRED_DATABASE_URL:-postgresql://${DB_USER:-postgres}:${DB_PASSWORD:-your-super-secret-password}@db-postgres:5432/${DB_NAME:-postgres}}
    - REDIS_URL=redis://redis:6379/1
    - JWT_SECRET=${DB_JWT_SECRET:-your-super-secret-jwt-token}
    - LOG_LEVEL=info
    - MODEL_REGISTRY_URL=http://model-registry:8700
    - OPENAI_API_KEY=${ALFRED_OPENAI_API_KEY}
    - ANTHROPIC_API_KEY=${ALFRED_ANTHROPIC_API_KEY}
    - OLLAMA_URL=http://llm-service:11434
    - DEFAULT_MODEL=llama3
    - FALLBACK_MODEL=llama3:8b
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8701/health"]
    interval: 30s
    timeout: 10s
    retries: 3
    start_period: 10s
  depends_on:
    db-postgres:
      condition: service_healthy
    redis:
      condition: service_started
    model-registry:
      condition: service_started
  restart: unless-stopped
  networks:
    - alfred-network
  labels:
    com.docker.compose.project: "alfred"
    com.docker.compose.group: "core-infrastructure"
    com.docker.compose.service: "model-router"
```

### API Endpoints

```yaml
# Model Router API
POST /api/v1/model/generate
  - Request content-based model generation
  - Automatically selects appropriate model

POST /api/v1/model/generate/{model_id}
  - Request generation from a specific model
  - Bypasses selection algorithm

GET /api/v1/model/available
  - List available models with capabilities

POST /api/v1/model/analyze
  - Analyze content without generating
  - Returns complexity scores and recommendations

GET /api/v1/model/statistics
  - Get usage statistics for models

GET /api/v1/model/health
  - Check health of model connections
```

### Technology Stack

- Python FastAPI for the API server
- SQLAlchemy for database interactions
- Redis for caching and rate limiting
- Pydantic for data validation
- AsyncIO for non-blocking operations
- Prometheus for metrics collection

## Configuration Rules

```yaml
# Sample model selection rules
model_selection_rules:
  - name: "Image Content Rule"
    conditions:
      content_type: "image"
      complexity:
        min: 0.7
    model: "gpt4o"
    
  - name: "Document Analysis Rule"
    conditions:
      content_type: "document"
      task_type: "analysis"
    model: "llama3:70b"
    
  - name: "Code Generation Rule"
    conditions:
      task_type: "code"
    model: "codellama"
    
  - name: "Complex Reasoning Rule"
    conditions:
      complexity:
        min: 0.8
    model: "gpt41"
    
  - name: "Quick Response Rule"
    conditions:
      special_requirements: "low_latency"
    model: "llama3:8b"
```

## Expected Behavior

1. During startup:
   - Connect to model registry
   - Load model selection rules
   - Initialize dispatchers for each model provider
   - Start serving API requests

2. During request processing:
   - Analyze incoming request for content type and complexity
   - Select appropriate model based on rules and analysis
   - Dispatch request to selected model provider
   - Process and return response
   - Record usage metrics

3. Error handling:
   - Detect model failures
   - Attempt fallback to alternative models
   - Log errors for monitoring
   - Return appropriate error responses