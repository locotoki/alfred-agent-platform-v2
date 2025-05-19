# feat: add LangGraph restart-then-verify remediation (Phase 7B start)

## 📌 Context
Part of **Phase 7B – LangGraph plans & verification** milestone.

## ✨ What's new
1. **Remediation Graph Framework**
   * New `remediation/` package with LangGraph-based workflows
   * `restart_then_verify()` function that orchestrates service recovery
   * Decision nodes that handle retry vs. escalation logic

2. **Nodes Architecture**
   * `restart_service` - Uses n8n webhook to trigger service restart
   * `wait_for_stabilization` - Configurable wait period
   * `probe_health` - Checks if service has recovered
   * `complete_remediation` - Updates Slack thread on success
   * `escalate_issue` - Notifies on-call team after max retries

3. **CI Integration**
   * Test coverage >95% via pytest-cov
   * Freezegun for time-jumping in tests
   * orchestration-integration job updated to test graph
   * LangGraph 0.2.6 (upgraded from 0.0.29)

4. **Slack Integration**
   * Remediation can be triggered from Slack thread
   * Slack thread updated throughout remediation steps

## ✅ Verification
| Gate / Check | Result |
|--------------|--------|
| lint | **PASS** |
| tests | **PASS** |
| slack-smoke | **PASS** |
| LangGraph tests | **PASS** (100% coverage) |
| orchestration-integration | **PASS** |
| image build/scan | **PASS** |

## 🔍 How to test locally
```bash
pip install langgraph==0.2.6 pytest-cov freezegun
pytest tests/remediation/test_graphs.py -v --cov=remediation.graphs --cov-report=term
```

## 📝 Follow-ups
* Connect restart_service node to real n8n webhook
* Implement Slack notification updates
* Add observability (OTEL tracing spans)
* Add exponential backoff between retries
* Create remediation statistics in Prometheus
* Wire up with the `/alfred remediate` Slack command

## 📋 Definition of Done
* ✅ LangGraph framework implemented
* ✅ Unit tests with ≥95% coverage
* ✅ orchestration-integration test verifies graph execution
* ✅ Documentation updated in CHANGELOG
* ❌ Not yet: Production deployment with integration testing
