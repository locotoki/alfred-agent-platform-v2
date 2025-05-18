# Workflow Documentation

This directory contains detailed documentation for all workflows in the Alfred Agent Platform.

## What is a Workflow?

In the Alfred Agent Platform, a workflow is a defined sequence of steps that accomplishes a specific task by orchestrating one or more agents. Workflows can be triggered manually, scheduled, or executed in response to events.

## Workflow Organization

Workflows are organized in multiple ways to make them easy to find:

- **[By Agent](./by-agent/)**: Workflows organized by the primary agent that implements them
- **[By Project](./by-project/)**: Workflows organized by the project they belong to
- **[Catalog](./catalog/)**: A comprehensive listing of all available workflows
- **[Development](./development/)**: Guides and resources for workflow development

## Workflow Catalog

For a complete listing of all workflows, see the [Workflow Catalog](./catalog/workflow-catalog.md).

## Creating Workflow Documentation

When creating documentation for a new workflow:

1. Determine the primary agent responsible for the workflow
2. Create the workflow documentation in the appropriate location:
   - `/workflows/by-agent/[agent-folder]/[workflow-name].md`
   - `/workflows/by-project/[project-folder]/[workflow-name].md` (if project-specific)
3. Follow the [workflow template](../templates/workflow-template.md)
4. Update the [Workflow Catalog](./catalog/workflow-catalog.md)
5. Update the associated agent documentation to reference the new workflow

### Required Information

At minimum, workflow documentation should include:

- Basic metadata (name, owner, status, etc.)
- Overview of the workflow's purpose
- Workflow diagram or process flow
- Input and output specifications
- Detailed step descriptions
- Error handling information
- Example use cases

### Using AI to Create Workflow Documentation

You can use AI tools to help create workflow documentation. See the [AI Tool Guide](../governance/ai-tools/README.md) for specific instructions.

## Current Workflows

### Social Intelligence Agent Workflows
- Niche-Scout: Find trending YouTube niches with growth metrics
- Seed-to-Blueprint: Create YouTube channel strategy from seed video or niche

### Financial-Tax Agent Workflows
- Tax-Estimate: Generate tax liability forecasts
- Financial-Report: Create comprehensive financial reports
- Expense-Categorization: Automatically categorize expenses

### Legal-Compliance Agent Workflows
- Contract-Review: Review contracts for compliance issues
- Terms-Analysis: Analyze terms of service for potential risks

## Workflow Status

| Workflow | Agent | Status | Documentation Status | Last Updated |
|----------|-------|--------|---------------------|--------------|
| Niche-Scout | Social Intelligence | Active | Complete | YYYY-MM-DD |
| Seed-to-Blueprint | Social Intelligence | Active | Complete | YYYY-MM-DD |
| Tax-Estimate | Financial-Tax | Active | In Progress | YYYY-MM-DD |
| [Other Workflows] | - | - | Planned | - |

## Workflow Development

For information on how to develop new workflows, see the [Workflow Development Guide](./development/workflow-development-guide.md).

## Related Documentation

- [Agent Documentation](../agents/README.md)
- [Project Documentation](../projects/README.md)
- [Architecture Documentation](../architecture/README.md)
