#!/usr/bin/env python3
import requests
import json

# Model Registry endpoint
MODEL_REGISTRY_URL = "http://localhost:8079"

def get_registry_models():
    """Get list of registered models from the Model Registry."""
    print(f"Fetching models from {MODEL_REGISTRY_URL}/api/v1/models")
    
    try:
        response = requests.get(
            f"{MODEL_REGISTRY_URL}/api/v1/models",
            timeout=5
        )
        
        print(f"Response status code: {response.status_code}")
        if response.status_code == 200:
            models = response.json()
            return models
        else:
            print(f"Error: {response.text}")
            return []
    except Exception as e:
        print(f"Exception: {str(e)}")
        return []

def main():
    """Main function for testing the Model Registry."""
    models = get_registry_models()
    
    if models:
        print(f"\nFound {len(models)} registered models:")
        
        # Group models by provider
        providers = {}
        for model in models:
            provider = model.get("provider", "unknown")
            if provider not in providers:
                providers[provider] = []
            providers[provider].append(model)
        
        # Print models grouped by provider
        for provider, provider_models in providers.items():
            print(f"\n{provider.upper()} MODELS:")
            for model in provider_models:
                name = model.get("name", "unknown")
                display_name = model.get("display_name", name)
                print(f"  - {display_name} (id: {model.get('id')}, name: {name})")

if __name__ == "__main__":
    main()