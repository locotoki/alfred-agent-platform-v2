# Atlas Operations Guide

*Last Updated: 2025-05-11*  
*Owner: Infra Crew*  
*Status: MVP Implementation*

## Overview

This guide covers operational aspects of the Atlas architecture agent, including deployment, monitoring, and troubleshooting.

## Deployment

### Development Environment

To deploy Atlas in a development environment:

```bash
# Start the Atlas development stack
make atlas-dev

# Verify services are running
docker ps | grep atlas
```

### Production Environment

For production deployment, follow these steps:

1. Ensure Supabase is properly configured with the tables from the migration script
2. Configure Docker/K8s secrets for OpenAI API key and Supabase credentials
3. Deploy using the provided Docker Compose or Kubernetes manifests
4. Set up monitoring with Prometheus and Grafana

## Monitoring

### Key Metrics

| Metric | Description | Alert Threshold |
|--------|-------------|----------------|
| `atlas_tokens_total` | Total token usage | Warn at 80% of daily budget, critical at 100% |
| `atlas_run_seconds` | Processing time per request | Critical if p95 > 10s |
| `pubsub_unacknowledged_messages` | Messages waiting to be processed | Warn if > 50 for 5 minutes |

### Dashboards

The Grafana dashboard for Atlas monitoring includes:

- Token usage over time
- Request latency percentiles
- Error rates and types
- Queue depth

## Maintenance Tasks

| Frequency | Task | Command |
|-----------|------|---------|
| Daily | Check token usage | View Grafana dashboard |
| Weekly | Index new documents | `scripts/index_repo.sh <path>` |
| Monthly | Rotate API keys | Update secrets and restart services |

## Troubleshooting

### Common Issues

#### Atlas Worker Not Starting

**Symptoms:** Container exits immediately, logs show authentication errors

**Resolution:**
1. Check that OPENAI_API_KEY is set correctly
2. Verify Supabase URL and service role key are valid
3. Ensure Pub/Sub emulator is running

#### High Latency

**Symptoms:** Slow responses, metrics show high `atlas_run_seconds`

**Resolution:**
1. Check RAG service performance
2. Verify OpenAI API responsiveness
3. Consider scaling up resources or increasing worker count

#### Failed Message Processing

**Symptoms:** Messages stuck in queue, errors in logs

**Resolution:**
1. Check error logs for specific issues
2. Verify message format is correct
3. Restart worker if necessary
4. Check for OpenAI API rate limits

## Scaling

Atlas is designed to scale horizontally. To handle increased load:

1. Add more atlas-worker instances
2. Increase resources for the RAG gateway
3. Scale Qdrant for higher throughput
4. Consider implementing Redis caching for frequent queries

## Backup and Recovery

1. Regularly back up Supabase database
2. Back up Qdrant collections
3. Maintain configuration in version control
4. Document recovery procedures specific to your deployment