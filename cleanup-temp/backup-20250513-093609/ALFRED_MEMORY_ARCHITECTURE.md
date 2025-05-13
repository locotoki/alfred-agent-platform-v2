# Alfred Memory Architecture

*Document Created: May 13, 2025*  
*Prepared for: Atlas (Architecture Agent)*  
*Status: Planning Phase*

## 1. Overview

This document provides a comprehensive architecture proposal for implementing robust memory capabilities in the Alfred Agent Platform v2. The memory system will enable agents to maintain context across conversations, recall relevant historical information, and provide personalized experiences to users.

The architecture follows the platform's design principles of modularity, scalability, and flexibility while enhancing agent capabilities through multi-tiered memory management.

## 2. Current State Assessment

### 2.1 Existing Infrastructure

The platform already has several components that can be leveraged for memory implementation:

1. **PostgreSQL/Supabase**
   - Used for task tracking and agent registry
   - Structured data storage with JSON capabilities
   - Supports pgvector extension for embeddings
   - Tables: `tasks`, `task_results`, `processed_messages`, `agent_registry`

2. **Redis**
   - Used for caching and policy middleware
   - Supports TTL-based expiry for ephemeral data
   - Currently underutilized for stateful features

3. **Qdrant Vector Database**
   - Used for RAG implementation
   - Supports vector search for semantic retrieval
   - Already integrated with agent services

4. **Object Storage**
   - Available through Supabase Storage
   - Suitable for long-term archival

### 2.2 Current Memory Implementation

The current platform has limited memory capabilities:

1. **Session-Based Memory (Streamlit UI)**
   - In-memory storage of conversation history
   - Limited to single session duration
   - No persistence across sessions

2. **Task Tracking (BaseAgent)**
   - Tracks task status and results
   - No conversational context preservation
   - No association between related tasks

3. **Missing Components**
   - No standardized memory interface for agents
   - No short-term conversation memory
   - No long-term semantic memory
   - No memory integration between interfaces (Slack, UI)

## 3. Memory Architecture Design

The proposed architecture implements a multi-tiered memory system:

```
┌─────────────────────────────────────────────────────────────┐
│                   Unified Memory Interface                   │
│                                                             │
│  ┌─────────────┐      ┌─────────────────┐      ┌──────────┐ │
│  │ Short-Term  │      │   Medium-Term   │      │ Long-Term │ │
│  │   Memory    │◄────►│     Memory      │◄────►│  Memory   │ │
│  │  (Redis)    │      │  (PostgreSQL)   │      │ (Qdrant)  │ │
│  └─────────────┘      └─────────────────┘      └──────────┘ │
└───────────┬───────────────────┬─────────────────────┬───────┘
            │                   │                     │
┌───────────▼───────┐   ┌───────▼───────┐     ┌───────▼───────┐
│    Agent Layer    │   │ Interface Layer│     │ Analytics Layer│
│  Memory-Enabled   │   │ Slack, UI, API │     │ Optimization  │
│      Agents       │   │   Integration  │     │ & Governance  │
└───────────────────┘   └───────────────┘     └───────────────┘
```

### 3.1 Memory Tiers

#### Short-Term Memory (Redis)
- **Purpose**: Immediate context for active sessions
- **Storage**: Redis with TTL-based expiry
- **Contents**: Recent messages, active context, session metadata
- **Retention**: Hours to days (configurable TTL)
- **Access Pattern**: High-frequency, low-latency

#### Medium-Term Memory (PostgreSQL)
- **Purpose**: Conversation history and structured memory
- **Storage**: Supabase PostgreSQL tables
- **Contents**: Full conversation history, summaries, metadata
- **Retention**: Weeks to months
- **Access Pattern**: Medium frequency, relational queries

#### Long-Term Memory (Vector Database)
- **Purpose**: Semantic knowledge and pattern recognition
- **Storage**: Qdrant vector collections
- **Contents**: Embeddings of conversation content with metadata
- **Retention**: Months to years
- **Access Pattern**: Similarity-based retrieval

