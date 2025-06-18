#!/usr/bin/env python3
"""Simple Hello World endpoint."""

def hello_world():
    """Return a friendly greeting."""
    return {"message": "Hello, World!", "status": "success"}

if __name__ == "__main__":
    result = hello_world()
    print(f"Hello World endpoint: {result}")
