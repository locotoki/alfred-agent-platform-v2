# Alfred Agent Platform v2 - Documentation Quick Reference

**Last Updated:** 2025-05-10
**Owner:** Documentation Team
**Status:** Active

## Documentation System Structure

| Category | Location | Purpose |
|----------|----------|---------|
| **Agent Documentation** | `/docs/agents/{category}/{agent-name}.md` | Documents specific agents, capabilities, and implementations |
| **Workflow Documentation** | `/docs/workflows/by-agent/{agent}/{workflow}.md`<br>`/docs/workflows/by-project/{project}/{workflow}.md` | Documents specific workflows, steps, and I/O |
| **Project Documentation** | `/docs/projects/{project-name}/{document}.md` | Documents multi-agent projects and architectures |
| **Architecture Documentation** | `/docs/architecture/*` | Documents system-wide architecture decisions |
| **Process Documentation** | `/docs/governance/processes/*` | Documents operational and development processes |
| **Templates** | `/docs/templates/*` | Standard templates for documentation creation |
| **AI Tools** | `/docs/governance/ai-tools/*` | Guidelines for using AI in documentation |

## Template Cheat Sheet

### Agent Template

```markdown
# [Agent Name]

**Last Updated:** YYYY-MM-DD
**Owner:** [Owner Name/Team]
**Status:** [Planned/In Development/Active]

## Overview
[2-3 paragraph description]

## Agent Metadata
[Category, Status, Version info]

## Capabilities
[Core capabilities, limitations]

## Workflows
[Supported workflows with links]

## Technical Specifications
[I/O, Tools, Configuration]

## Use Cases
[Example use cases with code samples]

## Implementation Details
[Architecture, Dependencies, Deployment]
```

### Workflow Template

```markdown
# [Workflow Name]

**Last Updated:** YYYY-MM-DD
**Owner:** [Owner Name/Team]
**Status:** [Planned/In Development/Active]

## Overview
[1-2 paragraph description]

## Workflow Metadata
[Primary Agent, Supporting Agents, etc.]

## Workflow Diagram
[Flow diagram]

## Input Parameters
[Parameters table]

## Output
[Output format and example]

## Workflow Steps
[Detailed steps with component/agent info]

## Error Handling
[Error handling strategies]
```

### Project Template

```markdown
# [Project Name]

**Last Updated:** YYYY-MM-DD
**Owner:** [Owner Name/Team]
**Status:** [Planning/In Development/Active/Maintenance]

## Overview
[2-3 paragraph description]

## Project Metadata
[Status, Timeline, Repository]

## Key Components
[Major components and their purpose]

## Agent Integration
[How agents are used in the project]

## Workflows
[Project workflows with documentation links]

## Architecture
[System architecture with diagrams]
```

## Validation Tools

| Tool | Purpose | Command |
|------|---------|---------|
| **Run All Validations** | Executes comprehensive validation suite | `./scripts/run-validations.sh` |
| **Infrastructure Validation** | Validates infrastructure components | `./scripts/infrastructure-validation.sh` |
| **Database Validation** | Validates database schema and extensions | `python scripts/utils/database_validation.py` |
| **Service Health Checks** | Checks status of all services | `python scripts/utils/service_health_check.py` |
| **Markdown Linting** | Validates markdown formatting | `markdownlint docs/**/*.md` |
| **Link Validation** | Checks for broken links | `markdown-link-check docs/**/*.md` |
| **Exactly-Once Processing** | Tests message processing guarantees | `python -m pytest tests/integration/test_exactly_once_processing.py -v` |
| **A2A Envelope Tests** | Tests A2A messaging envelope | `python -m pytest tests/unit/test_envelope.py -v` |

## Common Documentation Tasks

### Creating New Documentation

1. **Choose appropriate template**:
   - Agent: `/docs/templates/agent-template.md`
   - Workflow: `/docs/templates/workflow-template.md`
   - Project: `/docs/templates/project-template.md`

2. **Follow file structure convention**:
   - Use lowercase filenames with hyphens
   - Place in correct directory based on type
   - Example: `/docs/agents/domain/social-intelligence.md`

3. **Create documentation ticket** in issue tracker:
   - Define target audience and document type
   - Assign to content creator

4. **Create initial draft** following the template
   - Apply linting and validation tools
   - Self-review against quality checklist

5. **Submit for review**:
   - Submit as PR with `documentation` label
   - Technical and editorial review
   - Address feedback iteratively

6. **Final approval and publication**:
   - Get approval from documentation owner
   - Merge into appropriate branch

### Updating Documentation

1. **Identify outdated content** via issue
2. **Make targeted changes** to existing documentation
3. **Include change rationale** in PR description
4. **Apply same review process** as new documentation
5. **Update "Last Updated" date** when document changes
6. **Maintain revision history** for significant changes

## Documentation Standards

### File Naming Conventions

- Use lowercase letters
- Use hyphens to separate words
- Be descriptive but concise
- Examples: `social-intelligence.md`, `niche-scout.md`

### Markdown Formatting

- **Headers**: `#` for title, `##` for sections, `###` for subsections
- **Lists**: Unordered (`-`) for items without sequence, ordered (`1.`) for sequential steps
- **Code blocks**: Always specify language for syntax highlighting
- **Tables**: Include header row and alignment indicators
- **Links**: Use relative links for internal documentation

### Content Requirements

- **Title & Metadata**: Document title and metadata fields
- **Overview**: Brief introduction to the subject
- **Main Content**: Structured by document template
- **Related Documentation**: Links to related documents
- **References**: Citations or external references

## AI Documentation Assistance

### Documentation Creation Prompt

```
You are a Documentation Expert for the Alfred Agent Platform.
I need to create a new [DOCUMENT_TYPE] document for [NAME].
This document will be stored at [FILE_PATH].

## Document Type Information
[Specific requirements for document type]

## Template to Follow
[Template content]

## Information About [NAME]
[Relevant information]

## Requirements
Please create a comprehensive document following our standards:
1. Follow template structure
2. Use clear technical language
3. Include all provided information
4. Use proper Markdown formatting
5. Ensure relative links use correct format
6. Mark missing information as [TBD]
```

### Documentation Review Prompt

```
Please review this [agent/workflow/project] documentation for compliance with our standards:

[document content]

Check for:
1. Template adherence
2. Proper formatting
3. Complete information
4. Accurate cross-references
5. Clear explanations
```

## Important Links

- **Documentation Standards**: `/docs/governance/standards/documentation-standards.md`
- **Documentation Process**: `/docs/governance/processes/documentation-process.md`
- **AI Tools Guide**: `/docs/governance/ai-tools/README.md`
- **Templates Directory**: `/docs/templates/`
- **Implementation Status**: `/docs/IMPLEMENTATION_STATUS.md`
- **Project Plan**: `/docs/development/AI Agent Platform v2 - Master Project Plan.md`
- **Validation Scripts**: `/scripts/run-validations.sh`
- **Troubleshooting Guide**: `/docs/TROUBLESHOOTING.md`
