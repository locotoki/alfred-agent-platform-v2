# Port Standard for Alfred Agent Platform v2

## Standard Port Assignments
- Mission Control UI: 3007
- Social Intelligence Agent: 9000 (DO NOT CHANGE)
- Supabase REST API: 3000
- Supabase Studio: 3001
- Grafana: 3002
- PostgreSQL: 5432
- Qdrant Vector DB: 6333
- Redis: 6379
- PubSub Emulator: 8085
- Legal Compliance Agent: 9002
- Financial Tax Agent: 9003
- Prometheus: 9090
- Node Exporter: 9100
- Postgres Exporter: 9187
- Ollama: 11434

## Rationale
The 3000-3005 port range has experienced conflicts with other services. To maintain stability, we've standardized on port 3007 for the Mission Control UI, which avoids conflicts with Supabase and other services.

## Configuration Files
The following files must maintain this port configuration:
1. package.json: "dev": "next dev -p 3007"
2. .env.local: NEXT_PUBLIC_SERVER_URL=http://localhost:3007
3. next.config.js: port: parseInt(process.env.PORT, 10) || 3007

## Dynamic URL Configuration
Services should use dynamic URL configuration whenever possible:
```typescript
const baseUrl = typeof window !== 'undefined' ? window.location.origin : 'http://localhost:3007';
```

This ensures that the application works across different environments without hardcoding ports.

## Port Conflict Resolution
If you encounter port conflicts:
1. Check for running processes: `lsof -i :3007`
2. Kill conflicting processes: `kill -9 $(lsof -t -i:3007)`
3. Restart the service
