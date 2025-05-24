# Board Update - BizDev Backlog

Date: Sat May 24 12:04:48 UTC 2025

## Actions Taken

1. Added the following BizDev epic issues to the GA v3.0.0 Checklist project:
   - #398: Epic 401: BizDev MVP
   - #399: Epic 402: BizDev MVP
   - #400: Epic 403: BizDev MVP
   - #401: Epic 404: BizDev MVP
   - #402: Epic 405: BizDev MVP

2. All issues have been labeled with `bizdev-sprint` for easy filtering.

3. Note: GitHub Projects V2 does not support dynamically adding new status options via CLI.
   To create a "BizDev Backlog" column, a project maintainer needs to:
   - Go to the project settings
   - Edit the Status field
   - Add a new option called "BizDev Backlog"

## Current State

- Issues are now in the project's default "Todo" column
- They can be filtered using the `bizdev-sprint` label
- Once the "BizDev Backlog" status option is added, they can be moved there

## Recommendation

Use the GitHub web UI to add the "BizDev Backlog" option to the Status field,
then bulk-move all issues with the `bizdev-sprint` label to that column.