### 3.2 Core Components

#### Memory Interface

A standardized interface for memory operations:

```python
class Memory:
    async def add_message(self, session_id: str, message: Dict[str, Any]) -> None:
        """Add a message to the conversation memory."""
        pass
        
    async def get_recent_messages(self, session_id: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent messages from the conversation memory."""
        pass
        
    async def get_conversation_summary(self, session_id: str) -> str:
        """Get a summary of the conversation."""
        pass
        
    async def search_semantic_memory(self, query: str, limit: int = 5) -> List[Dict[str, Any]]:
        """Search semantic memory for relevant information."""
        pass
        
    async def clear_session(self, session_id: str) -> None:
        """Clear the conversation memory for a session."""
        pass
```

#### Memory-Enabled Agent

Extension of the BaseAgent with memory capabilities:

```python
class MemoryEnabledAgent(BaseAgent):
    def __init__(
        self,
        name: str,
        version: str,
        supported_intents: List[str],
        pubsub_transport: PubSubTransport,
        supabase_transport: SupabaseTransport,
        policy_middleware: PolicyMiddleware,
        memory: UnifiedMemory
    ):
        super().__init__(
            name, version, supported_intents, 
            pubsub_transport, supabase_transport, policy_middleware
        )
        self.memory = memory
        
    async def process_task(self, envelope: A2AEnvelope) -> Dict[str, Any]:
        """Process a task with memory context enhancement."""
        # Extract session information
        session_id = envelope.content.get("session_id", f"session-{envelope.task_id}")
        
        # Get memory context
        context = await self.memory.get_context(session_id, envelope.content.get("message", ""))
        
        # Add user message to memory
        await self.memory.add_message(session_id, {
            "role": "user",
            "content": envelope.content.get("message", ""),
            "user_id": envelope.content.get("user_id", "unknown")
        })
        
        # Process with context
        result = await self._process_with_context(envelope, context)
        
        # Add assistant response to memory
        await self.memory.add_message(session_id, {
            "role": "assistant",
            "content": result.get("response", "")
        })
        
        return result
```

#### Memory Consolidation

Service for optimizing and managing memory:

```python
class MemoryConsolidationService:
    """Service for memory optimization and consolidation."""
    
    async def generate_conversation_summary(self, conversation_id: str) -> str:
        """Generate a summary of a conversation using LLM."""
        # Implementation details...
        
    async def generate_embeddings_batch(self, limit: int = 100) -> int:
        """Generate embeddings for messages without them."""
        # Implementation details...
        
    async def archive_old_conversations(self, days: int = 90) -> int:
        """Archive conversations older than specified days."""
        # Implementation details...
```

## 4. Database Schema Design

### 4.1 PostgreSQL Schema

```sql
-- Create memory schema
CREATE SCHEMA IF NOT EXISTS memory;

-- Conversations table
CREATE TABLE memory.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id TEXT NOT NULL,
    user_id TEXT NOT NULL,
    interface TEXT NOT NULL, -- "slack", "streamlit", "api"
    title TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    summary TEXT,
    metadata JSONB
);

-- Messages table
CREATE TABLE memory.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES memory.conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL, -- "user", "assistant", "system"
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
    metadata JSONB,
    embedding VECTOR(1536) -- If using pgvector extension
);

-- Create conversation index
CREATE INDEX idx_conversations_session_id ON memory.conversations(session_id);
CREATE INDEX idx_conversations_user_id ON memory.conversations(user_id);
CREATE INDEX idx_messages_conversation_id ON memory.messages(conversation_id);

-- Create vector index if using pgvector
CREATE INDEX idx_messages_embedding ON memory.messages USING ivfflat(embedding vector_cosine_ops)
WITH (lists = 100);
```

### 4.2 Redis Schema

