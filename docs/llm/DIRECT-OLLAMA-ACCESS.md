# Direct Ollama Access Implementation

This document details the current implementation of direct Ollama access in the Alfred Agent Platform.

## Overview

Due to issues with the Model Router, we implemented a direct access approach for Ollama models that bypasses the router entirely. This approach provides reliable responses from local Ollama models while the Model Router issues are being addressed.

## Implementation Details

### Core Components

1. **Process Command Function**
   
   The `process_command` function in the Streamlit UI was modified to directly call Ollama for all requests:

   ```python
   def process_command(message: str) -> str:
       """Process commands with direct model calls."""
       # Special case for help and models commands
       if message.startswith("/help") or message == "help":
           return get_help_response()
           
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
           
       # Create Ollama payload and send request
       # [implementation details]
   ```

2. **Endpoint Fallbacks**

   Multiple Ollama endpoints are tried in order to ensure reliability:

   ```python
   # List of endpoints to try
   ollama_endpoints = [
       "http://alfred-ollama:11434",  # Container name in Docker network
       "http://ollama:11434",         # Alternative container name
       "http://localhost:11434"       # Local development
   ]
   
   # Try each endpoint
   for endpoint in ollama_endpoints:
       try:
           # Send to Ollama
           # [implementation details]
       except Exception as e:
           # Continue to next endpoint
   ```

3. **Fallback for Non-Ollama Models**

   When a non-Ollama model is selected, the system falls back to TinyLlama:

   ```python
   # For non-Ollama models, use tinyllama
   if not any(prefix in model_name.lower() for prefix in ["llama", "tiny", "code"]):
       model_name = "tinyllama"
   ```

## Utility Scripts

Several utility scripts were created to support the direct Ollama access:

1. **test-ollama-direct.py**
   - Direct testing of Ollama API
   - Bypasses all Alfred infrastructure

2. **joke.py**
   - Simple utility for getting jokes from Ollama models
   - Supports different models via command-line argument

3. **direct-chat.py**
   - Interactive chat interface for Ollama models
   - Maintains conversation history

4. **fix-streamlit-direct.sh**
   - Applies the direct Ollama access patch to the Streamlit UI
   - Restarts the container to apply changes

## Benefits and Limitations

### Benefits
- **Reliability**: Works consistently regardless of Model Router state
- **Simplicity**: Direct API calls without complex routing
- **Performance**: Fewer network hops and processing layers
- **Debuggability**: Clear request/response cycle

### Limitations
- **Cloud Models**: Doesn't support cloud models (OpenAI, Anthropic)
- **Advanced Features**: Lacks model switching based on content
- **Scalability**: Won't scale to many different model types
- **Management**: No centralized model management

## Integration with Streamlit UI

The Streamlit UI was updated to use the direct Ollama access approach:

1. **Debug Information**: Shows the actual API requests and responses
2. **Model Selection**: Still works through the UI
3. **Provider Selection**: All providers still appear, but only Ollama works reliably

## Future Integration with Model Router

This direct access approach is a temporary solution while the Model Router issues are addressed. The long-term plan is to:

1. Fix the underlying Model Router issues
2. Maintain direct access as a fallback mechanism
3. Gradually transition to using the Model Router for all models
4. Implement proper fallback chains in the Model Router

See [MODEL-ROUTER-ISSUES.md](./model-router-issues.md) for details on the Model Router issues and planned fixes.