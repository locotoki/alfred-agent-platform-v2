# Additional GitHub Token Permissions

The `createPullRequest` error might be resolved by adding these permissions:

## Potentially Helpful Permissions

1. **`public_repo`** - Access public repositories
   - Sometimes needed even for private repos with certain API operations

2. **`read:org`** - Read org and team membership
   - Can be required for repositories in organizations

3. **`admin:repo_hook`** - Full control of repository hooks
   - Sometimes needed for PR creation workflows

4. **`admin:org`** - Full control of orgs and teams
   - Only if your repo is in an organization

## Most Likely Solution

The issue is probably one of these:

1. **Token hasn't refreshed in environment**
   - The old token is still cached
   - Solution: Close terminal, open new one, export new token

2. **Repository settings**
   - Check if PR creation is restricted in repo settings
   - Settings → General → Pull Requests → Check permissions

3. **Branch protection rules**
   - Check if feat/phase8.4-sprint5 has special protection
   - Settings → Branches → Check protection rules

## Debug Steps

```bash
# 1. Verify the new token is being used
echo $GITHUB_TOKEN | head -c 30

# 2. Test basic repo access
gh repo view locotoki/alfred-agent-platform-v2

# 3. Try creating a draft PR (less permissions needed)
gh pr create --draft --title "Test" --body "Test"

# 4. Check available scopes on current token
gh api /user -H "Authorization: token $GITHUB_TOKEN" | jq .scopes
```

## Complete Token Refresh

```bash
# 1. Clear all GitHub CLI auth
unset GITHUB_TOKEN
gh auth logout

# 2. Login fresh with new token
gh auth login
# Choose: GitHub.com → HTTPS → Paste your new token

# 3. Verify permissions
gh auth status
```

## Alternative: Use Different Auth Method

Instead of PAT, try GitHub CLI's OAuth flow:
```bash
gh auth login --web
```

This often has broader permissions than PATs.
