#!/usr/bin/env python3
"""
Simple CLI for chatting with Ollama models.

Usage:
  python3 ollama-chat.py [model_name]

If model_name is not provided, defaults to "tinyllama".
"""

import sys
import json
import requests
from typing import List, Dict, Any, Optional

class OllamaClient:
    """Client for interacting with Ollama API."""
    
    def __init__(self, base_url: str = "http://localhost:11434"):
        """Initialize the Ollama client.
        
        Args:
            base_url: Base URL for Ollama API
        """
        self.base_url = base_url
        self.history: List[Dict[str, str]] = []
        
    def chat(self, message: str, model: str = "tinyllama") -> str:
        """Send a chat message to Ollama and return the response.
        
        Args:
            message: User message to send
            model: Name of the Ollama model to use
            
        Returns:
            Response text from the model
        """
        # Add user message to history
        self.history.append({"role": "user", "content": message})
        
        # Create request payload
        payload = {
            "model": model,
            "messages": self.history,
            "stream": False
        }
        
        try:
            # Send request to Ollama
            response = requests.post(
                f"{self.base_url}/api/chat",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=60
            )
            
            if response.status_code == 200:
                result = response.json()
                
                # Extract assistant message
                if "message" in result and "content" in result["message"]:
                    assistant_message = result["message"]["content"]
                    
                    # Add assistant response to history
                    self.history.append({"role": "assistant", "content": assistant_message})
                    
                    return assistant_message
                    
                return f"Error: Unexpected response format: {json.dumps(result)}"
            else:
                return f"Error: {response.status_code} - {response.text}"
                
        except Exception as e:
            return f"Error: {str(e)}"
    
    def list_models(self) -> List[str]:
        """List available Ollama models.
        
        Returns:
            List of model names
        """
        try:
            response = requests.get(f"{self.base_url}/api/tags")
            if response.status_code == 200:
                models_data = response.json().get("models", [])
                return [model.get("name") for model in models_data]
            else:
                print(f"Error listing models: {response.status_code} - {response.text}")
                return []
        except Exception as e:
            print(f"Exception listing models: {str(e)}")
            return []

def main():
    """Main function for Ollama chat CLI."""
    # Create Ollama client
    client = OllamaClient()
    
    # Get model from command line args or use default
    model = sys.argv[1] if len(sys.argv) > 1 else "tinyllama"
    
    # List available models
    available_models = client.list_models()
    if available_models:
        print(f"Available models: {', '.join(available_models)}")
    
    if model not in available_models:
        print(f"Warning: Model '{model}' not found in available models. Using anyway.")
    
    print(f"\nChat with {model} (type 'exit' to quit)\n")
    
    # Start chat loop
    while True:
        user_input = input("> ")
        if user_input.lower() in ["exit", "quit", "bye"]:
            break
            
        print("\nThinking...\n")
        response = client.chat(user_input, model)
        print(f"{response}\n")

if __name__ == "__main__":
    main()