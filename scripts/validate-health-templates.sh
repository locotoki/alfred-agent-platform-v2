#!/bin/bash
# Script to validate if services conform to the standardized health check template

set -e

FAILED_SERVICES=()
PASSED_SERVICES=()
SKIPPED_SERVICES=()

# Check all services
for SERVICE_DIR in services/*/; do
    SERVICE_NAME=$(basename "$SERVICE_DIR")

    echo "Validating $SERVICE_NAME..."

    # Skip special directories
    if [[ "$SERVICE_NAME" == "_template" ]]; then
        echo "  Skipping template directory"
        SKIPPED_SERVICES+=("$SERVICE_NAME")
        continue
    fi

    # Check if Dockerfile exists
    if [ ! -f "$SERVICE_DIR/Dockerfile" ]; then
        echo "  Dockerfile not found, skipping"
        SKIPPED_SERVICES+=("$SERVICE_NAME")
        continue
    fi

    # Check if it's a multistage build with healthcheck
    if ! grep -q "FROM.*AS healthcheck" "$SERVICE_DIR/Dockerfile"; then
        echo "  FAILED: Missing healthcheck stage in Dockerfile"
        FAILED_SERVICES+=("$SERVICE_NAME")
        continue
    fi

    # Check if it copies healthcheck binary
    if ! grep -q "COPY --from=healthcheck.*healthcheck" "$SERVICE_DIR/Dockerfile"; then
        echo "  FAILED: Missing healthcheck binary copy in Dockerfile"
        FAILED_SERVICES+=("$SERVICE_NAME")
        continue
    fi

    # Check if it sets HEALTHCHECK command
    if ! grep -q "^HEALTHCHECK " "$SERVICE_DIR/Dockerfile"; then
        echo "  FAILED: Missing HEALTHCHECK command in Dockerfile"
        FAILED_SERVICES+=("$SERVICE_NAME")
        continue
    fi

    # Check if it uses the standard entrypoint script
    if ! grep -q "ENTRYPOINT.*entrypoint.sh" "$SERVICE_DIR/Dockerfile"; then
        echo "  FAILED: Not using standard entrypoint script"
        FAILED_SERVICES+=("$SERVICE_NAME")
        continue
    fi

    # Check if entrypoint script exists
    if [ ! -f "$SERVICE_DIR/entrypoint.sh" ]; then
        echo "  FAILED: entrypoint.sh script not found"
        FAILED_SERVICES+=("$SERVICE_NAME")
        continue
    fi

    # Check if entrypoint script starts healthcheck
    if ! grep -q "healthcheck.*--export-prom" "$SERVICE_DIR/entrypoint.sh"; then
        echo "  FAILED: entrypoint.sh does not start healthcheck"
        FAILED_SERVICES+=("$SERVICE_NAME")
        continue
    fi

    # Service passed validation
    echo "  PASSED: Service follows standardized template"
    PASSED_SERVICES+=("$SERVICE_NAME")
done

# Print summary
echo ""
echo "VALIDATION SUMMARY"
echo "================="
echo "Passed: ${#PASSED_SERVICES[@]} services"
for service in "${PASSED_SERVICES[@]}"; do
    echo "  ✓ $service"
done

echo ""
echo "Failed: ${#FAILED_SERVICES[@]} services"
for service in "${FAILED_SERVICES[@]}"; do
    echo "  ✗ $service"
done

echo ""
echo "Skipped: ${#SKIPPED_SERVICES[@]} services"
for service in "${SKIPPED_SERVICES[@]}"; do
    echo "  - $service"
done

# Exit with failure if any services failed validation
if [ ${#FAILED_SERVICES[@]} -gt 0 ]; then
    echo ""
    echo "Some services do not conform to the standardized health check template."
    echo "Run the apply-template-standard.sh script to update them:"
    echo ""
    for service in "${FAILED_SERVICES[@]}"; do
        echo "  ./scripts/apply-template-standard.sh $service"
    done
    exit 1
fi
