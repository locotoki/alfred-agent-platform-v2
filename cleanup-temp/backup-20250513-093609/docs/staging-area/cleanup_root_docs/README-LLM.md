# Alfred LLM Integration

This README provides an overview of the LLM (Large Language Model) integration in the Alfred Agent Platform.

## Quick Start

1. Update API keys:
   ```bash
   ./update-llm-keys.sh
   ```

2. Start LLM services:
   ```bash
   ./restart-llm-services.sh
   ```

3. Setup Ollama models:
   ```bash
   ./setup-ollama-models.sh
   ```

4. Fix Streamlit UI for direct Ollama access:
   ```bash
   ./fix-streamlit-direct.sh
   ```

5. Access the UI at:
   ```
   http://localhost:8502
   ```

## Overview

The Alfred Agent Platform integrates both local LLMs (via Ollama) and cloud-based LLMs (via OpenAI and Anthropic APIs) to provide intelligent responses to user queries.

### Key Components:

- **Model Registry**: Catalog of available models and their capabilities
- **Model Router**: Service for routing queries to appropriate models
- **Ollama Integration**: Local model inference with TinyLlama and Llama2
- **API Integration**: Cloud model access via OpenAI and Anthropic
- **Streamlit UI**: User interface for interacting with LLMs

## Current Status

The LLM integration is functional with the following capabilities:

- ✅ Local model inference via Ollama (TinyLlama, Llama2)
- ✅ Model listing and selection in the UI
- ✅ Direct streaming responses from models
- ❌ Model Router has some limitations (see docs for details)
- ❌ Cloud API integration needs API keys

## Available Documentation

Detailed documentation is available in the `docs/llm/` directory:

- [LLM-ROADMAP.md](./docs/LLM-ROADMAP.md): Current status and future plans
- [ARCHITECTURE.md](./docs/llm/ARCHITECTURE.md): System architecture overview
- [MODEL-ROUTER-ISSUES.md](./docs/llm/MODEL-ROUTER-ISSUES.md): Known issues and solutions
- [DIRECT-OLLAMA-ACCESS.md](./docs/llm/DIRECT-OLLAMA-ACCESS.md): Direct access implementation
- [LLM-SETUP.md](./LLM-SETUP.md): Detailed setup instructions

## Command-Line Tools

For testing and development, several command-line tools are available:

- `joke.py`: Get a quick joke from Ollama
  ```bash
  python3 joke.py [model_name]
  ```

- `direct-chat.py`: Interactive chat with Ollama
  ```bash
  python3 direct-chat.py [model_name]
  ```

- `test-openai.py`: Test OpenAI API integration
  ```bash
  python3 test-openai.py
  ```

- `test-functionality.sh`: Verify all components are working
  ```bash
  ./test-functionality.sh
  ```

## Configuration

### Environment Variables

LLM-specific environment variables are stored in `.env.llm`:

- `ALFRED_OPENAI_API_KEY`: OpenAI API key
- `ALFRED_ANTHROPIC_API_KEY`: Anthropic API key
- `MODEL_REGISTRY_URL`: URL for the Model Registry service
- `MODEL_ROUTER_URL`: URL for the Model Router service

### Model Management

To add a new Ollama model:

1. Download the model:
   ```bash
   docker exec -it alfred-ollama ollama pull <model_name>
   ```

2. Register it in the Model Registry:
   ```bash
   curl -X POST http://localhost:8079/api/v1/models \
     -H "Content-Type: application/json" \
     -d '{
       "name": "<model_name>",
       "display_name": "User-friendly Name",
       "provider": "ollama",
       "model_type": "chat",
       "description": "Description of the model"
     }'
   ```

## Development Roadmap

The LLM integration is being developed in phases:

1. **Phase 1**: Stabilization (current focus)
   - Fix Model Router issues
   - Improve API key management
   - Enhance error handling

2. **Phase 2**: Enhanced Routing
   - Implement basic model selection logic
   - Add fallback chains
   - Expand model support

3. **Phase 3**: True AI Switchboard
   - Content-aware routing
   - Multi-model orchestration
   - Resource optimization

For detailed plans, see [LLM-ROADMAP.md](./docs/LLM-ROADMAP.md).