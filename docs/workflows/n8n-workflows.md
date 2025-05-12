# n8n Workflows

## Overview

The Alfred Agent Platform utilizes n8n for workflow automation, enabling the integration of various platform services and external systems. n8n workflows are visual, event-driven processes that define how data and actions flow between different components of the system.

## Standard n8n Workflows

### PR Triage Workflow

**Purpose:** Automate the code review process for GitHub pull requests.

**Trigger:** GitHub webhook event (pull_request action)

**Components:**
- GitHub Webhook node - Receives PR events
- PR Event Check node - Filters for relevant PR events
- Extract PR Info node - Extracts key data from the PR payload
- Trigger CrewAI Review node - Sends PR to CrewAI code review crew
- Format Response node - Processes the CrewAI response
- Slack Notification node - Notifies team about review status
- Webhook Response node - Responds to the GitHub webhook

**Data Flow:**
1. GitHub sends a webhook when a PR is opened or updated
2. The workflow validates it's a PR event
3. Key PR information is extracted (repo, branch, author, etc.)
4. The CrewAI code review crew is triggered with PR details
5. Review status is sent to Slack
6. A confirmation response is sent back to GitHub

**Configuration:**
- Requires GitHub webhook setup in the repository settings
- Needs Slack credentials configured in n8n
- Uses the CrewAI service URL from environment variables

**Customization Options:**
- Modify PR filtering criteria (e.g., only certain repositories)
- Adjust which data is sent to the code review crew
- Change notification formatting or destination
- Add additional steps like PR labeling or assignment

### Daily Metrics Workflow

**Purpose:** Collect and report platform metrics on a daily basis.

**Trigger:** Schedule (daily at 9:00 AM)

**Components:**
- Schedule node - Triggers the workflow daily
- Prepare Date Range node - Formats date ranges for queries
- Get Platform Metrics node - Retrieves metrics from core services
- Get CrewAI Metrics node - Retrieves metrics from CrewAI service
- Process Metrics node - Combines and processes metrics data
- Format Slack Message node - Creates a formatted Slack message
- Send to Slack node - Delivers the metrics report
- Store Metrics node - Archives metrics in the platform database

**Data Flow:**
1. The workflow triggers at the scheduled time
2. Date ranges are calculated for the reporting period
3. Metrics are gathered from platform and CrewAI services
4. Metrics are processed and combined
5. A formatted report is created
6. The report is sent to Slack
7. Metrics are stored for historical analysis

**Configuration:**
- Requires Slack credentials configured in n8n
- Uses service URLs from environment variables
- Requires API key authentication for metrics endpoints

**Customization Options:**
- Change schedule frequency or timing
- Modify metrics collection (additional data sources)
- Adjust report formatting or destination
- Add email delivery or other notification methods
- Customize metrics storage format or location

## Creating Custom Workflows

### Workflow Development Process

1. **Planning:**
   - Define workflow objective and trigger
   - Identify required data and services
   - Map out the data flow and decision points

2. **Development:**
   - Create a new workflow in the n8n interface
   - Add and configure trigger node (webhook, schedule, etc.)
   - Add processing nodes for data transformation
   - Add action nodes for services interaction
   - Connect nodes to define the execution flow
   - Add error handling and conditional branches

3. **Testing:**
   - Use the Execute Workflow button to test
   - Inspect node outputs at each step
   - Verify data transformations and service calls
   - Test error scenarios and edge cases

4. **Deployment:**
   - Save and activate the workflow
   - Configure production credentials
   - Export workflow JSON for version control
   - Document workflow purpose and configuration

### Common Node Types

- **Trigger Nodes:**
  - Webhook - Receives HTTP requests
  - Schedule - Runs on a time schedule
  - Cron - Runs on a cron schedule
  - PubSub - Listens for PubSub messages

- **Processing Nodes:**
  - Code - Executes custom JavaScript code
  - Set - Sets or modifies variables
  - IF - Conditional branching
  - Switch - Multi-path branching
  - Function - Applies a function to data

- **Service Nodes:**
  - HTTP Request - Makes API calls
  - Slack - Sends messages to Slack
  - GitHub - Interacts with GitHub
  - Database - Queries or updates databases
  - File - Reads or writes files

### Best Practices

1. **Error Handling:**
   - Add error handling nodes after critical operations
   - Use Try/Catch blocks in Code nodes
   - Configure error notifications for production workflows

2. **Security:**
   - Store credentials using n8n Credentials feature
   - Never hardcode sensitive information in workflows
   - Use environment variables for configuration

3. **Performance:**
   - Use batch operations when possible
   - Limit data transferred between nodes
   - Consider workflow execution time and frequency

4. **Maintainability:**
   - Add comments to document complex logic
   - Use meaningful node names
   - Group related functionality
   - Export workflows to version control
   - Document workflow purpose and configuration

## Integration with Alfred Platform

### Service Connections

n8n workflows can connect to Alfred Platform services using:

1. **HTTP Request Nodes:**
   ```
   URL: ${ALFRED_SERVICE_URL}/endpoint
   Headers: X-API-Key: ${ALFRED_API_KEY}
   Method: POST
   Body: JSON formatted payload
   ```

2. **Environment Variables:**
   - `ALFRED_CORE_URL` - Core service URL
   - `ALFRED_CREWAI_URL` - CrewAI service URL
   - `ALFRED_RAG_URL` - RAG Gateway URL
   - `ALFRED_API_KEY` - API key for services

3. **Database Connection:**
   - Direct connection to platform database
   - Used for storing workflow outputs
   - Requires database credentials

### Authentication

Authentication with Alfred services uses:

1. **API Key Authentication:**
   - Add `X-API-Key` header to requests
   - Use environment variable or credential

2. **Service-to-Service Authentication:**
   - Internal service communication
   - Configured via environment variables

## Troubleshooting

### Common Issues

1. **Workflow Not Triggering:**
   - Check if webhook URL is accessible
   - Verify schedule configuration
   - Confirm trigger node configuration

2. **Service Connection Errors:**
   - Verify service URLs and credentials
   - Check network connectivity
   - Confirm service health status

3. **Data Transformation Issues:**
   - Use debug mode to inspect data flow
   - Check for null or unexpected values
   - Verify JavaScript code in Code nodes

### Debugging Methods

1. **Execution Log:**
   - View the execution log in the n8n interface
   - Check for error messages and warnings

2. **Debug Mode:**
   - Enable Debug mode in the workflow
   - View actual data at each node

3. **Console.log:**
   - Add `console.log()` statements in Code nodes
   - View output in the browser console or logs