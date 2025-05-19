import asyncio
import json
import os
import time
from datetime import datetime

import requests
import streamlit as st
import structlog

# Configure logging
logger = structlog.get_logger(__name__)

# Application constants
API_URL = os.environ.get("ALFRED_API_URL", "http://agent-core:8011")
MODEL_REGISTRY_URL = os.getenv("MODEL_REGISTRY_URL", "http://model-registry:8079")
MODEL_ROUTER_URL = os.getenv("MODEL_ROUTER_URL", "http://model-router:8080")
SESSION_USER_ID = "streamlit_user"  # Default user ID for session
SESSION_CHANNEL_ID = "streamlit_channel"  # Default channel ID for session

# Configure the page
st.set_page_config(
    page_title="Alfred Chat Interface",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Apply custom CSS
st.markdown(
    """
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
""",
    unsafe_allow_html=True,
)


class ModelRegistryClient:
    """Client for interacting with the Model Registry service."""

    def __init__(self, base_url=None):
        """Initialize the Model Registry client."""
        self.base_url = base_url or os.environ.get("MODEL_REGISTRY_URL", "http://localhost:8079")
        self._models_cache = {}
        self._last_refresh = 0
        self._cache_ttl = 60  # Cache TTL in seconds

    def _refresh_cache_if_needed(self):
        """Refresh the models cache if it's expired."""
        pass  # We'll use hardcoded models for now

    def get_all_models(self) -> list:
        """
        Get all available models from the Model Registry.

        Returns:
            List of model configurations
        """
        try:
            response = requests.get(f"{self.base_url}/api/v1/models", timeout=2)
            response.raise_for_status()
            return response.json()
        except requests.RequestException as e:
            logger.error(f"Error fetching models: {e}")
            # Return hardcoded models
            return [
                {
                    "name": "gpt4o",
                    "display_name": "GPT-4o",
                    "provider": "openai",
                    "description": "OpenAI's GPT-4o model with vision capabilities",
                    "active": True,
                },
                {
                    "name": "gpt4-1mini",
                    "display_name": "GPT-4.1-mini",
                    "provider": "openai",
                    "description": "OpenAI's more efficient GPT-4.1-mini model",
                    "active": True,
                },
                {
                    "name": "gpt4-1",
                    "display_name": "GPT-4.1",
                    "provider": "openai",
                    "description": "OpenAI's GPT-4.1 for complex tasks",
                    "active": True,
                },
                {
                    "name": "gpt35-turbo",
                    "display_name": "GPT-3.5 Turbo",
                    "provider": "openai",
                    "description": "OpenAI's cost-effective GPT-3.5 Turbo model",
                    "active": True,
                },
                {
                    "name": "llama3",
                    "display_name": "Llama 3 (8B)",
                    "provider": "ollama",
                    "description": "Meta's Llama 3 model (8B version)",
                    "active": True,
                },
                {
                    "name": "llama3:70b",
                    "display_name": "Llama 3 (70B)",
                    "provider": "ollama",
                    "description": "Meta's Llama 3 model (70B version)",
                    "active": True,
                },
                {
                    "name": "codellama",
                    "display_name": "CodeLlama",
                    "provider": "ollama",
                    "description": "Meta's CodeLlama model for code generation and analysis",
                    "active": True,
                },
                {
                    "name": "llava",
                    "display_name": "LLaVA",
                    "provider": "ollama",
                    "description": "Multimodal model for vision and language tasks",
                    "active": True,
                },
            ]

    def get_model_by_name(self, name: str) -> dict:
        """
        Get a specific model by name.

        Args:
            name: The name of the model to retrieve

        Returns:
            Model configuration if found, None otherwise
        """
        # Special handling for 'auto'
        if name == "auto":
            return {
                "name": "auto",
                "display_name": "Auto (Let system decide)",
                "provider": "system",
                "description": "Automatically select the best model based on your query",
                "active": True,
            }

        # Check hardcoded models
        all_models = self.get_all_models()
        for model in all_models:
            if model["name"] == name:
                return model

        return None


async def send_message_async(message: str) -> str:
    """Send a message to the LLM service or Alfred Bot API asynchronously."""
    try:
        # Check if we should use direct LLM inference
        if (
            hasattr(st.session_state, "use_direct_inference")
            and st.session_state.use_direct_inference
        ):
            # Import the client lazily to avoid circular imports
            import asyncio

            from send_message import create_model_router_client

            # Create client if needed
            if not hasattr(st.session_state, "model_router_client"):
                st.session_state.model_router_client = create_model_router_client(
                    st.session_state.model_router_url
                )

            # Use model router client for direct model inference
            model_id = st.session_state.selected_model

            if st.session_state.debug_mode:
                st.sidebar.write("Sending to Model Router", {"message": message, "model": model_id})

            # Process the message
            response_data = await st.session_state.model_router_client.process_message(
                message=message,
                model_id=model_id if model_id != "auto" else None,
                user_id=SESSION_USER_ID,
                debug_mode=st.session_state.debug_mode,
            )

            if st.session_state.debug_mode:
                st.sidebar.write("Model Router Response:", response_data)

            # Check for errors
            if "error" in response_data:
                # Fall back to simulated response
                model_info = ""
                if model_id != "auto":
                    model_info = f" (using {model_id})"

                error_details = response_data.get("error", "Unknown error")
                logger.error(f"Model Router error: {error_details}")

                if st.session_state.debug_mode:
                    return f'Error from Model Router: {error_details}\n\nI received your message: "{message}"{model_info}'
                else:
                    return f'I received your message: "{message}"{model_info}\n\nThis is a simulated response as there was an error with the model. In production, this would be processed by the appropriate model and agent.'

            # Extract the response content
            if "response" in response_data:
                return response_data["response"]
            elif "content" in response_data:
                return response_data["content"]
            else:
                # Return stringified response as fallback
                return f"Response from model: {str(response_data)}"

        else:
            # Fall back to calling the Alfred API endpoint
            url = f"{st.session_state.api_url}/api/chat"

            payload = {
                "message": message,
                "user_id": SESSION_USER_ID,
                "channel_id": SESSION_CHANNEL_ID,
            }

            # Add model selection if not set to "auto"
            if st.session_state.selected_model != "auto":
                payload["model"] = st.session_state.selected_model

            if st.session_state.debug_mode:
                st.sidebar.write("Request to Alfred API:", payload)

            response = requests.post(
                url,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=30,  # Longer timeout for API calls
            )

            # If we get a 404, the app might not be running the core.py version
            # Simulate a basic response
            if response.status_code == 404:
                if st.session_state.debug_mode:
                    st.sidebar.warning("API endpoint not found. Using simulated response.")

                # Create a simulated response with the selected model info
                model_info = ""
                if st.session_state.selected_model != "auto":
                    model_info = f" (using {st.session_state.selected_model})"

                return f'I received your message: "{message}"{model_info}\n\nThis is a simulated response as the full API is not yet deployed. In production, this would be processed by the appropriate model and agent.'

            if response.status_code == 200:
                data = response.json()
                if st.session_state.debug_mode:
                    st.sidebar.write("Response:", data)
                return data.get("response", "No response received")
            else:
                error_msg = f"Error: {response.status_code} - {response.text}"
                if st.session_state.debug_mode:
                    st.sidebar.write("Error:", error_msg)

                # Create a simulated response with the selected model info
                model_info = ""
                if st.session_state.selected_model != "auto":
                    model_info = f" (using {st.session_state.selected_model})"

                return f'I received your message: "{message}"{model_info}\n\nThis is a simulated response as the API returned an error. In production, this would be processed by the appropriate model and agent.'
    except Exception as e:
        error_msg = f"Error communicating with service: {str(e)}"
        logger.error("api_communication_failed", error=str(e))
        if st.session_state.debug_mode:
            st.sidebar.write("Exception:", error_msg)

        # Provide a graceful response
        model_info = ""
        if st.session_state.selected_model != "auto":
            model_info = f" (using {st.session_state.selected_model})"

        return f'I received your message: "{message}"{model_info}\n\nThis is a simulated response as there was an error communicating with the service. In production, this would be processed by the appropriate model and agent.'


# Synchronous wrapper for the async function
def send_message(message: str) -> str:
    """Synchronous wrapper around send_message_async."""
    try:
        # For direct inference which needs async
        if (
            hasattr(st.session_state, "use_direct_inference")
            and st.session_state.use_direct_inference
        ):
            # Use the synchronous version that falls back to the API
            return send_message_sync(message)
        else:
            # If using the API directly, just call it synchronously
            return send_message_sync(message)
    except Exception as e:
        logger.error(f"Error in send_message: {e}")
        return f"Error processing your message: {str(e)}"


def init_session_state():
    """Initialize session state if it doesn't exist."""
    if "messages" not in st.session_state:
        st.session_state.messages = []

    if "debug_mode" not in st.session_state:
        st.session_state.debug_mode = False

    if "chat_history_size" not in st.session_state:
        st.session_state.chat_history_size = 100

    if "api_url" not in st.session_state:
        st.session_state.api_url = API_URL

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

    if "use_direct_inference" not in st.session_state:
        st.session_state.use_direct_inference = True  # Enable direct model inference by default


def process_command(message: str) -> str:
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
        "messages": [{"role": "user", "content": message}],
        "stream": False,
    }

    if st.session_state.debug_mode:
        st.sidebar.write(f"Sending direct to Ollama with model: {model_name}")
        st.sidebar.write("Payload:", payload)

    # List of endpoints to try
    ollama_endpoints = [
        "http://alfred-ollama:11434",
        "http://ollama:11434",
        "http://localhost:11434",
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
                timeout=30,
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


def get_help_response() -> str:
    """Get a formatted help message."""
    help_md = """
    ## Alfred Bot Commands

    I can help you with various tasks through the chat interface.

    ### Basic Commands:
    - `help` - Show this help message
    - `ping` - Test bot responsiveness
    - `models` - List available LLM models

    ### Intelligence:
    - `trend <topic>` - Analyze trends for a topic

    ### Task Management:
    - `status <task_id>` - Check task status
    - `cancel <task_id>` - Cancel a running task

    > 💡 You can use commands with or without the leading slash (e.g., `help` or `/help`)
    """
    return help_md


def get_models_response() -> str:
    """Get a formatted list of available models."""
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


def fetch_available_models():
    """Fetch available models from the Model Registry."""
    try:
        client = st.session_state.model_registry_client
        models = client.get_all_models()

        # Format models for display
        formatted_models = [
            {
                "id": model["name"],
                "name": model["display_name"],
                "provider": model["provider"],
                "description": model.get("description", ""),
            }
            for model in models
        ]

        # Sort models by provider and then by name
        formatted_models.sort(key=lambda x: (x["provider"], x["name"]))

        # Add "auto" option at the top
        formatted_models.insert(
            0,
            {
                "id": "auto",
                "name": "Auto (Let system decide)",
                "provider": "system",
                "description": "Automatically select the best model based on your query",
            },
        )

        st.session_state.available_models = formatted_models
        return formatted_models
    except Exception as e:
        logger.error(f"Failed to fetch models: {e}")
        # Return at least the "auto" option if fetch fails
        return [
            {
                "id": "auto",
                "name": "Auto (Let system decide)",
                "provider": "system",
                "description": "Automatically select the best model based on your query",
            }
        ]


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
        "Provider", providers, index=providers.index("system") if "system" in providers else 0
    )

    # Filter models by selected provider
    provider_models = [model for model in models if model["provider"] == selected_provider]

    # Create select box for models from the selected provider
    model_options = {model["name"]: model["id"] for model in provider_models}
    selected_model_name = st.sidebar.selectbox("Model", list(model_options.keys()), index=0)

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

    # Direct inference toggle
    use_direct_inference = st.sidebar.checkbox(
        "Use direct model inference",
        value=st.session_state.use_direct_inference,
        help="When enabled, connects directly to models via the Model Router instead of using the Alfred API",
    )
    if use_direct_inference != st.session_state.use_direct_inference:
        st.session_state.use_direct_inference = use_direct_inference

    # Alfred API URL (only if not using direct inference)
    if not st.session_state.use_direct_inference:
        api_url = st.sidebar.text_input("Alfred API URL", value=st.session_state.api_url)
        if api_url != st.session_state.api_url:
            st.session_state.api_url = api_url

    # Model Registry URL
    model_registry_url = st.sidebar.text_input(
        "Model Registry URL", value=st.session_state.model_registry_url
    )
    if model_registry_url != st.session_state.model_registry_url:
        st.session_state.model_registry_url = model_registry_url
        # Update client with new URL
        st.session_state.model_registry_client = ModelRegistryClient(model_registry_url)

    # Model Router URL (only if using direct inference)
    if st.session_state.use_direct_inference:
        model_router_url = st.sidebar.text_input(
            "Model Router URL", value=st.session_state.model_router_url
        )
        if model_router_url != st.session_state.model_router_url:
            st.session_state.model_router_url = model_router_url
            # Clear existing client to force recreation with new URL
            if hasattr(st.session_state, "model_router_client"):
                delattr(st.session_state, "model_router_client")

    st.sidebar.divider()

    # Chat history size
    st.sidebar.subheader("Display Settings")
    chat_history_size = st.sidebar.slider(
        "Chat History Size",
        min_value=10,
        max_value=500,
        value=st.session_state.chat_history_size,
        step=10,
    )
    if chat_history_size != st.session_state.chat_history_size:
        st.session_state.chat_history_size = chat_history_size

    # Debug mode toggle
    debug_mode = st.sidebar.checkbox("Debug Mode", value=st.session_state.debug_mode)
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
                if not st.session_state.use_direct_inference:
                    try:
                        # First try the /health endpoint (standard)
                        health_url = f"{st.session_state.api_url}/health"
                        try:
                            health_response = requests.get(health_url, timeout=3)

                            if health_response.status_code == 200:
                                st.success(
                                    f"Connected to Alfred Bot API ({health_response.elapsed.total_seconds():.3f}s)"
                                )
                            else:
                                # Try root endpoint as fallback
                                root_response = requests.get(st.session_state.api_url, timeout=3)
                                if root_response.status_code == 200:
                                    st.success(
                                        f"Connected to Alfred Bot API ({root_response.elapsed.total_seconds():.3f}s)"
                                    )
                                else:
                                    st.error(
                                        f"API check failed: {health_response.status_code} & {root_response.status_code}"
                                    )
                        except Exception:
                            # Try root endpoint as fallback
                            root_response = requests.get(st.session_state.api_url, timeout=3)
                            if root_response.status_code == 200:
                                st.success(
                                    f"Connected to Alfred Bot API ({root_response.elapsed.total_seconds():.3f}s)"
                                )
                            else:
                                raise
                    except Exception as e:
                        st.error(f"Alfred API connection failed: {str(e)}")

                # Check Model Registry connection
                try:
                    registry_health_url = f"{st.session_state.model_registry_url}/health"
                    registry_response = requests.get(registry_health_url, timeout=3)

                    if registry_response.status_code == 200:
                        st.success(
                            f"Connected to Model Registry ({registry_response.elapsed.total_seconds():.3f}s)"
                        )
                    else:
                        st.warning(
                            f"Model Registry health check failed: {registry_response.status_code}"
                        )
                        st.info("Using built-in model list instead of dynamic model discovery.")
                except Exception as e:
                    st.info("Model Registry service is not running.")
                    st.success("✅ Using built-in model list with OpenAI and Ollama models.")

                # Check Model Router connection (only if using direct inference)
                if st.session_state.use_direct_inference:
                    try:
                        router_health_url = f"{st.session_state.model_router_url}/health"
                        router_response = requests.get(router_health_url, timeout=3)

                        if router_response.status_code == 200:
                            st.success(
                                f"Connected to Model Router ({router_response.elapsed.total_seconds():.3f}s)"
                            )
                        else:
                            st.warning(
                                f"Model Router health check failed: {router_response.status_code}"
                            )
                            st.info("Consider disabling direct model inference.")
                    except Exception as e:
                        st.error(f"Model Router connection failed: {str(e)}")
                        st.info("Consider disabling direct model inference.")

                # Check Ollama connection (if using direct inference)
                if st.session_state.use_direct_inference:
                    try:
                        ollama_url = "http://localhost:11434/api/tags"
                        ollama_response = requests.get(ollama_url, timeout=3)

                        if ollama_response.status_code == 200:
                            models = ollama_response.json().get("models", [])
                            model_names = [m.get("name") for m in models]
                            st.success(
                                f"Connected to Ollama - Available models: {', '.join(model_names)}"
                            )
                        else:
                            st.warning(f"Ollama check failed: {ollama_response.status_code}")
                    except Exception as e:
                        st.warning(f"Ollama connection failed: {str(e)}")

                # Refresh models to show fallbacks
                fetch_available_models()

    st.sidebar.divider()

    # Add command reference
    with st.sidebar.expander("Command Reference"):
        st.markdown(
            """
        ### Quick Commands
        - `help` - Show all available commands
        - `ping` - Check if Alfred is responsive
        - `models` - List all available LLM models
        - `trend <topic>` - Analyze trends for a topic
        - `status <task_id>` - Check task status

        You can use commands with or without the leading slash.
        """
        )


