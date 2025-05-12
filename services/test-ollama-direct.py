#!/usr/bin/env python3
import requests
import json

# Ollama endpoint
OLLAMA_URL = "http://localhost:11434"

def test_ollama_direct():
    """Test direct inference with TinyLlama model through Ollama."""
    # Create request payload for Ollama chat endpoint
    payload = {
        "model": "tinyllama",
        "messages": [
            {"role": "user", "content": "Hello, can you introduce yourself?"}
        ],
        "stream": False  # Disable streaming for simplicity
    }

    print(f"Sending request to {OLLAMA_URL}/api/chat")
    
    # Send request to Ollama
    response = requests.post(
        f"{OLLAMA_URL}/api/chat",
        json=payload,
        headers={"Content-Type": "application/json"},
        timeout=60  # Longer timeout for model inference
    )

    print(f"Response status code: {response.status_code}")
    if response.status_code == 200:
        try:
            result = response.json()
            print(json.dumps(result, indent=2))
        except json.JSONDecodeError:
            # Handle streaming response
            print("Received streaming response:")
            print(response.text)
    else:
        print(f"Error: {response.text}")

if __name__ == "__main__":
    test_ollama_direct()