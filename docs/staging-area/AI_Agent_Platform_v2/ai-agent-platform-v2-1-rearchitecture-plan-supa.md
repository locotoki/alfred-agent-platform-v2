# AI Agent Platform v2.1 – Rearchitecture Plan (Supabase + Pub/Sub + A2A)

## **AI Agent Platform v2.1 – Rearchitecture Plan (Supabase + Pub/Sub + A2A)**

### **1. Core Technology Stack**

```
LayerTechNotesLLMOllama (Llama 3)Local GPU + LangChain for external LLMs laterFront-endMission Control UI (Next.js)Port3000, Supabase Realtime websocketsEntry AgentAlfred Slack botPort8011Specialist AgentsSocialIntel (LangGraph), LegalCompliance (LangGraph)Ports9000+ (Docker containers)TransportPub/SubGoogle Cloud Pub/Sub (local emulator for dev)State StoreSupabasePostgres database with pgvector extensionVector StoreQdrantPort6333/6334 for optimized vector searchObservabilityLangSmith → Cloud TracePort1984 for dev, traces to Cloud TraceA2A AdapterCustom librarylibs/pubsub_adapter/ for envelope handling
```

### **2. System Architecture (v2 Fusion)**

```

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
│  • ...                        │   └─────────────────┘
│        |        ▲                         ▲
│        | gRPC   | LangGraph calls         │
└────────┼────────┘                         │
         │                                  │
         ▼                                  │
   ┌────────────┐  Pub/Sub  ┌────────────┐  │
   │ a2a.tasks  │◄──────────┤ a2a.tasks  │◄─┘
   │   .create  │           │ .completed │   Exactly-once
   └────────────┘           └────────────┘   Guarantees
         ▲
         │
┌────────┴─────────┐
│  Supabase DB     │           ┌───────────┐
│  (Postgres +     │           │  Qdrant   │
│   pgvector)      │           │  Vector   │
└──────────────────┘           └───────────┘

```

**Key Changes from Original Plan**:

- Firestore removed entirely → all state/dedupe in Supabase Postgres
- Added A2A adapter library for envelope handling
- LangSmith traces exported to Cloud Trace for unified monitoring
- Explicit gRPC support for agent communication
- LangGraph chosen over Vertex AI for local-first development

### **3. Core Components and Integration**

### **3.1 A2A Adapter Library**

- Located in `libs/pubsub_adapter/`
- Handles envelope wrapping/unwrapping with A2A schema validation
- Adds `trace_id` and `correlation_id` to all messages
- Auto-generates `agent.json` from Python dataclasses

```python

python
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

### **3.2 Exactly-Once Processing**

Implement dedupe using Supabase:

```sql

sql
-- Supabase migration
create table processed_msgs (
  message_id text primary key,
  processed_at timestamp default now()
);
create index on processed_msgs (processed_at);

```

```python

python
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

```python
-- Complete database schema
create table tasks (
  id uuid primary key,
  intent text not null,
  status text not null,
  created_at timestamp default now()
);

create table results (
  id uuid primary key,
  task_id uuid references tasks(id),
  content jsonb,
  created_at timestamp default now()
);

create table agent_registry (
  id uuid primary key,
  name text unique,
  card jsonb,
  last_seen timestamp
);
```

### **3.3 Policy Middleware**

Implement as decorators before LangChain chains:

- PII scrubbing (regex + optional `google.udf.redact`)
- Rate limiting per `slack_user_id` via Redis
- Profanity filtering (OpenAI moderation or profanity-check library)

```python
# Redis rate limiting
import redis
r = redis.Redis(host='redis', port=6379)

def rate_limit(user_id: str, limit: int = 60):
key = f"rl:{user_id}"
current = r.incr(key)
if current == 1:
r.expire(key, 60)
if current > limit:
raise RateLimitExceeded()
```

### **3.4 Observability Stack**

- LangSmith for agent workflow debugging
- OpenTelemetry for distributed tracing
- Export spans to Cloud Trace
- Grafana dashboards for metrics

```python

python
import opentelemetry.trace as ot

tracer = ot.get_tracer("alfred")
with tracer.start_as_current_span("pubsub_handler", attributes={"trace_id": trace_id}):
# agent logic here

```

### **4. Engineering Tasks (Prioritized)**

```
PriorityTaskDescription1A2A Adapter LibraryCreate base envelope handler with schema validation2Supabase SetupConfigure Postgres + pgvector, dedupe table3Exactly-Once HandlerImplement message deduplication logic4Policy MiddlewareAdd PII scrub, rate limit, profanity filter5LangChain IntegrationWire up SocialIntel and LegalCompliance agents6Tracing & MonitoringConnect LangSmith → Cloud Trace7CI/CD PipelineSet up GitHub Actions with smoke tests8Mission Control UIAdd Supabase Realtime for live updates9Autoscaling GuardsConfigure Cloud Run limits and alerts
```

### **5. Sprint Plan (2-week, 1 Backend Engineer)**

```
DayDeliverable1-2A2A adapter scaffolding + schema tests3-4Supabase dedupe table & handler integrated5Policy middleware (PII, rate-limit)6LangSmith + Cloud Trace wiring7-8Smoke-test GitHub Action passes locally9Mission-Control UI live-update via Supabase Realtime10Buffer / demo prep
```

### **6. Deployment Strategy**

### **6.1 Local Development**

- Docker Compose with all services
- Pub/Sub emulator for messaging
- Supabase local instance
- Git LFS for model files

### **6.2 CI/CD**

- GitHub Actions for builds
- pytest for unit tests
- Smoke tests with docker-compose
- Auto-deploy to Cloud Run on main branch

### **6.3 Production Considerations**

- Cloud Run with `maxInstances=20, minInstances=0`
- Prometheus alerts for queue depth > 1,000 messages
- Daily cron job to clean old messages from dedupe table

### **7. Future Considerations**

### **7.1 Vertex AI Migration Path**

Maintain ability to migrate if:

- Daily tasks exceed 50k
- HIPAA compliance required
- Need managed autoscaling

Keep `make spike-vertex` target for comparison testing.

### **7.2 Technology Decisions**

- **LangChain + LangGraph chosen over Vertex AI** for:
    - Local-first development
    - Full graph flexibility
    - Lower costs
    - Vendor portability
    - Open-source community support

### **8. Key Architecture Principles**

1. **Local-First**: Everything runs in Docker Compose
2. **Cloud-Optional**: Same stack locally and in production
3. **Open Standards**: A2A envelope schema, JSON throughout
4. **Incremental Scaling**: Start small, add services as needed
5. **Observable by Default**: Tracing from day one

### **Next Steps**

1. Create repository structure
2. Implement A2A adapter library
3. Set up Supabase with pgvector
4. Configure CI pipeline
5. Build first agent (SocialIntel)

This architecture provides the foundation for a scalable, maintainable AI agent platform while keeping development velocity high and operational costs low.

[**AI Agent Platform v2 – Re-architecture Plan (Supabase + Pub/Sub)**](AI%20Agent%20Platform%20v2%20%E2%80%93%20Re-architecture%20Plan%20(Supab%201e8b4fd21ff0807cb7b3daf15a63bda6.md)
