# Vector-Ingest ML Functionality Restoration Plan

## Current State
- Minimal FastAPI service with health endpoint only
- Heavy ML dependencies (langchain, sentence-transformers) removed for P0 cold-start fix
- Original functionality backed up in `worker.py.backup`

## Migration Strategy

### Phase 1: ML Base Image Creation
1. Create `alfred-python-ml` base image with pre-installed ML dependencies
2. Pre-download default model during image build
3. Test cold-start performance with base image

### Phase 2: Service Implementation
1. Create `worker_full.py` with complete functionality:
   - Health endpoints (/health, /healthz)
   - Vector ingestion endpoint (/ingest)
   - Lazy loading for ML models
   - CloudEvents support
   
2. Create `Dockerfile.ml` using ML base image

### Phase 3: Testing & Validation
1. Build and test locally with `build-test.sh`
2. Measure cold-start time (target: <10s)
3. Verify health endpoints work immediately
4. Test ingestion functionality

### Phase 4: Gradual Rollout
1. Deploy to staging with feature flag
2. Run performance tests
3. Monitor resource usage
4. Switch production when validated

## Implementation Files
- `base-images/python-ml/Dockerfile` - ML-enabled base image
- `services/vector-ingest/Dockerfile.ml` - Service Dockerfile using ML base
- `services/vector-ingest/worker_full.py` - Full implementation
- `services/vector-ingest/requirements.txt` - Service dependencies
- `services/vector-ingest/build-test.sh` - Local test script

## Next Steps
1. Test the ML base image build locally
2. Measure cold-start performance
3. Create feature flag for gradual rollout
4. Update docker-compose.yml to use new image when ready