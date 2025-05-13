# Next Steps for LLM Integration

This document outlines the immediate next steps to improve the LLM integration in the Alfred Agent Platform.

## Immediate Priorities

### 1. Create Pull Request for Current Implementation

- **Description**: Package the current direct Ollama access implementation into a pull request
- **Files to Include**:
  - Updated `streamlit_chat_ui.py` with direct Ollama access
  - Utility scripts (`joke.py`, `direct-chat.py`, etc.)
  - Documentation files
  - Setup scripts
- **Testing Required**: 
  - Verify Ollama models work with different prompts
  - Confirm UI properly shows real responses
  - Ensure debug mode shows API details

### 2. Fix Model Router ID Handling

- **Description**: Update the Model Router to accept both string names and numeric IDs
- **Implementation Plan**:
  - Add a lookup function that converts names to IDs in the router
  - Modify the router's validation logic
  - Add proper error messages for invalid models
- **Files to Modify**:
  - `model-router/app/services/router_engine.py`
  - `model-router/app/api/router.py`

### 3. Add Endpoint Configurations

- **Description**: Add proper endpoint configurations for all models in the registry
- **Implementation Plan**:
  - Define default endpoints for each provider type
  - Update existing model registrations
  - Add validation for endpoint configuration
- **Files to Modify**:
  - `model-registry/app/models/model.py`
  - `model-registry/app/api/models.py`
  - `model-registry/init-db.sql`

### 4. Implement Basic Auto Selection

- **Description**: Add simple but functional logic for the "Auto" model selection option
- **Implementation Plan**:
  - Implement basic content analysis
  - Create simple scoring rules for model selection
  - Add fallback to reliable models (e.g., TinyLlama)
- **Files to Modify**:
  - `model-router/app/services/selection_rules.py`
  - `model-router/app/services/router_engine.py`

### 5. Improve Error Handling

- **Description**: Add better error handling and informative messages throughout the system
- **Implementation Plan**:
  - Define standardized error types
  - Add contextual information to errors
  - Implement graceful degradation
- **Files to Modify**:
  - `model-router/app/errors.py`
  - `model-router/app/services/router_engine.py`
  - `streamlit-chat/streamlit_chat_ui.py`

## Medium-Term Tasks

### 1. Content-Aware Routing

- **Description**: Enhance routing with content analysis
- **Key Components**:
  - Content type detection
  - Complexity estimation
  - Provider and model capability matching

### 2. API Key Management

- **Description**: Improve API key handling for cloud providers
- **Key Components**:
  - Secure key storage
  - Key validation and rotation
  - Per-request authentication

### 3. Multi-Provider Testing

- **Description**: Develop comprehensive testing for all providers
- **Key Components**:
  - Automated tests for each provider
  - Fallback chain testing
  - Performance benchmarking

## How to Contribute

1. **Understand the System**: Review the documentation in `docs/llm/`
2. **Select a Task**: Choose one of the next steps to work on
3. **Implement Changes**: Make the necessary code changes
4. **Test Thoroughly**: Verify the system works with your changes
5. **Submit a PR**: Create a pull request with your changes

## Resources

- **Documentation**: See the full documentation in `docs/llm/`
- **Architecture**: Review the system architecture in `docs/llm/ARCHITECTURE.md`
- **Roadmap**: Check the complete roadmap in `docs/LLM-ROADMAP.md`
- **Current Issues**: Understand current limitations in `docs/llm/MODEL-ROUTER-ISSUES.md`