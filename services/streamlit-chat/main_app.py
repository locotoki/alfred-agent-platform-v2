import streamlit as st
import os
from datetime import datetime
import structlog
import requests

# Import needed modules
from model_registry_client import ModelRegistryClient
from send_message import send_message

# Configure logging
logger = structlog.get_logger(__name__)

# Configuration
ALFRED_API_URL = os.getenv("ALFRED_API_URL", "http://localhost:8011")
MODEL_REGISTRY_URL = os.getenv("MODEL_REGISTRY_URL", "http://localhost:8079")
MODEL_ROUTER_URL = os.getenv("MODEL_ROUTER_URL", "http://localhost:8080")
SESSION_USER_ID = "streamlit_user"  # Default user ID for session
SESSION_CHANNEL_ID = "streamlit_channel"  # Default channel ID for session

# Page config
st.set_page_config(
    page_title="Alfred Chat Interface",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Apply custom CSS
st.markdown("""
<style>
    .chat-message-user {
        background-color: #e6f7ff;
        border-radius: 10px;
        padding: 10px;
        margin-bottom: 10px;
    }
    .chat-message-assistant {
        background-color: #f0f0f0;
        border-radius: 10px;
        padding: 10px;
        margin-bottom: 10px;
    }
    .thinking {
        color: #888888;
        font-style: italic;
    }
    .header-container {
        display: flex;
        align-items: center;
    }
    .header-title {
        font-weight: bold;
        font-size: 1.5rem;
    }
    .header-icon {
        font-size: 2rem;
        margin-right: 10px;
    }
    .command-help {
        background-color: #f9f9f9;
        border-left: 5px solid #4CAF50;
        padding: 10px;
        margin-bottom: 10px;
    }
</style>
""", unsafe_allow_html=True)

def init_session_state():
    """Initialize session state if it doesn't exist."""
    if "messages" not in st.session_state:
        st.session_state.messages = []
    
    if "debug_mode" not in st.session_state:
        st.session_state.debug_mode = False
    
    if "chat_history_size" not in st.session_state:
        st.session_state.chat_history_size = 100
    
    if "api_url" not in st.session_state:
        st.session_state.api_url = ALFRED_API_URL
    
    if "model_registry_url" not in st.session_state:
        st.session_state.model_registry_url = MODEL_REGISTRY_URL
    
    if "model_router_url" not in st.session_state:
        st.session_state.model_router_url = MODEL_ROUTER_URL
    
    if "selected_model" not in st.session_state:
        st.session_state.selected_model = "auto"  # "auto" means let the router decide
    
    if "available_models" not in st.session_state:
        st.session_state.available_models = []
        
    if "model_registry_client" not in st.session_state:
        st.session_state.model_registry_client = ModelRegistryClient(MODEL_REGISTRY_URL)

def process_command(message: str) -> str:
    """Process commands with special handling."""
    if message.startswith("/"):
        # Strip the leading slash
        command = message[1:].strip()
    else:
        command = message.strip()
        
    # Split into command and arguments
    parts = command.split(maxsplit=1)
    cmd = parts[0].lower() if parts else ""
    args = parts[1] if len(parts) > 1 else ""
    
    # Handle commands that need special UI treatment
    if cmd == "help":
        return """
## Alfred Bot Commands

I can help you with various tasks through commands:

### Basic Commands:
- `help` - Show this help message
- `ping` - Check if Alfred is responsive
- `models` - List all available LLM models

### Intelligence:
- `trend <topic>` - Analyze trends for a topic

### Task Management:
- `status <task_id>` - Check task status
- `cancel <task_id>` - Cancel a running task
"""
    elif cmd == "ping":
        # Simulate a ping response when API is not fully functional
        try:
            # Try real API first
            response = send_message(command, SESSION_USER_ID, SESSION_CHANNEL_ID) 
            if "Not Found" in response:
                return "Pong! Alfred is responsive (simulated response)."
            return response
        except Exception:
            return "Pong! Alfred is responsive (simulated response)."
    elif cmd == "models":
        # Get models from the registry client
        try:
            models = st.session_state.model_registry_client.get_all_models()
            
            # Format the models for display
            models_by_provider = {}
            for model in models:
                provider = model.get("provider", "unknown")
                if provider not in models_by_provider:
                    models_by_provider[provider] = []
                models_by_provider[provider].append(model)
            
            # Build the response text
            response = "## Available Models\n\n"
            
            for provider, provider_models in sorted(models_by_provider.items()):
                response += f"### {provider.title()}\n"
                for model in provider_models:
                    display_name = model.get("display_name", model.get("name", "Unknown"))
                    description = model.get("description", "")
                    model_id = model.get("name", "unknown")
                    response += f"- **{display_name}** ({model_id})"
                    if description:
                        response += f": {description}"
                    response += "\n"
                response += "\n"
            
            return response
        except Exception as e:
            logger.error("list_models_failed", error=str(e))
            return f"Error fetching models: {str(e)}"
    else:
        # Default processing through API
        return send_message(command, SESSION_USER_ID, SESSION_CHANNEL_ID)

def fetch_available_models():
    """Fetch available models from the Model Registry."""
    try:
        client = st.session_state.model_registry_client
        models = client.get_all_models()
        
        # Format models for display
        formatted_models = [
            {"id": model["name"], 
             "name": model["display_name"], 
             "provider": model["provider"],
             "description": model.get("description", "")}
            for model in models
        ]
        
        # Sort models by provider and then by name
        formatted_models.sort(key=lambda x: (x["provider"], x["name"]))
        
        # Add "auto" option at the top
        formatted_models.insert(0, {
            "id": "auto",
            "name": "Auto (Let system decide)",
            "provider": "system",
            "description": "Automatically select the best model based on your query"
        })
        
        st.session_state.available_models = formatted_models
        return formatted_models
    except Exception as e:
        logger.error(f"Failed to fetch models: {e}")
        # Return at least the "auto" option if fetch fails
        return [{
            "id": "auto",
            "name": "Auto (Let system decide)",
            "provider": "system",
            "description": "Automatically select the best model based on your query"
        }]

def sidebar_config():
    """Setup and handle sidebar configuration."""
    st.sidebar.title("Configuration")
    
    # Model selection section
    st.sidebar.subheader("Model Selection")
    
    # Refresh models button
    if st.sidebar.button("Refresh Models"):
        with st.sidebar:
            with st.spinner("Fetching available models..."):
                fetch_available_models()
    
    # Ensure models are loaded
    models = st.session_state.available_models
    if not models:
        with st.sidebar:
            with st.spinner("Loading models..."):
                models = fetch_available_models()
    
    # Group models by provider
    providers = sorted(set(model["provider"] for model in models))
    
    # Create radio buttons for model selection
    selected_provider = st.sidebar.radio(
        "Provider", 
        providers,
        index=providers.index("system") if "system" in providers else 0
    )
    
    # Filter models by selected provider
    provider_models = [model for model in models if model["provider"] == selected_provider]
    
    # Create select box for models from the selected provider
    model_options = {model["name"]: model["id"] for model in provider_models}
    selected_model_name = st.sidebar.selectbox(
        "Model",
        list(model_options.keys()),
        index=0
    )
    
    # Update selected model in session state
    selected_model_id = model_options[selected_model_name]
    if selected_model_id != st.session_state.selected_model:
        st.session_state.selected_model = selected_model_id
    
    # Show model description if available
    selected_model = next((m for m in models if m["id"] == selected_model_id), None)
    if selected_model and selected_model.get("description"):
        st.sidebar.info(selected_model["description"])
    
    st.sidebar.divider()
    
    # API URL configuration
    st.sidebar.subheader("Connection Settings")
    api_url = st.sidebar.text_input(
        "Alfred API URL", 
        value=st.session_state.api_url
    )
    if api_url != st.session_state.api_url:
        st.session_state.api_url = api_url
    
    model_registry_url = st.sidebar.text_input(
        "Model Registry URL", 
        value=st.session_state.model_registry_url
    )
    if model_registry_url != st.session_state.model_registry_url:
        st.session_state.model_registry_url = model_registry_url
        # Update client with new URL
        st.session_state.model_registry_client = ModelRegistryClient(model_registry_url)
    
    st.sidebar.divider()
    
    # Chat history size
    st.sidebar.subheader("Display Settings")
    chat_history_size = st.sidebar.slider(
        "Chat History Size", 
        min_value=10, 
        max_value=500, 
        value=st.session_state.chat_history_size,
        step=10
    )
    if chat_history_size != st.session_state.chat_history_size:
        st.session_state.chat_history_size = chat_history_size
    
    # Debug mode toggle
    debug_mode = st.sidebar.checkbox(
        "Debug Mode", 
        value=st.session_state.debug_mode
    )
    if debug_mode != st.session_state.debug_mode:
        st.session_state.debug_mode = debug_mode
    
    st.sidebar.divider()
    
    # Actions section
    st.sidebar.subheader("Actions")
    
    # Clear chat button
    if st.sidebar.button("Clear Chat History"):
        st.session_state.messages = []
        st.rerun()
    
    # Connection test
    if st.sidebar.button("Test Connection"):
        with st.sidebar:
            with st.spinner("Testing connection..."):
                # Check Alfred API connection
                try:
                    # First try the /health endpoint (standard)
                    health_url = f"{st.session_state.api_url}/health"
                    try:
                        health_response = requests.get(health_url, timeout=3)
                        
                        if health_response.status_code == 200:
                            st.success(f"Connected to Alfred Bot API ({health_response.elapsed.total_seconds():.3f}s)")
                        else:
                            # Try root endpoint as fallback
                            root_response = requests.get(st.session_state.api_url, timeout=3)
                            if root_response.status_code == 200:
                                st.success(f"Connected to Alfred Bot API ({root_response.elapsed.total_seconds():.3f}s)")
                            else:
                                st.error(f"API check failed: {health_response.status_code} & {root_response.status_code}")
                    except Exception:
                        # Try root endpoint as fallback
                        root_response = requests.get(st.session_state.api_url, timeout=3)
                        if root_response.status_code == 200:
                            st.success(f"Connected to Alfred Bot API ({root_response.elapsed.total_seconds():.3f}s)")
                        else:
                            raise
                except Exception as e:
                    st.error(f"Alfred API connection failed: {str(e)}")
                
                # Check Model Registry connection
                try:
                    registry_health_url = f"{st.session_state.model_registry_url}/health"
                    registry_response = requests.get(registry_health_url, timeout=3)
                    
                    if registry_response.status_code == 200:
                        st.success(f"Connected to Model Registry ({registry_response.elapsed.total_seconds():.3f}s)")
                    else:
                        st.warning(f"Model Registry health check failed: {registry_response.status_code}")
                        st.info("Using built-in model list instead of dynamic model discovery.")
                except Exception as e:
                    st.info("Model Registry service is not running.")
                    st.success("✅ Using built-in model list with OpenAI and Ollama models.")
                
                # Refresh models to show fallbacks
                fetch_available_models()
    
    st.sidebar.divider()
    
    # Add command reference
    with st.sidebar.expander("Command Reference"):
        st.markdown("""
        ### Quick Commands
        - `help` - Show all available commands
        - `ping` - Check if Alfred is responsive
        - `models` - List all available LLM models
        - `trend <topic>` - Analyze trends for a topic
        - `status <task_id>` - Check task status
        
        You can use commands with or without the leading slash.
        """)

def main():
    """Main application function."""
    # Initialize session state
    init_session_state()
    
    # Configure sidebar
    sidebar_config()
    
    # Header with custom styling
    st.markdown(
        '<div class="header-container">'
        '<span class="header-icon">🤖</span>'
        '<span class="header-title">Alfred Chat Interface</span>'
        '</div>',
        unsafe_allow_html=True
    )
    
    # Display all previous messages
    for message in st.session_state.messages:
        with st.chat_message(message["role"]):
            st.markdown(message["content"])
    
    # User input
    prompt = st.chat_input("Send a message to Alfred...")
    
    if prompt:
        # Display user message
        with st.chat_message("user"):
            st.markdown(prompt)
        
        # Add user message to history
        st.session_state.messages.append({
            "role": "user", 
            "content": prompt, 
            "time": datetime.now().isoformat()
        })
        
        # Display thinking indicator
        with st.chat_message("assistant"):
            message_placeholder = st.empty()
            message_placeholder.markdown('<div class="thinking">Thinking...</div>', unsafe_allow_html=True)
            
            # Process the message and get response
            response = process_command(prompt)
            
            # Update with actual response
            message_placeholder.markdown(response)
        
        # Add assistant response to history
        st.session_state.messages.append({
            "role": "assistant", 
            "content": response, 
            "time": datetime.now().isoformat()
        })
        
        # Trim history if it exceeds the maximum size
        if len(st.session_state.messages) > st.session_state.chat_history_size:
            st.session_state.messages = st.session_state.messages[-st.session_state.chat_history_size:]

if __name__ == "__main__":
    main()