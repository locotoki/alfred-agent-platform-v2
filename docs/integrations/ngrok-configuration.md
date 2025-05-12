# ngrok Configuration Guide

**Last Updated:** 2025-05-12  
**Owner:** Platform Team  
**Status:** Active

## Overview

This guide provides comprehensive instructions for configuring and using ngrok with the Alfred Agent Platform. ngrok enables secure HTTP tunneling from public endpoints to your local development environment, allowing external services like Slack to communicate with locally running components of the platform. This is particularly useful for development and testing of webhook-based integrations.

## Purpose and Requirements

### Use Cases

1. **Slack Bot Development**: Enable Slack to send events to a locally running Alfred Slack Bot
2. **Webhook Testing**: Test webhook integrations without deploying to a public server
3. **Demo Environments**: Quickly set up demonstration environments accessible externally
4. **Development Workflow**: Streamline development of webhook-based integrations

### Requirements

- ngrok account (free or paid)
- ngrok authentication token
- Local development environment
- Appropriate firewall permissions
- Admin rights for system service setup (optional)

## Installation

### Linux

```bash
# Add ngrok's official GPG key
curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null

# Add the ngrok repository to the system
echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list

# Update the package index and install ngrok
sudo apt update && sudo apt install -y ngrok
```

### macOS

```bash
# Using Homebrew
brew install ngrok

# Or manual download
curl https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-stable-darwin-amd64.zip -o ngrok.zip
unzip ngrok.zip
sudo mv ngrok /usr/local/bin
```

### Windows

```bash
# Using Chocolatey
choco install ngrok

# Or download and install manually from https://ngrok.com/download
```

## Configuration

### Basic Authentication Setup

1. Sign up for an ngrok account at https://ngrok.com/
2. Retrieve your authentication token from the ngrok dashboard
3. Add your authentication token to ngrok:

```bash
ngrok config add-authtoken YOUR_NGROK_AUTH_TOKEN
```

### Configuration File Setup

Create a configuration file for Alfred-specific settings:

```yaml
# ~/ngrok-alfred.yml
version: 2
authtoken: YOUR_NGROK_AUTH_TOKEN  # Replace with your actual token
tunnels:
  alfred-bot:
    proto: http
    addr: 8011  # Alfred Slack Bot port
    # If you have a paid plan, you can use a custom subdomain:
    # subdomain: alfred-platform
```

### Service Configuration

For persistent operation, create a system service:

```bash
# Create systemd service file
sudo tee /etc/systemd/system/ngrok-alfred.service > /dev/null << 'EOF'
[Unit]
Description=ngrok tunnel for Alfred Slack Bot
After=network.target

[Service]
ExecStart=ngrok start --config=/home/USERNAME/ngrok-alfred.yml alfred-bot
Restart=always
User=USERNAME
Group=USERNAME

[Install]
WantedBy=multi-user.target
EOF

# Replace USERNAME with your actual username
sudo sed -i "s/USERNAME/$(whoami)/g" /etc/systemd/system/ngrok-alfred.service

# Enable and start the service
sudo systemctl enable ngrok-alfred
sudo systemctl start ngrok-alfred
```

## Usage

### Starting a Tunnel Manually

```bash
# Start ngrok using the configuration file
ngrok start --config=~/ngrok-alfred.yml alfred-bot

# Start a tunnel without a configuration file
ngrok http 8011
```

### Verifying the Tunnel

```bash
# Check if the tunnel is running
curl http://localhost:4040/api/tunnels

# Get the public URL
curl http://localhost:4040/api/tunnels | jq '.tunnels[0].public_url'
```

### Checking Tunnel Status

The ngrok web interface is available at http://localhost:4040 when ngrok is running. This shows:

- Active tunnels
- Request/response inspection
- Metrics and logging
- Replay capabilities

## Slack Integration

### Configuring Slack with ngrok

1. Start your ngrok tunnel for the Alfred Slack Bot
2. Get the public URL: `curl http://localhost:4040/api/tunnels | jq '.tunnels[0].public_url'`
3. Access your Slack App configuration at https://api.slack.com/apps
4. Navigate to "Event Subscriptions"
5. Enable events and set the Request URL to:
   ```
   https://your-ngrok-domain.ngrok.io/slack/events
   ```
6. Navigate to "Slash Commands"
7. Update the `/alfred` command URL to:
   ```
   https://your-ngrok-domain.ngrok.io/slack/events
   ```
8. Save changes

### Testing the Integration

1. Verify the endpoint is working using the Slack verification:
   ```bash
   curl https://your-ngrok-domain.ngrok.io/slack/health
   ```
   Expected response: `{"status":"ok","version":"1.0.0"}`

