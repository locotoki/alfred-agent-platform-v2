# Port and Workflow Fixes

We've fixed multiple issues with the mission-control service related to port configuration, missing pages, and type errors.

## Port Configuration

The mission-control service was configured to use port 3003, but it was actually running on port 3007. We've updated all port references to consistently use port 3007:

1. Updated `package.json` dev and start scripts to use port 3007
2. Updated `next.config.js` server runtime config to use port 3007
3. Updated `next.dev.js` port configuration to use port 3007
4. Updated `restart-server.sh` to reference port 3007
5. Updated `run-dev.sh` to reference port 3007
6. Updated `public/port-fix.js` to handle port 3007
7. Updated `services/youtube-workflows.ts` to use port 3007 as fallback

## Missing Workflow Pages

We detected and fixed the missing workflow index pages:

1. Created `/pages/workflows/niche-scout/index.tsx` based on the fixed version
2. Created `/pages/workflows/seed-to-blueprint/index.tsx` to handle the blueprint workflow

## Duplicate Page Resolution

During testing, we encountered duplicate page issues where both `/workflows/niche-scout.tsx` and `/workflows/niche-scout/index.tsx` were resolving to the same route. Fixed by:

1. Moving the root-level workflow files (`niche-scout.tsx` and `seed-to-blueprint.tsx`) to backup files
2. Keeping only the index.tsx files within each workflow subdirectory

## Type Issues and Variable Fixes

Fixed multiple type errors and variable reference issues:

1. Modified archived files to comment out imports and non-essential code
2. Fixed variable references in `seed-to-blueprint.ts` API handler
3. Updated type references in component files to match the defined schemas

## API Endpoint Handling

The `youtube-workflows.ts` service was attempting multiple endpoint paths to handle URL structure variability. We've kept this functionality but updated it to use the correct port.

## How to Run the Service

To run the fixed workflows:

1. Stop any running Next.js servers
2. Run `cd /home/locotoki/projects/alfred-agent-platform-v2/services/mission-control && npm run dev -- -p 3007`
3. Access the workflows at http://localhost:3007/workflows

## Remaining Issues

Some potential areas that may need additional work:

1. The `MainLayout` component may need additional styling or adjustments
2. API endpoint paths should be further standardized to eliminate multiple fallback attempts
3. Mock data generation could be centralized to maintain consistency
4. Component and type definitions need thorough review to ensure compatibility with the frontend UI