```
# Session key structure 
session:{session_id}:messages = [JSON array of recent messages]
session:{session_id}:metadata = {JSON object with session metadata}
session:{session_id}:active_tasks = [JSON array of active task IDs]
session:{session_id}:context = {JSON object with current context}

# Set reasonable TTL 
EXPIRE session:{session_id}:* 3600  # 1 hour default
```

### 4.3 Vector Collection Schema

```python
# Qdrant collection configuration
conversation_collection = {
    "name": "conversation_memory",
    "vectors_config": {
        "size": 1536,
        "distance": "Cosine"
    },
    "shard_number": 1,
    "replication_factor": 1,
    "write_consistency_factor": 1,
    "on_disk_payload": True,
    "hnsw_config": {
        "m": 16,
        "ef_construct": 100
    }
}
```

## 5. Implementation Classes

### 5.1 RedisMemory Implementation

```python
class RedisMemory(Memory):
    def __init__(self, redis_client):
        self.redis = redis_client
        self.ttl = 3600  # 1 hour default
        
    async def add_message(self, session_id: str, message: Dict[str, Any]) -> None:
        """Add a message to the Redis memory."""
        key = f"session:{session_id}:messages"
        # Get existing messages
        messages_json = await self.redis.get(key) 
        messages = json.loads(messages_json) if messages_json else []
        # Add new message
        messages.append({
            **message,
            "timestamp": datetime.now().isoformat()
        })
        # Store back with TTL
        await self.redis.setex(key, self.ttl, json.dumps(messages))
        # Update last accessed timestamp
        await self.redis.setex(f"session:{session_id}:last_accessed", 
                              self.ttl, 
                              datetime.now().isoformat())
        
    async def get_recent_messages(self, session_id: str, limit: int = 10) -> List[Dict[str, Any]]:
        """Get recent messages from Redis memory."""
        key = f"session:{session_id}:messages"
        messages_json = await self.redis.get(key)
        if not messages_json:
            return []
        messages = json.loads(messages_json)
        # Return most recent messages
        return messages[-limit:]
```

### 5.2 PostgresMemory Implementation

```python
class PostgresMemory(Memory):
    def __init__(self, db_pool):
        self.db = db_pool
        
    async def add_message(self, session_id: str, message: Dict[str, Any]) -> None:
        """Add a message to PostgreSQL memory."""
        async with self.db.acquire() as conn:
            # Ensure conversation exists
            conversation_id = await self._get_or_create_conversation(conn, session_id, message)
            # Insert message
            await conn.execute(
                """
                INSERT INTO memory.messages (conversation_id, role, content, metadata)
                VALUES ($1, $2, $3, $4)
                """,
                conversation_id,
                message.get("role"),
                message.get("content"),
                json.dumps(message.get("metadata", {}))
            )
            # Update conversation last_message_at
            await conn.execute(
                """
                UPDATE memory.conversations 
                SET last_message_at = now(), updated_at = now()
                WHERE id = $1
                """,
                conversation_id
            )
            
    async def _get_or_create_conversation(self, conn, session_id: str, message: Dict[str, Any]) -> str:
        """Get or create a conversation and return its ID."""
        # Check if conversation exists
        result = await conn.fetchrow(
            """
            SELECT id FROM memory.conversations 
            WHERE session_id = $1
            """, 
            session_id
        )
        
        if result:
            return result["id"]
        
        # Create new conversation
        result = await conn.fetchrow(
            """
            INSERT INTO memory.conversations 
            (session_id, user_id, interface, title, metadata)
            VALUES ($1, $2, $3, $4, $5)
            RETURNING id
            """,
            session_id,
            message.get("user_id", "unknown"),
            message.get("interface", "unknown"),
            message.get("content", "")[:50] + "...",  # Simple title from first message
            json.dumps(message.get("metadata", {}))
        )
        
        return result["id"]
```

### 5.3 VectorMemory Implementation

