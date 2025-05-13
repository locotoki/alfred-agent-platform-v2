# LLM Integration for Alfred Agent Platform

This document explains how to set up and use the LLM integration for the Alfred Agent Platform.

## Overview

The Alfred Agent Platform supports two types of LLM integration:

1. **Local Models** via Ollama (TinyLlama, Llama2)
2. **Cloud Models** via API providers (OpenAI, Anthropic)

## Architecture

The LLM integration consists of the following components:

* **Model Registry**: Manages available models and their capabilities
* **Model Router**: Routes requests to the appropriate model based on content and requirements
* **Ollama**: Provides local model inference
* **Streamlit UI**: User interface for interacting with models

## Setup Instructions

### Prerequisites

* Docker and Docker Compose
* 8+ GB RAM for running Ollama models
* API keys for cloud providers (optional)

### Step 1: Update API Keys

Create or update the .env.llm file with your API keys:

```bash
./update-llm-keys.sh
```

This extracts the OpenAI API key from the main .env file and updates .env.llm.

### Step 2: Start LLM Services

Start the LLM services with Docker Compose:

```bash
./restart-llm-services.sh
```

This will start the following containers:
* alfred-model-registry
* alfred-model-router
* alfred-postgres
* alfred-ollama

### Step 3: Download Ollama Models

Download and register Ollama models:

```bash
./setup-ollama-models.sh
```

This will download TinyLlama and Llama2 models from Ollama and register them in the Model Registry.

### Step 4: Fix Streamlit UI

Apply the patch to enable direct Ollama access from the Streamlit UI:

```bash
./fix-streamlit-direct.sh
```

This ensures the Streamlit UI can communicate directly with Ollama for reliable model responses.

### Step 5: Test the Integration

Test the full functionality of the LLM integration:

```bash
./test-functionality.sh
```

## Using the LLM Integration

### Streamlit UI

Access the Streamlit UI at http://localhost:8502 

1. Select "ollama" as the provider
2. Choose "TinyLlama" or "Llama2" as the model
3. Enable "Debug Mode" to see the API communication details
4. Send a message to interact with the model

### Command Line Tools

Several command-line tools are available for interacting with models:

* `python3 ./joke.py` - Get a joke from TinyLlama
* `python3 ./joke.py llama2` - Get a joke from Llama2
* `python3 ./direct-chat.py tinyllama` - Interactive chat with TinyLlama
* `python3 ./test-openai.py` - Test OpenAI API connection

## Troubleshooting

### Model Registry Issues

If the Model Registry can't connect to the database:
1. Check if the postgres container is running
2. Verify the database connection details in the environment variables

### Ollama Issues

If Ollama isn't responding:
1. Check if the ollama container is running
2. Verify the models are downloaded with `curl http://localhost:11434/api/tags`
3. Try restarting the ollama container

### UI Issues

If the Streamlit UI isn't showing real model responses:
1. Make sure "Use direct model inference" is enabled
2. Select an "ollama" provider model
3. Enable Debug Mode to see what's happening
4. Try running the fix script again: `./fix-streamlit-direct.sh`

## Adding New Models

### Adding Local Ollama Models

1. Download the model from Ollama:
   ```bash
   docker exec -it alfred-ollama ollama pull <model_name>
   ```

2. Register the model in the Model Registry:
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

### Adding Cloud Provider Models

1. Add your API key to .env.llm
2. Register the model in the Model Registry with the appropriate endpoints
3. Restart the services with `./restart-llm-services.sh`

## Development

To modify the LLM integration:

1. Streamlit UI code is in `services/streamlit-chat/streamlit_chat_ui.py`
2. Model Registry API is in the `alfred-model-registry` container
3. Model Router API is in the `alfred-model-router` container

For any changes to the Streamlit UI, apply them and then update the container:
```bash
docker cp services/streamlit-chat/streamlit_chat_ui.py ui-chat:/app/
docker restart ui-chat
```