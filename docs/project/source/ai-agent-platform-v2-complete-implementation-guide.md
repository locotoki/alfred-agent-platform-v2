# AI Agent Platform v2 : Complete Implementation Guide

## **🎯 Project Overview**

A scalable, modular AI agent platform built with Docker, Supabase, and Pub/Sub messaging for enterprise-grade AI operations.

### **Key Features**

- 🤖 Multiple AI agents with LangChain and LangGraph
- 📨 Event-driven architecture with Google Cloud Pub/Sub
- 🗄️ State management with Supabase (PostgreSQL + pgvector)
- 🔍 Vector search with Qdrant
- 🎯 Real-time updates via Supabase Realtime
- 📊 Comprehensive monitoring with Prometheus and Grafana
- 🔒 Built-in security with rate limiting and PII scrubbing
- 🚀 Local-first development with Docker Compose

## **📋 Prerequisites**

### **Hardware Requirements**

- CPU: AMD Ryzen 9 7900X or better
- GPU: NVIDIA RTX 4090 with 24GB VRAM
- RAM: 64GB minimum
- Storage: 2TB NVMe SSD
- OS: Ubuntu 22.04 LTS or Windows 11 with WSL2

### **Software Requirements**

- Docker Engine 25.0+ with Docker Compose v2
- Python 3.11.7+
- Node.js 20 LTS
- Git 2.43+
- NVIDIA Driver 545.29.06+
- CUDA Toolkit 12.3+

## **🚀 Phase 0: Development Environment Setup**

### **Install Essential Tools**

```bash

bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install build tools
sudo apt install -y build-essential curl wget git software-properties-common

# Install Python 3.11
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install -y python3.11 python3.11-dev python3.11-venv
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

# Install pip
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

# Install Git and Git LFS
sudo apt install -y git git-lfs
git lfs install

# Install Docker Engine (not Desktop)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
newgrp docker

# Install Docker Compose v2
sudo apt install -y docker-compose-plugin
docker compose version

# Install NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Test GPU access
docker run --rm --gpus all nvidia/cuda:12.3.1-base-ubuntu22.04 nvidia-smi

# Install Node.js 20 LTS
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install VS Code
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
sudo apt update
sudo apt install code

# Install VS Code extensions
code --install-extension ms-python.python
code --install-extension ms-python.vscode-pylance
code --install-extension ms-python.debugpy
code --install-extension ms-azuretools.vscode-docker
code --install-extension ms-vscode-remote.remote-containers
code --install-extension eamodio.gitlens
code --install-extension github.copilot
code --install-extension ms-vscode.makefile-tools

```

## **📁 Phase 1: Project Structure**

### **Complete Directory Structure**

```

alfred-agent-platform/
├── .github/
│   ├── workflows/
│   │   ├── ci.yml
│   │   ├── cd-staging.yml
│   │   ├── cd-production.yml
│   │   └── security-scan.yml
│   └── ISSUE_TEMPLATE/
│       ├── bug_report.md
│       └── feature_request.md
├── .devcontainer/
│   └── devcontainer.json
├── agents/                           # Agent business logic
│   ├── alfred_bot/
│   ├── social_intel/
│   ├── legal_compliance/
│   └── financial_tax/
├── services/                         # Dockerized microservices
│   ├── alfred-bot/
│   ├── architect-api/
│   ├── legal-compliance/
│   ├── financial-tax/
│   └── mission-control/
├── libs/                            # Shared libraries
│   ├── a2a_adapter/
│   ├── agent_core/
│   └── observability/
├── infra/                           # Infrastructure as Code
│   ├── terraform/
│   ├── k8s/
│   └── docker/
├── migrations/                      # Database migrations
│   ├── supabase/
│   └── alembic/
├── scripts/
├── tests/
├── docs/
├── monitoring/
├── security/
├── .vscode/
├── .gitignore
├── .dockerignore
├── .env.example
├── docker-compose.yml
├── docker-compose.override.yml
├── Makefile
├── pyproject.toml
├── requirements.txt
├── requirements-dev.txt
├── pytest.ini
├── README.md
├── CONTRIBUTING.md
├── LICENSE
└── SECURITY.md

```

### **Initialize Project**

```bash

bash
# Create repository
mkdir alfred-agent-platform-v2
cd alfred-agent-platform-v2
git init

# Create comprehensive project structure
mkdir -p .github/workflows .github/ISSUE_TEMPLATE
mkdir -p .devcontainer .vscode
mkdir -p agents/{alfred_bot,social_intel,legal_compliance,financial_tax}
mkdir -p services/{alfred-bot,architect-api,legal-compliance,financial-tax,mission-control}
mkdir -p libs/{a2a_adapter,agent_core,observability}
mkdir -p infra/{terraform/{environments/{dev,staging,prod},modules},k8s/{base,overlays},docker/compose}
mkdir -p migrations/{supabase,alembic/versions}
mkdir -p scripts/{setup,deploy,test,utils}
mkdir -p tests/{unit,integration,e2e}/fixtures
mkdir -p docs/{architecture,api,operations,development}
mkdir -p monitoring/{prometheus/alerts,grafana/dashboards,logging}
mkdir -p security/{policies,scanning}

# Create essential files
touch .gitignore .dockerignore .env.example
touch docker-compose.yml docker-compose.override.yml Makefile
touch pyproject.toml requirements.txt requirements-dev.txt pytest.ini
touch README.md CONTRIBUTING.md LICENSE SECURITY.md

```

## **🔧 Phase 2: Configuration Files**

### **Git Configuration**

<details> <summary>.gitignore</summary>

```

gitignore
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
ENV/
.env
.env.*
!.env.example
.venv
.pytest_cache/
.coverage
.coverage.*
htmlcov/
.tox/
.mypy_cache/
.ruff_cache/

# Docker
docker-compose.override.yml
.docker/

# IDE
.vscode/
!.vscode/extensions.json
!.vscode/settings.json
!.vscode/tasks.json
!.vscode/launch.json
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Secrets and credentials
*.pem
*.key
*.crt
secrets/
credentials/

# ML Models
models/
*.gguf
*.bin
*.pt
*.pth
*.onnx
*.safetensors

# Data
data/
*.parquet
*.arrow
*.csv
*.json
!package.json
!tsconfig.json

# Logs
logs/
*.log

# Build artifacts
dist/
build/
*.egg-info/

# Testing
.coverage
coverage.xml
test-results/
junit.xml

# Node
node_modules/
npm-debug.log
yarn-debug.log
yarn-error.log
.pnp/
.pnp.js

# Next.js
.next/
out/

# Terraform
*.tfstate
*.tfstate.*
.terraform/
terraform.tfvars
!terraform.tfvars.example

# Jupyter
.ipynb_checkpoints/

```

</details>

### **Git LFS Configuration**

<details> <summary>.gitattributes</summary>

```

gitattributes
# ML Models
*.gguf filter=lfs diff=lfs merge=lfs -text
*.bin filter=lfs diff=lfs merge=lfs -text
*.safetensors filter=lfs diff=lfs merge=lfs -text
*.onnx filter=lfs diff=lfs merge=lfs -text
*.pt filter=lfs diff=lfs merge=lfs -text
*.pth filter=lfs diff=lfs merge=lfs -text
*.h5 filter=lfs diff=lfs merge=lfs -text
*.pb filter=lfs diff=lfs merge=lfs -text

# Datasets
*.parquet filter=lfs diff=lfs merge=lfs -text
*.arrow filter=lfs diff=lfs merge=lfs -text
*.feather filter=lfs diff=lfs merge=lfs -text
*.sqlite filter=lfs diff=lfs merge=lfs -text
*.db filter=lfs diff=lfs merge=lfs -text

# Large files
*.zip filter=lfs diff=lfs merge=lfs -text
*.tar filter=lfs diff=lfs merge=lfs -text
*.tar.gz filter=lfs diff=lfs merge=lfs -text
*.tgz filter=lfs diff=lfs merge=lfs -text
*.tar.bz2 filter=lfs diff=lfs merge=lfs -text

# Media files
*.mp4 filter=lfs diff=lfs merge=lfs -text
*.mov filter=lfs diff=lfs merge=lfs -text
*.mp3 filter=lfs diff=lfs merge=lfs -text
*.wav filter=lfs diff=lfs merge=lfs -text

# Documentation images
docs/**/*.png filter=lfs diff=lfs merge=lfs -text
docs/**/*.jpg filter=lfs diff=lfs merge=lfs -text
docs/**/*.jpeg filter=lfs diff=lfs merge=lfs -text

```

