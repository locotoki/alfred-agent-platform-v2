# Update GitHub Token in Environment

Your token `Alfred_AI_Infra_v2` now has all required scopes. To use it:

## 1. Get Your Updated Token

1. Go to: https://github.com/settings/tokens
2. Find "Alfred_AI_Infra_v2"
3. Click "Regenerate token" (since you can't view existing token)
4. Copy the new token value

## 2. Update Environment

```bash
# In your terminal
export GITHUB_TOKEN=ghp_YOUR_NEW_TOKEN_HERE

# OR update .bashrc/.zshrc for persistence
echo 'export GITHUB_TOKEN=ghp_YOUR_NEW_TOKEN_HERE' >> ~/.bashrc
source ~/.bashrc
```

## 3. Test Commands

```bash
# Verify token is updated
echo $GITHUB_TOKEN | head -c 20

# Create PR
cd /home/locotoki/projects/alfred-agent-platform-v2
gh pr create --title "feat: ML weekly retrain scheduler" \
  --body "Implements ML model retraining scheduler using cron and Ray Tune for issue #155" \
  --base feat/phase8.4-sprint5

# Comment on issues
gh issue comment 155 --body "🚀 Implementation complete - PR ready for review"
gh issue comment 159 --body "Sprint-5 kickoff meeting scheduled"
```

## 4. Alternative: Manual Creation

If token update is delayed, use:
- PR creation: https://github.com/locotoki/alfred-agent-platform-v2/pull/new/feat/ml-pipeline?base=feat/phase8.4-sprint5
- Issue #155: https://github.com/locotoki/alfred-agent-platform-v2/issues/155
- Issue #159: https://github.com/locotoki/alfred-agent-platform-v2/issues/159

Your token now has:
- ✅ `repo` - Full repository access
- ✅ `workflow` - GitHub Actions
- ✅ `write:discussion` - Issue comments
- ✅ `project` - Project boards
- ✅ `write:packages` - Package registry
