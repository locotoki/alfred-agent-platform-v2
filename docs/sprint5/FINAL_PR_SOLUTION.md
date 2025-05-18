# Final Solution for PR Creation

The issue is that GitHub CLI is using a cached token. Here are three solutions:

## Solution 1: Force New Token in Current Session

```bash
# Clear environment
unset GITHUB_TOKEN

# Load new token
source /home/locotoki/projects/alfred-agent-platform-v2/.env.dev

# Use token directly
GITHUB_TOKEN=$GITHUB_TOKEN gh pr create \
  --title "feat: ML weekly retrain scheduler" \
  --body "Implements ML model retraining scheduler for issue #155" \
  --base feat/phase8.4-sprint5
```

## Solution 2: Use Script with New Token

Run the prepared script:
```bash
/home/locotoki/projects/alfred-agent-platform-v2/create_pr_now.sh
```

## Solution 3: Manual Web Creation

Since all code is pushed, create PR manually:

1. Open: https://github.com/locotoki/alfred-agent-platform-v2/pull/new/feat/ml-pipeline
2. Base: `feat/phase8.4-sprint5`
3. Title: `feat: ML weekly retrain scheduler`
4. Body: Use template from `docs/sprint5/FINAL_MANUAL_STEPS.md`

## Why This Happens

GitHub CLI caches authentication. Even though you updated the token:
- Environment still has old token
- GitHub CLI cached the old auth
- New permissions aren't being used

## Verification

Your token has all needed permissions:
- ✅ repo
- ✅ public_repo
- ✅ workflow
- ✅ write:discussion
- ✅ project
- ✅ write:packages

The issue is purely about making GitHub CLI use the new token.
