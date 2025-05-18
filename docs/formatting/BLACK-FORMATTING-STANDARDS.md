# Black Formatting Standards

This document outlines the Black formatting standards used in the Alfred Agent Platform v2 codebase.

## Configuration

We use Black with the following configuration parameters:

- **Black Version:** 24.1.1
- **Line Length:** 100 characters (as specified in `pyproject.toml`)
- **Target Python Version:** 3.11

## Automation

Black formatting is enforced in the following ways:

1. **CI Check:** The `.github/workflows/black-check.yml` workflow verifies that all Python files conform to Black formatting standards in PRs and pushes to specific branches.

2. **Automated Formatting:** The `.github/workflows/apply-black.yml` workflow can be manually triggered to apply Black formatting to a branch, or runs automatically weekly.

3. **Pre-commit Hook:** We use Black as a pre-commit hook for local development. This is already configured in `.pre-commit-config.yaml`:

```yaml
repos:
- repo: https://github.com/psf/black
  rev: 24.1.1
  hooks:
    - id: black
      language_version: python3.11
      exclude: "(youtube-test-env/|migrations/|node_modules/|\.git/|\.mypy_cache/|\.env/|\.venv/|env/|venv/|\.ipynb/)"
```

4. **Script for Manual Formatting:** The `scripts/apply-black-formatting.sh` script can be used to apply Black formatting manually:

```bash
# Install hooks and pre-commit
./scripts/install-hooks.sh

# Format code without committing changes
./scripts/apply-black-formatting.sh

# Format code and commit changes
./scripts/apply-black-formatting.sh --commit

# Format code on a new branch and commit changes
./scripts/apply-black-formatting.sh --branch style/fix-formatting --commit
```

## Benefits

Black provides several benefits to our development workflow:

- **Consistency:** Uniform code formatting across the codebase
- **Focus on Content:** Less time spent on formatting decisions, more on code logic
- **Readability:** Predictable code structure improves readability
- **Reduced Conflicts:** Fewer merge conflicts due to formatting differences

## Exclusions

The following directories are excluded from Black formatting:

- `youtube-test-env/`
- `migrations/`
- `node_modules/`
- `.git/`
- `.mypy_cache/`
- `.env/`
- `.venv/`
- `env/`
- `venv/`
- `.ipynb/`

## Integration with Other Tools

Black is compatible with the following tools we use:

- **isort:** For import sorting (using the Black profile)
- **flake8:** For linting (with appropriate configuration to avoid conflicts)
- **mypy:** For type checking

## How to Run Black Locally

You can run Black locally with the following command:

```bash
# Install Black
pip install black==24.1.1

# Run Black on the entire codebase
black .

# Run Black on a specific file or directory
black path/to/file_or_directory

# Check without formatting
black --check .
```

## Troubleshooting

If you encounter issues with Black formatting:

1. Ensure you have the correct version installed (24.1.1)
2. Verify your `pyproject.toml` has the correct configuration
3. Try running with the `--verbose` flag for more information
4. For files that need to be excluded, add them to the exclude pattern in the relevant workflow or script
