# YouTube Workflow Troubleshooting Guide

## Common Issues & Solutions

### 0. Docker Not Running

**Symptoms:**
- Social Intelligence Agent not responding
- All API endpoints returning 404 or connection errors

**Quick Fixes:**
- Start Docker service using the appropriate command for your system:
  ```bash
  # On Ubuntu/Debian
  sudo systemctl start docker
  # On Windows WSL
  wsl.exe -d docker-desktop
  ```
- Verify Docker is running:
  ```bash
  docker ps
  ```
- Start the Social Intelligence Agent container:
  ```bash
  cd /home/locotoki/projects/alfred-agent-platform-v2
  docker-compose up -d social-intel
  ```
- If mock data mode is acceptable for testing, no action is needed as the system will automatically fall back to mock data

### 1. Port Mismatch Errors (404 Not Found)

**Symptoms:**
- 404 errors in browser console when attempting API calls
- Network requests to wrong port (e.g., `:3000` instead of `:3005`)

**Quick Fixes:**
- Update `package.json` to use port 3005 for both dev and start commands
- Verify `.env.local` has correct `SOCIAL_INTEL_URL=http://localhost:9000`
- Update service code to use dynamic origin detection:
  ```typescript
  // In youtube-workflows.ts
  const baseUrl = typeof window !== 'undefined' ? window.location.origin : '';
  const SOCIAL_INTEL_URL = `${baseUrl}/api/social-intel`;
  ```

**Terminal Commands:**
```bash
# Check if port 3005 is in use
lsof -i :3005
# Check if port 9000 is in use (Social Intelligence Agent)
lsof -i :9000
# Verify network connections
netstat -tuln | grep -E '3005|9000'
```

### 2. API Connection Failures

**Symptoms:**
- API calls failing with connection refused errors
- Timeouts when calling Social Intelligence Agent

**Quick Fixes:**
- Verify Social Intelligence Agent is running:
  ```bash
  docker ps | grep social-intel
  ```
- Test direct connection to Social Intelligence Agent:
  ```bash
  curl http://localhost:9000/api/health
  ```
- Add fallback to mock data in API endpoints:
  ```typescript
  try {
    // API call code...
  } catch (error) {
    console.error('Falling back to mock data:', error);
    return res.status(200).json(getMockData());
  }
  ```

### 3. UI Error Handling Issues

**Symptoms:**
- Generic error messages
- Spinning loading indicators without resolution
- No feedback when API calls fail

**Quick Fixes:**
- Enhance error state in component:
  ```typescript
  const [error, setError] = useState<{
    message: string;
    technical?: string;
  } | null>(null);
  
  // When catching errors:
  setError({
    message: 'User-friendly message',
    technical: err instanceof Error ? err.message : 'Unknown error'
  });
  ```
- Add timeout handling to prevent UI hanging:
  ```typescript
  const timeout = 45000; // 45 seconds
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);
  
  try {
    const response = await fetch(url, {
      signal: controller.signal,
      // other options...
    });
    clearTimeout(timeoutId);
    // process response...
  } catch (err) {
    if (err.name === 'AbortError') {
      setError({ message: 'Request timed out. Please try again.' });
    } else {
      setError({ message: 'Error connecting to service', technical: err.message });
    }
  }
  ```

### 4. Result Page Not Displaying Data

**Symptoms:**
- Blank result pages
- Missing data in visualizations
- Console errors related to undefined properties

**Quick Fixes:**
- Add defensive rendering with optional chaining:
  ```tsx
  {result?.trending_niches?.length > 0 ? (
    <VisualizationComponent data={result.trending_niches} />
  ) : (
    <EmptyState message="No trending niches found." />
  )}
  ```
- Add data structure validation before rendering:
  ```typescript
  const isValidResult = (data: any): data is NicheScoutResult => {
    return Boolean(
      data &&
      Array.isArray(data.trending_niches) &&
      data.trending_niches.length > 0
    );
  };
  
  // In component:
  if (!isValidResult(result)) {
    return <ErrorState message="Invalid result data structure" />;
  }
  ```

