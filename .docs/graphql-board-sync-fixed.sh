#!/bin/bash
# Fixed GraphQL Script to Add BizDev Backlog Status and Move Epics
# REQUIRES: GH_TOKEN (PAT with project scope) and PROJECT_ID

set -euo pipefail

: "${GH_TOKEN?Need a PAT in GH_TOKEN with project scope}"
: "${PROJECT_ID?Set PROJECT_ID to the GA v3.0.0 Checklist Project V2 node ID}"

## Ensure gh CLI uses the PAT with project permissions
export GH_TOKEN

echo "Using Project ID: $PROJECT_ID"

## Get all fields and find Status field
echo "Getting Status field ID..."
FIELDS_RESPONSE=$(gh api graphql -F projectId=$PROJECT_ID -f query='
  query($projectId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        fields(first: 50) {
          nodes {
            __typename
            id
            name
            ... on ProjectV2SingleSelectField {
              options {
                id
                name
              }
            }
          }
        }
      }
    }
  }')

echo "Fields response received"

## Find Status field ID
STATUS_FIELD_ID=$(echo "$FIELDS_RESPONSE" | jq -r '
  .data.node.fields.nodes[]
  | select(.name == "Status" and .__typename == "ProjectV2SingleSelectField")
  | .id')

if [ -z "$STATUS_FIELD_ID" ]; then
  echo "Error: Could not find Status field"
  exit 1
fi

echo "Status field ID: $STATUS_FIELD_ID"

## Check if BizDev Backlog exists
BACKLOG_OPTION_ID=$(echo "$FIELDS_RESPONSE" | jq -r '
  .data.node.fields.nodes[]
  | select(.name == "Status" and .__typename == "ProjectV2SingleSelectField")
  | .options[]
  | select(.name == "BizDev Backlog")
  | .id')

if [ -z "$BACKLOG_OPTION_ID" ]; then
  echo "Creating BizDev Backlog option..."

  CREATE_RESPONSE=$(gh api graphql -f mutation='
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
      }
    }' -F projectId=$PROJECT_ID -F fieldId=$STATUS_FIELD_ID)

  BACKLOG_OPTION_ID=$(echo "$CREATE_RESPONSE" | jq -r '.data.createProjectV2FieldOption.projectV2FieldOption.id')
  echo "Created BizDev Backlog with ID: $BACKLOG_OPTION_ID"
else
  echo "BizDev Backlog already exists with ID: $BACKLOG_OPTION_ID"
fi

## Get repo details
REPO_OWNER=$(gh repo view --json owner -q .owner.login)
REPO_NAME=$(gh repo view --json name -q .name)

echo "Repository: $REPO_OWNER/$REPO_NAME"

## Move each issue to BizDev Backlog
for ISSUE in 398 399 400 401 402; do
  echo ""
  echo "Processing issue #$ISSUE..."

  # Get issue node ID
  ISSUE_RESPONSE=$(gh api repos/$REPO_OWNER/$REPO_NAME/issues/$ISSUE)
  CONTENT_NODE=$(echo "$ISSUE_RESPONSE" | jq -r .node_id)

  echo "  Issue node ID: $CONTENT_NODE"

  # Get project item ID
  ITEM_RESPONSE=$(gh api graphql -F projectId=$PROJECT_ID -F contentId=$CONTENT_NODE -f query='
    query($projectId: ID!, $contentId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 10, after: null) {
            nodes {
              id
              content {
                ... on Issue {
                  id
                }
              }
            }
          }
        }
      }
    }')

  ITEM_ID=$(echo "$ITEM_RESPONSE" | jq -r --arg contentId "$CONTENT_NODE" '
    .data.node.items.nodes[]
    | select(.content.id == $contentId)
    | .id')

  if [ -z "$ITEM_ID" ]; then
    echo "  ⚠️  Issue #$ISSUE not found in project, skipping..."
    continue
  fi

  echo "  Project item ID: $ITEM_ID"

  # Update status to BizDev Backlog
  UPDATE_RESPONSE=$(gh api graphql -F projectId=$PROJECT_ID -F itemId=$ITEM_ID -F fieldId=$STATUS_FIELD_ID -F optionId=$BACKLOG_OPTION_ID -f mutation='
    mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
      updateProjectV2ItemFieldValue(
        input: {
          projectId: $projectId
          itemId: $itemId
          fieldId: $fieldId
          value: {
            singleSelectOptionId: $optionId
          }
        }
      ) {
        projectV2Item {
          id
        }
      }
    }')

  echo "  ✅ Issue #$ISSUE moved to BizDev Backlog"
done

echo ""
echo "✅ Board sync complete! All BizDev epics processed."
