# BizDev Backlog Status - PAT Required

Date: Sat May 24 12:48:00 UTC 2025

## Summary

To programmatically add the "BizDev Backlog" status option and move issues #398-#402, a Personal Access Token (PAT) with `project` scope is required.

## Script Ready to Execute

The complete GraphQL script is ready and documented. To run it:

```bash
# Set required environment variables
export GH_TOKEN="ghp_your_PAT_with_project_scope"
export PROJECT_ID="PVT_kwHOAWDeVs4A5ubE"

# Run the script from the PR description
```

## What the Script Does

1. Gets the Status field ID for the project
2. Checks if "BizDev Backlog" option exists
3. Creates the option if missing
4. Gets the option ID
5. Moves issues #398-#402 to the BizDev Backlog status

## Current State

- Issues #398-#402 are in the GA v3.0.0 Checklist project
- They are in the Todo column
- They are labeled with `bizdev-sprint`
- The "BizDev Backlog" status option needs to be created

## Manual Alternative

If a PAT is not available, use the GitHub web UI:
1. Go to https://github.com/users/locotoki/projects/3/settings
2. Find the "Status" field
3. Click "Add option"
4. Enter "BizDev Backlog"
5. Save changes
6. Go back to the board view
7. Filter by label:bizdev-sprint
8. Bulk-move issues to BizDev Backlog column
