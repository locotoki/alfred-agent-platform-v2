# GitHub Documentation Reference Guide

This guide provides instructions for accessing key documentation files from the Alfred Agent Platform v2 repository through GitHub.

## Essential Documentation Files

The following files provide the most comprehensive understanding of the AI Agent Platform v2:

1. **Master Project Plan**
   - Path: `docs/project/master-plan.md`
   - GitHub URL: `https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/docs/project/master-plan.md`
   - Description: Overall project plan, timeline, and current status

2. **Technical Design Guide**
   - Path: `docs/project/technical-design.md`
   - GitHub URL: `https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/docs/project/technical-design.md`
   - Description: Technical architecture and design principles

3. **Project Integration**
   - Path: `docs/project-integration.md`
   - GitHub URL: `https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/docs/project-integration.md`
   - Description: Bridges documentation with project implementation

4. **Agent Implementation Guide**
   - Path: `docs/agents/guides/agent-implementation-guide.md`
   - GitHub URL: `https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/docs/agents/guides/agent-implementation-guide.md`
   - Description: Practical guide for implementing new agents

5. **Agent Catalog**
   - Path: `docs/agents/catalog/agent-catalog.md`
   - GitHub URL: `https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/docs/agents/catalog/agent-catalog.md`
   - Description: Comprehensive listing of all agents in the system

6. **Workflow Catalog**
   - Path: `docs/workflows/catalog/workflow-catalog.md`
   - GitHub URL: `https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/docs/workflows/catalog/workflow-catalog.md`
   - Description: Comprehensive listing of all workflows in the system

7. **A2A Protocol Documentation**
   - Path: `docs/api/a2a-protocol.md`
   - GitHub URL: `https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/docs/api/a2a-protocol.md`
   - Description: Agent-to-agent communication protocol details

8. **System Design**
   - Path: `docs/architecture/system-design.md`
   - GitHub URL: `https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/docs/architecture/system-design.md`
   - Description: Detailed system architecture information

9. **Infrastructure Crew High-Level Design**
   - Path: `docs/infrastructure-crew/architecture/infrastructure-crew-high-level-design.md`
   - GitHub URL: `https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/docs/infrastructure-crew/architecture/infrastructure-crew-high-level-design.md`
   - Description: Infrastructure architecture details

10. **Main Documentation Index**
    - Path: `docs/README.md`
    - GitHub URL: `https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/docs/README.md`
    - Description: Navigation hub for all documentation

11. **Claude Code Guide**
    - Path: `CLAUDE.md`
    - GitHub URL: `https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/CLAUDE.md`
    - Description: Essential guidance for AI tools when working with the codebase

## Accessing Documentation from Tools

### For AI Tools (Claude, ChatGPT, etc.)

When prompting AI tools to review or understand the Alfred Agent Platform v2, provide the following instructions:

```
Please reference the Alfred Agent Platform v2 documentation on GitHub at https://github.com/[your-username]/alfred-agent-platform-v2/tree/main/docs

Key files to review for comprehensive understanding:
1. docs/project/master-plan.md - Overall project plan and status
2. docs/project/technical-design.md - Technical architecture
3. docs/project-integration.md - Documentation-implementation bridge
4. docs/agents/guides/agent-implementation-guide.md - Agent implementation details
5. docs/agents/catalog/agent-catalog.md - List of all agents
6. docs/workflows/catalog/workflow-catalog.md - List of all workflows
7. docs/api/a2a-protocol.md - Agent communication protocol
8. docs/architecture/system-design.md - System architecture
9. docs/infrastructure-crew/architecture/infrastructure-crew-high-level-design.md - Infrastructure
10. docs/README.md - Main documentation index
11. CLAUDE.md - Code style and development guidelines
```

The CLAUDE.md file is particularly important for AI-assisted development. It contains development guidelines:

```
# CLAUDE.md

## Build & Test Commands
- Setup: `make init`
- Build all services: `make build`
- Run all tests: `make test`
- Run specific test types: `make test-unit`, `make test-integration`, `make test-e2e`
- Run single test: `python -m pytest path/to/test_file.py::test_function_name -v`
- Lint code: `make lint`
- Format code: `make format`

## Code Style Guidelines
- Python version: 3.11+
- Line length: 100 characters
- Formatting: Black
- Import sorting: isort with black profile
- Type hints: Required (disallow_untyped_defs=true)
- Naming: snake_case for variables/functions, PascalCase for classes
- Error handling: Use structured logging with context
- Testing: pytest with markers for unit/integration/e2e
- Logging: Use structlog with context attributes
- Documentation: Docstrings required for public functions and classes
```

### For GitHub Actions

To reference documentation in GitHub Actions workflows:

```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Document reference example
        run: |
          echo "Processing according to documentation at docs/agents/guides/agent-implementation-guide.md"
          # Your build steps here
```

### For README Badges

Add these badges to your README.md to provide quick access to documentation:

```markdown
[![Documentation](https://img.shields.io/badge/docs-view%20documentation-blue)](https://github.com/[your-username]/alfred-agent-platform-v2/tree/main/docs)
[![Master Plan](https://img.shields.io/badge/master%20plan-view-green)](https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/docs/project/master-plan.md)
[![Technical Design](https://img.shields.io/badge/technical%20design-view-orange)](https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/docs/project/technical-design.md)
```

### For API Documentation Tools

If using tools like Swagger or Redoc, reference the A2A protocol:

```yaml
openapi: 3.0.0
info:
  title: Alfred Agent Platform v2 API
  version: 1.0.0
  description: |
    API documentation for the Alfred Agent Platform v2.
    For detailed protocol documentation, see: 
    https://github.com/[your-username]/alfred-agent-platform-v2/blob/main/docs/api/a2a-protocol.md
```

## Prompt for AI-Assisted Development

When using AI tools for development assistance with this project, use this prompt:

```
I'm working on the Alfred Agent Platform v2 project. Before providing assistance, please review the key documentation at https://github.com/[your-username]/alfred-agent-platform-v2/tree/main/docs, particularly:

1. Technical design: docs/project/technical-design.md
2. Agent implementation: docs/agents/guides/agent-implementation-guide.md
3. A2A protocol: docs/api/a2a-protocol.md
4. Code style: CLAUDE.md

My current task involves [task description]. Please assist while maintaining consistency with the project's architecture and standards.

The CLAUDE.md file contains these code style guidelines:
- Python version: 3.11+
- Line length: 100 characters
- Formatting: Black
- Type hints: Required (disallow_untyped_defs=true)
- Naming: snake_case for variables/functions, PascalCase for classes
- Error handling: Use structured logging with context
- Testing: pytest with markers for unit/integration/e2e
- Logging: Use structlog with context attributes
```

## Cloning Documentation for Local Reference

To clone the repository and have all documentation accessible locally:

```bash
git clone https://github.com/[your-username]/alfred-agent-platform-v2.git
cd alfred-agent-platform-v2/docs
```

---

**Note:** Replace `[your-username]` with your actual GitHub username in all URLs.