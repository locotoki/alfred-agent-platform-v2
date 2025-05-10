# Social Intelligence Service - Current State

## 1. Folder & Service Map

### Main Folders
- `/services/social-intel` - Main service directory
  - `/app` - Core service implementation
    - `/templates` - HTML report templates
  - Dockerfile - Service container definition

### Docker Components
- **Images**:
  - `social-intelligence` - Main Social Intelligence API service (Python 3.11)
- **Container Names**:
  - `social-intelligence` - Main service container
  - `niche-scout-redis` - Redis container used for caching
  - `qdrant` - Vector database (referenced in Dockerfile)

## 2. Public API Contract

| Method | Path | Auth Header | Request Params | Response Shape |
|--------|------|-------------|----------------|----------------|
| GET | `/status` | None | None | `{"agent": "social-intel", "version": "1.0.0", "status": "running", "supported_intents": [...]}` |
| GET | `/health/` | None | None | `{"status": "healthy", "service": "social-intel", "version": "1.0.0"}` |
| GET | `/health/metrics` | None | None | Prometheus metrics |
| GET | `/health/ready` | None | None | `{"status": "ready"}` |
| GET | `/health/live` | None | None | `{"status": "alive"}` |
| POST | `/force-analyze` | None | `query: string` | `{"query": "...", "results": [...]}` |
| POST | `/niche-scout` | None | `query?: string, category?: string, subcategory?: string` | `{"date": "...", "query": "...", "niches": [...], "analysis_summary": {...}, "recommendations": [...], "_id": "...", "_files": {...}}` |
| POST | `/youtube/niche-scout` | None | Same as `/niche-scout` | Same as `/niche-scout` |
| POST | `/api/youtube/niche-scout` | None | Same as `/niche-scout` | Same as `/niche-scout` |
| POST | `/seed-to-blueprint` | None | `video_url?: string, niche?: string` | `{"date": "...", "seed_type": "...", "seed_value": "...", "analyzed_niche": "...", "competitor_analysis": [...], "content_gaps": [...], "channel_strategy": {...}, "execution_plan": {...}, "_id": "...", "_files": {...}}` |
| POST | `/youtube/blueprint` | None | Same as `/seed-to-blueprint` | Same as `/seed-to-blueprint` |
| POST | `/api/youtube/blueprint` | None | Same as `/seed-to-blueprint` | Same as `/seed-to-blueprint` |
| GET | `/workflow-result/{result_id}` | None | `type: string` | Depends on workflow type (niche-scout or seed-to-blueprint) |
| GET | `/youtube/workflow-result/{result_id}` | None | Same as `/workflow-result/{result_id}` | Same as `/workflow-result/{result_id}` |
| GET | `/api/youtube/workflow-result/{result_id}` | None | Same as `/workflow-result/{result_id}` | Same as `/workflow-result/{result_id}` |
| GET | `/workflow-history` | None | None | `[{"id": "...", "workflow_type": "...", "parameters": {...}, "status": "...", "started_at": "...", "completed_at": "...", "result_url": "...", "user_id": "..."}]` |
| GET | `/youtube/workflow-history` | None | None | Same as `/workflow-history` |
| GET | `/api/youtube/workflow-history` | None | None | Same as `/workflow-history` |
| GET | `/scheduled-workflows` | None | None | `[{"id": "...", "workflow_type": "...", "parameters": {...}, "frequency": "...", "next_run": "...", "status": "...", "created_at": "...", "updated_at": "...", "user_id": "..."}]` |
| GET | `/youtube/scheduled-workflows` | None | None | Same as `/scheduled-workflows` |
| GET | `/api/youtube/scheduled-workflows` | None | None | Same as `/scheduled-workflows` |
| POST | `/schedule-workflow` | None | `workflow_type: string, parameters: object, frequency: string, next_run: string` | `{"id": "...", "workflow_type": "...", "parameters": {...}, "frequency": "...", "next_run": "...", "status": "scheduled", "created_at": "...", "updated_at": "...", "user_id": "..."}` |
| POST | `/youtube/schedule-workflow` | None | Same as `/schedule-workflow` | Same as `/schedule-workflow` |
| POST | `/api/youtube/schedule-workflow` | None | Same as `/schedule-workflow` | Same as `/schedule-workflow` |

## 3. Job Schedules & Cron

*None*

Currently, the service implements a scheduled workflow API but does not have any running cron jobs or scheduled tasks. The scheduling functionality is designed around an API that allows users to:

- Schedule workflows with `/schedule-workflow` endpoint
- Retrieve scheduled workflows with `/scheduled-workflows` endpoint 

However, the implementation is simulated with mock data and does not actually execute scheduled jobs.

## 4. Database Objects

*None*

The Social Intelligence service does not directly implement any database tables, models, or schemas. It uses API simulation and in-memory storage instead of persistent database storage.

The service is designed to integrate with:

- Redis (for caching and policy middleware)
- Qdrant (referenced in Dockerfile ENV)

Database connections are simulated with stub implementations:

```python
# From main.py
supabase_transport = SupabaseTransport(
    database_url=os.getenv("DATABASE_URL")
)

redis_client = redis.from_url(os.getenv("REDIS_URL", "redis://redis:6379"))
```

However, actual database operations are not implemented in the current codebase.

## 5. Prometheus Metrics

Metrics are exposed through the `/health/metrics` endpoint using the Prometheus client. 

From the code analysis, there are no explicitly defined custom metrics (no direct references to counter, gauge, or histogram implementations). However, the service uses `create_health_app` which implements standard metrics exposure:

```python
@health_app.get("/metrics")
async def metrics():
    return prometheus_client.generate_latest()
```

The Dockerfile includes the prometheus-client package:

```
prometheus-client==0.19.0
```

## 6. Environment & Secrets

The following environment variables are used in the service:

```
# From Dockerfile
PYTHONPATH=/app
PYTHONUNBUFFERED=1
QDRANT_URL=http://qdrant:6333

# From code
GCP_PROJECT_ID=alfred-agent-platform  # Default value
DATABASE_URL  # No default
REDIS_URL=redis://redis:6379  # Default value
YOUTUBE_API_KEY  # No default, required for actual API calls
```

## 7. Test & Coverage Snapshot

*None*

No formal test suite or coverage reports were found in the codebase. The service includes a `test_youtube.sh` script in the root directory, but it appears to be a manual testing script rather than an automated test suite.

## 8. Open TODO/FIXME Items

*None*

No TODO or FIXME comments were found in the codebase.

## 9. Outstanding Risks / Tech Debt

Based on the code analysis, the following risks and technical debt items are identified:

- **Simulated API Implementations**: Most functionality uses simulated data rather than actual API calls or database operations.
- **Missing Authentication**: No authentication mechanisms are implemented for the API endpoints.
- **No Test Suite**: Lack of automated tests increases the risk of regressions during updates.
- **Data Persistence**: Results are stored in local files rather than a proper database, risking data loss.
- **YouTube API Key Handling**: The API key is directly accessed from environment variables without proper secret management.
- **Error Handling**: Some error paths may not be thoroughly tested or handled.
- **Scalability Concerns**: In-memory data handling may not scale well with increased load.
- **No Input Validation**: Limited validation on user inputs to the API endpoints.
- **Dependency Management**: The Dockerfile creates stub implementations of dependencies rather than using proper package management.