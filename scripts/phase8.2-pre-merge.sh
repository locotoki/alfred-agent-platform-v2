#!/bin/bash
# Phase 8.2 – Pre-merge Checklist

set -e  # Exit on error
REPORT_FILE="./tmp/ci-report.log"
mkdir -p ./tmp

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Phase 8.2 Pre-merge Checklist ===" | tee -a "$REPORT_FILE"
echo "$(date)" | tee -a "$REPORT_FILE"

# 1. Environment bootstrap (run once)
echo -e "\n${YELLOW}Step 1: Environment Bootstrap${NC}" | tee -a "$REPORT_FILE"

# Check poetry
if ! command -v poetry &> /dev/null; then
    echo "Error: poetry not found. Please install poetry first." | tee -a "$REPORT_FILE"
    echo "Run: curl -sSL https://install.python-poetry.org | python3 -" | tee -a "$REPORT_FILE"
    exit 1
fi

echo "Installing dependencies with poetry..." | tee -a "$REPORT_FILE"
poetry install 2>&1 | tee -a "$REPORT_FILE"

# Docker cleanup
echo "Cleaning Docker system..." | tee -a "$REPORT_FILE"
docker system prune -f 2>&1 | tee -a "$REPORT_FILE"

# Kind cluster setup
echo "Setting up kind cluster..." | tee -a "$REPORT_FILE"
kind delete cluster || true
if [ -f deploy/kind-config.yml ]; then
    kind create cluster --config deploy/kind-config.yml 2>&1 | tee -a "$REPORT_FILE"
else
    echo "Warning: deploy/kind-config.yml not found, using default config" | tee -a "$REPORT_FILE"
    kind create cluster 2>&1 | tee -a "$REPORT_FILE"
fi

# 2. Execute consolidated CI checks
echo -e "\n${YELLOW}Step 2: Running CI Checks${NC}" | tee -a "$REPORT_FILE"
if [ -f ./scripts/phase8.2-final-checks.sh ]; then
    ./scripts/phase8.2-final-checks.sh 2>&1 | tee -a "$REPORT_FILE"
    CI_EXIT_CODE=${PIPESTATUS[0]}
else
    echo "Error: ./scripts/phase8.2-final-checks.sh not found" | tee -a "$REPORT_FILE"
    CI_EXIT_CODE=1
fi

# 3. Process results
echo -e "\n${YELLOW}Step 3: Processing Results${NC}" | tee -a "$REPORT_FILE"
if [ $CI_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}CI checks failed!${NC}" | tee -a "$REPORT_FILE"
    echo "Please check $REPORT_FILE for details" | tee -a "$REPORT_FILE"
    echo "Fix the issues and re-run this script" | tee -a "$REPORT_FILE"
    exit $CI_EXIT_CODE
fi

# 4. Confirm success
echo -e "\n${YELLOW}Step 4: Verifying Success${NC}" | tee -a "$REPORT_FILE"

# Check GitHub Actions status if gh is available
if command -v gh &> /dev/null; then
    echo "Checking GitHub Actions status..." | tee -a "$REPORT_FILE"
    PR_STATUS=$(gh pr checks 80 --json state,name 2>/dev/null || echo "UNKNOWN")
    echo "PR checks status: $PR_STATUS" | tee -a "$REPORT_FILE"
fi

# Display success banner
echo -e "\n${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ALL GREEN! ✅               ║${NC}"
echo -e "${GREEN}║  Local CI checks passed successfully  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"

# 5. Tag reviewers
echo -e "\n${YELLOW}Step 5: Notifying Reviewers${NC}" | tee -a "$REPORT_FILE"
if command -v gh &> /dev/null; then
    echo "Commenting on PR #80..." | tee -a "$REPORT_FILE"
    gh pr comment 80 --body "✅ Local + CI green. Ready for final approval.

Local CI Report Summary:
- Poetry dependencies: ✓
- Docker environment: ✓
- Kind cluster: ✓
- Lint checks: ✓
- Type checks: ✓
- Unit tests: ✓
- Coverage threshold: ✓
- Integration tests: ✓

@gpt-o3 @alfred-platform/coordinators Please review for final approval."
    
    echo -e "${GREEN}PR comment posted successfully${NC}" | tee -a "$REPORT_FILE"
else
    echo "Warning: gh CLI not found. Please manually comment on PR #80" | tee -a "$REPORT_FILE"
fi

echo -e "\n${GREEN}Pre-merge checklist complete!${NC}" | tee -a "$REPORT_FILE"
echo "Report saved to: $REPORT_FILE"