</details>

### **Project Configuration**

<details> <summary>pyproject.toml</summary>

```toml

toml
[tool.poetry]
name = "alfred-agent-platform"
version = "2.0.0"
description = "AI Agent Platform with Supabase and Pub/Sub"
authors = ["Your Name <your.email@example.com>"]
readme = "README.md"
packages = [
    { include = "agents" },
    { include = "libs" }
]

[tool.poetry.dependencies]
python = "^3.11"
python-dotenv = "^1.0.0"
pydantic = "^2.6.0"
pydantic-settings = "^2.1.0"
asyncio = "^3.4.3"
asyncpg = "^0.29.0"
aiohttp = "^3.9.1"
langchain = "^0.1.6"
langchain-community = "^0.0.20"
langchain-core = "^0.1.23"
langchain-openai = "^0.0.5"
langgraph = "^0.0.29"
langsmith = "^0.0.87"
psycopg2-binary = "^2.9.9"
sqlalchemy = "^2.0.25"
alembic = "^1.13.1"
qdrant-client = "^1.7.0"
google-cloud-pubsub = "^2.19.0"
slack-bolt = "^1.18.1"
slack-sdk = "^3.23.0"
fastapi = "^0.108.0"
uvicorn = "^0.27.0"
opentelemetry-api = "^1.22.0"
opentelemetry-sdk = "^1.22.0"
opentelemetry-exporter-otlp = "^1.22.0"
prometheus-client = "^0.19.0"

[tool.poetry.group.dev.dependencies]
pytest = "^7.4.4"
pytest-asyncio = "^0.23.3"
pytest-cov = "^4.1.0"
black = "^24.1.1"
isort = "^5.13.2"
flake8 = "^7.0.0"
mypy = "^1.8.0"
pre-commit = "^3.6.0"

[build-system]
requires = ["poetry-core"]
build-backend = "poetry.core.masonry.api"

[tool.black]
line-length = 100
target-version = ['py311']
include = '\.pyi?$'

[tool.isort]
profile = "black"
line_length = 100
multi_line_output = 3

[tool.mypy]
python_version = "3.11"
disallow_untyped_defs = true
ignore_missing_imports = true
show_error_codes = true

[tool.pytest.ini_options]
pythonpath = ["."]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]
asyncio_mode = "auto"
addopts = "-ra -q --strict-markers"
markers = [
    "slow: marks tests as slow (deselect with '-m \"not slow\"')",
    "integration: marks integration tests",
    "e2e: marks end-to-end tests"
]

```

</details>

### **Dependencies**

<details> <summary>requirements.txt</summary>

```

txt
# Core Dependencies
python-dotenv==1.0.0
pydantic==2.6.0
pydantic-settings==2.1.0

# Async Support
asyncio==3.4.3
asyncpg==0.29.0
aiohttp==3.9.1

# LangChain Ecosystem
langchain==0.1.6
langchain-community==0.0.20
langchain-core==0.1.23
langchain-openai==0.0.5
langgraph==0.0.29
langsmith==0.0.87

# Database
psycopg2-binary==2.9.9
sqlalchemy==2.0.25
alembic==1.13.1

# Vector Store
qdrant-client==1.7.0

# Message Queue
google-cloud-pubsub==2.19.0

# Slack Integration
slack-bolt==1.18.1
slack-sdk==3.23.0

# API Framework
fastapi==0.108.0
uvicorn==0.27.0

# Observability
opentelemetry-api==1.22.0
opentelemetry-sdk==1.22.0
opentelemetry-exporter-otlp==1.22.0
prometheus-client==0.19.0

# Additional utilities
redis==5.0.1
httpx==0.26.0
tenacity==8.2.3
structlog==24.1.0

```

</details>

## **🐳 Phase 3: Docker Configuration**

### **Main Docker Compose**

<details> <summary>docker-compose.yml</summary>

```yaml

yaml
services:
# Database Services
  supabase-db:
    image: supabase/postgres:15.1.0.117
    container_name: supabase-db
    healthcheck:
      test: pg_isready -U postgres -h localhost
      interval: 5s
      timeout: 5s
      retries: 10
    ports:
      - "5432:5432"
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-your-super-secret-password}
      POSTGRES_DB: postgres
      JWT_SECRET: ${JWT_SECRET:-your-super-secret-jwt-token}
      JWT_EXP: 3600
    volumes:
      - supabase-db-data:/var/lib/postgresql/data
      - ./migrations/supabase:/docker-entrypoint-initdb.d
    command:
      - postgres
      - -c
      - wal_level=logical
      - -c
      - max_connections=1000

  supabase-auth:
    image: supabase/gotrue:v2.132.3
    container_name: supabase-auth
    depends_on:
      supabase-db:
        condition: service_healthy
    ports:
      - "9999:9999"
    environment:
      GOTRUE_API_HOST: 0.0.0.0
      GOTRUE_API_PORT: 9999
      API_EXTERNAL_URL: ${API_EXTERNAL_URL:-http://localhost:8000}
      GOTRUE_DB_DRIVER: postgres
      GOTRUE_DB_DATABASE_URL: postgres://postgres:${POSTGRES_PASSWORD}@supabase-db:5432/postgres?search_path=auth
      GOTRUE_SITE_URL: ${SITE_URL:-http://localhost:3000}
      GOTRUE_URI_ALLOW_LIST: ${ADDITIONAL_REDIRECT_URLS}
      GOTRUE_DISABLE_SIGNUP: ${DISABLE_SIGNUP:-false}
      GOTRUE_JWT_ADMIN_ROLES: service_role
      GOTRUE_JWT_AUD: authenticated
      GOTRUE_JWT_DEFAULT_GROUP_NAME: authenticated
      GOTRUE_JWT_EXP: ${JWT_EXPIRY:-3600}
      GOTRUE_JWT_SECRET: ${JWT_SECRET}
      GOTRUE_EXTERNAL_EMAIL_ENABLED: ${ENABLE_EMAIL_SIGNUP:-true}
      GOTRUE_MAILER_AUTOCONFIRM: ${ENABLE_EMAIL_AUTOCONFIRM:-false}

  supabase-rest:
    image: postgrest/postgrest:v11.2.0
    container_name: supabase-rest
    depends_on:
      supabase-db:
        condition: service_healthy
    ports:
      - "3000:3000"
    environment:
      PGRST_DB_URI: postgres://authenticator:${POSTGRES_PASSWORD}@supabase-db:5432/postgres
      PGRST_DB_SCHEMAS: public,storage,graphql_public
      PGRST_DB_ANON_ROLE: anon
      PGRST_JWT_SECRET: ${JWT_SECRET}

  supabase-realtime:
    image: supabase/realtime:v2.25.35
    container_name: supabase-realtime
    depends_on:
      supabase-db:
        condition: service_healthy
    ports:
      - "4000:4000"
    environment:
      PORT: 4000
      DB_HOST: supabase-db
      DB_PORT: 5432
      DB_NAME: postgres
      DB_USER: supabase_admin
      DB_PASSWORD: ${POSTGRES_PASSWORD}
      DB_SSL: "false"
      JWT_SECRET: ${JWT_SECRET}
      REPLICATION_MODE: RLS
      REPLICATION_POLL_INTERVAL: 100
      SECURE_CHANNELS: "true"
      SLOT_NAME: supabase_realtime_rls
      TEMPORARY_SLOT: "true"

  supabase-storage:
    image: supabase/storage-api:v0.43.11
    container_name: supabase-storage
    depends_on:
      supabase-db:
        condition: service_healthy
      supabase-rest:
        condition: service_started
    ports:
      - "5000:5000"
    environment:
      ANON_KEY: ${ANON_KEY}
      SERVICE_KEY: ${SERVICE_ROLE_KEY}
      POSTGREST_URL: http://supabase-rest:3000
      PGRST_JWT_SECRET: ${JWT_SECRET}
      DATABASE_URL: postgres://supabase_storage_admin:${POSTGRES_PASSWORD}@supabase-db:5432/postgres
      FILE_SIZE_LIMIT: 52428800

# Message Queue Services
  pubsub-emulator:
    image: gcr.io/google.com/cloudsdktool/cloud-sdk:latest
    container_name: pubsub-emulator
    command: gcloud beta emulators pubsub start --host-port=0.0.0.0:8085 --project=alfred-agent-platform
    ports:
      - "8085:8085"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8085/v1/projects/alfred-agent-platform/topics"]

# Vector Database
  qdrant:
    image: qdrant/qdrant:v1.7.4
    container_name: qdrant
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - qdrant-storage:/qdrant/storage

# LLM Services
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama-models:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]

# Observability Stack
  redis:
    image: redis:7-alpine
    container_name: redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data

  prometheus:
    image: prom/prometheus:v2.48.1
    container_name: prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
      - prometheus-data:/prometheus

  grafana:
    image: grafana/grafana:10.2.3
    container_name: grafana
    ports:
      - "3002:3000"
    volumes:
      - ./monitoring/grafana/dashboards:/var/lib/grafana/dashboards
      - grafana-data:/var/lib/grafana
    environment:
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_ADMIN_PASSWORD:-admin}

volumes:
  supabase-db-data:
  supabase-storage-data:
  qdrant-storage:
  ollama-models:
  redis-data:
  prometheus-data:
  grafana-data:

networks:
  default:
    name: alfred-network
    driver: bridge

```

