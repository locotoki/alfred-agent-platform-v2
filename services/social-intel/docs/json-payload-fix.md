# JSON Payload Handling Fix

## Issue Description

The Social Intelligence service API endpoints were returning 404 Not Found errors when receiving JSON payloads from the Mission Control service. The root cause was that the FastAPI endpoints were defined to accept query parameters, but the Mission Control service was sending JSON in the request body using an A2A envelope format.

## Root Cause

1. **Mission Control Service** was sending requests with JSON payloads:
   ```javascript
   const payload = {
     intent: 'YOUTUBE_NICHE_SCOUT',
     data: {
       queries: query ? [query as string] : ['mobile gaming tips', 'cooking recipes', 'fitness workouts'],
       category: req.query.category || 'All',
       timeRange: req.query.timeRange || 'Last 30 days',
       demographics: req.query.demographics || 'All'
     },
     task_id: `niche-scout-${Date.now()}`,
     trace_id: `trace-${Date.now()}`
   };
   ```

2. **Social Intelligence Service** endpoints were only defined to accept query parameters:
   ```python
   @app.post("/niche-scout")
   async def run_niche_scout(
       query: str = Query(None, description="Optional query to focus the niche analysis"),
       category: str = Query(None, description="Main content category (e.g., 'tech', 'kids')"),
       subcategory: str = Query(None, description="Specific subcategory (e.g., 'kids.nursery')")
   ):
   ```

This mismatch in communication formats caused the API calls to fail with 404 errors, as the required parameters weren't found where the Social Intelligence service was looking for them.

## Solution

The solution was to update the FastAPI endpoint handlers to accept and parse both query parameters and JSON request bodies:

1. Added `Request` parameter to extract the raw request body:
   ```python
   @app.post("/niche-scout")
   async def run_niche_scout(
       request: Request,  # Added this parameter
       query: str = Query(None, description="Optional query to focus the niche analysis"),
       category: str = Query(None, description="Main content category (e.g., 'tech', 'kids')"),
       subcategory: str = Query(None, description="Specific subcategory (e.g., 'kids.nursery')")
   ):
   ```

2. Added code to extract parameters from JSON body (with A2A envelope support):
   ```python
   # Try to parse JSON body if present
   json_data = {}
   try:
       json_data = await request.json()
       logger.info("Received JSON payload", payload=json_data)

       # If this is an A2A envelope, extract the relevant fields
       if json_data.get("intent") == "YOUTUBE_NICHE_SCOUT":
           # Extract data from A2A envelope
           data = json_data.get("data", {})
           queries = data.get("queries", [])
           if queries and isinstance(queries, list):
               query = queries[0]  # Use the first query
               logger.info("Extracted query from JSON payload", query=query)

           # Extract category from JSON payload
           json_category = data.get("category")
           if json_category and json_category != "All":
               category = json_category
               logger.info("Using category from JSON payload", category=category)
           elif json_category == "All":
               category = None
   except Exception as e:
       logger.error("Failed to parse JSON body, using query parameters", error=str(e))
   ```

3. Added similar changes to all relevant endpoints (`/niche-scout`, `/youtube/niche-scout`, `/api/youtube/niche-scout`, etc.)

## Testing

After implementing the fix:
1. The API successfully handles JSON payloads from Mission Control
2. Parameters are correctly extracted from the A2A envelope format
3. The services can now communicate properly with both query parameters and JSON body formats
4. Detailed logging was added to diagnose parameter extraction

## Technical Notes

- The fix maintains backward compatibility with query parameters
- The code prefers JSON body parameters over query parameters when both are present
- The API can now properly work with the A2A envelope format used for inter-service communication
- Error handling ensures the API still works even if JSON parsing fails

## Related Files

- `/app/app/main.py` - Main FastAPI application file where the fix was implemented
- `/services/mission-control/src/pages/api/social-intel/niche-scout.ts` - Mission Control API endpoint that sends the JSON payloads