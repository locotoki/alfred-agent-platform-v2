#!/bin/bash
set -e

YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}Fixing vector-db health check...${NC}"

# Check if the container is running
if ! docker ps | grep -q vector-db; then
  echo -e "${RED}Container vector-db is not running.${NC}"
  exit 1
fi

# Install curl in the container
echo -e "${YELLOW}Installing curl in the vector-db container...${NC}"
docker exec vector-db sh -c "apt-get update && apt-get install -y curl"

# Verify curl is installed
if ! docker exec vector-db which curl > /dev/null; then
  echo -e "${RED}Failed to install curl in the container.${NC}"
  echo -e "${YELLOW}Let's try a different approach with a custom health check script...${NC}"
  
  # Create a custom health check script that uses wget or other tools
  docker exec vector-db sh -c 'cat > /healthcheck.sh << EOF
#!/bin/sh
# Try to access the healthz endpoint
if wget -q -O - http://localhost:6333/healthz > /dev/null 2>&1; then
  exit 0
else
  exit 1
fi
EOF'
  
  docker exec vector-db sh -c "chmod +x /healthcheck.sh"
  
  # Modify the health check to use our script
  echo -e "${YELLOW}We need to recreate the container with the new health check.${NC}"
  
  # Stop the current container
  docker stop vector-db
  
  # Get the volume name
  VOLUME_NAME=$(docker inspect --format='{{range .Mounts}}{{.Name}}{{end}}' vector-db)
  
  # Run a new container with the same config but different healthcheck
  docker run -d \
    --name vector-db-fixed \
    --network alfred-network \
    -p 6333:6333 \
    -p 6334:6334 \
    -v $VOLUME_NAME:/qdrant/storage \
    --health-cmd "/healthcheck.sh" \
    --health-interval 10s \
    --health-timeout 5s \
    --health-retries 3 \
    --health-start-period 10s \
    qdrant/qdrant:v1.7.4
  
  # Remove the old container
  docker rm vector-db
  
  # Rename the new container
  docker rename vector-db-fixed vector-db
  
  echo -e "${GREEN}✅ Created a new vector-db container with a custom health check script.${NC}"
else
  # Test if health check works now
  if docker exec vector-db curl -s http://localhost:6333/healthz > /dev/null; then
    echo -e "${GREEN}✅ curl is installed and health check endpoint is accessible.${NC}"
    echo -e "${YELLOW}The container should become healthy in the next health check cycle.${NC}"
  else
    echo -e "${RED}❌ Health check is still failing. The endpoint may not be available.${NC}"
    
    # Try to diagnose why the health endpoint isn't accessible
    docker exec vector-db curl -v http://localhost:6333/healthz
  fi
fi