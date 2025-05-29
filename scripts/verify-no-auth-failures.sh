#!/bin/bash
# Verify no authentication failures across all services
# Exit criteria: 0 auth failures

set -euo pipefail

echo "=== Verifying No Authentication Failures ==="
echo "Checking all service logs for auth errors..."

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Track failures
TOTAL_FAILURES=0
FAILED_SERVICES=()

# Common auth failure patterns
AUTH_FAILURE_PATTERNS=(
    "authentication failed"
    "password authentication failed"
    "NOAUTH Authentication required"
    "invalid password"
    "permission denied"
    "unauthorized"
    "403 Forbidden"
    "401 Unauthorized"
    "ERR AUTH"
    "WRONGPASS"
    "authentication error"
)

# Function to check service logs for auth failures
check_service_logs() {
    local service=$1
    local failures=0

    echo -n "Checking $service... "

    # Get logs from last 5 minutes
    local logs=$(docker-compose logs --tail=1000 --since=5m "$service" 2>&1 || echo "")

    if [ -z "$logs" ]; then
        echo -e "${YELLOW}No logs${NC}"
        return 0
    fi

    # Check for auth failure patterns
    for pattern in "${AUTH_FAILURE_PATTERNS[@]}"; do
        local count=$(echo "$logs" | grep -i "$pattern" | wc -l)
        if [ $count -gt 0 ]; then
            failures=$((failures + count))
        fi
    done

    if [ $failures -eq 0 ]; then
        echo -e "${GREEN}✓ No auth failures${NC}"
    else
        echo -e "${RED}✗ Found $failures auth failures${NC}"
        FAILED_SERVICES+=("$service")

        # Show sample of failures
        echo "  Sample errors:"
        for pattern in "${AUTH_FAILURE_PATTERNS[@]}"; do
            echo "$logs" | grep -i "$pattern" | head -3 | while IFS= read -r line; do
                echo "    $line"
            done
        done
    fi

    TOTAL_FAILURES=$((TOTAL_FAILURES + failures))
    return $failures
}

# Get list of running services
SERVICES=$(docker-compose ps --services 2>/dev/null || echo "")

if [ -z "$SERVICES" ]; then
    echo -e "${RED}No services running. Start services first.${NC}"
    exit 1
fi

# Check each service
echo "Scanning $(echo "$SERVICES" | wc -l) services..."
echo ""

while IFS= read -r service; do
    if [ -n "$service" ]; then
        check_service_logs "$service" || true
    fi
done <<< "$SERVICES"

# Redis-specific authentication check
echo ""
echo "Running Redis authentication test..."
if docker exec redis redis-cli -a "${REDIS_PASSWORD:-}" ping >/dev/null 2>&1; then
    echo -e "${GREEN}✓ Redis authentication working${NC}"
else
    echo -e "${RED}✗ Redis authentication failed${NC}"
    TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
fi

# PostgreSQL-specific authentication check
echo "Running PostgreSQL authentication test..."
if docker exec db-postgres psql -U "${DB_USER:-postgres}" -c "SELECT 1" >/dev/null 2>&1; then
    echo -e "${GREEN}✓ PostgreSQL authentication working${NC}"
else
    echo -e "${RED}✗ PostgreSQL authentication failed${NC}"
    TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
fi

# Generate health report
echo ""
echo "=== Authentication Health Report ==="
echo "Total authentication failures: $TOTAL_FAILURES"
echo ""

if [ $TOTAL_FAILURES -eq 0 ]; then
    echo -e "${GREEN}✓ EXIT CRITERIA MET: 0 authentication failures${NC}"
    echo ""
    echo "All services are authenticating successfully!"

    # Additional health checks
    echo ""
    echo "Container Health Status:"
    docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Health}}" | grep -E "(NAME|healthy|unhealthy|starting)" || true

    exit 0
else
    echo -e "${RED}✗ EXIT CRITERIA NOT MET: Found $TOTAL_FAILURES authentication failures${NC}"
    echo ""
    echo "Failed services:"
    printf '%s\n' "${FAILED_SERVICES[@]}" | sort | uniq
    echo ""
    echo "Remediation steps:"
    echo "1. Check .env file has correct passwords"
    echo "2. Run './scripts/reconcile-credentials.sh' to fix credentials"
    echo "3. Restart affected services: docker-compose restart ${FAILED_SERVICES[*]}"
    echo "4. Check service-specific configuration files"

    exit 1
fi
