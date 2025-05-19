### Integrate IntentRouter with Orchestrator
*Labels:* size/M · type/feature · codex

#### Acceptance Criteria
- [ ] Orchestrator calls `IntentRouter.route()` before any LLM call
- [ ] On "unknown_intent" reply with help message (no LLM tokens spent)
- [ ] Increment Prom metric `alfred_orchestrator_route_total`
- [ ] Unit test: unknown intent keeps `alfred_llm_tokens_total` unchanged
