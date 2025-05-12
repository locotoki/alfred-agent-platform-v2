#!/bin/bash

# Start script for LLM integration services
echo "Starting Alfred LLM Integration Services..."

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running or not installed"
    exit 1
fi

# Check if nvidia-smi is available (for GPU support)
if command -v nvidia-smi &> /dev/null; then
    echo "NVIDIA GPU detected"
    GPU_AVAILABLE=true
else
    echo "NVIDIA GPU not detected, will run without GPU acceleration"
    GPU_AVAILABLE=false
fi

# Start the services
echo "Starting containers with docker-compose..."
docker-compose -f llm-integration-docker-compose.yml up -d

# Wait for services to be ready
echo "Waiting for services to be ready..."
sleep 5

# Check Model Registry health
echo "Checking Model Registry health..."
MAX_ATTEMPTS=6
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s "http://localhost:8079/health" | grep -q "healthy"; then
        echo "Model Registry is healthy!"
        MODEL_REGISTRY_READY=true
        break
    else
        echo "Waiting for Model Registry to be ready... (Attempt $((ATTEMPT+1))/$MAX_ATTEMPTS)"
        ATTEMPT=$((ATTEMPT+1))
        sleep 5
    fi
done

if [ "$MODEL_REGISTRY_READY" != "true" ]; then
    echo "Warning: Model Registry might not be ready. Check with 'docker logs alfred-model-registry'"
fi

# Check Model Router health
echo "Checking Model Router health..."
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s "http://localhost:8080/health" | grep -q "healthy"; then
        echo "Model Router is healthy!"
        MODEL_ROUTER_READY=true
        break
    else
        echo "Waiting for Model Router to be ready... (Attempt $((ATTEMPT+1))/$MAX_ATTEMPTS)"
        ATTEMPT=$((ATTEMPT+1))
        sleep 5
    fi
done

if [ "$MODEL_ROUTER_READY" != "true" ]; then
    echo "Warning: Model Router might not be ready. Check with 'docker logs alfred-model-router'"
fi

# Check Ollama service
echo "Checking Ollama service..."
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -s "http://localhost:11434/api/tags" > /dev/null 2>&1; then
        echo "Ollama service is ready!"
        OLLAMA_READY=true
        break
    else
        echo "Waiting for Ollama service to be ready... (Attempt $((ATTEMPT+1))/$MAX_ATTEMPTS)"
        ATTEMPT=$((ATTEMPT+1))
        sleep 5
    fi
done

if [ "$OLLAMA_READY" != "true" ]; then
    echo "Warning: Ollama service might not be ready. Check with 'docker logs alfred-ollama'"
fi

# Start Streamlit UI
echo "Starting Streamlit UI..."
cd services/streamlit-chat
streamlit run streamlit_chat_ui.py &
STREAMLIT_PID=$!

echo ""
echo "Alfred LLM Integration Services are running!"
echo ""
echo "Access the services at:"
echo "- Streamlit UI: http://localhost:8501"
echo "- Model Registry: http://localhost:8079"
echo "- Model Router: http://localhost:8080"
echo "- Ollama: http://localhost:11434"
echo ""
echo "Press Ctrl+C to stop the services"

# Wait for user to press Ctrl+C
trap "kill $STREAMLIT_PID; docker-compose -f llm-integration-docker-compose.yml down; echo 'Services stopped.'" INT
wait $STREAMLIT_PID