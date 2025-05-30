# Immediate Actions for Baseline Stabilization

## Current State (May 30, 2025)
- ✅ 9/10 services healthy
- ❌ 1 service unhealthy (db-api - missing anon role)
- ✅ Meeting GA requirement (≤2 unhealthy)
- 🚧 Need reproducible setup process

## Today's Priority Actions

### 1. Fix db-api (10 minutes)
```bash
# Option A: Rebuild postgres with init script
docker compose down db-postgres db-api
docker compose up -d db-postgres
# Wait for postgres to be ready
docker compose up -d db-api

# Option B: Manual fix attempt
./scripts/fix-db-api.sh
```

### 2. Capture Baseline Hash (5 minutes)
```bash
# Run audit and save hash
./scripts/audit-core.sh > logs/baseline-audit.txt
cat logs/baseline-audit.txt | sha256sum > core-baseline/audit.hash

# Commit the baseline
git add core-baseline/audit.hash logs/baseline-audit.txt
git commit -m "chore: lock core baseline configuration"
```

### 3. Test Fresh Setup (15 minutes)
```bash
# Simulate new developer experience
docker compose down --volumes --remove-orphans
docker network rm alfred-network || true

# Run bootstrap
./scripts/bootstrap-dev.sh

# Verify all healthy
./scripts/check-core-health.sh
```

### 4. Create CI Workflow (20 minutes)
Create `.github/workflows/core-health-gate.yml`:
```yaml
name: Core Health Gate
on: [push, pull_request]

jobs:
  core-health:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Start Core Services
        run: |
          docker compose up -d redis redis-exporter db-postgres db-api \
            agent-core telegram-adapter pubsub-emulator pubsub-metrics \
            monitoring-metrics monitoring-dashboard
            
      - name: Wait for Services
        run: sleep 120
        
      - name: Check Health
        run: ./scripts/check-core-health.sh
        
      - name: Verify Baseline
        run: |
          ./scripts/audit-core.sh > current-audit.txt
          diff core-baseline/audit.hash <(cat current-audit.txt | sha256sum)
```

## This Week's Goals

### Monday - Lock the Baseline ✅
- [x] Create audit script
- [x] Create bootstrap script
- [x] Create health check script
- [ ] Fix db-api permanently
- [ ] Capture and commit baseline hash

### Tuesday - CI Integration
- [ ] Create GitHub workflow
- [ ] Test on feature branch
- [ ] Add to branch protection rules

### Wednesday - Documentation
- [ ] Update main README
- [ ] Create troubleshooting guide
- [ ] Document environment variables

### Thursday - Golden Images
- [ ] Create Dockerfile for hardened postgres
- [ ] Create Dockerfile for redis with auth
- [ ] Push to GitHub Container Registry

### Friday - Team Rollout
- [ ] Team demo of bootstrap process
- [ ] Gather feedback
- [ ] Address any issues

## Definition of Done

- [ ] New developer can go from clone to healthy in <5 minutes
- [ ] CI prevents unhealthy services from merging
- [ ] Baseline audit hash is tracked in git
- [ ] All 10 core services consistently healthy
- [ ] No manual SQL commands needed

## Tracking Metrics

| Metric | Current | Target |
|--------|---------|---------|
| Time to healthy | ~15 min | <5 min |
| Manual steps | 3-4 | 1 |
| Success rate | ~70% | 100% |
| Services healthy | 9/10 | 10/10 |

## Communication Plan

1. **Slack Update** (Today)
   ```
   🎯 Baseline Stabilization Update
   
   ✅ Achieved 9/10 healthy services
   ✅ Created automated bootstrap script
   🚧 Fixing last unhealthy service (db-api)
   
   New developer setup: ./scripts/bootstrap-dev.sh
   ```

2. **PR Description** (When ready)
   ```
   ## Baseline Stabilization
   
   Locks down core service configuration to prevent drift.
   
   ### Changes
   - Added audit script to capture baseline
   - Added bootstrap script for reproducible setup
   - Added health check script
   - Added CI workflow to enforce baseline
   
   ### Testing
   - Verified fresh setup works
   - All 10 core services healthy
   - CI gate prevents drift
   ```