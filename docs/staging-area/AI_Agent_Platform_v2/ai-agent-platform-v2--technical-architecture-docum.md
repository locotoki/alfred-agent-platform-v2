# AI Agent Platform v2- Technical Architecture Document

# **AI Agent Platform v2- Technical Architecture Document**

## 1 Architecture Snapshot (v2 fusion)

```
java
CopyEdit
┌────────────────────────────────────────────────────────────────┐
│                    Mission-Control UI (Next.js)               │
│        ⬑ Supabase Realtime websockets for live status         │
└────────────────────────────────────────────────────────────────┘
                ▲                             |
                | HTTP (agent card, health)   | WebSocket
┌───────────────┴───────────────┐   ┌────────┴────────┐
│  Specialist Agents (Docker)   │   │ Entry Agent     │
│  • SocialIntel (LangGraph)    │   │  Alfred Slack   │
│  • LegalCompliance (LangGraph)│   │  Bot            │
│  • …                          │   └─────────────────┘
│        |        ▲                         ▲
│        | gRPC   | LangGraph calls         │
└────────┼────────┘                         │
         │                                  │
         ▼                                  │
   ┌────────────┐  Pub/Sub  ┌────────────┐  │
   │ a2a.tasks  │◄──────────┤ a2a.tasks  │◄─┘
   │   .create  │           │ .completed │   Exactly-once
   └────────────┘           └────────────┘   Guarantees
         ▲                                  (see §2.2)
         │
┌────────┴─────────┐
│  Supabase DB     │           ┌───────────┐
│  (Postgres +     │           │  Qdrant   │
│   pgvector)      │           │  Vector   │
└──────────────────┘           └───────────┘

```

*Key deltas from the first diagram*

- **Firestore gone** → dedupe & state land in Supabase Postgres.
- A2A adapter library lives in `libs/pubsub_adapter/` and marshals envelopes for every agent process.
- LangSmith spans exported to Cloud Trace for one dashboard.

---

## 2 Engineering Tasks (ordered)

### 2.1 A2A Adapter Library (⭐ start here)

- Wrap / unwrap envelope; validate with the canonical JSON Schema.
- Add `trace_id` + `correlation_id`.
- Auto-generate `agent.json` from Python `dataclass` so we never drift.

```python
python
CopyEdit
# libs/pubsub_adapter/envelope.py
from pydantic import BaseModel, Field
class Artifact(BaseModel):
    key: str
    uri: str
class A2AEnvelope(BaseModel):
    intent: str
    role: str
    artifacts: list[Artifact] = Field(default_factory=list)
    trace_id: str
    correlation_id: str | None = None

```

### 2.2 Exactly-Once Handler

```sql
sql
CopyEdit
-- Supabase migration file
create table processed_msgs (
  message_id  text primary key,
  processed_at timestamp default now()
);
create index on processed_msgs (processed_at);

```

```python
python
CopyEdit
async def already_seen(conn, message_id: str) -> bool:
    try:
        await conn.execute(
            "insert into processed_msgs(message_id) values($1) on conflict do nothing",
            message_id,
        )
        return False
    except asyncpg.UniqueViolationError:
        return True

```

A daily Supabase `cron` job deletes rows older than 48 h to keep the table slim.

### 2.3 Policy Middleware

- Tiny decorator executed before every LangChain chain:
    - PII scrub (regex + `google.udf.redact` optional)
    - Rate-limit per `slack_user_id` via Redis‐in-memory counter.
    - Profanity filter (OpenAI `moderation` or free `profanity-check`).

### 2.4 Tracing & Evaluation

- `langsmith` Python SDK already captures steps; add:

```python
python
CopyEdit
import opentelemetry.trace as ot

tracer = ot.get_tracer("alfred")
with tracer.start_as_current_span("pubsub_handler", attributes={"trace_id": trace_id}):
    ...

```

- Export to Cloud Trace; Grafana Cloud-Run dashboard already imported.

### 2.5 CI / CD Pipelines

- **Unit tests** (`pytest -m fast`) run on every PR.
- **Smoke test** GitHub Actions job:
    1. `docker compose up -d supabase pubsub-emulator agents`
    2. Publish sample `a2a.tasks.create`.
    3. Assert a `tasks.completed` arrives within 20 s.

### 2.6 Autoscale Guard

- Cloud Run `maxInstances=20`, `minInstances=0`.
- PromQL alert: `pubsub.subscription.num_undelivered_messages > 1_000 for 5m`.

---

## 3 Sprint Plan (1 backend eng, 2-week sprint)

