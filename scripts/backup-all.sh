#!/bin/bash
# Automated backup script for all stateful services
set -euo pipefail

# Configuration
BACKUP_ROOT="${BACKUP_ROOT:-/tmp/backups}"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="$BACKUP_ROOT/$DATE"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo -e "${BLUE}🔵 Starting backup: $DATE${NC}"
echo -e "Backup directory: $BACKUP_DIR\n"

# Function to check if service is running
service_running() {
    docker compose ps --services --filter "status=running" | grep -q "^$1$"
}

# PostgreSQL backup
if service_running "db-postgres"; then
    echo -e "${BLUE}📦 Backing up PostgreSQL...${NC}"
    if docker compose exec -T db-postgres pg_dump -U postgres alfred_db > "$BACKUP_DIR/postgres.sql" 2>/dev/null; then
        size=$(du -h "$BACKUP_DIR/postgres.sql" | cut -f1)
        echo -e "${GREEN}✓ PostgreSQL backup complete ($size)${NC}"
    else
        echo -e "${RED}✗ PostgreSQL backup failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠ PostgreSQL not running, skipping${NC}"
fi

# Redis backup
if service_running "redis"; then
    echo -e "\n${BLUE}📦 Backing up Redis...${NC}"
    if docker compose exec -T redis redis-cli BGSAVE > /dev/null 2>&1; then
        sleep 2  # Wait for background save
        docker compose cp redis:/data/dump.rdb "$BACKUP_DIR/redis.rdb" 2>/dev/null || true
        if [ -f "$BACKUP_DIR/redis.rdb" ]; then
            size=$(du -h "$BACKUP_DIR/redis.rdb" | cut -f1)
            echo -e "${GREEN}✓ Redis backup complete ($size)${NC}"
        else
            echo -e "${RED}✗ Redis backup failed${NC}"
        fi
    else
        echo -e "${RED}✗ Redis BGSAVE failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Redis not running, skipping${NC}"
fi

# Vector DB backup (if using Qdrant)
if service_running "vector-db"; then
    echo -e "\n${BLUE}📦 Backing up Vector DB...${NC}"
    # Create snapshot via API
    if curl -X POST "http://localhost:6333/snapshots" -H "Content-Type: application/json" > /dev/null 2>&1; then
        # Get latest snapshot name
        snapshot=$(curl -s "http://localhost:6333/snapshots" | jq -r '.result[0].name' 2>/dev/null)
        if [ -n "$snapshot" ]; then
            # Download snapshot
            curl -s "http://localhost:6333/snapshots/$snapshot" > "$BACKUP_DIR/vector-db.snapshot"
            size=$(du -h "$BACKUP_DIR/vector-db.snapshot" | cut -f1)
            echo -e "${GREEN}✓ Vector DB backup complete ($size)${NC}"
        fi
    else
        echo -e "${RED}✗ Vector DB backup failed${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Vector DB not running, skipping${NC}"
fi

# Configuration files backup
echo -e "\n${BLUE}📦 Backing up configuration files...${NC}"
if [ -f .env ]; then
    cp .env "$BACKUP_DIR/env.backup"
    echo -e "${GREEN}✓ Environment configuration backed up${NC}"
fi

# Docker compose files
cp docker-compose*.yml "$BACKUP_DIR/" 2>/dev/null || true
echo -e "${GREEN}✓ Docker compose configurations backed up${NC}"

# Create backup manifest
cat > "$BACKUP_DIR/manifest.json" << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "version": "$(cat VERSION 2>/dev/null || echo 'unknown')",
  "services": {
    "postgres": $([ -f "$BACKUP_DIR/postgres.sql" ] && echo "true" || echo "false"),
    "redis": $([ -f "$BACKUP_DIR/redis.rdb" ] && echo "true" || echo "false"),
    "vector_db": $([ -f "$BACKUP_DIR/vector-db.snapshot" ] && echo "true" || echo "false"),
    "config": $([ -f "$BACKUP_DIR/env.backup" ] && echo "true" || echo "false")
  }
}
EOF

# Create compressed archive
echo -e "\n${BLUE}📦 Creating compressed archive...${NC}"
cd "$BACKUP_ROOT"
tar -czf "$DATE.tar.gz" "$DATE/"
archive_size=$(du -h "$DATE.tar.gz" | cut -f1)

# Cleanup uncompressed files (optional)
# rm -rf "$DATE/"

echo -e "\n${GREEN}✅ Backup complete!${NC}"
echo -e "Archive: $BACKUP_ROOT/$DATE.tar.gz ($archive_size)"
echo -e "Manifest: $BACKUP_DIR/manifest.json"

# Retention policy (keep last 7 days)
echo -e "\n${BLUE}🧹 Cleaning old backups...${NC}"
find "$BACKUP_ROOT" -name "*.tar.gz" -mtime +7 -delete
echo -e "${GREEN}✓ Old backups cleaned${NC}"