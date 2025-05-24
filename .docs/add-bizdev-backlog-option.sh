#!/bin/bash
# Direct GraphQL mutation to add BizDev Backlog option
# REQUIRES: GH_TOKEN (PAT with project scope)

set -euo pipefail

: "${GH_TOKEN?Need a PAT in GH_TOKEN with project scope}"

export GH_TOKEN

PROJECT_ID="PVT_kwHOAWDeVs4A5ubE"
STATUS_FIELD_ID="PVTSSF_lAHOAWDeVs4A5ubEzgueYhQ"

echo "=== Adding BizDev Backlog Status Option ==="
echo "Project ID: $PROJECT_ID"
echo "Status Field ID: $STATUS_FIELD_ID"
echo ""

# Try to create the option
echo "Attempting to create 'BizDev Backlog' option..."

RESPONSE=$(gh api graphql \
  -F projectId="$PROJECT_ID" \
  -F fieldId="$STATUS_FIELD_ID" \
  -f query='
mutation($projectId: ID!, $fieldId: ID!) {
  createProjectV2FieldOption(
    input: {
      projectId: $projectId
      fieldId: $fieldId
      name: "BizDev Backlog"
    }
  ) {
    projectV2FieldOption {
      id
      name
    }
    errors {
      message
    }
  }
}' 2>&1) || true

echo "Response:"
echo "$RESPONSE" | jq . || echo "$RESPONSE"

# Check if it worked
if echo "$RESPONSE" | jq -e '.data.createProjectV2FieldOption.projectV2FieldOption.id' >/dev/null 2>&1; then
  OPTION_ID=$(echo "$RESPONSE" | jq -r '.data.createProjectV2FieldOption.projectV2FieldOption.id')
  echo ""
  echo "✅ Successfully created 'BizDev Backlog' option with ID: $OPTION_ID"
else
  echo ""
  echo "❌ Failed to create option. This typically means:"
  echo "   - The PAT doesn't have sufficient project permissions"
  echo "   - The option already exists"
  echo "   - Organization settings restrict project modifications"
  echo ""
  echo "Please add the option manually via:"
  echo "https://github.com/users/locotoki/projects/3/settings"
fi
