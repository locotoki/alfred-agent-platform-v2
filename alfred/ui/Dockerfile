FROM alfred/healthcheck:0.4.0 AS healthcheck

FROM python:3.11-slim
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck
RUN chmod +x /usr/local/bin/healthcheck

WORKDIR /app

# Install dependencies
RUN pip install --no-cache-dir streamlit requests 

# Copy application code
COPY streamlit_chat_ui.py .

# Expose Streamlit port
EXPOSE 8501
EXPOSE 9091

# Set environment variables
ENV ALFRED_API_URL=http://agent-core:8011
ENV ALFRED_MODEL_ROUTER_URL=http://model-router:8080
ENV ENABLE_DIRECT_INFERENCE=true

# Run the application with healthcheck wrapper
CMD ["healthcheck", "--export-prom", ":9091", "--", "streamlit", "run", "streamlit_chat_ui.py", "--server.address=0.0.0.0"]
