# Manual PR Creation Steps

Since the GitHub CLI is using a cached token, follow these manual steps:

## 1. Open PR Creation Page
https://github.com/locotoki/alfred-agent-platform-v2/pull/new/feat/ml-pipeline

## 2. Configure PR Settings
- **Base branch**: `feat/phase8.4-sprint5`
- **Compare branch**: `feat/ml-pipeline`
- **Title**: `feat: ML weekly retrain scheduler`

## 3. PR Body Content
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

## 4. Add Labels
- `feat`
- `phase8.4-s5`

## 5. Submit PR
Click "Create pull request" button

## 6. Note the PR Number
After creation, copy the PR number (e.g., #160)

## 7. After CI Passes
```bash
gh pr merge <PR_NUMBER> --merge
```

## 8. Verify Project Board
```bash
gh project view "Phase 8.4 – Sprint 5"
```

This will:
- Automatically move issue #155 to "Done"
- Trigger any linked automations
- Complete Sprint-5 first feature
