# Atlas Usage Guide

This guide explains how to use Atlas, the Infrastructure Architect Agent, to generate architecture specifications for your projects.

## Quick Start

To use Atlas, you need to:
1. Ensure the Atlas system is running
2. Send architecture requests through Pub/Sub
3. Retrieve the generated specifications

## Prerequisites

- Docker and Docker Compose installed
- OpenAI API key configured in `.env.dev`
- Alfred Agent Platform v2 repository cloned

## Starting the Atlas System

```bash
# Start Atlas and all required services
cd /home/locotoki/projects/alfred-agent-platform-v2
docker-compose -f docker-compose.dev.yml up -d
```

This starts:
- Atlas Worker
- RAG Gateway
- Qdrant (vector database)
- Redis (caching)
- Pub/Sub Emulator (messaging)
- Supabase (persistence)

## Verifying System Health

```bash
# Check Atlas Worker health
curl http://localhost:8000/healthz

# Check RAG Gateway health
curl http://localhost:8501/healthz

# Check Prometheus metrics
curl http://localhost:8000/metrics | grep atlas_health
```

## Sending Architecture Requests

You can request architecture specifications in two ways:

### 1. Using the Publish Script (Recommended)

```bash
# Request a microservice logging architecture
./scripts/publish_task.sh "Design a microservice logging architecture with observability features"

# Request a serverless API architecture
./scripts/publish_task.sh "Design a serverless API architecture for a real estate application"

# Request a data pipeline architecture
./scripts/publish_task.sh "Design a data pipeline architecture for processing IoT sensor data"
```

### 2. Using curl Directly

```bash
# Create the message JSON
MESSAGE='{"role":"architect","msg_type":"chat","content":"Design a database architecture for high-scale e-commerce","metadata":{}}'
BASE64_MSG=$(echo -n "$MESSAGE" | base64 | tr -d '\n')

# Send to Pub/Sub
curl -X POST "http://localhost:8681/v1/projects/alfred-agent-platform/topics/architect_in:publish" \
  -H "Content-Type: application/json" \
  -d "{\"messages\":[{\"data\":\"$BASE64_MSG\"}]}"
```

## Viewing Architecture Specifications

The generated architecture specifications are available through:

### 1. Docker Logs

```bash
# View real-time logs and look for architect_out messages
docker logs -f alfred-agent-platform-v2-atlas-worker-1 | grep architect_out
```

### 2. Supabase Database (if you have Supabase Studio)

1. Open Supabase Studio
2. Navigate to the `architect_out` table
3. View the most recent entries

### 3. Direct API Query

```bash
# Fetch the most recent architecture specification
curl -s -X GET \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  "http://localhost:3000/rest/v1/architect_out?select=*&order=created_at.desc&limit=1" | jq '.[0].data.content'
```

## Example: Full Workflow

```bash
# Start the system
docker-compose -f docker-compose.dev.yml up -d

# Verify system health
curl http://localhost:8000/healthz

# Send architecture request
./scripts/publish_task.sh "Design a microservice architecture for a food delivery application"

# Wait a few seconds for processing
sleep 10

# View the generated architecture
docker logs alfred-agent-platform-v2-atlas-worker-1 | grep -A 100 "food delivery application" | less
```

## Advanced Usage

### 1. Providing Additional Context

When you have specific requirements, include them in your request:

```bash
./scripts/publish_task.sh "Design a cloud-native architecture for a financial application with these requirements:
- Must handle 10,000 transactions per second
- Needs to be compliant with PCI-DSS
- Should have separate environments for dev, test, and production
- Must include monitoring and alerting
- Should minimize operational costs while ensuring high availability"
```

### 2. Specific Architecture Types

Atlas can generate various types of architectures:

#### Microservices
```bash
./scripts/publish_task.sh "Design a microservice architecture for a video streaming platform"
```

#### Serverless
```bash
./scripts/publish_task.sh "Design a serverless architecture for a photo sharing application"
```

#### Data Processing
```bash
./scripts/publish_task.sh "Design a data processing architecture for real-time analytics"
```

#### Infrastructure as Code
```bash
./scripts/publish_task.sh "Design an Infrastructure as Code architecture using Terraform for a multi-region deployment"
```

### 3. Requesting Specific Diagrams

To get diagrams in your specification, request them explicitly:

```bash
./scripts/publish_task.sh "Design a microservice architecture for an e-commerce platform. Include C4 model diagrams with PlantUML notation."
```

## Troubleshooting

### Atlas Worker Not Responding

1. Check the health endpoint:
   ```bash
   curl http://localhost:8000/healthz
   ```

2. View the logs:
   ```bash
   docker logs alfred-agent-platform-v2-atlas-worker-1
   ```

3. Restart the service:
   ```bash
   docker-compose -f docker-compose.dev.yml restart atlas-worker
   ```

### RAG Gateway Issues

1. Check the health endpoint:
   ```bash
   curl http://localhost:8501/healthz
   ```

2. View the logs:
   ```bash
   docker logs alfred-agent-platform-v2-atlas-rag-gateway-1
   ```

3. Restart the service:
   ```bash
   docker-compose -f docker-compose.dev.yml restart atlas-rag-gateway
   ```

### Pub/Sub Message Delivery Issues

1. Verify the Pub/Sub emulator is running:
   ```bash
   docker ps | grep pubsub
   ```

2. Check if topics exist:
   ```bash
   curl http://localhost:8681/v1/projects/alfred-agent-platform/topics
   ```

3. Manually send a test message:
   ```bash
   ./scripts/test_atlas_supabase.sh
   ```

## Architecture Quality Tips

To get the best results from Atlas:

1. **Be specific**: Include as many details as possible about your requirements
2. **Define constraints**: Mention scaling, security, compliance, or budget constraints
3. **Specify technologies**: If you have technology preferences, state them clearly
4. **Provide context**: Explain the purpose and users of the architecture
5. **Ask for alternatives**: Request various approaches to solve your problem

## Next Steps

- To add custom knowledge to Atlas, index your documentation using `./scripts/index_repo.sh <path>`
- View system metrics in Prometheus at `http://localhost:9090`
- Check the [Atlas Development Guide](./DEVELOPMENT.md) to learn how to customize Atlas
- See the [Roadmap](./roadmap.md) for upcoming features