#!/bin/bash
# Script to apply the standardized health check template to a service

set -e

# Check if a service name was provided
if [ -z "$1" ]; then
    echo "Usage: $0 <service-name>"
    echo "Example: $0 model-registry"
    exit 1
fi

SERVICE_NAME=$1
SERVICE_DIR="services/$SERVICE_NAME"

# Check if the service directory exists
if [ ! -d "$SERVICE_DIR" ]; then
    echo "Error: Service directory '$SERVICE_DIR' does not exist."
    exit 1
fi

# Backup current Dockerfile
TIMESTAMP=$(date "+%Y%m%d-%H%M%S")
if [ -f "$SERVICE_DIR/Dockerfile" ]; then
    echo "Backing up current Dockerfile to $SERVICE_DIR/Dockerfile.bak-$TIMESTAMP"
    cp "$SERVICE_DIR/Dockerfile" "$SERVICE_DIR/Dockerfile.bak-$TIMESTAMP"
fi

# Determine the service port
SERVICE_PORT=$(grep -E "EXPOSE\s+[0-9]+" "$SERVICE_DIR/Dockerfile" | head -1 | grep -o "[0-9]\+")
if [ -z "$SERVICE_PORT" ]; then
    # Try to find port from environment variables
    SERVICE_PORT=$(grep -E "ENV\s+PORT\s*=\s*[0-9]+" "$SERVICE_DIR/Dockerfile" | head -1 | grep -o "[0-9]\+")
fi

if [ -z "$SERVICE_PORT" ]; then
    echo "Warning: Could not determine service port. Defaulting to 8080."
    SERVICE_PORT=8080
fi

echo "Detected service port: $SERVICE_PORT"

# Create the new standardized Dockerfile
echo "Creating standardized Dockerfile..."
cat > "$SERVICE_DIR/Dockerfile.new" << EOF
# First stage: Get the healthcheck binary
FROM gcr.io/distroless/static-debian12:nonroot AS healthcheck
WORKDIR /app
COPY --from=ghcr.io/alfred-health/healthcheck:latest /usr/local/bin/healthcheck /usr/local/bin/healthcheck

# Main application stage
EOF

# Determine base image from current Dockerfile
BASE_IMAGE=$(grep -E "^FROM\s+" "$SERVICE_DIR/Dockerfile" | head -1 | sed -e 's/FROM\s\+//g')
echo "Using base image: $BASE_IMAGE"

# Append the base image and remaining Dockerfile content
echo "FROM $BASE_IMAGE AS app" >> "$SERVICE_DIR/Dockerfile.new"

# Extract any existing RUN commands for dependencies
grep -E "^RUN\s+" "$SERVICE_DIR/Dockerfile" | sed 's/^/\n/' >> "$SERVICE_DIR/Dockerfile.new"

# Add the healthcheck binary and configuration
cat >> "$SERVICE_DIR/Dockerfile.new" << EOF

# Install healthcheck binary from first stage
COPY --from=healthcheck /usr/local/bin/healthcheck /usr/local/bin/healthcheck

# Set up health check environment variables
ENV HEALTH_CHECK_PORT=$SERVICE_PORT
ENV HEALTH_CHECK_PATH=/health
ENV HEALTH_CHECK_INTERVAL=30s
ENV METRICS_EXPORTER_PORT=9091

# Set healthcheck command with standard parameters
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \\
    CMD ["/usr/local/bin/healthcheck", \\
         "--export-prom", ":\${METRICS_EXPORTER_PORT}", \\
         "--interval", "\${HEALTH_CHECK_INTERVAL}", \\
         "--port", "\${HEALTH_CHECK_PORT}", \\
         "--path", "\${HEALTH_CHECK_PATH}"]
EOF

# Extract COPY commands for application code
grep -E "^COPY\s+" "$SERVICE_DIR/Dockerfile" | sed 's/^/\n/' >> "$SERVICE_DIR/Dockerfile.new"

# Create the entrypoint script
echo "Creating standardized entrypoint script..."
cat > "$SERVICE_DIR/entrypoint.sh" << EOF
#!/bin/bash
# Standardized entrypoint script with health check integration for $SERVICE_NAME service

set -e

# Start healthcheck in background with standard configuration
: "\${HEALTH_CHECK_PORT:=$SERVICE_PORT}"
: "\${HEALTH_CHECK_PATH:=/health}"
: "\${HEALTH_CHECK_INTERVAL:=30s}"
: "\${METRICS_EXPORTER_PORT:=9091}"

# Start the healthcheck binary in the background
/usr/local/bin/healthcheck \\
    --export-prom ":\${METRICS_EXPORTER_PORT}" \\
    --interval "\${HEALTH_CHECK_INTERVAL}" \\
    --port "\${HEALTH_CHECK_PORT}" \\
    --path "\${HEALTH_CHECK_PATH}" &

# Store the healthcheck process ID
HEALTHCHECK_PID=\$!

# $SERVICE_NAME specific initialization
# Add any service-specific initialization here

# Handle cleanup when container is stopped
cleanup() {
    echo "Stopping $SERVICE_NAME service and healthcheck..."

    # Kill any running service processes if needed

    # Kill the healthcheck process
    if [ -n "\${HEALTHCHECK_PID}" ] && kill -0 \${HEALTHCHECK_PID} 2>/dev/null; then
        kill -TERM \${HEALTHCHECK_PID}
        wait \${HEALTHCHECK_PID}
    fi

    exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Start the service using the CMD provided in the Dockerfile
exec "\$@"
EOF

chmod +x "$SERVICE_DIR/entrypoint.sh"

# Add entrypoint configuration to Dockerfile
cat >> "$SERVICE_DIR/Dockerfile.new" << EOF

# Copy and prepare the entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

EOF

# Extract any existing environment settings or EXPOSE commands
grep -E "^ENV\s+" "$SERVICE_DIR/Dockerfile" | sed 's/^/\n/' >> "$SERVICE_DIR/Dockerfile.new"
grep -E "^EXPOSE\s+" "$SERVICE_DIR/Dockerfile" | sed 's/^/\n/' >> "$SERVICE_DIR/Dockerfile.new"

# Extract ENTRYPOINT and CMD from existing Dockerfile
ENTRYPOINT=$(grep -E "^ENTRYPOINT\s+" "$SERVICE_DIR/Dockerfile" | head -1 | sed 's/^ENTRYPOINT\s\+//g')
CMD=$(grep -E "^CMD\s+" "$SERVICE_DIR/Dockerfile" | head -1 | sed 's/^CMD\s\+//g')

# Set entrypoint to use our script
echo -e "\n# Use the entrypoint script to run the application" >> "$SERVICE_DIR/Dockerfile.new"
echo "ENTRYPOINT [\"/app/entrypoint.sh\"]" >> "$SERVICE_DIR/Dockerfile.new"

# Add the original CMD if it exists
if [ ! -z "$CMD" ]; then
    echo "CMD $CMD" >> "$SERVICE_DIR/Dockerfile.new"
fi

echo "Standardized template applied to $SERVICE_NAME."
echo "New Dockerfile saved as $SERVICE_DIR/Dockerfile.new"
echo "Entrypoint script created at $SERVICE_DIR/entrypoint.sh"
echo ""
echo "To apply these changes, review them and then run:"
echo "  cp $SERVICE_DIR/Dockerfile.new $SERVICE_DIR/Dockerfile"
echo ""
echo "Remember to update any service-specific initialization in the entrypoint script."
