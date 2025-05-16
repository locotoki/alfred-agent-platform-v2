import os
import requests
import streamlit as st

# Set page configuration
st.set_page_config(
    page_title="Alfred Chat UI",
    page_icon="🤖",
    layout="wide"
)

# Configuration
MODEL_ROUTER_URL = os.environ.get("ALFRED_MODEL_ROUTER_URL", "http://model-router:8080")
API_URL = os.environ.get("ALFRED_API_URL", "http://agent-core:8011")
ENABLE_DIRECT_INFERENCE = os.environ.get("ENABLE_DIRECT_INFERENCE", "true").lower() == "true"

# App state
if "messages" not in st.session_state:
    st.session_state.messages = []
if "current_model" not in st.session_state:
    st.session_state.current_model = "gpt-3.5-turbo"

# App title and header
st.title("Alfred Chat UI")
st.header("Welcome to Alfred Chat")

# Connection status indicator
try:
    # Try to connect to the model router
    response = requests.get(f"{MODEL_ROUTER_URL}/health", timeout=2)
    if response.status_code == 200:
        st.write("✅ Status: Connected to model router")
    else:
        st.warning(f"⚠️ Model router connection issue: {response.status_code}")
except Exception as e:
    st.error(f"❌ Could not connect to model router: {str(e)}")
    st.info("Falling back to simulation mode")

# Sidebar for settings
with st.sidebar:
    st.header("Settings")
    
    # Enable direct inference
    use_direct_inference = st.checkbox("Use direct model inference", value=ENABLE_DIRECT_INFERENCE)
    
    # Model selection
    available_models = ["gpt-3.5-turbo", "gpt-4", "claude-3-sonnet", "claude-3-opus", "llama2", "llama3"]
    
    if use_direct_inference:
        try:
            # Fetch available models from model router
            response = requests.get(f"{MODEL_ROUTER_URL}/models", timeout=2)
            if response.status_code == 200:
                fetched_models = response.json()
                if fetched_models and isinstance(fetched_models, list):
                    available_models = fetched_models
                    st.success("✅ Loaded models from model router")
        except Exception as e:
            st.warning(f"Could not fetch models: {str(e)}")
            st.info("Using default model list")
    
    st.session_state.current_model = st.selectbox("Select model", available_models)
    
    # Debug mode
    debug_mode = st.checkbox("Debug Mode", value=False)
    
    if debug_mode:
        st.write("#### Debug Info")
        st.write(f"Model Router: {MODEL_ROUTER_URL}")
        st.write(f"API URL: {API_URL}")
        st.write(f"Current Model: {st.session_state.current_model}")

# Display existing messages
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.write(message["content"])

# User input
user_input = st.chat_input("Type your message here...")

if user_input:
    # Add user message to the UI
    with st.chat_message("user"):
        st.write(user_input)
    
    # Add user message to session state
    st.session_state.messages.append({"role": "user", "content": user_input})
    
    # Show thinking indicator
    with st.chat_message("assistant"):
        thinking_placeholder = st.empty()
        thinking_placeholder.write("Thinking...")
        
        try:
            if use_direct_inference:
                # Send request to model router
                payload = {
                    "model": st.session_state.current_model,
                    "messages": st.session_state.messages,
                    "temperature": 0.7
                }
                response = requests.post(f"{MODEL_ROUTER_URL}/completions", json=payload, timeout=30)
                
                if response.status_code == 200:
                    response_data = response.json()
                    assistant_response = response_data.get("choices", [{}])[0].get("message", {}).get("content", "")
                else:
                    assistant_response = f"Error from model router: {response.status_code} - {response.text}"
            else:
                # Simulation mode - echo back with model info
                assistant_response = f"You said: {user_input}\n\nThis is a simulated response from {st.session_state.current_model}."
            
            # Update thinking message with actual response
            thinking_placeholder.write(assistant_response)
            
            # Add assistant response to session state
            st.session_state.messages.append({"role": "assistant", "content": assistant_response})
            
        except Exception as e:
            error_message = f"Error processing your request: {str(e)}"
            thinking_placeholder.write(error_message)
            
            # Add error message to session state
            st.session_state.messages.append({"role": "assistant", "content": error_message})

# Health endpoint for Docker healthcheck
def health():
    return {"status": "ok"}