# Function to send messages to Alfred
def send_message_sync(message):
    """Synchronous function to send messages to Alfred."""
    try:
        # Get model information for the response
        model_info = ""
        if st.session_state.selected_model != "auto":
            model_info = f" (using {st.session_state.selected_model})"

        # Try direct model router connection first if enabled
        if st.session_state.use_direct_inference:
            try:
                # Create request payload for model router
                payload = {
                    "id": f"streamlit_{int(time.time())}",
                    "task_type": "chat",
                    "content": message,
                    "context": {
                        "user_id": SESSION_USER_ID,
                        "session_id": f"session_{SESSION_USER_ID}_{int(time.time())}",
                    },
                    "parameters": {"temperature": 0.7, "max_tokens": 1000},
                }

                # Add model selection if not set to "auto"
                if st.session_state.selected_model != "auto":
                    payload["model_preference"] = st.session_state.selected_model

                if st.session_state.debug_mode:
                    st.sidebar.write("Sending direct to Model Router:", payload)

                # Send request to model router process endpoint
                response = requests.post(
                    f"{st.session_state.model_router_url}/api/v1/process",
                    json=payload,
                    headers={"Content-Type": "application/json"},
                    timeout=60,  # Longer timeout for model inference
                )

                if response.status_code == 200:
                    result = response.json()
                    if st.session_state.debug_mode:
                        st.sidebar.write("Model Router Response:", result)

                    # Extract the content from the response
                    if "response" in result:
                        return result["response"]
                    elif "content" in result:
                        return result["content"]
                    elif "choices" in result and len(result["choices"]) > 0:
                        # Handle OpenAI-style response format
                        choice = result["choices"][0]
                        if "message" in choice and "content" in choice["message"]:
                            return choice["message"]["content"]
                        elif "text" in choice:
                            return choice["text"]
                    # If we couldn't extract the content, return the raw response
                    return f"Response from model: {str(result)}"
            except Exception as e:
                if st.session_state.debug_mode:
                    st.sidebar.write(f"Model Router Error: {str(e)}")
                # Continue to API or simulation on failure

        # Check health of API
        try:
            health_check = requests.get(f"{st.session_state.api_url}/health", timeout=3)
            api_healthy = health_check.status_code == 200
        except Exception:
            api_healthy = False

        # If API is healthy, try to call the chat endpoint
        if api_healthy:
            try:
                # Create payload with model selection if needed
                payload = {
                    "message": message,
                    "user_id": SESSION_USER_ID,
                    "channel_id": SESSION_CHANNEL_ID,
                }

                # Add model selection if not set to "auto"
                if st.session_state.selected_model != "auto":
                    payload["model"] = st.session_state.selected_model

                # Call the Alfred API endpoint
                response = requests.post(
                    f"{st.session_state.api_url}/api/chat",
                    json=payload,
                    headers={"Content-Type": "application/json"},
                    timeout=30,  # Longer timeout for API calls
                )

                if response.status_code == 200:
                    return response.json().get("response", "No response received")
            except Exception:
                # If chat endpoint fails, continue to simulation
                pass

        # If API is not healthy or chat endpoint failed, use simulated response
        # Provide a more interesting simulated response based on the message content
        if "hello" in message.lower() or "hi" in message.lower():
            return f"Hello! I'm Alfred, your intelligent assistant{model_info}. How can I help you today?"
        elif "help" in message.lower():
            return get_help_response()
        elif "models" in message.lower():
            return get_models_response()
        elif "how are you" in message.lower():
            return f"I'm doing well, thank you for asking! I'm ready to assist you with any tasks or questions{model_info}."
        elif any(
            word in message.lower()
            for word in ["who", "what", "about you", "yourself", "tell me about"]
        ):
            return f"I am Alfred, an AI assistant{model_info} designed to help with a variety of tasks. I can provide information, assist with analysis, and connect to various services. My capabilities include selecting different AI models to best handle your specific queries. How can I assist you today?"
        elif any(
            word in message.lower()
            for word in ["can", "able", "capability", "do for me", "help me"]
        ):
            return f"As your AI assistant{model_info}, I can help with many tasks including:\n\n- Answering questions and providing information\n- Processing and analyzing data\n- Integrating with various systems and services\n- Selecting appropriate models for specific tasks\n- Routing queries to specialized agents when needed\n\nWhat type of assistance do you need today?"
        elif any(word in message.lower() for word in ["thank", "thanks", "appreciate", "helpful"]):
            return f"You're welcome! I'm glad I could be of assistance{model_info}. Feel free to ask if you need anything else."
        else:
            # More varied generic responses
            import random

            responses = [
                f'I\'m analyzing your query: "{message}"{model_info}. In a full implementation, I would process this with the appropriate AI model and return a detailed response.',
                f'I\'ve received your message about "{message}"{model_info}. This demonstration shows how different models can be selected for different types of queries.',
                f'Thank you for your message: "{message}"{model_info}. The Alfred system is designed to route queries to the most appropriate model or agent based on the content.',
                f'I understand you\'re asking about "{message}"{model_info}. In a production environment, this would be processed by specialized AI models optimized for this type of query.',
            ]
            return random.choice(responses)
    except Exception as e:
        # Provide a graceful error response with model info
        model_info = ""
        if st.session_state.selected_model != "auto":
            model_info = f" (using {st.session_state.selected_model})"

        return f'I received your message: "{message}"{model_info}\n\nThis is a simulated response as there was an error communicating with Alfred: {str(e)}'


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
        "</div>",
        unsafe_allow_html=True,
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
        st.session_state.messages.append(
            {"role": "user", "content": prompt, "time": datetime.now().isoformat()}
        )

        # Display thinking indicator
        with st.chat_message("assistant"):
            message_placeholder = st.empty()
            message_placeholder.markdown(
                '<div class="thinking">Thinking...</div>', unsafe_allow_html=True
            )

            # Process the message and get response
            response = process_command(prompt)

            # Update with actual response
            message_placeholder.markdown(response)

        # Add assistant response to history
        st.session_state.messages.append(
            {"role": "assistant", "content": response, "time": datetime.now().isoformat()}
        )

        # Trim history if it exceeds the maximum size
        if len(st.session_state.messages) > st.session_state.chat_history_size:
            st.session_state.messages = st.session_state.messages[
                -st.session_state.chat_history_size :
            ]


if __name__ == "__main__":
    main()
