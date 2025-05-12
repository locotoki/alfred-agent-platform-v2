#!/usr/bin/env python3
import requests
import json

# Model Router endpoint
MODEL_ROUTER_URL = "http://localhost:8080"

def test_ollama_model():
    """Test direct inference with TinyLlama model."""
    # Create request payload for model router
    payload = {
        "id": "test_request_123",
        "task_type": "chat",
        "content": [
            {
                "type": "text",
                "content": "Hello, can you introduce yourself?",
                "metadata": {}
            }
        ],
        "context": {
            "user_id": "test_user",
            "session_id": "test_session_123",
            "require_local_inference": True
        },
        "model_preference": "tinyllama"
    }

    print(f"Sending request to {MODEL_ROUTER_URL}/api/v1/process")
    
    # Send request to model router
    response = requests.post(
        f"{MODEL_ROUTER_URL}/api/v1/process",
        json=payload,
        headers={"Content-Type": "application/json"},
        timeout=60  # Longer timeout for model inference
    )

    print(f"Response status code: {response.status_code}")
    if response.status_code == 200:
        result = response.json()
        print(json.dumps(result, indent=2))
    else:
        print(f"Error: {response.text}")

if __name__ == "__main__":
    test_ollama_model()