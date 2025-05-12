# n8n Workflows for Alfred Agent Platform

This directory contains n8n workflow definitions for the Alfred Agent Platform.

## Available Workflows

### PR Triage Workflow

The PR Triage workflow automates code review for GitHub pull requests:

1. Listens for GitHub webhook events on PR open/update
2. Extracts PR information and metadata
3. Submits the PR to the CrewAI Code Review crew for analysis
4. Posts a notification to Slack when the review is queued
5. Returns a response to the webhook caller

To use this workflow:
- Configure a GitHub webhook pointing to the n8n webhook URL
- Set up Slack credentials in n8n

### Daily Metrics Workflow

The Daily Metrics workflow collects platform metrics and reports them:

1. Runs on a daily schedule (9:00 AM by default)
2. Fetches metrics from the Alfred Platform core services
3. Fetches metrics from the CrewAI service
4. Processes and formats the metrics data
5. Posts a report to Slack
6. Stores the metrics in the platform's metrics database

To use this workflow:
- Set up Slack credentials in n8n
- Ensure the Alfred API key environment variable is configured

## Setup Instructions

1. Import the workflow JSON files into your n8n instance
2. Configure the environment variables in n8n:
   - `ALFRED_CREWAI_URL`: URL of the CrewAI service
   - `ALFRED_RAG_URL`: URL of the RAG Gateway
   - `ALFRED_CORE_URL`: URL of the Alfred Core service
   - `ALFRED_API_KEY`: API key for Alfred services

3. Set up credentials in n8n:
   - Slack OAuth2 API credentials
   - HTTP Basic Auth credentials (if needed)

## Testing the Workflows

### Testing PR Triage Workflow:

Send a POST request to the workflow's webhook URL with a GitHub PR payload:

```bash
curl -X POST http://localhost:5500/webhook/github-webhook \
  -H "Content-Type: application/json" \
  -H "X-GitHub-Event: pull_request" \
  -d '{
    "action": "opened",
    "number": 123,
    "pull_request": {
      "title": "Add new feature",
      "body": "This PR adds a great new feature",
      "html_url": "https://github.com/owner/repo/pull/123",
      "user": {
        "login": "username",
        "name": "User Name"
      },
      "head": {
        "ref": "feature-branch"
      },
      "base": {
        "ref": "main"
      },
      "additions": 100,
      "deletions": 50,
      "changed_files": 3,
      "created_at": "2023-05-10T12:00:00Z",
      "updated_at": "2023-05-10T12:00:00Z"
    },
    "repository": {
      "full_name": "owner/repo"
    }
  }'
```

### Testing Daily Metrics Workflow:

Manually trigger the workflow from the n8n web interface.

## Customizing Workflows

- Edit the workflow in the n8n web interface
- Adjust schedule times, query parameters, or Slack formatting
- Add additional nodes for more integrations (email, ticketing systems, etc.)
- Update the workflow JSON files in this directory after making changes