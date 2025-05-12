# LLM Integration Architecture

## Overview

The Alfred Agent Platform LLM integration provides access to both local and cloud-based language models through a unified interface. This document describes the architecture of the LLM integration system.

## Components

### Model Registry

**Purpose**: Maintains a catalog of available models and their capabilities.

**Responsibilities**:
- Store model metadata (provider, type, capabilities)
- Register and deregister models
- Handle model versioning
- Provide API for querying available models

**Implementation**:
- FastAPI service with PostgreSQL backend
- REST API for model management
- Cache layer for efficient model lookup

### Model Router

**Purpose**: Routes user queries to the most appropriate model based on content and requirements.

**Responsibilities**:
- Analyze query content and requirements
- Select appropriate model based on rules
- Handle fallbacks when primary model fails
- Provide uniform interface regardless of underlying model

**Implementation**:
- FastAPI service with routing rules engine
- Selection logic for matching queries to models
- Abstraction layer for different provider APIs
- Error handling and fallback chains

### Local Model Providers

**Purpose**: Provide inference with locally hosted models.

**Current Providers**:
- **Ollama**: Lightweight container for running various open-source models
  - TinyLlama
  - Llama2
  - Potential for many other models (CodeLlama, LLaVA, etc.)

**Implementation**:
- Docker container for Ollama
- Model files stored in volume
- REST API for inference requests

### Cloud Model Providers

**Purpose**: Provide inference with cloud-hosted models via APIs.

**Current Providers**:
- **OpenAI**: GPT-4, GPT-3.5-Turbo, etc.
- **Anthropic**: Claude models (Opus, Sonnet, Haiku)

**Implementation**:
- API clients for each provider
- Secure API key management
- Standardized request/response format

### User Interfaces

**Purpose**: Allow users to interact with models.

**Current Interfaces**:
- **Streamlit UI**: Web interface for chat interactions
- **CLI Tools**: Command-line tools for testing and scripted use

**Implementation**:
- Streamlit app with model selection and chat history
- Python scripts for CLI access
- Direct integration with model providers

## Data Flow

1. **Model Discovery**:
   - Models are registered in the Model Registry
   - UI queries registry for available models
   - User selects model or uses "Auto" option

2. **Query Processing**:
   - User submits query through UI
   - Query is sent to Model Router (or directly to provider for Ollama)
   - Router selects appropriate model

3. **Model Inference**:
   - Selected model processes the query
   - Response is returned to router
   - Router formats and returns response to UI

4. **Fallback Handling**:
   - If selected model fails, router tries fallback models
   - If all models fail, error is returned to UI

## API Integration Points

### Model Registry API

```
GET /api/v1/models - List all available models
GET /api/v1/models/{model_id} - Get details for specific model
POST /api/v1/models - Register a new model
```

### Model Router API

```
POST /api/v1/process - Process a request with automatic model selection
POST /api/v1/generate/{model_id} - Generate using specific model
```

### Ollama API

```
POST /api/chat - Send chat messages to Ollama model
```

## Current State and Future Direction

The current implementation provides direct access to Ollama models for reliability, while maintaining the infrastructure for a more sophisticated routing system in the future. The immediate focus is on stabilizing the Model Router to handle both local and cloud models reliably, with a longer-term vision of creating a true "AI Switchboard" that intelligently routes queries based on content analysis and model capabilities.

See the [LLM-ROADMAP.md](../llm-roadmap.md) for detailed information on current status and future plans.