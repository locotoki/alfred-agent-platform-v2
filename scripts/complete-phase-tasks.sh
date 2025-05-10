#!/bin/bash

# Script to complete all remaining Phase tasks
# Based on current gaps identified on May 04, 2025

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Starting Phase Completion Tasks...${NC}"
echo "===================================="

# Task 1: Enable missing database extension
echo -e "\n${YELLOW}Task 1: Enabling pg_cron extension${NC}"
docker exec supabase-db psql -U postgres -d postgres -c "CREATE EXTENSION IF NOT EXISTS pg_cron;"
echo -e "${GREEN}✓ pg_cron extension enabled${NC}"

# Task 2: Install Python dependencies for validation scripts
echo -e "\n${YELLOW}Task 2: Installing Python dependencies${NC}"
cd /home/locotoki/projects/alfred-agent-platform-v2
pip install aiohttp asyncpg python-dotenv structlog redis

# Task 3: Build and deploy Financial-Tax service
echo -e "\n${YELLOW}Task 3: Building Financial-Tax service${NC}"
cd /home/locotoki/projects/alfred-agent-platform-v2/services/financial-tax
docker build -t alfred-platform/financial-tax:latest .

echo -e "\n${YELLOW}Starting Financial-Tax service${NC}"
cd /home/locotoki/projects/alfred-agent-platform-v2
docker-compose up -d financial-tax

# Wait for service to start
sleep 10

# Task 4: Verify service health
echo -e "\n${YELLOW}Task 4: Verifying service health${NC}"
if curl -s http://localhost:9003/health/health > /dev/null; then
    echo -e "${GREEN}✓ Financial-Tax service is healthy${NC}"
else
    echo -e "${RED}✗ Financial-Tax service health check failed${NC}"
fi

# Task 5: Update Prometheus configuration
echo -e "\n${YELLOW}Task 5: Updating monitoring configuration${NC}"
cd /home/locotoki/projects/alfred-agent-platform-v2/monitoring/prometheus

# Add financial-tax to prometheus.yml
cat >> prometheus.yml << EOF

  - job_name: 'financial-tax'
    static_configs:
      - targets: ['financial-tax:9003']
    metrics_path: '/health/metrics'
EOF

# Restart Prometheus
docker restart prometheus

# Task 6: Run comprehensive tests
echo -e "\n${YELLOW}Task 6: Running comprehensive tests${NC}"
cd /home/locotoki/projects/alfred-agent-platform-v2

# Run unit tests
python3 -m pytest tests/unit/ -v

# Run integration tests
python3 -m pytest tests/integration/ -v -m integration

# Run financial-tax specific tests
python3 -m pytest agents/financial_tax/tests/ -v

echo -e "\n${GREEN}Phase Completion Tasks Summary:${NC}"
echo "--------------------------------"
echo -e "${GREEN}✓ Database extensions configured${NC}"
echo -e "${GREEN}✓ Python dependencies installed${NC}"
echo -e "${GREEN}✓ Financial-Tax service deployed${NC}"
echo -e "${GREEN}✓ Monitoring updated${NC}"
echo -e "${GREEN}✓ Tests executed${NC}"

echo -e "\n${YELLOW}Next Steps:${NC}"
echo "1. Run full infrastructure validation: ./scripts/infrastructure-validation.sh"
echo "2. Set up cron jobs: make setup-cron"
echo "3. Check service health: make health-check"
echo "4. Run deployment checklist: ./scripts/deployment-checklist.sh"
