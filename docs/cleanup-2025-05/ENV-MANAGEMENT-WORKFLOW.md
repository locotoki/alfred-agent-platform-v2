# Environment Variable Management Workflow

## Problem Statement
Every new pull/build encounters missing environment variables, causing repeated troubleshooting of Slack integration and other services.

## Solution: Standardized ENV Management

### 1. Local Development Setup

#### A. Master ENV Template
Create `.env.template` with ALL required variables (without secrets):

```bash
# Slack Integration
SLACK_SIGNING_SECRET=
SLACK_BOT_TOKEN=
SLACK_APP_TOKEN=
SLACK_WEBHOOK_URL=

# Alfred-specific Slack vars (some services use these)
ALFRED_SLACK_BOT_TOKEN=${SLACK_BOT_TOKEN}
ALFRED_SLACK_SIGNING_SECRET=${SLACK_SIGNING_SECRET}
ALFRED_SLACK_APP_TOKEN=${SLACK_APP_TOKEN}
ALFRED_SLACK_WEBHOOK_URL=${SLACK_WEBHOOK_URL}

# Redis
REDIS_PASSWORD=

# JWT
JWT_SIGNING_KEY=

# Database
POSTGRES_PASSWORD=postgres
DB_PASSWORD=${POSTGRES_PASSWORD}

# Registry
GHCR_PAT=

# Compose
COMPOSE_PROFILES=bizdev,obs,qa
ALFRED_REGISTRY=ghcr.io/digital-native-ventures/alfred-agent-platform-v2

# Telegram (dummy for local dev)
TELEGRAM_BOT_TOKEN=dummy-token
```

#### B. One-Time Local Setup Script
```bash
#!/bin/bash
# setup-local-env.sh

if [ ! -f .env ]; then
    echo "Setting up local environment..."
    cp .env.template .env
    echo "⚠️  Please fill in the secrets in .env file"
    echo "Required secrets:"
    echo "  - SLACK_* variables"
    echo "  - REDIS_PASSWORD"
    echo "  - JWT_SIGNING_KEY"
    echo "  - GHCR_PAT"
else
    echo "✅ .env already exists"
fi

# Validate required variables
./scripts/validate-env.sh
```

### 2. Docker Compose Integration

#### A. Update docker-compose.yml to use env_file
```yaml
services:
  slack-adapter:
    env_file:
      - .env
    environment:
      # Override or add service-specific vars
      - SERVICE_NAME=slack-adapter
```

#### B. Create docker-compose.env.yml override
```yaml
# docker-compose.env.yml - Ensures all services get env vars
version: '3.8'

services:
  agent-core:
    env_file: .env
  
  agent-bizdev:
    env_file: .env
    
  slack-adapter:
    env_file: .env
    
  slack-mcp-gateway:
    env_file: .env
    
  crm-sync:
    env_file: .env
    
  contact-ingest:
    env_file: .env
```

### 3. Automated Validation

#### A. Pre-flight Check Script
```bash
#!/bin/bash
# scripts/validate-env.sh

REQUIRED_VARS=(
    "SLACK_SIGNING_SECRET"
    "SLACK_BOT_TOKEN"
    "SLACK_APP_TOKEN"
    "SLACK_WEBHOOK_URL"
    "REDIS_PASSWORD"
    "JWT_SIGNING_KEY"
    "GHCR_PAT"
)

missing=0
for var in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Missing: $var"
        ((missing++))
    else
        echo "✅ Found: $var"
    fi
done

if [ $missing -gt 0 ]; then
    echo ""
    echo "⚠️  $missing required variables missing!"
    echo "Run: cp .env.template .env && vi .env"
    exit 1
fi

echo ""
echo "✅ All required environment variables present!"
```

### 4. Git Workflow Integration

#### A. Add to .gitignore
```
.env
.env.local
.env.*.local
# But NOT .env.template
```

#### B. Pre-commit Hook
```bash
#!/bin/bash
# .git/hooks/pre-commit

# Prevent committing .env files
if git diff --cached --name-only | grep -E "^\.env$|^\.env\..*$" | grep -v "\.template$"; then
    echo "❌ ERROR: Attempting to commit .env file with secrets!"
    echo "Remove with: git reset HEAD .env"
    exit 1
fi
```

### 5. New Developer Onboarding

#### A. README.md addition
```markdown
## Quick Start

1. Clone the repository
2. Set up environment variables:
   ```bash
   cp .env.template .env
   # Edit .env with your secrets (get from team lead)
   ```
3. Validate setup:
   ```bash
   ./scripts/validate-env.sh
   ```
4. Start services:
   ```bash
   docker compose up -d
   ```
```

#### B. Makefile target
```makefile
# Add to Makefile
.PHONY: setup-env
setup-env:
	@if [ ! -f .env ]; then \
		cp .env.template .env; \
		echo "✅ Created .env from template"; \
		echo "⚠️  Please edit .env with actual secrets"; \
	else \
		echo "✅ .env already exists"; \
	fi
	@./scripts/validate-env.sh
```

### 6. CI/CD Integration

#### A. GitHub Secrets Setup
Store all production secrets in GitHub Secrets:
- `PROD_SLACK_SIGNING_SECRET`
- `PROD_SLACK_BOT_TOKEN`
- `PROD_SLACK_APP_TOKEN`
- `PROD_SLACK_WEBHOOK_URL`
- etc.

#### B. Build Script Enhancement
```bash
#!/bin/bash
# scripts/build-with-env.sh

# For CI/CD builds
if [ "$CI" = "true" ]; then
    # Use GitHub secrets
    export SLACK_SIGNING_SECRET=${{ secrets.PROD_SLACK_SIGNING_SECRET }}
    # ... other vars
else
    # Use local .env
    if [ -f .env ]; then
        export $(grep -v '^#' .env | xargs)
    else
        echo "❌ No .env file found!"
        exit 1
    fi
fi

# Now build
docker compose build
```

### 7. Service-Specific ENV Requirements

Create a central documentation:
```yaml
# services/ENV-REQUIREMENTS.yml
services:
  slack-adapter:
    required:
      - SLACK_SIGNING_SECRET
      - SLACK_BOT_TOKEN
      - SLACK_APP_TOKEN
    optional:
      - SLACK_WEBHOOK_URL
      
  slack-mcp-gateway:
    required:
      - SLACK_APP_TOKEN
      - SLACK_BOT_TOKEN
      
  agent-core:
    required:
      - REDIS_PASSWORD
      - JWT_SIGNING_KEY
```

## Implementation Steps

1. **Create templates** (5 min)
   ```bash
   # Create .env.template with all vars
   # Create setup-local-env.sh
   # Create validate-env.sh
   ```

2. **Update docker-compose** (10 min)
   ```bash
   # Add env_file to all services
   # Create docker-compose.env.yml
   ```

3. **Update Makefile** (5 min)
   ```bash
   # Add setup-env target
   # Update existing targets to validate env first
   ```

4. **Test workflow** (10 min)
   ```bash
   make setup-env
   docker compose up -d
   ```

5. **Document** (5 min)
   ```bash
   # Update README.md
   # Create ENV-REQUIREMENTS.yml
   ```

## Result
- No more missing env variables
- New developers can start in < 5 minutes
- CI/CD uses GitHub secrets automatically
- Local dev uses .env file consistently
- Validation catches issues before they cause problems