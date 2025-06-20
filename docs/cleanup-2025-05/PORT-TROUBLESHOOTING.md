# Port Troubleshooting Guide for Alfred Agent Platform v2

## Standard Port Configuration
- **Mission Control UI**: 3007
- **Social Intelligence Agent**: 9000 (DO NOT CHANGE)

Refer to `PORT-STANDARD.md` for the complete port allocation.

## Common Issues

### 1. "Address already in use" Error

**Symptoms**:
- Error message: `Error: listen EADDRINUSE: address already in use :::3007`
- Mission Control won't start

**Solutions**:
```bash
# Find the process using port 3007
lsof -i :3007

# Kill the process
kill -9 $(lsof -t -i:3007)

# Restart Mission Control
cd services/mission-control
npm run dev
```

### 2. Connection Refused to Social Intelligence Agent

**Symptoms**:
- UI shows "Could not connect to API" errors
- Mock data appears instead of real data

**Solutions**:
```bash
# Check if Social Intelligence Agent container is running
docker ps | grep architect-api

# Start the container if not running
docker-compose up -d architect-api

# Check container logs for errors
docker logs $(docker ps -q --filter name=architect-api)
```

### 3. URL Hardcoding Issues

**Symptoms**:
- API calls fail when accessing from a different port
- Console shows 404 errors for API endpoints

**Solutions**:
1. Check for hardcoded URLs in code:
```bash
grep -r "localhost:3[0-9][0-9][0-9]" --include="*.ts" --include="*.tsx" services/mission-control/src
```

2. Replace with dynamic URL construction:
```typescript
const baseUrl = typeof window !== 'undefined' ? window.location.origin : 'http://localhost:3007';
```

### 4. .env.local Configuration Issues

**Symptoms**:
- Inconsistent behavior between environments
- API endpoints failing despite services running

**Solutions**:
1. Verify .env.local has correct configuration:
```bash
cat services/mission-control/.env.local
```

2. Update if needed:
```bash
echo "SOCIAL_INTEL_URL=http://localhost:9000
NEXT_PUBLIC_SERVER_URL=http://localhost:3007
NEXT_PUBLIC_API_BASE_URL=/api/architect-api" > services/mission-control/.env.local
```

## Validation Steps

After making changes, validate the configuration:

```bash
# Run the environment check script
bash ./docs/phase6-mission-control/youtube-workflows/environment-check-script.sh

# Verify Mission Control is accessible
curl -I http://localhost:3007

# Verify Social Intelligence Agent is accessible
curl -I http://localhost:9000/api/health
```

## When All Else Fails

If port conflicts persist:

1. **Docker Restart**:
```bash
docker-compose down
docker-compose up -d
```

2. **WSL Restart** (if using WSL):
```bash
wsl --shutdown
# Then restart WSL from Windows
```

3. **Alternative Port**:
If port 3007 is consistently unavailable, you can temporarily use a different port:
```bash
cd services/mission-control
PORT=3008 npm run dev
```
But remember to update documentation and notify your team about the change.
