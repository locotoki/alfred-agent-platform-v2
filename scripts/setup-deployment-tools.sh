#!/usr/bin/env bash
set -e

echo "=== Alfred Agent Platform - Deployment Tools Setup ==="
echo ""
echo "This script requires sudo access. Please run it manually:"
echo "  bash scripts/setup-deployment-tools.sh"
echo ""

# Install system dependencies
echo "1. Installing system dependencies..."
sudo apt-get update
sudo apt-get install -y unzip curl wget

# Install AWS CLI v2
echo ""
echo "2. Installing AWS CLI v2..."
if ! command -v aws &> /dev/null; then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf awscliv2.zip aws/
else
    echo "AWS CLI already installed: $(aws --version)"
fi

# Install kubectl
echo ""
echo "3. Installing kubectl..."
if ! command -v kubectl &> /dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
else
    echo "kubectl already installed: $(kubectl version --client --short)"
fi

# Install Helm v3
echo ""
echo "4. Installing Helm v3..."
if ! command -v helm &> /dev/null; then
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "Helm already installed: $(helm version --short)"
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "1. Configure AWS credentials:"
echo "   aws configure"
echo ""
echo "2. Configure kubectl for EKS:"
echo "   aws eks update-kubeconfig --region eu-west-1 --name alfred-staging-cluster"
echo ""
echo "3. Verify configuration:"
echo "   kubectl get nodes"
echo ""
echo "4. Run deployment:"
echo "   source .env.local"
echo "   ./scripts/deploy-slack-mcp-staging.sh --image ghcr.io/locotoki/alfred-agent-platform-v2/slack_mcp_gateway:17482304b0fb9a802bf6a58ae89ea2751afc0b7e"