| Day | Deliverable |
| --- | --- |
| 1–2 | A2A adapter scaffolding + schema tests |
| 3–4 | Supabase dedupe table & handler integrated |
| 5 | Policy middleware (PII, rate-limit) |
| 6 | LangSmith + Cloud Trace wiring |
| 7–8 | Smoke-test GitHub Action passes locally |
| 9 | Mission-Control UI live-update via Supabase Realtime |
| 10 | Buffer / demo prep |

---

## 4 Future Spike → Vertex AI Engine

Keep a `make spike-vertex` target that:

- Builds an agent image with minimal shim (`gunicorn main:app`).
- Deploys to Vertex AI Agent Builder for cost-vs-latency metrics.
- Publishes result to BigQuery for side-by-side comparison.

---

### Next decision gate

*If* average daily tasks > 50 k *or* HIPAA attestation is signed, revisit Vertex; until then this stack keeps infra lean and dev-env identical to prod.

## **1. Overview**

The **AI Agent Platform** v2 is a modular, scalable, and event-driven system designed to handle AI-powered agents for processing tasks, orchestrating workflows, and managing state. The platform integrates **Supabase** for state storage, **Qdrant** for vector search, and **Pub/Sub** for event-driven messaging, while supporting an agent-based architecture with **LangChain** and **LangGraph**.

The system follows an **event-driven architecture (EDA)** with components loosely coupled through **task envelopes**, allowing for high scalability, fault tolerance, and future-proof integration with other AI models or services.

---

## **2. Key System Components**

### **2.1 Entry Agent (Alfred Slack Bot)**

- **Function**: The entry point for users, typically through **Slack** commands or direct messages.
- **Technology**: Built with **Slack Bolt SDK** and listens for slash commands and messages.
- **Responsibilities**:
    - Receive user input (e.g., a command to start a new task).
    - Publish a task to the **Pub/Sub** broker for further processing by specialized agents.
    - Provide task status updates through **Slack**.

### **2.2 Specialist Agents**

- **SocialIntelligenceAgent (LangChain)**:
    - **Function**: Process data related to trend analysis (scrape, cluster, summarize).
    - **Technology**: Uses **LangChain** for orchestration, integrating **LangGraph** for clustering and relationship analysis.
    - **Data Flow**: Retrieves data via APIs, processes it, and stores the results in **Qdrant** or **Supabase** for further search.
- **LegalComplianceAgent (LangGraph)**:
    - **Function**: Handles compliance updates, scraping government sites, and summarizing relevant regulations.
    - **Technology**: Uses **LangGraph** for reasoning and clustering, and **LangChain** for summarization tasks.
    - **Data Flow**: Scrapes websites, clusters data, and stores summaries and relevant documents in **Supabase**.
- **FinancialTaxAgent**:
    - **Function**: Provides tax estimates based on rate sheets.
    - **Technology**: Uses **LangChain** for orchestrating steps like data fetching, calculations, and publishing results.

### **2.3 Pub/Sub Layer (Event Spine)**

- **Function**: The messaging backbone for the platform, allowing agents to communicate via events.
- **Technology**: **Google Cloud Pub/Sub** (or **Pub/Sub emulator** for local development).
- **Responsibilities**:
    - **Task Topics**: Tasks are published on `a2a.tasks.create` and `a2a.tasks.completed` topics.
    - **Dead-Letter Queue (DLQ)**: Tasks that fail after a predefined number of attempts are sent to the **DLQ** for analysis and manual intervention.

### **2.4 State & Task Storage (Supabase)**

- **Function**: Store agent state and task-related data, including user inputs, results, and intermediate processing.
- **Technology**: **Supabase** (Postgres with **pgvector** for vector storage).
- **Responsibilities**:
    - Store agent tasks and metadata in Postgres tables.
    - Manage state for long-running tasks.
    - Store vectors (embeddings) in **pgvector** for semantic search.

### **2.5 Vector Search (Qdrant)**

- **Function**: Fast vector-based search for handling AI model embeddings and similarity matching.
- **Technology**: **Qdrant** provides optimized vector storage and search.
- **Responsibilities**:
    - Store embeddings generated by agents, such as trends, summarization, and clustering results.
    - Perform similarity searches to find relevant results quickly.

### **2.6 Observability & Monitoring (LangSmith)**

- **Function**: Provides visibility into agent workflows and ensures that tasks are executed correctly.
- **Technology**: **LangSmith** for debugging and performance monitoring.
- **Responsibilities**:
    - Trace tasks through the agent pipeline, monitoring **task envelopes**.
    - Collect metrics and logs for **Prometheus** and **Grafana** integration.

---

## **3. System Data Flow**

