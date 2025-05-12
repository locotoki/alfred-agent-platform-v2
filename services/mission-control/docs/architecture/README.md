# Architecture Documentation

This directory contains architecture documentation for the Alfred Agent Platform.

## Directory Structure

- **[Overview](./overview/)**: High-level architecture diagrams and descriptions
- **[Components](./components/)**: Component-specific architecture details
- **[Integrations](./integrations/)**: Integration points with external systems
- **[Decisions](./decisions/)**: Architecture Decision Records (ADRs)

## Key Architecture Documents

- [System Overview](./overview/system-overview.md): High-level overview of the entire system
- [Component Architecture](./components/component-architecture.md): Detailed component architecture
- [Data Flow Diagrams](./overview/data-flow-diagrams.md): System data flows
- [API Architecture](./components/api-architecture.md): API design and architecture

## Architecture Decision Records (ADRs)

Architecture Decision Records (ADRs) document significant architectural decisions made during the development of the platform. Each ADR follows the template in the [templates directory](../templates/architecture-decision-record-template.md).

### Current ADRs:

- [ADR-001: Microservices Architecture](./decisions/adr-001-microservices-architecture.md)
- [ADR-002: Agent Communication Protocol](./decisions/adr-002-agent-communication-protocol.md)

## Contributing to Architecture Documentation

When adding or updating architecture documentation:

1. Follow the established templates and conventions
2. Include both textual descriptions and visual diagrams
3. Update the relevant README files
4. Consider creating a new ADR for significant architectural decisions
5. Ensure diagrams are available in both source format and as exported images