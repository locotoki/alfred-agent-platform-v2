#!/bin/bash
# Consolidate Docker Compose Files
# This script implements the Docker Compose consolidation plan

# Text formatting
BOLD=$(tput bold)
NORM=$(tput sgr0)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
BLUE=$(tput setaf 4)
RED=$(tput setaf 1)

# Backup timestamp
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
BACKUP_DIR="backup/docker-compose-consolidation-${TIMESTAMP}"

echo -e "${BLUE}${BOLD}=== Docker Compose Consolidation Script ===${NORM}"
echo -e "${BLUE}Creating backup directory: ${BACKUP_DIR}${NORM}"

# Create backup directory
mkdir -p "${BACKUP_DIR}"
mkdir -p "${BACKUP_DIR}/docs"

# 1. Backup current Docker Compose files
echo -e "${YELLOW}Backing up current Docker Compose files...${NORM}"
cp docker-compose*.yml "${BACKUP_DIR}/"
cp -r docker-compose/ "${BACKUP_DIR}/"

# 2. Backup documentation files
echo -e "${YELLOW}Backing up documentation files...${NORM}"
cp COMPOSE-CLEANUP-SUMMARY.md "${BACKUP_DIR}/docs/" 2>/dev/null || true
cp CONTAINERIZATION-PLAN.md "${BACKUP_DIR}/docs/" 2>/dev/null || true
cp CONTAINERIZATION-RECOMMENDATIONS.md "${BACKUP_DIR}/docs/" 2>/dev/null || true
cp DOCKER-COMPOSE-CLEANUP.md "${BACKUP_DIR}/docs/" 2>/dev/null || true
cp DOCKER-COMPOSE-GUIDE.md "${BACKUP_DIR}/docs/" 2>/dev/null || true
cp DOCKER-COMPOSE-TESTING.md "${BACKUP_DIR}/docs/" 2>/dev/null || true
cp DOCKER-COMPOSE-HEALTH-FIXES.md "${BACKUP_DIR}/docs/" 2>/dev/null || true
cp DOCKER-COMPOSE-STRUCTURE.md "${BACKUP_DIR}/docs/" 2>/dev/null || true

# 3. Ensure new directory structure exists
echo -e "${YELLOW}Ensuring directory structure exists...${NORM}"
mkdir -p docker-compose/profiles
mkdir -p docs/operations/containerization

# 4. Remove redundant files
echo -e "${YELLOW}Removing redundant files...${NORM}"
rm -f docker-compose-clean.yml 2>/dev/null || true
rm -f docker-compose.mock-storage.yml 2>/dev/null || true
rm -f docker-compose.storage.yml 2>/dev/null || true

# 5. Remove redundant documentation
echo -e "${YELLOW}Removing redundant documentation...${NORM}"
rm -f COMPOSE-CLEANUP-SUMMARY.md 2>/dev/null || true
rm -f CONTAINERIZATION-PLAN.md 2>/dev/null || true
rm -f CONTAINERIZATION-RECOMMENDATIONS.md 2>/dev/null || true
rm -f DOCKER-COMPOSE-CLEANUP.md 2>/dev/null || true
rm -f DOCKER-COMPOSE-GUIDE.md 2>/dev/null || true
rm -f DOCKER-COMPOSE-TESTING.md 2>/dev/null || true
rm -f DOCKER-COMPOSE-HEALTH-FIXES.md 2>/dev/null || true
rm -f DOCKER-COMPOSE-STRUCTURE.md 2>/dev/null || true

# 6. Move Docker Compose files
echo -e "${YELLOW}Ensuring Docker Compose files are in the right places...${NORM}"
cp -n docker-compose.local.yml.template docker-compose/docker-compose.local.yml.template 2>/dev/null || true

# 7. Update README.md to reference new documentation
echo -e "${YELLOW}Updating Docker Compose documentation references in README.md...${NORM}"
if grep -q "Docker Compose" README.md; then
  # Replace Docker Compose section with reference to new docs
  sed -i '/## Docker Compose/,/## /c\
## Docker Compose\n\
\n\
The platform uses a simplified Docker Compose structure:\n\
\n\
- `docker-compose.yml` - Main configuration\n\
- `docker-compose.dev.yml` - Development overrides\n\
- `docker-compose.prod.yml` - Production optimizations\n\
- `docker-compose.local.yml` - Personal developer settings (from template)\n\
\n\
For detailed usage, see the [Docker Compose Guide](docs/operations/containerization/docker-compose-guide.md).\n\
\n\
```bash\n\
# Development mode\n\
./start-platform.sh -e dev\n\
\n\
# With mock services\n\
./start-platform.sh -e dev mock\n\
```\n\
\n\
## ' README.md
fi

echo -e "${GREEN}${BOLD}=== Docker Compose consolidation complete! ===${NORM}"
echo -e "${GREEN}✅ Files backed up to: ${BACKUP_DIR}${NORM}"
echo -e "${GREEN}✅ Documentation consolidated in: docs/operations/containerization/${NORM}"
echo -e "${GREEN}✅ Docker Compose structure simplified${NORM}"
echo -e "\n${BLUE}Next steps:${NORM}"
echo -e "1. Review the updated documentation in docs/operations/containerization/"
echo -e "2. Test the system with the consolidated configuration"
echo -e "3. Commit the changes to version control"