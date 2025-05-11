import streamlit as st
import requests
import json
import os

st.set_page_config(
    page_title="Alfred Agent Platform",
    page_icon="🤖",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Title and description
st.title("Alfred Agent Platform - Development Interface")
st.caption("⚠️ This is a development-only interface and not intended for production use.")

# Sidebar
st.sidebar.header("Services")

# Function to check service health
def check_service_health(url):
    try:
        response = requests.get(f"{url}/healthz", timeout=2)
        if response.status_code == 200:
            return "✅ Online"
        else:
            return "❌ Error"
    except Exception:
        return "❌ Offline"

# Display service status
services = {
    "Slack Bot": "http://slack-bot:8011",
    "Mission Control": "http://mission-control:8012", 
    "RAG Gateway": "http://rag-gateway:8013",
    "WhatsApp Adapter": "http://whatsapp-adapter:8014"
}

for service_name, service_url in services.items():
    status = check_service_health(service_url)
    st.sidebar.text(f"{service_name}: {status}")

# Tabs
tab1, tab2, tab3 = st.tabs(["Slack Bot", "RAG Gateway", "WhatsApp"])

# Slack Bot Tab
with tab1:
    st.header("Test Slack Bot")
    
    with st.form("slack_form"):
        user_id = st.text_input("User ID", value="U123456")
        channel_id = st.text_input("Channel ID", value="C789012")
        message_text = st.text_input("Message Text", value="help")
        
        submitted = st.form_submit_button("Send Message")
        
        if submitted:
            # Create a mock Slack event
            event_payload = {
                "token": "test_token",
                "team_id": "T123456",
                "api_app_id": "A123456",
                "event": {
                    "type": "message",
                    "text": message_text,
                    "user": user_id,
                    "ts": "1609459200.000001",
                    "channel": channel_id,
                    "channel_type": "channel"
                },
                "type": "event_callback",
                "event_id": "Ev123456",
                "event_time": 1609459200
            }
            
            try:
                response = requests.post(
                    f"{services['Slack Bot']}/api/events",
                    headers={"Content-Type": "application/json"},
                    json=event_payload,
                    timeout=5
                )
                
                st.subheader("Response")
                if response.status_code == 200:
                    st.json(response.json())
                else:
                    st.error(f"Error: {response.status_code}")
                    st.text(response.text)
            except Exception as e:
                st.error(f"Failed to connect: {str(e)}")

# RAG Gateway Tab
with tab2:
    st.header("Test RAG Gateway")
    
    with st.form("rag_form"):
        query = st.text_area("Query", value="What are the latest sales figures?")
        context = st.text_area("Context (JSON)", value='{"userId": "U123456", "channel": "C789012"}')
        
        submitted = st.form_submit_button("Send Query")
        
        if submitted:
            try:
                # Parse context
                context_json = json.loads(context)
                
                # Create payload
                payload = {
                    "query": query,
                    "context": context_json
                }
                
                response = requests.post(
                    f"{services['RAG Gateway']}/api/query",
                    headers={"Content-Type": "application/json"},
                    json=payload,
                    timeout=10
                )
                
                st.subheader("Response")
                if response.status_code == 200:
                    st.json(response.json())
                else:
                    st.error(f"Error: {response.status_code}")
                    st.text(response.text)
            except json.JSONDecodeError:
                st.error("Invalid JSON in context field")
            except Exception as e:
                st.error(f"Failed to connect: {str(e)}")

# WhatsApp Tab
with tab3:
    st.header("Test WhatsApp Adapter")
    
    with st.form("whatsapp_form"):
        phone_number = st.text_input("Phone Number", value="1234567890")
        message_text = st.text_area("Message Text", value="Hello from Alfred!")
        
        submitted = st.form_submit_button("Send Message")
        
        if submitted:
            try:
                # Create payload
                payload = {
                    "to": phone_number,
                    "message": message_text
                }
                
                response = requests.post(
                    f"{services['WhatsApp Adapter']}/api/send",
                    headers={"Content-Type": "application/json"},
                    json=payload,
                    timeout=5
                )
                
                st.subheader("Response")
                if response.status_code == 200:
                    st.json(response.json())
                else:
                    st.error(f"Error: {response.status_code}")
                    st.text(response.text)
            except Exception as e:
                st.error(f"Failed to connect: {str(e)}")

# Environment Info
st.sidebar.divider()
st.sidebar.subheader("Environment")
env_vars = {
    "ENVIRONMENT": os.environ.get("ENVIRONMENT", "Not set"),
    "SLACK_BOT_TOKEN": f"{os.environ.get('SLACK_BOT_TOKEN', 'Not set')[:5]}..." if os.environ.get('SLACK_BOT_TOKEN') else "Not set",
    "OPENAI_API_KEY": f"{os.environ.get('OPENAI_API_KEY', 'Not set')[:5]}..." if os.environ.get('OPENAI_API_KEY') else "Not set",
}

for key, value in env_vars.items():
    st.sidebar.text(f"{key}: {value}")