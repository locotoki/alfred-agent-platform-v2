#!/bin/bash
#
# Run all tests
# This script runs all test scripts in sequence
#

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directory with test scripts
TEST_DIR="/home/locotoki/projects/alfred-agent-platform-v2/refactor-unified/tests"

# Array of test scripts to run
TEST_SCRIPTS=(
  "validate-compose.sh"
  "test-alfred-script.sh"
  "test-service-health.sh"
  "validate-core-services.sh"
)

# Function to run a test script
function run_test() {
  local script=$1
  echo -e "\n${BLUE}=== Running $script ===${NC}"
  
  # Check if script exists and is executable
  if [[ ! -x "$TEST_DIR/$script" ]]; then
    echo -e "${RED}Error: $script not found or not executable${NC}"
    return 1
  fi
  
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
  echo -e "${BLUE}=== Running All Tests ===${NC}"
  
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
  echo -e "Passed: $passed"
  echo -e "Failed: $failed"
  
  if [[ "$failed" -gt 0 ]]; then
    echo -e "\n${RED}Failed tests:${NC}"
    for test in "${failed_tests[@]}"; do
      echo -e "- $test"
    done
    exit 1
  else
    echo -e "\n${GREEN}✓ All tests passed${NC}"
    exit 0
  fi
}

# Run main function
main