#!/bin/bash
# This script handles deployment to both staging and production environments
# Usage: ./deploy.sh [staging]

set -e

# Determine environment from arguments
ENVIRONMENT=${1:-prod}
echo "Deploying to $ENVIRONMENT environment"

# Configure Helm based on environment
if [[ "$ENVIRONMENT" == "staging" ]]; then
    RELEASE_NAME="crewai-staging"
    NAMESPACE="staging"
    VALUES_FILE="./charts/crewai/values-staging.yaml"
    
    # Default values for staging if not present in environment
    CREWAI_ENDPOINT=${CREWAI_ENDPOINT:-"https://crewai.staging.internal"}
else
    RELEASE_NAME="crewai"
    NAMESPACE="production"
    VALUES_FILE="./charts/crewai/values.yaml"
    
    # Ensure production required variables are set
    if [[ -z "$CREWAI_ENDPOINT" ]]; then
        echo "Error: CREWAI_ENDPOINT must be set for production deployment"
        exit 1
    fi
    
    if [[ -z "$CREWAI_A2A_TOKEN_PATH" ]]; then
        echo "Error: CREWAI_A2A_TOKEN_PATH must be set for production deployment"
        exit 1
    fi
    
    # Read token from file
    if [[ -f "$CREWAI_A2A_TOKEN_PATH" ]]; then
        CREWAI_A2A_TOKEN=$(cat "$CREWAI_A2A_TOKEN_PATH")
        echo "Successfully read A2A token from $CREWAI_A2A_TOKEN_PATH"
    else
        echo "Error: Token file not found at $CREWAI_A2A_TOKEN_PATH"
        exit 1
    fi
fi

# Create namespace if doesn't exist
kubectl get namespace "$NAMESPACE" 2>/dev/null || kubectl create namespace "$NAMESPACE"

# Deploy using Helm
echo "Deploying CrewAI to $NAMESPACE namespace as $RELEASE_NAME"

# Set appropriate values based on environment
if [[ "$ENVIRONMENT" == "staging" ]]; then
    # Deploy staging
    helm upgrade --install "$RELEASE_NAME" ./charts/crewai \
        --namespace "$NAMESPACE" \
        --set crewai.endpoint="$CREWAI_ENDPOINT" \
        --set image.tag="latest" \
        --values "$VALUES_FILE" \
        --wait --timeout 5m
else
    # Deploy production with token
    helm upgrade --install "$RELEASE_NAME" ./charts/crewai \
        --namespace "$NAMESPACE" \
        --set crewai.endpoint="$CREWAI_ENDPOINT" \
        --set crewai.auth.token="$CREWAI_A2A_TOKEN" \
        --set crewai.auth.audience="$CREWAI_ENDPOINT" \
        --set image.tag="${GITHUB_REF#refs/tags/}" \
        --values "$VALUES_FILE" \
        --wait --timeout 5m
fi

echo "Deployment completed successfully"

# Verify the deployment
kubectl get pods -n "$NAMESPACE" -l "app.kubernetes.io/name=crewai"

# If in production, run a quick health check
if [[ "$ENVIRONMENT" == "prod" ]]; then
    echo "Running health check on production deployment..."
    kubectl exec -n "$NAMESPACE" -l "app.kubernetes.io/name=crewai" -c crewai -- wget -q -O- http://localhost:8080/health || echo "Health check failed!"
    echo "Deployment verification completed"
fi