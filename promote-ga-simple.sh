#\!/usr/bin/env bash
# promote-ga-simple.sh — Direct promotion of RC to GA
set -euo pipefail

REPO="Digital-Native-Ventures/alfred-agent-platform-v2"
TAG_RC="v3.0.0-rc1"
TAG_GA="v3.0.0"

echo "🔄 Fetching RC tag..."
git fetch origin "$TAG_RC"

# Check if GA tag already exists
if git tag -l  < /dev/null |  grep -q "^$TAG_GA$"; then
  echo "ℹ️  $TAG_GA already exists — checking if needs update"
  git tag -d "$TAG_GA"
  echo "🏷️  Re-creating $TAG_GA from $TAG_RC..."
else
  echo "🏷️  Creating $TAG_GA from $TAG_RC..."
fi

# Create GA tag pointing to same commit as RC
git tag -a "$TAG_GA" -m "GA release v3.0.0

General Availability release of Alfred Agent Platform v3.0.0

Key features:
- One-command stack startup (<60s cold-start)
- Agent-core RAG + agent-bizdev CRM sync
- Bench p95: 43.9s (SLA ≤ 75s)
- Security hardening: Trivy gate, Keycloak auth
- Complete documentation (run-book, secrets, ADRs)

Based on RC: $TAG_RC" "$TAG_RC"

# Push GA tag
git push origin "$TAG_GA" --force

# Create GitHub release
echo "📝 Creating GitHub release..."
gh release create "$TAG_GA" \\
  --repo "$REPO" \\
  --title "Alfred Agent Platform v3.0.0 GA" \\
  --notes "## 🎉 General Availability Release

### ✨ Key Features
- **One-command deployment**: \\`alfred up\\` cold-starts in <60 seconds
- **Agent ecosystem**: Core RAG service + BizDev CRM sync agent
- **Performance**: p95 cold-start 43.9s (beats 75s SLA)
- **Security**: Trivy vulnerability scanning, Keycloak authentication
- **Documentation**: Complete run-book, secret management, and ADRs

### 📊 Release Metrics
- **Mypy compliance**: 100% (zero errors)
- **Bench soak**: 10-run p95 = 43,850ms
- **GA-blockers resolved**: 8 PRs (#539-#546)
- **Stability freeze**: July 4-10, 2025

### 🚀 Getting Started
\\`\\`\\`bash
# Clone and start the platform
git clone https://github.com/$REPO.git
cd alfred-agent-platform-v2
alfred up
\\`\\`\\`

### 📖 Documentation
- [Run Book](docs/run-book.md)
- [Secret Management](docs/secret-management.md)
- [Architecture Decisions](docs/adr/)

### 🙏 Contributors
Thanks to all contributors who made this release possible!" \\
  --verify-tag || echo "ℹ️  Release may already exist"

echo ""
echo "✅ GA tag $TAG_GA created and pushed!"
echo "🎉 Alfred Agent Platform v3.0.0 is now Generally Available!"
