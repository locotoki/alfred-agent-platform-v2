# LLM Integration Guide

**Last Updated:** 2025-05-14

## Overview

This guide provides comprehensive instructions for setting up and using the Language Model (LLM) integration within the Alfred Agent Platform v2. The platform supports both local models through Ollama and cloud-based models through OpenAI and Anthropic APIs.

## Architecture

The LLM integration consists of the following components:

1. **Model Registry**: Manages available models and their capabilities
2. **Model Router**: Routes requests to appropriate models
3. **Local Models (Ollama)**: Provides local inference without API keys
4. **Cloud Providers**: Enables access to powerful cloud models (OpenAI, Anthropic)
5. **Streamlit UI**: User interface for direct model interaction

![LLM Integration Architecture](./docs/images/llm-architecture.png)

## Setup Instructions

### 1. Environment Setup

First, ensure your environment is properly configured:

```bash
# Copy example environment file if you haven't already
cp .env.example .env

# Open the file for editing
nano .env
```

Add your API keys to the `.env` file:

```
ALFRED_OPENAI_API_KEY=your_openai_key_here
ALFRED_ANTHROPIC_API_KEY=your_anthropic_key_here
```

### 2. Start LLM Services

Use the platform management script to start the LLM-related services:

```bash
# Start core infrastructure, database, and LLM services
./start-platform.sh redis db-postgres model-registry model-router llm-service ui-chat
```

### 3. Setup Local Models (Ollama)

To download and set up local LLM models:

```bash
# Make the script executable
chmod +x ./scripts/setup/setup-ollama-models.sh

# Run the setup script
./scripts/setup/setup-ollama-models.sh
```

This will download and set up the following models:
- TinyLlama (Fast, lightweight model)
- Llama2 (General purpose model)
- CodeLlama (Code-specific model)
- LLaVA (Vision-capable model)
- Llama3 (Latest Llama model)

### 4. Verify Setup

Verify that your LLM integration is working correctly:

```bash
# Check Model Registry status
curl http://localhost:8079/health

# Check Model Router status
curl http://localhost:8080/health

# Check Ollama status
curl http://localhost:11434/api/tags
```

## Available Models

### Local Models (Ollama)

| Model | Description | Size | Use Case |
|-------|-------------|------|----------|
| TinyLlama | Lightweight model | 1.1B | Quick responses, testing |
| Llama2 | Meta's Llama 2 | 7B | General purpose |
| Llama3 | Meta's Llama 3 | 8B | Improved general purpose |
| Llama3:70b | Meta's Large Llama 3 | 70B | Advanced reasoning |
| CodeLlama | Code-specialized model | 7B | Programming assistance |
| LLaVA | Vision-language model | 7B | Image understanding |

### Cloud Models (API Key Required)

#### OpenAI Models

| Model | Description | Strengths |
|-------|-------------|-----------|
| GPT-4o | Latest multimodal model | Vision, reasoning, instruction following |
| GPT-4.1-mini | Efficient GPT-4.1 | Good balance of speed and quality |
| GPT-4.1 | Latest text model | Complex reasoning, long-context tasks |
| GPT-3.5 Turbo | Cost-effective model | Fast responses, straightforward tasks |

#### Anthropic Models

| Model | Description | Strengths |
|-------|-------------|-----------|
| Claude 3 Opus | Most powerful Claude | Complex tasks, research, detailed analysis |
| Claude 3 Sonnet | Balanced model | General purpose, good reasoning |
| Claude 3 Haiku | Fast, efficient | Quick responses, straightforward tasks |

## Using the Streamlit UI with Models

The Streamlit UI provides a user-friendly interface for interacting with different models:

1. Access the UI at: http://localhost:8502
2. In the sidebar, enable "Use direct model inference"
3. Select a provider (Ollama, OpenAI, or Anthropic)
4. Choose a specific model from the dropdown
5. Enable Debug Mode to see detailed API communication
6. Start chatting in the main interface

