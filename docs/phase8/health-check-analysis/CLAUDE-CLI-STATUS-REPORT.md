# Claude CLI / Local Stack Status Report
*Generated: 25 May 2025*

## 1. Stack Health & Uptime

### Container Status Summary
- **Total Services**: 59
- **Healthy Services**: 36 (61%)
- **Unhealthy Services**: 23 (39%)
- **Key Healthy Services**: db-postgres, redis, agent-core, db-auth, slack-adapter, telegram-adapter

### Service Health Details

#### Healthy Core Services
- **Infrastructure**: db-postgres, redis, pubsub-emulator (all healthy)
- **Authentication**: db-auth, auth-ui (both healthy)
- **Adapters**: slack-adapter, telegram-adapter (both healthy)
- **Core**: agent-core, agent-bizdev (both healthy)
- **Monitoring**: monitoring-metrics, monitoring-dashboard (both healthy)

#### Unhealthy Services (Need Investigation)
- **Agents**: agent-atlas, agent-social
- **Database Services**: db-admin, db-api, db-realtime, db-storage
- **Metrics Exporters**: All db-*-metrics services
- **Models**: model-router, model-registry
- **Others**: llm-service, mail-server, vector-db

### Benchmark Results
- **Cold Start Mean**: 14.0 seconds (from bench/cold_start.json)
- **Build Profile**: Available at bench/build_profile.txt

## 2. Git Repo & CI Status

### Current Branch & Commit
```
Branch: main (up to date with origin/main)
Latest Commit: 8ff6ef1 fix: resolve port conflicts in docker-compose.yml (#485)
```

### Recent Commits (Last 10)
1. 8ff6ef1 - fix: resolve port conflicts in docker-compose.yml (#485)
2. 5dc6e9b - fix(mission-control): make COPY paths repo-root-safe & simplify build (#483)
3. 951ec54 - feat(alfred-core): add health.json asset file (#482)
4. 9fd744e - fix(alfred-core): remove leading slash from ASSETS default value (#481)
5. 0071b4a - fix(core): use \ env var to satisfy BuildKit (#480)

### Working Directory State
- **Modified Files**: 1 (alfred/adapters/slack/Dockerfile)
- **Untracked Files**: 23 (mostly documentation and override files)
- **Key Changes**: Port conflict fixes, health check improvements, development environment setup

### Open Pull Requests (Top 10)
| PR# | Title | Branch | Status | Created |
|-----|-------|--------|--------|---------|
| 466 | Add healthcheck prefix validation to CI | ci/release-root-context | OPEN | 2025-05-25 |
| 465 | Align healthcheck base-image prefix | chore/align-healthcheck-prefix | OPEN | 2025-05-25 |
| 445 | ci: add --no-cache to release image builds | ci/cache-busting-release-workflow | OPEN | 2025-05-25 |
| 432 | Fix: pubsub-metrics Dockerfile & health-check | fix/pubsub-metrics-dockerfile | OPEN | 2025-05-24 |
| 420 | ADR-013: BizDev service architecture | feat/adr-013-bizdev-arch | OPEN | 2025-05-24 |

### CI Status
- **Lint**: ✅ Passing ("Lint check passed with global ignores applied")
- **CI Workflows Available**:
  - ci-tier0.yml
  - ci.yml
  - python-ci.yml
  - lint.yml
  - test-explainer.yml

## 3. Key Accomplishments

### Completed Tasks
1. **PR #485 (Merged)**: Fixed port conflicts
   - slack_mcp_gateway: 3000 → 3010
   - slack-adapter: 3001 → 3011
   - hubspot-mock: 8000 → 8088

2. **Critical Service Fixes**:
   - Fixed slack-adapter missing uvicorn dependency
   - Created auth_db database and schema for db-auth
   - Applied comprehensive health check overrides

3. **Health Improvements**:
   - Increased healthy services from 11 to 36
   - Created targeted health check configurations
   - Documented fixes and improvements

## 4. Blockers & Issues

### Immediate Blockers
1. **23 Unhealthy Services**: Various database and metrics services remain unhealthy
2. **Alfred CLI**: No status command available (tried `alfred status` - command not found)
3. **Agent Logs**: agent-core and agent-bizdev logs are empty (may be using different logging)

### Technical Debt
- Multiple open PRs need review/merge
- Untracked files need to be committed or gitignored
- Some services missing proper health check implementations

## 5. Recommendations

### Next Steps (Priority Order)
1. **Investigate Unhealthy Services**: Focus on database services (db-admin, db-api, etc.)
2. **Clean Working Directory**: Commit or gitignore the 23 untracked files
3. **Review Open PRs**: Several CI/health-related PRs could improve stability
4. **Document Alfred CLI**: The CLI exists but lacks documentation for available commands

### Quick Wins
- Merge PR #465 & #466 for healthcheck improvements
- Apply similar fixes to slack-adapter for other unhealthy services
- Create health check documentation for remaining services

## 6. Command Outputs

### Service Count Summary
```bash
docker-compose ps | wc -l  # 60 total (59 services + header)
Healthy: 36
Unhealthy: 23
```

### Available Tools
- Docker Compose: ✅ Working
- Make: ✅ Working (lint command successful)
- GitHub CLI: ✅ Working
- Alfred CLI: ⚠️ Exists but limited functionality

### Test Coverage
- pytest.ini and pytest-ci.ini present
- Lint checks passing
- Full test suite status unknown (would need to run)
