#!/usr/bin/env python3
"""Create a direct replacement of the process_command function in
streamlit_chat_ui.py.
"""

import re

# The new process_command function
NEW_FUNCTION = '''
def process_command(message: str) -> str:.
    """Process commands with direct model calls."""
    # Special case for help
    if message.startswith("/help") or message == "help":
        return get_help_response()

    # Special case for models
    if message.startswith("/models") or message == "models":
        return get_models_response()

    # For all other commands, call Ollama directly
    model_name = st.session_state.selected_model

    # Normalize model name
    if ":" in model_name:
        model_name = model_name.split(":")[-1]

    # For non-Ollama models, use tinyllama
    if not any(prefix in model_name.lower() for prefix in ["llama", "tiny", "code"]):
        if st.session_state.debug_mode:
            st.sidebar.info(f"Using tinyllama instead of {model_name}")
        model_name = "tinyllama"

    # Create Ollama payload
    payload = {
        "model": model_name,
        "messages": [
            {"role": "user", "content": message}
        ],
        "stream": False
    }

    if st.session_state.debug_mode:
        st.sidebar.write(f"Sending direct to Ollama with model: {model_name}")
        st.sidebar.write("Payload:", payload)

    # List of endpoints to try
    ollama_endpoints = [
        "http://alfred-ollama:11434",
        "http://ollama:11434",
        "http://localhost:11434"
    ]

    # Try each endpoint
    for endpoint in ollama_endpoints:
        try:
            if st.session_state.debug_mode:
                st.sidebar.info(f"Trying endpoint: {endpoint}")

            # Send to Ollama
            import requests
            response = requests.post(
                f"{endpoint}/api/chat",
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=30
            )

            if response.status_code == 200:
                result = response.json()

                if st.session_state.debug_mode:
                    st.sidebar.success(f"Got response from {endpoint}")

                # Extract content
                if "message" in result and "content" in result["message"]:
                    return result["message"]["content"]
                else:
                    return f"Received response but couldn't extract content: {str(result)}"
        except Exception as e:
            if st.session_state.debug_mode:
                st.sidebar.error(f"Error with {endpoint}: {str(e)}")
            # Continue to next endpoint

    # If all endpoints failed
    return f"I tried to answer your question about '{message}' but couldn't connect to any language models. Please check that Ollama is running properly."
'''


def patch_file():
    """Patch the streamlit_chat_ui.py file."""
    filepath = "/home/locotoki/projects/alfred-agent-platform-v2/services/streamlit-chat/streamlit_chat_ui.py"

    with open(filepath, "r") as f:
        content = f.read()

    # Find the process_command function
    pattern = r"def process_command\(message: str\) -> str:.*?return send_message\(command\)"

    # Replace it with our new function
    new_content = re.sub(pattern, NEW_FUNCTION.strip(), content, flags=re.DOTALL)

    # Write the modified content back
    with open(filepath, "w") as f:
        f.write(new_content)

    print(f"Successfully patched {filepath}")


if __name__ == "__main__":
    patch_file()
