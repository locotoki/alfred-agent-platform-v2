# Model Router: Current Issues and Solutions

This document details the current issues with the Model Router component and proposed solutions.

## Issue 1: Model ID Handling

### Problem
The Model Router expects numeric IDs but receives string model names from the Streamlit UI, causing routing failures.

**Example**:
```
ERROR: Failed to get model gpt-3.5-turbo: {"detail":[{"type":"int_parsing","loc":["path","model_id"],"msg":"Input should be a valid integer, unable to parse string as an integer","input":"gpt-3.5-turbo"}]}
```

### Root Cause
- Model Registry assigns numeric IDs to models (e.g., TinyLlama has ID 11)
- Streamlit UI sends the string name (e.g., "tinyllama") in the `model_preference` field
- Model Router tries to interpret this string as an integer

### Current Workaround
Direct access to Ollama for local models, bypassing the Model Router entirely.

### Proposed Solution
1. Update the Model Router to accept both numeric IDs and string names
2. Add a lookup function that converts string names to numeric IDs
3. Validate model preferences before processing

**Implementation Plan**:
```python
# In Model Router's routing logic
def validate_model_preference(model_preference: Union[str, int]) -> Optional[int]:
    if isinstance(model_preference, int):
        return model_preference
    
    # If string is numeric, convert directly
    if model_preference.isdigit():
        return int(model_preference)
    
    # Look up by name
    model = get_model_by_name(model_preference)
    if model:
        return model.id
    
    return None
```

## Issue 2: Missing Endpoint Configurations

### Problem
Many models in the registry don't have properly configured endpoints, leading to routing failures.

### Root Cause
- Model registration doesn't enforce endpoint configuration
- Default endpoints aren't created for known providers

### Proposed Solution
1. Update model schema to require endpoint configuration
2. Add default endpoints for known providers (Ollama, OpenAI, Anthropic)
3. Create endpoint validation during model registration

**Implementation Plan**:
```python
# Default endpoint templates
DEFAULT_ENDPOINTS = {
    "ollama": {
        "endpoint_type": "rest",
        "endpoint_url": "http://ollama:11434/api/chat",
        "auth_type": "none"
    },
    "openai": {
        "endpoint_type": "rest",
        "endpoint_url": "https://api.openai.com/v1/chat/completions",
        "auth_type": "api_key"
    },
    "anthropic": {
        "endpoint_type": "rest",
        "endpoint_url": "https://api.anthropic.com/v1/messages",
        "auth_type": "api_key"
    }
}

# During model registration
def register_model(model_data):
    # If no endpoints provided, use default
    if not model_data.get("endpoints") and model_data.get("provider") in DEFAULT_ENDPOINTS:
        model_data["endpoints"] = [DEFAULT_ENDPOINTS[model_data["provider"]]]
```

## Issue 3: Error Handling and Fallbacks

### Problem
The Model Router fails completely when a model is unavailable, without trying alternatives.

### Root Cause
- No fallback chains implemented
- Error handling is minimal
- No graceful degradation strategy

### Proposed Solution
1. Implement fallback chains based on model capabilities
2. Add robust error handling with detailed messages
3. Create a preference-based fallback system

**Implementation Plan**:
```python
# In the routing logic
async def route_request(request, model_preference=None):
    # Primary model selection
    primary_model = select_model(request, model_preference)
    
    try:
        # Try primary model
        return await dispatch_to_model(request, primary_model)
    except ModelException as e:
        logger.warning(f"Primary model {primary_model.name} failed: {str(e)}")
        
        # Get fallback models
        fallbacks = get_fallback_models(primary_model)
        
        # Try each fallback
        for fallback in fallbacks:
            try:
                logger.info(f"Trying fallback model: {fallback.name}")
                return await dispatch_to_model(request, fallback)
            except ModelException as fallback_error:
                logger.warning(f"Fallback model {fallback.name} failed: {str(fallback_error)}")
                continue
                
        # If all models fail, raise error with details
        raise ModelRoutingError(
            f"All models failed for request {request.id}",
            tried_models=[primary_model] + fallbacks
        )
```

## Issue 4: Limited "Auto" Selection Intelligence

### Problem
The "Auto" option for model selection doesn't have real intelligence for picking the best model.

### Root Cause
- Basic rule-based selection with limited analysis
- No consideration of content characteristics
- No learning from past selections

### Proposed Solution
1. Implement basic content analysis (text complexity, subject, etc.)
2. Create a scoring system for model selection
3. Add rules for specific content types

**Implementation Plan**:
```python
# In the model selection logic
def analyze_request(request):
    """Analyze request content to determine characteristics."""
    analysis = {
        "content_types": detect_content_types(request),
        "token_count": estimate_token_count(request),
        "text_length": calculate_text_length(request),
        "complexity": estimate_complexity(request),
        "subject_area": detect_subject_area(request),
        "code_content": has_code(request),
        "image_content": has_images(request)
    }
    return analysis

def select_model(request, model_preference=None):
    """Select the best model based on request analysis."""
    if model_preference:
        return get_model_by_preference(model_preference)
        
    # Analyze request
    analysis = analyze_request(request)
    
    # Score models based on analysis
    scored_models = score_models_for_request(analysis)
    
    # Return highest scoring model
    return scored_models[0] if scored_models else get_default_model()
```

## Next Steps

1. **Immediate Fixes**:
   - Update Model Router to accept both string names and numeric IDs
   - Add default endpoints for known providers
   - Implement basic fallback handling

2. **Medium-term Improvements**:
   - Develop content analysis for better model selection
   - Create a configurable fallback system
   - Add learning capabilities to improve routing over time

See the [LLM-ROADMAP.md](../llm-roadmap.md) for the complete development plan.