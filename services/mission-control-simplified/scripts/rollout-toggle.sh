#!/bin/bash

# Niche-Scout Rollout Toggle Script
# Controls the percentage of traffic sent to the new Niche-Scout proxy service
# For canary deployments and instant rollbacks

set -e

# Default values
SERVICE_HOST="localhost"
SERVICE_PORT=${SERVICE_PORT:-3007}  # Mission Control port
CONFIG_ENDPOINT="/config"
CURRENT_PERCENTAGE=0
ACTION=""
TARGET_PERCENTAGE=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Display script usage
show_usage() {
    echo -e "${BLUE}Niche-Scout Rollout Toggle Script${NC}"
    echo "Controls the percentage of traffic sent through the new Niche-Scout proxy service"
    echo 
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --set <percentage>   Set rollout percentage (0-100)"
    echo "  --enable             Enable proxy (sets to 100%)"
    echo "  --disable            Disable proxy (sets to 0%)"
    echo "  --canary             Start a 10% canary rollout"
    echo "  --status             Show current rollout status"
    echo "  --rollback           Emergency rollback to 0%"
    echo "  --host <hostname>    Specify service host (default: localhost)"
    echo "  --port <port>        Specify service port (default: 3007)"
    echo "  --help               Show this help message"
    echo
    echo "Examples:"
    echo "  $0 --status"
    echo "  $0 --canary"
    echo "  $0 --set 50"
    echo "  $0 --rollback"
    echo
}

# Function to get current configuration
get_current_config() {
    echo -e "${BLUE}Fetching current configuration...${NC}"
    
    response=$(curl -s -X GET "http://${SERVICE_HOST}:${SERVICE_PORT}${CONFIG_ENDPOINT}")
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Failed to connect to service at ${SERVICE_HOST}:${SERVICE_PORT}${NC}"
        exit 1
    fi
    
    # Extract proxy enabled status and percentage
    proxy_enabled=$(echo $response | grep -o '"proxyEnabled":[^,}]*' | cut -d':' -f2 | tr -d ' ')
    traffic_percentage=$(echo $response | grep -o '"proxyTrafficPercentage":[^,}]*' | cut -d':' -f2 | tr -d ' ')
    
    if [[ -z "$proxy_enabled" ]]; then
        echo -e "${RED}Error: Could not determine proxy status${NC}"
        echo "Raw response: $response"
        exit 1
    fi
    
    CURRENT_PERCENTAGE=$traffic_percentage
    
    # Display current status
    echo -e "${GREEN}Current configuration:${NC}"
    if [[ "$proxy_enabled" == "true" ]]; then
        echo -e "  Proxy service: ${GREEN}ENABLED${NC}"
    else
        echo -e "  Proxy service: ${RED}DISABLED${NC}"
    fi
    
    if [[ -z "$traffic_percentage" ]]; then
        echo -e "  Traffic percentage: ${YELLOW}UNKNOWN${NC}"
    else
        echo -e "  Traffic percentage: ${BLUE}${traffic_percentage}%${NC}"
    fi
    
    echo
}

# Function to update configuration
update_config() {
    local percentage=$1
    local enabled="true"
    
    if [[ $percentage -eq 0 ]]; then
        enabled="false"
    fi
    
    echo -e "${BLUE}Updating configuration...${NC}"
    echo -e "  Setting proxy traffic to: ${GREEN}${percentage}%${NC}"
    
    # Build JSON payload
    payload="{\"featureFlags\":{\"proxyEnabled\":${enabled},\"proxyTrafficPercentage\":${percentage}}}"
    
    # Send update request
    response=$(curl -s -X POST "http://${SERVICE_HOST}:${SERVICE_PORT}${CONFIG_ENDPOINT}" \
        -H "Content-Type: application/json" \
        -d "$payload")
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}Error: Failed to update configuration${NC}"
        exit 1
    fi
    
    # Check response for success
    success=$(echo $response | grep -o '"success":[^,}]*' | cut -d':' -f2 | tr -d ' ')
    
    if [[ "$success" == "true" ]]; then
        echo -e "${GREEN}Configuration updated successfully!${NC}"
        
        # Verify the change actually took effect
        sleep 1
        get_current_config
        
        if [[ "$CURRENT_PERCENTAGE" != "$percentage" ]]; then
            echo -e "${RED}Warning: Configuration update may not have taken effect${NC}"
            echo -e "${YELLOW}Expected: ${percentage}%, Actual: ${CURRENT_PERCENTAGE}%${NC}"
        fi
    else
        echo -e "${RED}Error: Failed to update configuration${NC}"
        echo "Raw response: $response"
        exit 1
    fi
}

# Function to perform canary rollout (10%)
do_canary_rollout() {
    echo -e "${BLUE}Initiating 10% canary rollout...${NC}"
    
    # First check current status
    get_current_config
    
    if [[ "$CURRENT_PERCENTAGE" == "10" ]]; then
        echo -e "${YELLOW}Canary rollout already at 10%${NC}"
        return
    fi
    
    echo -e "${BLUE}Setting traffic percentage to 10%...${NC}"
    update_config 10
    
    echo -e "${GREEN}Canary rollout complete${NC}"
    echo -e "${YELLOW}Monitor metrics for 15-30 minutes before increasing traffic percentage${NC}"
}

# Function to perform emergency rollback (0%)
do_emergency_rollback() {
    echo -e "${RED}EMERGENCY ROLLBACK INITIATED${NC}"
    echo -e "${YELLOW}Setting traffic percentage to 0%...${NC}"
    
    update_config 0
    
    echo -e "${GREEN}Rollback complete - proxy service is now disabled${NC}"
    echo -e "${YELLOW}Please investigate the issue before re-enabling${NC}"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    
    case $key in
        --set)
            ACTION="set"
            TARGET_PERCENTAGE="$2"
            shift
            shift
            ;;
        --enable)
            ACTION="set"
            TARGET_PERCENTAGE=100
            shift
            ;;
        --disable)
            ACTION="set"
            TARGET_PERCENTAGE=0
            shift
            ;;
        --canary)
            ACTION="canary"
            shift
            ;;
        --status)
            ACTION="status"
            shift
            ;;
        --rollback)
            ACTION="rollback"
            shift
            ;;
        --host)
            SERVICE_HOST="$2"
            shift
            shift
            ;;
        --port)
            SERVICE_PORT="$2"
            shift
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $key${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Validate arguments
if [[ -z "$ACTION" ]]; then
    echo -e "${RED}Error: No action specified${NC}"
    show_usage
    exit 1
fi

if [[ "$ACTION" == "set" ]]; then
    # Validate percentage value
    if ! [[ "$TARGET_PERCENTAGE" =~ ^[0-9]+$ ]] || [[ $TARGET_PERCENTAGE -lt 0 ]] || [[ $TARGET_PERCENTAGE -gt 100 ]]; then
        echo -e "${RED}Error: Percentage must be a number between 0 and 100${NC}"
        exit 1
    fi
fi

# Execute requested action
case $ACTION in
    status)
        get_current_config
        ;;
    set)
        get_current_config
        update_config $TARGET_PERCENTAGE
        ;;
    canary)
        do_canary_rollout
        ;;
    rollback)
        do_emergency_rollback
        ;;
esac

echo -e "${GREEN}Operation completed successfully${NC}"
exit 0