#!/bin/bash
# Script to validate that required GitHub Secrets are available
# This script is meant to be run as part of the CI/CD pipeline

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check if an environment variable is set
check_env_var() {
  local var_name=$1
  local environment=$2
  
  # Hide the actual value for security
  if [ -n "${!var_name}" ]; then
    echo "✅ $var_name is set for $environment environment"
  else
    echo "❌ $var_name is NOT set for $environment environment"
    exit 1
  fi
}

# Check staging environment variables
if [ "$GITHUB_ENVIRONMENT" == "staging" ]; then
  echo "Validating staging environment secrets:"
  check_env_var "SLACK_BOT_TOKEN" "staging"
  check_env_var "SLACK_APP_TOKEN" "staging"
  check_env_var "SLACK_SIGNING_SECRET" "staging"
fi

# Check production environment variables
if [ "$GITHUB_ENVIRONMENT" == "prod" ]; then
  echo "Validating production environment secrets:"
  check_env_var "CREWAI_ENDPOINT_PROD" "prod"
  check_env_var "CREWAI_A2A_CLIENT_ID" "prod"
  check_env_var "CREWAI_A2A_CLIENT_SECRET" "prod"
fi

echo "All required secrets are available!"
exit 0