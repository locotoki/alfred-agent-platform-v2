#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}
   █████╗ ██╗     ███████╗██████╗ ███████╗██████╗     ██████╗ ██╗      █████╗ ████████╗███████╗ ██████╗ ██████╗ ███╗   ███╗
  ██╔══██╗██║     ██╔════╝██╔══██╗██╔════╝██╔══██╗    ██╔══██╗██║     ██╔══██╗╚══██╔══╝██╔════╝██╔═══██╗██╔══██╗████╗ ████║
  ███████║██║     █████╗  ██████╔╝█████╗  ██║  ██║    ██████╔╝██║     ███████║   ██║   █████╗  ██║   ██║██████╔╝██╔████╔██║
  ██╔══██║██║     ██╔══╝  ██╔══██╗██╔══╝  ██║  ██║    ██╔═══╝ ██║     ██╔══██║   ██║   ██╔══╝  ██║   ██║██╔══██╗██║╚██╔╝██║
  ██║  ██║███████╗██║     ██║  ██║███████╗██████╔╝    ██║     ███████╗██║  ██║   ██║   ██║     ╚██████╔╝██║  ██║██║ ╚═╝ ██║
  ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝  ╚═╝╚══════╝╚═════╝     ╚═╝     ╚══════╝╚═╝  ╚═╝   ╚═╝   ╚═╝      ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝
${NC}"

echo -e "${BLUE}Platform Verification Tool${NC}"
echo -e "${YELLOW}Checking all services and endpoints...${NC}\n"

# Function to check HTTP endpoint
check_endpoint() {
    local name=$1
    local url=$2
    local expected_status=$3
    
    echo -ne "${YELLOW}Checking $name... ${NC}"
    
    status_code=$(curl -s -o /dev/null -w "%{http_code}" $url)
    
    if [ "$status_code" = "$expected_status" ]; then
        echo -e "${GREEN}✅ OK ($status_code)${NC}"
        return 0
    else
        echo -e "${RED}❌ ERROR (Expected: $expected_status, Got: $status_code)${NC}"
        return 1
    fi
}

# Function to check container status
check_container() {
    local name=$1
    local container_name=$2
    
    echo -ne "${YELLOW}Checking $name container... ${NC}"
    
    if [ "$(docker ps -q -f name=$container_name)" ]; then
        status=$(docker inspect --format='{{.State.Status}}' $container_name)
        health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}N/A{{end}}' $container_name)
        
        if [ "$status" = "running" ]; then
            if [ "$health" = "healthy" ] || [ "$health" = "N/A" ]; then
                echo -e "${GREEN}✅ OK ($status, Health: $health)${NC}"
                return 0
            else
                echo -e "${RED}❌ ERROR (Status: $status, Health: $health)${NC}"
                return 1
            fi
        else
            echo -e "${RED}❌ ERROR (Status: $status)${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ ERROR (Container not found)${NC}"
        return 1
    fi
}

# Function to test Supabase connectivity
test_supabase() {
    echo -ne "${YELLOW}Testing Supabase data access... ${NC}"
    
    # Try to read from architect_in table
    result=$(curl -s -X GET http://localhost:3000/architect_in)
    
    if [ -n "$result" ] && [[ $result == *"message"* ]]; then
        echo -e "${GREEN}✅ OK (Read successful)${NC}"
        
        # Try writing to the table
        echo -ne "${YELLOW}Testing Supabase write access... ${NC}"
        timestamp=$(date +%s)
        curl -s -X POST -H "Content-Type: application/json" \
             -d "{\"data\":{\"message\":\"verification test $timestamp\"}}" \
             http://localhost:3000/architect_in >/dev/null
        
        # Verify the write
        result=$(curl -s -X GET http://localhost:3000/architect_in)
        if [[ $result == *"verification test $timestamp"* ]]; then
            echo -e "${GREEN}✅ OK (Write successful)${NC}"
            return 0
        else
            echo -e "${RED}❌ ERROR (Write failed)${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ ERROR (Read failed)${NC}"
        return 1
    fi
}

# Check all container states
echo -e "${BLUE}Checking Container Status:${NC}"
check_container "Atlas" "alfred-agent-platform-v2-atlas-1"
check_container "RAG Gateway" "alfred-agent-platform-v2-rag-gateway-1"
check_container "Supabase DB" "alfred-agent-platform-v2-supabase-db-1"
check_container "Supabase REST" "alfred-agent-platform-v2-supabase-rest-1"
check_container "Redis" "alfred-agent-platform-v2-redis-1"
check_container "Grafana" "alfred-agent-platform-v2-grafana-1"
check_container "Prometheus" "alfred-agent-platform-v2-prometheus-1"

echo -e "\n${BLUE}Checking Health Endpoints:${NC}"
check_endpoint "Atlas /healthz" "http://localhost:8000/healthz" "200"
check_endpoint "Atlas /health" "http://localhost:8000/health" "200"
check_endpoint "RAG Gateway /healthz" "http://localhost:8501/healthz" "200"
check_endpoint "Prometheus health" "http://localhost:9090/-/healthy" "200"
check_endpoint "Grafana" "http://localhost:3005/login" "200"

echo -e "\n${BLUE}Testing Data Persistence:${NC}"
test_supabase

echo -e "\n${BLUE}Network Connectivity Tests:${NC}"
echo -e "${YELLOW}Testing Atlas -> RAG Gateway connectivity...${NC}"
docker exec alfred-agent-platform-v2-atlas-1 curl -s http://rag-gateway:8501/healthz
echo ""

echo -e "${YELLOW}Testing Atlas -> Supabase connectivity...${NC}"
docker exec alfred-agent-platform-v2-atlas-1 curl -s http://supabase-rest:3000/architect_in | grep -o "message" | head -1
echo ""

echo -e "${YELLOW}Testing Agent -> Supabase connectivity...${NC}"
docker exec alfred-agent-platform-v2-alfred-bot-1 sh -c "
apk add --no-cache curl >/dev/null 2>&1
curl -s http://supabase-rest:3000/architect_in | grep -o 'message' | head -1
"
echo ""

echo -e "${GREEN}✅ Verification complete!${NC}\n"
echo -e "${BLUE}Service Access URLs:${NC}"
echo -e "${GREEN}Supabase REST:${NC} http://localhost:3000"
echo -e "${GREEN}Supabase Auth:${NC} http://localhost:9999"
echo -e "${GREEN}Supabase Studio:${NC} http://localhost:3001"
echo -e "${GREEN}RAG Gateway:${NC} http://localhost:8501"
echo -e "${GREEN}Atlas:${NC} http://localhost:8000"
echo -e "${GREEN}Prometheus:${NC} http://localhost:9090"
echo -e "${GREEN}Grafana:${NC} http://localhost:3005"