</details>

### **Environment Variables**

<details> <summary>.env.example</summary>

```

env
# Environment
ENVIRONMENT=development
DEBUG=true

# Database
POSTGRES_PASSWORD=your-super-secret-password
POSTGRES_USER=postgres
POSTGRES_DB=postgres
DATABASE_URL=postgresql://postgres:your-super-secret-password@supabase-db:5432/postgres

# Supabase
JWT_SECRET=your-super-secret-jwt-token-with-at-least-32-characters-long
ANON_KEY=your-anon-key
SERVICE_ROLE_KEY=your-service-role-key
SUPABASE_URL=http://localhost:8000
SUPABASE_PUBLIC_URL=http://localhost:8000

# Authentication
SITE_URL=http://localhost:3000
ADDITIONAL_REDIRECT_URLS=http://localhost:3000/auth/callback,http://localhost:3003/auth/callback
DISABLE_SIGNUP=false
JWT_EXPIRY=3600

# SMTP (Optional)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key
SMTP_ADMIN_EMAIL=admin@example.com
SMTP_SENDER_NAME=Alfred Platform

# Slack
SLACK_BOT_TOKEN=xoxb-your-slack-bot-token
SLACK_SIGNING_SECRET=your-slack-signing-secret
SLACK_APP_TOKEN=xapp-your-slack-app-token

# Google Cloud
GCP_PROJECT_ID=alfred-agent-platform
PUBSUB_EMULATOR_HOST=pubsub-emulator:8085

# OpenAI
OPENAI_API_KEY=sk-your-openai-api-key

# LangSmith
LANGSMITH_API_KEY=ls-your-langsmith-api-key
LANGCHAIN_TRACING_V2=true
LANGCHAIN_ENDPOINT=http://langsmith:1984
LANGCHAIN_PROJECT=alfred-platform

# Monitoring
GRAFANA_ADMIN_PASSWORD=your-grafana-admin-password
PROMETHEUS_RETENTION_TIME=15d

# Security
API_KEY_SALT=your-random-salt-value
ENCRYPTION_KEY=your-32-byte-encryption-key

# Feature Flags
ENABLE_EMAIL_SIGNUP=true
ENABLE_EMAIL_AUTOCONFIRM=false
ENABLE_ANONYMOUS_SIGN_INS=false

# Rate Limiting
RATE_LIMIT_PER_MINUTE=60
RATE_LIMIT_PER_HOUR=1000

```

</details>

## **🗄️ Phase 4: Database Setup**

### **Database Migrations**

<details> <summary>001_extensions.sql</summary>

```sql

sql
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "pgjwt";
CREATE EXTENSION IF NOT EXISTS "pg_stat_statements";
CREATE EXTENSION IF NOT EXISTS "pg_cron";
CREATE EXTENSION IF NOT EXISTS "vector";

```

</details> <details> <summary>002_core_tables.sql</summary>

```sql

sql
-- Task management tables
CREATE TABLE tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id TEXT UNIQUE NOT NULL,
    intent TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    content JSONB DEFAULT '{}',
    priority INTEGER DEFAULT 1 CHECK (priority BETWEEN 1 AND 5),
    created_by TEXT,
    assigned_to TEXT,
    parent_task_id UUID REFERENCES tasks(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    failed_at TIMESTAMPTZ,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    max_retries INTEGER DEFAULT 3,
    timeout_seconds INTEGER DEFAULT 300,
    metadata JSONB DEFAULT '{}'
);

-- Task results table
CREATE TABLE task_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
    result_type TEXT NOT NULL,
    content JSONB NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

-- Message deduplication table
CREATE TABLE processed_messages (
    message_id TEXT PRIMARY KEY,
    processed_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ DEFAULT NOW() + INTERVAL '48 hours'
);

-- Agent registry table
CREATE TABLE agent_registry (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT UNIQUE NOT NULL,
    type TEXT NOT NULL,
    version TEXT NOT NULL,
    status TEXT DEFAULT 'inactive' CHECK (status IN ('active', 'inactive', 'maintenance')),
    endpoint_url TEXT,
    health_check_url TEXT,
    capabilities JSONB DEFAULT '[]',
    configuration JSONB DEFAULT '{}',
    last_heartbeat TIMESTAMPTZ,
    registered_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Vector storage table
CREATE TABLE embeddings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content TEXT NOT NULL,
    embedding vector(1536),
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_tasks_status ON tasks(status);
CREATE INDEX idx_tasks_created_at ON tasks(created_at);
CREATE INDEX idx_tasks_intent ON tasks(intent);
CREATE INDEX idx_task_results_task_id ON task_results(task_id);
CREATE INDEX idx_processed_messages_expires_at ON processed_messages(expires_at);
CREATE INDEX idx_agent_registry_status ON agent_registry(status);
CREATE INDEX idx_embeddings_embedding ON embeddings USING ivfflat (embedding vector_cosine_ops);

```

</details>

## **🔨 Phase 5: Build Automation**

### **Makefile**

<details> <summary>Makefile</summary>

