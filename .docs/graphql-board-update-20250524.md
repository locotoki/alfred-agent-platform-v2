# GraphQL Board Update - BizDev Backlog

Date: Sat May 24 12:11:48 UTC 2025

## Attempted Actions

1. Tried to use GitHub GraphQL API to programmatically add "BizDev Backlog" status option
2. Encountered authentication/permission issues with the GraphQL mutations

## GraphQL Queries Required

### 1. Get Status Field ID
```graphql
query($projectId: ID!) {
  node(id: $projectId) {
    ... on ProjectV2 {
      fields(first: 50) {
        nodes { id name dataType }
      }
    }
  }
}
```

### 2. Create New Status Option
```graphql
mutation($input: CreateProjectV2FieldOptionInput!) {
  createProjectV2FieldOption(input: $input) {
    projectV2FieldOption { id }
  }
}
```

### 3. Update Item Status
```graphql
mutation($input: UpdateProjectV2ItemFieldValueInput!) {
  updateProjectV2ItemFieldValue(input: $input) {
    projectV2Item { id }
  }
}
```

## Requirements

- A Personal Access Token (PAT) with `project` scope
- The token must have write access to the project
- Must use `GH_TOKEN` environment variable, not the default `GITHUB_TOKEN`

## Current State

- Issues #398-#402 are in the GA v3.0.0 Checklist project
- They are in the Todo column
- They are labeled with `bizdev-sprint`
- Manual intervention still required to add the "BizDev Backlog" status option

## Alternative Approach

Use the GitHub web UI:
1. Navigate to the project settings
2. Edit the Status field
3. Add "BizDev Backlog" as a new option
4. Use the project board view to bulk-move issues
