<!-- ARCHITECT PROMPT: You are an AI architect.  
Generate a task breakdown from the planning bullets below.  
Return a markdown table with columns: | Status | ID | File | Description |.  
Use [ ] for unchecked tasks and [x] for completed ones. -->

## Planning bullets
- Fix task-ticker trigger (remove branches-ignore: [main])
- Deploy architect_review.yml auto-merge workflow to main

| Status | ID  | File                        | Description                                           |
|--------|-----|-----------------------------|-------------------------------------------------------|
| [ ]    | 001 | PR #710                     | Enable optional E2E & perf-stress jobs                |
| [ ]    | 002 | PR #710                     | Make flake-detector a required gate                   |
| [ ]    | 003 | Issue #695                  | Kick-off Dependabot + weekly Trivy automation         |
| [ ]    | 004 | Migrate_Slack_Adapter.md    | Migrate Slack adapter from ngrok to Cloudflare Tunnel |
| [ ]    | 005 | Slack_Manifest_Update.md    | Update Slack manifest for Cloudflare Tunnel migration |
| [ ]    | 006 | Issue #697                  | Begin BizDev agent scaffold                           |