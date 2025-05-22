#!/bin/bash
# Pre-commit hook to verify no system packages in dist-packages
# ADR-010: Ensure dev container hardening

set -euo pipefail

echo "Checking for system packages in dist-packages..."

# Check if running inside container
if [ -f /.dockerenv ] || [ -n "${DOCKER_CONTAINER:-}" ]; then
    # Inside container - check for contamination
    if [ -n "$(find /usr/lib/python*/dist-packages -type f 2>/dev/null)" ]; then
        echo "ERROR: System packages found in dist-packages!"
        echo "This violates ADR-010 container hardening requirements."
        echo "Please rebuild the container with the multi-stage Dockerfile."
        find /usr/lib/python*/dist-packages -type f | head -10
        exit 1
    fi
    echo "✓ No system packages found in dist-packages"
else
    # Outside container - skip check
    echo "✓ Not in container, skipping dist-packages check"
fi

exit 0
