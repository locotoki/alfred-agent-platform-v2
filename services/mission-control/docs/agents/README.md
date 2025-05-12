# Agent Documentation

This directory contains detailed documentation for all agents in the Alfred Agent Platform.

## Agent Categories

- **[Core](./core/)**: Core system agents (Conductor, Atlas, Forge, Sentinel)
- **[Personal](./personal/)**: Personal & Family tier agents
- **[Business](./business/)**: Solo-Biz tier agents (Internal-Only Business Operations)
- **[SaaS](./saas/)**: External-Facing SaaS agents (Multi-tenant)
- **[Domain](./domain/)**: Domain-specific agents (Social Intelligence, etc.)

## Agent Documentation Structure

Each agent should have a dedicated markdown file following this naming convention:
```
[agent-name].md
```

The agent documentation should follow the template provided in the [templates directory](../templates/agent-template.md).

## Agent Catalog

For a complete listing of all available and planned agents, see the [Agent Catalog](../planning/roadmap/agent-catalog.md).

## Adding New Agent Documentation

1. Identify the appropriate category for the agent
2. Copy the [agent template](../templates/agent-template.md) to the corresponding category directory
3. Name the file according to the agent name (lowercase-hyphenated)
4. Fill in all sections of the template
5. Update the Agent Catalog to include the new agent