#!/bin/bash
# Slack Integration Safeguard Script
# Prevents breakage by versioning and backing up working images

set -e

echo "🛡️ Slack Integration Safeguard"
echo "=============================="

# Check if services are currently working
check_health() {
    echo "Checking service health..."
    
    # Check slack_mcp_gateway
    if docker exec slack_mcp_gateway wget -q -O- http://localhost:3000/health > /dev/null 2>&1; then
        echo "✅ slack_mcp_gateway is healthy"
        GATEWAY_HEALTHY=true
    else
        echo "❌ slack_mcp_gateway is NOT healthy"
        GATEWAY_HEALTHY=false
    fi
    
    # Check echo-agent
    if docker ps | grep -q echo-agent; then
        echo "✅ echo-agent is running"
        AGENT_HEALTHY=true
    else
        echo "❌ echo-agent is NOT running"
        AGENT_HEALTHY=false
    fi
}

# Backup working images
backup_images() {
    if [[ "$GATEWAY_HEALTHY" == "true" ]] && [[ "$AGENT_HEALTHY" == "true" ]]; then
        echo ""
        echo "🔒 Creating backup of working images..."
        
        # Generate timestamp
        TIMESTAMP=$(date +%Y%m%d_%H%M%S)
        
        # Tag current working versions
        docker tag slack-mcp-gateway:latest slack-mcp-gateway:backup-${TIMESTAMP}
        docker tag echo-agent:latest echo-agent:backup-${TIMESTAMP}
        
        # Also create a "last-known-good" tag
        docker tag slack-mcp-gateway:latest slack-mcp-gateway:last-known-good
        docker tag echo-agent:latest echo-agent:last-known-good
        
        echo "✅ Backed up as:"
        echo "   - slack-mcp-gateway:backup-${TIMESTAMP}"
        echo "   - echo-agent:backup-${TIMESTAMP}"
        echo "   - slack-mcp-gateway:last-known-good"
        echo "   - echo-agent:last-known-good"
        
        # Save backup info
        cat > .slack-backup-info <<EOF
BACKUP_DATE=${TIMESTAMP}
GATEWAY_IMAGE=slack-mcp-gateway:backup-${TIMESTAMP}
AGENT_IMAGE=echo-agent:backup-${TIMESTAMP}
EOF
        echo ""
        echo "📝 Backup info saved to .slack-backup-info"
    else
        echo ""
        echo "⚠️  Services not healthy - skipping backup"
    fi
}

# Restore from backup
restore_images() {
    if [[ -f .slack-backup-info ]]; then
        source .slack-backup-info
        echo ""
        echo "🔄 Restoring from backup ${BACKUP_DATE}..."
        
        # Tag backup images as latest
        docker tag ${GATEWAY_IMAGE} slack-mcp-gateway:latest
        docker tag ${AGENT_IMAGE} echo-agent:latest
        
        echo "✅ Restored from backup"
        echo ""
        echo "Restart services with:"
        echo "  docker-compose -f docker-compose.yml -f docker-compose.slack.yml restart slack_mcp_gateway echo-agent"
    else
        echo "❌ No backup found. Attempting to restore from last-known-good..."
        
        if docker image inspect slack-mcp-gateway:last-known-good > /dev/null 2>&1; then
            docker tag slack-mcp-gateway:last-known-good slack-mcp-gateway:latest
            docker tag echo-agent:last-known-good echo-agent:latest
            echo "✅ Restored from last-known-good tags"
        else
            echo "❌ No last-known-good images found"
            exit 1
        fi
    fi
}

# Main menu
case "${1:-}" in
    check)
        check_health
        ;;
    backup)
        check_health
        backup_images
        ;;
    restore)
        restore_images
        ;;
    *)
        echo "Usage: $0 {check|backup|restore}"
        echo ""
        echo "Commands:"
        echo "  check   - Check health of Slack services"
        echo "  backup  - Backup working images (only if healthy)"
        echo "  restore - Restore from last backup"
        echo ""
        echo "Example workflow:"
        echo "  1. $0 check    # Verify services are working"
        echo "  2. $0 backup   # Create backup of working state"
        echo "  3. ... make changes ..."
        echo "  4. $0 restore  # If things break, restore backup"
        ;;
esac