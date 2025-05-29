# Staging Deployment Guide for v3.0.1

**Date**: 2025-05-29
**Version**: v3.0.1
**Status**: Ready for Deployment (Pending Kubernetes Access)

## Prerequisites

Before deploying to staging, ensure:

1. **Kubernetes Context**: Set to staging cluster
   ```bash
   kubectl config use-context staging
   ```

2. **GHCR Access**: Helm must be authenticated to pull from GHCR
   ```bash
   echo $GITHUB_TOKEN | helm registry login ghcr.io -u $GITHUB_USER --password-stdin
   ```

3. **Namespace Permissions**: Ensure you have permissions to create/update resources in `alfred-staging`

## Deployment Script

The deployment script (`deploy-staging-v3.0.1.sh`) will:

1. Create the namespace if it doesn't exist
2. Deploy the Helm chart v3.0.1
3. Wait for all pods to be ready (up to 10 minutes)
4. Run smoke tests on core services

## Expected Outcome

When deployed to a proper staging environment, you should see:

```
🚀 Deploying Alfred v3.0.1 to staging namespace: alfred-staging
namespace/alfred-staging created
📦 Installing Helm chart...
Release "alfred" has been upgraded. Happy Helming!
NAME: alfred
LAST DEPLOYED: Wed May 29 09:51:00 2025
NAMESPACE: alfred-staging
STATUS: deployed
REVISION: 1
TEST SUITE: None

🔍 Checking deployment status...
NAME                           READY   STATUS    RESTARTS   AGE
agent-core-5d7b9c6f4b-abc123   1/1     Running   0          2m
agent-bizdev-7f8d5c4b9-def456  1/1     Running   0          2m
contact-ingest-6b5d8c7f-ghi789 1/1     Running   0          2m
crm-sync-8c9d6b5f4-jkl012      1/1     Running   0          2m
slack-adapter-5f7b8c9d-mno345  1/1     Running   0          2m
db-metrics-7d8c5b6f9-pqr678    1/1     Running   0          2m

🧪 Running smoke tests...
Testing agent-core...
✅ agent-core healthy
Testing agent-bizdev...
✅ agent-bizdev healthy
✅ v3.0.1 staged and healthy.
```

## Manual Deployment Steps

If the script fails or you prefer manual deployment:

```bash
# 1. Create namespace
kubectl create namespace alfred-staging

# 2. Deploy Helm chart
helm upgrade --install alfred \
  oci://ghcr.io/digital-native-ventures/charts/alfred \
  --version 3.0.1 \
  --namespace alfred-staging \
  --wait --timeout 10m

# 3. Check pod status
kubectl -n alfred-staging get pods

# 4. Check logs for any service
kubectl -n alfred-staging logs -l app=agent-core --tail=50

# 5. Test health endpoints
kubectl -n alfred-staging port-forward svc/agent-core 8011:8011
# In another terminal:
curl http://localhost:8011/health
```

## Post-Deployment Verification

1. **Check all pods are running**:
   ```bash
   kubectl -n alfred-staging get pods
   ```

2. **Verify no restart loops**:
   ```bash
   kubectl -n alfred-staging get pods -w
   ```

3. **Check service endpoints**:
   ```bash
   kubectl -n alfred-staging get svc
   kubectl -n alfred-staging get endpoints
   ```

4. **Review logs for errors**:
   ```bash
   for pod in $(kubectl -n alfred-staging get pods -o name); do
     echo "=== $pod ==="
     kubectl -n alfred-staging logs $pod --tail=20 | grep -i error || echo "No errors"
   done
   ```

## Monitoring

Once deployed, monitor the services for at least 1 hour:

1. **Resource usage**:
   ```bash
   kubectl -n alfred-staging top pods
   ```

2. **Event stream**:
   ```bash
   kubectl -n alfred-staging get events --watch
   ```

3. **Service logs**:
   ```bash
   kubectl -n alfred-staging logs -f deployment/agent-core
   ```

## Rollback Plan

If issues are detected:

```bash
# Rollback to previous version
helm rollback alfred -n alfred-staging

# Or completely uninstall
helm uninstall alfred -n alfred-staging
```

## Production Readiness Checklist

Before promoting to production:

- [ ] All pods stable for 1+ hours
- [ ] No error logs in any service
- [ ] Health checks consistently passing
- [ ] Resource usage within expected limits
- [ ] No pod restarts after initial startup
- [ ] Inter-service communication verified
- [ ] Metrics being collected properly

## Current Status

✅ **v3.0.1 is ready for staging deployment**

The deployment script and all artifacts are prepared. Once Kubernetes staging access is configured, the deployment can proceed using the provided script.

---

**Note**: The local testing has verified that all v3.0.1 images are working correctly. The staging deployment will provide additional validation in a Kubernetes environment before production rollout.