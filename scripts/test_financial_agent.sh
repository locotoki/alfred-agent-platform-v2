#!/bin/bash
# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Running Financial Tax Agent Tests${NC}"
echo "========================================"

# Run unit tests with coverage
echo -e "${YELLOW}Running Unit Tests${NC}"
docker exec financial-tax python3.11 -m pytest /app/tests/unit/agents/financial_tax/ -v --cov=/app/agents/financial_tax --cov-report=term-missing --cov-report=xml:/app/coverage.xml

# Check if tests passed
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Unit tests passed${NC}"
    
    # Run integration tests
    echo -e "${YELLOW}Running Integration Tests${NC}"
    docker exec financial-tax python3.11 -m pytest /app/tests/integration/agents/financial_tax/ -v -m integration
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Integration tests passed${NC}"
        
        # Display coverage report
        echo -e "${YELLOW}Coverage Report${NC}"
        docker exec financial-tax python3.11 -m coverage report --show-missing
        
        # Generate HTML report
        docker exec financial-tax python3.11 -m coverage html -d /app/coverage_html
        echo -e "${GREEN}HTML coverage report generated at coverage_html/${NC}"
    else
        echo -e "${RED}✗ Integration tests failed${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Unit tests failed${NC}"
    exit 1
fi
