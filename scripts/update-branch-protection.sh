#!/bin/bash
# update-branch-protection.sh - Instructions for updating branch protection rules

echo "=========================================================="
echo "   Branch Protection Update Instructions"
echo "=========================================================="
echo
echo "To update branch protection rules to include the new required status checks,"
echo "please follow these manual steps:"
echo
echo "1. Go to: https://github.com/locotoki/alfred-agent-platform-v2/settings/branches"
echo
echo "2. Click on 'Edit' next to the 'main' branch protection rule"
echo
echo "3. Under 'Require status checks to pass before merging', make sure"
echo "   the following checks are selected:"
echo "   - test"
echo "   - lint"
echo "   - build"
echo "   - slack-smoke"
echo "   - orchestration-integration"
echo
echo "4. Make sure 'Require branches to be up to date before merging' is checked"
echo
echo "5. Click 'Save changes' at the bottom of the page"
echo
echo "These steps will ensure that all PRs require the new CI checks to pass"
echo "before they can be merged to main."
echo "=========================================================="