# Port Conflict Resolution Guide

This document explains how we resolved the port conflict issues in the Mission Control service, which was configured to use port 3003 but was actually running on port 3007.

## Problem

The Mission Control service had a port configuration mismatch:
- Configuration files were set to use port 3003
- The service was actually running on port 3007
- This caused API calls to fail and resulted in "Connection refused" errors

## Resolution Steps

### 1. Update Port Configuration in Key Files

We updated all port references from 3003 to 3007 in the following files:

#### package.json

```json
"scripts": {
  "dev": "next dev -p 3007",
  "build": "next build",
  "start": "next start -p 3007",
  ...
}
```

#### next.config.js

```javascript
serverRuntimeConfig: {
  port: parseInt(process.env.PORT, 10) || 3007,
},
```

#### next.dev.js

```javascript
// Set the port
const port = 3007;
const dev = true;
```

#### restart-server.sh

```bash
# Start the server on port 3007
echo "Starting server on port 3007..."
nohup npm run start > server.log 2>&1 &
```

#### run-dev.sh

```bash
# Run the custom Next.js development server
echo "Starting development server on port 3007..."
node next.dev.js
```

### 2. Update Client-Side Fallback URLs

#### youtube-workflows.ts

```javascript
// Force use of current window origin to avoid hardcoded port issues
const baseUrl = typeof window !== 'undefined' ? window.location.origin : 'http://localhost:3007';
const SOCIAL_INTEL_URL = `${baseUrl}/api/social-intel`;
```

### 3. Update Port-Fix Script 

#### public/port-fix.js

Modified the port-fix.js script to handle port 3007:

```javascript
// Replace hardcoded ports with current window origin
if (url.includes('localhost:3000') || url.includes('localhost:3003') || 
    url.includes('localhost:3005') || url.includes('localhost:3007')) {
  url = url.replace(/http:\/\/localhost:(3000|3003|3005|3007)/g, currentOrigin);
  console.log('Port fix: Redirecting API call to', url);
}
```

### 4. Resolve Duplicate Page Issues

We encountered duplicate page issues during the fix:

```
⚠ Duplicate page detected. src/pages/workflows/niche-scout.tsx and src/pages/workflows/niche-scout/index.tsx resolve to /workflows/niche-scout
⚠ Duplicate page detected. src/pages/workflows/seed-to-blueprint.tsx and src/pages/workflows/seed-to-blueprint/index.tsx resolve to /workflows/seed-to-blueprint
```

We resolved this by:
1. Moving the root-level workflow files to backup files:
   ```bash
   mv niche-scout.tsx niche-scout.tsx.bak
   mv seed-to-blueprint.tsx seed-to-blueprint.tsx.bak
   ```
2. Using only the index.tsx files within each workflow subdirectory

## Testing the Resolution

To test that the port conflict has been resolved:

1. Start the server:
   ```bash
   cd /home/locotoki/projects/alfred-agent-platform-v2/services/mission-control
   ./restart-server.sh
   ```

2. Access the workflow interface at: 
   ```
   http://localhost:3007/workflows
   ```

3. Test both workflows:
   - Niche-Scout workflow
   - Seed-to-Blueprint workflow

4. Verify API calls are being routed correctly (check server.log)

## Future Recommendations

1. **Consistent Environment Configuration**: Use a .env file for port configuration to avoid hardcoded values
2. **Service Discovery**: Implement a service registry for microservices to avoid hardcoded URLs
3. **Health Checks**: Add robust health checks that verify correct port configurations
4. **Port Conflict Detection**: Add startup checks to detect and warn about port conflicts
5. **API Gateway**: Consider using an API gateway for routing to avoid internal port concerns
6. **Standardize Endpoint Structure**: Consolidate on a consistent URL pattern for API endpoints

## Conclusion

By ensuring consistent port configuration across all files and handling port-dependent dynamic URLs properly, we've resolved the port conflict issues. The Mission Control service now successfully runs on port 3007 with all workflows functioning as expected, even with mock data when backend services are unavailable.