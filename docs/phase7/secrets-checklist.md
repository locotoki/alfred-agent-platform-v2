# Phase 7 Secrets Configuration Checklist

Use this checklist to verify that all required secrets for Phase 7 are properly configured.

## GitHub Actions Secrets

### Staging Environment

- [ ] `SLACK_BOT_TOKEN` - From Slack App → OAuth & Permissions
  - Value format: `xoxb-...`
  - Permission scopes: `channels:history`, `channels:read`, `chat:write`, `commands`

- [ ] `SLACK_APP_TOKEN` - From Slack App → Basic Information → App-Level Tokens
  - Value format: `xapp-...`
  - Permission scope: `connections:write`

- [ ] `SLACK_SIGNING_SECRET` - From Slack App → Basic Information
  - Value format: Alphanumeric string

### Production Environment

- [ ] `CREWAI_ENDPOINT_PROD` - Production endpoint
  - Value: `https://crewai.prod.internal`

- [ ] `CREWAI_A2A_CLIENT_ID` - From GCP Workload Identity Pool
  - Value format: Client ID from GCP

- [ ] `CREWAI_A2A_CLIENT_SECRET` - From GCP A2A credentials
  - Value format: Client secret from GCP

## Environment Protection

- [ ] Production environment has "Required reviewers" enabled
- [ ] Appropriate team members are added as required reviewers

## Branch Protection

- [ ] Main branch requires status checks to pass before merging
- [ ] "orchestration-integration" is added as a required status check

## Slack App Configuration

- [ ] Socket Mode is enabled in Slack App settings
- [ ] Event subscriptions are configured
- [ ] Interactive Components are enabled
- [ ] Slash command `/alfred` is registered

## Verification Steps

1. Create a test PR to verify CI pipeline works correctly
2. Check that the slack-smoke job passes
3. Verify that secrets are not exposed in build logs
4. Confirm orchestration-integration job completes successfully
5. Ensure production deployment job has access to all required secrets