## Troubleshooting

### Common Issues and Solutions

#### Ollama Models Not Appearing

If Ollama models don't appear in the Streamlit UI:

```bash
# Check if Ollama container is running
docker ps | grep ollama

# Check available models
curl http://localhost:11434/api/tags

# Restart Ollama service if needed
docker restart llm-service
```

#### API Key Issues

If you encounter "API key not configured" errors:

1. Check your `.env` file to ensure keys are properly set
2. Restart the services to load new environment variables:
   ```bash
   ./start-platform.sh -a down
   ./start-platform.sh model-registry model-router llm-service ui-chat
   ```

#### Model Router Connection Issues

If the Streamlit UI can't connect to the Model Router:

1. Verify the Model Router is running:
   ```bash
   docker ps | grep model-router
   ```
2. Check the health endpoint:
   ```bash
   curl http://localhost:8080/health
   ```
3. Look at the logs:
   ```bash
   ./start-platform.sh -a logs model-router
   ```

### Health Checks

Monitor the health of your LLM services:

```bash
# Check Model Registry health
curl http://localhost:8079/health

# Check Model Router health
curl http://localhost:8080/health

# Check Ollama status
curl http://localhost:11434/api/tags
```

## Advanced Configuration

### Adding Custom Ollama Models

To add additional models to Ollama:

```bash
# Pull a new model
docker exec -i llm-service ollama pull mistral

# Register the model with the Model Registry
curl -X POST http://localhost:8079/api/v1/models \
  -H "Content-Type: application/json" \
  -d '{
    "name": "mistral",
    "display_name": "Mistral 7B",
    "provider": "ollama",
    "description": "Mistral AI 7B instruction model",
    "active": true
  }'
```

### Configuring Model Router Rules

The Model Router can be configured with rules for intelligent routing:

1. Edit the configuration file:
   ```bash
   nano ./services/model-router/config/rules.json
   ```

2. Add rules for routing based on content or task type:
   ```json
   {
     "rules": [
       {
         "pattern": ".*code.*",
         "model": "codellama"
       },
       {
         "pattern": ".*image.*",
         "model": "llava"
       }
     ],
     "default": "llama3"
   }
   ```

3. Restart the Model Router:
   ```bash
   docker restart model-router
   ```

## Direct API Integration

For developers who want to integrate with the Model Router directly:

### Process Endpoint

```bash
curl -X POST http://localhost:8080/api/v1/process \
  -H "Content-Type: application/json" \
  -d '{
    "id": "request_123",
    "task_type": "chat",
    "content": "Tell me about the solar system",
    "context": {
      "user_id": "user_123",
      "session_id": "session_456"
    },
    "model_preference": "llama3"
  }'
```

### Model-Specific Endpoint

```bash
curl -X POST http://localhost:8080/api/v1/generate/llama3 \
  -H "Content-Type: application/json" \
  -d '{
    "id": "request_123",
    "task_type": "chat",
    "content": "Tell me about the solar system",
    "context": {
      "user_id": "user_123",
      "session_id": "session_456"
    }
  }'
```

## Performance Considerations

- Local Ollama models run on your hardware and performance depends on your system's capabilities
- TinyLlama is the fastest but least capable model
- Llama3:70b provides the best quality for local models but requires significant hardware resources
- Cloud models (OpenAI, Anthropic) provide consistent performance but depend on internet connectivity
- For production use with many concurrent users, consider using cloud models or scaling hardware for local models

## Next Steps

1. Try different models to understand their capabilities
2. Set up model routing rules for your specific use cases
3. Integrate model calls into your applications using the Model Router API
4. Consider fine-tuning models for specific domains (requires additional setup)

For more detailed information, see the [LLM Architecture Document](./docs/llm/ARCHITECTURE.md) and [Model Router Documentation](./docs/llm/MODEL-ROUTER.md).