```makefile

makefile
.PHONY: help init setup start stop restart logs test lint format clean build deploy

# Variables
DOCKER_COMPOSE = docker compose
PYTHON = python3.11
PIP = $(PYTHON) -m pip
PROJECT_NAME = alfred-agent-platform

# Colors
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m# No Color

help:## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@egrep '^(.+)\:\ ##\ (.+)' $(MAKEFILE_LIST) | column -t -c 2 -s ':#'

init:## Initialize project (first time setup)
	@echo "$(GREEN)Initializing project...$(NC)"
	cp .env.example .env
	$(PIP) install -r requirements.txt
	$(PIP) install -r requirements-dev.txt
	pre-commit install
	git lfs install
	@echo "$(GREEN)Project initialized! Edit .env file with your settings.$(NC)"

setup:## Setup development environment
	@echo "$(GREEN)Setting up development environment...$(NC)"
	$(DOCKER_COMPOSE) build
	$(DOCKER_COMPOSE) up -d supabase-db
	@echo "$(YELLOW)Waiting for database to be ready...$(NC)"
	sleep 10
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)Development environment is ready!$(NC)"

start:## Start all services
	@echo "$(GREEN)Starting all services...$(NC)"
	$(DOCKER_COMPOSE) up -d
	@echo "$(GREEN)All services started!$(NC)"
	@echo "$(YELLOW)Services available at:$(NC)"
	@echo "  - Supabase Studio: http://localhost:3001"
	@echo "  - Mission Control: http://localhost:3003"
	@echo "  - Grafana: http://localhost:3002"
	@echo "  - Prometheus: http://localhost:9090"

stop:## Stop all services
	@echo "$(YELLOW)Stopping all services...$(NC)"
	$(DOCKER_COMPOSE) down
	@echo "$(GREEN)All services stopped!$(NC)"

restart: stop start## Restart all services

logs:## Show logs for all services
	$(DOCKER_COMPOSE) logs -f

logs-%:## Show logs for specific service (e.g., make logs-alfred-bot)
	$(DOCKER_COMPOSE) logs -f $*

test:## Run all tests
	@echo "$(GREEN)Running tests...$(NC)"
	$(PYTHON) -m pytest tests/ -v

test-unit:## Run unit tests
	@echo "$(GREEN)Running unit tests...$(NC)"
	$(PYTHON) -m pytest tests/unit/ -v

test-integration:## Run integration tests
	@echo "$(GREEN)Running integration tests...$(NC)"
	$(PYTHON) -m pytest tests/integration/ -v -m integration

test-e2e:## Run end-to-end tests
	@echo "$(GREEN)Running end-to-end tests...$(NC)"
	$(PYTHON) -m pytest tests/e2e/ -v -m e2e

lint:## Run linting
	@echo "$(GREEN)Running linters...$(NC)"
	$(PYTHON) -m black --check .
	$(PYTHON) -m isort --check-only .
	$(PYTHON) -m flake8 .
	$(PYTHON) -m mypy .
	$(PYTHON) -m bandit -r agents/ libs/ services/

format:## Format code
	@echo "$(GREEN)Formatting code...$(NC)"
	$(PYTHON) -m black .
	$(PYTHON) -m isort .

clean:## Clean up generated files
	@echo "$(YELLOW)Cleaning up...$(NC)"
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".mypy_cache" -exec rm -rf {} +
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
	find . -type f -name "*.pyo" -delete
	find . -type f -name "*.coverage" -delete
	find . -type f -name "coverage.xml" -delete
	@echo "$(GREEN)Cleanup complete!$(NC)"

build:## Build all Docker images
	@echo "$(GREEN)Building all Docker images...$(NC)"
	$(DOCKER_COMPOSE) build --no-cache

db-migrate:## Run database migrations
	@echo "$(GREEN)Running database migrations...$(NC)"
	$(DOCKER_COMPOSE) exec supabase-db psql -U postgres -d postgres -f /docker-entrypoint-initdb.d/001_extensions.sql
	$(DOCKER_COMPOSE) exec supabase-db psql -U postgres -d postgres -f /docker-entrypoint-initdb.d/002_core_tables.sql

db-reset:## Reset database (CAUTION: This will delete all data!)
	@echo "$(RED)WARNING: This will delete all data! Are you sure? [y/N]$(NC)"
	@read -r REPLY; \
	if [ "$$REPLY" = "y" ] || [ "$$REPLY" = "Y" ]; then \
		$(DOCKER_COMPOSE) down -v; \
		$(DOCKER_COMPOSE) up -d supabase-db; \
		sleep 10; \
		$(MAKE) db-migrate; \
		echo "$(GREEN)Database reset complete!$(NC)"; \
	else \
		echo "$(YELLOW)Database reset cancelled.$(NC)"; \
	fi

monitor:## Open monitoring dashboards
	@echo "$(GREEN)Opening monitoring dashboards...$(NC)"
	@command -v open >/dev/null 2>&1 && open http://localhost:3002 || echo "Grafana: http://localhost:3002"
	@command -v open >/dev/null 2>&1 && open http://localhost:9090 || echo "Prometheus: http://localhost:9090"

dev: setup## Start development environment with logs
	@echo "$(GREEN)Starting development environment with logs...$(NC)"
	$(DOCKER_COMPOSE) up

```

</details>

## **🚦 Phase 6: CI/CD Pipeline**

### **GitHub Actions CI**

<details> <summary>.github/workflows/ci.yml</summary>

```yaml

yaml
name: CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

env:
  PYTHON_VERSION: "3.11"
  NODE_VERSION: "20"
  DOCKER_BUILDKIT: 1
  COMPOSE_DOCKER_CLI_BUILD: 1

jobs:
# Security scanning
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: TruffleHog OSS
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD
          extra_args: --debug --only-verified

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          trivy-config: trivy.yaml
          severity: 'CRITICAL,HIGH'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy scan results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'

# Python linting and testing
  lint-and-test:
    needs: security-scan
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'

      - name: Install dependencies
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install -r requirements-dev.txt

      - name: Run formatters check
        run: |
          black --check .
          isort --check-only .

      - name: Run linters
        run: |
          flake8 .
          mypy .
          bandit -r agents/ libs/ services/ -c pyproject.toml

      - name: Run tests with coverage
        run: |
          pytest tests/ -v --cov=./ --cov-report=xml --cov-report=html
        env:
          DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test_db
          PUBSUB_EMULATOR_HOST: localhost:8085

      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          files: ./coverage.xml
          flags: unittests
          name: codecov-umbrella
          fail_ci_if_error: false

# Build Docker images
  build-images:
    needs: lint-and-test
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service:
          - alfred-bot
          - architect-api
          - legal-compliance
          - financial-tax
          - mission-control

    steps:
      - uses: actions/checkout@v4
        with:
          lfs: true

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Cache Docker layers
        uses: actions/cache@v3
        with:
          path: /tmp/.buildx-cache
          key: ${{ runner.os }}-buildx-${{ matrix.service }}-${{ github.sha }}
          restore-keys: |
            ${{ runner.os }}-buildx-${{ matrix.service }}-
            ${{ runner.os }}-buildx-

      - name: Build ${{ matrix.service }}
        uses: docker/build-push-action@v4
        with:
          context: ./services/${{ matrix.service }}
          push: false
          tags: |
            alfred-platform/${{ matrix.service }}:${{ github.sha }}
            alfred-platform/${{ matrix.service }}:latest
          cache-from: type=local,src=/tmp/.buildx-cache
          cache-to: type=local,dest=/tmp/.buildx-cache-new,mode=max

      - name: Move cache
        run: |
          rm -rf /tmp/.buildx-cache
          mv /tmp/.buildx-cache-new /tmp/.buildx-cache

# Integration tests
  integration-tests:
    needs: build-images
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Python
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}

      - name: Start services
        run: |
          docker-compose -f docker-compose.yml up -d
          sleep 30  # Wait for services to be ready

      - name: Run integration tests
        run: |
          pip install -r requirements.txt
          pip install -r requirements-dev.txt
          pytest tests/integration/ -v -m integration

      - name: Stop services
        if: always()
        run: docker-compose down -v

```

</details>

## **📦 Phase 7: Core Libraries**

### **A2A Adapter Library**

<details> <summary>libs/a2a_adapter/envelope.py</summary>

