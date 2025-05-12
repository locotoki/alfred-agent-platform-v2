#!/bin/bash
set -e

echo "Setting up Atlas tables in Supabase..."

# Copy the migration file to the container first
docker cp migrations/0001_supabase_channels.sql supabase-db:/docker-entrypoint-initdb.d/

# Apply the migration
docker exec supabase-db psql -U postgres -d postgres -f /docker-entrypoint-initdb.d/0001_supabase_channels.sql

echo "Creating .env.dev file with Supabase configuration..."

# Create the .env.dev file if it doesn't exist
if [ ! -f .env.dev ]; then
    cat > .env.dev << EOF
# OpenAI API key - you need to fill this in
OPENAI_API_KEY=your_openai_api_key

# Supabase configuration
SUPABASE_URL=http://localhost:54321
SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSJ9.vI9obAHOGyVVKa3pD--kJlyxp-Z2zV9UUMAhKpNLAcU

# Pub/Sub configuration
PUBSUB_PROJECT_ID=atlas-dev
EOF
    echo "Created .env.dev file. Please edit it to add your OpenAI API key."
else
    echo ".env.dev file already exists. Skipping creation."
fi

echo "Restarting Atlas Worker with Supabase configuration..."

# Source the environment variables
export $(grep -v '^#' .env.dev | xargs)

# Restart the Atlas Worker
docker-compose -f docker-compose.dev.yml up -d atlas-worker

echo "Setup complete!"
echo "To test Atlas, run: ./scripts/publish_task.sh \"Design a microservice logging architecture\""