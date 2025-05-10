# Mission Control Port Configuration

To ensure reliable operation regardless of port availability, Mission Control now implements a port fallback mechanism.

## Port Selection Logic

1. The server will first attempt to use the preferred port (3007):
   ```javascript
   const PREFERRED_PORT = process.env.PORT || 3007;
   ```

2. If port 3007 is unavailable (already in use by another process), it will automatically fall back to port 3010:
   ```javascript
   const FALLBACK_PORT = 3010;
   ```

3. The server will clearly indicate in the console which port it's using:
   ```
   Mission Control server running on port 3007
   ```
   or
   ```
   Mission Control server running on fallback port 3010
   NOTE: Using fallback port because primary port 3007 is in use
   ```

## Accessing the Service

The API endpoints and UI pages will use the active port automatically, and the server's console output will show the correct URLs.

### API Endpoints
- Health check: `http://localhost:[PORT]/api/health`
- Agent status: `http://localhost:[PORT]/api/agents/status`
- Niche-Scout: `http://localhost:[PORT]/api/workflows/niche-scout` (POST)
- Seed-to-Blueprint: `http://localhost:[PORT]/api/workflows/seed-to-blueprint` (POST)

### UI Pages
- Dashboard: `http://localhost:[PORT]/`
- Niche-Scout workflow: `http://localhost:[PORT]/workflows/niche-scout`
- Seed-to-Blueprint workflow: `http://localhost:[PORT]/workflows/seed-to-blueprint`

## Fixing the Port Conflict

If you want to ensure Mission Control always uses port 3007:

1. Find the process currently using port 3007:
   ```
   netstat -tulpn | grep ":3007"
   ```
   or
   ```
   lsof -i :3007
   ```

2. Terminate the process:
   ```
   kill -9 [PID]
   ```

3. Restart Mission Control:
   ```
   node server.js
   ```

## Environment Variable Override

You can also specify a different port using the `PORT` environment variable:
```
PORT=3456 node server.js
```

This will override both the preferred and fallback ports in the configuration.