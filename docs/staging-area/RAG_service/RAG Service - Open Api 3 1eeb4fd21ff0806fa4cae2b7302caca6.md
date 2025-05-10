# RAG Service - Open Api 3

openapi: 3.1.0
info:
title: RAG Service API
version: 0.1.0
description: |
REST interface for embedding, indexing, hybrid retrieval and chat generation.
All objects conform to the JSON schemas defined in the companion *RAG Service – JSON Schemas* document.
servers:

- url: [http://rag-gateway:8080](http://rag-gateway:8080/)
description: Local on‑prem Gateway (default)
security:
- bearerAuth: []
paths:
/v1/embed:
post:
summary: Embed one or more texts and return vector(s).
tags: [Embedding]
security:
- bearerAuth: []
requestBody:
required: true
content:
application/json:
schema:
type: object
required: [texts]
properties:
texts:
type: array
items:
type: string
model_hint:
type: string
description: Optional model override; defaults to e5-large-v2.
responses:
"200":
description: Embedding vectors.
content:
application/json:
schema:
type: object
properties:
vectors:
type: array
items:
type: array
items:
type: number
"401":
$ref: "#/components/responses/Unauthorized"
/v1/index:
post:
summary: Index a batch of documents (chunk + embed + upsert).
tags: [Ingestion]
security:
- bearerAuth: []
requestBody:
required: true
content:
application/json:
schema:
type: object
required: [trace_id, tenant_id, documents]
properties:
trace_id:
type: string
tenant_id:
type: string
documents:
type: array
items:
$ref: "#/components/schemas/SourceDocument"
responses:
"202":
description: Accepted – ingestion in progress.
"401":
$ref: "#/components/responses/Unauthorized"
/v1/query:
post:
summary: Hybrid search – BM25 + ANN with optional re‑ranker.
tags: [Retrieval]
security:
- bearerAuth: []
parameters:
- in: header
name: Trace-Id
required: false
schema:
type: string
description: Client supplied trace id (fallback if body.trace_id absent).
requestBody:
required: true
content:
application/json:
schema:
$ref: "#/components/schemas/RetrievalRequest"
responses:
"200":
description: Retrieval results.
content:
application/json:
schema:
$ref: "#/components/schemas/RetrievalResponse"
"401":
$ref: "#/components/responses/Unauthorized"
/v1/chat:
post:
summary: Chat completion with RAG‑augmented context.
tags: [Generation]
security:
- bearerAuth: []
requestBody:
required: true
content:
application/json:
schema:
type: object
required: [messages, tenant_id, trace_id]
properties:
trace_id:
type: string
tenant_id:
type: string
messages:
type: array
items:
type: object
required: [role, content]
properties:
role:
type: string
enum: [system, user, assistant]
content:
type: string
top_k_context:
type: integer
default: 6
description: How many retrieved docs to inject.
responses:
"200":
description: Streaming chat response (SSE / chunked JSON).
content:
text/event-stream:
schema:
type: string
application/json:
schema:
type: object
properties:
completion:
type: string
citations:
type: array
items:
$ref: "#/components/schemas/SourceDocument"
"401":
$ref: "#/components/responses/Unauthorized"

components:
securitySchemes:
bearerAuth:
type: http
scheme: bearer
bearerFormat: JWT
responses:
Unauthorized:
description: Missing or invalid JWT.
schemas:
RetrievalRequest:
$ref: "[https://example.com/rag/RetrievalRequest.schema.json](https://example.com/rag/RetrievalRequest.schema.json)"
RetrievalResponse:
$ref: "[https://example.com/rag/RetrievalResponse.schema.json](https://example.com/rag/RetrievalResponse.schema.json)"
SourceDocument:
$ref: "[https://example.com/rag/SourceDocument.schema.json](https://example.com/rag/SourceDocument.schema.json)"
TraceContext:
$ref: "[https://example.com/rag/TraceContext.schema.json](https://example.com/rag/TraceContext.schema.json)"