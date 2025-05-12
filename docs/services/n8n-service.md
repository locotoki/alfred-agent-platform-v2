# n8n Workflow Automation Service

## Overview

The n8n service provides workflow automation capabilities for the Alfred Agent Platform. It enables the creation, execution, and management of complex workflows that integrate different services and components of the platform. n8n offers a visual workflow builder and an extensive set of pre-built integrations, making it ideal for automating routine tasks and creating event-driven processes.

## Key Features

- **Visual Workflow Builder**: Design workflows using an intuitive UI with nodes and connections
- **Trigger-Based Execution**: Start workflows based on webhooks, schedules, or events
- **Service Integration**: Connect Alfred services with external systems
- **Data Transformation**: Process and format data between different systems
- **Conditional Logic**: Create workflows with branches, loops, and error handling
- **Credentials Management**: Securely store and manage access tokens and credentials
- **Workflow Versioning**: Track changes to workflows over time

## Pre-built Workflows

The Alfred Agent Platform includes several pre-built n8n workflows:

1. **PR Triage Workflow**: Automates code review processes
   - Receives GitHub PR webhook events
   - Extracts PR metadata
   - Triggers CrewAI Code Review crew
   - Notifies team via Slack
   - Tracks review status

2. **Daily Metrics Workflow**: Collects and reports platform metrics
   - Runs on a scheduled basis (daily)
   - Gathers metrics from platform services
   - Formats reports for stakeholders
   - Delivers reports via Slack
   - Archives metrics for historical analysis

## Architecture

The n8n service is designed to operate as a containerized service within the Alfred Agent Platform:

1. **Web UI**: Visual interface for workflow design and management
2. **Execution Engine**: Processes workflow nodes in the correct order
3. **Database**: Stores workflow definitions, execution history, and credentials
4. **API Server**: Provides REST API for programmatic workflow management
5. **Webhook Server**: Listens for incoming webhooks to trigger workflows

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `N8N_BASIC_AUTH_ACTIVE` | Enable basic auth | true |
| `N8N_BASIC_AUTH_USER` | Basic auth username | admin |
| `N8N_BASIC_AUTH_PASSWORD` | Basic auth password | alfred123 |
| `N8N_HOST` | Host to listen on | localhost |
| `N8N_PORT` | Port to listen on | 5678 |
| `N8N_PROTOCOL` | Protocol (http/https) | http |
| `N8N_LOG_LEVEL` | Logging level | info |
| `N8N_METRICS` | Enable metrics | true |
| `N8N_METRICS_PORT` | Metrics port | 5679 |
| `ALFRED_CREWAI_URL` | URL for CrewAI service | http://crewai-service:9004 |
| `ALFRED_RAG_URL` | URL for RAG Gateway | http://agent-rag:8501 |
| `ALFRED_CORE_URL` | URL for Alfred Core | http://agent-core:8011 |
| `ALFRED_API_KEY` | API key for Alfred services | (configured at runtime) |

## Docker Image

The n8n service is packaged as a Docker container with the following specifications:

- Base Image: `n8nio/n8n:latest`
- Exposed Ports: 5500 (Web UI), 5679 (Metrics)
- Health Check: `curl -f http://localhost:5678/healthz`
- Volume Mount: `/home/node/.n8n` for persistent data
- Workflow Mount: `/home/node/workflows` for workflow definitions

## Web Interface

The n8n web interface is accessible at:
```
http://localhost:5500
```

The interface provides:

- **Workflow Editor**: Visual editor for creating and modifying workflows
- **Workflow List**: Overview of all defined workflows
- **Execution History**: Log of workflow executions and results
- **Credentials**: Management of stored credentials
- **Settings**: Configuration of n8n behavior and features

## Integration Points

n8n integrates with the Alfred Agent Platform services through:

1. **HTTP Requests**: Direct API calls to services
2. **Webhooks**: Receiving event notifications
3. **Environment Variables**: Accessing configuration
4. **Shared Database**: Storing workflow results in platform database

## Creating Custom Workflows

1. **Design the Workflow**:
   - Access the n8n web interface
   - Create a new workflow
   - Add trigger nodes (HTTP webhook, Schedule, etc.)
   - Add action nodes (HTTP requests, data transformation, etc.)
   - Connect nodes to create the workflow logic
   - Configure error handling

2. **Test the Workflow**:
   - Use the Execute Workflow button to test
   - Review execution results
   - Debug and refine as needed

3. **Deploy the Workflow**:
   - Set the workflow to active
   - Configure production credentials
   - Export the workflow JSON for version control

4. **Monitor and Maintain**:
   - Check execution history
   - Set up error notifications
   - Update workflows as requirements change

## Security Considerations

- **Credentials**: All credentials are stored encrypted
- **Authentication**: Web UI is protected with basic auth
- **API Keys**: Service API keys are stored as credentials
- **Execution Isolation**: Workflows run in isolated contexts
- **Audit Trail**: All executions are logged for review

## Backup and Recovery

Workflow definitions and credentials are stored in:

1. **Database**: PostgreSQL database shared with platform
2. **Exported Files**: JSON workflow definitions in version control

To backup:
- Export workflows through UI or API
- Include database in platform backup procedures

To restore:
- Import workflow definitions
- Restore database from backup

## Troubleshooting

Common issues and resolutions:

| Issue | Resolution |
|-------|------------|
| Workflow fails to start | Check trigger configuration and permissions |
| HTTP request errors | Verify service URLs and credentials |
| Webhook not triggering | Confirm webhook URL is accessible |
| Credentials not working | Update or recreate credential entries |
| Data transformation errors | Check input data format and transformation logic |