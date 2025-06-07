### v0.9.23-beta1
* cold-start (minimal): 0s
* ML base image: ghcr.io/locotoki/vector-ingest-base:ml-20250607 (2.71GB)
* Status: Ready for ML deployment

### ML Enablement Test (PR #685)
* cold-start (ML-enabled): 1s (target ≤ 10s) ✅
* Health endpoint functional: ✅
* Note: ML model loading has permission issue in base image (cache directory)
* Status: ML infrastructure ready, model loading needs permission fix

