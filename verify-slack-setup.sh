#!/bin/bash
################################################################################
# ▶️  QUICK VERIFY BLOCK — finish /alfred slash-command bring-up               #
# Run right after you've started the ngrok tunnel. It will:                    #
#   1.  Fetch the current HTTPS ngrok URL.                                     #
#   2.  Echo the exact Slack App URLs you need to paste.                       #
#   3.  Write PUBLIC_BASE_URL to .env.local and restart Slack services.        #
#   4.  Fire a `/alfred ping` test from your CLI (slash-command simulation).   #
################################################################################
set -euo pipefail

PORT=8080
ENV_FILE=".env.local"

###############################################################################
# 1️⃣  Grab the active ngrok URL                                              #
###############################################################################
URL=$(curl -s http://127.0.0.1:4040/api/tunnels | \
      jq -r '.tunnels[] | select(.proto=="https") | .public_url')
if [[ -z "$URL" || "$URL" == "null" ]]; then
  echo "❌  No https ngrok tunnel detected on :4040 – start ngrok first!"
  echo "     Command:  ngrok http $PORT &"
  exit 1
fi
echo -e "\n🌐  Your public HTTPS URL is:\n   $URL"

###############################################################################
# 2️⃣  Show Slack App settings                                                #
###############################################################################
cat <<EOF

🛠  Slack App → **Slash Commands**
   • Command: /alfred
   • Request URL:  $URL/slack/commands
   • Short description: Alfred bot command
   • Save

🛠  Slack App → **Interactivity & Shortcuts**
   • Request URL:  $URL/slack/commands
   • Enable → Save

(If you use Events API, set the same base URL with `/slack/events`.)

EOF

###############################################################################
# 3️⃣  Persist PUBLIC_BASE_URL + restart Slack containers                      #
###############################################################################
grep -q '^PUBLIC_BASE_URL=' "$ENV_FILE" && \
  sed -i.bak "s|^PUBLIC_BASE_URL=.*|PUBLIC_BASE_URL=$URL|" "$ENV_FILE" || \
  echo "PUBLIC_BASE_URL=$URL" >> "$ENV_FILE"

echo "🔄  Restarting Slack adapter stack …"
docker compose --env-file "$ENV_FILE" up -d slack-adapter alfred-bot slack_mcp_gateway
sleep 4
docker compose logs --tail 20 slack-adapter | grep -i "socket" || true

###############################################################################
# 4️⃣  Simulate /alfred ping from CLI                                         #
###############################################################################
echo -e "\nPress [Enter] to simulate \"/alfred ping\" …"
read -r
curl -s -X POST "$URL/slack/commands" \
  -d "token=TEST" \
  -d "command=/alfred" \
  -d "text=ping" \
  -d "user_id=U123" \
  -d "channel_id=C123" \
  | jq . || echo "Response received (jq not available)"

echo -e "\n✅  If you see { \"response_type\": ... \"Pong\" } the slash-command path is live."
echo -e "Now try **/alfred ping** in Slack — you should get \"Pong!\" back."
echo -e "All set! 🚀"