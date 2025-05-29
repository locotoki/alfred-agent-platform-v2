#!/bin/bash
# Validate that all required environment variables are present

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Validating Environment Variables"
echo "==================================="
echo ""

# Load .env file if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs -0)
else
    echo -e "${RED}❌ ERROR: No .env file found!${NC}"
    echo ""
    echo "To fix this:"
    echo "1. cp .env.template .env"
    echo "2. Edit .env with your secrets"
    exit 1
fi

# Define required variables
REQUIRED_VARS=(
    "SLACK_SIGNING_SECRET"
    "SLACK_BOT_TOKEN"
    "SLACK_APP_TOKEN"
    "SLACK_WEBHOOK_URL"
    "REDIS_PASSWORD"
    "JWT_SIGNING_KEY"
    "GHCR_PAT"
)

# Optional but recommended
OPTIONAL_VARS=(
    "POSTGRES_PASSWORD"
    "ALFRED_REGISTRY"
    "COMPOSE_PROFILES"
)

# Check required variables
missing=0
echo "Required Variables:"
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo -e "${RED}❌ Missing: $var${NC}"
        ((missing++))
    else
        # Show masked value for security
        val="${!var}"
        if [ ${#val} -gt 10 ]; then
            masked="${val:0:4}****${val: -4}"
        else
            masked="****"
        fi
        echo -e "${GREEN}✅ Found: $var = $masked${NC}"
    fi
done

echo ""
echo "Optional Variables:"
for var in "${OPTIONAL_VARS[@]}"; do
    if [ -z "${!var:-}" ]; then
        echo -e "${YELLOW}⚠️  Missing (optional): $var${NC}"
    else
        echo -e "${GREEN}✅ Found: $var${NC}"
    fi
done

echo ""
if [ $missing -gt 0 ]; then
    echo -e "${RED}❌ VALIDATION FAILED: $missing required variables missing!${NC}"
    echo ""
    echo "To get the required values:"
    echo "- Slack tokens: Check with team lead or Slack app settings"
    echo "- Redis password: Check existing deployment or generate new"
    echo "- JWT key: Generate with: openssl rand -base64 32"
    echo "- GHCR PAT: Create at https://github.com/settings/tokens"
    exit 1
else
    echo -e "${GREEN}✅ All required environment variables present!${NC}"
    
    # Additional validation for Slack tokens format
    echo ""
    echo "Validating token formats..."
    
    if [[ ! "$SLACK_BOT_TOKEN" =~ ^xoxb- ]]; then
        echo -e "${YELLOW}⚠️  Warning: SLACK_BOT_TOKEN should start with 'xoxb-'${NC}"
    fi
    
    if [[ ! "$SLACK_APP_TOKEN" =~ ^xapp- ]]; then
        echo -e "${YELLOW}⚠️  Warning: SLACK_APP_TOKEN should start with 'xapp-'${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}✅ Environment is ready for Alfred Platform!${NC}"
fi