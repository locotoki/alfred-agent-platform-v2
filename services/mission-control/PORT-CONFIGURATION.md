# Port Configuration for Mission Control

## Port Usage in Alfred Agent Platform

After careful analysis of the running services, here's what we found:

| Port | Service | Container/App |
|------|---------|---------------|
| 3000 | Supabase REST API | supabase-rest |
| 3001 | Supabase Studio | supabase-studio |
| 3002 | Grafana | grafana |
| 3003 | Mission Control UI | mission-control |
| 5432 | PostgreSQL | supabase-db |
| 6333 | Qdrant Vector DB | qdrant |
| 6379 | Redis | redis |
| 8085 | PubSub Emulator | pubsub-emulator |
| 9000 | Social Intel Agent | social-intel |
| 9002 | Legal Compliance Agent | legal-compliance |
| 9003 | Financial Tax Agent | financial-tax |
| 9090 | Prometheus | prometheus |
| 9100 | Node Exporter | node-exporter |
| 9187 | Postgres Exporter | postgres-exporter |
| 11434 | Ollama | ollama |

## Port Selection Rationale

The Mission Control UI has been configured to use port 3003 because:

1. Port 3000 is already in use by Supabase REST API (PostgREST)
   - This was causing the Mission Control UI to show Swagger documentation instead of the dashboard

2. Port 3001 is used by Supabase Studio
   - This is the admin UI for managing the Supabase database

3. Port 3002 is used by Grafana
   - This is the metrics visualization dashboard

4. Port 3003 was the next logical choice in the sequence, and it is available

## Configuration Updates

The following files have been updated to use port 3003:

1. `package.json`: Updated dev and start scripts
2. `next.config.js`: Updated server runtime configuration
3. `.env.local`: Updated public server URL
4. `src/services/youtube-workflows.ts`: Updated fallback base URL
5. `restart-server.sh`: Updated startup port and access instructions
6. `public/port-fix.js`: Updated port handling to manage all variations

## How to Access the Mission Control UI

The Mission Control UI is now accessible at:

```
http://localhost:3003
```

## Troubleshooting

If you see a "Connection refused" or "Cannot connect to server" error:

1. Make sure the Mission Control server is running:
   ```
   cd services/mission-control
   ./restart-server.sh
   ```

2. Check if port 3003 is already in use by another application:
   ```
   lsof -i :3003
   ```

3. If port 3003 is in use, you can modify the configuration to use a different available port