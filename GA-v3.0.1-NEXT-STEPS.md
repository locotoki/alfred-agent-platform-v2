# GA v3.0.1 Patch Release - Next Steps Plan

## Current State Summary

### ✅ Completed
1. **GA v3.0.0 Release** (2025-05-27)
   - 12 services built and pushed to GHCR
   - Helm chart v3.0.0 published
   - GitHub release created

2. **v3.0.1 Patches Built**
   - agent-core:v3.0.1
   - agent-bizops:v3.0.1 (PR #592)
   - contact-ingest:v3.0.1 (PR #593)
   - slack-adapter:v3.0.1
   - db-metrics:v3.0.1

### 🔄 In Progress
1. **Open PRs**
   - PR #589: crm-sync circular import fix
   - PR #592: agent-bizops import path fix
   - PR #593: contact-ingest module structure fix

2. **Known Issues**
   - ✅ contact-ingest: Health check fixed - curl added to v3.0.1 (branch: fix/contact-ingest-imports-591)
   - crm-sync: Waiting for PR #589 to build v3.0.1
   - Several services missing from GA workflow

## Next Steps Action Plan

### Phase 1: Complete v3.0.1 Patch (Priority: HIGH)

1. **✅ COMPLETED: Fixed contact-ingest health check**
   - Added curl to Dockerfile
   - Built and pushed contact-ingest:v3.0.1
   - Branch: fix/contact-ingest-imports-591 (ready to merge)

2. **Merge PR #589 and build crm-sync:v3.0.1**
   ```bash
   # After merge:
   docker buildx build --platform linux/amd64,linux/arm64 \
     -t ghcr.io/digital-native-ventures/alfred-agent-platform-v2/crm-sync:v3.0.1 \
     --push -f services/crm-sync/Dockerfile .
   ```

3. **Test v3.0.1 stack locally**
   ```bash
   TAG=v3.0.1 docker compose up -d \
     agent-core agent-bizdev contact-ingest slack-adapter crm-sync db-metrics
   ```

4. **Tag and release v3.0.1**
   ```bash
   git tag -a v3.0.1 -m "Patch release: Fix import errors in multiple services"
   git push origin v3.0.1
   ```

### Phase 2: Update GA Workflow (Priority: MEDIUM)

1. **Add missing services to docker-release.yml**
   - ui-chat
   - ui-admin
   - agent-atlas
   - hubspot-mock
   - model-registry
   - model-router

2. **Create PR for workflow updates**

### Phase 3: Full Stack Validation (Priority: HIGH)

1. **Deploy to staging with v3.0.1**
   ```bash
   helm upgrade alfred-staging ./charts/alfred \
     --set global.image.tag=v3.0.1 \
     --namespace staging
   ```

2. **Run smoke tests**
   - Health endpoints
   - Basic API functionality
   - Inter-service communication

3. **Monitor for 30 minutes**
   - Check logs for errors
   - Verify metrics collection
   - Test alert firing

### Phase 4: Production Deployment (Priority: CRITICAL)

1. **Create deployment checklist**
2. **Schedule maintenance window**
3. **Deploy v3.0.1 to production**
4. **Post-deployment verification**

## Service Status Matrix

| Service | v3.0.0 Status | v3.0.1 Status | Action Required |
|---------|---------------|---------------|-----------------|
| agent-core | ✅ Built | ✅ Built | None |
| agent-bizops | ❌ Import error | ✅ Fixed & Built | Merge PR #592 |
| contact-ingest | ❌ Module error | ✅ Fixed & Built | Merge PR #593 |
| crm-sync | ❌ Circular import | 🔄 PR #589 | Merge and build |
| slack-adapter | ✅ Built | ✅ Built | None |
| db-metrics | ✅ Built | ✅ Built | None |
| ui-chat | ❌ Not in workflow | - | Add to workflow |
| hubspot-mock | ❌ Not in workflow | - | Add to workflow |

## Risk Assessment

1. **High Risk**: crm-sync circular import blocking CRM functionality
2. **Medium Risk**: Health checks failing may trigger false alerts
3. **Low Risk**: Missing services from workflow (can be built manually)

## Success Criteria

- [ ] All GA services passing health checks
- [ ] No import errors in logs
- [ ] Staging deployment stable for 1 hour
- [ ] Prometheus metrics being collected
- [ ] Slack integration functional

## Timeline

- **Today**: Complete v3.0.1 patches, test locally
- **Tomorrow**: Deploy to staging, monitor
- **Day 3**: Production deployment