### 5. Mock Data Not Appearing When Expected

**Symptoms:**
- Empty result pages when Social Intelligence Agent is unavailable
- API calls failing instead of returning mock data

**Quick Fixes:**
- Verify mock data generation functions exist and are called
- Add explicit fallback logic in API handlers:
  ```typescript
  // In niche-scout.ts, seed-to-blueprint.ts, etc.
  try {
    // Existing API call logic...
  } catch (error) {
    console.warn('API call failed, using mock data', error);
    const mockData = getMockData(); // Implement this function
    return res.status(200).json(mockData);
  }
  ```

## Diagnostic Commands

### Check Server Status
```bash
# Check Next.js server
ps aux | grep "next"

# Check Docker containers
docker ps | grep -E 'social-intel|mission-control'

# View Next.js logs
tail -f /home/locotoki/projects/alfred-agent-platform-v2/services/mission-control/nohup.out
```

### Network Diagnostics
```bash
# Test direct connection to Social Intelligence Agent
curl -v http://localhost:9000/api/health

# Test Mission Control API proxy
curl -v http://localhost:3005/api/social-intel/workflow-history
```

### Configuration Verification
```bash
# Check environment variables
cat /home/locotoki/projects/alfred-agent-platform-v2/services/mission-control/.env.local

# Verify port configuration in package.json
grep -A 5 "scripts" /home/locotoki/projects/alfred-agent-platform-v2/services/mission-control/package.json
```

## Common Error Messages & Solutions

### "Failed to fetch" in Console
This typically indicates a CORS issue or network connectivity problem.

**Solution:** 
- Ensure API calls are made to the same origin or proper CORS headers are set
- Verify Social Intelligence Agent is running
- Check network connectivity between services

### "Not Found" when calling Social Intelligence Agent
This indicates that the API endpoint structure in the Social Intelligence Agent may differ from what's expected.

**Solution:**
- Check the actual endpoint structure in the Social Intelligence Agent documentation or code
- Update the `endpoints` array in the API files to include the correct paths
- Verify that the Social Intelligence Agent has implemented the expected endpoints
- Try all possible endpoint paths in this order:
  ```
  /youtube/niche-scout
  /api/youtube/niche-scout
  /niche-scout
  ```

### "Cannot read properties of undefined"
Often occurs when trying to access properties of null or undefined objects in result data.

**Solution:**
- Add null checks with optional chaining (`?.`)
- Implement data validation before rendering
- Add default/fallback values for missing properties

### "AbortError: The operation was aborted"
Indicates a request timeout or manual abort.

**Solution:**
- Increase timeout duration for complex operations
- Add proper error handling for AbortError specifically
- Check if Social Intelligence Agent is overloaded or slow to respond

## Quick Reference: API Endpoints

| Endpoint | Purpose | Expected Response |
|----------|---------|-------------------|
| `/api/social-intel/niche-scout` | Run Niche-Scout workflow | `NicheScoutResult` object |
| `/api/social-intel/seed-to-blueprint` | Run Seed-to-Blueprint workflow | `BlueprintResult` object |
| `/api/social-intel/workflow-history` | Get history of workflow runs | Array of `WorkflowHistory` |
| `/api/social-intel/workflow-result/[id]` | Get results for specific workflow | `NicheScoutResult` or `BlueprintResult` |

## Quick Reset Procedure

If you encounter persistent issues, try this reset sequence:

1. Restart the Social Intelligence Agent:
   ```bash
   cd /home/locotoki/projects/alfred-agent-platform-v2
   docker-compose restart social-intel
   ```

2. Restart the Mission Control UI:
   ```bash
   cd /home/locotoki/projects/alfred-agent-platform-v2/services/mission-control
   npm run dev
   ```

3. Clear browser cache and reload the page

4. Test with minimal workflow inputs to verify functionality