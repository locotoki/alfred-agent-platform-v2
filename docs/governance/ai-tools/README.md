# Using AI Tools with Alfred Documentation

This guide explains how to effectively use AI tools like Claude Desktop, Claude Code, and ChatGPT when working with Alfred Agent Platform documentation.

## Supported AI Tools

- **Claude Desktop**: For general document creation and editing
- **Claude Code**: For documentation that involves code examples or integration with code
- **ChatGPT (GPT-4o, GPT-4)**: For document creation, editing, and review

## General Instructions for AI Tools

When using any AI tool with this documentation, provide the following context:

1. What type of document you're working on (agent, workflow, project)
2. Where the document fits in the overall structure
3. Any templates or examples you want the AI to follow

## Tool-Specific Instructions

### Claude Desktop

Claude Desktop is excellent for:
- Creating initial drafts of documentation
- Polishing and refining existing documentation
- Creating consistent formatting

**Example Prompt:**
```
I'm creating documentation for the Social Intelligence agent in the Alfred Agent Platform. 
Please help me draft this document following the agent template. 

The agent documentation should be placed at /docs/agents/domain/social-intelligence.md

Here's the template to follow:
[paste template content]

Here's what I know about the Social Intelligence agent:
[paste information about the agent]
```

### Claude Code

Claude Code is ideal for:
- Documentation that includes code examples
- API documentation
- Technical specifications with code snippets

**Example Prompt:**
```
I'm documenting the API for the Social Intelligence agent. Please help me create 
technical documentation that includes code examples for the API endpoints.

The documentation should follow our standard format and include:
- Endpoint descriptions
- Request/response examples in JSON
- Error handling examples
- Code snippets in Python and JavaScript

Here are the API specs:
[paste API specs]
```

### ChatGPT

ChatGPT works well for:
- Quick documentation edits
- Generating ideas for documentation structure
- Reviewing documentation for clarity and completeness

**Example Prompt:**
```
I have documentation for the Niche-Scout workflow. Please review it for:
1. Adherence to our template structure
2. Technical accuracy
3. Clarity and completeness
4. Consistency with our documentation standards

Here's the current document:
[paste document]

Here's our standard template:
[paste template]
```

## System Prompts for AI Tools

### General Documentation System Prompt

```
# Alfred Agent Platform Documentation Assistant

You are a Documentation Assistant for the Alfred Agent Platform. Your role is to help create, edit, and maintain high-quality documentation following these guidelines:

## Documentation Structure
- Agent docs go in /docs/agents/{category}/
- Workflow docs go in /docs/workflows/by-agent/ or /docs/workflows/by-project/
- Project docs go in /docs/projects/{project-name}/

## Document Types and Templates
- Agent documentation follows the template in /docs/templates/agent-template.md
- Workflow documentation follows the template in /docs/templates/workflow-template.md
- Project documentation follows the template in /docs/templates/project-template.md

## Formatting Rules
- Use Markdown format
- Follow consistent heading hierarchy (# for title, ## for sections, ### for subsections)
- Use tables for structured data
- Use code blocks with language specifiers for code/examples
- Use relative links to reference other documentation files

## Document Naming
- All filenames should be lowercase with hyphens between words
- Agent docs: {agent-name}.md
- Workflow docs: {workflow-name}.md
- Project docs: specific conventions in project README

## Document Content Requirements
- All documents must have a clear title and introduction
- All documents must include last updated date and owner
- Technical details should be accurate and specific
- Examples should be provided where appropriate
- Cross-references to related documents should be included

Help me follow these guidelines while creating/editing documentation for the Alfred Agent Platform.
```

### Document Creation Prompt

See the [document creation prompt](./prompts/doc-creation-prompt.md) for a specialized prompt to use when creating new documentation.

### Document Review Prompt

See the [document review prompt](./prompts/doc-review-prompt.md) for a specialized prompt to use when reviewing existing documentation.

## Best Practices

1. **Provide Clear Context**: Always give the AI tool enough context about what you're trying to accomplish.

2. **Use Templates**: Reference the appropriate template when asking for help with documentation.

3. **Review AI Output**: Always review AI-generated documentation for accuracy and completeness.

4. **Iterative Refinement**: Use AI tools iteratively to refine documentation, rather than expecting perfect output in one go.

5. **Keep AI Updated**: Share feedback with the AI when its output doesn't meet your documentation standards, so it can improve.

## Common AI Documentation Tasks

### Creating a New Document

```
I need to create a new [agent/workflow/project] document for [name]. 
The document should follow our standard template and be placed at [path].

Here's what I know about this [agent/workflow/project]:
[key information]

Please help me draft this document according to our standards.
```

### Updating an Existing Document

```
I need to update our documentation for [name] at [path]. 
Specifically, I need to update the [section] with new information about [topic].

Here's the current document:
[paste document]

Here's the new information I need to add:
[new information]

Please update the document while maintaining our formatting and structure.
```

### Reviewing a Document

```
Please review this [agent/workflow/project] documentation for compliance with our standards:

[paste document]

Check for:
1. Template adherence
2. Proper formatting
3. Complete information
4. Accurate cross-references
5. Clear explanations
```

## Additional Resources

- [Markdown Guide](https://www.markdownguide.org/)
- [Documentation Best Practices](../standards/documentation-best-practices.md)
- [AI Tool Documentation](../standards/ai-tool-documentation.md)