### **3.1 Task Creation and Execution Flow**

1. **User Input (Slack)**:
    - A user sends a command to **Alfred Slack Bot**, which triggers the task creation process.
2. **Task Published to Pub/Sub**:
    - Alfred publishes a message to the `a2a.tasks.create` topic on **Pub/Sub**, containing task details in the **A2A envelope format** (including `task_id`, `intent`, `content`, and `trace_id`).
3. **Specialist Agent Subscribes to Task**:
    - Specialized agents (e.g., **SocialIntelligenceAgent**) subscribe to `a2a.tasks.create` topics, retrieve the task, and process it based on the **intent** specified in the envelope.
4. **Processing & Storage**:
    - The agent processes the task, which may involve scraping data, clustering, or interacting with other APIs.
    - The agent stores the results (e.g., trends, clusters, summaries) in **Supabase** (task metadata, results, state) and **Qdrant** (vector embeddings).
5. **Task Completion**:
    - Once the agent completes its task, it publishes a message to `a2a.tasks.completed` on Pub/Sub, including task results and status updates.
6. **State & Real-Time Updates**:
    - The agent state is updated in **Supabase** and real-time updates (e.g., task status) are pushed to the **Mission Control UI** via **Supabase Realtime**.
7. **Task Completion Notification**:
    - **Alfred** or other frontend interfaces (e.g., web UI) are updated about task completion via **Slack** or a custom **Mission Control UI**.

### **3.2 Error Handling & Retry Logic**

- If a task fails (e.g., due to a network issue or agent failure), it will be retried based on a **backoff strategy**.
- If the task fails after several attempts, it will be moved to the **Dead-Letter Queue (DLQ)** for further investigation.

### **3.3 Agent Card Generation**

def generate_agent_card(agent_class):
    return {
        "schema_version": "0.4",
        "name": agent_class.**name**,
        "intents": agent_class.supported_intents,
        "role": agent_class.role,
        "endpoints": {
            "health": f"http://{agent_class.host}:{agent_class.port}/health"
        }
    }

---

## **4. System Design Considerations**

### **4.1 Scalability**

- **Horizontal Scaling**: The system is designed for horizontal scaling, where each agent can scale independently. For example, you can scale the **SocialIntelligenceAgent** based on incoming data volume.
- **Pub/Sub**: Since **Pub/Sub** is fully managed by Google Cloud, it automatically scales as the number of messages increases.

### **4.2 Fault Tolerance**

- **Retries & DLQ**: The system ensures that tasks are retried automatically before they are sent to the **Dead-Letter Queue**. This ensures that transient errors don't result in task loss.
- **Idempotency**: Each task has a unique `task_id` to ensure that tasks are processed only once, avoiding duplicates in the system.

### **4.3 Security**

- **Authorization & Authentication**: Use **OAuth** or **JWT** for securing agent interactions and authenticating users accessing the system through **Slack** or the **Mission Control UI**.
- **Encryption**: Data at rest (in **Supabase** and **Qdrant**) and in transit (via **TLS**) will be encrypted to protect sensitive information.

---

## **5. Integration with External Services**

- **External APIs**: Agents may interact with third-party APIs (e.g., scraping websites or querying external data). These interactions are abstracted within the agents themselves, ensuring minimal impact on the overall platform.
- **Future Integrations**: The system supports **plug-and-play** integration with additional agents, new AI models, or external services via **LangChain**'s modular framework.

---

## **6. Future-Proofing**

### **6.1 Extensibility**

- **Modular Agents**: New agents can be easily added by following the **A2A envelope schema** and publishing/subscribing to appropriate Pub/Sub topics. This approach ensures that adding new agents does not affect the overall system architecture.

### **6.2 Technology Upgrades**

- **AI Model Updates**: Future AI models (e.g., new versions of **GPT-4** or **Claude**) can be integrated into the platform by modifying the agent’s processing logic without changing the core architecture.
- **Database Evolution**: If you choose to migrate away from **Supabase Postgres** to another database in the future, the **Pub/Sub** layer and agent envelopes will remain compatible, minimizing the need for major rewrites.

---

## **7. Conclusion**

This **Technical Architecture Document** outlines the rearchitected Alfred Agent Platform, focusing on modularity, scalability, and fault tolerance. By leveraging **Supabase** for state storage, **Qdrant** for vector search, and **Pub/Sub** for event-driven communication, the system is poised for scalability and easy integration with future technologies.

The design supports a **plug-and-play** agent framework, **real-time task monitoring**, and **end-to-end tracing**, ensuring a highly maintainable and extensible platform.

Let me know if you need additional details or revisions to the architecture!