# Board Sync Automation

Automated GitHub project board synchronization that moves linked issues to "Done" status after successful PR merges.

## Overview

The board sync automation consists of:

1. **Script**: `workflow/cli/board_sync.sh` - Moves GitHub issues to Done column
2. **Workflow**: `.github/workflows/board-sync.yml` - Triggers automatically after CI success
3. **Makefile target**: `make board-sync` - Manual execution interface

## Features

- ✅ **Automatic triggering** after successful CI workflow completion
- ✅ **Manual triggering** via GitHub Actions or Makefile
- ✅ **Robust error handling** with clear error messages
- ✅ **Dry-run mode** for testing without making changes
- ✅ **Smart project detection** - finds the correct project board automatically
- ✅ **Multiple input formats** - supports issue numbers and GitHub URLs
- ✅ **Comprehensive logging** with color-coded output

## Usage

### Automatic (Recommended)

Board sync runs automatically when:
1. CI workflow completes successfully
2. The merged PR contains issue references (e.g., "Closes #174", "Fixes #174")

### Manual Execution

#### Via Makefile
```bash
# Move issue #174 to Done
make board-sync ISSUE_URL=174

# Move issue via URL
make board-sync ISSUE_URL=https://github.com/locotoki/alfred-agent-platform-v2/issues/174
```

#### Via Script Directly
```bash
# Basic usage
./workflow/cli/board_sync.sh 174

# Dry run (test without changes)
./workflow/cli/board_sync.sh 174 --dry-run

# Verbose output
./workflow/cli/board_sync.sh 174 --verbose

# Combined options
./workflow/cli/board_sync.sh 174 --dry-run --verbose
```

#### Via GitHub Actions
1. Go to Actions → Board Sync Automation
2. Click "Run workflow"
3. Enter issue number or URL
4. Click "Run workflow"

## Prerequisites

### For Local/Manual Use
- GitHub CLI (`gh`) installed and authenticated
- GitHub token with `read:project` scope
- Access to the project board

### For Automatic CI Use
- `GH_AUTOMATION_PAT` secret with `read:project` scope
- Or fallback to `GITHUB_TOKEN` (limited functionality)

## Setup Instructions

### 1. GitHub Token Setup
Create a personal access token with these scopes:
- `repo` (already configured)
- `read:project` (new requirement)

#### Option A: Update existing token
```bash
gh auth refresh -s read:project
```

#### Option B: Create new token
1. Go to GitHub Settings → Developer settings → Personal access tokens
2. Create token with `repo` and `read:project` scopes
3. Add as `GH_AUTOMATION_PAT` secret in repository settings

### 2. Test Setup
```bash
# Test with dry run
make board-sync ISSUE_URL=174 DRY_RUN=true

# Or directly
./workflow/cli/board_sync.sh 174 --dry-run --verbose
```

## How It Works

### Automatic Detection Process
1. **Trigger**: CI workflow completes successfully
2. **Issue Detection**: Scans merged PR for issue references
3. **Project Discovery**: Finds appropriate project board
4. **Issue Location**: Locates issue in project board
5. **Status Update**: Moves issue to "Done" column

### Project Board Detection
The script automatically finds projects in this order:
1. "Alfred-core Sprint Board"
2. "Sprint"
3. "Alfred Platform"
4. "Main"
5. First available project (with warning)

### Issue Reference Patterns
The workflow detects these patterns in PR titles/bodies:
- `#123`
- `Closes #123`
- `Fixes #123`
- `Resolves #123`

## Error Handling

### Common Issues

| Error | Cause | Solution |
|-------|-------|----------|
| "Missing project permissions" | Token lacks `read:project` scope | Run `gh auth refresh -s read:project` |
| "Issue not found in project" | Issue not linked to board | Add issue to project board manually |
| "No projects found" | No access to projects | Verify repository permissions |
| "Could not find Done status" | Project uses different status names | Script shows available options |

### Debugging

Enable verbose mode for detailed output:
```bash
./workflow/cli/board_sync.sh 174 --verbose
```

Use dry-run mode to test without changes:
```bash
./workflow/cli/board_sync.sh 174 --dry-run
```

## Configuration

### Environment Variables
- `GITHUB_TOKEN`: GitHub authentication token
- `DRY_RUN`: Set to `true` to enable dry-run mode globally
- `VERBOSE`: Set to `true` to enable verbose output globally

### Script Constants
Edit `workflow/cli/board_sync.sh` to modify:
- Repository owner/name
- Default project search patterns
- Status column names to search for

## Security

- ✅ Uses least-privilege access (read-only project access)
- ✅ Validates all inputs and API responses
- ✅ No secrets exposed in logs
- ✅ Fails safely on permission issues

## Integration with Other Workflows

The board sync automation integrates with:
- **CI Pipeline**: Triggers after successful builds
- **Update Status**: Works alongside progress beacon updates
- **Release Process**: Moves issues as features are deployed

## Troubleshooting

### "Failed to list projects"
```bash
# Check authentication
gh auth status

# Refresh with project scope
gh auth refresh -s read:project

# Test manually
gh project list --owner locotoki
```

### "Issue not found in project"
The issue exists but isn't linked to the project board:
1. Open the project board
2. Add the issue manually
3. Re-run board sync

### "Could not find Done status option"
Project uses different status names:
1. Run with `--verbose` to see available options
2. Update script if needed, or rename status in project

## Future Enhancements

- [ ] Support multiple project boards
- [ ] Configurable status mappings
- [ ] Integration with issue templates
- [ ] Slack notifications for board updates
- [ ] Bulk operations for multiple issues

---

## Related Documentation

- [GitHub CLI Authentication](https://cli.github.com/manual/gh_auth)
- [GitHub Projects API](https://docs.github.com/en/issues/planning-and-tracking-with-projects)
- [GitHub Actions Workflows](../../.github/workflows/README.md)