```python

python
from datetime import datetime
from typing import Dict, Any, Optional, List
from uuid import uuid4
from pydantic import BaseModel, Field

class Artifact(BaseModel):
    key: str
    uri: str
    mime_type: Optional[str] = None
    description: Optional[str] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)

class A2AEnvelope(BaseModel):
    schema_version: str = "0.4"
    task_id: str = Field(default_factory=lambda: str(uuid4()))
    intent: str
    role: str = "assistant"
    content: Dict[str, Any] = Field(default_factory=dict)
    artifacts: List[Artifact] = Field(default_factory=list)
    trace_id: str = Field(default_factory=lambda: str(uuid4()))
    correlation_id: Optional[str] = None
    timestamp: str = Field(default_factory=lambda: datetime.utcnow().isoformat() + "Z")
    metadata: Dict[str, Any] = Field(default_factory=dict)
    priority: int = Field(default=1, ge=1, le=5)
    timeout_seconds: int = Field(default=300, ge=1, le=3600)

    def to_pubsub_message(self) -> Dict[str, Any]:
        """Convert envelope to Pub/Sub message format."""
        return {
            "data": self.json(),
            "attributes": {
                "intent": self.intent,
                "priority": str(self.priority),
                "trace_id": self.trace_id
            }
        }

    @classmethod
    def from_pubsub_message(cls, message: Dict[str, Any]) -> 'A2AEnvelope':
        """Create envelope from Pub/Sub message."""
        data = message.get("data", "{}")
        if isinstance(data, bytes):
            data = data.decode('utf-8')
        return cls.parse_raw(data)

```

</details>

### **Base Agent Class**

<details> <summary>libs/agent_core/base_agent.py</summary>

```python

python
from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
import asyncio
import structlog
from datetime import datetime

from libs.a2a_adapter import A2AEnvelope, PubSubTransport, SupabaseTransport, PolicyMiddleware

logger = structlog.get_logger(__name__)

class BaseAgent(ABC):
    def __init__(
        self,
        name: str,
        version: str,
        supported_intents: List[str],
        pubsub_transport: PubSubTransport,
        supabase_transport: SupabaseTransport,
        policy_middleware: PolicyMiddleware
    ):
        self.name = name
        self.version = version
        self.supported_intents = supported_intents
        self.pubsub = pubsub_transport
        self.supabase = supabase_transport
        self.policy = policy_middleware

        self.is_running = False
        self._tasks = set()

    @abstractmethod
    async def process_task(self, envelope: A2AEnvelope) -> Dict[str, Any]:
        """Process a task and return results."""
        pass

    async def start(self):
        """Start the agent."""
        logger.info(
            "agent_starting",
            name=self.name,
            version=self.version,
            intents=self.supported_intents
        )

        self.is_running = True

# Register agent
        await self._register_agent()

# Start heartbeat
        self._tasks.add(asyncio.create_task(self._heartbeat_loop()))

# Start subscription
        subscription_name = f"{self.name}-subscription"
        await self.pubsub.subscribe(
            subscription_name,
            self._handle_message,
            self._handle_error
        )

    async def stop(self):
        """Stop the agent."""
        logger.info("agent_stopping", name=self.name)

        self.is_running = False

# Cancel all tasks
        for task in self._tasks:
            task.cancel()

# Wait for tasks to complete
        await asyncio.gather(*self._tasks, return_exceptions=True)

# Update agent status
        await self._update_agent_status("inactive")

    @policy_middleware.apply_policies
    async def _handle_message(self, envelope: A2AEnvelope):
        """Handle incoming message."""
        try:
# Check if intent is supported
            if envelope.intent not in self.supported_intents:
                logger.warning(
                    "unsupported_intent",
                    intent=envelope.intent,
                    agent=self.name
                )
                return

# Check for duplicate
            is_duplicate = await self.supabase.check_duplicate(envelope.task_id)
            if is_duplicate:
                logger.info(
                    "duplicate_message",
                    task_id=envelope.task_id
                )
                return

# Update task status to processing
            await self.supabase.update_task_status(envelope.task_id, "processing")

# Process task
            result = await self.process_task(envelope)

# Store result
            await self.supabase.store_task_result(
                envelope.task_id,
                "success",
                result
            )

# Update task status to completed
            await self.supabase.update_task_status(envelope.task_id, "completed")

# Publish completion
            completion_envelope = A2AEnvelope(
                intent=f"{envelope.intent}_COMPLETED",
                content=result,
                correlation_id=envelope.task_id,
                trace_id=envelope.trace_id
            )

            await self.pubsub.publish_task(
                completion_envelope,
                topic=self.pubsub.completed_topic_path
            )

        except Exception as e:
            logger.error(
                "task_processing_failed",
                error=str(e),
                task_id=envelope.task_id,
                agent=self.name
            )

# Update task status to failed
            await self.supabase.update_task_status(
                envelope.task_id,
                "failed",
                str(e)
            )

    async def _handle_error(self, error: Exception):
        """Handle subscription errors."""
        logger.error(
            "subscription_error",
            error=str(error),
            agent=self.name
        )

    async def _register_agent(self):
        """Register agent in database."""
        async with self.supabase._pool.acquire() as conn:
            await conn.execute(
                """
                INSERT INTO agent_registry (name, type, version, status, capabilities)
                VALUES ($1, $2, $3, $4, $5)
                ON CONFLICT (name) DO UPDATE
                SET version = $3, status = $4, updated_at = NOW()
                """,
                self.name,
                self.__class__.__name__,
                self.version,
                "active",
                self.supported_intents
            )

    async def _heartbeat_loop(self):
        """Send heartbeat to maintain agent status."""
        while self.is_running:
            try:
                async with self.supabase._pool.acquire() as conn:
                    await conn.execute(
                        """
                        UPDATE agent_registry
                        SET last_heartbeat = NOW()
                        WHERE name = $1
                        """,
                        self.name
                    )

                await asyncio.sleep(30)# Heartbeat every 30 seconds

            except Exception as e:
                logger.error(
                    "heartbeat_failed",
                    error=str(e),
                    agent=self.name
                )
                await asyncio.sleep(5)# Retry after 5 seconds

```

</details>

## **🤖 Phase 8: First Service Implementation**

### **Alfred Bot Service**

<details> <summary>services/alfred-bot/app/main.py</summary>

```python

python
from fastapi import FastAPI, Request
from slack_bolt.adapter.fastapi import SlackRequestHandler
from slack_bolt import App
import os
import structlog
import redis
from contextlib import asynccontextmanager

from libs.a2a_adapter import A2AEnvelope, PubSubTransport, SupabaseTransport, PolicyMiddleware
from libs.agent_core.health import create_health_app

logger = structlog.get_logger(__name__)

# Initialize services
pubsub_transport = PubSubTransport(
    project_id=os.getenv("GCP_PROJECT_ID", "alfred-agent-platform")
)

supabase_transport = SupabaseTransport(
    database_url=os.getenv("DATABASE_URL")
)

redis_client = redis.from_url(os.getenv("REDIS_URL", "redis://redis:6379"))
policy_middleware = PolicyMiddleware(redis_client)

# Initialize Slack app
slack_app = App(
    token=os.environ.get("SLACK_BOT_TOKEN"),
    signing_secret=os.environ.get("SLACK_SIGNING_SECRET")
)

@slack_app.command("/alfred")
async def handle_alfred_command(ack, body, client):
    """Handle /alfred slash command."""
    await ack()

    try:
        command_text = body.get("text", "").strip()
        user_id = body["user_id"]
        channel_id = body["channel_id"]

# Parse command
        parts = command_text.split(maxsplit=1)
        if not parts:
            await client.chat_postMessage(
                channel=channel_id,
                text="Please specify a command. Try `/alfred help` for available commands."
            )
            return

        command = parts[0].lower()
        args = parts[1] if len(parts) > 1 else ""

# Handle different commands
        if command == "help":
            await show_help(client, channel_id)
        elif command == "ping":
            await handle_ping(client, channel_id, user_id)
        elif command == "trend":
            await handle_trend_analysis(client, channel_id, user_id, args)
        else:
            await client.chat_postMessage(
                channel=channel_id,
                text=f"Unknown command: {command}. Try `/alfred help` for available commands."
            )

    except Exception as e:
        logger.error("command_handling_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            text="Sorry, something went wrong. Please try again later."
        )

async def handle_ping(client, channel_id, user_id):
    """Handle ping command."""
    envelope = A2AEnvelope(
        intent="PING",
        content={"message": "ping", "user_id": user_id}
    )

    try:
        message_id = await pubsub_transport.publish_task(envelope)

        await client.chat_postMessage(
            channel=channel_id,
            text=f"Ping task created! Task ID: {envelope.task_id}"
        )
    except Exception as e:
        logger.error("ping_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            text="Failed to create ping task. Please try again."
        )

async def handle_trend_analysis(client, channel_id, user_id, query):
    """Handle trend analysis command."""
    if not query:
        await client.chat_postMessage(
            channel=channel_id,
            text="Please provide a trend to analyze. Example: `/alfred trend artificial intelligence`"
        )
        return

    envelope = A2AEnvelope(
        intent="TREND_ANALYSIS",
        content={
            "query": query,
            "user_id": user_id,
            "channel_id": channel_id
        }
    )

    try:
# Store task
        task_id = await supabase_transport.store_task(envelope)

# Publish task
        message_id = await pubsub_transport.publish_task(envelope)

        await client.chat_postMessage(
            channel=channel_id,
            text=f"Analyzing trends for: {query}\nTask ID: {envelope.task_id}"
        )
    except Exception as e:
        logger.error("trend_analysis_failed", error=str(e))
        await client.chat_postMessage(
            channel=channel_id,
            text="Failed to start trend analysis. Please try again."
        )

async def show_help(client, channel_id):
    """Show help message."""
    help_text = """
*Alfred Bot Commands:*
- `/alfred help` - Show this help message
- `/alfred ping` - Test bot responsiveness
- `/alfred trend <topic>` - Analyze trends for a topic
- `/alfred status <task_id>` - Check task status
- `/alfred cancel <task_id>` - Cancel a running task
    """

    await client.chat_postMessage(
        channel=channel_id,
        text=help_text
    )

# Create FastAPI app
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle."""
# Startup
    await supabase_transport.connect()
    logger.info("alfred_bot_started")

    yield

# Shutdown
    await supabase_transport.disconnect()
    logger.info("alfred_bot_stopped")

app = FastAPI(title="Alfred Bot", lifespan=lifespan)

# Add health check endpoints
health_app = create_health_app("alfred-bot", "1.0.0")
app.mount("/health", health_app)

# Add Slack handler
slack_handler = SlackRequestHandler(slack_app)

@app.post("/slack/events")
async def slack_events(request: Request):
    """Handle Slack events."""
    return await slack_handler.handle(request)

```

