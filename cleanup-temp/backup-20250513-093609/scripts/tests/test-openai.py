#!/usr/bin/env python3
"""
Simple script to test OpenAI API access using the key from .env.llm
"""

import os
import requests
import json
import re


def load_env():
    """Load environment variables from .env.llm file."""
    # Read from .env.llm
    try:
        with open(".env.llm", "r") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                key, value = line.split("=", 1)
                os.environ[key] = value
    except Exception as e:
        print(f"Error loading .env.llm: {e}")

    # If API key is not set, try main .env file
    if not os.getenv("ALFRED_OPENAI_API_KEY"):
        try:
            with open(".env", "r") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#"):
                        continue
                    match = re.match(r"OPENAI_API_KEY=(.+)", line)
                    if match:
                        os.environ["ALFRED_OPENAI_API_KEY"] = match.group(1)
                        break
        except Exception as e:
            print(f"Error loading .env: {e}")


def test_openai_api():
    """Test OpenAI API access using the API key."""
    # Get API key from environment
    api_key = os.getenv("ALFRED_OPENAI_API_KEY")

    if not api_key:
        print("Error: No OpenAI API key found in environment variables")
        return

    print(f"Using OpenAI API key: {api_key[:5]}...{api_key[-4:]}")

    # Create request payload
    url = "https://api.openai.com/v1/chat/completions"
    headers = {"Content-Type": "application/json", "Authorization": f"Bearer {api_key}"}

    payload = {
        "model": "gpt-3.5-turbo",
        "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": "Tell me a short joke about programming"},
        ],
        "max_tokens": 100,
    }

    # Send request
    try:
        print("Sending request to OpenAI API...")
        response = requests.post(url, headers=headers, json=payload, timeout=30)

        print(f"Response status code: {response.status_code}")

        if response.status_code == 200:
            result = response.json()
            message = result.get("choices", [{}])[0].get("message", {}).get("content", "")
            print("\nResponse from OpenAI:")
            print(message)
        else:
            print(f"Error from OpenAI API: {response.text}")
    except Exception as e:
        print(f"Exception: {str(e)}")


if __name__ == "__main__":
    load_env()
    test_openai_api()
