## Fix coroutine-not-subscriptable errors in financial_tax & explainer agents

During the implementation of SC-320 (enabling flake8-docstring rules), we discovered an issue with the async/await patterns in the financial_tax and explainer agent modules.

### Traceback:
```
TypeError: 'coroutine' object is not subscriptable
```

### Affected files:
- tests/unit/agents/financial_tax/test_agent.py
- tests/unit/agents/financial_tax/test_chains.py 
- tests/unit/agents/financial_tax/test_models.py
- tests/unit/alfred/alerts/explainer/test_agent.py
- tests/unit/alfred/slack/diagnostics/test_explain_command.py

### Root cause:
It appears that several async methods are being called without await, resulting in coroutine objects that cannot be subscripted (indexed).

Examples:
- ExplainerAgent.explain_alert() is an async method being called without await
- Various financial_tax agent methods also show similar issues

### Suggested approach:
1. Update test functions to be async and properly await the methods they're testing
2. Ensure all async method calls use proper await syntax
3. Update test fixtures to handle async patterns correctly
