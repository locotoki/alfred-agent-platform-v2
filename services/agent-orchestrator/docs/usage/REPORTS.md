# Using the Reports Feature

The Alfred Agent Orchestrator now includes a comprehensive reporting system that allows you to view and analyze data from agent operations.

## Accessing Reports

1. Navigate to the Alfred Agent Orchestrator UI at http://localhost:8080
2. Click on the "Reports" item in the sidebar navigation
3. The Reports dashboard will display available reports

## Available Report Types

### Agent Performance Reports
- Shows metrics on agent performance and reliability
- Includes response times, success rates, and error frequency
- Provides historical trends for performance analysis

### Workflow Analytics
- Displays detailed information about workflow executions
- Shows statistics on most frequently used workflows
- Provides insights into workflow completion rates and durations

### Resource Utilization
- Monitors system resource usage by different agents
- Tracks CPU, memory, and network utilization
- Highlights potential bottlenecks or optimization opportunities

## Interacting with Reports

### Filtering Data
- Use the date range selector to narrow report timeframes
- Apply filters to focus on specific agents or workflows
- Toggle between different visualization types (charts, tables, etc.)

### Exporting Reports
- Export reports in various formats (CSV, PDF, etc.)
- Schedule automatic report generation
- Share reports with team members

### Customizing Views
- Rearrange dashboard components
- Save custom report configurations
- Create personalized report views

## Theme Support

Reports support both light and dark themes:
- Click the theme toggle in the top navigation bar
- Reports will automatically adjust to match the selected theme
- Charts and visualizations are optimized for both themes

## Technical Details

The reporting system connects to various data sources:
- Agent performance metrics from the monitoring system
- Workflow execution data from the workflow history database
- Resource metrics from the infrastructure monitoring tools

Data is refreshed every 5 minutes, with the option to manually refresh as needed.
