# GitHub Personal Access Token Requirements

## Essential Scopes for Sprint Workflows

To enable full GitHub CLI functionality for creating PRs, commenting on issues, and managing projects, select these scopes:

### ✅ Required Scopes

1. **`repo`** - Full control of private repositories
   - Enables PR creation, branch management, and code access

2. **`workflow`** - Update GitHub Action workflows
   - Allows triggering and monitoring CI/CD pipelines

3. **`write:discussion`** - Read and write team discussions
   - Required for commenting on issues and PRs

4. **`project`** - Full control of projects
   - Enables moving issues across project board columns

### ❌ Currently Missing Scopes

Based on your error messages, you're missing:
- `write:discussion` - This is why issue comments fail
- `project` - This is why project board updates fail

### 🔧 How to Fix

1. Go to your token settings page
2. Check these boxes:
   - [x] `repo` (Full control of private repositories)
   - [x] `workflow` (Update GitHub Action workflows)
   - [x] `write:discussion` (Read and write team discussions)
   - [x] `project` (Full control of projects)

3. Click "Update token" at the bottom
4. Copy the updated token
5. Update your GitHub CLI with the new token:
   ```bash
   gh auth login
   # Choose: GitHub.com > HTTPS > Paste token
   ```

### 🧪 Test Your Permissions

After updating, test with:
```bash
# Test PR creation
gh pr create --title "Test PR" --body "Test" --draft

# Test issue commenting
gh issue comment 1 --body "Test comment"

# Test project access
gh project list

# Clean up test PR
gh pr close --delete-branch
```

### 📋 Complete Sprint Workflow

With proper permissions, you can:
```bash
# Create PR
gh pr create --title "feat: ML scheduler" --body "..." --base feat/phase8.4-sprint5

# Comment on issues
gh issue comment 155 --body "Implementation complete"

# Update project board
gh project item-add 1 --owner locotoki --url https://github.com/locotoki/alfred-agent-platform-v2/issues/155

# Monitor CI
gh run watch

# Merge when ready
gh pr merge <PR#> --merge
```

### 🔐 Security Best Practice

- Set token expiration to 90 days
- Use minimal scopes needed
- Rotate tokens regularly
- Never commit tokens to code

### 🚨 Common Errors and Solutions

| Error | Missing Scope | Solution |
|-------|--------------|----------|
| `GraphQL: Resource not accessible by personal access token (createPullRequest)` | `repo` | Add repo scope |
| `GraphQL: Resource not accessible by personal access token (addComment)` | `write:discussion` | Add discussion write scope |
| `GraphQL: Resource not accessible by personal access token (addProjectNextItem)` | `project` | Add project scope |
| `must have push access` | `repo` | Ensure repo scope is checked |