```python
class VectorMemory(Memory):
    def __init__(self, qdrant_client, embedding_service):
        self.qdrant = qdrant_client
        self.embedding_service = embedding_service
        self.collection_name = "conversation_memory"
        
    async def add_to_semantic_memory(self, message: Dict[str, Any]) -> None:
        """Add a message to semantic memory with embedding."""
        # Generate embedding
        content = message.get("content", "")
        embedding = await self.embedding_service.get_embedding(content)
        
        # Store in vector DB
        await self.qdrant.upsert(
            collection_name=self.collection_name,
            points=[{
                "id": str(uuid.uuid4()),
                "vector": embedding,
                "payload": {
                    "content": content,
                    "role": message.get("role"),
                    "timestamp": datetime.now().isoformat(),
                    "conversation_id": message.get("conversation_id"),
                    "user_id": message.get("user_id"),
                    "metadata": message.get("metadata", {})
                }
            }]
        )
        
    async def search_semantic_memory(self, query: str, limit: int = 5) -> List[Dict[str, Any]]:
        """Search semantic memory for relevant information."""
        # Generate query embedding
        query_embedding = await self.embedding_service.get_embedding(query)
        
        # Search vector DB
        search_result = await self.qdrant.search(
            collection_name=self.collection_name,
            query_vector=query_embedding,
            limit=limit
        )
        
        # Format results
        return [item.payload for item in search_result]
```

### 5.4 UnifiedMemory Implementation

```python
class UnifiedMemory(Memory):
    def __init__(
        self, 
        short_term: RedisMemory, 
        medium_term: PostgresMemory, 
        long_term: VectorMemory
    ):
        self.short_term = short_term
        self.medium_term = medium_term
        self.long_term = long_term
        
    async def add_message(self, session_id: str, message: Dict[str, Any]) -> None:
        """Add a message to all memory systems."""
        # Add to short-term memory
        await self.short_term.add_message(session_id, message)
        
        # Add to medium-term memory
        message_id = await self.medium_term.add_message(session_id, message)
        
        # Add to long-term memory if appropriate
        # Only store assistant and user messages, not system
        if message.get("role") in ["assistant", "user"]:
            # Ensure the message has the conversation_id from postgres
            semantic_message = {**message, "conversation_id": message_id}
            await self.long_term.add_to_semantic_memory(semantic_message)
            
    async def get_context(self, session_id: str, query: str = None) -> Dict[str, Any]:
        """Get complete context including short, medium and long-term memory."""
        # Get recent messages from short-term memory
        recent_messages = await self.short_term.get_recent_messages(session_id)
        
        # Get conversation summary from medium-term memory
        summary = await self.medium_term.get_conversation_summary(session_id)
        
        # Build context dictionary
        context = {
            "recent_messages": recent_messages,
            "summary": summary,
        }
        
        # Add semantic search results if query provided
        if query:
            semantic_results = await self.long_term.search_semantic_memory(query)
            context["semantic_results"] = semantic_results
            
        return context
```

## 6. Interface Integration

### 6.1 API Service

```python
from fastapi import FastAPI, Depends

app = FastAPI()

async def get_memory():
    """Get memory dependency."""
    return memory_service

@app.post("/api/memory/{session_id}/messages")
async def add_message(
    session_id: str, 
    message: Dict[str, Any],
    memory: UnifiedMemory = Depends(get_memory)
):
    """Add a message to memory."""
    await memory.add_message(session_id, message)
    return {"status": "success"}
    
@app.get("/api/memory/{session_id}/context")
async def get_context(
    session_id: str,
    query: str = None,
    memory: UnifiedMemory = Depends(get_memory)
):
    """Get memory context."""
    context = await memory.get_context(session_id, query)
    return context
    
@app.delete("/api/memory/{session_id}")
async def clear_session(
    session_id: str,
    memory: UnifiedMemory = Depends(get_memory)
):
    """Clear session memory."""
    await memory.clear_session(session_id)
    return {"status": "success"}
```

### 6.2 Streamlit UI Integration

