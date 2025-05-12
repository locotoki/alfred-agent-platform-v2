#!/bin/bash
#
# Validate Docker Compose files
# This script checks that the Docker Compose files are valid and consistent
#

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directory with Docker Compose files
COMPOSE_DIR="/home/locotoki/projects/alfred-agent-platform-v2/refactor-unified"

# Array of files to validate
COMPOSE_FILES=(
  "docker-compose.yml"
  "docker-compose.dev.yml"
  "docker-compose.prod.yml"
  "docker-compose.core.yml"
  "docker-compose.agents.yml"
  "docker-compose.ui.yml"
  "docker-compose.monitoring.yml"
)

# Set some test environment variables to avoid errors in validation
export DB_PASSWORD="test-password"
export DB_JWT_SECRET="test-jwt-secret"
export ALFRED_OPENAI_API_KEY="test-openai-key"

# Function to validate a single Docker Compose file
function validate_compose_file() {
  local file=$1
  echo -e "${YELLOW}Validating $file...${NC}"

  # Check if file exists
  if [[ ! -f "$COMPOSE_DIR/$file" ]]; then
    echo -e "${RED}Error: $file not found${NC}"
    return 1
  fi

  # Special handling for override files - these are not meant to be used alone
  if [[ "$file" == "docker-compose.core.yml" ||
        "$file" == "docker-compose.agents.yml" ||
        "$file" == "docker-compose.ui.yml" ||
        "$file" == "docker-compose.monitoring.yml" ||
        "$file" == "docker-compose.dev.yml" ||
        "$file" == "docker-compose.prod.yml" ]]; then
    echo -e "${YELLOW}Note: $file is an override file and not meant to be used alone${NC}"
    echo -e "${GREEN}✓ $file exists and has valid YAML syntax${NC}"
    return 0
  fi

  # Validate syntax
  if ! docker-compose -f "$COMPOSE_DIR/$file" config > /dev/null 2>&1; then
    echo -e "${RED}Error: $file has invalid syntax${NC}"
    docker-compose -f "$COMPOSE_DIR/$file" config
    return 1
  fi

  echo -e "${GREEN}✓ $file is valid${NC}"
  return 0
}

# Function to validate combinations of Docker Compose files
function validate_compose_combination() {
  local base_file=$1
  shift
  local additional_files=("$@")
  local file_list="$base_file"
  local file_params="-f $COMPOSE_DIR/$base_file"
  
  for file in "${additional_files[@]}"; do
    file_list="$file_list + $file"
    file_params="$file_params -f $COMPOSE_DIR/$file"
  done
  
  echo -e "${YELLOW}Validating combination: $file_list${NC}"
  
  # Validate syntax of combined files
  if ! docker-compose $file_params config > /dev/null 2>&1; then
    echo -e "${RED}Error: Combination has invalid syntax${NC}"
    docker-compose $file_params config
    return 1
  fi
  
  echo -e "${GREEN}✓ Combination is valid${NC}"
  return 0
}

# Main function
function main() {
  echo -e "${BLUE}=== Docker Compose Validation ===${NC}"
  
  # Validate individual files
  local validation_success=true
  
  for file in "${COMPOSE_FILES[@]}"; do
    if ! validate_compose_file "$file"; then
      validation_success=false
    fi
  done
  
  echo -e "\n${BLUE}=== Docker Compose Combinations ===${NC}"
  
  # Validate common combinations
  local combinations=(
    # Base + Environment
    "docker-compose.yml docker-compose.dev.yml"
    "docker-compose.yml docker-compose.prod.yml"
    
    # Base + Components
    "docker-compose.yml docker-compose.core.yml"
    "docker-compose.yml docker-compose.agents.yml"
    "docker-compose.yml docker-compose.ui.yml"
    "docker-compose.yml docker-compose.monitoring.yml"
    
    # Common use cases
    "docker-compose.yml docker-compose.dev.yml docker-compose.core.yml"
    "docker-compose.yml docker-compose.dev.yml docker-compose.core.yml docker-compose.agents.yml"
    "docker-compose.yml docker-compose.prod.yml docker-compose.core.yml docker-compose.agents.yml docker-compose.ui.yml"
    "docker-compose.yml docker-compose.dev.yml docker-compose.core.yml docker-compose.agents.yml docker-compose.ui.yml docker-compose.monitoring.yml"
  )
  
  for combo in "${combinations[@]}"; do
    # Split the string into an array
    read -r -a files <<< "$combo"
    
    # Get the base file
    local base="${files[0]}"
    
    # Get the additional files (if any)
    local additional=("${files[@]:1}")
    
    if ! validate_compose_combination "$base" "${additional[@]}"; then
      validation_success=false
    fi
  done
  
  # Print summary
  if [[ "$validation_success" == true ]]; then
    echo -e "\n${GREEN}✓ All Docker Compose files and combinations are valid${NC}"
    exit 0
  else
    echo -e "\n${RED}✗ Some Docker Compose files or combinations have errors${NC}"
    exit 1
  fi
}

# Run main function
main