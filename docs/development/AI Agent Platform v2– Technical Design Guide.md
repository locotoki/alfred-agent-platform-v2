# **AI Agent Platform v2– Technical Design Guide**

## **Purpose**

This document serves as a comprehensive **technical design guide** for rearchitecting the **Alfred Agent Platform**. The platform will leverage **Supabase** for state storage and **Pub/Sub** for messaging, ensuring scalability, flexibility, and future-proofing. The system will be modular, event-driven, and designed to scale horizontally across multiple agents, services, and data layers.

---

## **1. High-Level System Design**

### **Key Design Principles**

### **Scalability**

- **Horizontal Scalability**: The system should scale across multiple containers or nodes, ensuring that services such as agents, state stores, and messaging brokers can expand as task volume increases.
- **Distributed Systems**: Design the system to handle distributed workloads with independent scaling for each component (agents, database, Pub/Sub).
- **Cloud-Native**: Leverage cloud-native tools (like **Google Cloud Run**, **AWS Lambda**, **Kubernetes**) to auto-scale and optimize cloud usage.

### **Modularity**

- **Loose Coupling**: Components such as agents, databases, and messaging layers should communicate via standardized envelopes (e.g., A2A schema). This decouples components, allowing them to evolve independently.
- **Microservices**: The system will be designed with independent services (agents, databases, task processing) so that each can scale and evolve without causing disruptions to others.

### **Flexibility & Extensibility**

- **Open Standards**: Stick to open standards and protocols (e.g., **A2A envelope schema**, JSON), making the system easily extensible and adaptable to new technologies.
- **Pluggable Agents**: Agents should be replaceable or extendable with minimal disruption, following a standard interface for communication (via **Pub/Sub**).

### **Security & Privacy**

- **Role-Based Access Control (RBAC)**: Implement RBAC for controlling access to tasks and sensitive data.
- **Data Encryption**: Ensure data encryption in transit (TLS/SSL) and at rest, particularly for sensitive user or task data.
- **Audit & Compliance**: Keep an audit trail of agent actions and task processing to comply with data protection regulations like **GDPR**.

### **Observability & Monitoring**

- **End-to-End Tracing**: Implement distributed tracing across tasks, agents, and services using **OpenTelemetry** or **Jaeger**.
- **Metrics & Alerts**: Set up custom monitoring and alerting with **Prometheus**, **Grafana**, and **Google Cloud Monitoring** to ensure task success, system performance, and error handling.

---

## **2. Core Components and Technologies**

### **a) Transport Layer (Pub/Sub)**

- **Google Cloud Pub/Sub** will remain the primary messaging layer for inter-agent communication, providing **exactly-once** semantics.
- **Task Communication**: Agents will communicate through two main topics:
    - `a2a.tasks.create` (for task initiation)
    - `a2a.tasks.completed` (for task completion)
- **Broker Independence**: While **Pub/Sub** is the primary broker, the platform can support alternative transport layers (e.g., **Supabase Realtime**, **Redis Streams**) via modular adapters.

### **a) Transport Layer (**Service Discovery)

- Agents register their card at startup to agent_registry table
- Service discovery queries Supabase for active agents
- Registry updates on health check failures
- Agents cache registry locally with 60s aTTL

### **b) State & Task Storage (Supabase)**

- **Supabase** will replace Firestore for state storage. It uses **Postgres** with the **pgvector** extension for vector-based storage, ensuring that the platform has both SQL capabilities and vector support in one place.
- **Task State Storage**: Tasks will be stored in **Postgres** using structured tables. Supabase's real-time capabilities will push updates to clients (like the **Mission Control UI**).
- **Vector Store**: **pgvector** will be used for storing and querying vector embeddings, enabling efficient semantic searches.

### **c) Vector Storage (Qdrant)**

- **Qdrant** will continue to be used for **vector search** because it provides optimizations like **HNSW** (Hierarchical Navigable Small World) for fast nearest-neighbor search. **Supabase**'s **pgvector** may not perform as well for large-scale vector searches.

### **d) AI Agent Framework (LangChain & LangGraph)**

- **LangChain** will orchestrate task workflows by chaining multiple LLM calls and integrating external APIs. It provides a simple interface to manage complex decision-making logic in agents.
- **LangGraph** will be used for clustering, reasoning, and advanced data relationship mapping, especially for agents like **SocialIntelligence** and **LegalCompliance**.

### **e) Observability & Monitoring**

- **LangSmith** will be used to test, monitor, and debug agent workflows. It integrates directly with **LangChain** and helps ensure that task envelopes are processed correctly.
- **Prometheus** and **Grafana** will handle system metrics, while **OpenTelemetry** will be used for tracing and monitoring task performance across distributed agents.

---

## **3. Detailed Architecture**

### **3.1 Agent Workflow**

1. **Task Creation**: When a task is triggered (via **Slack bot** or other sources), the entry agent (e.g., Alfred) will publish a message to the `a2a.tasks.create` topic.
2. **Task Processing**:
    - The agent responsible for the task will subscribe to the task creation message, process the task, and possibly call other agents or external APIs as part of the task workflow.
    - Agents use **LangChain** to orchestrate workflows (e.g., invoking **LangGraph** for reasoning or clustering data).
