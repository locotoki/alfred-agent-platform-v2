# Chat Adapters Run Book

## Slack adapter

The adapter exposes **/health** (liveness) and is wired to Kubernetes readiness &
liveness probes. A pod reaches *Ready* when `/health` returns **200 OK**.

```sh
kubectl -n chat-adapters port-forward svc/slack-adapter 8080:8080 &
curl -sf http://localhost:8080/health   # → ok
```

### Local Testing

When running with docker-compose, the slack adapter is available on port 3001:

```sh
curl http://localhost:3001/health
# Expected response: {"status": "healthy", "service": "alfred-slack-adapter"}
```

### Health Endpoints

- `/health` - Basic health check for liveness
- `/healthz` - Kubernetes-style health check with version info

### Troubleshooting

If the slack adapter is not responding:

1. Check container logs: `docker logs slack-adapter`
2. Verify environment variables are set (especially SLACK_SIGNING_SECRET)
3. Ensure the container has started: `docker ps | grep slack-adapter`