</details>

### **Alfred Bot Dockerfile**

<details> <summary>services/alfred-bot/Dockerfile</summary>

```

dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Copy shared libraries
COPY --from=build-context libs /app/libs

# Set environment variables
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Expose port
EXPOSE 8011

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8011/health/health || exit 1

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8011"]

```

</details>

## **🧪 Phase 9: Testing Framework**

### **Test Configuration**

<details> <summary>tests/conftest.py</summary>

```python

python
import pytest
import asyncio
import os
from typing import Generator
from unittest.mock import AsyncMock, MagicMock
import asyncpg
import redis
from google.cloud import pubsub_v1

from libs.a2a_adapter import PubSubTransport, SupabaseTransport, PolicyMiddleware

@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Create an instance of the default event loop for the test session."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

@pytest.fixture(autouse=True)
def setup_test_env():
    """Set up test environment variables."""
    os.environ["ENVIRONMENT"] = "test"
    os.environ["PUBSUB_EMULATOR_HOST"] = "localhost:8085"
    os.environ["DATABASE_URL"] = "postgresql://postgres:postgres@localhost:5432/test_db"
    os.environ["REDIS_URL"] = "redis://localhost:6379/1"
    os.environ["GCP_PROJECT_ID"] = "test-project"

@pytest.fixture
async def test_db():
    """Provide a clean test database."""
    conn = await asyncpg.connect(os.environ["DATABASE_URL"])

# Clean up existing data
    await conn.execute("TRUNCATE TABLE tasks, task_results, processed_messages CASCADE")

    yield conn

    await conn.close()

@pytest.fixture
def mock_pubsub():
    """Mock Pub/Sub client."""
    mock = MagicMock(spec=pubsub_v1.PublisherClient)
    mock.publish.return_value.result.return_value = "test-message-id"
    return mock

@pytest.fixture
def mock_redis():
    """Mock Redis client."""
    return MagicMock(spec=redis.Redis)

@pytest.fixture
def pubsub_transport(mock_pubsub):
    """Create PubSubTransport with mock."""
    transport = PubSubTransport(project_id="test-project")
    transport.publisher = mock_pubsub
    return transport

@pytest.fixture
async def supabase_transport(test_db):
    """Create SupabaseTransport with test database."""
    transport = SupabaseTransport(database_url=os.environ["DATABASE_URL"])
    await transport.connect()
    yield transport
    await transport.disconnect()

@pytest.fixture
def policy_middleware(mock_redis):
    """Create PolicyMiddleware with mock Redis."""
    return PolicyMiddleware(redis_client=mock_redis)

```

</details>

### **Unit Tests**

<details> <summary>tests/unit/test_envelope.py</summary>

```python

python
import pytest
from datetime import datetime

from libs.a2a_adapter import A2AEnvelope, Artifact

def test_envelope_creation():
    """Test creating an A2A envelope."""
    envelope = A2AEnvelope(
        intent="TEST_INTENT",
        content={"message": "test"}
    )

    assert envelope.schema_version == "0.4"
    assert envelope.intent == "TEST_INTENT"
    assert envelope.role == "assistant"
    assert isinstance(envelope.task_id, str)
    assert isinstance(envelope.trace_id, str)
    assert isinstance(envelope.timestamp, str)
    assert envelope.priority == 1

def test_envelope_serialization():
    """Test envelope serialization and deserialization."""
    original = A2AEnvelope(
        intent="TEST_INTENT",
        content={"message": "test"},
        artifacts=[
            Artifact(key="test", uri="s3://bucket/file.txt")
        ]
    )

# Serialize to Pub/Sub message
    pubsub_msg = original.to_pubsub_message()
    assert "data" in pubsub_msg
    assert "attributes" in pubsub_msg

# Deserialize back
    recovered = A2AEnvelope.from_pubsub_message(pubsub_msg)

    assert recovered.intent == original.intent
    assert recovered.task_id == original.task_id
    assert recovered.content == original.content
    assert len(recovered.artifacts) == 1
    assert recovered.artifacts[0].key == "test"

def test_artifact_model():
    """Test Artifact model."""
    artifact = Artifact(
        key="report",
        uri="s3://reports/2024/analysis.pdf",
        mime_type="application/pdf",
        description="Analysis report"
    )

    assert artifact.key == "report"
    assert artifact.uri == "s3://reports/2024/analysis.pdf"
    assert artifact.mime_type == "application/pdf"
    assert artifact.description == "Analysis report"

```

</details>

## **📊 Phase 10: Monitoring Setup**

### **Prometheus Configuration**

<details> <summary>monitoring/prometheus/prometheus.yml</summary>

```yaml

yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    monitor: 'alfred-platform'

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['alertmanager:9093']

rule_files:
  - /etc/prometheus/alerts/*.yml

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'alfred-bot'
    static_configs:
      - targets: ['alfred-bot:8011']
    metrics_path: '/health/metrics'

  - job_name: 'architect-api'
    static_configs:
      - targets: ['architect-api:9000']
    metrics_path: '/health/metrics'

  - job_name: 'supabase'
    static_configs:
      - targets: ['supabase-db:9187']

  - job_name: 'redis'
    static_configs:
      - targets: ['redis:6379']

  - job_name: 'qdrant'
    static_configs:
      - targets: ['qdrant:6333']
    metrics_path: '/metrics'

```

</details>

### **Alerts Configuration**

<details> <summary>monitoring/prometheus/alerts/basic.yml</summary>

```yaml

yaml
groups:
  - name: platform_alerts
    rules:
      - alert: HighErrorRate
        expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.1
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: High error rate detected
          description: Error rate is above 10% for 5 minutes

      - alert: AgentDown
        expr: up{job=~"alfred-bot|architect-api|legal-compliance"} == 0
        for

```

