# Alfred Agent Platform v2 - YouTube Workflow Implementation Plan

## Project Context

The Alfred Agent Platform v2 includes a Social Intelligence Agent with YouTube analysis capabilities, accessible through the Mission Control UI. Two key workflows need to be fully integrated:

1. **Niche-Scout**: Identifies trending YouTube niches based on metrics and trends
2. **Seed-to-Blueprint**: Generates YouTube channel strategies from seed videos or niches

## Current Implementation State

Most components are already implemented with proper port configurations:

- **UI Components**: All workflow pages exist with dynamic API connections
- **API Integration**: Endpoints use dynamic URL detection to avoid port hardcoding
- **Port Configuration**: Mission Control UI on port 3007, Social Intelligence Agent on port 9000
- **Documentation**: Updated to reflect standardized port configuration

## Port Configuration Standards

To prevent recurring port conflicts, we've standardized on the following port assignments:

- **Mission Control UI**: 3007 (avoids conflicts with Supabase and other services)
- **Social Intelligence Agent**: 9000 (DO NOT CHANGE)

The official port configuration standards are now documented in `PORT-STANDARD.md` at the project root.

## Implementation Steps

### 1. Port Configuration Verification (Priority High)

```typescript
// Verify .env.local file has correct configuration
// services/mission-control/.env.local
SOCIAL_INTEL_URL=http://localhost:9000
NEXT_PUBLIC_SERVER_URL=http://localhost:3007
NEXT_PUBLIC_API_BASE_URL=/api/social-intel
```

```json
// Verify package.json has correct port configuration
// services/mission-control/package.json
"scripts": {
  "dev": "next dev -p 3007",
  "build": "next build",
  "start": "next start -p 3007",
}
```

### 2. Dynamic URL Implementation (Priority High)

The YouTube workflow service already implements dynamic URL detection:

```typescript
// In youtube-workflows.ts
// This is the correct implementation - do not change
const baseUrl = typeof window !== 'undefined' ? window.location.origin : 'http://localhost:3007';
const SOCIAL_INTEL_URL = `${baseUrl}/api/social-intel`;
```

All API endpoints should follow this pattern for maximum resilience to port changes.

### 3. Error Handling Enhancements (Priority Medium)

```typescript
// Enhance error handling in workflow components
try {
  // API call logic
} catch (error) {
  console.error('Detailed error:', error);
  
  // Provide useful feedback to the user
  setErrorState({
    message: 'Connection to Social Intelligence Agent failed',
    technical: error instanceof Error ? error.message : 'Unknown error',
    timestamp: new Date().toISOString()
  });
  
  // Fallback to mock data mode
  return mockData;
}
```

### 4. Robustness Improvements (Priority Medium)

```typescript
// Add connection health check function
const checkServiceHealth = async () => {
  try {
    const response = await fetch(`${baseUrl}/api/social-intel/health`, {
      method: 'GET',
      signal: AbortSignal.timeout(3000)  // 3-second timeout
    });
    
    return response.ok;
  } catch (error) {
    console.warn('Health check failed:', error);
    return false;
  }
};
```

### 5. Testing Steps (Priority High)

1. **Verify Port Configuration:**
   ```bash
   # Verify package.json
   grep -E '"dev": |"start": ' services/mission-control/package.json
   
   # Verify .env.local
   grep -E 'SOCIAL_INTEL_URL|NEXT_PUBLIC_SERVER_URL' services/mission-control/.env.local
   ```

2. **Verify Service Connectivity:**
   ```bash
   # Check if Mission Control is running
   curl -I http://localhost:3007
   
   # Check if Social Intelligence Agent is running
   curl -I http://localhost:9000/api/health
   ```

3. **Run the Environment Check Script:**
   ```bash
   bash ./docs/phase6-mission-control/youtube-workflows/environment-check-script.sh
   ```

4. **Test Workflow Functionality:**
   - Navigate to http://localhost:3007/workflows/niche-scout
   - Run a test query
   - Check network requests in browser dev tools
   - Verify correct ports being used in requests

### 6. Documentation Updates (Priority Medium)

1. **Update Implementation Status:**
   - Document the standardized port configuration in `implementation_status_final.md`
   - Reference the `PORT-STANDARD.md` document as the authoritative source

2. **Update User Documentation:**
   - Ensure all documentation references port 3007 for the UI
   - Make clear that port 9000 remains fixed for the Social Intelligence Agent

## Advanced Improvements (If Time Permits)

### 1. Better Fallback Mode UI

```tsx
// Add clear mock data indicator in UI
{result._mock && (
  <div className="bg-amber-100 border-l-4 border-amber-500 text-amber-700 p-4 mb-4">
    <p className="font-medium">🔍 Mock Data Mode</p>
    <p className="text-sm">
      Showing sample data because we couldn't connect to the Social Intelligence Agent.
      {result._error && <span> Error: {result._error}</span>}
    </p>
  </div>
)}
```

### 2. Auto-Retry Mechanism

```typescript
// Add retry mechanism for failed API calls
const callWithRetry = async (endpoint, payload, maxRetries = 3) => {
  let lastError;
  
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
        signal: AbortSignal.timeout(30000 * (attempt + 1)) // Increase timeout with each retry
      });
      
      if (response.ok) {
        return await response.json();
      }
    } catch (error) {
      console.warn(`Attempt ${attempt + 1} failed:`, error);
      lastError = error;
      
      // Wait before retry (exponential backoff)
      await new Promise(r => setTimeout(r, 1000 * Math.pow(2, attempt)));
    }
  }
  
  // If all retries failed
  throw lastError || new Error('All retry attempts failed');
};
```

## Testing Checklist

- [ ] Environment check script passes without warnings
- [ ] Mission Control runs on port 3007
- [ ] Social Intelligence Agent runs on port 9000
- [ ] API calls use dynamic URL construction
- [ ] Niche-Scout workflow completes successfully
- [ ] Seed-to-Blueprint workflow completes successfully
- [ ] Error handling works when Social Intelligence Agent is unavailable
- [ ] All documentation references correct ports

## Next Steps After Implementation

1. Consider adding centralized port configuration in a dedicated config file
2. Implement more robust monitoring for service health
3. Add load testing for concurrent workflow execution
4. Enhance visualization options for workflow results