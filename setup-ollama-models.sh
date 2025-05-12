#!/bin/bash

# Script to pull and setup Ollama models for the Alfred Agent Platform
# Use this script to load models into the Ollama service

# Ensure Ollama service is running
if ! docker ps | grep -q alfred-ollama; then
  echo "Ollama service (alfred-ollama) is not running."
  echo "Please run deploy-llm-integration.sh first."
  exit 1
fi

echo "Setting up Ollama models..."
echo "--------------------------"

# Function to pull a model with progress indication
pull_model() {
  local model=$1
  echo "Pulling $model model... (this may take several minutes)"
  docker exec -i alfred-ollama ollama pull $model
  if [ $? -eq 0 ]; then
    echo "✅ Successfully pulled $model"
  else
    echo "❌ Failed to pull $model"
  fi
}

# Available models to pull
models=(
  "tinyllama"
  "llama2"
  "codellama"
  "llava"
  "llama3"
)

# Interactive mode - ask which models to pull
echo "Select models to pull (space-separated numbers, or 'all'):"
for i in "${!models[@]}"; do
  echo "[$((i+1))] ${models[$i]}"
done
echo "[all] Pull all models"
echo "[q] Quit without pulling models"
read -p "> " selection

if [[ "$selection" == "q" ]]; then
  echo "Exiting without pulling models."
  exit 0
elif [[ "$selection" == "all" ]]; then
  echo "Pulling all models..."
  for model in "${models[@]}"; do
    pull_model $model
  done
else
  # Convert selection to array of indices
  indices=($selection)
  for index in "${indices[@]}"; do
    if [[ "$index" =~ ^[0-9]+$ ]] && [ "$index" -ge 1 ] && [ "$index" -le "${#models[@]}" ]; then
      pull_model "${models[$((index-1))]}"
    else
      echo "Invalid selection: $index"
    fi
  done
fi

echo
echo "Model setup complete!"
echo
echo "To verify models in the Model Registry:"
echo "  curl http://localhost:8079/api/v1/models"
echo
echo "To manually add a model to the registry:"
echo "  curl -X POST http://localhost:8079/api/v1/models -H \"Content-Type: application/json\" -d '{\"name\":\"model_name\",\"display_name\":\"Model Display Name\",\"provider\":\"ollama\",\"model_type\":\"chat\",\"description\":\"Model description\",\"capabilities\":[{\"capability\":\"text\",\"capability_score\":0.8},{\"capability\":\"reasoning\",\"capability_score\":0.7}]}'"
echo
echo "To list available Ollama models:"
echo "  docker exec -i alfred-ollama ollama list"
echo
echo "Done!"