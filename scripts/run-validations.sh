#!/bin/bash

# Validation Script to run all checks
set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Running Infrastructure Validations...${NC}"
echo "======================================"

# Function to run checks manually
check_service() {
    local name=$1
    local port=$2
    local endpoint=$3

    echo -n "Checking $name..."
    if curl -s "http://localhost:$port$endpoint" > /dev/null; then
        echo -e "${GREEN} ✓ Healthy${NC}"
    else
        echo -e "${RED} ✗ Not responding${NC}"
    fi
}

# Special function for Redis
check_redis() {
    echo -n "Checking Redis..."
    if nc -zv localhost 6379 2>/dev/null; then
        echo -e "${GREEN} ✓ Healthy${NC}"
    else
        echo -e "${RED} ✗ Not responding${NC}"
    fi
}

echo -e "\n${YELLOW}1. Service Health Checks${NC}"
echo "-------------------------"
check_service "Alfred Bot" 8011 "/health/health"
check_service "Social Intel" 9000 "/health/health"
check_service "Legal Compliance" 9002 "/health/health"
check_service "Financial-Tax" 9003 "/health/health"
check_service "Supabase REST" 3000 "/"
check_service "Supabase Realtime" 4000 "/"
check_service "Pub/Sub Emulator" 8085 "/v1/projects/alfred-agent-platform/topics"
check_redis
check_service "Qdrant" 6333 "/health"
check_service "Prometheus" 9090 "/-/healthy"
check_service "Grafana" 3002 "/api/health"

echo -e "\n${YELLOW}2. Database Extensions Check${NC}"
echo "----------------------------"
docker exec supabase-db psql -U postgres -d postgres -c "SELECT extname, extversion FROM pg_extension ORDER BY extname;" || echo -e "${RED}Failed to check extensions${NC}"

echo -e "\n${YELLOW}3. Docker Container Status${NC}"
echo "--------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}" | grep -E "(healthy|running)" || echo -e "${RED}No healthy containers${NC}"

echo -e "\n${YELLOW}4. Critical Tables Check${NC}"
echo "------------------------"
docker exec supabase-db psql -U postgres -d postgres -c "SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' AND table_name IN ('tasks', 'task_results', 'processed_messages', 'agent_registry');" || echo -e "${RED}Failed to check tables${NC}"

echo -e "\n${YELLOW}5. Testing A2A Envelope${NC}"
echo "----------------------"
cd /home/locotoki/projects/alfred-agent-platform-v2
python3 -c "from libs.a2a_adapter import A2AEnvelope; e = A2AEnvelope(intent='TEST'); print(f'Envelope created: {e.task_id[:8]}...')" || echo -e "${RED}A2A Envelope test failed${NC}"

echo -e "\n${GREEN}Validation Complete!${NC}"
echo "===================="
