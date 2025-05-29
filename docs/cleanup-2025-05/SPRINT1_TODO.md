# Phase 8.3 Sprint 1 TODO - Alert Grouping MVP

## 1 ▸ Track / Branch Table
| Issue | Branch | Description |
|-------|--------|-------------|
| #90 | `feat/alert-group-model` | Alert group data model |
| #91 | `feat/alert-group-algorithm` | Deduplication algorithm |
| #92 | `feat/alert-group-api` | REST API endpoints |
| #93 | `feat/alert-group-migration` | Database migrations |
| #94 | `feat/alert-group-ui` | Frontend components |
| #95 | `test/alert-group-unit` | Unit test suite |
| #96 | `test/alert-group-load` | Load testing |
| #97 | `docs/alert-grouping` | Documentation |
| #98 | `chore/feature-flag-rollout` | Feature flag setup |
| #99 | `feat/alert-dispatcher-update` | Dispatcher integration |

## 2 ▸ Dependencies
| Component | Version | Notes |
|-----------|---------|-------|
| Python | 3.11 | Base runtime |
| SQLAlchemy | ≥2.0 | ORM for models |
| React | v18 + shadcn | UI components |
| Alembic | latest | DB migrations |
| Locust | 2.26 | Load testing |

## 3 ▸ Acceptance Tests
```bash
# Unit tests
inv venv.clean && inv test.unit --k alert_group

# API tests
curl -H "X-Feature-Flag: on" http://localhost:9000/api/v1/alerts/grouped

# Integration tests
inv db.upgrade head && pytest tests/backend/alert_group/

# Load tests
locust -f load/alert_group.py --headless -u 50 -r 10 -t 2m
```

## 4 ▸ Required Files
```
backend/alfred/alerts/grouping.py
backend/alfred/alerts/models/alert_group.py
migrations/versions/20250520_add_alert_group_table.py
api/routes/alerts.py
frontend/src/components/GroupedAlerts.tsx
docs/dev/alert-grouping.md
```

## 5 ▸ CI Requirements
- All GitHub Actions green
- CodeQL security scan passes
- Coverage ≥85% for `alfred.alerts.*`
- Type checking passes (mypy)

## 6 ▸ Acceptance Gates
- [ ] PR #100 merged with completed checklist
- [ ] `/alerts/grouped` returns valid JSON
- [ ] UI shows accordion groups
- [ ] Feature flag `ALERT_GROUPING_ENABLED` working
- [ ] P95 latency < 150ms at 50 RPS
- [ ] Docs updated and announcement sent

---
*Sprint 1: Alert Grouping MVP behind feature flag*