```python
# Add memory integration to streamlit chat UI
def init_session_state():
    """Initialize session state if it doesn't exist."""
    if "messages" not in st.session_state:
        st.session_state.messages = []
    # Generate a unique session ID if not already present
    if "session_id" not in st.session_state:
        st.session_state.session_id = f"streamlit-{uuid.uuid4()}"

async def send_message_async(message: str) -> str:
    """Send a message to the API with memory context."""
    try:
        # Prepare payload with session context
        payload = {
            "message": message,
            "session_id": st.session_state.session_id,
            "user_id": SESSION_USER_ID
        }
        
        # Get memory context if available
        try:
            memory_response = await asyncio.wait_for(
                aiohttp.ClientSession().get(
                    f"{st.session_state.api_url}/api/memory/{st.session_state.session_id}/context",
                    json={"query": message}
                ),
                timeout=2.0
            )
            if memory_response.status == 200:
                memory_data = await memory_response.json()
                payload["context"] = memory_data
        except Exception as e:
            st.debug(f"Failed to get memory context: {e}")
        
        # Process the message with context
        response = await st.session_state.model_router_client.process_message(
            message=message,
            model_id=st.session_state.selected_model if st.session_state.selected_model != "auto" else None,
            user_id=SESSION_USER_ID,
            session_id=st.session_state.session_id,
            context=payload.get("context"),
            debug_mode=st.session_state.debug_mode
        )
        
        # Store response in memory if available
        try:
            await asyncio.wait_for(
                aiohttp.ClientSession().post(
                    f"{st.session_state.api_url}/api/memory/{st.session_state.session_id}/messages",
                    json={
                        "role": "assistant",
                        "content": response.get("response") or response.get("content"),
                        "user_id": SESSION_USER_ID,
                        "interface": "streamlit"
                    }
                ),
                timeout=2.0
            )
        except Exception as e:
            st.debug(f"Failed to store response in memory: {e}")
        
        return response.get("response") or response.get("content")
    # Error handling...
```

### 6.3 Slack Bot Integration

```python
async def process_message(client, channel_id, user_id, text, thread_ts=None, is_dm=False):
    """Process a message from a user with memory context."""
    try:
        # Generate session ID from channel and thread
        session_id = f"slack-{channel_id}"
        if thread_ts:
            session_id += f"-{thread_ts}"
        
        # Get memory context if available
        context = {}
        try:
            async with httpx.AsyncClient() as http_client:
                response = await http_client.get(
                    f"{ALFRED_API_URL}/api/memory/{session_id}/context",
                    json={"query": text},
                    timeout=2.0
                )
                if response.status_code == 200:
                    context = response.json()
        except Exception as e:
            logger.warning(f"Failed to get memory context: {e}")
        
        # Create an A2A envelope for chat processing with context
        envelope = A2AEnvelope(
            intent="CHAT",
            content={
                "message": text,
                "user_id": user_id,
                "channel_id": channel_id,
                "thread_ts": thread_ts,
                "session_id": session_id,
                "context": context
            }
        )
        
        # Store and process message
        # Implementation details...
    # Error handling...
```

## 7. Implementation Plan

### 7.1 Phase 1: Core Schema and Infrastructure (Week 1-2)

1. **Database Setup**
   - Create PostgreSQL memory schema and tables
   - Configure Redis for session storage
   - Set up Qdrant collection for conversation memory

2. **Core Interface Development**
   - Implement Memory interface
   - Create implementations for each storage type
   - Develop UnifiedMemory integration layer

### 7.2 Phase 2: Memory Service (Week 3-4)

1. **Service Implementation**
   - Build Memory service microservice
   - Create API endpoints for memory operations
   - Implement authentication and authorization

2. **Testing and Validation**
   - Unit tests for memory components
   - Integration tests with storage systems
   - Load testing with simulated conversations

### 7.3 Phase 3: Agent Integration (Week 5-6)

1. **Agent Framework Enhancement**
   - Extend BaseAgent with memory capabilities
   - Update agent implementations to use memory
   - Add context enhancement in task processing

