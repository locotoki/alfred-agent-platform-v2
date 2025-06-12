#\!/bin/bash
# Alfred Agent Platform v2 - Full Stack Deployment
# Works consistently on macOS, Windows, Linux

cd "$(dirname "$0")"

echo "🚀 Starting Alfred Agent Platform v2 - Full Stack"

# Stop any existing services
docker compose down --remove-orphans

# Start with all UI services (matches Windows deployment)
docker compose \
  --profile dev \
  --profile llm \
  --profile ui \
  up -d

echo "⏳ Waiting for services to start..."
sleep 15

echo "🌐 Platform URLs:"
echo "• Chat UI        → http://localhost:8502"
echo "• Admin UI       → http://localhost:3007" 
echo "• Agent Core     → http://localhost:8011/health"
echo "• Supabase UI    → http://localhost:3001"
echo "• MailHog        → http://localhost:8025"

echo "✅ Full platform operational\!"
