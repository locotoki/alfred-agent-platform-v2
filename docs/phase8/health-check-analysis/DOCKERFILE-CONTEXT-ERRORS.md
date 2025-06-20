# Dockerfile Context / COPY Errors

## 1. model-router
- **Dockerfile Path**: services/model-router/Dockerfile
- **Issue**: COPY app/ app/ - but no app/ directory exists in services/model-router/
- **Error**: Build will fail with "COPY failed: file not found in build context"
- **Fix Needed**: Create app/main.py with basic FastAPI health endpoint

## 2. model-registry
- **Dockerfile Path**: services/model-registry/Dockerfile
- **Issue**: Similar issue - missing app/ directory
- **Error**: Build will fail with "COPY failed: file not found in build context"
- **Fix Needed**: Create app/main.py with basic FastAPI health endpoint

## 3. agent-atlas
- **Dockerfile Path**: services/atlas-worker/Dockerfile
- **Issue**: Needs investigation - using atlas-worker:latest image
- **Current State**: Empty logs suggest build or startup failure

## 4. agent-social
- **Dockerfile Path**: services/architect-api/Dockerfile
- **Issue**: Needs investigation - using alfred-agent-platform-v2-architect-api:latest
- **Current State**: Empty logs suggest build or startup failure

## 5. Stub Dockerfiles (not real services)
- **alfred/model/router/Dockerfile**: Just `FROM alpine:3.19` with sleep infinity
- **alfred/model/registry/Dockerfile**: Just `FROM alpine:3.19` with sleep infinity
- **These are placeholders** - the real services are in services/ directory

## 6. Healthcheck Binary Issue
- Several Dockerfiles reference: `ghcr.io/alfred-health/healthcheck:latest`
- Should be: `ghcr.io/locotoki/alfred-agent-platform-v2/healthcheck:0.4.0`
- Affects: model-router, model-registry, possibly others

## Build Context Summary
Services failing due to missing files:
1. model-router - missing app/ directory
2. model-registry - missing app/ directory
3. Various services using wrong healthcheck image reference
