#!/bin/bash

# Integration test script for Alfred Agent Orchestrator with Social Intelligence Agent

echo "Starting integration tests for Alfred Agent Orchestrator"
echo "========================================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Docker is not running or not accessible. Please start Docker and try again."
  exit 1
fi

# Check if the network exists, create if not
if ! docker network inspect alfred-network &> /dev/null; then
  echo "Creating Docker network: alfred-network"
  docker network create alfred-network
fi

# Check if Social Intelligence Agent is running
if ! docker ps | grep -q social-intel; then
  echo "Social Intelligence Agent is not running."
  echo "Would you like to start it from the Alfred Agent Platform? (y/n)"
  read -r start_agent

  if [[ "$start_agent" == "y" ]]; then
    # Check if the platform exists
    if [ -d "/home/locotoki/projects/alfred-agent-platform-v2" ]; then
      echo "Starting Social Intelligence Agent from Alfred Agent Platform..."
      cd /home/locotoki/projects/alfred-agent-platform-v2 || exit
      docker-compose up -d social-intel redis qdrant pubsub-emulator

      # Wait for services to start
      echo "Waiting for services to start..."
      sleep 10

      # Check if services are running
      if docker ps | grep -q social-intel; then
        echo "Social Intelligence Agent started successfully."
      else
        echo "Failed to start Social Intelligence Agent."
        echo "Proceeding with mock data."
        export VITE_USE_MOCK_DATA=true
      fi
    else
      echo "Alfred Agent Platform not found. Proceeding with mock data."
      export VITE_USE_MOCK_DATA=true
    fi
  else
    echo "Proceeding with mock data."
    export VITE_USE_MOCK_DATA=true
  fi
else
  echo "Social Intelligence Agent is running."
fi

# Return to orchestrator directory
cd /home/locotoki/alfred-agent-orchestrator || exit

# Test API connectivity
echo "Testing API connectivity to Social Intelligence Agent..."
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9000/health/ || echo "000")

if [ "$response" == "200" ]; then
  echo "Social Intelligence Agent API is accessible."
  export VITE_USE_MOCK_DATA=false
else
  echo "Social Intelligence Agent API is not accessible. Status code: $response"
  echo "Using mock data for testing."
  export VITE_USE_MOCK_DATA=true
fi

# Build and start the orchestrator in test mode
echo "Building and starting Alfred Agent Orchestrator..."
if [ "$VITE_USE_MOCK_DATA" == "true" ]; then
  # Update env file for mock data
  if grep -q "VITE_USE_MOCK_DATA" .env; then
    sed -i 's/VITE_USE_MOCK_DATA=.*/VITE_USE_MOCK_DATA=true/' .env
  else
    echo "VITE_USE_MOCK_DATA=true" >> .env
  fi
else
  # Update env file for real data
  if grep -q "VITE_USE_MOCK_DATA" .env; then
    sed -i 's/VITE_USE_MOCK_DATA=.*/VITE_USE_MOCK_DATA=false/' .env
  else
    echo "VITE_USE_MOCK_DATA=false" >> .env
  fi
fi

# Start in development mode
if command -v npm &> /dev/null; then
  echo "Starting orchestrator with npm..."
  echo "Installing dependencies..."
  npm install

  echo "Starting development server..."
  export PORT=5174  # Use a different port for testing
  npm run dev -- --port 5174 &
  ORCHESTRATOR_PID=$!

  # Wait for server to start
  echo "Waiting for server to start..."
  sleep 10

  # Test server connectivity
  response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:5174/ || echo "000")

  if [ "$response" == "200" ]; then
    echo "Alfred Agent Orchestrator is running and accessible."

    # Perform basic tests
    echo "Running basic URL tests..."

    # Test homepage
    if curl -s http://localhost:5174/ | grep -q "Orchestrator"; then
      echo "✓ Homepage loads successfully"
    else
      echo "✗ Homepage test failed"
    fi

    # Manual tests
    echo ""
    echo "Manual Test Instructions:"
    echo "------------------------"
    echo "1. Open http://localhost:5174/ in your browser"
    echo "2. Navigate to the YouTube Workflows section"
    echo "3. Test running the Niche-Scout workflow"
    echo "4. Test running the Seed-to-Blueprint workflow"
    echo "5. View workflow history and results"
    echo ""

    # Wait for user to finish testing
    read -rp "Press Enter when finished testing..."

    # Stop the server
    kill $ORCHESTRATOR_PID
  else
    echo "Alfred Agent Orchestrator failed to start. Status code: $response"
    if [ -n "$ORCHESTRATOR_PID" ]; then
      kill $ORCHESTRATOR_PID
    fi
  fi
else
  echo "npm is not installed. Please install npm and try again."
fi

echo "Integration test script completed."
