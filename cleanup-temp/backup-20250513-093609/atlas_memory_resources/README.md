# Atlas Memory Resources

This directory contains key files and documentation to help Atlas understand the memory architecture requirements for the Alfred Agent Platform v2.

## Directory Structure

### `/architecture`
- `ALFRED_MEMORY_ARCHITECTURE.md` - Comprehensive design document for the proposed memory architecture

### `/code`
- `base_agent.py` - Core agent implementation (lacks memory capabilities)
- `streamlit_chat_ui.py` - User interface implementation showing current session-based memory approach

### `/database`
- `init-db.sql` - Model registry database schema
- `social-intel-schema.sql` - Example service-specific schema

### `/protocol`
- `a2a-protocol.md` - Agent-to-Agent communication protocol documentation
- `a2a-envelope-schema.json` - JSON schema for A2A message format

### `/config`
- `docker-compose-clean.yml` - Infrastructure configuration showing available services

## Key Components

The platform currently has:
1. Redis for potential short-term memory
2. PostgreSQL for structured data storage
3. Qdrant for vector search capabilities
4. Agent Core framework with extensible architecture
5. A2A messaging protocol for inter-agent communication

The memory architecture document proposes a comprehensive design using these components to implement a multi-tiered memory system for agents.

## Current Status

The platform currently has:
- Session-based memory in the UI (no persistence)
- Task tracking in agents (no conversational context)
- Infrastructure components that can be leveraged (Redis, PostgreSQL, Qdrant)

Missing components:
- Standardized memory interface
- Multi-tiered memory implementation
- Memory consolidation service
- Agent memory integration

## Implementation Priority

1. Memory interface and core implementations
2. Database schema creation
3. Agent integration
4. UI and API integration
5. Memory optimization services
