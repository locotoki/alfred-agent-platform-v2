#!/bin/bash
# Script to install and configure ngrok for Alfred Platform

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root (with sudo)"
  exit 1
fi

echo "Installing ngrok..."

# Add ngrok's official GPG key
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null

# Add the ngrok repository to the system
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list

# Update the package index and install ngrok
apt update && apt install -y ngrok

echo "ngrok installed successfully!"

echo "Creating ngrok configuration file..."

# Get the current user
CURRENT_USER=$(logname || echo "$SUDO_USER" || echo "$USER")
CONFIG_DIR="/home/$CURRENT_USER"
CONFIG_FILE="$CONFIG_DIR/ngrok-alfred.yml"

# Create the configuration file
cat > "$CONFIG_FILE" << 'EOL'
version: 2
authtoken: YOUR_NGROK_AUTH_TOKEN
tunnels:
  alfred-bot:
    proto: http
    addr: 8011
    # If you have a paid plan, uncomment the line below and set your desired subdomain
    # subdomain: alfred-platform
EOL

# Set proper ownership
chown "$CURRENT_USER:$CURRENT_USER" "$CONFIG_FILE"

echo "Creating systemd service for ngrok..."

# Create a systemd service file
cat > /etc/systemd/system/ngrok-alfred.service << EOL
[Unit]
Description=ngrok tunnel for Alfred Slack Bot
After=network.target

[Service]
ExecStart=ngrok start --config=${CONFIG_FILE} alfred-bot
Restart=always
User=${CURRENT_USER}
Group=${CURRENT_USER}

[Install]
WantedBy=multi-user.target
EOL

echo "ngrok configuration created at $CONFIG_FILE"
echo ""
echo "IMPORTANT: Before starting the service, edit $CONFIG_FILE and add your ngrok authtoken"
echo "You can get your token by signing up at https://ngrok.com"
echo ""
echo "Once configured, enable and start the service with:"
echo "sudo systemctl enable ngrok-alfred"
echo "sudo systemctl start ngrok-alfred"
echo ""
echo "To check the status, run:"
echo "sudo systemctl status ngrok-alfred"
echo ""
echo "To get your public URL, run:"
echo "curl http://localhost:4040/api/tunnels | jq '.tunnels[0].public_url'"