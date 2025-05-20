#!/usr/bin/env python3
"""Direct chat interface with Ollama LLM models.

This script provides a simple command-line chat interface to Ollama models,
completely bypassing the model router and the Streamlit UI.

Usage:
  python3 direct-chat.py [model_name]

If model_name is not provided, defaults to "tinyllama".
"""

import json
import sys

import requests


class OllamaChat:.
    """Simple command-line chat interface for Ollama."""

    def __init__(self, model="tinyllama"):
        """Initialize the chat interface.

        Args:
            model: The Ollama model to use (default: tinyllama).

        """
        self.model = model
        self.history = []
        self.ollama_url = "http://localhost:11434"

    def send_message(self, message):
        """Send a message to the model and get the response.

        Args:
            message: The message to send

        Returns:
            The model's response.

        """
        # Add user message to history
        self.history.append({"role": "user", "content": message})

        # Create request payload
        payload = {"model": self.model, "messages": self.history, "stream": False}

        try:
            # Send request
            response = requests.post(
                f"{self.ollama_url}/api/chat",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=60,
            )

            if response.status_code == 200:
                result = response.json()

                # Extract message content
                if "message" in result and "content" in result["message"]:
                    assistant_message = result["message"]["content"]

                    # Add assistant response to history
                    self.history.append(
                        {"role": "assistant", "content": assistant_message}
                    )

                    return assistant_message
                else:
                    return f"Error: Could not extract content from response: {json.dumps(result)}"
            else:
                return f"Error: {response.status_code} - {response.text}"
        except Exception as e:
            return f"Exception: {str(e)}"

    def start_chat(self):
        """Start an interactive chat session."""
        print(f"Starting chat with {self.model}. Type 'exit' to quit.")
        print("Loading model... (first response may take a moment)")

        # Send initial message to load the model
        initial_response = self.send_message(
            "Hello! Please introduce yourself briefly."
        )
        print(f"\nModel: {initial_response}\n")

        while True:
            user_input = input("> ")
            if user_input.lower() in ["exit", "quit", "bye"]:
                print("\nGoodbye!")
                break

            print("\nThinking...\n")
            response = self.send_message(user_input)
            print(f"Model: {response}\n")


def main():
    """Main function."""
    # Get model from command line args or use default
    model = sys.argv[1] if len(sys.argv) > 1 else "tinyllama"

    # Start chat
    chat = OllamaChat(model)
    chat.start_chat()


if __name__ == "__main__":
    main()
