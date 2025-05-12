# Atlas Usage Guide

*Last Updated: 2025-05-11*  
*Owner: Infra Crew*  
*Status: Active*  

## Overview

Atlas is an AI-powered architecture agent that generates detailed technical specifications and architecture decision records (ADRs) based on your requirements. This guide provides instructions on how to use Atlas effectively and get the best results.

## Getting Started

### Prerequisites

- Access to the Alfred Agent Platform
- Appropriate permissions to send and receive messages
- Basic understanding of software architecture concepts

### Accessing Atlas

Atlas can be accessed through:

1. **Slack Bot**: Direct message the Alfred bot with an architecture request
2. **CLI**: Use the `atlas-publish` command in the Alfred CLI
3. **API**: Send requests programmatically using the A2A protocol
4. **Web UI**: Use the Mission Control web interface

## Writing Effective Prompts

The quality of Atlas's output is significantly influenced by the quality of your prompts. Here are some guidelines for writing effective architecture prompts:

### Structure Your Requirements

```
Design a [specific system type] with [key requirements] for [specific purpose].

Key Requirements:
- [requirement 1]
- [requirement 2]
- [requirement 3]

The architecture should focus on [scalability/security/reliability/etc.].

Additional context:
[any existing systems, constraints, or preferences]
```

### Be Specific About Scope

Clearly indicate the scope of the architecture you want:

- **High-level**: "Design a system architecture overview for a multi-tenant SaaS platform"
- **Component-level**: "Design the data storage layer for a real-time analytics platform"
- **Detail-specific**: "Design a caching strategy for a high-traffic e-commerce API"

### Specify Technology Constraints

If you have specific technology requirements or constraints, mention them explicitly:

- "The solution must use AWS services"
- "The architecture should be cloud-agnostic"
- "We need to integrate with our existing Oracle database"

### Request Specific Diagrams

Atlas can generate architecture diagrams using Mermaid or ASCII art. Specify the types of diagrams you need:

- "Include a component diagram showing the main services"
- "Provide a sequence diagram for the authentication flow"
- "Include a deployment diagram showing cloud resources"

## Example Prompts

### General Architecture

```
Design a scalable microservices architecture for an e-commerce platform that needs to handle 10,000 concurrent users and 100,000 products.

Key requirements:
- Support payment processing with multiple providers
- Real-time inventory updates
- Personalized recommendations
- Order history and tracking

The architecture should prioritize reliability and horizontal scalability.
```

### Technical Design

```
Design the database architecture for a healthcare application that stores patient records, appointments, and medical history.

Requirements:
- HIPAA compliance for data storage
- Support for both structured and unstructured data
- Efficient querying for patient history
- Backup and disaster recovery

Currently using PostgreSQL but open to other options if justified.
```

### Migration Strategy

```
Design a migration strategy for moving a monolithic Java application to a microservices architecture.

The current application:
- 500,000 lines of code
- Oracle database with 200+ tables
- Handles 50,000 daily users
- Has complex business logic in stored procedures

Include phasing, testing strategy, and risk mitigation.
```

## Interpreting Results

Atlas generates comprehensive architecture specifications that include:

1. **Overview**: High-level description of the architecture
2. **Component Design**: Detailed specifications for each component
3. **Interaction Patterns**: How components communicate
4. **Deployment Model**: How to deploy the architecture
5. **Considerations**: Trade-offs, alternatives, and justifications
6. **Diagrams**: Visual representations of the architecture

Review the entire document, paying special attention to:

- **Trade-offs**: Atlas will explain pros and cons of design decisions
- **Alternatives**: Other approaches that were considered
- **Scaling considerations**: How the architecture can grow
- **Security implications**: Potential security concerns and mitigations

## Best Practices

### Iterative Refinement

1. Start with a high-level request to get the overall architecture
2. Ask follow-up questions to clarify specific components
3. Request detailed design for the most critical components

### Provide Context

1. Include information about existing systems when relevant
2. Mention specific challenges or constraints
3. Provide background on non-functional requirements

### Collaborate with Atlas

1. Ask Atlas to explain reasoning behind specific decisions
2. Request alternatives if you're not satisfied with a design choice
3. Use Atlas to compare different architectural approaches

## Troubleshooting

### Incomplete or Generic Responses

If Atlas provides generic or incomplete responses:

1. Be more specific in your requirements
2. Break down your request into smaller, focused questions
3. Provide more context about your specific use case

### Technical Limitations

Atlas has some limitations:

1. It cannot directly access your codebase or infrastructure
2. It works with information you provide plus its built-in knowledge
3. It may not be aware of very recent technologies or frameworks

## Advanced Usage

### Creating Architecture Decision Records (ADRs)

```
Create an ADR for choosing a message broker for our microservices architecture.

Context:
- Need to support both synchronous and asynchronous communication
- Expect high throughput (10K messages/second)
- Require at-least-once delivery guarantee
- Looking at Kafka, RabbitMQ, and Google Pub/Sub

Please include pros/cons of each option and a justified recommendation.
```

### Generating Technical Specifications

```
Create a detailed technical specification for the authentication system of our mobile banking app.

Requirements:
- Multi-factor authentication
- Biometric support (fingerprint and face ID)
- OAuth2 integration with social providers
- JWT token-based auth with refresh tokens
- Compliance with financial sector regulations

Include API contract, security measures, and implementation guidelines.
```

## Tips from Expert Users

1. **Be clear about constraints**: Explicitly state business, technical, or resource constraints
2. **Start broad, then narrow**: Begin with high-level architecture, then drill down into specifics
3. **Challenge the design**: Ask "What are potential drawbacks of this approach?"
4. **Explore alternatives**: Ask "What alternative approaches could work here?"
5. **Ask for examples**: Request code snippets or configuration examples for critical components