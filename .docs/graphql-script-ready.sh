#!/bin/bash
# GraphQL Script to Add BizDev Backlog Status and Move Epics
# REQUIRES: GH_TOKEN (PAT with project scope) and PROJECT_ID

set -euo pipefail

: "${GH_TOKEN?Need a PAT in GH_TOKEN with project scope}"
: "${PROJECT_ID?Set PROJECT_ID to the GA v3.0.0 Checklist Project V2 node ID}"

## Ensure gh CLI uses the PAT with project permissions
export GH_TOKEN

## Get the Status field ID
STATUS_FIELD_ID=$(gh api graphql -F projectId=$PROJECT_ID -f query='
  query($projectId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        fields(first: 50) {
          nodes { id name }
        }
      }
    }
  }' --jq '.data.node.fields.nodes[] | select(.name == "Status") | .id')

echo "Status field ID: $STATUS_FIELD_ID"

## Check if "BizDev Backlog" option exists
OPTION_EXISTS=$(gh api graphql -F projectId=$PROJECT_ID -f query='
  query($projectId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        fields(first: 50) {
          nodes {
            ... on ProjectV2SingleSelectField {
              name
              options { name }
            }
          }
        }
      }
    }
  }' --jq '
    .data.node.fields.nodes[]
    | select(.name == "Status")
    | .options[].name' | grep -Fxq "BizDev Backlog" && echo yes || echo no)

echo "BizDev Backlog exists: $OPTION_EXISTS"

## Create the option if missing
if [ "$OPTION_EXISTS" = "no" ]; then
  echo "Creating BizDev Backlog option..."
  gh api graphql -f mutation='
    mutation($project: ID!, $field: ID!) {
      createProjectV2FieldOption(
        input: { projectId: $project, fieldId: $field, name: "BizDev Backlog" }
      ) { projectV2FieldOption { id } }
    }' -F project=$PROJECT_ID -F field=$STATUS_FIELD_ID
fi

## Get the option ID
BACKLOG_OPTION_ID=$(gh api graphql -F projectId=$PROJECT_ID -f query='
  query($projectId: ID!) {
    node(id: $projectId) {
      ... on ProjectV2 {
        fields(first: 50) {
          nodes {
            ... on ProjectV2SingleSelectField {
              name
              options { id name }
            }
          }
        }
      }
    }
  }' --jq '
    .data.node.fields.nodes[]
    | select(.name == "Status")
    | .options[]
    | select(.name == "BizDev Backlog")
    | .id')

echo "BizDev Backlog option ID: $BACKLOG_OPTION_ID"

## Get repo details
REPO_OWNER=$(gh repo view --json owner -q .owner.login)
REPO_NAME=$(gh repo view --json name -q .name)

## Move each issue to BizDev Backlog
for ISSUE in 398 399 400 401 402; do
  echo "Processing issue #$ISSUE..."

  # Get issue node ID
  CONTENT_NODE=$(gh api repos/$REPO_OWNER/$REPO_NAME/issues/$ISSUE --jq .node_id)

  # Get project item ID
  ITEM_ID=$(gh api graphql -F projectId=$PROJECT_ID -F contentId=$CONTENT_NODE -f query='
    query($projectId: ID!, $contentId: ID!) {
      node(id: $projectId) {
        ... on ProjectV2 {
          items(first: 1, contentId: $contentId) {
            nodes { id }
          }
        }
      }
    }' --jq '.data.node.items.nodes[0].id')

  # Update status to BizDev Backlog
  gh api graphql -F project=$PROJECT_ID -F item=$ITEM_ID -F field=$STATUS_FIELD_ID -F option=$BACKLOG_OPTION_ID -f mutation='
    mutation(
      $project: ID!, $item: ID!, $field: ID!, $option: ID!
    ) {
      updateProjectV2ItemFieldValue(
        input: {
          projectId: $project
          itemId: $item
          fieldId: $field
          value: { singleSelectOptionId: $option }
        }
      ) { projectV2Item { id } }
    }'

  echo "Issue #$ISSUE moved to BizDev Backlog"
done

echo "✅ All BizDev epics moved to BizDev Backlog status!"
