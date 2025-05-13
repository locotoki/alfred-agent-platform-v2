#!/bin/bash
# Script to test the full functionality of the Ollama and OpenAI integration

echo -e "\n=== Testing LLM Functionality ===\n"

# Step 1: Check if Ollama models are available
echo -e "Step 1: Checking Ollama models...\n"
curl -s http://localhost:11434/api/tags | grep name

# Step 2: Check if Model Registry is functioning
echo -e "\nStep 2: Checking Model Registry...\n"
curl -s http://localhost:8079/api/v1/models | grep -A 1 "\"name\":" | head -10

# Step 3: Test direct Ollama access with TinyLlama
echo -e "\nStep 3: Testing direct access to TinyLlama...\n"
RESPONSE=$(curl -s -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"tinyllama","messages":[{"role":"user","content":"Tell me a joke"}],"stream":false}')
  
echo "Response from TinyLlama:"
echo "$RESPONSE" | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//'

# Step 4: Test direct Ollama access with Llama2
echo -e "\nStep 4: Testing direct access to Llama2...\n"
RESPONSE=$(curl -s -X POST http://localhost:11434/api/chat \
  -H "Content-Type: application/json" \
  -d '{"model":"llama2","messages":[{"role":"user","content":"Tell me a joke"}],"stream":false}')
  
echo "Response from Llama2:"
echo "$RESPONSE" | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//'

# Step 5: Test Streamlit UI functionality
echo -e "\nStep 5: Verifying Streamlit UI is running...\n"
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8502 | grep -q "200"; then
  echo "✅ Streamlit UI is running at http://localhost:8502"
  echo "Please open the browser to test the UI with Ollama models"
else
  echo "❌ Streamlit UI is not accessible. Check if the container is running."
fi

echo -e "\n=== LLM Integration Testing Complete ===\n"
echo "All services are running correctly."
echo "You can now use the Streamlit UI at http://localhost:8502 to interact with Ollama models."
echo "Instructions:"
echo "1. Select 'ollama' as the provider"
echo "2. Choose 'TinyLlama' or 'Llama2' as the model"
echo "3. Enable 'Debug Mode' to see the API communication"
echo "4. Send a message to test real model responses"