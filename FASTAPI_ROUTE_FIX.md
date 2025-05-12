# FastAPI Route Fix for Agent Services

This document explains the issue with FastAPI routes in the agent-financial and agent-legal services and provides details on the fix.

## Issue Description

The agent services are experiencing startup errors with the following message:

```
fastapi.exceptions.FastAPIError: Invalid args for response field! Hint: check that <class 'agents.financial_tax.TaxCalculationRequest'> is a valid Pydantic field type. If you are using a return type annotation that is not a valid Pydantic field (e.g. Union[Response, dict, None]) you can disable generating the response model from the type annotation with the path operation decorator parameter response_model=None.
```

### Root Cause

1. The FastAPI routes in the agent services are trying to infer the response model from the function return type.
2. The route handlers are returning dictionaries, but FastAPI is trying to use the request models as response models.
3. The request models use `langchain.pydantic_v1.BaseModel` which is not directly compatible with FastAPI's Pydantic integration.

## Solution

The solution is to explicitly disable response model inference by adding `response_model=None` to all FastAPI route decorators. This tells FastAPI not to try to infer the response model from the function return type.

### Implemented Fixes

1. Created a script to modify all route decorators in the agent service files:
   - Added `response_model=None` to all `@app.post()` and `@app.get()` decorators
   - Applied this fix to both local service files and running containers

2. Created a bash script to:
   - Run the Python fix script
   - Restart the affected services
   - Check the service status and logs

### How to Use the Fix

Run the fix script:

```bash
./fix-agent-routes.sh
```

This will:
1. Modify the FastAPI route decorators
2. Restart the agent services
3. Show the service status and recent logs

### Manual Application (if needed)

If you need to apply the fix manually, add `response_model=None` to all route decorators:

```python
# Before
@app.post("/api/v1/financial-tax/calculate-tax")
async def calculate_tax(...):
    # Function body

# After
@app.post("/api/v1/financial-tax/calculate-tax", response_model=None)
async def calculate_tax(...):
    # Function body
```

### Alternative Solutions

For future development, consider these alternatives:

1. Define proper response models using FastAPI's Pydantic models
2. Migrate from LangChain's Pydantic to standard Pydantic models
3. Update function return type annotations to match the actual return types

## Verification

After applying the fix, verify:

1. Both agent services start without FastAPI errors
2. Health endpoints return HTTP 200
3. API endpoints accept requests and queue tasks properly