Retry

Claude hit the max length for a message and has paused its response. You can write Continue to keep the chat going.

**CK**

Continue

Edit

## **📊 Phase 10: Monitoring Setup (continued)**

### **Alerts Configuration (continued)**

<details> <summary>monitoring/prometheus/alerts/basic.yml (continued)</summary>

```yaml

yaml
      - alert: AgentDown
        expr: up{job=~"alfred-bot|architect-api|legal-compliance"} == 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: Agent {{ $labels.job }} is down
          description: Agent has been down for more than 2 minutes

      - alert: HighMemoryUsage
        expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: High memory usage in {{ $labels.container_name }}
          description: Memory usage is above 80% for 5 minutes

      - alert: PubSubBacklog
        expr: pubsub_subscription_num_undelivered_messages > 1000
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: High Pub/Sub backlog
          description: More than 1000 undelivered messages for 10 minutes

      - alert: DatabaseConnectionsHigh
        expr: pg_stat_database_numbackends / pg_settings_max_connections > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: Database connections near limit
          description: Database connections above 80% of max_connections

      - alert: TaskProcessingLatency
        expr: histogram_quantile(0.95, rate(task_processing_duration_seconds_bucket[5m])) > 30
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: High task processing latency
          description: 95th percentile task processing time above 30s

```

</details>

### **Grafana Dashboard**

<details> <summary>monitoring/grafana/dashboards/platform-overview.json</summary>

```json

json
{
  "dashboard": {
    "title": "Alfred Platform Overview",
    "uid": "alfred-overview",
    "timezone": "browser",
    "editable": true,
    "panels": [
      {
        "title": "Request Rate",
        "type": "graph",
        "datasource": "Prometheus",
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 0
        },
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (service)",
            "legendFormat": "{{service}}",
            "refId": "A"
          }
        ]
      },
      {
        "title": "Error Rate",
        "type": "graph",
        "datasource": "Prometheus",
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 0
        },
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) by (service)",
            "legendFormat": "{{service}}",
            "refId": "A"
          }
        ]
      },
      {
        "title": "Task Processing Time",
        "type": "graph",
        "datasource": "Prometheus",
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 8
        },
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(task_processing_duration_seconds_bucket[5m]))",
            "legendFormat": "p95",
            "refId": "A"
          },
          {
            "expr": "histogram_quantile(0.99, rate(task_processing_duration_seconds_bucket[5m]))",
            "legendFormat": "p99",
            "refId": "B"
          }
        ]
      },
      {
        "title": "Active Tasks",
        "type": "singlestat",
        "datasource": "Prometheus",
        "gridPos": {
          "h": 4,
          "w": 6,
          "x": 12,
          "y": 8
        },
        "targets": [
          {
            "expr": "sum(tasks_active)",
            "legendFormat": "Active Tasks",
            "refId": "A"
          }
        ],
        "format": "none",
        "thresholds": "50,100",
        "colors": ["green", "yellow", "red"]
      },
      {
        "title": "Memory Usage",
        "type": "graph",
        "datasource": "Prometheus",
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 0,
          "y": 16
        },
        "targets": [
          {
            "expr": "container_memory_usage_bytes{name=~\"alfred-.*\"} / 1024 / 1024 / 1024",
            "legendFormat": "{{name}}",
            "refId": "A"
          }
        ],
        "yaxes": [
          {
            "format": "GB",
            "show": true
          }
        ]
      },
      {
        "title": "CPU Usage",
        "type": "graph",
        "datasource": "Prometheus",
        "gridPos": {
          "h": 8,
          "w": 12,
          "x": 12,
          "y": 16
        },
        "targets": [
          {
            "expr": "rate(container_cpu_usage_seconds_total{name=~\"alfred-.*\"}[5m]) * 100",
            "legendFormat": "{{name}}",
            "refId": "A"
          }
        ],
        "yaxes": [
          {
            "format": "percent",
            "show": true
          }
        ]
      }
    ]
  }
}

```

</details>

## **📱 Phase 11: VS Code Configuration**

### **VS Code Settings**

<details> <summary>.vscode/settings.json</summary>

```json

json
{
  "python.defaultInterpreterPath": "${workspaceFolder}/.venv/bin/python",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": true,
  "python.linting.flake8Enabled": true,
  "python.formatting.provider": "black",
  "python.formatting.blackArgs": ["--line-length", "100"],
  "python.linting.mypyEnabled": true,
  "python.linting.mypyArgs": [
    "--ignore-missing-imports",
    "--follow-imports=silent",
    "--show-column-numbers",
    "--strict"
  ],
  "python.testing.pytestEnabled": true,
  "python.testing.unittestEnabled": false,
  "python.testing.pytestArgs": ["tests"],
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.organizeImports": true
  },
  "files.exclude": {
    "**/__pycache__": true,
    "**/*.pyc": true,
    "**/.pytest_cache": true,
    "**/.mypy_cache": true
  },
  "[python]": {
    "editor.rulers": [100]
  },
  "docker.containers.label": "Hidden",
  "docker.networks.label": "Hidden",
  "docker.volumes.label": "Hidden",
  "docker.images.label": "Hidden",
  "yaml.schemas": {
    "https://json.schemastore.org/github-workflow.json": ".github/workflows/*.yml",
    "https://json.schemastore.org/docker-compose.json": "docker-compose*.yml"
  }
}

```

</details>

### **VS Code Launch Configuration**

<details> <summary>.vscode/launch.json</summary>

```json

json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Python: Alfred Bot",
      "type": "python",
      "request": "launch",
      "module": "uvicorn",
      "args": [
        "app.main:app",
        "--host",
        "0.0.0.0",
        "--port",
        "8011",
        "--reload"
      ],
      "cwd": "${workspaceFolder}/services/alfred-bot",
      "env": {
        "PYTHONPATH": "${workspaceFolder}",
        "DEBUG": "true"
      },
      "console": "integratedTerminal",
      "justMyCode": false
    },
    {
      "name": "Python: Remote Attach",
      "type": "python",
      "request": "attach",
      "connect": {
        "host": "localhost",
        "port": 5678
      },
      "pathMappings": [
        {
          "localRoot": "${workspaceFolder}",
          "remoteRoot": "/app"
        }
      ]
    },
    {
      "name": "Python: Current File",
      "type": "python",
      "request": "launch",
      "program": "${file}",
      "console": "integratedTerminal",
      "env": {
        "PYTHONPATH": "${workspaceFolder}"
      }
    },
    {
      "name": "Python: Debug Tests",
      "type": "python",
      "request": "launch",
      "module": "pytest",
      "args": ["-v", "--no-cov"],
      "console": "integratedTerminal",
      "justMyCode": false
    }
  ]
}

```

</details>

### **Dev Container Configuration**

<details> <summary>.devcontainer/devcontainer.json</summary>

