#!/bin/bash

# Text formatting
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

echo -e "${BOLD}${BLUE}=== Alfred Agent Platform v2 Service Health Check ===${RESET}"
echo 

# Check services grouped by category
echo -e "${BOLD}Core Infrastructure:${RESET}"
services=("redis" "vector-db" "pubsub-emulator" "llm-service")
for service in "${services[@]}"; do
    status=$(docker inspect --format='{{.State.Status}} | {{.State.Health.Status}}' $service 2>/dev/null || echo "not found")
    if [[ $status == *"running | healthy"* ]]; then
        echo -e "  ${GREEN}✓ $service${RESET}"
    elif [[ $status == *"running | starting"* ]]; then
        echo -e "  ${YELLOW}⟳ $service (starting)${RESET}"
    elif [[ $status == *"running | unhealthy"* ]]; then
        echo -e "  ${RED}✗ $service (unhealthy)${RESET}"
    elif [[ $status == *"not found"* ]]; then
        echo -e "  ${RED}✗ $service (not found)${RESET}"
    else
        echo -e "  ${RED}✗ $service ($status)${RESET}"
    fi
done

echo -e "\n${BOLD}Database Services:${RESET}"
services=("db-postgres" "db-auth" "db-api" "db-admin" "db-realtime" "db-storage")
for service in "${services[@]}"; do
    status=$(docker inspect --format='{{.State.Status}} | {{.State.Health.Status}}' $service 2>/dev/null || echo "not found")
    if [[ $status == *"running | healthy"* ]]; then
        echo -e "  ${GREEN}✓ $service${RESET}"
    elif [[ $status == *"running | starting"* ]]; then
        echo -e "  ${YELLOW}⟳ $service (starting)${RESET}"
    elif [[ $status == *"running | unhealthy"* ]]; then
        echo -e "  ${RED}✗ $service (unhealthy)${RESET}"
    elif [[ $status == *"not found"* ]]; then
        echo -e "  ${RED}✗ $service (not found)${RESET}"
    else
        echo -e "  ${RED}✗ $service ($status)${RESET}"
    fi
done

echo -e "\n${BOLD}LLM Services:${RESET}"
services=("model-registry" "model-router")
for service in "${services[@]}"; do
    status=$(docker inspect --format='{{.State.Status}} | {{.State.Health.Status}}' $service 2>/dev/null || echo "not found")
    if [[ $status == *"running | healthy"* ]]; then
        echo -e "  ${GREEN}✓ $service${RESET}"
    elif [[ $status == *"running | starting"* ]]; then
        echo -e "  ${YELLOW}⟳ $service (starting)${RESET}"
    elif [[ $status == *"running | unhealthy"* ]]; then
        echo -e "  ${RED}✗ $service (unhealthy)${RESET}"
    elif [[ $status == *"not found"* ]]; then
        echo -e "  ${RED}✗ $service (not found)${RESET}"
    else
        echo -e "  ${RED}✗ $service ($status)${RESET}"
    fi
done

echo -e "\n${BOLD}Agent Services:${RESET}"
services=("agent-core" "agent-rag" "agent-atlas" "agent-social" "agent-financial" "agent-legal")
for service in "${services[@]}"; do
    status=$(docker inspect --format='{{.State.Status}} | {{.State.Health.Status}}' $service 2>/dev/null || echo "not found")
    if [[ $status == *"running | healthy"* ]]; then
        echo -e "  ${GREEN}✓ $service${RESET}"
    elif [[ $status == *"running | starting"* ]]; then
        echo -e "  ${YELLOW}⟳ $service (starting)${RESET}"
    elif [[ $status == *"running | unhealthy"* ]]; then
        echo -e "  ${RED}✗ $service (unhealthy)${RESET}"
    elif [[ $status == *"not found"* ]]; then
        echo -e "  ${RED}✗ $service (not found)${RESET}"
    else
        echo -e "  ${RED}✗ $service ($status)${RESET}"
    fi
done

echo -e "\n${BOLD}UI Services:${RESET}"
services=("ui-chat" "ui-admin" "auth-ui")
for service in "${services[@]}"; do
    status=$(docker inspect --format='{{.State.Status}} | {{.State.Health.Status}}' $service 2>/dev/null || echo "not found")
    if [[ $status == *"running | healthy"* ]]; then
        echo -e "  ${GREEN}✓ $service${RESET}"
    elif [[ $status == *"running | starting"* ]]; then
        echo -e "  ${YELLOW}⟳ $service (starting)${RESET}"
    elif [[ $status == *"running | unhealthy"* ]]; then
        echo -e "  ${RED}✗ $service (unhealthy)${RESET}"
    elif [[ $status == *"not found"* ]]; then
        echo -e "  ${RED}✗ $service (not found)${RESET}"
    else
        echo -e "  ${RED}✗ $service ($status)${RESET}"
    fi
done

echo -e "\n${BOLD}Monitoring Services:${RESET}"
services=("monitoring-metrics" "monitoring-dashboard" "monitoring-node" "monitoring-db" "monitoring-redis")
for service in "${services[@]}"; do
    status=$(docker inspect --format='{{.State.Status}} | {{.State.Health.Status}}' $service 2>/dev/null || echo "not found")
    if [[ $status == *"running | healthy"* ]]; then
        echo -e "  ${GREEN}✓ $service${RESET}"
    elif [[ $status == *"running | starting"* ]]; then
        echo -e "  ${YELLOW}⟳ $service (starting)${RESET}"
    elif [[ $status == *"running | unhealthy"* ]]; then
        echo -e "  ${RED}✗ $service (unhealthy)${RESET}"
    elif [[ $status == *"not found"* ]]; then
        echo -e "  ${RED}✗ $service (not found)${RESET}"
    else
        echo -e "  ${RED}✗ $service ($status)${RESET}"
    fi
done

echo
echo -e "${BOLD}${BLUE}=== Endpoint Accessibility Check ===${RESET}"
echo

# Check if specific endpoints are accessible
endpoints=(
    "http://localhost:8000/healthz|Atlas API"
    "http://localhost:8501/healthz|RAG Gateway"
    "http://localhost:8502/health_check.html|Chat UI"
    "http://localhost:3007/health|Admin Dashboard"
    "http://localhost:9000/health/|Social Intel Agent"
    "http://localhost:9002/health/|Legal Compliance Agent"
    "http://localhost:9003/health/|Financial Tax Agent"
    "http://localhost:8079/health|Model Registry"
    "http://localhost:8080/health|Model Router"
    "http://localhost:5000/health|Storage API"
)

for endpoint in "${endpoints[@]}"; do
    IFS="|" read -r url name <<< "$endpoint"
    
    # Try curl with timeout to see if endpoint is accessible
    if timeout 2 curl -s "$url" > /dev/null; then
        echo -e "  ${GREEN}✓ $name ($url)${RESET}"
    else
        echo -e "  ${RED}✗ $name ($url)${RESET}"
    fi
done

echo
echo -e "${BOLD}${BLUE}Done!${RESET}"