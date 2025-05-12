#!/usr/bin/env python3
"""
Test script to directly access Ollama, Model Registry, and Model Router using their container IPs.
"""

import requests
import json
import time

# Use localhost with exposed ports
OLLAMA_URL = "http://localhost:11434"
MODEL_REGISTRY_URL = "http://localhost:8079"
MODEL_ROUTER_URL = "http://localhost:8080"

def test_ollama():
    """Test direct access to Ollama."""
    print("\n--- Testing Ollama API ---")
    try:
        # First check available models
        print(f"Getting available models from {OLLAMA_URL}/api/tags")
        response = requests.get(f"{OLLAMA_URL}/api/tags", timeout=5)
        
        if response.status_code == 200:
            models = response.json().get("models", [])
            print(f"Available models: {json.dumps(models, indent=2)}")
            
            # Send a test request to the first model
            if models:
                model = models[0]["name"]
                
                print(f"\nSending test chat request to {model}")
                chat_response = requests.post(
                    f"{OLLAMA_URL}/api/chat",
                    json={
                        "model": model,
                        "messages": [
                            {"role": "user", "content": "Hello! Can you tell me a joke?"}
                        ],
                        "stream": False
                    },
                    timeout=30
                )
                
                if chat_response.status_code == 200:
                    result = chat_response.json()
                    print(f"Response: {json.dumps(result.get('message', {}).get('content', 'No content'), indent=2)}")
                else:
                    print(f"Error from Ollama chat: {chat_response.status_code} - {chat_response.text}")
        else:
            print(f"Error getting models: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Exception testing Ollama: {str(e)}")

def test_model_registry():
    """Test direct access to Model Registry."""
    print("\n--- Testing Model Registry API ---")
    try:
        print(f"Getting models from {MODEL_REGISTRY_URL}/api/v1/models")
        response = requests.get(f"{MODEL_REGISTRY_URL}/api/v1/models", timeout=5)
        
        if response.status_code == 200:
            models = response.json()
            print(f"Found {len(models)} models in registry")
            
            # Print model names and providers
            for model in models:
                print(f"- {model.get('display_name')} ({model.get('provider')}): {model.get('name')}")
        else:
            print(f"Error getting models: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Exception testing Model Registry: {str(e)}")

def test_model_router():
    """Test direct access to Model Router."""
    print("\n--- Testing Model Router API ---")
    try:
        # First check health
        print(f"Checking health at {MODEL_ROUTER_URL}/health")
        response = requests.get(f"{MODEL_ROUTER_URL}/health", timeout=5)
        
        if response.status_code == 200:
            print(f"Health check response: {response.json()}")
            
            # Try to process a message using TinyLlama
            request_id = f"test_{int(time.time())}"
            
            print(f"\nSending process request using TinyLlama")
            process_response = requests.post(
                f"{MODEL_ROUTER_URL}/api/v1/process",
                json={
                    "id": request_id,
                    "task_type": "chat",
                    "content": [
                        {
                            "type": "text",
                            "content": "Hello! Can you tell me a joke?",
                            "metadata": {}
                        }
                    ],
                    "context": {
                        "user_id": "test_user",
                        "session_id": f"test_session_{int(time.time())}",
                        "require_local_inference": True
                    },
                    "model_preference": "tinyllama"
                },
                timeout=30
            )
            
            print(f"Response status: {process_response.status_code}")
            if process_response.status_code == 200:
                result = process_response.json()
                print(f"Response: {json.dumps(result, indent=2)}")
            else:
                print(f"Error from Model Router: {process_response.text}")
        else:
            print(f"Health check failed: {response.status_code} - {response.text}")
    except Exception as e:
        print(f"Exception testing Model Router: {str(e)}")

def main():
    """Run all tests."""
    test_ollama()
    test_model_registry()
    test_model_router()

if __name__ == "__main__":
    main()