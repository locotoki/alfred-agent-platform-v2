"""
Streamlit Chat UI - Alfred Agent Platform
A simple UI for interacting with the Alfred Agent Platform
"""

import os
import json
import time
import requests
import streamlit as st
from datetime import datetime

# Configuration
API_URL = os.environ.get("ALFRED_API_URL", "http://agent-core:8011")
MODEL_ROUTER_URL = os.environ.get("ALFRED_MODEL_ROUTER_URL", "http://model-router:8080")
ENABLE_DIRECT_INFERENCE = os.environ.get("ENABLE_DIRECT_INFERENCE", "true").lower() == "true"

# Page config
st.set_page_config(
    page_title="Alfred Agent Chat",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Sidebar
st.sidebar.title("Alfred Agent Platform")
st.sidebar.subheader("Configuration")

# Model selection
model_options = ["gpt-3.5-turbo", "claude-3-sonnet", "llama2", "gemini-pro"]
selected_model = st.sidebar.selectbox("Select Model", model_options)

# Direct inference option
use_direct_inference = st.sidebar.checkbox(
    "Use direct model inference", value=ENABLE_DIRECT_INFERENCE
)

# Debug mode
debug_mode = st.sidebar.checkbox("Debug Mode", value=False)

# Initialize session state
if "messages" not in st.session_state:
    st.session_state.messages = []

if "api_responses" not in st.session_state:
    st.session_state.api_responses = []

# Main content
st.title("Alfred Agent Chat")

# Display chat messages
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.write(message["content"])

# Chat input
prompt = st.chat_input("Type your message here...")


# Function to send message to API
def send_message_to_api(prompt, model):
    start_time = time.time()

    # Direct inference to model router
    if use_direct_inference:
        try:
            response = requests.post(
                f"{MODEL_ROUTER_URL}/v1/chat/completions",
                json={
                    "model": model,
                    "messages": [{"role": "user", "content": prompt}],
                    "temperature": 0.7,
                },
                timeout=30,
            )
            response_data = response.json()
            response_text = (
                response_data.get("choices", [{}])[0].get("message", {}).get("content", "")
            )
            api_details = {
                "endpoint": f"{MODEL_ROUTER_URL}/v1/chat/completions",
                "response_time": f"{time.time() - start_time:.2f}s",
                "status_code": response.status_code,
                "raw_response": response_data,
            }

        except Exception as e:
            response_text = f"Error connecting to model service: {str(e)}"
            api_details = {"error": str(e), "endpoint": f"{MODEL_ROUTER_URL}/v1/chat/completions"}

    # Use agent API
    else:
        try:
            response = requests.post(
                f"{API_URL}/api/v1/chat", json={"prompt": prompt, "model": model}, timeout=30
            )
            response_data = response.json()
            response_text = response_data.get("response", "")
            api_details = {
                "endpoint": f"{API_URL}/api/v1/chat",
                "response_time": f"{time.time() - start_time:.2f}s",
                "status_code": response.status_code,
                "raw_response": response_data,
            }

        except Exception as e:
            response_text = f"Error connecting to API: {str(e)}"
            api_details = {"error": str(e), "endpoint": f"{API_URL}/api/v1/chat"}

    return response_text, api_details


# Process chat input
if prompt:
    # Add user message to chat
    st.session_state.messages.append({"role": "user", "content": prompt})

    # Display user message
    with st.chat_message("user"):
        st.write(prompt)

    # Show typing indicator
    with st.chat_message("assistant"):
        with st.spinner("Thinking..."):
            response_text, api_details = send_message_to_api(prompt, selected_model)
            st.session_state.api_responses.append(api_details)
            st.write(response_text)

    # Add assistant message to chat history
    st.session_state.messages.append({"role": "assistant", "content": response_text})

# Debug information
if debug_mode and st.session_state.api_responses:
    st.sidebar.subheader("API Details")
    for i, api_response in enumerate(st.session_state.api_responses):
        with st.sidebar.expander(f"Response {i+1}"):
            st.write(f"**Endpoint:** {api_response.get('endpoint')}")
            st.write(f"**Response Time:** {api_response.get('response_time', 'N/A')}")
            st.write(f"**Status Code:** {api_response.get('status_code', 'N/A')}")
            if "error" in api_response:
                st.error(f"**Error:** {api_response['error']}")
            if "raw_response" in api_response:
                st.json(api_response["raw_response"])

# Footer
st.sidebar.markdown("---")
st.sidebar.caption(f"Alfred Agent Platform v2 • {datetime.now().strftime('%Y-%m-%d')}")
st.sidebar.caption("Made with ❤️ using Streamlit")


# Health check endpoint for Docker
def health():
    return {"status": "healthy"}
