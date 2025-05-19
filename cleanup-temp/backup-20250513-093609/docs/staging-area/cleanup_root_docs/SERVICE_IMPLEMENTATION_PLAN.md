# Service Implementation Plan

To fully deploy the refactored Docker Compose configuration with real services, follow this plan:

## 1. Service Code Structure

Organize your service code according to the expected directory structure:

```
alfred-agent-platform-v2/
├── services/
│   ├── alfred-core/              # Core agent service code
│   │   └── Dockerfile.dev        # Development Dockerfile
│   ├── rag-service/              # RAG service code
│   │   └── Dockerfile.dev
│   ├── atlas-service/            # Atlas service code
│   │   └── Dockerfile.dev
│   └── ...                       # Other service code directories
├── ui/
│   ├── chat/                     # Chat UI code
│   │   └── Dockerfile.dev
│   └── admin/                    # Admin UI code
│       └── Dockerfile.dev
├── monitoring/
│   ├── prometheus/               # Prometheus configuration
│   │   └── prometheus.yml
│   └── grafana/                  # Grafana dashboards
│       ├── dashboards/
│       └── provisioning/
└── migrations/                   # Database migrations
    └── supabase/                 # Supabase SQL migrations
```

## 2. Docker Image Preparation

Either build the service images locally or push them to a registry:

### Option A: Local Development (Recommended for testing)

Update the docker-compose.dev.yml file to use build contexts:

```yaml
services:
  agent-core:
    build:
      context: ./services/alfred-core
      dockerfile: Dockerfile.dev
    # ... other settings

  ui-chat:
    build:
      context: ./ui/chat
      dockerfile: Dockerfile.dev
    # ... other settings
```

### Option B: Docker Registry (Recommended for production)

1. Build and push your images to a registry:
   ```bash
   docker build -t your-registry/agent-core:latest ./services/alfred-core
   docker push your-registry/agent-core:latest
   ```

2. Update the registry in your .env file:
   ```
   ALFRED_REGISTRY=your-registry
   ALFRED_VERSION=latest
   ```

## 3. Staged Deployment

1. **Start Infrastructure Services**:
   ```bash
   ./alfred.sh start --components=core --env=dev
   ```

2. **Verify Infrastructure**:
   ```bash
   ./alfred.sh status
   ```

3. **Add Agent Services**:
   ```bash
   ./alfred.sh start --components=core,agents --env=dev
   ```

4. **Add UI Services**:
   ```bash
   ./alfred.sh start --components=core,agents,ui --env=dev
   ```

5. **Add Monitoring** (optional):
   ```bash
   ./alfred.sh start --components=core,agents,ui,monitoring --env=dev
   ```

## 4. Running in Production

For production deployment:

1. Ensure all secrets are properly set in .env
2. Use pre-built images from your registry
3. Run with production configuration:
   ```bash
   ./alfred.sh start --components=core,agents,ui --env=prod
   ```

## Rollback Plan

If issues arise during deployment:

1. Stop the new services:
   ```bash
   ./alfred.sh stop --force
   ```

2. Restore from backup:
   ```bash
   cp /home/locotoki/projects/alfred-agent-platform-v2/backup_20250511_164713/* /home/locotoki/projects/alfred-agent-platform-v2/
   ```

3. Restart using the original method

## Troubleshooting

Common issues you might encounter:

1. **Missing Dockerfile.dev**: Ensure your service directories contain the proper Dockerfile.dev files
2. **Network Issues**: Check that all services are on the alfred-network
3. **Environment Variables**: Verify that variables defined in .env match what services expect
4. **Volume Mounts**: Confirm all volume paths exist on the host machine
5. **Build Context**: Make sure service code is in the expected location relative to docker-compose files

For detailed logs:
```bash
./alfred.sh logs --service=service-name
```
