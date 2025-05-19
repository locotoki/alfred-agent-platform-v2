# RAG Service – system_context_diagram

# System Context Diagram (C4 Level 1)

```mermaid
graph TD
    subgraph External Systems
        Users[(End Users)]
        OpenAI[OpenAI API]
    end
    Agents{Agents}
    Gateway[RAG Gateway]
    Vector[Qdrant<br/>Vector DB]
    Supabase[(Supabase Auth + DB)]
    Redis[(Redis Bus)]
    Prom[Prometheus]

    Users --> Agents
    Agents --> Gateway
    Gateway --> Vector
    Gateway --> Supabase
    Agents -->|events| Redis
    Gateway -->|metrics| Prom
    OpenAI --> Gateway
```

**Trust Boundaries**

* Public Internet: Agents ↔︎ Gateway when outside cluster

* Private VLAN: Gateway ↔︎ Qdrant / Supabase
