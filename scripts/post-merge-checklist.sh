#!/bin/bash
# Post-merge checklist for Phase 1 metrics exporter implementation

set -e

VERSION="v0.2.0-phase1"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

echo "========================================================="
echo "  Post-Merge Checklist for $VERSION"
echo "  $(date)"
echo "========================================================="
echo ""

echo "1. Verify the merge was successful"
echo "   - Main branch has the metrics exporter changes: [   ]"
echo "   - Tag $VERSION exists: [   ]"
echo ""

echo "2. Build and push baseline images"
echo "   Command: make phase0"
echo "   - All services built successfully: [   ]"
echo "   - All images tagged with $VERSION: [   ]"
echo "   - All images pushed to registry: [   ]"
echo ""

echo "3. Create dashboard backup"
echo "   Command: ./scripts/backup-dashboards.sh"
echo "   - Dashboard backup created: [   ]"
echo "   - Dashboard backup committed to repository: [   ]"
echo ""

echo "4. Close Phase 1 issue"
echo "   Command: ./scripts/close-phase1-issue.sh"
echo "   - Issue closed with appropriate comment: [   ]"
echo "   - Card moved to Released column on project board: [   ]"
echo ""

echo "5. Validate in staging environment"
echo "   - Metrics endpoints accessible on all services: [   ]"
echo "   - Prometheus scraping service_health metrics: [   ]"
echo "   - Grafana dashboard shows service_health metrics: [   ]"
echo ""

echo "6. Update documentation"
echo "   - Release notes updated on internal wiki: [   ]"
echo "   - Team notified about the new release: [   ]"
echo ""

echo "========================================================="
echo "  Checklist completed by: ____________________"
echo "  Date: ____________________"
echo "========================================================="