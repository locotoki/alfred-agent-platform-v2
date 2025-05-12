#!/bin/bash
#
# Test alfred.sh script
# This script tests the functionality of the alfred.sh command interface
#

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directory with alfred.sh script
ALFRED_DIR="/home/locotoki/projects/alfred-agent-platform-v2/refactor-unified"
ALFRED_SCRIPT="$ALFRED_DIR/alfred.sh"

# Function to test alfred.sh help command
function test_help_command() {
  echo -e "${YELLOW}Testing help command...${NC}"
  
  # Check if help command returns success
  if ! "$ALFRED_SCRIPT" help > /dev/null; then
    echo -e "${RED}Error: Help command failed${NC}"
    return 1
  fi
  
  # Check if help output contains expected information
  if ! "$ALFRED_SCRIPT" help | grep -q "Usage:"; then
    echo -e "${RED}Error: Help output does not contain usage information${NC}"
    return 1
  fi
  
  echo -e "${GREEN}✓ Help command works${NC}"
  return 0
}

# Function to test alfred.sh argument parsing
function test_argument_parsing() {
  echo -e "${YELLOW}Testing argument parsing...${NC}"
  
  # Test environment flag
  if ! "$ALFRED_SCRIPT" status --env=dev | grep -q "Using development environment"; then
    echo -e "${RED}Error: --env=dev flag not recognized${NC}"
    return 1
  fi
  
  if ! "$ALFRED_SCRIPT" status --env=prod | grep -q "Using production environment"; then
    echo -e "${RED}Error: --env=prod flag not recognized${NC}"
    return 1
  fi
  
  # Test components flag
  if ! "$ALFRED_SCRIPT" status --components=core | grep -q "Including components: core"; then
    echo -e "${RED}Error: --components=core flag not recognized${NC}"
    return 1
  fi
  
  if ! "$ALFRED_SCRIPT" status --components=core,agents | grep -q "Including components: core,agents"; then
    echo -e "${RED}Error: --components=core,agents flag not recognized${NC}"
    return 1
  fi
  
  # Test unknown command
  if "$ALFRED_SCRIPT" unknown-command > /dev/null 2>&1; then
    echo -e "${RED}Error: Unknown command should fail${NC}"
    return 1
  fi
  
  echo -e "${GREEN}✓ Argument parsing works${NC}"
  return 0
}

# Function to test network management
function test_network_management() {
  echo -e "${YELLOW}Testing network management...${NC}"

  # Check if script has network creation function
  if ! grep -q "create_network" "$ALFRED_SCRIPT"; then
    echo -e "${RED}Error: alfred.sh does not have network management functions${NC}"
    return 1
  fi

  # Check if script has network removal function
  if ! grep -q "remove_network" "$ALFRED_SCRIPT"; then
    echo -e "${RED}Error: alfred.sh does not have network removal functions${NC}"
    return 1
  fi

  # Test network output by simulating action without taking it
  # Use --help to avoid actual operations but still see output
  if ! "$ALFRED_SCRIPT" help | grep -q "network"; then
    echo -e "${RED}Error: alfred.sh help does not mention networks${NC}"
    return 1
  fi

  echo -e "${GREEN}✓ Network management functions exist${NC}"
  return 0
}

# Main function
function main() {
  echo -e "${BLUE}=== Testing alfred.sh Script ===${NC}"
  
  # Check if alfred.sh exists and is executable
  if [[ ! -x "$ALFRED_SCRIPT" ]]; then
    echo -e "${RED}Error: alfred.sh not found or not executable${NC}"
    exit 1
  fi
  
  # Run tests
  local test_success=true
  
  if ! test_help_command; then
    test_success=false
  fi
  
  if ! test_argument_parsing; then
    test_success=false
  fi
  
  if ! test_network_management; then
    test_success=false
  fi
  
  # Print summary
  if [[ "$test_success" == true ]]; then
    echo -e "\n${GREEN}✓ All alfred.sh script tests passed${NC}"
    exit 0
  else
    echo -e "\n${RED}✗ Some alfred.sh script tests failed${NC}"
    exit 1
  fi
}

# Run main function
main