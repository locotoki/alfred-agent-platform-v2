#!/usr/bin/env python3
"""
Patch the streamlit_chat_ui.py file to use direct Ollama access.
"""

import os
import re

def patch_streamlit_chat_ui():
    """Patch the streamlit_chat_ui.py file."""
    # Path to the file
    file_path = "/app/streamlit_chat_ui.py"
    
    # Read the file
    with open(file_path, "r") as f:
        content = f.read()
    
    # Replace the process_command function
    pattern = r"def process_command\(message: str\) -> str:.*?return send_message\(command\)"
    replacement = """def process_command(message: str) -> str:
    """Bypass simulation and get real responses from Ollama."""
    from direct_wrapper import process_command as direct_process
    
    # Get selected model from session state
    model = st.session_state.selected_model
    debug = st.session_state.debug_mode
    
    # Process using direct Ollama access
    return direct_process(message, model, debug)"""
    
    # Use regex with DOTALL to match across multiple lines
    new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    
    # Write the modified content back
    with open(file_path, "w") as f:
        f.write(new_content)
    
    print("Successfully patched streamlit_chat_ui.py")

if __name__ == "__main__":
    patch_streamlit_chat_ui()
