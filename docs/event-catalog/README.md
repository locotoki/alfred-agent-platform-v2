# Event Catalog

This directory contains auto-generated documentation from protobuf schemas.

## CloudEvents Structure

All events follow the CloudEvents v1.0 specification:

```json
{
  "specversion": "1.0",
  "type": "<agent>.<event>.v<major>",
  "source": "agent-<name>",
  "id": "<uuid>",
  "time": "<timestamp>",
  "tenant": "<tenant-id>",
  "data": {
    // Protobuf payload
  }
}
```

## Topics

Topic naming convention: `<tenant>.<agent>.<event>`

## Available Schemas

### agent_rag.v1

**QueryRequest**
- `id` (string): Request identifier
- `tenant_id` (string): Tenant identifier
- `text` (string): Query text

**QueryResponse**
- `id` (string): Response identifier  
- `hits` (QueryChunk[]): Search results

**QueryChunk**
- `chunk_id` (string): Chunk identifier
- `text` (string): Chunk content
- `score` (float): Relevance score

## Events

### rag.query.v1

Emitted when RAG query is processed.

**CloudEvent Type**: `rag.query.v1`
**Source**: `agent-rag`
**Data Schema**: `agent_rag.v1.QueryResponse`