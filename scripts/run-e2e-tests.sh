#!/bin/bash
# Run E2E tests locally

set -euo pipefail

echo "🧪 Running E2E Tests for Alfred Platform"
echo "========================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse arguments
RUN_SMOKE=true
RUN_REGRESSION=false
RUN_SLACK=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --all)
            RUN_REGRESSION=true
            RUN_SLACK=true
            shift
            ;;
        --regression)
            RUN_REGRESSION=true
            shift
            ;;
        --slack)
            RUN_SLACK=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --all         Run all tests (smoke, regression, slack)"
            echo "  --regression  Include regression tests"
            echo "  --slack       Include Slack integration tests"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check dependencies
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose is required but not installed${NC}"
    exit 1
fi

if ! command -v pytest &> /dev/null; then
    echo -e "${YELLOW}⚠️  pytest not found, installing...${NC}"
    pip install pytest pytest-timeout requests rich click
fi

# Start services
echo -e "\n${YELLOW}🚀 Starting services...${NC}"
docker-compose -f docker-compose.yml \
    -f docker-compose.healthchecks.yml \
    -f docker-compose.observability.yml \
    up -d

# Wait for services to be healthy
echo -e "\n${YELLOW}⏳ Waiting for services to be healthy...${NC}"
MAX_WAIT=120
WAITED=0
while ! docker-compose ps | grep -v "Exit" | grep -q "healthy"; do
    if [ $WAITED -ge $MAX_WAIT ]; then
        echo -e "${RED}❌ Services failed to become healthy after ${MAX_WAIT}s${NC}"
        docker-compose ps
        exit 1
    fi
    sleep 5
    WAITED=$((WAITED + 5))
    echo -ne "\rWaited ${WAITED}s..."
done
echo -e "\n${GREEN}✓ Services are healthy${NC}"

# Run Alfred health check
echo -e "\n${YELLOW}🏥 Running Alfred health check...${NC}"
if ./alfred-cli health; then
    echo -e "${GREEN}✓ Alfred health check passed${NC}"
else
    echo -e "${RED}❌ Alfred health check failed${NC}"
    exit 1
fi

# Run smoke tests
if [ "$RUN_SMOKE" = true ]; then
    echo -e "\n${YELLOW}🔥 Running smoke tests...${NC}"
    if pytest tests/e2e/test_smoke.py -v --tb=short; then
        echo -e "${GREEN}✓ Smoke tests passed${NC}"
    else
        echo -e "${RED}❌ Smoke tests failed${NC}"
        FAILED=true
    fi
fi

# Run regression tests
if [ "$RUN_REGRESSION" = true ]; then
    echo -e "\n${YELLOW}🔄 Running regression tests...${NC}"
    if pytest tests/e2e/test_regression.py -v --tb=short; then
        echo -e "${GREEN}✓ Regression tests passed${NC}"
    else
        echo -e "${RED}❌ Regression tests failed${NC}"
        FAILED=true
    fi
fi

# Run Slack tests
if [ "$RUN_SLACK" = true ]; then
    echo -e "\n${YELLOW}💬 Running Slack integration tests...${NC}"
    if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
        echo -e "${YELLOW}⚠️  SLACK_WEBHOOK_URL not set, skipping Slack tests${NC}"
    else
        if pytest tests/e2e/test_slack_integration.py -v --tb=short -m slack; then
            echo -e "${GREEN}✓ Slack tests passed${NC}"
        else
            echo -e "${RED}❌ Slack tests failed${NC}"
            FAILED=true
        fi
    fi
fi

# Summary
echo -e "\n========================================"
if [ "${FAILED:-false}" = true ]; then
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
else
    echo -e "${GREEN}✅ All tests passed!${NC}"
fi

# Cleanup prompt
echo -e "\n${YELLOW}Services are still running. To stop them:${NC}"
echo "  docker-compose down -v"
