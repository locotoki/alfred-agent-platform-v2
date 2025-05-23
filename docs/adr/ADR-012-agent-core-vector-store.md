# ADR-012 · Service Boundaries for agent-core & Vector Store

## Status
Proposed · 23 May 2025

## Context
A clear contract is required between the RAG loop (*agent-core*) and the underlying vector store to allow future pluggability (Qdrant, Pinecone). …

## Decision
To keep GA scope tight we will …

## Consequences
* (+) Swappable store implementations post-GA.
* (–) Slightly higher initial latency due to abstraction layer.

