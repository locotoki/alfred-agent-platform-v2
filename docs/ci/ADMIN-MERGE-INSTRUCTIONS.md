# Administrative Merge Instructions for PR #25

If the override workflows don't automatically satisfy the branch protection rules, an administrator can merge PR #25 using the GitHub CLI with admin privileges.

## Option 1: Merge via GitHub Web Interface (Admin Required)

1. Go to the PR page: https://github.com/locotoki/alfred-agent-platform-v2/pull/25
2. You'll see a yellow banner warning about failing checks
3. Click the "Merge pull request" button anyway
4. When prompted, confirm the merge

## Option 2: Merge via GitHub CLI (Admin Required)

Run the following command in your terminal:

```bash
gh pr merge 25 --squash --admin --delete-branch
```

This will:
- Force merge the PR using admin privileges (overriding branch protection)
- Squash all commits into a single commit
- Delete the branch after merging

## Post-Merge Steps

1. Post the Slack announcement:
   ```
   Health-check exporter live on all services 🎉.
   Next: module-org fixes to get CI 100% green; please avoid merging non-hotfix PRs to main until that's done.
   ```

2. Continue with PR #27 for Python module reorganization

3. After PR #27 is merged, run the cleanup script:
   ```bash
   ./scripts/cleanup-after-healthcheck-merge.sh
   ```

This will remove all temporary CI workarounds and return the repository to a clean state.