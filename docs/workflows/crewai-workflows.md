# CrewAI Workflows

## Overview

CrewAI workflows in the Alfred Agent Platform utilize specialized agent crews to perform complex tasks through multi-agent collaboration. These workflows leverage the CrewAI framework to create teams of agents with different roles and expertise, working together to accomplish objectives that would be difficult for a single agent.

## Available Crew Types

### Research Crew

The Research Crew specializes in comprehensive information gathering, analysis, and reporting on specific topics.

**Agents:**
- **Research Manager**: Plans and oversees the research process
- **Domain Expert**: Provides specialized knowledge and validates findings
- **Information Analyst**: Gathers and synthesizes information from various sources
- **Content Writer**: Creates clear, comprehensive research reports

**Workflow Process:**
1. Research Manager develops a comprehensive research plan
2. Information Analyst gathers relevant information based on the plan
3. Domain Expert analyzes and validates the collected information
4. Content Writer creates the final research report
5. Results are published back to the requesting system

**Use Cases:**
- Market research for new product development
- Competitive analysis for strategic planning
- Technology trend analysis for roadmap planning
- Domain-specific research for decision support

### Code Review Crew

The Code Review Crew performs comprehensive code assessments, focusing on quality, security, and performance.

**Agents:**
- **Technical Lead**: Oversees the review process and provides architectural insights
- **Security Engineer**: Identifies and analyzes security vulnerabilities
- **Performance Engineer**: Locates performance bottlenecks and optimization opportunities
- **Code Quality Expert**: Ensures code follows best practices and is maintainable

**Workflow Process:**
1. Technical Lead performs initial code assessment
2. Security Engineer, Performance Engineer, and Code Quality Expert analyze the code in parallel
3. Technical Lead compiles findings into a comprehensive review report
4. Results are published back to the code repository or requesting system

**Use Cases:**
- Pull request reviews for critical code changes
- Security audits of application components
- Performance assessments for optimization
- Code quality evaluations for technical debt reduction

### Data Analysis Crew

The Data Analysis Crew specializes in extracting insights from data through statistical analysis and visualization.

**Agents:**
- **Data Science Manager**: Plans and oversees the analysis process
- **Data Engineer**: Prepares and transforms data for analysis
- **Data Analyst**: Performs statistical analysis and extracts insights
- **Data Visualization Expert**: Creates visual representations of findings

**Workflow Process:**
1. Data Science Manager defines the analysis plan and objectives
2. Data Engineer prepares and cleans the data for analysis
3. Data Analyst performs exploratory analysis and statistical testing
4. Visualization Expert creates clear, informative visualizations
5. Data Science Manager compiles the final analysis report
6. Results are published back to the requesting system

**Use Cases:**
- Business metrics analysis for executive reporting
- Customer behavior analysis for product improvements
- Operational data analysis for efficiency optimization
- Financial data analysis for forecasting and planning

## Integration Methods

### Direct API Integration

CrewAI workflows can be triggered directly through the CrewAI service API:

```bash
curl -X POST http://localhost:9004/crews/{crew_type}/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "task_id": "task-123",
    "tenant_id": "client-abc",
    "content": {
      "objective": "Task objective description",
      "process_type": "sequential",
      "additional_parameters": {
        "key1": "value1",
        "key2": "value2"
      }
    }
  }'
```

### n8n Workflow Integration

CrewAI workflows can be integrated into n8n workflows using the HTTP Request node:

1. Configure an HTTP Request node pointing to the CrewAI API
2. Format the request payload according to the crew type
3. Process the response to extract the task ID
4. Optionally poll for task completion using a subsequent HTTP Request node

### PubSub Integration

For asynchronous processing, CrewAI workflows can be triggered via PubSub:

1. Publish a message to the `crew.tasks` topic
2. Include crew_type, task_id, and content in the message
3. Subscribe to the `crew.results` topic to receive task results

## Customizing Crew Workflows

### Modifying Existing Crews

Existing crews can be customized by:

1. Modifying the agent definitions in the crew implementation
2. Adjusting the task sequence and dependencies
3. Adding or replacing tools available to the agents
4. Changing the process type (sequential vs. hierarchical)

### Creating New Crews

To create a new crew type:

1. Create a new class extending `BaseCrew` in `crewai_service/crews/`
2. Define the specialized agents with appropriate roles and tools
3. Create the task sequence with proper dependencies
4. Register the new crew in the `CREW_REGISTRY` in `registry.py`
5. Restart the CrewAI service to make the new crew available

### Adding Custom Tools

Custom tools can be added to crews to extend their capabilities:

1. Create a new tool class extending `BaseTool` in `crewai_service/tools/`
2. Implement the `_run` and `_arun` methods
3. Include the tool in the crew's `_setup_tools` method
4. Assign the tool to appropriate agents in the crew

## Monitoring and Debugging

### Metrics

CrewAI workflow execution can be monitored through Prometheus metrics:

- `crewai_tasks_total`: Count of tasks by crew type and status
- `crewai_task_duration_seconds`: Execution time histogram
- `crewai_active_tasks`: Currently running tasks by crew type

### Logs

Detailed execution logs are available through the CrewAI service logs:

```bash
docker logs crewai-service
```

The log level can be adjusted using the `CREWAI_LOG_LEVEL` environment variable.

### Task Status API

Individual task status can be checked using the tasks API:

```bash
curl http://localhost:9004/tasks/{task_id}
```

## Best Practices

1. **Task Scoping**: Define clear, focused objectives for each crew task
2. **Context Provision**: Include sufficient context in the task content
3. **Process Selection**: Choose the appropriate process type for the workflow:
   - `sequential` for workflows with clear steps
   - `hierarchical` for workflows with complex dependencies
4. **Resource Consideration**: Larger crews with more agents require more resources
5. **Error Handling**: Implement proper error handling in workflows that consume crew results
6. **Tenant Isolation**: Always specify tenant_id for proper data isolation
7. **Task Tracking**: Generate and store unique task IDs for tracking and debugging