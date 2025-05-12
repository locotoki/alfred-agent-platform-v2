# Alfred Chat Interface: Production Deployment Guide

This guide provides instructions for deploying the Alfred Chat Interface (Streamlit UI and Alfred Bot) to a production environment.

## Prerequisites

- A Linux server with Docker and Docker Compose installed
- Slack Bot credentials (Bot Token and Signing Secret)
- Database connection information
- Port 8501 and 8011 available on the host system
- Sufficient permissions to run Docker commands

## Deployment Steps

### 1. Prepare the Environment

1. Clone the repository (if not already done):
   ```bash
   git clone https://github.com/your-organization/alfred-agent-platform-v2.git
   cd alfred-agent-platform-v2
   ```

2. Navigate to the Streamlit Chat directory:
   ```bash
   cd services/streamlit-chat
   ```

3. Create a production environment file:
   ```bash
   cp .env.production.sample .env.production
   ```

4. Edit the `.env.production` file with your production credentials:
   ```bash
   nano .env.production
   ```

### 2. Configure Domain Names (Optional)

If you plan to use domain names for the services, you'll need to:

1. Set up DNS records for your domains (e.g., `chat.alfred.example.com` and `api.alfred.example.com`)
2. Modify the `traefik` labels in `docker-compose.prod.yml` to match your domains
3. Set up SSL certificates (recommended for production)

### 3. Run the Deployment Script

Execute the deployment script with appropriate permissions:

```bash
sudo ./deploy-production.sh
```

The script will:
- Check for required environment variables
- Pull the latest code (if in a Git repository)
- Build and start the services
- Verify the health of all services
- Test the integration between components
- Provide access URLs and log file locations

### 4. Verify the Deployment

After deployment completes, verify that:

1. The Streamlit Chat UI is accessible at `http://your-server-ip:8501` or your configured domain
2. The Alfred Bot API is responding at `http://your-server-ip:8011/health`
3. The Redis service is running correctly

### 5. Set Up Reverse Proxy (Recommended)

For a production environment, we recommend placing the services behind a reverse proxy like Nginx or Traefik to:

- Provide SSL termination
- Handle domain routing
- Improve security

Example Nginx configuration for the Streamlit Chat UI:

```nginx
server {
    listen 80;
    server_name chat.alfred.example.com;
    
    # Redirect HTTP to HTTPS
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name chat.alfred.example.com;
    
    ssl_certificate /path/to/certificate.pem;
    ssl_certificate_key /path/to/privatekey.pem;
    
    location / {
        proxy_pass http://localhost:8501;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

### 6. Monitoring and Maintenance

#### Checking Logs

To check the logs of running services:

```bash
docker compose -f docker-compose.prod.yml logs -f
```

To check logs for a specific service:

```bash
docker compose -f docker-compose.prod.yml logs -f streamlit-chat
docker compose -f docker-compose.prod.yml logs -f alfred-bot
```

#### Restarting Services

To restart all services:

```bash
docker compose -f docker-compose.prod.yml restart
```

To restart a specific service:

```bash
docker compose -f docker-compose.prod.yml restart streamlit-chat
```

#### Updating the Deployment

To update the deployment with the latest code:

1. Pull the latest changes:
   ```bash
   git pull
   ```

2. Re-run the deployment script:
   ```bash
   sudo ./deploy-production.sh
   ```

#### Stopping the Services

To stop all services:

```bash
docker compose -f docker-compose.prod.yml down
```

## Troubleshooting

### Common Issues

1. **Services not starting**: Check the logs for errors using `docker compose -f docker-compose.prod.yml logs`

2. **Cannot access Streamlit UI**: Verify that port 8501 is accessible from your network and not blocked by firewall

3. **Alfred Bot not connecting to Slack**: Check the Slack credentials in the environment file and verify the bot is properly configured in Slack

4. **Database connection issues**: Verify the `DATABASE_URL` is correct and the database is accessible from the server

5. **Redis connection failures**: Ensure Redis is running and accessible on port 6379

### Health Check

To manually check the health of services:

```bash
curl http://localhost:8011/health
curl http://localhost:8501
```

## Security Considerations

For a production deployment, consider:

1. **Network Security**: Place services behind a firewall and only expose necessary ports
2. **Authentication**: Add authentication to the Streamlit UI (e.g., via a reverse proxy)
3. **Encryption**: Use HTTPS for all external access
4. **Environment Variables**: Secure your environment files and credentials
5. **Regular Updates**: Keep all components updated with security patches

## Backup Strategy

Regularly back up:

1. The Redis data volume (`redis-data`)
2. Your PostgreSQL database
3. The configuration files and environment variables

## Resources

- [Docker Documentation](https://docs.docker.com/)
- [Streamlit Deployment](https://docs.streamlit.io/knowledge-base/deploy/index.html)
- [Slack API Documentation](https://api.slack.com/docs)