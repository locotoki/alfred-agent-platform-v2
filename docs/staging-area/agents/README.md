# Alfred Agent Platform - Agent Catalog

This directory contains documentation for all available and planned agents in the Alfred Agent Platform.

## Directory Structure

- `README.md` - This file, containing an overview of available agents
- `core/` - Core system agents (Conductor, Atlas, Forge, Sentinel)
- `personal/` - Personal & Family tier agents
- `business/` - Solo-Biz tier agents (Internal-Only Business Operations)
- `saas/` - External-Facing SaaS agents (Multi-tenant)
- `domain/` - Domain-specific agents (Social Intelligence, etc.)

## Agent Categories

### Core System Agents
| Agent Name   | Role                  | Tier      | Status      |
|--------------|----------------------|-----------|-------------|
| Conductor    | Orchestrator         | System    | Planned     |
| Atlas        | Infrastructure Architect | System | Planned     |
| Forge        | Builder & Ops        | System    | Planned     |
| Sentinel     | Validator            | System    | Planned     |

### Personal & Family Agents
| Agent Name     | Purpose                        | Status      |
|----------------|--------------------------------|-------------|
| Alfred-bot     | General household Q&A          | Planned     |
| Budget-Buddy   | Spend summaries, renewals      | Planned     |
| Legal-Reminder | Contract renewal alerts        | Planned     |
| Memory-Finder  | Photo & note retrieval         | Planned     |
| Health-Prompt  | Medicine/vitals reminders      | Optional    |

### Solo-Biz Agents (Internal-Only)
| Agent Name        | Purpose                       | Key Output          | Status    |
|-------------------|-------------------------------|---------------------|-----------|
| BizDev-Bot        | Market & competitor research  | PPT/Markdown        | Planned   |
| Code-Smith        | Repo scaffolding, refactors   | PR diff             | Planned   |
| Design-Drafter    | Wireframes, brand assets      | Figma/PNG           | Planned   |
| Growth Bot        | SEO & ad-copy generation      | CSV posts           | Planned   |
| Financial-Tax     | Liability forecasts, bookkeeping | XLSX + narrative | Active    |
| Legal-Compliance  | Contract review, red-flag     | Annotated PDF       | Active    |
| Ops-Pilot         | Infra edits, backup snapshots | Terraform patch     | Planned   |
| RAG Optimizer     | Eval harness upkeep           | Eval report         | Planned   |

### External-Facing SaaS Agents
| Agent Name         | Purpose                        | SaaS Integration     | Status    |
|--------------------|--------------------------------|----------------------|-----------|
| Support Bot        | Draft KB articles, ticket replies | Zendesk/Intercom | Planned   |
| Community-Mod Bot  | Enforce TOS, sentiment triage  | Discord/Slack        | Planned   |
| Pricing-Experiment | Landing-page A/B tests         | Plausible & Stripe   | Planned   |

### Domain-Specific Agents
| Agent Name          | Purpose                      | Domain          | Status    |
|---------------------|------------------------------|-----------------|-----------|
| Social Intelligence | Social media trend analysis  | Content/Marketing | Active   |
| Niche-Scout         | Find trending YouTube niches | Content/Marketing | Active   |
| Seed-to-Blueprint   | Create YouTube strategy      | Content/Marketing | Active   |

## Adding New Agents

To document a new agent, create a markdown file in the appropriate category folder following the template structure:

```
/docs/staging-area/agents/[category]/[agent-name].md
```

Use the [agent-template.md](./agent-template.md) file as a starting point for your documentation.