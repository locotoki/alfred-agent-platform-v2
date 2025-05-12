# Testing the CrewAI Integration

This document provides instructions for testing the CrewAI and n8n integration with the Alfred Agent Platform.

## Prerequisites

- Alfred Agent Platform running (core services)
- CrewAI and n8n services deployed
- API keys and environment variables configured

## Starting the Services

Use the Makefile target to start the CrewAI and n8n services:

```bash
make up-crewai-n8n
```

This will start both the CrewAI service and the n8n workflow automation service.

## Testing CrewAI Service

### Testing the API Endpoints

The CrewAI service exposes several API endpoints:

1. Health check:
   ```bash
   curl http://localhost:9004/health
   ```

2. List available crews:
   ```bash
   curl http://localhost:9004/crews
   ```

3. Submit a task to a specific crew:
   ```bash
   curl -X POST http://localhost:9004/crews/research/tasks \
     -H "Content-Type: application/json" \
     -d '{
       "task_id": "test-123",
       "tenant_id": "test",
       "content": {
         "objective": "Research the benefits of microservices architecture",
         "process_type": "sequential"
       }
     }'
   ```

4. Check task status:
   ```bash
   curl http://localhost:9004/tasks/test-123
   ```

5. Get metrics summary:
   ```bash
   curl http://localhost:9004/metrics/summary
   ```

### Using the Test Scripts

We've provided test scripts to help verify the integration:

1. Test submitting a task to a crew:
   ```bash
   python test_crew_task.py [crew_type] [base_url]
   ```
   Default values: `crew_type=research`, `base_url=http://localhost:9004`

2. Test the metrics API:
   ```bash
   python test_metrics.py [base_url]
   ```
   Default value: `base_url=http://localhost:9004`

## Testing n8n Integration

### Accessing n8n

The n8n web interface is available at:
```
http://localhost:5500
```

Login credentials:
- Username: admin (or as configured in the environment)
- Password: alfred123 (or as configured in the environment)

### Testing Workflows

The following workflows are available in n8n:

1. **PR Triage Workflow** - Triggers an AI code review when a PR is opened
   - To test, use the webhook URL from n8n to simulate a GitHub webhook event

2. **Daily Metrics Workflow** - Gathers and reports platform metrics
   - To test, manually trigger the workflow from the n8n interface

### Using Curl to Test the PR Triage Webhook

1. Get the webhook URL from n8n's PR Triage Workflow
2. Send a test payload:

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

## Troubleshooting

### CrewAI Service Issues

- Check the logs:
  ```bash
  docker logs crewai-service
  ```
  
- Verify environment variables:
  ```bash
  docker exec crewai-service env | grep ALFRED
  ```

### n8n Issues

- Check the logs:
  ```bash
  docker logs workflow-n8n
  ```

- Verify n8n is connected to the database:
  ```bash
  docker exec workflow-n8n nc -vz db-postgres 5432
  ```

- Ensure the API keys are correctly set up in n8n credentials