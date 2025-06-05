#!/bin/bash
# Alfred Agent Platform - Public Deployment Setup
# This script helps configure secure public access to your platform

set -e

echo "🚀 Alfred Agent Platform - Public Deployment Setup"
echo "=================================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ Please do not run this script as root"
   exit 1
fi

# Function to install dependencies
install_deps() {
    echo "📦 Installing dependencies..."
    sudo apt update
    sudo apt install -y nginx certbot python3-certbot-nginx ufw curl
}

# Function to configure firewall
setup_firewall() {
    echo "🔥 Configuring firewall..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow ssh
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw --force enable
}

# Function to setup nginx reverse proxy
setup_nginx() {
    local domain=$1
    echo "🌐 Setting up nginx reverse proxy for domain: $domain"
    
    cat > /tmp/alfred-nginx.conf << EOF
server {
    listen 80;
    server_name $domain;
    return 301 https://\$server_name\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name $domain;

    # SSL configuration will be added by certbot
    
    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # Rate limiting
    limit_req_zone \$binary_remote_addr zone=api:10m rate=10r/s;
    limit_req_zone \$binary_remote_addr zone=ui:10m rate=5r/s;

    # Chat UI - Main user interface
    location / {
        limit_req zone=ui burst=10 nodelay;
        proxy_pass http://localhost:8502;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Admin interface - Requires authentication
    location /admin {
        limit_req zone=ui burst=5 nodelay;
        proxy_pass http://localhost:3007;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Add basic auth (you can replace with oauth later)
        auth_basic "Admin Area";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }

    # API endpoints
    location /api {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://localhost:8011;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Monitoring (Grafana) - Requires authentication
    location /monitoring {
        limit_req zone=ui burst=5 nodelay;
        proxy_pass http://localhost:3005;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Add basic auth
        auth_basic "Monitoring";
        auth_basic_user_file /etc/nginx/.htpasswd;
    }

    # Health check endpoint
    location /health {
        proxy_pass http://localhost:8011/health;
        access_log off;
    }
}
EOF
    
    sudo mv /tmp/alfred-nginx.conf /etc/nginx/sites-available/alfred
    sudo ln -sf /etc/nginx/sites-available/alfred /etc/nginx/sites-enabled/
    sudo rm -f /etc/nginx/sites-enabled/default
    sudo nginx -t
    sudo systemctl reload nginx
}

# Function to setup SSL with Let's Encrypt
setup_ssl() {
    local domain=$1
    local email=$2
    echo "🔒 Setting up SSL certificate for $domain"
    sudo certbot --nginx -d $domain --email $email --agree-tos --non-interactive
}

# Function to create admin credentials
setup_admin_auth() {
    echo "👤 Setting up admin authentication..."
    read -p "Enter admin username: " admin_user
    sudo htpasswd -c /etc/nginx/.htpasswd $admin_user
}

# Function to setup Docker environment
setup_docker_env() {
    echo "🐳 Setting up Docker environment variables..."
    
    if [ ! -f .env ]; then
        cat > .env << EOF
# Alfred Agent Platform - Production Environment
ALFRED_ENVIRONMENT=production
ALFRED_DEBUG=false

# Database
POSTGRES_PASSWORD=$(openssl rand -base64 32)
DB_PASSWORD=$(openssl rand -base64 32)
DB_JWT_SECRET=$(openssl rand -base64 64)

# Redis
REDIS_PASSWORD=$(openssl rand -base64 32)

# API Keys (you need to provide these)
ALFRED_OPENAI_API_KEY=your-openai-api-key-here
ALFRED_ANTHROPIC_API_KEY=your-anthropic-api-key-here
ALFRED_YOUTUBE_API_KEY=your-youtube-api-key-here

# Slack (if using)
SLACK_BOT_TOKEN=your-slack-bot-token-here
SLACK_SIGNING_SECRET=your-slack-signing-secret-here
SLACK_APP_TOKEN=your-slack-app-token-here

# Monitoring
MONITORING_ADMIN_PASSWORD=$(openssl rand -base64 16)

# External URLs
API_EXTERNAL_URL=https://$1
SITE_URL=https://$1
EOF
        echo "✅ Created .env file with secure passwords"
        echo "⚠️  Please edit .env and add your API keys"
    else
        echo "ℹ️  .env file already exists"
    fi
}

# Function to start services
start_services() {
    echo "🚀 Starting Alfred services..."
    docker-compose up -d
    
    echo "⏳ Waiting for services to become healthy..."
    sleep 30
    
    # Check service health
    for service in agent-core ui-chat ui-admin monitoring-dashboard; do
        if docker-compose ps $service | grep -q "Up"; then
            echo "✅ $service is running"
        else
            echo "❌ $service failed to start"
        fi
    done
}

# Main setup flow
main() {
    echo "Starting setup process..."
    
    # Get domain and email from user
    read -p "Enter your domain name (e.g., alfred.yourdomain.com): " domain
    read -p "Enter your email for SSL certificate: " email
    
    # Validate inputs
    if [ -z "$domain" ] || [ -z "$email" ]; then
        echo "❌ Domain and email are required"
        exit 1
    fi
    
    echo "🎯 Setting up Alfred Agent Platform for domain: $domain"
    
    # Run setup steps
    install_deps
    setup_firewall
    setup_docker_env $domain
    setup_nginx $domain
    setup_ssl $domain $email
    setup_admin_auth
    start_services
    
    echo ""
    echo "🎉 Setup complete!"
    echo "================================"
    echo "🌐 Main chat interface: https://$domain"
    echo "👨‍💼 Admin dashboard: https://$domain/admin"
    echo "📊 Monitoring: https://$domain/monitoring"
    echo "🔧 API endpoint: https://$domain/api"
    echo ""
    echo "🔑 Next steps:"
    echo "1. Edit .env file and add your API keys"
    echo "2. Restart services: docker-compose up -d"
    echo "3. Test the endpoints above"
    echo "4. Configure DNS to point $domain to this server"
    echo ""
    echo "📖 Documentation: https://github.com/locotoki/alfred-agent-platform-v2"
}

# Check if domain argument provided
if [ $# -eq 0 ]; then
    main
else
    # Non-interactive mode
    domain=$1
    email=${2:-admin@$domain}
    install_deps
    setup_firewall
    setup_docker_env $domain
    setup_nginx $domain
    echo "⚠️  Run 'sudo certbot --nginx -d $domain' manually to setup SSL"
    echo "⚠️  Run setup_admin_auth function to create admin credentials"
fi