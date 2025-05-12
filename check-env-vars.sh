#!/bin/bash
# check-env-vars.sh
# This script verifies that all required environment variables are set before starting services

# Text formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Print script header
echo -e "${BOLD}Alfred Agent Platform - Environment Variable Check${NC}"
echo "Checking for required environment variables..."
echo

# Function to check if a variable is set
check_var() {
  local var_name=$1
  local is_critical=${2:-true}  # Default to critical
  local var_value=${!var_name}
  
  # Check if variable exists and is not empty
  if [ -z "$var_value" ]; then
    if [ "$is_critical" = true ]; then
      echo -e "${RED}✗ CRITICAL: $var_name is not set${NC}"
      CRITICAL_MISSING=true
    else
      echo -e "${YELLOW}⚠ WARNING: $var_name is not set${NC}"
    fi
    return 1
  else
    if [[ $var_name == *"KEY"* || $var_name == *"SECRET"* || $var_name == *"PASSWORD"* || $var_name == *"TOKEN"* ]]; then
      # For sensitive values, don't show the actual value
      echo -e "${GREEN}✓ $var_name is set [hidden for security]${NC}"
    else
      echo -e "${GREEN}✓ $var_name is set to '$var_value'${NC}"
    fi
    return 0
  fi
}

# Initialize error tracking
CRITICAL_MISSING=false

# Group: Core Alfred Settings
echo -e "\n${BOLD}Core Settings:${NC}"
check_var ALFRED_ENVIRONMENT
check_var ALFRED_DEBUG
check_var ALFRED_PROJECT_ID

# Group: Database
echo -e "\n${BOLD}Database Settings:${NC}"
check_var DB_USER
check_var DB_PASSWORD
check_var DB_NAME
check_var DB_JWT_SECRET
check_var ALFRED_DATABASE_URL

# Group: Authentication
echo -e "\n${BOLD}Authentication Settings:${NC}"
check_var JWT_SECRET
check_var ANON_KEY
check_var SERVICE_ROLE_KEY
check_var SUPABASE_URL
check_var SITE_URL

# Group: External APIs (not all required)
echo -e "\n${BOLD}External API Settings:${NC}"
check_var ALFRED_OPENAI_API_KEY false
check_var ALFRED_YOUTUBE_API_KEY false

# Group: Slack Integration (only if enabled)
echo -e "\n${BOLD}Slack Integration:${NC}"
if [ "${ALFRED_ENABLE_SLACK:-false}" = "true" ]; then
  check_var SLACK_BOT_TOKEN
  check_var SLACK_SIGNING_SECRET
else
  echo -e "${YELLOW}⚠ Slack integration is disabled, skipping Slack token checks${NC}"
fi

# Group: Monitoring
echo -e "\n${BOLD}Monitoring Settings:${NC}"
check_var MONITORING_ADMIN_PASSWORD false

# Check for potential issues with default fallback values
echo -e "\n${BOLD}Security Checks:${NC}"
if grep -q "your-super-secret" .env 2>/dev/null; then
  echo -e "${YELLOW}⚠ WARNING: Found default placeholder values in .env file${NC}"
  echo -e "    Please replace these with real values in production environments"
fi

# Print summary
echo -e "\n${BOLD}Summary:${NC}"
if [ "$CRITICAL_MISSING" = true ]; then
  echo -e "${RED}✗ Critical environment variables are missing${NC}"
  echo -e "  Please set these variables in your .env file and try again"
  echo -e "  You can use .env.example as a template"
  exit 1
else
  echo -e "${GREEN}✓ All critical environment variables are set${NC}"
  echo -e "  You can proceed with starting the services"
  echo
  echo -e "Run: ./start-platform.sh up dev"
  exit 0
fi