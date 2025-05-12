# Atlas Enhancement Roadmap

This document tracks planned enhancements for the Atlas system.

## Documentation Improvements

| Enhancement | Benefit | Priority | Status |
|-------------|---------|----------|--------|
| ASCII or Mermaid sequence diagram of request flow | Gives visual learners a 5-second grasp of message paths | Medium | Planned |
| One-liner Docker / k8s deploy snippet | Lets readers jump straight from docs to running code | Medium | Planned |
| Metrics cheat-sheet (e.g., atlas_tokens_total, run_seconds_p95, alert thresholds) | Helps ops teams know what "good" looks like | Low | Planned |
| Link to docs/atlas/usage.md for prompt-craft tips | Surfaces deeper docs without cluttering the summary | Low | Planned |
| Version & commit hash badge in the header | Signals freshness and makes CI status visible at a glance | Low | Planned |

## Technical Enhancements

| Enhancement | Benefit | Priority | Status |
|-------------|---------|----------|--------|
| Hybrid reranker for RAG | Improves relevance of retrieved context | High | Planned |
| Streaming responses | Better user experience for large generations | Medium | Planned |
| Multi-provider LLM support | Reduced dependency on OpenAI | Medium | Planned |
| Fine-tuned domain-specific models | Improved accuracy for architecture tasks | Low | Planned |
| Automated testing suite | Ensures reliability across changes | High | Planned |

## Operations Improvements

| Enhancement | Benefit | Priority | Status |
|-------------|---------|----------|--------|
| Kubernetes deployment manifests | Production-grade deployment | Medium | Planned |
| Grafana dashboard templates | Better visibility into performance | Medium | Planned |
| Cost optimization guide | Reduce token usage | Low | Planned |
| Load testing framework | Validate performance at scale | Low | Planned |
| Backup and restore procedures | Ensure data durability | Medium | Planned |

## Release Planning

### v1.1 (Next Release)
- Fix Supabase persistence issues ✅
- Add metrics for token usage tracking
- Create basic dashboard for monitoring

### v1.2 
- Implement hybrid reranker
- Add streaming response capability
- Improve error handling and resilience

### v2.0
- Multi-provider LLM support
- Domain-specific fine-tuned models
- Complete production deployment templates