2. **Interface Integration**
   - Enhance Streamlit UI with memory features
   - Update Slack bot for memory context
   - Add memory-aware API endpoints

### 7.4 Phase 4: Advanced Features (Week 7-8)

1. **Memory Optimization**
   - Implement conversation summarization
   - Build embedding generation pipeline
   - Create memory consolidation service

2. **Analytics and Management**
   - Develop memory analytics dashboard
   - Create memory management tools
   - Implement governance and privacy features

## 8. Performance Considerations

### 8.1 Scalability

- **Horizontal Scaling**
  - Memory service instances can scale horizontally
  - Redis can be configured as a cluster for high availability
  - PostgreSQL can be scaled with read replicas
  - Qdrant supports clustering for vector search

- **Load Distribution**
  - Distribute memory operations across instances
  - Use connection pooling for database access
  - Implement caching for frequent queries

### 8.2 Optimization Strategies

- **Memory Depth Limits**
  - Short-term: 10-20 most recent messages
  - Medium-term: Full history with pagination
  - Long-term: Top 5-10 most relevant results

- **Batch Processing**
  - Generate embeddings in background batches
  - Summarize conversations asynchronously
  - Archive old conversations during off-peak hours

- **Caching Strategy**
  - Cache frequent memory contexts
  - Use Redis for fast context retrieval
  - Implement LRU caching for query results

## 9. Security and Privacy

### 9.1 Data Protection

- **Encryption**
  - Encrypt sensitive data in memory
  - Use TLS for all network communication
  - Implement field-level encryption when needed

- **Access Control**
  - Role-based access to memory data
  - Session isolation for multi-tenant deployment
  - API authentication for memory operations

### 9.2 Compliance Features

- **GDPR Support**
  - User data export capability
  - Right to be forgotten implementation
  - Data retention policies

- **Audit Logging**
  - Track all memory access operations
  - Log memory modification events
  - Monitor for unusual access patterns

## 10. Technical Requirements

### 10.1 Dependencies

- **Redis**: v7.0+ with RedisJSON module
- **PostgreSQL**: v15+ with pgvector extension
- **Qdrant**: v1.5+ with fast vector search
- **Python**: 3.11+ with asyncio support
- **FastAPI**: For Memory service API
- **LangChain/LangGraph**: For LLM integration

### 10.2 Configuration

- **Memory Service Deployment**
  ```yaml
  services:
    memory-service:
      build:
        context: ./services/memory-service
        dockerfile: Dockerfile
      image: memory-service:latest
      container_name: memory-service
      ports:
        - "8090:8090"
      environment:
        - REDIS_URL=redis://redis:6379
        - DATABASE_URL=postgresql://user:pass@db-postgres:5432/alfred
        - VECTOR_DB_URL=http://vector-db:6333
      depends_on:
        - redis
        - db-postgres
        - vector-db
      networks:
        - alfred-network
  ```

## 11. References and Resources

### 11.1 Related Documentation

- [System Architecture](docs/architecture/system-architecture.md)
- [Agent Core Framework](docs/architecture/agent-core.md)
- [A2A Protocol Documentation](docs/api/a2a-protocol.md)
- [Orchestration Architecture](docs/architecture/orchestration-architecture.md)

### 11.2 External References

- [Redis Documentation](https://redis.io/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Qdrant Documentation](https://qdrant.tech/documentation)
- [pgvector Documentation](https://github.com/pgvector/pgvector)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)

## 12. Conclusion

The proposed memory architecture provides a comprehensive solution for enhancing Alfred's agent capabilities with robust, multi-tiered memory. By implementing this system, Alfred will gain significant advantages in context awareness, personalized user interactions, and continuous learning across conversations.

The design follows the platform's architectural principles while enabling new capabilities that will set Alfred apart from simpler agent implementations. The modular approach allows for incremental development and deployment while maintaining compatibility with existing components.

---

*Document Prepared for Atlas (Architecture Agent) by Alfred Platform Team*