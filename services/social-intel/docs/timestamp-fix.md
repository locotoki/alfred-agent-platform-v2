# Timestamp Format Fix

## Issue Description

The Social Intelligence service was returning a `minute must be in 0..59` error when interacting with the Mission Control service. This error occurred due to a timestamp format mismatch between JavaScript and Python.

## Root Cause

There was a fundamental difference in how timestamps were generated between the two services:

1. **JavaScript (Mission Control)** uses `Date.now()` which returns milliseconds since Unix epoch
   ```javascript
   task_id: `niche-scout-${Date.now()}`  // e.g., "niche-scout-1746832944708"
   ```

2. **Python (Social Intelligence)** was using `datetime.now().timestamp()` which returns seconds since Unix epoch
   ```python
   result["_id"] = f"niche-scout-{int(datetime.now().timestamp())}"  // e.g., "niche-scout-1746832944"
   ```

When the Python-generated ID (seconds-based) was later interpreted in a JavaScript context as milliseconds, it resulted in an invalid date/time with minutes > 59, causing the "minute must be in 0..59" error.

## Solution

The fix was to modify the Python code to use milliseconds to match JavaScript's format:

```python
import time
result["_id"] = f"niche-scout-{int(time.time() * 1000)}"  # returns milliseconds since epoch
```

This change was applied to both ID generation points in the `main.py` file:
- For Niche-Scout workflow results (around line 175)
- For Seed-to-Blueprint workflow results (around line 256)

## Testing

After implementing the fix:
1. The API now returns IDs in the correct millisecond format (e.g., "niche-scout-1746832944708")
2. The "minute must be in 0..59" error no longer appears in the logs
3. Both services can now communicate correctly with consistent timestamp formats

## Technical Notes

- `time.time()` returns seconds as a floating-point number
- Multiplying by 1000 and converting to an integer gives the equivalent milliseconds
- This approach ensures timestamp compatibility between JavaScript and Python services

## Related Files

- `/app/app/main.py` - Main FastAPI application file where the fix was implemented
- `/app/app/workflow_endpoints.py` - Contains additional datetime validation that helped identify the issue