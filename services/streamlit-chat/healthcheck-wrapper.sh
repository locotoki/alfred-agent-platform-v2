#!/bin/sh
# Health check wrapper for ui-chat service

# Start the streamlit application in the background
streamlit run streamlit_chat.py --server.address=0.0.0.0 --server.port=8501 &

# Give streamlit time to start
sleep 5

# Start the health proxy that will handle health checks
exec python health_proxy.py