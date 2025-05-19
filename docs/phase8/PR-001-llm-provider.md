# feat: Implement ADR-001 LLM Provider with OpenAI adapter

## Summary
This PR implements the first phase of the LLM Provider architecture as specified in ADR-001, including the OpenAI adapter, intent router, and Slack webhook with HMAC verification.

## Changes
- Added `arch/adr/ADR-001-llm-provider.md` documenting the LLM provider decision
- Implemented `alfred/core/llm_adapter.py` with Strategy pattern for OpenAI and Claude
- Created `alfred/agents/intent_router.py` for basic intent classification
- Built `alfred/adapters/slack/webhook.py` with FastAPI and HMAC verification
- Added comprehensive unit tests for all new components

## Linked Documentation
- **ADR:** [ADR-001-llm-provider.md](/arch/adr/ADR-001-llm-provider.md)

## Issue Cards Addressed
✅ **LLM Unit Tests & Prom Counter** (`alfred/core/tests/test_llm_adapter.py`)
- Mock OpenAI SDK implementation
- Test streaming & non-streaming paths
- Prometheus `alfred_llm_tokens_total` counter
- Budget guard for token count

✅ **IntentRouter Skeleton** (`alfred/agents/intent_router.py`)
- `IntentRouter` class with `route(message: str) -> Intent`
- Plugin registry for intent handlers
- Fallback "unknown_intent" handler
- Unit tests with 3 sample messages
- Prometheus counter `alfred_intents_total`

✅ **Slack Adapter Webhook + HMAC Verify** (`alfred/adapters/slack/webhook.py`)
- FastAPI endpoint `POST /slack/events`
- Request signature validation
- Slash command `/alfred ping` → "pong"
- Error 401 on bad signature
- Unit tests with valid & invalid signatures
- Metrics: `alfred_slack_events_total{result="ok|invalid_sig"}`

## Test Summary
```
==================== 40 passed in 0.18s ====================
```

All tests now pass with 87% coverage (exceeds 85% requirement).

### Coverage Report
```
Name                               Stmts   Miss  Cover   Missing
----------------------------------------------------------------
alfred/adapters/slack/webhook.py     108      6    94%   114, 196-204
alfred/agents/intent_router.py        57      0   100%
alfred/core/llm_adapter.py           123     31    75%   (SDK client properties)
----------------------------------------------------------------
TOTAL                                288     37    87%
```

## Prometheus Metrics Added
- `alfred_llm_tokens_total` - Total tokens used across all LLM calls
- `alfred_intents_total` - Total intents processed
- `alfred_slack_events_total` - Total Slack events received

## Pre-commit Compliance
✅ All pre-commit hooks pass:
- Black formatting
- isort import ordering
- No legacy `services.*` imports
- File endings and whitespace

## Next Steps
Once approved, the following Sprint 2 cards are ready:
- API Gateway CI Job
- Containerise Slack Adapter
- Integrate IntentRouter with Orchestrator
- Cost Dashboard Prometheus → Grafana

---
**Status:** Ready for Architect review