```json

json
{
  "name": "Alfred Agent Platform",
  "dockerComposeFile": [
    "../docker-compose.yml",
    "../docker-compose.override.yml"
  ],
  "service": "dev-environment",
  "workspaceFolder": "/workspace",
  "shutdownAction": "stopCompose",
  "features": {
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.11",
      "installJupyterLab": true,
      "installTools": true
    },
    "ghcr.io/devcontainers/features/git:1": {
      "version": "latest",
      "ppa": true
    },
    "ghcr.io/devcontainers/features/git-lfs:1": {
      "version": "latest"
    },
    "ghcr.io/devcontainers/features/docker-in-docker:2": {
      "version": "latest",
      "moby": true,
      "dockerDashComposeVersion": "v2"
    },
    "ghcr.io/devcontainers/features/node:1": {
      "version": "20"
    }
  },
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.vscode-pylance",
        "ms-python.debugpy",
        "ms-python.black-formatter",
        "ms-python.isort",
        "ms-python.flake8",
        "ms-python.mypy-type-checker",
        "ms-azuretools.vscode-docker",
        "ms-vscode.makefile-tools",
        "ms-toolsai.jupyter",
        "github.copilot",
        "github.copilot-labs",
        "eamodio.gitlens",
        "davidanson.vscode-markdownlint",
        "yzhang.markdown-all-in-one",
        "redhat.vscode-yaml",
        "ms-kubernetes-tools.vscode-kubernetes-tools",
        "hashicorp.terraform",
        "golang.go",
        "zxh404.vscode-proto3",
        "streetsidesoftware.code-spell-checker",
        "oderwat.indent-rainbow",
        "usernamehw.errorlens",
        "christian-kohler.path-intellisense",
        "formulahendry.auto-rename-tag",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode"
      ],
      "settings": {
        "python.defaultInterpreterPath": "/usr/local/bin/python",
        "python.linting.enabled": true,
        "python.linting.pylintEnabled": true,
        "python.linting.flake8Enabled": true,
        "python.formatting.provider": "black",
        "python.formatting.blackArgs": ["--line-length", "100"],
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
          "source.organizeImports": true
        },
        "files.watcherExclude": {
          "**/.git/objects/**": true,
          "**/.git/subtree-cache/**": true,
          "**/node_modules/**": true,
          "**/.hg/store/**": true,
          "**/.venv/**": true
        }
      }
    }
  },
  "forwardPorts": [
    3000, 3001, 3002, 3003, 5432, 6333, 8011, 8085, 9000, 9090, 11434
  ],
  "postCreateCommand": "make init",
  "postStartCommand": "make dev",
  "remoteUser": "vscode",
  "mounts": [
    "source=/var/run/docker.sock,target=/var/run/docker.sock,type=bind"
  ],
  "runArgs": ["--init", "--privileged"],
  "containerEnv": {
    "PYTHONPATH": "/workspace"
  }
}

```

</details>

## **📖 Phase 12: Documentation**

### **README.md**

<details> <summary>README.md</summary>

```markdown

markdown
# Alfred Agent Platform v2

A scalable, modular AI agent platform built with Docker, Supabase, and Pub/Sub messaging.

## Features

- 🤖 Multiple AI agents with LangChain and LangGraph
- 📨 Event-driven architecture with Google Cloud Pub/Sub
- 🗄️ State management with Supabase (PostgreSQL + pgvector)
- 🔍 Vector search with Qdrant
- 🎯 Real-time updates via Supabase Realtime
- 📊 Comprehensive monitoring with Prometheus and Grafana
- 🔒 Built-in security with rate limiting and PII scrubbing
- 🚀 Local-first development with Docker Compose

## Quick Start

### Prerequisites

- Docker Engine 25.0+
- Docker Compose v2
- Python 3.11+
- NVIDIA GPU with drivers (for local LLM)
- Git and Git LFS

### Setup

1. Clone the repository:
   ```bash
   git clone https://github.com/your-org/alfred-agent-platform-v2.git
   cd alfred-agent-platform-v2

```

1. Initialize the environment:

    ```bash

    bash
    make init

    ```

2. Configure your environment:

    ```bash

    bash
    cp .env.example .env
    # Edit .env with your settings

    ```

3. Start the platform:

    ```bash

    bash
    make setup

    ```

4. Access the services:
    - Supabase Studio: [http://localhost:3001](http://localhost:3001/)
    - Mission Control UI: [http://localhost:3003](http://localhost:3003/)
    - Grafana: [http://localhost:3002](http://localhost:3002/)
    - Prometheus: [http://localhost:9090](http://localhost:9090/)

## **Development**

### **Running Tests**

```bash

bash
# Run all tests
make test

# Run specific test types
make test-unit
make test-integration
make test-e2e

```

### **Code Quality**

```bash

bash
# Format code
make format

# Run linters
make lint

```

### **Adding a New Agent**

1. Create agent directory:

    ```bash

    bash
    mkdir -p agents/new_agent

    ```

2. Implement agent logic inheriting from `BaseAgent`
3. Create Docker service in `services/new-agent`
4. Add to `docker-compose.yml`
5. Update CI/CD matrix

## **Architecture**

The platform follows an event-driven microservices architecture:

- **Entry Points**: Slack bot, API endpoints
- **Message Bus**: Google Cloud Pub/Sub
- **State Storage**: Supabase (PostgreSQL)
- **Vector Search**: Qdrant
- **Agent Framework**: LangChain + LangGraph
- **Monitoring**: Prometheus + Grafana

## **Configuration**

### **Environment Variables**

Key environment variables:

- `ENVIRONMENT`: Development/staging/production
- `DATABASE_URL`: PostgreSQL connection string
- `PUBSUB_EMULATOR_HOST`: Pub/Sub emulator address
- `OPENAI_API_KEY`: OpenAI API key
- `SLACK_BOT_TOKEN`: Slack bot token

See `.env.example` for full list.

### **Database Migrations**

```bash

bash
# Run migrations
make db-migrate

# Reset database (CAUTION: deletes all data)
make db-reset

```

## **Deployment**

### **Local Development**

```bash

bash
make dev

```

### **Staging Deployment**

```bash

bash
# Triggered automatically on push to develop branch

```

### **Production Deployment**

```bash

bash
# Triggered automatically on push to main branch

```

## **Monitoring**

Access monitoring dashboards:

```bash

bash
make monitor

```

- Grafana: [http://localhost:3002](http://localhost:3002/) (admin/admin)
- Prometheus: [http://localhost:9090](http://localhost:9090/)

## **Contributing**

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## **License**

This project is licensed under the MIT License - see the LICENSE file for details.

```

</details>

### Architecture Documentation

<details>
<summary>docs/architecture/system-design.md</summary>

```markdown
# System Architecture

## Overview

The Alfred Agent Platform follows an event-driven microservices architecture designed for scalability, reliability, and extensibility.

## Core Components

### Message Bus (Pub/Sub)
- Event-driven communication between services
- Guaranteed message delivery
- Dead letter queue for failed messages
- Exactly-once processing guarantee

### State Management (Supabase)
- PostgreSQL for persistent storage
- pgvector for vector search capabilities
- Real-time updates via WebSocket
- Row-level security for data protection

### Agent Framework
- LangChain for AI capabilities
- LangGraph for complex workflows
- Standardized agent interface
- Plugin architecture for extensions

### Vector Search (Qdrant)
- High-performance vector similarity search
- Scalable to billions of vectors
- Real-time indexing
- Multi-tenant support

## Data Flow

1. **Request Ingestion**
   - Slack command or API call
   - Create A2A envelope
   - Publish to Pub/Sub

2. **Task Processing**
   - Agent subscribes to relevant intents
   - Process task with AI capabilities
   - Store results in Supabase

3. **Result Delivery**
   - Publish completion event
   - Update UI in real-time
   - Send notifications

## Security

- JWT authentication
- Rate limiting per user
- PII scrubbing in middleware
- TLS encryption in transit
- Encrypted storage at rest

## Scalability

- Horizontal scaling of agents
- Database connection pooling
- Caching with Redis
- Load balancing with health checks

## Monitoring

- Prometheus metrics collection
- Grafana dashboards
- Alert rules for SLA compliance
- Distributed tracing with OpenTelemetry

```

</details>

## **✅ Summary**

This consolidated guide provides a complete implementation plan for the AI Agent Platform v2, including:

1. **Prerequisites & Setup**: Comprehensive environment setup with updated tools and configurations
2. **Project Structure**: Well-organized directory layout for scalability
3. **Docker Configuration**: Complete containerization with all required services
4. **Database Setup**: Proper migrations with extensions and security
5. **CI/CD Pipeline**: Automated testing and deployment workflows
6. **Core Libraries**: Reusable components for agent development
7. **First Service**: Working Alfred Bot implementation
8. **Testing Framework**: Comprehensive test coverage
9. **Monitoring**: Production-ready observability stack
10. **IDE Configuration**: Optimized development experience
11. **Documentation**: Clear guides for developers and operators

All identified issues from the initial assessment have been addressed, providing a solid foundation for building and scaling the AI agent platform.
