# Alfred Agent Platform - Agent Catalog

**Last Updated:** YYYY-MM-DD  
**Owner:** [Owner Name/Team]

This document provides a comprehensive catalog of all agents in the Alfred Agent Platform, both existing and planned.

## Agent Categories and Deployment Tiers

### Tier Definitions

- **Personal / Family** – One household, fully local, no outside clients
- **Solo-Biz (Internal-Only)** – For freelancing or digital-product operations; processes business data but no external log-ins
- **External-Facing SaaS** – Multi-tenant product where paying customers have accounts and their data lives in the system

## Agent Catalog

### Core System Agents
| Agent Name   | Role                  | Tier      | Status      | Target Date |
|--------------|----------------------|-----------|-------------|-------------|
| Conductor    | Orchestrator         | System    | Planned     | YYYY-MM-DD  |
| Atlas        | Infrastructure Architect | System | Planned     | YYYY-MM-DD  |
| Forge        | Builder & Ops        | System    | Planned     | YYYY-MM-DD  |
| Sentinel     | Validator            | System    | Planned     | YYYY-MM-DD  |

### Personal & Family Agents
| Agent Name     | Purpose                        | Status      | Target Date |
|----------------|--------------------------------|-------------|-------------|
| Alfred-bot     | General household Q&A          | Planned     | YYYY-MM-DD  |
| Budget-Buddy   | Spend summaries, renewals      | Planned     | YYYY-MM-DD  |
| Legal-Reminder | Contract renewal alerts        | Planned     | YYYY-MM-DD  |
| Memory-Finder  | Photo & note retrieval         | Planned     | YYYY-MM-DD  |
| Health-Prompt  | Medicine/vitals reminders      | Optional    | YYYY-MM-DD  |

### Solo-Biz Agents (Internal-Only)
| Agent Name        | Purpose                       | Key Output          | Status    | Target Date |
|-------------------|-------------------------------|---------------------|-----------|-------------|
| BizDev-Bot        | Market & competitor research  | PPT/Markdown        | Planned   | YYYY-MM-DD  |
| Code-Smith        | Repo scaffolding, refactors   | PR diff             | Planned   | YYYY-MM-DD  |
| Design-Drafter    | Wireframes, brand assets      | Figma/PNG           | Planned   | YYYY-MM-DD  |
| Growth Bot        | SEO & ad-copy generation      | CSV posts           | Planned   | YYYY-MM-DD  |
| Financial-Tax     | Liability forecasts, bookkeeping | XLSX + narrative | Active    | Completed   |
| Legal-Compliance  | Contract review, red-flag     | Annotated PDF       | Active    | Completed   |
| Ops-Pilot         | Infra edits, backup snapshots | Terraform patch     | Planned   | YYYY-MM-DD  |
| RAG Optimizer     | Eval harness upkeep           | Eval report         | Planned   | YYYY-MM-DD  |

### External-Facing SaaS Agents
| Agent Name         | Purpose                        | SaaS Integration     | Status    | Target Date |
|--------------------|--------------------------------|----------------------|-----------|-------------|
| Support Bot        | Draft KB articles, ticket replies | Zendesk/Intercom | Planned   | YYYY-MM-DD  |
| Community-Mod Bot  | Enforce TOS, sentiment triage  | Discord/Slack        | Planned   | YYYY-MM-DD  |
| Pricing-Experiment | Landing-page A/B tests         | Plausible & Stripe   | Planned   | YYYY-MM-DD  |

### Domain-Specific Agents
| Agent Name          | Purpose                      | Domain          | Status    | Target Date |
|---------------------|------------------------------|-----------------|-----------|-------------|
| Social Intelligence | Social media trend analysis  | Content/Marketing | Active   | Completed   |
| Niche-Scout         | Find trending YouTube niches | Content/Marketing | Active   | Completed   |
| Seed-to-Blueprint   | Create YouTube strategy      | Content/Marketing | Active   | Completed   |

## Development Roadmap

### Q1 2025
- Complete implementation of Personal & Family tier agents
- Begin development of Solo-Biz agents

### Q2 2025
- Complete implementation of core Solo-Biz agents
- Begin development of External-Facing SaaS agents

### Q3 2025
- Complete implementation of External-Facing SaaS agents
- Begin development of additional Domain-Specific agents

### Q4 2025
- Expand agent capabilities across all tiers
- Implement cross-agent workflows and integration scenarios

## Agent Dependency Graph

```
Conductor
├── Atlas
├── Forge
└── Sentinel

Social Intelligence
├── Niche-Scout
└── Seed-to-Blueprint
```

## Adding New Agents

To propose a new agent for the platform:

1. Create a new agent specification following the [agent template](../../templates/agent-template.md)
2. Submit the specification for review
3. Upon approval, add the agent to this catalog
4. Create detailed documentation in the appropriate [agents directory](../../agents/)