3. **Task Completion**: Once the agent completes its task, it will publish the `a2a.tasks.completed` message, containing the results of the task and any follow-up actions needed.
4. **State Storage**: The task’s status and data will be saved in **Supabase Postgres**. Vectors or embeddings related to the task will be stored in **Qdrant** or **pgvector** for fast search.

### **3.2 Data Flow Diagram (Updated)**

```
pgsql
CopyEdit
@startuml
skinparam componentStyle rectangle
skinparam cloudColor LightBlue
skinparam frameBorderColor Gray
actor "Slack / UI" as S
frame "Local Docker Compose" {
  component "Alfred\n(Slack Bot)" as A
  component "SocialIntelligenceAgent (LangChain)" as SI
  component "LegalComplianceAgent (LangGraph)"  as LC
  component "FinancialTaxAgent" as FT
  component "N8N\n(Worker)" as N8N
  database  "Supabase DB\n(Postgres + pgvector)" as R
  component "Qdrant\n(Vector DB)" as QD
  component "Firebase Emulator\n(Functions + Firestore)" as FE
  cloud     "Pub/Sub Emulator"       as PE
  component "LangSmith"              as LS
}
frame "Google Cloud (Prod option)" {
  cloud     "Cloud Pub/Sub"  as GCPPS
  database  "Supabase DB"      as GCF
  component "Cloud Run\nAgents" as CRA
}
queue "Dead-Letter Topic" as DLQ
S  -->  A : Slash / DM
A  -->  PE : a2a.tasks.create
A  -->  GCPPS : (when prod)
PE --> SI
PE --> LC
PE --> FT
PE --> N8N
SI --> PE : a2a.tasks.completed
LC --> PE
FT --> PE
PE --> DLQ : >5 attempts
SI --> QD : upsert vectors
SI --> R  : cache lookups
N8N --> R : state cache
N8N --> S  : Slack updates
LS --> SI : monitor workflow
FE  --> R  : state cache
PE ..> GCPPS : same topics (switch env)
@enduml

```

---

## **4. System Implementation**

### **4.1 Setup Supabase**

1. **Install Supabase** with Docker Compose:

    ```yaml
    yaml
    CopyEdit
    services:
      supabase-db:
        image: supabase/postgres:16
      supabase-rest:
        image: supabase/postgrest
      supabase-realtime:
        image: supabase/realtime

    ```

2. **Configure pgvector**: Install `pgvector` to support vector storage:

    ```sql
    sql
    CopyEdit
    CREATE EXTENSION IF NOT EXISTS pgvector;

    ```


### **4.2 Code Changes**

1. **State Store Migration**: Replace Firestore client with Postgres using `asyncpg`:

    ```python
    python
    CopyEdit
    import asyncpg
    conn = await asyncpg.connect("postgres://supabase_user@supabase:5432/postgres")
    await conn.execute("INSERT INTO tasks ...")

    ```

2. **Integrate LangChain**: Orchestrate agent workflows with **LangChain**.
    - Use **LangChain’s AgentExecutor** to define and execute task chains.
3. **Real-Time Updates**: For live updates, integrate **Supabase Realtime** via **WebSockets** in the UI.

---

## **5. Future-Proofing Considerations**

### **5.1 Multi-Cloud & Hybrid Architecture**

- Design the platform to be **cloud-agnostic**, enabling deployment across **AWS**, **GCP**, or hybrid environments.
- **Serverless Options**: Use serverless computing (e.g., **AWS Lambda**, **Cloud Run**) for stateless components (e.g., task processing agents).

### **5.2 Agent Extensibility**

- Use **plug-and-play** agent design so that new agents can be added with minimal changes to existing infrastructure. Each agent will follow the **A2A schema** to ensure consistent communication and interoperability.

### **5.3 Open Standards for Communication**

- Adhere to open data formats (e.g., JSON) and protocols for agent interaction to make it easier to integrate with third-party services or tools.

---

## **6. Next Steps and Engineering Tasks**

1. **Set Up Supabase**: Initialize Supabase for state storage and vector support (pgvector).
2. **Reimplement State Logic**: Migrate Firestore logic to **asyncpg** for Postgres interactions.
3. **Integrate Pub/Sub**: Keep **Pub/Sub** for agent messaging and ensure exactly-once delivery.
4. **Develop LangChain Workflows**: Build agent workflows using **LangChain** and integrate **LangGraph** for reasoning.
5. **Implement Real-time Dashboard**: Use **Supabase Realtime** to update UI with task statuses.
6. **Monitor & Test**: Set up **LangSmith** for monitoring and debugging agent workflows.

---

## **7. Conclusion**

This design guides the transformation of your Alfred Agent Platform into a modular, scalable, and future-proof system. By using **Supabase** for state storage and maintaining **Pub/Sub** for messaging, you ensure a reliable foundation for building intelligent agents capable of handling complex workflows. The platform's modularity and scalability will allow for easy integration with new technologies as the system evolves.

Let me know if you'd like further clarifications or to start implementing any specific part of this plan!
