# LLM Services Health Monitoring

This document describes the health monitoring for the LLM services in the Alfred Agent Platform.

## LLM Service Stack

The LLM service stack consists of:

1. **llm-service**: Local model inference using Ollama (port 11434)
2. **model-registry**: Model catalog and discovery service (port 8079)
3. **model-router**: Request routing and model selection service (port 8080)
4. **ui-chat**: Streamlit UI for interacting with LLM services (port 8502)

## Health Check Endpoints

Each service provides a health check endpoint that can be used to verify its status:

- **llm-service**: `http://localhost:11434/api/tags`
- **model-registry**: `http://localhost:8079/health`
- **model-router**: `http://localhost:8080/health`
- **ui-chat**: `http://localhost:8502/healthz`

## Checking Service Health

You can check the health of these services using curl:

```bash
# Check llm-service
curl -s http://localhost:11434/api/tags | jq .

# Check model-registry
curl -s http://localhost:8079/health

# Check model-router
curl -s http://localhost:8080/health

# Check available models
curl -s http://localhost:8079/api/v1/models | jq .
```

## Common Issues and Resolutions

### Model Registry Database Tables Missing

If the model-registry service fails to start due to missing database tables, you can manually create them:

```bash
# Execute the model registry initialization script
docker exec db-postgres psql -U postgres -f /docker-entrypoint-initdb.d/900_model_registry_init.sql

# Restart the model-registry service
docker-compose -f docker-compose-clean.yml restart model-registry

# Restart the model-router service
docker-compose -f docker-compose-clean.yml restart model-router
```

### Streamlit Configuration Issues

If the UI Chat service has configuration issues, you may need to fix the Streamlit configuration:

```bash
# Create or fix the Streamlit configuration
docker exec -i ui-chat bash -c "cat > /app/.streamlit/config.toml" << 'EOF'
[server]
enableCORS = false
enableXsrfProtection = false
headless = true
runOnSave = true

[theme]
base = "light"
primaryColor = "#0066b2"
backgroundColor = "#f0f2f6"
secondaryBackgroundColor = "#e0e4e9"
textColor = "#262730"
font = "sans serif"
EOF

# Restart the UI Chat service
docker-compose -f docker-compose-clean.yml restart ui-chat
```

### Models Not Appearing

If models are not appearing in the model registry:

1. Check if the ollama service is running and healthy: `curl http://localhost:11434/api/tags`
2. Verify the model registry database is properly initialized: `docker exec db-postgres psql -U postgres -c "SELECT COUNT(*) FROM model_registry.models;"`
3. Restart the model discovery service: `docker-compose -f docker-compose-clean.yml restart model-registry`
4. Check the logs: `docker logs model-registry`

## Starting LLM Services with API Keys

To enable real LLM inference with both local and public models:

1. Run the setup script:
   ```
   ./start-llm-with-keys.sh
   ```

2. Enter your API keys when prompted:
   - OpenAI API key for GPT models
   - Anthropic API key for Claude models
   - Or press Enter to skip certain providers

3. Choose whether to set up Ollama models when prompted:
   - This will download local LLM models that can run without API keys
   - Available models include: TinyLlama, Llama2, CodeLlama, LLaVA, and Llama3

4. Access the Streamlit UI at http://localhost:8502
   - Enable "Use direct model inference" in the sidebar
   - Choose models from different providers
   - Use Debug Mode to see API details
