# LLM Integration Architecture Diagram

```
┌───────────────────────────────────────────────────────────────────────┐
│                       Alfred Agent Platform v2                         │
└───────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌───────────────────────────────────────────────────────────────────────┐
│                              User Interfaces                           │
│                                                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │ Streamlit   │  │ Admin       │  │ Auth         │  │ Slack       │  │
│  │ Chat UI     │  │ Dashboard   │  │ UI           │  │ Integration │  │
│  │ Port: 8502  │  │ Port: 3007  │  │ Port: 8030   │  │             │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────────┘  └──────┬──────┘  │
└─────────┼───────────────┼───────────────────────────────────┼─────────┘
          │               │                                   │
          ▼               ▼                                   ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                          API Layer / Gateway                             │
│                                                                         │
│  ┌──────────────┐ ┌────────────────┐ ┌────────────────┐ ┌────────────┐  │
│  │ agent-core   │ │ model-router   │ │ model-registry │ │ db-auth    │  │
│  │ Port: 8011   │ │ Port: 8701     │ │ Port: 8700     │ │ Port: 9999 │  │
│  └──────┬───────┘ └────────┬───────┘ └────────┬───────┘ └────────────┘  │
└─────────┼────────────────┬─┴───────────────┬──┴─────────────────────────┘
          │                │                 │
          ▼                ▼                 ▼
┌──────────────────┐ ┌────────────────┐ ┌───────────────────────────────┐
│ Agent Services   │ │ Model Services │ │ Infrastructure Services        │
│                  │ │                │ │                               │
│ ┌──────────────┐ │ │ ┌────────────┐ │ │ ┌───────────┐ ┌────────────┐ │
│ │ agent-rag    │ │ │ │ llm-service │ │ │ │ db-postgres│ │ redis      │ │
│ │ Port: 8501   │◄┼─┼─┤ Port: 11434 │ │ │ │ Port: 5432 │ │ Port: 6379 │ │
│ └──────────────┘ │ │ └──────┬─────┘ │ │ └───────────┘ └────────────┘ │
│                  │ │        │       │ │                               │
│ ┌──────────────┐ │ │        │       │ │ ┌───────────┐ ┌────────────┐ │
│ │ agent-atlas  │ │ │        │       │ │ │ vector-db  │ │ mail-server│ │
│ │ Port: 8000   │◄┼─┼────────┘       │ │ │ Port: 6333 │ │ Port: 8025 │ │
│ └──────────────┘ │ │                │ │ └───────────┘ └────────────┘ │
│                  │ │                │ │                               │
│ ┌──────────────┐ │ │                │ │ ┌───────────┐ ┌────────────┐ │
│ │ agent-social │ │ │                │ │ │ pubsub-   │ │ monitoring │ │
│ │ Port: 9000   │ │ │                │ │ │ emulator  │ │ services   │ │
│ └──────────────┘ │ │                │ │ └───────────┘ └────────────┘ │
└──────────────────┘ └────────────────┘ └───────────────────────────────┘
          │                 │                       │
          └─────────┬───────┘                       │
                    ▼                               │
┌───────────────────────────────────┐               │
│        External AI Services        │               │
│                                   │               │
│  ┌───────────┐  ┌───────────────┐ │               │
│  │ OpenAI    │  │ Anthropic     │ │               │
│  │ GPT-4o    │  │ Claude Models │ │               │
│  │ GPT-4.1   │  └───────────────┘ │               │
│  └───────────┘                    │               │
└───────────────────────────────────┘               │
                    ▲                               │
                    │                               │
                    └───────────────────────────────┘
```

## System Components

### User Interfaces
- **Streamlit Chat UI** (Port 8502): Primary user interface for chat interactions
- **Admin Dashboard** (Port 3007): Administration interface for system management
- **Auth UI** (Port 8030): Authentication management interface
- **Slack Integration**: External messaging platform integration

### API Layer / Gateway
- **agent-core** (Port 8011): Central orchestration service for all agent interactions
- **model-router** (Port 8701): Intelligent model selection and routing service
- **model-registry** (Port 8700): Model configuration and management service
- **db-auth** (Port 9999): Authentication and authorization service

### Agent Services
- **agent-rag** (Port 8501): Retrieval-Augmented Generation service
- **agent-atlas** (Port 8000): Advanced reasoning and planning agent
- **agent-social** (Port 9000): Social intelligence and content analysis

### Model Services
- **llm-service** (Port 11434): Local LLM inference using Ollama
  - Hosts open-source models like Llama 3, CodeLlama, and LLaVA

### Infrastructure Services
- **db-postgres** (Port 5432): PostgreSQL database for structured data
- **redis** (Port 6379): In-memory data store for caching and messaging
- **vector-db** (Port 6333): Qdrant vector database for embeddings
- **mail-server** (Port 8025): MailHog for email testing
- **pubsub-emulator**: Message bus for event-driven architecture
- **monitoring services**: Prometheus/Grafana for system monitoring

### External AI Services
- **OpenAI**: GPT-4o, GPT-4.1, GPT-4.1 Mini, GPT-3.5
- **Anthropic**: Claude models for specialized tasks

## Data Flow

1. **User Request Flow**:
   - User submits request through UI (Streamlit, Admin, Slack)
   - Request routed to agent-core for processing
   - agent-core contacts model-router for model selection
   - model-router queries model-registry for available models
   - Selected model processes the request
   - Response returned through the original interface

2. **Model Selection Flow**:
   - model-router analyzes incoming request content/type
   - Queries model-registry for model capabilities
   - Applies selection rules based on task characteristics
   - Selects optimal model (local or external)
   - Dispatches request to selected model
   - Monitors performance and records metrics

3. **Local Model Inference**:
   - llm-service receives inference requests
   - Loads appropriate model if not already loaded
   - GPU acceleration applied for supported models
   - Performs inference and returns results
   - Caches results when appropriate

4. **Cloud Model Integration**:
   - model-router formats request for external API
   - Manages API keys and authentication
   - Sends request to external service
   - Receives and processes response
   - Handles retries and fallbacks

## Technology Stack

- **Frontend**: Streamlit, React.js, Ant Design
- **Backend**: Python (FastAPI), Node.js
- **Databases**: PostgreSQL, Redis, Qdrant
- **Messaging**: PubSub Emulator, Redis PubSub
- **AI Framework**: LangChain, LangGraph
- **Local Inference**: Ollama, CUDA
- **Monitoring**: Prometheus, Grafana
- **Authentication**: JWT, Supabase Auth
- **Container Orchestration**: Docker Compose