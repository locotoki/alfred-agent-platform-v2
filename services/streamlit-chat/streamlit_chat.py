import os

import requests
import streamlit as st

# Configuration
ALFRED_API_URL = os.getenv("ALFRED_API_URL", "http://agent-core:8011")
ALFRED_MODEL_ROUTER_URL = os.getenv("ALFRED_MODEL_ROUTER_URL", "http://model-router:8080")
ENABLE_DIRECT_INFERENCE = os.getenv("ENABLE_DIRECT_INFERENCE", "true").lower() == "true"

# Page config
st.set_page_config(page_title="Alfred Chat", page_icon="🤖", layout="wide")

# Main UI
st.title("🤖 Alfred Chat UI")
st.header("Welcome to Alfred Chat")

# Check connection status
try:
    response = requests.get(f"{ALFRED_API_URL}/health", timeout=5)
    if response.status_code == 200:
        st.success("✅ Status: Connected to Alfred Core")
    else:
        st.warning("⚠️ Status: Alfred Core responding but unhealthy")
except:
    st.error("❌ Status: Cannot connect to Alfred Core")

# Sidebar settings
with st.sidebar:
    st.header("⚙️ Settings")
    use_direct = st.checkbox("Use direct model inference", value=ENABLE_DIRECT_INFERENCE)
    st.markdown("---")
    st.markdown("### 🔗 Service URLs")
    st.code(f"Core: {ALFRED_API_URL}")
    st.code(f"Model: {ALFRED_MODEL_ROUTER_URL}")

# Chat interface
st.markdown("---")
message = st.text_input("💬 Your message", placeholder="Type your message here...")
if st.button("Send", type="primary"):
    if message:
        st.info(f"Message sent: {message}")
    else:
        st.warning("Please enter a message")
