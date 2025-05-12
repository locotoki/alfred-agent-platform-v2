#!/bin/bash
set -e

echo "┌────────────────────────────────────────────┐"
echo "│ Updating Streamlit UI Service Configuration │"
echo "└────────────────────────────────────────────┘"
echo ""

# Create a docker-compose file just for the Streamlit UI
cat > streamlit-ui-docker-compose.yml << EOF
version: '3.8'

services:
  streamlit-ui:
    build:
      context: ./services/streamlit-chat
      dockerfile: Dockerfile
    image: alfred/streamlit-ui:latest
    container_name: alfred-streamlit
    restart: unless-stopped
    environment:
      - DEBUG=true
      - ALFRED_API_URL=http://agent-core:8011
      - MODEL_REGISTRY_URL=http://model-registry:8079
      - MODEL_ROUTER_URL=http://model-router:8080
    ports:
      - "8502:8501"
    networks:
      - alfred-network
    healthcheck:
      test: ["CMD", "wget", "--spider", "http://localhost:8501"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    depends_on:
      - model-registry
      - model-router

  model-registry:
    image: alfred/model-registry:latest
    container_name: alfred-model-registry
    restart: unless-stopped
    environment:
      - DEBUG=true
      - DATABASE_URL=postgresql+asyncpg://postgres:postgres@db-postgres:5432/postgres
      - OLLAMA_URL=http://llm-service:11434
      - OPENAI_API_KEY=\${OPENAI_API_KEY:-}
      - ANTHROPIC_API_KEY=\${ANTHROPIC_API_KEY:-}
      - PORT=8079
    ports:
      - "8079:8079"
    networks:
      - alfred-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8079/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    depends_on:
      - db-postgres

  model-router:
    image: alfred/model-router:latest
    container_name: alfred-model-router
    restart: unless-stopped
    environment:
      - DEBUG=true
      - MODEL_REGISTRY_URL=http://model-registry:8079
      - PORT=8080
    ports:
      - "8080:8080"
    networks:
      - alfred-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    depends_on:
      - model-registry

  # Postgres database
  db-postgres:
    image: postgres:14-alpine
    container_name: alfred-postgres
    restart: unless-stopped
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=postgres
    volumes:
      - postgres-data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - alfred-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5

  # Ollama for local LLM hosting
  llm-service:
    image: ollama/ollama:latest
    container_name: alfred-ollama
    restart: unless-stopped
    volumes:
      - ollama-data:/root/.ollama
    ports:
      - "11434:11434"
    networks:
      - alfred-network

networks:
  alfred-network:
    external: true
    name: alfred-network

volumes:
  postgres-data:
  ollama-data:
EOF

echo "✅ Created streamlit-ui-docker-compose.yml"

# Check if we need to create a Dockerfile for the Streamlit service
if [ ! -f "./services/streamlit-chat/Dockerfile" ]; then
  echo "Creating Dockerfile for Streamlit service..."
  
  mkdir -p ./services/streamlit-chat
  
  cat > ./services/streamlit-chat/Dockerfile << EOF
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8501

HEALTHCHECK CMD wget --spider http://localhost:8501 || exit 1

CMD ["streamlit", "run", "streamlit_chat_ui.py", "--server.port=8501", "--server.address=0.0.0.0"]
EOF

  # Create requirements file if it doesn't exist
  if [ ! -f "./services/streamlit-chat/requirements.txt" ]; then
    cat > ./services/streamlit-chat/requirements.txt << EOF
streamlit==1.29.0
requests==2.31.0
structlog==23.2.0
EOF
  fi
  
  echo "✅ Created Dockerfile and requirements.txt"
fi

echo "To start the updated Streamlit UI service:"
echo "  docker-compose -f streamlit-ui-docker-compose.yml up -d"
echo ""
echo "Streamlit UI will be available at: http://localhost:8502"
echo "It will connect to the Model Registry, Model Router, and Alfred API using proper container names."
echo ""
echo "✨ Configuration update completed!"

# Make the script executable
chmod +x "$0"