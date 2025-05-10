#!/bin/bash

# Deployment Checklist Script
# Based on Alfred Agent Platform v2 - Project Status Latest

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Financial-Tax Agent Deployment Checklist${NC}"
echo "========================================"

# Function to check status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ $1${NC}"
    else
        echo -e "${RED}✗ $1${NC}"
        exit 1
    fi
}

echo -e "\n${YELLOW}Pre-deployment Checks:${NC}"
echo "----------------------"

# 1. Run tests
echo "Running unit tests..."
python -m pytest tests/unit/ -v
check_status "Unit tests passed"

# 2. Check code coverage
echo "Checking code coverage..."
python -m pytest --cov=agents/financial_tax --cov-report=term-missing tests/unit/
check_status "Code coverage check completed"

# 3. Run linters
echo "Running linters..."
python -m black --check agents/financial_tax/ services/financial-tax/
check_status "Code formatting check"

python -m isort --check-only agents/financial_tax/ services/financial-tax/
check_status "Import sorting check"

python -m flake8 agents/financial_tax/ services/financial-tax/
check_status "Flake8 check"

python -m mypy agents/financial_tax/ services/financial-tax/
check_status "Type checking"

# 4. Security scan
echo "Running security scan..."
python -m bandit -r agents/financial_tax/ services/financial-tax/
check_status "Security scan passed"

# 5. Documentation check
echo "Checking documentation..."
test -f docs/agents/financial-tax-agent.md
check_status "Agent documentation exists"

test -f docs/api/financial-tax-api.yaml
check_status "API documentation exists"

echo -e "\n${YELLOW}Deployment Steps:${NC}"
echo "----------------"

# 1. Build Docker image
echo "Building Docker image..."
docker build -t alfred-platform/financial-tax:latest services/financial-tax/
check_status "Docker image built"

# 2. Run integration tests
echo "Running integration tests..."
python -m pytest tests/integration/financial_tax/ -v -m integration
check_status "Integration tests passed"

# 3. Verify environment variables
echo "Checking environment variables..."
test -n "$OPENAI_API_KEY"
check_status "OPENAI_API_KEY is set"

test -n "$DATABASE_URL"
check_status "DATABASE_URL is set"

test -n "$REDIS_URL"
check_status "REDIS_URL is set"

echo -e "\n${YELLOW}Post-deployment Verification:${NC}"
echo "---------------------------"

# 1. Check service health
echo "Verifying service health..."
curl -s http://localhost:9003/health/health || echo "Service not running on expected port"

# 2. Check monitoring
echo "Verifying monitoring..."
curl -s http://localhost:9090/api/v1/targets | grep financial-tax || echo "Service not registered in Prometheus"

# 3. Check logging
echo "Verifying logging..."
docker logs financial-tax 2>&1 | grep "service_started" || echo "Service logs not found"

echo -e "\n${GREEN}Deployment Checklist Complete!${NC}"
echo "=============================="

echo -e "\n${YELLOW}Summary:${NC}"
echo "--------"
echo -e "${GREEN}✓ All pre-deployment checks passed${NC}"
echo -e "${GREEN}✓ Docker image built successfully${NC}"
echo -e "${GREEN}✓ Integration tests passed${NC}"
echo -e "${GREEN}✓ Environment configured${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "----------"
echo "1. Deploy to staging environment"
echo "2. Run smoke tests"
echo "3. Monitor for 30 minutes"
echo "4. Deploy to production"
echo "5. Verify all endpoints"
echo "6. Update status page"
