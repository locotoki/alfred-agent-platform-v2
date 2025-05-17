# Alfred Namespace Layout

## Overview

The Alfred Agent Platform v2 uses a unified namespace structure under the `alfred` package. This document provides a comprehensive overview of the namespace organization post-Phase 7D refactoring.

## Namespace Structure

```
alfred/
├── __init__.py             # Package root (version: 0.8.1)
├── core/                   # Core agent functionality
│   ├── __init__.py
│   ├── alfred_core/
│   ├── alfred_bot/
│   ├── agent_orchestrator/
│   └── financial_tax/
├── metrics/                # Observability and metrics
│   ├── __init__.py
│   ├── db_metrics/
│   └── pubsub_metrics/
├── model/                  # ML model management
│   ├── __init__.py
│   ├── model_router/
│   └── model_registry/
├── slack/                  # Slack integrations
│   ├── __init__.py
│   ├── slackbot/
│   ├── slack_app/
│   └── slack_mcp_gateway/
├── storage/                # Data persistence
│   ├── __init__.py
│   ├── db_storage/
│   ├── auth_ui/
│   └── monitoring_redis/
├── ui/                     # User interfaces
│   ├── __init__.py
│   ├── mission_control/
│   ├── mission_control_simplified/
│   └── streamlit_chat/
├── workflow/               # Workflow engines
│   ├── __init__.py
│   ├── worker/
│   ├── rag/
│   └── pubsub/
├── agents/                 # Specialized agents
│   ├── __init__.py
│   ├── social_intel/
│   └── legal_compliance/
├── adapters/               # External adapters
│   ├── __init__.py
│   ├── whatsapp/
│   └── rag_gateway/
└── support/                # Support services
    ├── __init__.py
    └── redis/
```

## Import Conventions

### Standard Imports
```python
# Core functionality
from alfred.core.alfred_core import AlfredCore
from alfred.core.financial_tax import FinancialTaxAgent

# Metrics and observability
from alfred.metrics.db_metrics import create_app as create_metrics_app
from alfred.metrics.pubsub_metrics import MetricsCollector

# Slack integrations
from alfred.slack.slack_app import SlackApp
from alfred.slack.slackbot.client import SlackClient

# Storage and persistence
from alfred.storage.db_storage import StorageManager
from alfred.storage.auth_ui import AuthUIManager

# UI components
from alfred.ui.mission_control import MissionControlApp
from alfred.ui.streamlit_chat import StreamlitChatApp

# Workflow engines
from alfred.workflow.worker import WorkerManager
from alfred.workflow.rag import RAGService

# Specialized agents
from alfred.agents.social_intel import SocialIntelAgent
from alfred.agents.legal_compliance import LegalComplianceAgent

# External adapters
from alfred.adapters.whatsapp import WhatsAppAdapter
from alfred.adapters.rag_gateway import RAGGateway

# Support services
from alfred.support.redis import RedisManager
```

### Namespace Benefits

1. **Unified Package**: All components under single `alfred` namespace
2. **Clear Organization**: Logical grouping by functionality
3. **Import Clarity**: Explicit imports show dependencies
4. **Type Safety**: Enables progressive type hinting (Phase 8.1)
5. **Modularity**: Easy to add/remove components

## Migration Notes

- **Pre v0.8.2**: Scattered services in `services/` directory
- **Post v0.8.2**: Unified under `alfred` namespace
- **Compatibility**: Legacy imports redirected via `__init__.py`

## Development Guidelines

1. **New Modules**: Add under appropriate sub-namespace
2. **Imports**: Use fully qualified imports (`alfred.module.submodule`)
3. **Type Hints**: All new code must include type annotations
4. **Documentation**: Update this file when adding new namespaces

## Docker and Deployment

Docker Compose contexts updated to reflect new structure:

```yaml
services:
  service-name:
    build:
      context: ./alfred/module
      dockerfile: Dockerfile
```

## Future Roadmap

1. **Phase 8.1**: Progressive type hinting across all modules
2. **Phase 8.2**: Namespace-based dependency injection
3. **Phase 9.0**: Public API surface definition

## References

- [PR #66](https://github.com/locotoki/alfred-agent-platform-v2/pull/66) - Namespace refactoring
- [Phase 7D Summary](../phase7/namespace-hygiene-summit.md)
- [Type Hinting Plan](../phase8/type-hinting-plan.md)