### API Gateway CI Job
*Labels:* size/S · type/ci · codex
*Linked ADR:* ADR-001

#### Acceptance Criteria
- [ ] Add GitHub Action workflow `.github/workflows/ci-adapters.yml`
- [ ] Job installs poetry deps with `--only main,test`
- [ ] Run `pytest -m adapters` and fail on coverage < 85 %
- [ ] Upload coverage XML to Codecov (`codecov/codecov-action@v4`)
- [ ] Cache Poetry + pip to speed subsequent runs
