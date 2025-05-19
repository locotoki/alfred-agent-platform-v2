# ADR-001: LLM Provider for Alfred-core

Status: **Proposed** – 19 May 2025

## Context
Phase-1 MVP must "Connect to LLM provider (start with Alert Explainer pattern)" and hit the SLA of < 2 s latency for 90% of requests while serving bilingual (PT/EN) business users on Slack. The assessment lists GPT-4, Claude and "open models" as the short-list [ALFRED-CORE-ASSESSMENT-…]. Key constraints:
• SaaS launch within 4 weeks → zero infra for model hosting.
• Portuguese support & high reasoning accuracy.
• Cost risk accepted for MVP (single Slack workspace, ≤ 30 req/min).
• Future dual-personality requires pluggable back-ends.

## Decision
Adopt **OpenAI GPT-4o-Turbo** (2024-05 release) as the primary LLM provider via the official HTTPS API.

### Implementation guidelines:
1. Introduce `alfred/core/llm_adapter.py` with a Strategy/Adapter interface (`generate(messages, *, stream=False)`).
2. Default concrete class `OpenAIAdapter` – model `gpt-4o-turbo` (128K ctx, $5/1M input tokens).
3. Add fallback `ClaudeAdapter` (Claude 3 Sonnet) behind a feature flag for resiliency.
4. All business logic calls the adapter, never the SDK directly.

## Consequences
✅ State-of-the-art reasoning, vision alignment with multi-modal roadmap.
✅ PTS & EN handled natively.
✅ Lower latency than GPT-4-Turbo; streaming supported.
⚠️ Vendor lock-in & EU-data-residency – mitigated by the adapter layer and quarterly bake-offs against Claude / Mixtral.
⚠️ Token costs – track via Prometheus counter `alfred_llm_tokens_total` and monthly cost report.
➕ Future Phase-2: optional on-prem Ollama gateway for home instance.

## Alternatives
**Claude 3 Sonnet** – slightly lower cost, stronger at summarisation, but marginally higher latency and weaker tooling; chosen as secondary.

**Mixtral 8x7B on-prem** – no SaaS fees, full control; rejected for MVP due to hosting & ops overhead and slower Portuguese quality.

## References
Alfred-Core Assessment Report (18 May 2025) sections Development Priorities, Technical Requirements, Risk Assessment [ALFRED-CORE-ASSESSMENT-…]

---

# GitHub Issue Cards – Sprint 1 (4h slices)

### [IntentRouter Skeleton](/alfred/agents/intent_router.py)
*Labels:* size/S · type/feature · codex
*Linked ADR:* ADR-001

#### Acceptance Criteria
- [ ] `IntentRouter` class with `route(message: str) -> Intent` stub
- [ ] Plug‐in registry (dict) for intent handlers
- [ ] Fallback "unknown_intent" handler returns polite error
- [ ] Unit test: 3 sample messages → correct stub intents
- [ ] Prometheus counter `alfred_intents_total` increases per call

---

### [Slack Adapter Webhook + HMAC Verify](/alfred/adapters/slack/webhook.py)
*Labels:* size/M · type/feature · codex
*Linked ADR:* ADR-001

#### Acceptance Criteria
- [ ] FastAPI endpoint `POST /slack/events`
- [ ] Request signature validated using Slack signing secret
- [ ] Slash command `/alfred ping` echoes "pong" (HTTP 200)
- [ ] Error 401 on bad signature, logged at WARN
- [ ] Unit tests with valid & invalid signatures
- [ ] Metrics: `alfred_slack_events_total{result="ok|invalid_sig"}`

---

### [LLM Unit Tests & Prom Counter](/alfred/core/tests/test_llm_adapter.py)
*Labels:* size/S · type/test · codex
*Linked ADR:* ADR-001

#### Acceptance Criteria
- [ ] Mock OpenAI SDK; assert adapter passes messages correctly
- [ ] Test streaming & non-streaming paths
- [ ] Prometheus `alfred_llm_tokens_total` counter updated
- [ ] Budget guard: assert token count ≤ 10,000 in test suite

Each card conforms to the project's template – summary, bullet AC, size label, ADR link – and fits the ≤ 4h work slice rule.
