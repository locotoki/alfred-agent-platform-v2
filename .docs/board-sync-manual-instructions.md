# BizDev Backlog Board Sync - Manual Instructions

## Current Status

The automated board sync script cannot complete due to GitHub API limitations:
- The `createProjectV2FieldOption` mutation is not available in the current API
- GitHub CLI doesn't support adding project field options
- The GHCR_PAT has project permissions but cannot modify field options programmatically

## Issues to Move

The following BizDev epic issues need to be moved to "BizDev Backlog" status:
- #398: Epic 401: BizDev MVP
- #399: Epic 402: BizDev MVP
- #400: Epic 403: BizDev MVP
- #401: Epic 404: BizDev MVP
- #402: Epic 405: BizDev MVP

All issues are already added to the GA v3.0.0 Checklist project but have no status assigned.

## Manual Steps Required

### 1. Add "BizDev Backlog" Status Option

1. Navigate to: https://github.com/users/locotoki/projects/3/settings
2. Find the "Status" field in the Fields section
3. Click "Edit" on the Status field
4. Add a new option: "BizDev Backlog"
5. Save the changes

### 2. Move Issues to BizDev Backlog

Option A - Via Project Board:
1. Go to: https://github.com/users/locotoki/projects/3
2. Find issues #398-#402 (they should be in the "No Status" section)
3. Drag each issue to the "BizDev Backlog" column

Option B - Via Issue Page:
1. Open each issue (#398-#402)
2. In the right sidebar, find "GA v3.0.0 Checklist" project
3. Change Status from "No Status" to "BizDev Backlog"

## Automation Attempts

We attempted several approaches:
1. GraphQL mutations with PAT - API doesn't support field option creation
2. GitHub CLI project commands - No support for field option management
3. Direct API calls - Same limitations as GraphQL

## Conclusion

Due to GitHub's current API limitations, adding new project field options must be done through the web UI. This is a one-time manual action that takes about 2 minutes to complete.
