# Agent Documentation

This directory contains detailed documentation for all agents in the Alfred Agent Platform.

## Agent Categories

The agents are organized into the following categories:

- **[Core](./core/)**: Core system agents that handle infrastructure management, orchestration, and core platform functions
- **[Personal](./personal/)**: Personal & Family tier agents designed for household use
- **[Business](./business/)**: Solo-Biz tier agents for internal business operations
- **[SaaS](./saas/)**: External-Facing SaaS agents that can be offered as multi-tenant services
- **[Domain](./domain/)**: Domain-specific agents that focus on particular areas like content creation or financial analysis

## Agent Catalog

For a complete list of all agents, see the [Agent Catalog](../planning/roadmap/agent-catalog.md).

## Multi-Category Agents

Some agents belong to multiple categories. In these cases:

1. The primary documentation is stored in the agent's primary category folder
2. Reference files in secondary categories point to the primary documentation

Example:
- Primary: `/agents/business/financial-tax.md`
- Reference: `/agents/saas/financial-tax.md` (points to the primary file)

## Creating Agent Documentation

When creating documentation for a new agent:

1. Determine the agent's primary category
2. Create a new file in that category's directory following the [agent template](../templates/agent-template.md)
3. If the agent belongs to multiple categories, create reference files in the secondary categories
4. Update the [Agent Catalog](../planning/roadmap/agent-catalog.md) with the new agent

### Required Information

At minimum, agent documentation should include:

- Basic metadata (name, category, status, etc.)
- Overview of the agent's purpose and functionality
- Key capabilities and workflows
- Integration points
- Use cases

### Using AI to Create Agent Documentation

You can use AI tools to help create agent documentation. See the [AI Tool Guide](../governance/ai-tools/readme.md) for specific instructions.

## Current Agents

### Core Agents
- Conductor (planned)
- Atlas (planned)
- Forge (planned)
- Sentinel (planned)

### Personal Agents
- Alfred-bot (planned)
- Budget-Buddy (planned)
- Legal-Reminder (planned)
- Memory-Finder (planned)
- Health-Prompt (optional, planned)

### Business Agents
- BizDev-Bot (planned)
- Code-Smith (planned)
- Design-Drafter (planned)
- Growth Bot (planned)
- Financial-Tax (active)
- Legal-Compliance (active)
- Ops-Pilot (planned)
- RAG Optimizer (planned)

### SaaS Agents
- Support Bot (planned)
- Community-Mod Bot (planned)
- Pricing-Experiment (planned)

### Domain Agents
- Social Intelligence (active)

## Documentation Status

| Agent | Documentation Status | Last Updated |
|-------|---------------------|--------------|
| Social Intelligence | Complete | YYYY-MM-DD |
| Financial-Tax | In Progress | YYYY-MM-DD |
| Legal-Compliance | Planned | - |
| [Other Agents] | Planned | - |