#!/bin/bash
#
# Alfred Agent Platform v2 - Run All Tests
# This script runs all tests for the platform
#

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directory with test scripts
TEST_DIR="$(dirname "$0")"

# Array of test scripts to run
TEST_SCRIPTS=(
  "validate-core-services.sh"
  "test-service-health.sh"
  "test-alfred-script.sh"
  # Uncomment to run the complete system test
  # "test-complete-system.sh"
)

# Display ASCII art banner
function print_banner() {
  echo -e "${BLUE}"
  echo "    _    _  __               _   "
  echo "   / \  | |/ _|_ __ ___  __| |  "
  echo "  / _ \ | | |_| '__/ _ \/ _\` |  "
  echo " / ___ \| |  _| | |  __/ (_| |  "
  echo "/_/   \_\_|_| |_|  \___|\__,_|  "
  echo "                               "
  echo " Agent Platform v2 - Test Suite"
  echo -e "${NC}"
}

# Function to run a test script
function run_test() {
  local script=$1
  echo -e "\n${BLUE}=== Running $script ===${NC}"
  
  # Check if script exists and is executable
  if [[ ! -f "$TEST_DIR/$script" ]]; then
    echo -e "${RED}Error: $script not found${NC}"
    return 1
  fi
  
  # Make sure the script is executable
  chmod +x "$TEST_DIR/$script"
  
  # Run the script
  if ! "$TEST_DIR/$script"; then
    echo -e "${RED}✗ $script failed${NC}"
    return 1
  fi
  
  echo -e "${GREEN}✓ $script passed${NC}"
  return 0
}

# Main function
function main() {
  print_banner
  echo -e "${YELLOW}Running All Tests${NC}"
  
  # Track results
  local passed=0
  local failed=0
  local failed_tests=()
  
  # Run each test script
  for script in "${TEST_SCRIPTS[@]}"; do
    if run_test "$script"; then
      ((passed++))
    else
      ((failed++))
      failed_tests+=("$script")
    fi
  done
  
  # Print summary
  echo -e "\n${BLUE}=== Test Summary ===${NC}"
  echo -e "Total tests: $((passed + failed))"
  echo -e "Passed: ${GREEN}$passed${NC}"
  echo -e "Failed: ${RED}$failed${NC}"
  
  if [[ "$failed" -gt 0 ]]; then
    echo -e "\n${RED}Failed tests:${NC}"
    for test in "${failed_tests[@]}"; do
      echo -e "${RED}- $test${NC}"
    done
    exit 1
  else
    echo -e "\n${GREEN}✓ All tests passed${NC}"
    exit 0
  fi
}

# Run main function
main