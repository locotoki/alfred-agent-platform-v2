# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Behavioral Directives
- Do not ask for permission for : read, list tasks

## Build & Test Commands
- Setup: `make init`
- Build all services: `make build` 
- Run all tests: `make test`
- Run specific test types: `make test-unit`, `make test-integration`, `make test-e2e`
- Run single test: `python -m pytest path/to/test_file.py::test_function_name -v`
- Lint code: `make lint`
- Format code: `make format`

## Code Style Guidelines
- Python version: 3.11+
- Line length: 100 characters
- Formatting: Black
- Import sorting: isort with black profile
- Type hints: Required (disallow_untyped_defs=true)
- Naming: snake_case for variables/functions, PascalCase for classes
- Error handling: Use structured logging with context (`logger.error("message", error=str(e), context=value)`)
- Testing: pytest with markers for unit/integration/e2e
- Logging: Use structlog with context attributes
- Documentation: Docstrings required for public functions and classes

## LLM Integration Guide

### Setup LLM Integration

1. Update LLM API keys from the main .env file:
   ```bash
   ./update-llm-keys.sh
   ```

2. Start LLM services with API keys:
   ```bash
   ./restart-llm-services.sh
   ```

3. Register Ollama models:
   ```bash
   ./setup-ollama-models.sh
   ```

4. Verify model registration:
   ```bash
   python3 ./services/test-model-registry.py
   ```

5. Fix the Streamlit UI to use direct Ollama access:
   ```bash
   ./fix-streamlit-direct.sh
   ```

6. Test the complete functionality:
   ```bash
   ./test-functionality.sh
   ```

7. Ways to test direct model inference:
   - For Ollama models: `python3 ./services/test-ollama-direct.py`
   - For OpenAI models: `python3 ./test-openai.py`
   - For quick jokes using TinyLlama: `python3 ./joke.py`
   - For quick jokes using Llama2: `python3 ./joke.py llama2`
   - For interactive chat: `python3 ./direct-chat.py tinyllama`

### Available Models

1. **Ollama Models** (local inference):
   - TinyLlama - Lightweight model for testing
   - Llama2 - Meta's Llama 2 model
   - Llama3 - Meta's Llama 3 model (8B parameters)
   - Llama3:70b - Meta's Llama 3 model (70B parameters)
   - CodeLlama - Specialized for code generation
   - LLaVA - Multimodal model supporting images

2. **OpenAI Models** (requires API key):
   - GPT-4o - OpenAI's latest multimodal model
   - GPT-4.1-mini - More efficient GPT-4.1 variant
   - GPT-4.1 - OpenAI's latest text model
   - GPT-3.5 Turbo - Cost-effective model

3. **Anthropic Models** (requires API key):
   - Claude 3 Opus - Anthropic's most powerful model
   - Claude 3 Sonnet - Balanced performance model
   - Claude 3 Haiku - Fastest, most compact model

### Testing LLM Integration

1. Access the Streamlit UI:
   ```
   http://localhost:8502
   ```

2. In the sidebar:
   - Enable "Use direct model inference"
   - Select provider (ollama, openai, anthropic)
   - Select specific model
   - Enable Debug Mode to see detailed API communication

3. Type a test message and check the response

4. Troubleshooting:
   - Check that all services are running with `docker ps`
   - Verify Ollama models are available with `curl http://localhost:11434/api/tags`
   - Check model registry with `curl http://localhost:8079/api/v1/models`
   - Check model router health with `curl http://localhost:8080/health`

### Customizing LLM Integration

1. Add new API keys in `.env.llm`
2. Add new models in `model-registry/init-db.sql`
3. Restart services with `docker-compose -f llm-integration-docker-compose.yml down && ./start-llm-with-keys.sh`