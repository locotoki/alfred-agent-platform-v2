## Refactor flaky `test_chains.py`

### Background
During the SC-330 work to remove xfail markers and fix async issues, we identified several flaky tests in `tests/unit/agents/financial_tax/test_chains.py`. These tests are failing due to various issues with mock setup and async handling.

### Issues to address
1. LLMChain interface expects a Runnable but is receiving a Mock object
2. Async method handling in chain methods
3. Mocking strategy needs updating to work with current LangChain versions

### Acceptance Criteria
- [ ] Fix all test failures in `test_chains.py`
- [ ] Ensure all tests run reliably with pytest
- [ ] Update mocking approach to be compatible with current LangChain architecture
- [ ] Remove any need for patching with AsyncMock
- [ ] Update test assertions to match expected behavior

### Root cause analysis
The current mocking approach in `test_chains.py` is incompatible with the updated LangChain API. The specific error is:
```
ValueError: "LLMChain" object has no field "ainvoke"
```

### Suggested approach
1. Update the mock implementations to properly subclass or implement the Runnable interface
2. Update MockLLM to properly implement the expected interfaces
3. Consider using the LangChain testing utilities directly
