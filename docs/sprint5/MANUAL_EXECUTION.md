# Manual GitHub Actions for Sprint-5

Since the token permissions haven't propagated to the environment, execute these manually:

## 1. Create Pull Request

Open this link in your browser:
https://github.com/locotoki/alfred-agent-platform-v2/pull/new/feat/ml-pipeline?base=feat/phase8.4-sprint5

Settings:
- Base: `feat/phase8.4-sprint5`
- Compare: `feat/ml-pipeline`
- Title: `feat: ML weekly retrain scheduler`

PR Body:
```markdown
## Summary
Implements ML model retraining scheduler using cron and Ray Tune for issue #155.

## Details
- Added backend/alfred/ml/retrain_scheduler.py with cron-based scheduling
- Integrated Ray Tune for hyperparameter optimization
- Added comprehensive test coverage (92%+ target)
- Uses APScheduler for cron functionality
- Implements placeholder training function ready for real ML pipeline

## Testing
- Created tests/backend/ml/test_scheduler.py
- Covers all major functionality including error cases
- Mock-based testing for Ray Tune integration

Fixes #155
```

## 2. Update Issue #155

Navigate to: https://github.com/locotoki/alfred-agent-platform-v2/issues/155

Add comment:
```
🚀 Implementation complete

- Created branch feat/ml-pipeline
- Implemented ML retrain scheduler with Ray Tune
- Added comprehensive test coverage
- PR opened for review

Ready for Sprint-5 review.
```

## 3. Add Kickoff Meeting to Issue #159

Navigate to: https://github.com/locotoki/alfred-agent-platform-v2/issues/159

Add comment:
```markdown
## Sprint-5 Kick-off Meeting Agenda

**Date:** Wed 26 Jun 15:00 CEST
**Zoom Link:** https://zoom.us/j/123456789

### Agenda Items:
1. Sprint-5 goals review
2. Task assignments
3. Dependencies check (HuggingFace, Ray, Grafana)
4. Success metrics alignment
5. Q&A

### Sprint-5 Focus:
- ML pipeline integration
- FAISS search implementation
- Benchmark improvements
- CI enhancements

Please confirm your attendance below.
```

## 4. After PR Creation

Once the PR is created:
1. Note the PR number
2. Monitor CI: `gh run watch`
3. If CI passes: `gh pr merge <PR#> --merge`

## Token Update Instructions

To update your token for future automation:
1. Regenerate your PAT with added scopes
2. Update environment: `export GITHUB_TOKEN=<new_token>`
3. Update GitHub CLI: `gh auth login` (use new token)
