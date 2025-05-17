#!/bin/bash
# Deploy diagnostics bot to staging

set -e

echo "🚀 Deploying diagnostics bot to staging..."

# Ensure we're in the right directory
cd "$(dirname "$0")/.."

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install Helm first."
    exit 1
fi

# Check if kubectl is configured for staging
if ! kubectl config current-context | grep -q staging; then
    echo "⚠️  Current context doesn't appear to be staging"
    echo "Current context: $(kubectl config current-context)"
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Build dependencies if needed
echo "📦 Building chart dependencies..."
helm dependency build charts/alfred

# Deploy with diagnostics enabled
echo "🔧 Enabling diagnostics in staging..."
helm upgrade alfred ./charts/alfred \
    --install \
    --namespace staging \
    --set slack.diagnostics.enabled=true \
    --reuse-values \
    --wait

echo "✅ Diagnostics bot deployed!"
echo
echo "🧪 Test the bot in Slack with:"
echo "  /diag health"
echo "  /diag metrics"
echo
echo "📊 Check deployment status:"
kubectl get pods -n staging -l app=alfred-slack

# Verify the deployment
echo
echo "🔍 Checking pod logs..."
kubectl logs -n staging -l app=alfred-slack --tail=20