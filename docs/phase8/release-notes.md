# Release Notes - Phase 8

## [0.8.4] - 2025-05-17

### Added
- Alert Explanation Agent for Phase 8.2
- `/diag explain` command for alert explanations
- LangChain integration for AI-powered explanations
- Proper Slack release notifications via webhook
- GitHub Actions workflow for automated release announcements

### Fixed
- Type checking errors in diagnostics bot
- Test fixture paths and schemas
- Trivy security scan warnings
- Release notification script now sends actual Slack messages instead of logging

### Configuration
- Added `SLACK_RELEASE_WEBHOOK` secret for release announcements
- Webhook points to #releases channel for deployment notifications

### Setup Instructions

To enable Slack release notifications:

1. Get the webhook URL for your #releases channel in Slack
2. Add it as a GitHub repository secret:
   ```bash
   gh secret set SLACK_RELEASE_WEBHOOK -b "<webhook-url>"
   ```
3. Test the workflow:
   ```bash
   gh workflow run release.yml -f ref=main
   ```
4. Check that logs contain "Sending to Slack:" (not dry-run)
5. Verify the message appears in #releases channel

### Deployment
- Tagged as v0.8.4
- Includes all Phase 8.2 features
- Ready for staging deployment

## [0.8.3] - 2025-05-16

### Added
- Phase 8.1 completion with full type hinting
- Namespace hygiene improvements
- CI/CD optimizations

### Fixed
- mypy strict mode compliance
- Import sorting consistency
- Health check endpoints

### Changed
- Moved to alfred.* namespace structure
- Updated all imports to use new namespace
- Standardized logging with structlog