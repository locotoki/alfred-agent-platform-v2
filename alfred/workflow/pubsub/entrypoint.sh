#!/usr/bin/env bash
set -euo pipefail

exec "$@"

# Start PubSub emulator in the background
PROJECT_ID=${ALFRED_PROJECT_ID:-alfred-agent-platform}
gcloud beta emulators pubsub start --host-port=0.0.0.0:8085 --project=$PROJECT_ID &

# Wait for PubSub emulator to become ready
echo "Waiting for PubSub emulator to start..."
until curl -s "http://localhost:8085/v1/projects/$PROJECT_ID/topics" > /dev/null 2>&1; do
  sleep 2
done
echo "PubSub emulator started successfully"

# Set environment variables for other services
export PUBSUB_EMULATOR_HOST=localhost:8085
export PUBSUB_HOST=localhost:8085

# Start the health check wrapper using the virtual environment
echo "Starting health check wrapper on port 9091"
cd /app && /app/venv/bin/python health_wrapper.py &

# Wait for any process to exit
wait -n

# Exit with status of process that exited first
exit $?
