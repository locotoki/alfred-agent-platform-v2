#!/usr/bin/env bash
# Bulk updates Dockerfiles to use the latest healthcheck binary (v0.4.0)
# and ensures they expose the metrics endpoint on port 9091

set -euo pipefail

echo "Starting bulk update of healthcheck binary to v0.4.0..."

# Find all Dockerfiles using legacy healthcheck version
LEGACY_DOCKERFILES=$(./scripts/audit-health-binary.sh)

# Count of Dockerfiles to update
DOCKERFILE_COUNT=$(echo "$LEGACY_DOCKERFILES" | wc -l)
echo "Found $DOCKERFILE_COUNT Dockerfiles to update"

# Update each Dockerfile
for DOCKERFILE in $LEGACY_DOCKERFILES; do
  echo "Updating $DOCKERFILE..."
  
  # Upgrade healthcheck version to 0.4.0
  sed -i 's/healthcheck:0\.[0-3]\.[0-9]\+/healthcheck:0.4.0/' "$DOCKERFILE"
  
  # Ensure EXPOSE 9091 is present for metrics
  if ! grep -q 'EXPOSE 9091' "$DOCKERFILE"; then
    # Find the last EXPOSE line and add our metrics port after it
    if grep -q 'EXPOSE' "$DOCKERFILE"; then
      sed -i '/EXPOSE [0-9]/a EXPOSE 9091 # Metrics port' "$DOCKERFILE"
    else
      # If no EXPOSE lines exist, add it before the CMD or ENTRYPOINT
      if grep -q 'CMD\|ENTRYPOINT' "$DOCKERFILE"; then
        sed -i '/CMD\|ENTRYPOINT/i EXPOSE 9091 # Metrics port' "$DOCKERFILE"
      else
        # Append to the end of the file as a last resort
        echo 'EXPOSE 9091 # Metrics port' >> "$DOCKERFILE"
      fi
    fi
  fi
  
  # Update healthcheck command to export Prometheus metrics if needed
  if grep -q 'CMD \["healthcheck"' "$DOCKERFILE" && ! grep -q 'healthcheck.*export-prom' "$DOCKERFILE"; then
    sed -i 's|CMD \["healthcheck"\(.*\)]|CMD ["healthcheck", "--export-prom", ":9091"\1]|' "$DOCKERFILE"
  elif grep -q 'ENTRYPOINT \["healthcheck"' "$DOCKERFILE" && ! grep -q 'healthcheck.*export-prom' "$DOCKERFILE"; then
    sed -i 's|ENTRYPOINT \["healthcheck"\(.*\)]|ENTRYPOINT ["healthcheck", "--export-prom", ":9091"\1]|' "$DOCKERFILE"
  fi
  
  echo "✅ Updated $DOCKERFILE"
done

echo "Healthcheck binary update complete. Dockerfiles updated: $DOCKERFILE_COUNT"
echo "Don't forget to update Prometheus configuration to scrape the new metrics endpoints!"