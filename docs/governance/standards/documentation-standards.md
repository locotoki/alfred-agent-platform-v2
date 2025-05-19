# Documentation Standards

This document outlines the standards for all documentation in the Alfred Agent Platform. Following these standards ensures documentation is consistent, high-quality, and easy to maintain.

## Document Types

The documentation system includes these primary document types:

1. **Agent Documentation**: Documents specific agents, their capabilities, and implementation details
2. **Workflow Documentation**: Documents specific workflows, their steps, inputs/outputs, and use cases
3. **Project Documentation**: Documents projects that utilize multiple agents and workflows
4. **Architecture Documentation**: Documents system-wide architectural decisions and patterns
5. **Process Documentation**: Documents operational and development processes

## File Structure and Organization

### File Locations

- Agent documentation: `/docs/agents/{category}/{agent-name}.md`
- Workflow documentation: `/docs/workflows/by-agent/{agent-folder}/{workflow-name}.md` or `/docs/workflows/by-project/{project-folder}/{workflow-name}.md`
- Project documentation: `/docs/projects/{project-name}/{document-name}.md`

### File Naming Conventions

- Use lowercase letters
- Use hyphens to separate words
- Be descriptive but concise
- Avoid special characters
- Examples:
  - `social-intelligence.md`
  - `niche-scout.md`
  - `content-factory-architecture.md`

## Markdown Formatting Standards

### Headers

- Use # for document title (only one per document)
- Use ## for major sections
- Use ### for subsections
- Use #### for sub-subsections
- Never skip a heading level

Example:
```markdown
# Document Title

## Major Section

### Subsection

#### Sub-subsection
```

### Text Formatting

- Use **bold** for emphasis on important concepts
- Use *italics* for slight emphasis or to introduce terms
- Use `inline code` for code snippets, commands, or technical terms
- Use > for quotes or important notes

### Lists

- Use unordered lists (bullet points) for items without sequence
- Use ordered lists (numbers) for sequential steps or prioritized items
- Use consistent indentation for nested lists (2 spaces)

Example:
```markdown
- Item 1
  - Subitem A
  - Subitem B
- Item 2
  - Subitem C
```

### Code Blocks

- Always specify the language for syntax highlighting
- Use code blocks for all code examples, configuration, and command outputs

Example:
```markdown
```python
def hello_world():
    print("Hello, world!")
```
```

### Tables

- Use tables for structured data
- Include header row and alignment indicators
- Keep tables simple and readable

Example:
```markdown
| Name | Type | Description |
|------|------|-------------|
| item1 | string | Description of item 1 |
| item2 | number | Description of item 2 |
```

### Links

- Use relative links for internal documentation
- Use descriptive link text
- Ensure all links are valid

Example:
```markdown
See the [Social Intelligence Agent](../../agents/domain/social-intelligence.md) for more information.
```

## Document Metadata

Every document must include the following metadata at the top:

- **Title**: The full name of the document subject
- **Last Updated**: Date in YYYY-MM-DD format
- **Owner**: Person or team responsible for maintaining the document
- **Status**: Current status (e.g., Draft, In Review, Approved, etc.)

Example:
```markdown
# Social Intelligence Agent

**Last Updated:** 2023-04-15
**Owner:** AI Research Team
**Status:** Active
```

## Content Standards

### Language and Style

- Use clear, concise language
- Write in present tense
- Use active voice
- Define acronyms and technical terms on first use
- Be consistent with terminology
- Use sentence case for headings (only capitalize first word and proper nouns)

### Document Structure

Every document should include these general sections:

1. **Title and Metadata**: Document title and metadata fields
2. **Overview**: Brief introduction to the subject
3. **Main Content**: Structured according to the specific document template
4. **Related Documentation**: Links to related documents
5. **References**: Citations or external references (if applicable)

### Specific Content Requirements

#### Agent Documentation

- Must clearly describe the agent's purpose and capabilities
- Must specify all workflows the agent supports
- Must document configuration options
- Must include example use cases

#### Workflow Documentation

- Must include a workflow diagram or process flow
- Must specify inputs and outputs
- Must document each step in the workflow
- Must include error handling information

#### Project Documentation

- Must describe the project purpose and goals
- Must specify all agents and workflows involved
- Must include architecture diagrams
- Must document integration points

## Templates

Always use the provided templates for creating new documentation:

- [Agent Template](../../templates/agent-template.md)
- [Workflow Template](../../templates/workflow-template.md)
- [Project Template](../../templates/project-template.md)

## Review Process

All documentation should undergo the following review process:

1. **Self-Review**: Author reviews against standards checklist
2. **Peer Review**: Technical peer reviews for accuracy
3. **Documentation Review**: Documentation specialist reviews for standards compliance
4. **Final Approval**: Document owner approves the document

## Maintenance Standards

- Update the "Last Updated" date whenever the document changes
- Review all documentation quarterly
- Archive obsolete documentation rather than deleting it
- Maintain a document revision history for significant changes

## Documentation Tools

- Use Markdown for all documentation
- Use [markdownlint](https://github.com/DavidAnson/markdownlint) for Markdown linting
- Use [Prettier](https://prettier.io/) for consistent formatting
- Use [markdown-link-check](https://github.com/tcort/markdown-link-check) to verify links
