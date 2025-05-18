#!/usr/bin/env bash

echo "=== Deployment Readiness Check ==="

# Check kubectl
echo -n "kubectl: "
if command -v kubectl &> /dev/null; then
    echo "✓ installed"
    echo -n "kubectl context: "
    if kubectl config current-context &> /dev/null; then
        kubectl config current-context
    else
        echo "✗ not configured"
    fi
else
    echo "✗ not installed"
fi

# Check helm
echo -n "helm: "
if command -v helm &> /dev/null; then
    echo "✓ installed ($(helm version --short))"
else
    echo "✗ not installed"
fi

# Check environment variables
echo -n "Environment variables: "
if [ -f .env.local ]; then
    source .env.local
    if [ -n "$SLACK_APP_TOKEN" ] && [ -n "$SLACK_BOT_TOKEN" ]; then
        echo "✓ loaded"
        echo "  SLACK_APP_TOKEN: ${SLACK_APP_TOKEN:0:10}..."
        echo "  SLACK_BOT_TOKEN: ${SLACK_BOT_TOKEN:0:10}..."
    else
        echo "✗ missing values in .env.local"
    fi
else
    echo "✗ .env.local not found"
fi

# Check Docker
echo -n "Docker: "
if command -v docker &> /dev/null; then
    echo "✓ installed"
    echo -n "GHCR access: "
    if docker pull ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:latest &> /dev/null; then
        echo "✓ accessible"
    else
        echo "✗ unable to pull image"
    fi
else
    echo "✗ not installed"
fi

echo ""
echo "=== Summary ==="
echo "To deploy successfully, you need:"
echo "1. kubectl configured with access to your cluster"
echo "2. helm installed"
echo "3. .env.local with SLACK_APP_TOKEN and SLACK_BOT_TOKEN"
echo "4. Access to GHCR images"
