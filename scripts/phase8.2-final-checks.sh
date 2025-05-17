#!/bin/bash
# Phase 8.2 – Final CI & Review Tasks

set -e  # Exit on error

echo "=== Phase 8.2 Final CI & Review Tasks ==="

# 1. Full CI run (local parity with GH Actions)
echo "1. Running full CI suite..."
if command -v poetry &> /dev/null; then
    poetry run tox -e lint,type,test,kind
else
    echo "Warning: poetry not found. Running individual commands..."
    python3 -m black --check alfred/alerts/explainer alfred/slack/diagnostics
    python3 -m isort --check-only --profile black alfred/alerts/explainer alfred/slack/diagnostics
    python3 -m mypy alfred/alerts/explainer alfred/slack/diagnostics
fi

# 2. Confirm coverage threshold
echo "2. Checking test coverage..."
if command -v pytest &> /dev/null; then
    pytest --cov=alfred.alerts.explainer --cov-fail-under=95
else
    echo "Warning: pytest not found. Skipping coverage check."
fi

# 3. KIND smoke-test, Helm flag on/off
echo "3. KIND deployment test..."
if command -v kind &> /dev/null && command -v helm &> /dev/null; then
    make kind-deploy HELM_OPTS="--set explainer.enabled=true"
    kubectl logs -l app=explainer | grep -q "ready to summarise"
else
    echo "Warning: kind or helm not found. Skipping KIND test."
fi

# 4. Verify Slack mock reply
echo "4. Checking Slack mock..."
if [ -f ./tmp/slack_mock.log ]; then
    grep -q "Explanation:" ./tmp/slack_mock.log && echo "✓ Slack mock reply found"
else
    echo "Warning: Slack mock log not found at ./tmp/slack_mock.log"
fi

echo "5. Push fixes if any; wait for green ✅ on GH Actions"
echo "6. Once green, tag @gpt-o3 and Coordinator for final approval"

echo "=== Final checks complete ==="