# YouTube Workflow Implementation - Quick Start Guide

## Project Overview
The Alfred Agent Platform v2 includes a Social Intelligence Agent with YouTube workflows. The Mission Control UI is being enhanced to interface with these workflows.

## Current Status
- **UI Components**: Both Niche-Scout and Seed-to-Blueprint workflow pages already exist
- **API Integration**: Base endpoints created with dynamic port detection
- **Port Configuration**: Mission Control UI runs on 3007, Social Intelligence Agent on 9000
- **Dynamic URL Handling**: All components use dynamic URL construction for resilience

## Key Files & Locations

### UI Pages
- `/services/mission-control/src/pages/workflows/niche-scout/index.tsx`: Niche Scout form
- `/services/mission-control/src/pages/workflows/niche-scout/results/[id].tsx`: Results page
- `/services/mission-control/src/pages/workflows/seed-to-blueprint/index.tsx`: Blueprint form
- `/services/mission-control/src/pages/workflows/seed-to-blueprint/results/[id].tsx`: Results page

### API Endpoints
- `/services/mission-control/src/pages/api/social-intel/niche-scout.ts`: Niche Scout API proxy
- `/services/mission-control/src/pages/api/social-intel/seed-to-blueprint.ts`: Blueprint API proxy
- `/services/mission-control/src/pages/api/social-intel/workflow-history.ts`: Workflow history API
- `/services/mission-control/src/pages/api/social-intel/workflow-result/[id].ts`: Results API

### Services
- `/services/mission-control/src/services/youtube-workflows.ts`: Core service for YouTube API integration

### Types
- `/services/mission-control/src/types/youtube-workflows.ts`: TypeScript types for all workflow entities

## Required Configurations

1. **Port Configuration**
   - Verify that `package.json` has proper port configuration (should use port 3007 for dev and start commands)
   - Ensure `.env.local` contains `SOCIAL_INTEL_URL=http://localhost:9000` and `NEXT_PUBLIC_SERVER_URL=http://localhost:3007`
   - Refer to `PORT-STANDARD.md` at the project root for the official port configuration standards

2. **API Integration**
   - The service layer already uses dynamic origin detection:
   ```typescript
   const baseUrl = typeof window !== 'undefined' ? window.location.origin : 'http://localhost:3007';
   const SOCIAL_INTEL_URL = `${baseUrl}/api/social-intel`;
   ```

3. **Error Handling**
   - API endpoints have robust error handling with fallback to mock data
   - Multiple endpoint paths are tried in sequence for better resilience

## Quick Start Steps

1. **Verify Port Configuration**
   ```bash
   cat /services/mission-control/package.json
   # Verify "dev": "next dev -p 3007" and "start": "next start -p 3007"
   
   cat /services/mission-control/.env.local
   # Verify SOCIAL_INTEL_URL=http://localhost:9000
   # Verify NEXT_PUBLIC_SERVER_URL=http://localhost:3007
   ```

2. **Run the Environment Check Script**
   ```bash
   # Navigate to the project root
   cd /home/locotoki/projects/alfred-agent-platform-v2
   
   # Run the environment check script
   bash ./docs/phase6-mission-control/youtube-workflows/environment-check-script.sh
   ```

3. **Start the Services**
   ```bash
   # Start the Social Intelligence Agent container if not running
   docker-compose up -d social-intel
   
   # Start the Mission Control UI
   cd services/mission-control
   npm run dev
   ```

4. **Test Workflows**
   - Navigate to http://localhost:3007/workflows
   - Try the Niche-Scout workflow with a sample query 
   - Check the Blueprint workflow with a sample YouTube URL

## Working with Ports

Due to frequent port conflicts in the 3000-3005 range, we've standardized on using port 3007 for the Mission Control UI. If you encounter port conflicts:

1. **Check for running processes:**
   ```bash
   lsof -i :3007
   ```

2. **Kill any conflicting processes:**
   ```bash
   kill -9 $(lsof -t -i:3007)
   ```

3. **Restart Mission Control:**
   ```bash
   cd services/mission-control
   npm run dev
   ```

## Additional Notes

- The Social Intelligence Agent container should be running on port 9000
- Mock implementations are in place for development and testing when the API is unavailable
- The system tries multiple endpoint paths to handle different API structures
- All API components use dynamic URL handling to avoid hardcoded port references
- The `PORT-STANDARD.md` file at the project root serves as the authoritative reference for port configuration

## Next Steps

1. Test both workflows with actual API integration
2. Monitor network requests to ensure proper routing
3. Enhance error handling for edge cases
4. Update implementation status documentation