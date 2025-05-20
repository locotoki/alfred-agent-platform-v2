#!/usr/bin/env python3
"""Test script for directly calling the Model Router with a specific numeric
model ID.
"""

import json
import sys

import requests


def get_models():
    """Get models from the registry."""
    try:
        response = requests.get("http://localhost:8079/api/v1/models", timeout=5)
        if response.status_code == 200:
            return response.json()
        else:
            print(f"Error getting models: {response.status_code} - {response.text}")
            return []
    except Exception as e:
        print(f"Exception getting models: {str(e)}")
        return []


def find_model_id(models, model_name):
    """Find the numeric ID for a model by name."""
    for model in models:
        if model["name"] == model_name:
            return model["id"]
    return None


def test_model_router(model_id, message="Hello, can you tell me a joke?"):
    """Test the model router with a specific model ID."""
    print(f"Testing model router with model ID: {model_id}")

    # Create request payload for the generate endpoint instead of process
    payload = {"messages": [{"role": "user", "content": message}]}

    print(f"Sending request to http://localhost:8080/api/v1/generate/{model_id}")
    print(f"Payload: {json.dumps(payload, indent=2)}")

    try:
        # Send request to generate endpoint with model_id in the URL
        response = requests.post(
            f"http://localhost:8080/api/v1/generate/{model_id}",
            json=payload,
            headers={"Content-Type": "application/json"},
            timeout=60,
        )

        print(f"Response status code: {response.status_code}")

        if response.status_code == 200:
            result = response.json()
            print("\nResponse from model router:")
            print(json.dumps(result, indent=2))
        else:
            print(f"Error: {response.text}")
    except Exception as e:
        print(f"Exception: {str(e)}")


def main():
    """Main function."""
    models = get_models()

    if not models:
        print("No models found. Exiting.")
        return

    print("\nAvailable models:")
    for model in models:
        print(
            f"- {model['display_name']} ({model['provider']}): ID={model['id']}, name={model['name']}"
        )

    # Use command line args or default to TinyLlama
    model_name = sys.argv[1] if len(sys.argv) > 1 else "tinyllama"
    message = sys.argv[2] if len(sys.argv) > 2 else "Tell me a joke"

    model_id = find_model_id(models, model_name)

    if model_id:
        test_model_router(model_id, message)
    else:
        print(
            f"Model '{model_name}' not found. Please choose from the available models."
        )


if __name__ == "__main__":
    main()
