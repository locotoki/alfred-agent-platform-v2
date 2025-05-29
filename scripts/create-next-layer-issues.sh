#!/usr/bin/env bash
set -euo pipefail

# Configuration
repo="Digital-Native-Ventures/alfred-agent-platform-v2"
project="Next Layer Improvements"
milestone="Operational Excellence"

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}Creating Next Layer Improvement Issues...${NC}\n"

# Define issues with labels
declare -A issues=(
    ["Operational Safety: Automated Backup/Restore for Postgres + MinIO + Redis"]="enhancement,operations"
    ["Resilience Testing: Chaos Engineering for Staging Environment"]="enhancement,testing"
    ["Resource Governance: CPU/Memory Limits for All Services"]="enhancement,performance"
    ["Service Quality: OpenTelemetry Tracing Implementation"]="enhancement,observability"
    ["Developer Velocity: Live Reload Development Environment"]="enhancement,developer-experience"
)

# Create issues
for title in "${!issues[@]}"; do
    labels="${issues[$title]}"
    
    # Extract the main category for the description
    category=$(echo "$title" | cut -d: -f1)
    
    # Create issue with detailed description
    description="## $category

Implement the next layer improvement as documented in docs/operational/NEXT-LAYER-IMPROVEMENTS.md

### Acceptance Criteria
- [ ] Implementation follows the documented plan
- [ ] Tests are included
- [ ] Documentation is updated
- [ ] Success metrics are defined

### References
- [Next Layer Improvements Plan](../docs/operational/NEXT-LAYER-IMPROVEMENTS.md#$(echo $category | tr '[:upper:]' '[:lower:]' | tr ' ' '-'))
- [Baseline Stabilization](../docs/operational/BASELINE-STABILIZATION-PLAN.md)"

    num=$(gh issue create --repo "$repo" \
        --title "$title" \
        --body "$description" \
        --label "$labels" \
        --milestone "$milestone" \
        --json number -q '.number' 2>/dev/null || echo "")
    
    if [ -n "$num" ]; then
        # Add to project board
        gh project item-add "$project" --issue "$num" 2>/dev/null || true
        echo -e "${GREEN}✓${NC} Created #$num - $title"
    else
        echo -e "❌ Failed to create issue: $title"
    fi
done

echo -e "\n${BLUE}Creating Epic Issue...${NC}"

# Create epic issue linking all improvements
epic_body="# Next Layer Improvements Epic

Following successful repository cleanup and baseline stabilization, these improvements focus on operational excellence, resilience, and developer productivity.

## Improvement Areas

### 1. 🛡️ Operational Safety
Automated backup and restore capabilities for all stateful services.

### 2. 💥 Resilience Testing  
Chaos engineering to validate health checks and recovery mechanisms.

### 3. 📊 Resource Governance
CPU and memory limits to prevent resource starvation.

### 4. 🔍 Service Quality
OpenTelemetry tracing for performance insights.

### 5. 🚀 Developer Velocity
Live reload development environment for instant feedback.

## Documentation
- [Full Implementation Plan](../docs/operational/NEXT-LAYER-IMPROVEMENTS.md)
- [Baseline Stabilization](../docs/operational/BASELINE-STABILIZATION-PLAN.md)

## Success Criteria
- [ ] All 5 improvement areas implemented
- [ ] Metrics dashboard showing improvements
- [ ] Team trained on new capabilities
- [ ] Documentation complete"

epic_num=$(gh issue create --repo "$repo" \
    --title "Epic: Next Layer Improvements (Post-Stabilization)" \
    --body "$epic_body" \
    --label "epic,enhancement" \
    --milestone "$milestone" \
    --json number -q '.number' 2>/dev/null || echo "")

if [ -n "$epic_num" ]; then
    echo -e "${GREEN}✓${NC} Created Epic #$epic_num"
else
    echo -e "❌ Failed to create epic issue"
fi

echo -e "\n${GREEN}Done!${NC} Next Layer Improvement issues created."
echo -e "View the project board: https://github.com/${repo}/projects"