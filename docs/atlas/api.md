# Atlas API Reference

*Last Updated: 2025-05-11*  
*Owner: Infra Crew*  
*Status: MVP Implementation*

## Overview

This document details the API endpoints and message formats used by Atlas and its associated services.

## RAG Gateway API

The RAG Gateway provides two main endpoints for retrieving and embedding content:

### Query Chat

Retrieves relevant content based on a question.

**Endpoint:** `POST /v1/query_chat`

**Request:**
```json
{
  "query": "Design a logging system for a microservice architecture",
  "top_k": 15
}
```

**Response:**
```json
[
  {
    "text": "Relevant content from the knowledge base...",
    "similarity": 0.92,
    "source": "docs/architecture/logging.md"
  },
  {
    "text": "More relevant content...",
    "similarity": 0.85,
    "source": "docs/best-practices/observability.md"
  }
]
```

### Embed Batch

Embeds a batch of documents into the vector database.

**Endpoint:** `POST /v1/embed_batch`

**Request:**
```json
[
  "Content of document 1",
  "Content of document 2",
  "Content of document 3"
]
```

**Response:**
```json
{
  "job_id": "job-0001"
}
```

## Event Bus Messages

Atlas communicates via the event bus using the following message formats:

### Input Message (architect_in)

```json
{
  "role": "architect",
  "msg_type": "chat",
  "content": "Design a logging system for microservices",
  "metadata": {
    "tokens": 0,
    "model": "gpt-4.1",
    "parent_id": null,
    "status": "in_progress",
    "schema_ver": 1
  }
}
```

### Output Message (architect_out)

```json
{
  "role": "architect",
  "msg_type": "spec",
  "content": "# Logging System Architecture for Microservices\n\n## Overview\n\nThis document...",
  "metadata": {
    "tokens": 1250,
    "model": "gpt-4.1",
    "parent_id": null,
    "status": "done",
    "schema_ver": 1
  }
}
```

## Metrics

Atlas exposes Prometheus metrics at `/metrics` (port 8000):

| Metric | Type | Description |
|--------|------|-------------|
| `atlas_tokens_total` | Counter | Total tokens used by Atlas |
| `atlas_run_seconds` | Histogram | Latency of Atlas run |

## Internal Implementation Interfaces

### RAG Client

```python
def get_context(question: str) -> List[Dict]:
    """
    Retrieves relevant context for a given question
    
    Args:
        question: The question to retrieve context for
        
    Returns:
        List of context chunks with text and similarity score
    """
```

### OpenAI Client

```python
async def chat(prompt: str, context: List[Dict]) -> str:
    """
    Generates a response from OpenAI based on prompt and context
    
    Args:
        prompt: The user's request
        context: Relevant context from RAG
        
    Returns:
        Generated response
    """
```

### Bus Client

```python
async def publish(msg: Dict):
    """
    Publishes a message to the bus
    
    Args:
        msg: The message to publish
    """

async def subscribe(role: str) -> AsyncGenerator[Dict, None]:
    """
    Subscribes to messages for a specific role
    
    Args:
        role: The role to subscribe to
        
    Yields:
        Messages from the bus
    """
```