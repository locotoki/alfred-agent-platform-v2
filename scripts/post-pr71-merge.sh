#!/bin/bash
set -euo pipefail

echo "Phase 8.1 Post-Merge Tasks"
echo "========================="

# 1. Post-merge hygiene
echo "1. Updating local main branch..."
git fetch origin
git checkout main
git pull

# 2. Bump version
echo "2. Bumping version to 0.8.2..."
./scripts/bump_version.sh 0.8.2

# 3. Update CHANGELOG
echo "3. Updating CHANGELOG.md..."
cat > CHANGELOG_UPDATE.md << EOF
## [0.8.2] - 2025-05-17

### Added
- Strict mypy type checking across all alfred.* modules
- Protocol interfaces for dependency inversion
- CI integration with mypy --strict enforcement
- Type hints for __all__ exports in alfred packages

### Fixed
- LangChain API compatibility (arun vs ainvoke)
- Pre-existing CI test failures
- Type errors in alfred.* namespace modules

### Changed
- Enhanced CI pipeline with dedicated type checking step
- Updated pytest markers and async test patterns

EOF

# Prepend to existing CHANGELOG
if [ -f CHANGELOG.md ]; then
    cat CHANGELOG_UPDATE.md CHANGELOG.md > CHANGELOG_NEW.md
    mv CHANGELOG_NEW.md CHANGELOG.md
    rm CHANGELOG_UPDATE.md
else
    mv CHANGELOG_UPDATE.md CHANGELOG.md
fi

# 4. Commit and tag
echo "4. Committing release..."
git add VERSION charts/alfred/Chart.yaml CHANGELOG.md
git commit -m "chore: release v0.8.2"

echo "5. Creating and pushing tag..."
git tag v0.8.2
git push origin main
git push origin v0.8.2

# 5. Rebase downstream branches
echo "6. Rebasing downstream branches..."
for br in feature/phase-8.1-type-safety-alerts; do
    echo "   Rebasing $br..."
    git checkout $br || continue
    git rebase origin/main
    
    # Run tests if tox is available
    if command -v tox &> /dev/null; then
        tox -e lint,typing,py
    else
        echo "   Warning: tox not found, skipping tests"
    fi
    
    git push --force-with-lease origin $br
done

# 6. Create coordination issue
echo "7. Creating coordination issue..."
gh issue create \
    --title "Phase 8.1 – Track sequencing after typing baseline" \
    --body "## Summary
Phase 8.1 typing baseline merged as v0.8.2

## Next Tasks
- [ ] Implement alert dispatcher
- [ ] Helm alert label enrichment
- [ ] Slack /diag bot implementation

## Related PRs
- #71 - Phase 8.1 typing baseline (merged)
- feature/phase-8.1-alerts (rebased)
- feature/phase-8.1-slack-diagnostics (rebased)

## Assignment
@alfred-platform/observability" \
    --assignee "@me" \
    --label "phase8,coordination"

echo "Post-merge tasks completed!"