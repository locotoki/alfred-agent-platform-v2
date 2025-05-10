# Infrastructure Crew Documentation

This directory contains documentation for the Infrastructure Crew, an autonomous agent-based system for managing cloud infrastructure.

## Directory Structure

- **architecture/** - High-level design documents, system architecture, and flow diagrams
- **roles/** - Role definitions for each agent in the Infrastructure Crew
- **implementation/** - Implementation guides, framework documentation, and setup instructions
- **diagrams/** - Source and generated visualization assets
  - **src/** - Mermaid source files
  - **svg/** - Generated SVG diagrams
- **workflows/** - GitHub Actions workflows and automation scripts

## Quick Links

- [Lean Crew MVP](./architecture/lean-crew-mvp.md)
- [Infrastructure Crew Artifact Flow](./architecture/infrastructure-crew-artifact-flow.md)
- [AI Agent Framework Guide](./implementation/ai-agent-framework-guide.md)
- [Infrastructure Architect Role](./roles/infrastructure-architect.md)

## Agent Roster

| Agent | Role | Core Mandate |
|-------|------|--------------|
| Atlas | Infrastructure Architect | Produce infrastructure designs and plans |
| Forge | Builder & Ops | Convert plans to IaC and deploy |
| Sentinel | Validator | Security and compliance checks |
| Conductor | Orchestrator | Route artifacts and maintain workflow state |

For more details, see the [Lean Crew MVP](./architecture/lean-crew-mvp.md) document.
