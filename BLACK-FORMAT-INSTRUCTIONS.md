# Black Formatting Instructions

This document provides instructions for formatting the entire codebase with Black before enforcing strict code style checks in CI.

## Background

Our CI Pipeline's validate job runs `black --check`, but it's currently non-blocking. To enforce code style in Phase 3, we need to:

1. Format all existing code with Black
2. Re-enable strict Black checking in CI
3. Make the validate job a required status check

## Step-by-Step Instructions

Follow these steps to format the entire codebase with Black:

### 1. Run one of the formatting scripts

Choose one of the following methods depending on your environment:

#### Option A: Using local Python (if available)

```bash
./scripts/run-black-format.sh
```

#### Option B: Using Docker (recommended)

```bash
./scripts/docker-black-format.sh
```

### 2. Commit the changes

After running the formatter, commit all the changes:

```bash
git add -u
git commit -m "style: apply Black formatting across codebase"
```

### 3. Push and create a PR

```bash
git push -u origin chore/black-format-all
```

Then create a PR with the description: "No code changes, formatter only."

### 4. Merge the PR

Once approved, squash-merge the PR to keep history clean.

### 5. Re-enable strict Black checking

After merging, edit `.github/workflows/metrics-ci-pipeline.yml` to remove the conditional skip for Black checks. Push this change directly to main.

### 6. Update branch protection rule

Add the validate job as a required check in the branch protection rule.

## Minimizing Merge Conflicts

- Land the Black commit while the Phase-2 alerts PR is still under review
- Announce in Slack before merging: "Mass-formatting commit landing—please rebase & run black . on your branches."
- Reviewers can use GitHub's "Hide whitespace changes" to verify no functional code changed