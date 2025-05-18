# GitHub CLI Setup for Claude

## Required GitHub Personal Access Token (PAT) Permissions

To enable full GitHub CLI functionality for automated workflows, ensure your PAT has these scopes:

### Essential Scopes
- `repo` - Full control of private repositories
- `workflow` - Update GitHub Action workflows
- `write:discussion` - Write access to discussions and issue comments
- `read:org` - Read org and team membership
- `project` - Full control of projects

### Creating a Properly Scoped Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Name it: "Claude-CLI-Access"
4. Select scopes:
   ```
   ✓ repo (all sub-scopes)
   ✓ workflow
   ✓ write:packages
   ✓ delete:packages
   ✓ admin:org > write:org
   ✓ admin:org > read:org
   ✓ admin:public_key > read:public_key
   ✓ admin:enterprise > read:enterprise
   ✓ project
   ```
5. Generate token and save securely

### Configuring GitHub CLI

```bash
# Initial setup
gh auth login

# Choose:
# - GitHub.com
# - HTTPS
# - Paste authentication token
# - Enter your PAT

# Verify authentication
gh auth status

# Test permissions
gh pr list
gh issue list
```

### Common Permission Issues and Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| `Resource not accessible by personal access token` | Missing scopes | Regenerate token with required scopes |
| `GraphQL: createPullRequest` | No `repo` scope | Add `repo` scope to token |
| `GraphQL: addComment` | No `write:discussion` | Add discussion write permissions |
| `must have push access` | No write permissions | Ensure `repo` scope includes push access |

### Fallback Strategies

When GitHub CLI operations fail due to permissions:

1. **Use Web Interface URLs**
   ```bash
   # Generate PR creation URL
   echo "https://github.com/USER/REPO/pull/new/BRANCH"
   ```

2. **Create Manual Command Scripts**
   ```bash
   # Save commands for later execution
   cat > manual_pr.sh << 'EOF'
   gh pr create --title "Title" --body "Body" --base main
   gh issue comment 123 --body "Status update"
   EOF
   ```

3. **Document Required Manual Steps**
   - Create detailed markdown files with step-by-step instructions
   - Include screenshots or exact button sequences
   - Save PR templates and issue comment templates

### Environment Variables for CI/CD

```bash
# .env.example
GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxx  # PAT with full permissions
GH_ENTERPRISE_TOKEN=                    # For enterprise GitHub
```

### Best Practices

1. **Separate Tokens by Purpose**
   - Read-only token for queries
   - Write token for modifications
   - Admin token for sensitive operations

2. **Token Rotation**
   - Set expiration dates (90 days recommended)
   - Document rotation schedule
   - Keep backup tokens during transition

3. **Permission Auditing**
   ```bash
   # Check current token permissions
   gh api /user -H "Authorization: token $GITHUB_TOKEN"
   ```

4. **Graceful Degradation**
   - Always provide fallback manual instructions
   - Create helper scripts for common operations
   - Document web UI alternatives

### Integration with CLAUDE.md

Add this section to the main CLAUDE.md:

```markdown
## 🔐 GitHub CLI Configuration

Before executing Sprint tasks, ensure GitHub CLI is properly configured:

1. Run `gh auth status` to verify authentication
2. Check required scopes are present (see docs/CLAUDE_GITHUB_SETUP.md)
3. If operations fail, use fallback strategies:
   - Manual PR creation via web interface
   - Execute saved command scripts
   - Follow documented manual procedures

Required for Sprint workflows:
- Creating pull requests
- Updating issue status
- Managing project boards
- Adding comments and reviews
```

### Automated Permission Check Script

```bash
#!/bin/bash
# check_github_permissions.sh

echo "Checking GitHub CLI permissions..."

# Test PR creation ability
if gh pr list &>/dev/null; then
  echo "✓ Can list PRs"
else
  echo "✗ Cannot list PRs - check repo scope"
fi

# Test issue commenting
if gh issue list &>/dev/null; then
  echo "✓ Can list issues"
else
  echo "✗ Cannot list issues - check repo scope"
fi

# Test API access
if gh api /user &>/dev/null; then
  echo "✓ API access working"
else
  echo "✗ API access failed - check token"
fi

echo ""
echo "Token scopes:"
gh api /user -H "Authorization: token $GITHUB_TOKEN" | jq -r '.scopes'
```
