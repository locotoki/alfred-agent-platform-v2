#!/bin/bash
# check-env-consistency.sh
# Script to check environment variable consistency between docker-compose.unified.yml and .env.example

set -e

echo "Checking environment variable consistency..."

# Create a consolidated .env.example file if it doesn't exist
if [ ! -f "../.env.example" ]; then
  echo "Creating standardized .env.example file..."
  cat > "../.env.example" << 'EOF'
# Database Configuration
DB_USER=postgres
DB_PASSWORD=your-super-secret-password
DB_NAME=postgres
DB_JWT_SECRET=your-super-secret-jwt-token
DB_JWT_EXP=3600

# Service URLs (internal)
MODEL_ROUTER_URL=http://model-router:8080
RAG_GATEWAY_URL=http://agent-rag:8501
PUBSUB_EMULATOR_HOST=pubsub-emulator:8085

# API Keys
ALFRED_OPENAI_API_KEY=sk-mock-key-for-development-only
ALFRED_ANTHROPIC_API_KEY=
ALFRED_YOUTUBE_API_KEY=youtube-mock-key-for-development-only

# Project Settings
ALFRED_PROJECT_ID=alfred-agent-platform
ALFRED_ENVIRONMENT=development
ALFRED_DEBUG=true
ALFRED_MODE=default
ALFRED_ENABLE_SLACK=true
ALFRED_DATABASE_URL=postgresql://postgres:your-super-secret-password@db-postgres:5432/postgres

# Storage Settings
STORAGE_BACKEND=file
FILE_STORAGE_BACKEND_PATH=/var/lib/storage

# Supabase Settings
ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImV4cCI6MTc0OTUzNjEzMH0.zcPCLGlqF3YHBP-gTlXOQ2zjV-h3VmxbThiYEg2I5io
SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoic2VydmljZV9yb2xlIiwiZXhwIjoxNzQ5NTM2MTMwfQ.EDf3DT0Zl6qQbrLIQLwAXRWAN5kaJ5mvlAh1jm0CY-o
SUPABASE_PUBLIC_URL=http://localhost:8000
SECRET_KEY_BASE=2a889e9d516d08490c603f4ec73c58c0b1d4d9cc8c6be2b3c7639d2c780bb4d0
API_EXTERNAL_URL=http://localhost:8000
SITE_URL=http://localhost:3000
ADDITIONAL_REDIRECT_URLS=
DISABLE_SIGNUP=false
ENABLE_EMAIL_SIGNUP=true
ENABLE_EMAIL_AUTOCONFIRM=false
JWT_EXPIRY=3600
STUDIO_DEFAULT_ORGANIZATION=Alfred Organization
STUDIO_DEFAULT_PROJECT=Alfred Project

# Mail Settings
SMTP_HOST=mail-server
SMTP_PORT=1025
SMTP_USER=
SMTP_PASS=

# Monitoring
MONITORING_ADMIN_PASSWORD=admin
EOF
fi

# Extract all environment variables from docker-compose.yml
grep -o '\${[A-Za-z0-9_]*' ../docker-compose.unified.yml | sort | uniq | tr -d '${' > /tmp/all_env_vars.txt

# Extract variables from .env.example
grep -o '^[A-Za-z0-9_]*=' ../.env.example | tr -d '=' | sort > /tmp/env_example_vars.txt

echo "====================================================================="
echo "Variables in docker-compose.unified.yml but missing in .env.example:"
echo "====================================================================="
comm -23 /tmp/all_env_vars.txt /tmp/env_example_vars.txt

echo ""
echo "====================================================================="
echo "Variables in .env.example but not used in docker-compose.unified.yml:"
echo "====================================================================="
comm -13 /tmp/all_env_vars.txt /tmp/env_example_vars.txt

# Check for environment variables directly set (not using ${...})
echo ""
echo "====================================================================="
echo "Environment variables directly set without using placeholders:"
echo "====================================================================="
grep -A1 "environment:" ../docker-compose.unified.yml | grep -v "environment:" | grep -v "^\-\-" | grep -v "\${" | grep "=" | sed 's/^[ \t]*//'

# Cleanup
rm /tmp/all_env_vars.txt /tmp/env_example_vars.txt

echo ""
echo "✅ Environment variable consistency check completed."
echo ""
echo "To incorporate missing variables into .env.example, edit the file:"
echo "nano ../.env.example"
echo ""
echo "To apply environment variable standardization, update all direct variable assignments"
echo "in docker-compose.unified.yml to use \${VAR_NAME:-default_value} format."