2. Test the slash command in Slack:
   ```
   /alfred ping
   ```

3. Test direct messages to the Alfred bot user

## Security Considerations

### Free vs. Paid Plans

| Feature | Free Plan | Paid Plan |
|---------|-----------|-----------|
| Fixed Subdomains | No | Yes |
| Custom Domains | No | Yes |
| IP Restrictions | No | Yes |
| Team Management | No | Yes |
| TLS Certificates | Shared | Custom |

### Security Best Practices

1. **Access Controls**: Limit access to the tunneled application:
   ```yaml
   # In ngrok-alfred.yml
   tunnels:
     alfred-bot:
       proto: http
       addr: 8011
       basic_auth:
         - "username:password"  # For non-Slack testing only
   ```

2. **IP Restrictions** (Paid plans only):
   ```yaml
   # In ngrok-alfred.yml
   tunnels:
     alfred-bot:
       proto: http
       addr: 8011
       ip_restriction:
         allow_cidrs:
           - "192.168.1.0/24"  # Local network
           - "54.0.0.0/8"      # Slack IPs
   ```

3. **Limited Scope**: Run ngrok only when needed for development/testing
4. **Webhook Verification**: Always validate incoming webhook signatures
5. **Sensitive Data**: Avoid exposing sensitive data in development environments

## Troubleshooting

### Common Issues

| Issue | Possible Cause | Solution |
|-------|----------------|----------|
| "failed to bind" error | Port already in use | Stop existing process or change port |
| Authentication failed | Invalid auth token | Check/update your auth token |
| Connection refused | Target service not running | Start the Alfred Slack Bot service |
| Rate limit exceeded | Free plan limitations | Upgrade plan or wait for limit reset |
| Tunnel disconnecting | Network issues | Check internet connection, use agent mode |

### Debugging Tips

1. Check ngrok logs:
   ```bash
   sudo journalctl -u ngrok-alfred.service
   ```

2. Verify the Alfred Slack Bot is running:
   ```bash
   curl http://localhost:8011/slack/health
   ```

3. Check ngrok status:
   ```bash
   curl http://localhost:4040/api/tunnels
   ```

4. Test with a simple HTTP response:
   ```bash
   # Run a simple HTTP server
   python -m http.server 8000
   
   # In another terminal, tunnel to it
   ngrok http 8000
   ```

## Production Alternatives

For production environments, consider these alternatives to ngrok:

1. **Public Cloud Load Balancers**:
   - AWS Application Load Balancer
   - Google Cloud Load Balancing
   - Azure Application Gateway

2. **Reverse Proxies**:
   - Nginx with proper SSL configuration
   - Caddy Server with automatic HTTPS
   - Traefik with Let's Encrypt integration

3. **API Gateways**:
   - Kong API Gateway
   - AWS API Gateway
   - Google Cloud API Gateway

## Performance Considerations

- **Latency**: ngrok adds 10-50ms latency to each request
- **Bandwidth**: Free plan limited to 1MB/s
- **Connection Limits**: Free plan has connection limits
- **Stability**: Tunnels may disconnect after extended periods

## Monitoring and Logging

### ngrok Dashboard

Access the dashboard at https://dashboard.ngrok.com to view:

- Active tunnels
- Traffic statistics
- Event logs
- Billing information

### Local Interface

The local web interface at http://localhost:4040 provides:

- Real-time request inspection
- Replay capabilities
- Metrics visualization
- Tunnel status

### Integration with Platform Monitoring

Add the ngrok tunnel status to platform monitoring:

```bash
# Generate status check for Prometheus
curl -s http://localhost:4040/api/tunnels | jq '.tunnels | length' > /tmp/ngrok_tunnels_count.prom
```

## Future Enhancements

- **Custom Domain Integration**: Using ngrok with verified custom domains
- **Automated Setup Script**: Simplify installation and configuration
- **CI/CD Integration**: Integrate with CI/CD pipelines for testing
- **Load Balancing**: Multiple ngrok tunnels for load distribution
- **Metrics Collection**: Better integration with platform monitoring

## Related Documentation

- [Alfred Slack Bot](../agents/interfaces/alfred-slack-bot.md): The primary service using ngrok tunneling
- [Slack Conversation Workflow](../workflows/interfaces/slack-conversation-workflow.md): Workflow that uses the Slack connection
- [Platform Security Guide](../security/platform-security-guide.md): General security considerations for the platform

## References

- [ngrok Documentation](https://ngrok.com/docs)
- [Slack API: Events API](https://api.slack.com/events-api)
- [Slack API: Slash Commands](https://api.slack.com/interactivity/slash-commands)