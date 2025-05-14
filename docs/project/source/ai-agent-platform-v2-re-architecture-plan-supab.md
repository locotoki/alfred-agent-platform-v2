# AI Agent Platform v2 – Re-architecture Plan (Supabase + Pub/Sub)

## **AI Agent Platform v2 – Rearchitecture Plan (Supabase + Pub/Sub)**

### **1. Core Technology Stack**

| Layer | Tech | Notes |
| --- | --- | --- |
| **LLM** | Ollama (Llama 3) | Local GPU |
| **Front-end** | Open WebUI | Port `3000` |
| **Entry Agent** | Alfred Slack bot | Port `8011` |
| **Specialist Agents** | Social Intel (LangGraph), LegalCompliance | Ports `9000` (or specific agent ports) |
| **Transport** | **Pub/Sub** | Google Cloud Pub/Sub (local emulator for dev) |
| **State Store** | **Supabase** | Postgres database (with `pgvector` extension for vectors) |
| **Vector Store** | **Qdrant** | Port `6333/6334` |
| **Observability** | LangSmith (local) | Port `1984` |

### **2. New System Architecture**

With Supabase handling the state storage and Postgres as the central database, and **Pub/Sub** still in use for message handling, the architecture changes slightly from the previous version.

### **Key Changes**:

- **Supabase** will handle both state storage and vector-based search via **pgvector**.
- **Pub/Sub** will continue to manage agent-to-agent communication (task creation, completion).
- **Qdrant** will still be used for vector-based search as it offers optimized search algorithms that **pgvector** in Postgres may not match in terms of performance.

---

### **3. Detailed Components and Integration**

### **3.1 Supabase as the State Store**

- **Postgres Database**: Supabase provides a SQL database with full **Postgres** support. Use **pgvector** for storing vector embeddings (replacing **Firestore** and external vector stores).
- **State Store Migration**: You’ll need to rewrite the logic that interacts with Firestore and connect it to Supabase. This will require using **asyncpg** for database connections and writing SQL queries to handle state management.
    - Example: Replace Firestore-specific code with `asyncpg` in Python.
        
        ```python
        python
        CopyEdit
        import asyncpg
        conn = await asyncpg.connect("postgres://supabase_user@supabase:5432/postgres")
        await conn.execute("INSERT INTO tasks ...")
        
        ```
        
- **Real-time Features**: Supabase's **Realtime** feature will be useful for sending live updates (e.g., task status updates to the **Mission Control UI**).

### **3.2 Pub/Sub for Messaging**

- **Pub/Sub** will continue to manage communication between agents (task creation and completion). It provides **exactly-once** semantics, which makes it a reliable option for event-driven systems.
    - **Task Creation**: Agents will continue to publish tasks to `a2a.tasks.create`.
    - **Task Completion**: Upon completion, agents will publish messages to `a2a.tasks.completed`.
- **Supabase Realtime** can be used for **dashboard updates**, but **Pub/Sub** will remain the primary transport layer for tasks between agents to ensure high reliability and scalability.

### **3.3 Qdrant for Vector Search**

- **Qdrant** remains in place for fast vector search and similarity matching, as **pgvector** in Postgres is not as optimized for complex vector searches.
    - Supabase will handle other data, but **Qdrant** will continue to store and search vector data (e.g., embeddings for task content or agent knowledge).

### **3.4 LangChain & LangGraph Integration**

- **LangChain**: Continue using **LangChain** for chaining tasks and interacting with external APIs. The agents will be responsible for orchestrating task workflows and decision-making using LangChain.
- **LangGraph**: This will still be used for clustering and reasoning in agents like **SocialIntelligence** and **LegalCompliance**.

### **3.5 Observability with LangSmith**

- **LangSmith** will monitor and test the agent workflows to ensure that the **task envelopes** are processed correctly and agents are functioning as expected.
- **Tracing**: Implement **trace_id** for all Pub/Sub messages to provide end-to-end tracing of tasks across agents.

---

### **4. Migration Plan**

1. **Supabase Setup**:
    - Set up a **Supabase project** and configure Postgres with the **pgvector** extension.
    - Update the Docker Compose file to include Supabase, replacing Firestore:
        
        ```yaml
        yaml
        CopyEdit
        services:
          supabase-db:
            image: supabase/postgres:16
            networks: [ai-infra-network]
          supabase-rest:
            image: supabase/postgrest
          supabase-realtime:
            image: supabase/realtime
        
        ```
        
2. **Replace Firestore Logic**:
    - **State Store**: Replace Firestore interactions with SQL queries using **asyncpg**.
        - Example: In place of Firestore’s task storage:
            
            ```python
            python
            CopyEdit
            import asyncpg
            conn = await asyncpg.connect("postgres://supabase_user@supabase:5432/postgres")
            await conn.execute("INSERT INTO tasks ...")
            
            ```
            
3. **Pub/Sub Integration**:
    - Ensure that the **Pub/Sub** configuration remains intact, and the `a2a.tasks.create` and `a2a.tasks.completed` topics continue to operate smoothly.
    - The agents will publish and subscribe to **Pub/Sub** for communication, ensuring that messages are delivered and processed as per the A2A schema.
4. **Real-time Dashboard**:
    - Use **Supabase Realtime** for live task tracking (e.g., using websockets to push updates to the **Mission Control UI**).
5. **Vector Search**:
    - Continue using **Qdrant** for vector searches, as **pgvector** does not match Qdrant’s performance in this area.

---

### **5. Next Steps and Engineering Tasks**

1. **Supabase Setup**:
    - Install and configure Supabase for Postgres with **pgvector** for vector search.
    - Implement Docker Compose configuration to start Supabase services.
2. **Code Migration**:
    - Migrate agent logic to use **asyncpg** for database interactions.
    - Replace Firestore-related logic with SQL queries for task storage.
3. **Reconfigure Transport Layer**:
    - Ensure Pub/Sub topics and communication paths remain functional.
    - Set up **Supabase Realtime** to push live task updates to the UI.
4. **Testing**:
    - Set up **unit tests** to ensure that tasks are properly deduplicated and that agent workflows are functioning as expected with Supabase and Pub/Sub.
    - Implement **smoke tests** to verify that Pub/Sub communication and task completion flows work correctly.
5. **Observability Setup**:
    - Ensure **trace_id** is used in all messages for end-to-end tracing via **LangSmith**.

---

### **6. Advantages of This Architecture**

- **Open Source**: Moving to **Supabase** and keeping **Pub/Sub** ensures an open-source stack with robust event-driven communication.
- **Scalability**: **Pub/Sub** will continue to scale well for inter-agent communication, while **Supabase** offers a strong Postgres foundation for state storage and vector search.
- **Cost Efficiency**: With **Supabase self-hosted**, you can reduce costs compared to proprietary solutions like Firebase, while also keeping full control over the database and infrastructure.

---

### **Conclusion**

By rearchitecting the Alfred Agent Platform around **Supabase** for state management and continuing to use **Pub/Sub** for messaging, you’ll have an open-source, scalable platform that retains flexibility and future-proofing for integration with other tools. The architecture will provide robust handling of state and messaging, while also offering a path forward for scaling and optimization.

Let me know if you'd like to dive deeper into any part of this plan or if you're ready to begin