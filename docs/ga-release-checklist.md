# GA Release Checklist - v3.0.0

Target Date: **July 11, 2025**

## Pre-Release (1 Week Before)

### Code Quality
- [ ] All CI checks passing on main branch
- [ ] 100% health check coverage verified
- [ ] No critical or high security vulnerabilities
- [ ] All P0/P1 bugs resolved
- [ ] Code freeze declared

### Integration Requirements
- [ ] `/alfred health` command returns success within 5 seconds
- [ ] Slack MCP Gateway health endpoint responds with `{"status":"ok"}`
- [ ] Echo agent processes commands from Redis stream
- [ ] All Slack integration tests passing in CI

### Documentation
- [ ] Production deployment guide complete
- [ ] API documentation up to date
- [ ] Architecture diagrams current
- [ ] CHANGELOG.md updated
- [ ] Migration guide for v2.x users

### Infrastructure
- [ ] Production environment provisioned
- [ ] SSL certificates obtained/configured
- [ ] DNS records configured
- [ ] Monitoring dashboards imported
- [ ] Alerting rules configured
- [ ] Backup procedures tested

## Release Day

### Morning (9 AM)
- [ ] Final CI run on main branch
- [ ] Run full test suite locally
- [ ] Verify all health checks pass
- [ ] Create release branch: `release/v3.0.0`
- [ ] Update version numbers in:
  - [ ] VERSION file
  - [ ] package.json files
  - [ ] pyproject.toml files
  - [ ] Chart.yaml
  - [ ] docker-compose.yml files

### Build & Tag (10 AM)
- [ ] Run `./scripts/tag-ga-release.sh v3.0.0`
- [ ] Verify all Docker images built successfully
- [ ] Push images to GHCR
- [ ] Tag git repository
- [ ] Push tag to GitHub

### Deployment (11 AM)
- [ ] Deploy to staging environment
- [ ] Run smoke tests on staging
- [ ] Deploy to production
- [ ] Verify all services healthy
- [ ] Run production smoke tests

### Release (12 PM)
- [ ] Create GitHub release
- [ ] Attach release artifacts:
  - [ ] Helm chart package
  - [ ] Docker compose bundle
  - [ ] Release notes
- [ ] Update GitHub project board
- [ ] Close v3.0.0 milestone

### Communication (1 PM)
- [ ] Send release announcement to:
  - [ ] Slack #general channel
  - [ ] Engineering mailing list
  - [ ] Stakeholders email
- [ ] Update status page
- [ ] Post on social media (if applicable)
- [ ] Update documentation site

## Post-Release

### Day 1
- [ ] Monitor error rates and latency
- [ ] Check for any critical issues
- [ ] Review support tickets
- [ ] Gather initial feedback

### Week 1
- [ ] Conduct retrospective
- [ ] Document lessons learned
- [ ] Plan v3.1.0 features
- [ ] Address any post-release issues

## Rollback Plan

If critical issues are discovered:

1. **Immediate Actions**
   ```bash
   # Revert to previous version
   helm rollback alfred-prod -n alfred-prod

   # Or with Docker Compose
   docker-compose down
   git checkout v2.9.0
   docker-compose up -d
   ```

2. **Communication**
   - Notify all stakeholders
   - Update status page
   - Create incident report

3. **Investigation**
   - Gather logs and metrics
   - Identify root cause
   - Create hotfix plan

## Success Metrics

- [ ] All services report healthy
- [ ] Error rate < 0.1%
- [ ] P95 latency < 500ms
- [ ] No P0/P1 incidents in first 24 hours
- [ ] Positive user feedback

## Special Considerations

### db-auth Service
- The custom Dockerfile patches GoTrue migrations
- Monitor for any authentication issues
- Have rollback plan ready

### CI Infrastructure Issues
These are documented but non-blocking:
- #492: Docker Compose parity yq bug
- #493: Template validation
- #494: Mypy type errors
- #495: Financial tax imports

### Resource Limits
All services have defined limits:
- Monitor for OOM kills
- Adjust if necessary
- Document any changes

## Sign-offs

- [ ] Engineering Lead: _________________ Date: _______
- [ ] Product Manager: _________________ Date: _______
- [ ] DevOps Lead: _________________ Date: _______
- [ ] QA Lead: _________________ Date: _______

---

**Remember**: This is a significant milestone. Take time to celebrate the team's achievement! 🎉
