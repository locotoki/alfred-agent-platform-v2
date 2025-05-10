#!/bin/bash

# Infrastructure Validation Script
# As per Alfred Agent Platform v2 - Project Status Latest

set -e

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Starting Infrastructure Validation...${NC}"
echo "=================================================="

# 1. Database Schema Audit
echo -e "\n${YELLOW}1. Database Schema Audit${NC}"
echo "-----------------------------"
python scripts/utils/database_validation.py

# 2. A2A Envelope Validation
echo -e "\n${YELLOW}2. A2A Envelope Validation${NC}"
echo "-----------------------------"
python -m pytest tests/unit/test_envelope.py -v

# 3. Service Health Checks
echo -e "\n${YELLOW}3. Service Health Checks${NC}"
echo "-----------------------------"
python scripts/utils/service_health_check.py

# 4. Exactly-Once Processing Test
echo -e "\n${YELLOW}4. Exactly-Once Processing Test${NC}"
echo "-----------------------------"
python -m pytest tests/integration/test_exactly_once_processing.py -v

# 5. Verify Extensions
echo -e "\n${YELLOW}5. Database Extensions Check${NC}"
echo "-----------------------------"
psql -h localhost -U postgres -d postgres -p 5432 -c "SELECT extname, extversion FROM pg_extension ORDER BY extname;"

# 6. Check Pub/Sub Emulator
echo -e "\n${YELLOW}6. Pub/Sub Emulator Check${NC}"
echo "-----------------------------"
curl -s http://localhost:8085/v1/projects/alfred-agent-platform/topics

# 7. Check Redis Connection
echo -e "\n${YELLOW}7. Redis Connection Check${NC}"
echo "-----------------------------"
redis-cli -h localhost -p 6379 ping

# 8. Check Qdrant Vector DB
echo -e "\n${YELLOW}8. Qdrant Vector DB Check${NC}"
echo "-----------------------------"
curl -s http://localhost:6333/health

echo -e "\n${GREEN}Infrastructure Validation Complete!${NC}"
echo "=================================================="

# Summary Report
echo -e "\n${YELLOW}VALIDATION SUMMARY:${NC}"
echo "-----------------------------"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ All validation checks passed${NC}"
    exit 0
else
    echo -e "${RED}✗ Some validation checks failed${NC}"
    exit 1
fi
