#!/bin/bash

echo "Loading token from .env.dev..."
source /home/locotoki/projects/alfred-agent-platform-v2/.env.dev

echo "Using token: $(echo $GITHUB_TOKEN | head -c 30)..."

cd /home/locotoki/projects/alfred-agent-platform-v2

echo "Creating PR..."
GITHUB_TOKEN=$GITHUB_TOKEN gh pr create \
  --title "feat: ML weekly retrain scheduler" \
  --body "## Summary
Implements ML model retraining scheduler using cron and Ray Tune for issue #155.

## Details
- Added backend/alfred/ml/retrain_scheduler.py with cron-based scheduling
- Integrated Ray Tune for hyperparameter optimization
- Added comprehensive test coverage (92%+ target)
- Uses APScheduler for cron functionality

## Testing
- Created tests/backend/ml/test_scheduler.py
- Mock-based testing for Ray Tune integration

Fixes #155" \
  --base feat/phase8.4-sprint5
