# CI: Add Slack Smoke Job & Prod CrewAI Env Secrets

## Summary
This PR unblocks Phase 7 by adding the necessary CI/CD configurations:
- Added Slack smoke test job with proper environment configuration
- Added environment specifications for prod deployment with CrewAI credentials
- Created test scaffolding for Slack integration tests

## Changes
- Created `.github/workflows/main.yml` with proper environment configurations
- Added scaffolding for Slack smoke tests
- Added validation script for GitHub Secrets

## CI Gates
- [x] Lint
- [x] Tests
- [x] Smoke Health
- [x] OTEL Smoke
- [x] Orchestration Integration
- [x] Image Build/Scan
- [x] Template Lint

## Manual Steps Required
Before merging this PR, a repository maintainer must add the following secrets in the GitHub UI:

### Staging Environment
- `SLACK_APP_TOKEN` - From Slack → Basic Info → App-Level Token (connections:write)
- `SLACK_SIGNING_SECRET` - From Slack → Basic Info → Signing Secret

### Prod Environment 
- `CREWAI_ENDPOINT_PROD` - Set to https://crewai.prod.internal
- `CREWAI_A2A_CLIENT_ID` - From GCP Workload Identity Pool
- `CREWAI_A2A_CLIENT_SECRET` - From GCP for A2A client

The prod environment should be configured with required reviewers to protect these secrets.

## Branch Protection Update
After merging, add orchestration-integration to "Required status checks" in the branch protection settings.