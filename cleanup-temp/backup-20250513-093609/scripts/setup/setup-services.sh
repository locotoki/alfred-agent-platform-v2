#!/bin/bash
#
# Alfred Agent Platform v2 - Service Setup Script
# This script helps set up the service directories for the refactored configuration
#

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Base directory
BASE_DIR="$(pwd)"

# Print banner
echo -e "${BLUE}"
echo "    _    _  __               _   "
echo "   / \  | |/ _|_ __ ___  __| |  "
echo "  / _ \ | | |_| '__/ _ \/ _\` |  "
echo " / ___ \| |  _| | |  __/ (_| |  "
echo "/_/   \_\_|_| |_|  \___|\__,_|  "
echo "                               "
echo " Agent Platform v2 - Service Setup"
echo -e "${NC}"

# Create service directory structure
function create_directories() {
  echo -e "${YELLOW}Creating service directory structure...${NC}"

  # Create services directory if it doesn't exist
  mkdir -p "$BASE_DIR/services/alfred-core"
  mkdir -p "$BASE_DIR/services/rag-service"
  mkdir -p "$BASE_DIR/services/atlas-service"

  # Create UI directory if it doesn't exist
  mkdir -p "$BASE_DIR/ui/chat"
  mkdir -p "$BASE_DIR/ui/admin"

  # Create monitoring directory if it doesn't exist
  mkdir -p "$BASE_DIR/monitoring/prometheus"
  mkdir -p "$BASE_DIR/monitoring/grafana/dashboards"
  mkdir -p "$BASE_DIR/monitoring/grafana/provisioning"

  # Create migrations directory if it doesn't exist
  mkdir -p "$BASE_DIR/migrations/supabase"

  echo -e "${GREEN}Directory structure created!${NC}"
}

# Create sample Dockerfiles
function create_sample_dockerfiles() {
  echo -e "${YELLOW}Creating sample Dockerfiles...${NC}"

  # Create alfred-core Dockerfile.dev
  cat > "$BASE_DIR/services/alfred-core/Dockerfile.dev" << EOF
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8011", "--reload"]
EOF

  # Create rag-service Dockerfile.dev
  cat > "$BASE_DIR/services/rag-service/Dockerfile.dev" << EOF
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8501", "--reload"]
EOF

  # Create ui-chat Dockerfile.dev
  cat > "$BASE_DIR/ui/chat/Dockerfile.dev" << EOF
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["streamlit", "run", "streamlit_app.py", "--server.port=8501", "--server.address=0.0.0.0"]
EOF

  echo -e "${GREEN}Sample Dockerfiles created!${NC}"
}

# Create sample requirements.txt files
function create_sample_requirements() {
  echo -e "${YELLOW}Creating sample requirements.txt files...${NC}"

  # Create alfred-core requirements.txt
  cat > "$BASE_DIR/services/alfred-core/requirements.txt" << EOF
fastapi==0.100.0
uvicorn==0.22.0
pydantic==2.0.2
httpx==0.24.1
python-dotenv==1.0.0
EOF

  # Create rag-service requirements.txt
  cat > "$BASE_DIR/services/rag-service/requirements.txt" << EOF
fastapi==0.100.0
uvicorn==0.22.0
pydantic==2.0.2
httpx==0.24.1
python-dotenv==1.0.0
langchain==0.0.235
EOF

  # Create ui-chat requirements.txt
  cat > "$BASE_DIR/ui/chat/requirements.txt" << EOF
streamlit==1.24.0
httpx==0.24.1
python-dotenv==1.0.0
EOF

  echo -e "${GREEN}Sample requirements.txt files created!${NC}"
}

# Create sample app files
function create_sample_apps() {
  echo -e "${YELLOW}Creating sample app files...${NC}"

  # Create alfred-core main.py
  mkdir -p "$BASE_DIR/services/alfred-core/app"
  cat > "$BASE_DIR/services/alfred-core/app/main.py" << EOF
from fastapi import FastAPI
import os

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Welcome to Alfred Agent Core"}

@app.get("/health")
async def health():
    return {"status": "healthy"}
EOF

  # Create rag-service main.py
  mkdir -p "$BASE_DIR/services/rag-service/app"
  cat > "$BASE_DIR/services/rag-service/app/main.py" << EOF
from fastapi import FastAPI
import os

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Welcome to RAG Service"}

@app.get("/health")
async def health():
    return {"status": "healthy"}
EOF

  # Create ui-chat streamlit_app.py
  cat > "$BASE_DIR/ui/chat/streamlit_app.py" << EOF
import streamlit as st

st.title("Alfred Chat Interface")

st.write("Welcome to the Alfred Agent Platform")

message = st.text_input("Enter your message:")
if st.button("Send"):
    st.write(f"You sent: {message}")
    st.write("Response: I'm a placeholder response")
EOF

  echo -e "${GREEN}Sample app files created!${NC}"
}

# Create sample prometheus.yml
function create_sample_prometheus() {
  echo -e "${YELLOW}Creating sample Prometheus configuration...${NC}"

  cat > "$BASE_DIR/monitoring/prometheus/prometheus.yml" << EOF
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['monitoring-node:9100']

  - job_name: 'postgres-exporter'
    static_configs:
      - targets: ['monitoring-db:9187']
EOF

  echo -e "${GREEN}Sample Prometheus configuration created!${NC}"
}

# Function to set up empty migration files
function create_sample_migrations() {
  echo -e "${YELLOW}Creating sample migration files...${NC}"

  cat > "$BASE_DIR/migrations/supabase/01_init.sql" << EOF
-- Initial database setup
CREATE SCHEMA IF NOT EXISTS public;

-- Create a basic users table
CREATE TABLE IF NOT EXISTS public.users (
    id SERIAL PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Basic permissions
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
EOF

  echo -e "${GREEN}Sample migrations created!${NC}"
}

# Main execution
echo -e "${YELLOW}This script will create the service directory structure and sample files for Alfred Agent Platform v2.${NC}"
read -p "Continue? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
  create_directories
  create_sample_dockerfiles
  create_sample_requirements
  create_sample_apps
  create_sample_prometheus
  create_sample_migrations

  echo -e "\n${GREEN}Service setup complete!${NC}"
  echo -e "${YELLOW}Next steps:${NC}"
  echo -e "1. Review the sample files and replace with your actual service implementations"
  echo -e "2. Update the .env file with your environment variables"
  echo -e "3. Start services with: ./alfred.sh start --components=core"
  echo -e "\n${BLUE}See SERVICE_IMPLEMENTATION_PLAN.md for detailed instructions${NC}"
else
  echo -e "${RED}Setup cancelled${NC}"
  exit 1
fi
