#!/usr/bin/env python3
"""Simple script to request a joke from Ollama."""

import sys

import requests


def get_joke(model="tinyllama"):
    """Get a joke from the specified Ollama model."""
    url = "http://localhost:11434/api/chat"

    payload = {
        "model": model,
        "messages": [{"role": "user", "content": "Tell me a short, funny joke"}],
        "stream": False,
    }

    print(f"Requesting joke from {model}...")

    try:
        response = requests.post(
            url, json=payload, headers={"Content-Type": "application/json"}, timeout=30
        )

        if response.status_code == 200:
            result = response.json()
            joke = result.get("message", {}).get("content", "No joke found")
            return joke
        else:
            return f"Error from Ollama: {response.status_code} - {response.text}"
    except Exception as e:
        return f"Exception: {str(e)}"


if __name__ == "__main__":
    # Get model name from command line args or use default
    model = sys.argv[1] if len(sys.argv) > 1 else "tinyllama"

    joke = get_joke(model)
    print("\nJoke:\n")
    print(joke)
