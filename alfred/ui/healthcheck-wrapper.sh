#!/bin/bash
# Simple health check wrapper that runs the actual service
# This avoids the exec format error from the healthcheck binary

# Just run streamlit directly
exec streamlit run streamlit_chat.py --server.address=0.0.0.0
